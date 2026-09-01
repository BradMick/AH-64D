# Systems redesign — open

The damage model went generic in `abe604035`: hitpoints declare their own role,
Core asks by role, and any count is expressible in config. The **lookup** is
generic. The **systems structure behind it is not**, and that gap is what needs
designing.

## What works now

A designer declares whatever the airframe has:

```cpp
BMKHS_HITPOINT(hitengine1,  "hitengine1",  0.1206, 0.14, 0.05, 0.3, "engines", 0)
BMKHS_HITPOINT(hit_elec_generator3, "...",  ...,                    "generators", 2)
```

and Core reads it back:

```sqf
[_heli, "generators"]     call bmkhs_fnc_damageGet    //worst of however many
[_heli, "generators", 2]  call bmkhs_fnc_damageGet    //the third one
[_heli, "generators"]     call bmkhs_fnc_damageCount  //how many exist
```

Roles nothing claims return 0 — undamaged — so no pylons, no APU or no FCR
needs no special case.

## What does not work

Core simulates **exactly two** of each multi-member system, by name.

| duplicated pair | differs by |
|---|---|
| `fn_drivetrainNoseGearbox1` / `2` | one index, plus whitespace |
| `fn_electricalGenerator1` / `2` | one index, plus whitespace |
| `fn_electricalRectifier1` / `2` | one index — otherwise byte-identical |

Both controllers dispatch by name:

```sqf
//fn_drivetrainController
[_heli, _deltaTime] call bmkhs_fnc_drivetrainNoseGearbox1;
[_heli, _deltaTime] call bmkhs_fnc_drivetrainNoseGearbox2;

//fn_electricalController
[_heli, _apuOn, _rtrRPM] call bmkhs_fnc_electricalGenerator1;
[_heli]                  call bmkhs_fnc_electricalRectifier1;
[_heli, _apuOn, _rtrRPM] call bmkhs_fnc_electricalGenerator2;
[_heli]                  call bmkhs_fnc_electricalRectifier2;
```

Consequences for a designer:

- **Three generators** — the third takes damage and is never simulated.
- **One engine** — Core still runs nose gearbox 2, which reads
  `bmkhs_engPctTQ select 1` on a one-element array.
- **No pylons** — fine, that path is already count-driven.

The config now *implies* any count is supported. Until the systems follow, that
implication is wrong, which is worse than the old honest hardcoding.

## Why it is a redesign, not a refactor

Per-member state lives in **suffixed variables**, not arrays:

```
bmkhs_gen1On    bmkhs_gen2On
bmkhs_rect1On   bmkhs_rect2On
```

Engines already went the other way — `bmkhs_engPctTQ`, `bmkhs_engState`,
`bmkhs_engFF` are arrays indexed by engine. So the two halves of the systems
model disagree about how to represent a member, and the cockpit reads the
suffixed form directly:

- `fza_ah64_controls/fn_coreGetWCAs.sqf`
- `fza_ah64_mpd` electrical page

Converting to arrays touches those consumers; keeping suffixes means Core
builds names with `format`, which works but keeps two conventions alive.

That choice — and whether the electrical model should be a bus/source graph
rather than a fixed battery + 2 gen + 2 rect — is the discussion to have.

## Direction — entity/component, event-driven

Agreed shape (to be finalised):

**One class per system, extending a common base.** The base carries identity,
the damage role and threshold, enabled/failed state, and the update function.
The hitpoint role lives on the system, so what a thing IS and what damages it
are declared in one place.

```cpp
class Generator : BMKHS_System {
    damageRole   = "generators";   //resolves to however many hitpoints claim it
    dmgThreshold = 0.85;
    dependsOn[]  = {"engines", "apu"};
    update       = "bmkhs_fnc_electricalGenerator";
};
```

Member count comes from the damage role, so declaring a third generator
hitpoint gives a third generator. No suffixed function per member.

**Systems sleep until something changes.** Measured on the current code, five
of nine systems are pure state functions recomputing an unchanged answer 60
times a second:

