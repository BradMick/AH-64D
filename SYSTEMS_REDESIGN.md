# Systems redesign — open

**Part of the BMKHS refactor.** See `SFMPLUS_BOUNDARY_REPORT.md` for the
overall plan - one standalone Core PBO, aircraft shipping a companion pack.
That report set the direction (config-gated subsystems inside a single folder)
but predates the component model below, so where the two disagree this document
is current.

What this phase covers: the systems model itself - electrical, hydraulic,
drivetrain, damage, and eventually controls - moving from hardcoded AH-64
structure to declared components. It is the last large piece of Core that still
assumes the airframe.

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

**A source can also depend on a consumable.** A hydraulic pump only produces
pressure while there is fluid in the reservoir to move - a pump with a holed
reservoir makes nothing, however healthy the pump is and whatever is driving
it. The current `fn_hydraulicsPriPump` misses this: it checks only its own
damage and produces 3000 PSI regardless of reservoir level.

That is the same shape as the accumulator running until exhausted, so it is one
rule rather than a hydraulics special case:

```cpp
class BackupPump : BMKHS_Source {
    output      = "UTIL_HYD";
    drivenBy    = "DC";                 //electrically driven
    consumes    = "utilReservoir";      //no fluid, no pressure
    gate        = "bmkhs_backupPumpOn";
};
```

So a source produces only while ALL of:

    damage < threshold
    AND gate open (or no gate)
    AND driving circuit supplied (or nothing drives it)
    AND consumable above empty (or it consumes nothing)

The accumulator behaviour is the model working as intended and worth keeping
explicit: it discharges until spent, and then there is no hydraulic pressure
and no flight controls. A reservoir running dry should do exactly the same.

**This closes the leak chain.** A reservoir is a consumable that can be damaged,
so the full sequence is one dependency chain with no special cases:

    reservoir takes damage
      -> leaks, level falls
      -> level reaches empty
      -> pump has no `consumes` left, produces nothing
      -> circuit unsupplied
      -> no control authority

Today only the first two links exist. `fn_hydraulicsPriReservoir` already
models the leak properly - three severity bands driving a drain rate - and
computes `level < hydMinLevel`, but does nothing with it except a
`//CALL WCA here` comment. The reservoir empties and the pump never notices.

**A reservoir is a reservoir, whatever it holds.** Fuel tanks and hydraulic
reservoirs are the same component running two implementations today:

| | fuel tank | hydraulic reservoir |
|---|---|---|
| leak trigger | damage > threshold | damage > threshold |
| rate | linear ramp from threshold | three discrete severity bands |
| contents | kg of fuel | fraction of capacity |
| consumer | engines | pumps |

Both are "damaged reservoir drains its contents, and its consumers starve when
it is empty". One `BMKHS_Reservoir` kind covers both, which also means the
hydraulic side inherits the fuel tanks' `variableName` and per-tank leak
hitpoint for free.

#### Unified leak mechanic

Both already start leaking at **0.50 damage** - the same threshold, reached
independently in `TANK_LEAK_START_DMG` and `SYS_HYD_RES_MIN_DMG`. Only the
scaling above it differs, so unifying costs almost nothing.

**Linear ramp**, the fuel model. Rate scales from zero at the threshold to the
component's maximum at full damage:

    frac = (damage - leakStartDmg) / (1 - leakStartDmg)
    rate = leakMaxRate * frac

A weeping reservoir weeps and a destroyed one dumps, with no step at a band
boundary. The hydraulic side loses its three discrete bands
(`SYS_HYD_RES_MIN/MOD/HVY_DMG`); nothing depends on the steps, and one
threshold per reservoir replaces three.

**Contents are a fraction 0-1, capacity lives on the component.** Core does all
rate maths in one unit and each reservoir converts for display:

```cpp
class FwdTank : BMKHS_Reservoir {
    variableName = "fwdTank";
    capacity     = 473.1;        //kg
    leakStartDmg = 0.50;
    leakMaxRate  = 0.0000355;    //fraction per second
};
```

    fuel tank      publishes frac * capacity  ->  bmkhs_fwdTankMass in kg
    hydraulic res  publishes the fraction     ->  bmkhs_priHydLevel_pct

So `fn_fuelLeak` and the leak half of `fn_hydraulicsPriReservoir` /
`fn_hydraulicsUtilReservoir` collapse into one loop over every reservoir the
aircraft declares, in any domain.

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

### Per-member state — the fuel-tank pattern is the standard

Settled. The fuel tanks got there first, so they set it: a component declares
its own `variableName` and Core publishes one variable per property per member.

```cpp
class FuelTank01 { variableName = "fwdTank"; ... };
    ->  bmkhs_fwdTankMass, bmkhs_fwdTankMax, bmkhs_fwdTankInstalled
```

