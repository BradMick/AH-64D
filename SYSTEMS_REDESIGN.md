# Systems redesign — in progress

**Part of the BMKHS refactor.** See `SFMPLUS_BOUNDARY_REPORT.md` for the wider
plan. This document tracks the systems model itself moving from hardcoded
AH-64 structure to declared components.

**The field reference is `addons/bmkhs_helisim/components.hpp`**, not this
document. That header is what a builder reads to declare an airframe; this one
holds the design the code answers to, what is converted, and what bit us.

## The model — what the kinds ARE

This is the agreed design, and it is the thing to check an implementation
against. If the code and this section disagree, that is a bug in one of them
and worth resolving explicitly rather than quietly following the code.

    Source     produces onto a circuit, given whatever drives it
    Converter  consumes from one circuit, produces onto another
    Storage    a source that DEPLETES while supplying - the time-limited kind
    Circuit    a named node carrying a VALUE; consumers threshold it themselves
    Consumer   fed by a SET of circuits; supplied if ANY of them is up
    Reservoir  a consumable that leaks when damaged and starves its consumers

Domain-agnostic by design: `drivenBy` and `input` reference circuits in ANY
domain, which is what makes an electrically-driven hydraulic pump or an
engine-driven generator expressible without Core knowing either exists.

`Consumer` is what makes redundancy declarative rather than hardcoded - flight
controls on two circuits keep working when one dies, while SAS on one circuit
does not. Without it, every "which failures survive which" rule goes back to
being an if-chain naming this airframe's specific circuits.

**A component is a physical thing** - the APU, a generator, a pump, the
accumulator. What it PUTS OUT is not a component: an APU that drives the
accessory section and supplies bleed air is one component with two outputs.

**As built**, against the above:

| design | built as | note |
|---|---|---|
| Source | `fn_systemProducer` | renamed; same job |
| Converter | `fn_systemConverter` | |
| Storage | `fn_systemStorage` | |
| Circuit | `fn_systemCircuit` + `fn_systemCircuitState` | reading a node and reporting it are separate |
| Consumer | `fn_systemConsumer` | |
| Reservoir | folded into Storage | a reservoir is a store that leaks; agreed, not an accident |

## Where it stands

| domain | state |
|---|---|
| hydraulics | **converted and flown** - pumps, reservoirs, accumulator, accessory drive |
| electrical | not started; the generator and rectifier declarations exist but the old functions still run |
| drivetrain | not started |
| fuel | stays separate - it set the pattern the kinds follow |

Core runs one function per KIND rather than per system, so a pump and a
generator are the same code with different declarations:

```
fn_systemProducer   damage, gate, drive and consumable -> a value on a circuit
fn_systemStorage    a producer holding a charge, which drains and refills
fn_systemConsumer   supplied if ANY of its circuits is up, or all with needsAll
fn_systemCircuit    a named node; highest feeder wins
fn_systemsSolve     storage, producers, storage settle, consumers
fn_systemsComponents  config -> hashmaps, once, at init
```

Member count comes from the damage role, and damage is read AT THE MEMBER'S
INDEX - the role alone returns the worst member, which would fail all three
generators because one is destroyed. That was the bug that started this.

## What is left

**Electrical.** The larger conversion: around 27 external readers of
`acBusOn`, `dcBusOn`, `battBusOn`, `gen1On` and `rect1On` across ten addons.
Every name survives through `variableName`, but that is the thing to verify
rather than assume.

- battery as storage, `rechargedBy[] = {"AC"}` - the charging bus is the
  airframe's choice, DC on an aircraft wired that way
- `stopBelow` expresses the existing 0.25 cutoff
- `emerDischarge = 720`, from `elecBattTimerMin`
- AC and DC buses become circuits, replacing both bus functions
- `helisim_electrical.hpp` disappears, being one value

**Drivetrain.** Nose gearboxes are the last duplicated pair. Note the
transmission has no accessory LOAD - nothing subtracts torque for pumps or
generators - and transmission damage does not affect its output.