| pure state | integrates a timer |
|---|---|
| generators, rectifiers, AC bus, DC bus, hydraulic pumps | battery, APU, reservoir, accumulator, transmission |

A rectifier is `generatorOn && damage <= threshold` — it can only change when
one of those changes.

**Continuous is a runtime answer, not a static property.** The timer-driven
systems are not always integrating either:

| system | integrates only while |
|---|---|
| battery | on battery bus AND AC bus down |
| APU | spooling up or down, not at steady RPM |
| reservoir | actually leaking |
| accumulator | bleeding down |
| transmission | over a torque limit |

On a healthy running aircraft **none of these are integrating** — the battery
recharge/drain branch needs `!_acBusOn`, which is false whenever a generator is
online. So steady-state cost should approach zero, not four ticking systems.

The scheduler that expresses this: an update returns whether it wants the next
frame.

```sqf
//true = keep me scheduled, false = sleep until a dependency changes
[_heli, _index, _deltaTime] call bmkhs_fnc_electricalBattery
```

Dirty-flag propagation wakes a sleeping system when a dependency changes; a
system that is mid-transition keeps itself awake by returning true. Damage
changes are just another dependency.

### One graph, not three — electrical, hydraulic, drivetrain

Electrical, hydraulics and the drivetrain are the same structure wearing
different units: sources feed circuits, converters move capacity between them,
storage discharges when nothing else supplies.

| domain | source | circuit | converter | storage |
|---|---|---|---|---|
| electrical | generator, APU gen | AC / DC bus | rectifier, inverter | battery |
| hydraulic | engine-driven pump | PRI / UTIL circuit | electric backup pump | accumulator |
| drivetrain | engine | shaft / gearbox | gearbox (ratio) | rotor inertia |

The accumulator confirms it — `fn_hydraulicsAccumulator` is the battery with
different units: discharge only while no other source supplies the circuit,
plus a floor below which it is spent.

**Gating is a base-class property, not a storage one.** The accumulator only
releases pressure when the crew presses the emergency hydraulics button
(`bmkhs_emerHydOn`), the battery has `bmkhs_battSwitchOn`, a generator has
`bmkhs_gen1On`, and an electric backup pump has its own switch. Sources,
converters and storage can all be crew-armed, so the gate sits on the base
alongside identity and damage.

A component with no gate declared is always armed. A gated one contributes
nothing while its gate is shut - it is not failed, just off.

Storage additionally discharges only while:

    no other source supplies its circuit
    AND its gate is open
    AND it is above its spent threshold

```cpp
class Accumulator : BMKHS_Storage {
    damageRole = "accumulator";
    output     = "PRI_HYD";
    gate       = "bmkhs_emerHydOn";     //"" = always armed
    spentBelow = 1650;                  //PSI
};

class BackupPump : BMKHS_Source {       //a SOURCE, and still gated
    damageRole = "backupPump";
    output     = "UTIL_HYD";
    drivenBy   = "DC";                  //electrically driven, hence the domain crossing
    gate       = "bmkhs_backupPumpOn";
};
```

**This has to be one graph, not three parallel ones**, because real components
cross domains:

- an **electric backup hydraulic pump** consumes from an electrical bus and
  produces onto a hydraulic circuit
- a **generator** consumes shaft power from the drivetrain and produces onto an
  electrical bus
- an **APU** is a source in all three at once

Modelling them separately means those couplings become special cases again,
which is the thing being removed.

So the base kinds are domain-agnostic:

  BMKHS_Source     produces onto a circuit, given whatever drives it
  BMKHS_Converter  consumes from one circuit, produces onto another
  BMKHS_Storage    a source that depletes while nothing else supplies it
  BMKHS_Circuit    a named node; the solver answers "is it supplied"

`drivenBy` and `input` reference circuits in ANY domain, which is what makes
the electric backup pump and the engine-driven generator expressible without
Core knowing either exists.

### Electrical as a bus/source graph