Applied to the rest:

```cpp
class Generator1 : BMKHS_Source { variableName = "gen1"; ... };
    ->  bmkhs_gen1On
```

Those are the names that already exist - the difference is that the AIRCRAFT
declares them rather than Core hardcoding them. A third generator declares
`variableName = "gen3"` and publishes `bmkhs_gen3On` with no Core change.

This is also the output API. 27 files outside Core read bus and system state,
and the fuel tanks already proved a self-naming component keeps those reads
stable and discoverable from config.

**Engines are the outlier, not the generators.** They use array-per-property -
`bmkhs_engPctTQ` is `[0.9, 0.9]`, engine 2 is index 1 - and ten external files
read them with `select 0` / `select 1`:

    fza_ah64_controls, fza_ah64_fire, fza_ah64_ihadss, fza_ah64_mpd (4 pages)

Converging on the standard means engines publish `bmkhs_eng1PctTQ` /
`bmkhs_eng2PctTQ` and those ten files change with them.

**Not part of this work.** The engine model needs a full rewrite of its own and
that is where the conversion belongs - doing it piecemeal here would churn ten
external files twice. Engines keep their arrays until then; the standard is
what NEW and CONVERTED systems follow.

### Solver ordering — the battery is the root

Nothing starts without the battery: no bus can come up until it does, so it is
evaluated first. That makes ordering a topological walk rather than a special
case, because the battery is the only source needing nothing upstream - no
shaft power, no other circuit. Everything else is downstream of something.

    1. roots        storage and any source with no upstream circuit
    2. converters   in dependency order, as their input circuits come up
    3. dependents   sources driven by a circuit (electric backup pump, generators)

The battery being a root also removes the apparent circularity. Whether it
DRAINS depends on whether anything else supplies its bus - but that is a
post-solve question about charge, not part of deciding whether it is a source.
It always is, when gated on and above its spent threshold.

So: solve supply first, then settle storage charge from the result.

## Controls are components too — later, but plan for it

Not for the first pass, but the design has to leave room for it or it will have
to be retrofitted.

Every gate in this document names a control: `bmkhs_emerHydOn`,
`bmkhs_battSwitchOn`, `bmkhs_backupPumpOn`. Those are switches, and a switch is
a component with state, a hitpoint and a place in the graph - the same shape as
everything else here. It should be declared once and produce three things:

    the variable a gate reads
    the keybind
    the cockpit interaction

**The macro pattern already exists.** `CfgUserActions.hpp` has
`BMKHS_ANALOG` / `BMKHS_NONANALOG` / `BMKHS_ACTION`, each generating the
keybind and its handler dispatch together. What is missing is switch
BEHAVIOUR - everything is momentary (`onActivate` / `onDeactivate`), so
anything else is hand-written SQF.

The kinds that need expressing:

| kind | behaviour |
|---|---|
| momentary | on while held, off on release - what exists today |
| latching | press toggles, stays where it is put |
| momentary-one-way | springs back from one position only (start switch) |
| multi-position | N discrete positions, stepped or selected directly |
| guarded | needs the cover lifted first |

`fn_interactPowerLever` is the case that shows the gap: OFF / IDLE / FLY
written as an if-chain, once per engine.

**Power levers and throttles are not switches, and not each other.** Worth
separating now so the control model does not collapse them:

| | power lever | throttle |
|---|---|---|
| what | engine condition - fuel flow gate | continuous power modulation |
| range | detented positions (OFF/IDLE/FLY) | smooth 0-1 |
| use | set once per phase of flight | flown continuously |
| example | AH-64, most turbines | piston twist-grip, turbine beep |

An aircraft may have one, both or neither - the AH-64 has no throttle at all
because the governor holds Nr. So a power lever is a **detented axis**: a
continuous range whose marked positions are what the systems model reads, which
means it wants an analog binding as well as step-to-next-detent keys. A
throttle is a plain axis with no detents.

```cpp
class PowerLever : BMKHS_Control {
    variableName = "powerLever";
    kind         = "detentedAxis";
    detents[]    = {"OFF", "IDLE", "FLY"};   //positions the systems model reads
    default      = "OFF";
    perMember    = "engines";                //one per engine, from the damage role
};
```

publishing `bmkhs_eng1PowerLeverState` and generating both the analog bind and
step-up / step-down keys, with the gate model referencing a control Core does
not have to understand.

The wrinkle to design around: **keybinds are config-time and static**, while
component counts are aircraft-declared. An aircraft with three engines needs
three power-lever binds generated from `perMember`, so the macro has to expand
over a count the aircraft chooses. That is the part most likely to catch us if
the control model is bolted on afterwards rather than planned for now.

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
