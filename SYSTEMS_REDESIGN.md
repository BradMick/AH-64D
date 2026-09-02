# Systems redesign — converted

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
| — | `fn_systemTorque` | not in the original design: overtorque damage, which is a component property but not a supply one |

## Where it stands

| domain | state |
|---|---|
| hydraulics | **converted, flown** - pumps, reservoirs, accumulator, accessory drive |
| electrical | **converted, flown** - battery, generators, rectifiers, buses |
| APU | **converted, flown** - one component, driving accessories and bleed air |
| drivetrain | **converted, flown** - transmission, gearboxes, torque limits |
| fuel | stays separate - it set the pattern the kinds follow |

Nineteen hardcoded functions replaced by declarations, and four per-domain
configs absorbed into `helisim_components.hpp`, which is now the single place an
airframe says what it has.

Core runs one function per KIND rather than per system, so a pump and a
generator are the same code with different declarations:

```
fn_systemProducer      damage, gate, drive and consumable -> a value on a circuit
fn_systemConverter     takes from one circuit, feeds another; creates nothing
fn_systemStorage       a producer holding a charge, which drains and refills
fn_systemConsumer      supplied if ANY of its circuits is up, or all with needsAll
fn_systemCircuit       a named node; highest feeder wins
fn_systemCircuitState  publishes whether a node is up
fn_systemTorque        damages anything run past its limits
fn_systemsSolve        storage, producers+converters, storage settle, circuits, consumers
fn_systemsComponents   config -> hashmaps, once, at init
```

Member count comes from the damage role, and damage is read AT THE MEMBER'S
INDEX - the role alone returns the worst member, which would fail all three
generators because one is destroyed. That was the bug that started this.

## What is left

**Multiplayer with a CPG.** Never exercised, in any domain, and the only
untested path left. The gunner is a genuine remote reader of everything a crew
station displays, so anything missing `networked = 1` is frozen for them while
singleplayer looks perfect.

**`breaksOnFailure` has one user.** A nose gearbox overspeeding its engine is
the only damage propagation declared, so the shape is unproven - worth a second
case before trusting it.

**The tail rotor needs two consumers**, because its failure modes do not
combine: hydraulic authority is an either-or across two circuits, the drive is a
chain that must be intact. One consumer cannot express both, so `fn_inputUpdate`
reads both. It works, but it is the model bending rather than fitting.

**Hitpoints stay separate.** `class HitPoints` has to live inside the vehicle
class where Arma requires it, and `damageRole` is the join. That indirection
earns its place - it is what lets member count come from hitpoint count.

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

**Chains run deeper than one hop.** Nr feeds the transmission feeds the
accessory drive feeds the pumps; a generator feeds AC feeds a rectifier feeds
DC. Producers and converters re-resolve `SYS_SOLVE_PASSES` times so a chain
settles in one frame rather than lagging.

**A gate that reads a variable published later in the same solve is a frame
stale**, and that can deadlock a start. Gates can name a circuit instead, which
reads the live value.

**Change-detect needs a default the value can differ from.** Making a state
notify fire only on a change broke it outright: the previous value defaulted to
the current one, so the first comparison was always equal and the event never
fired at all.

**A threshold the model passes through legitimately is not a failure.** The
engine flips to ON at `engRunNG`, which is below the engine-out warning
threshold, so every start tripped the warning on the way up. Wait for the
condition to have been true once before believing it can be false.

**Conditions dropped in conversion are invisible.** The nose gearbox torque
check was wrapped in `isSingleEng`; losing that would have damaged gearboxes in
normal two-engine flight. Read what the old function GUARDED, not only what it
did.

## useSystems = 0

Nothing is simulated. The solve exits, so no hydraulics spool, no buses come
up, no APU exists - the engines and transmission still run because they are the
flight model, and everything else stays at its seeded value. There is no damage
model either, since a system exists because hitpoints declare it.

The aircraft spawns cold and dark and wakes on the player's first collective or
throttle input, spooling over ten seconds. Torque limits still apply: they run
outside the solve, and the ratings sit at the top level beside `useSystems` so
an airframe that declares no components at all still respects them.

## Controls are components too — the remaining piece

Every other domain is converted, so this is what is left of the redesign. Not
started, and the design has to leave room for it or it gets retrofitted.

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