The current model hardcodes the AH-64's topology three ways: the AC bus is fed
by generators by name, the DC bus by rectifiers by name, and the DIRECTION of
conversion is assumed — generators are AC, converters go AC to DC.

Not every airframe is wired that way. Some have DC generators and need
inverters (DC to AC) rather than rectifiers (AC to DC). Same components, wired
in reverse.

Generalises to two component kinds, where direction is data:

```cpp
class Generator1 : BMKHS_PowerSource {
    damageRole = "generators";
    output     = "AC";        //"DC" on a DC-generator aircraft
    drivenBy   = "engines";
};

class Rtru1 : BMKHS_PowerConverter {
    damageRole = "rectifiers";
    input      = "AC";
    output     = "DC";        //swap the two and it is an inverter
};

class Battery1 : BMKHS_PowerSource {
    damageRole = "batteries";
    output     = "DC";
    storage    = 1;           //drains when nothing else feeds its bus
};
```

Core then has no ACBus/DCBus functions at all — one solver that walks sources
and converters and answers, for any circuit, whether it is supplied. Circuit
names become the aircraft's to choose, so a three-bus transport or a single-bus
light helicopter needs no new code.

Consumers ask the solver rather than reading a hardcoded flag: "have I got AC",
"have I got DC", "have I got both", "is PRI hydraulic up". A component that
needs AC does not care whether it came from an AC generator directly or from a
DC generator through an inverter.

This also removes a structural coupling: `fn_electricalBattery` reads
`bmkhs_acBusOn` directly to choose drain vs recharge. In the general form that
becomes "is any non-storage source feeding my bus", which holds however the
aircraft is wired.

### Hitpoints are part of the component, not a parallel list

A component declares the damage role it answers to, and the hitpoints declaring
that role ARE its members. There is no separate count and no second list to
keep in step:

```cpp
class Generator : BMKHS_Source {
    damageRole = "generators";   //however many hitpoints claim this role
    output     = "AC";
};
```

Declare a third generator hitpoint and there is a third generator. Declare none
and there are no generators. The hitpoint set is the component inventory.

Damage acts on the component uniformly, whatever kind it is:

    damage >= dmgThreshold  ->  the component supplies nothing

so a failed generator stops feeding its bus, a failed converter stops passing
through, and a holed accumulator stops discharging - all one rule on the base,
not a check written into each system.

### No components means the system is not modelled

If nothing declares a role, that system does not exist on this aircraft. It is
NOT a failed system - there is simply nothing to simulate, and the solver has
one less input.

This is the same rule already established for damage: a role nothing claims
returns 0, undamaged, because no hitpoint means nothing can break it.

It also has to preserve the `useSystems = 0` contract. With systems off, or
with no electrical and no hydraulic components declared, the aircraft behaves
like vanilla Arma: powered up, running, no start procedure, full control
authority. The flight model still needs the rotor turning and the controls
moving, so:

- **hydraulics and drivetrain always run** - they are flight-model
  infrastructure, control authority and torque limits
- **electrical and APU are the startup systems** and can be absent entirely

An aircraft declaring no power sources gets full control authority rather than
a dead cockpit, because "no hydraulic components" means "this airframe does not
model hydraulic failure", not "the hydraulics have failed".

### Still open

Whether per-member state moves to arrays (matching engines) or keeps generated
suffixed names (matching what the cockpit reads today). That decides whether
the change stays inside Core or reaches the MPD and WCA code.

## Not yet flown

`abe604035` touched 22 Core files and every damage check in the model. Worth
confirming before building on it:

- engine damage still cuts engines
- hydraulic failure still degrades flight controls
- rotor damage thresholds still gate thrust
- `fn_repair` still restores each component

Two bugs that pass surfaced and are fixed, but the class of error is worth
watching for: Arma returns **-1**, not 0, for a hitpoint the vehicle lacks (the
old pylon loop summed it into a leak total), and `call fn == 0` parses as
`call (fn == 0)` in SQF.