**Per-domain configs fold into `helisim_components.hpp` as each converts**, the
way `helisim_hydraulics.hpp` already did. Hitpoints stay separate: `class
HitPoints` has to live inside the vehicle class where Arma requires it, and
`damageRole` is the join. That indirection earns its place - it is what lets
member count come from hitpoint count.

## Things that caught us

Worth knowing before converting another domain.

**Damage by role returns the WORST member.** Reading it without an index fails
every member because one is broken.

**Absent is not failed.** A role nothing claims means the airframe does not
have that component. Declaring NO role is different - present, but not
separately damageable, like an accumulator with no p3d selection. Undeclared
circuits must publish NOTHING rather than zero, so the read-side defaults that
keep a no-hydraulics airframe flying still fire.

**Multiplayer fails silently.** The solve runs where the aircraft is local;
everything else reads published results. The per-frame scheduler runs for the
pilot OR gunner of the aircraft they occupy, so a gunner is a genuine remote
reader. Anything a crew station displays needs `networked = 1` or it is frozen
for them - and singleplayer looks perfect either way.

**Rates defined over the wrong range.** Twice: a start draw that left the store
above its own advisory threshold, and a recharge that finished in half its
configured time because the rate spanned 0..1 while the store only moves
through the usable band above its floor. If a number does not produce the
behaviour it names, check what range it is defined over.

**`_x` shadowing.** An inner `forEach` rebinds `_x`, so a component read after
one silently reads the wrong thing. Bit both storage and consumers; bind the
component to `_comp` first.

**Ordering within the solve.** Storage supplies before anything is solved,
because charge is state - that is what cuts the accumulator -> APU -> pumps ->
accumulator startup loop. But charge can only MOVE once the rest has solved, so
draining and refilling are a settle pass at the end. Getting that wrong left
the accumulator reading zero forever.

## Not yet flown

- multiplayer with a CPG in the aircraft, which is the half never exercised
- the `bmkhs_utilHydPsi` casing fix, which switched on gun and pylon servo
  failure logic that had never run

## Controls are components too — later, but plan for it

Not for this phase, but the design has to leave room or it gets retrofitted.

Every gate names a control: `bmkhs_emerHydOn`, `bmkhs_battSwitchOn`,
`bmkhs_apuBtnOn`. A switch is a component with state, a hitpoint and a place in
the graph, and should be declared once to produce three things: the variable a
gate reads, the keybind, and the cockpit interaction.

`CfgUserActions.hpp` already has `BMKHS_ANALOG` / `BMKHS_NONANALOG` /
`BMKHS_ACTION`, each generating a keybind and its dispatch together. What is
missing is switch BEHAVIOUR - everything is momentary, so anything else is
hand-written SQF.

| kind | behaviour |
|---|---|
| momentary | on while held - what exists today |
| latching | press toggles, stays where it is put |
| momentary-one-way | springs back from one position (start switch) |
| multi-position | N discrete positions, stepped or selected |
| guarded | needs the cover lifted first |

`fn_interactPowerLever` shows the gap: OFF / IDLE / FLY as an if-chain, once
per engine.

**Power levers and throttles are not switches, and not each other.**

| | power lever | throttle |
|---|---|---|
| what | engine condition - a fuel gate | continuous power modulation |
| range | detented positions | smooth 0-1 |
| use | set once per phase of flight | flown continuously |

An aircraft may have one, both or neither - the AH-64 has no throttle at all
because the governor holds Nr. So a power lever is a detented axis: a
continuous range whose marked positions are what the systems model reads,
wanting an analog binding as well as step-to-detent keys.

The wrinkle to design around: **keybinds are config-time and static** while
component counts are aircraft-declared. Three engines needs three power-lever
binds generated from a count the aircraft chooses, and that is the part most
likely to catch us if controls are bolted on afterwards.
