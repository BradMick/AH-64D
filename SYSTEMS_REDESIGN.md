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

Open for discussion: whether the electrical model should be a generic
bus/source graph rather than battery + N generators + N rectifiers, and whether
per-member state moves to arrays (matching engines) or keeps generated suffixed
names (matching what the cockpit reads today).

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
