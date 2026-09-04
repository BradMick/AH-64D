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

## Scheduling — dirty-flag propagation

This is the agreed design and the reason for the redesign. **Built and flown** -
a cold start propagates end to end: APU spools, drives the accessory section,
pumps pressurise both sides, generators feed AC, rectifiers feed DC, the
accumulator recharges.

It was specified once, then not built - signature polling went in instead, which
cost frame rate rather than saving it and left the APU unable to start. This
section was restored from `c8e685dde`, where it was the only surviving copy,
so the document can contradict the code again.

**Systems sleep until something changes.** Most components are pure state
functions recomputing an unchanged answer 60 times a second. A rectifier is
`generatorOn && damage <= threshold` — it can only change when one of those
changes.

**Continuous is a runtime answer, not a static property.** The timer-driven
components are not always integrating either:

| component | integrates only while |
|---|---|
| battery | on battery bus AND AC bus down |
| APU | spooling up or down, not at steady RPM |
| reservoir | actually leaking |
| accumulator | bleeding down |
| transmission | over a torque limit |

On a healthy running aircraft **none of these are integrating**, so steady-state
cost should approach zero.

The scheduler that expresses this: an update returns whether it wants the next
frame.

```sqf
//true = keep me scheduled, false = sleep until a dependency changes
[_heli, _index, _deltaTime] call bmkhs_fnc_systemProducer
```

Dirty-flag propagation wakes a sleeping component when a dependency changes; a
component that is mid-transition keeps itself awake by returning true. Damage
changes are just another dependency.

**As built.** `fn_systemsComponents` derives the graph at load from the fields a
component already declares — `gates`, `drivenBy`, `input`, `requires`,
`rechargedBy`, `disengageOn` — rather than a separate `dependsOn` that could
drift from what the code actually reads. Two indices come out of it:
`bmkhs_sysReaders` maps a circuit to the components reading it, and
`bmkhs_sysWatchers` maps a variable to the components gated on it.

`fn_systemsSolve` then walks from what changed: variables whose value moved,
damage that moved, Nr, and anything that asked for another frame. Each component
that moves its own node dirties whatever reads that node, which appends to the
queue, so the walk reaches exactly as far as the change does and stops.

**Ordering falls out of the walk**, which is what removed the fixed
`SYS_SOLVE_PASSES` re-resolve and the `deltaTime = 0` passes that went with it.
A topological sort was never possible anyway: the accumulator starts the APU,
which drives the accessory section, which turns the pumps, which recharge the
accumulator. What cuts the cycle is that **charge is state, not supply** — a
store delivers what was put there earlier, so it is a root of the walk and its
recharge edge settles afterwards from the walk's own result.

Circuit states and consumers feed nothing, so they are not in the walk; the
solve publishes them from the settled graph, which also stops a node that fell
quiet from keeping its last published state.

## Where it stands

| domain | state |
|---|---|
| hydraulics | **converted, flown** - pumps, reservoirs, accumulator, accessory drive |
| electrical | **converted, flown** - battery, generators, rectifiers, buses |
| APU | **converted, flown** - one component, driving accessories and bleed air |
| drivetrain | **converted, flown** - transmission, gearboxes, torque limits, damage model |
| scheduling | **built, flown** - dirty propagation; see below |
| fuel | stays separate - it set the pattern the kinds follow |
| controls | **not started** - switches and power levers, the last piece |

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
fn_systemTorqueJitter  what a damaged drive is doing to an engine's torque needle
fn_systemCircuitFeed   records one feeder's contribution to a node
fn_systemsSolve        dirty walk from what changed; storage roots it, charge settles last
fn_systemsComponents   config -> hashmaps, once, at init
```

Member count comes from the damage role, and damage is read AT THE MEMBER'S
INDEX - the role alone returns the worst member, which would fail all three
generators because one is destroyed. That was the bug that started this.

## Drivetrain damage — the model, written down

This was deleted once by the conversion and rebuilt from the old code, so it is
recorded here rather than living only in `fn_systemTorque`.

A component declares its tiers worst-first as `{torque, grace seconds, divisor}`,
torque being a fraction of rated. A tier's clock runs **only while the torque is
in that tier** and resets the moment it leaves, so time spent higher up does not
spend a lower tier's grace and a brief excursion is not cumulative. 0 seconds
means no grace at all.

Once any tier's clock expires, the rate is the **sum over every exceeded tier**
of `(torque - limit) / divisor`. So it scales with the abuse - pulled harder, it
comes apart faster - rather than being a flat rate whatever the overtorque.
Nothing accrues with the engines off.

Damage feeds itself past 25%: the persistent rate is `damage/600`, `/500` or
`/400` by band, and the bands **replace** each other rather than stacking.

`breaksOnFailure[]` is what a destroyed component takes with it. An entry naming
a damage role destroys that role outright - the transmission is what holds the
rotors, the generators and the pumps up. An entry naming a `bmkhs_` variable
sets it at the member's index instead, which is how a nose gearbox that has come
apart overspeeds its engine.

`jittersTorque` makes a damaged drive wander the torque needle. The component
publishes its OWN wander under its own variable and `fn_systemTorqueJitter` sums
what reaches a given engine - its own component plus any that carries every
engine. The old shared four-slot array was the "exactly two of everything,
indexed by hand" assumption this refactor exists to remove.

**The AH-64's ratings.** Transmission, both engines summed: 200% continuous, 200
to 230 for six seconds, above 230 at once. Nose gearboxes, per engine and rated
**single-engine only** - with both running neither carries enough to hurt it -
110% continuous, 110 to 122 for two and a half minutes, 122 to 125 for six
seconds, above 125 at once.

### With no systems modelled

`useSystems = 0` does exactly one thing: overtorque damages `hithrotor` and
`hitvrotor`. Nothing else. No overspeed, no cascade, no jitter - there are no
systems to fail. Limits come from `xmsnTqLimits` and `ngbTqLimitsSE` at the top
level, which are read **only** on this path; with systems on the components
carry their own. Damage is read back off the rotor hitpoints, so battle damage
and overtorque are one number and a shot-up rotor is fragile under torque.

## What is left

**Controls as components — the next piece of work.** Switches and power levers,
the last domain still hardcoded. See `CONTROLS_AS_COMPONENTS.md`.

**Frame rate is unconfirmed.** Observed more stable and not dropping after the
dirty walk went in, but that is an impression, not a measurement, and it needs
much more testing. The honest number is not FPS - it is how many components the
walk runs per frame, which should be near zero on a settled aircraft and spike
only when something changes. That counter is not in the debug panel yet.

**Multiplayer with a CPG.** Never exercised, in any domain. The gunner is a
genuine remote reader of everything a crew station displays, so anything missing
`networked = 1` is frozen for them while singleplayer looks perfect.

**Repair, now event-driven and generic.** A `HandleDamage` handler in
`fn_coreInit` flags a repair when a hitpoint goes down, and `fn_repair` exits
unless it sees that flag. It walks the declared components rather than naming
any, so it restores whatever the airframe has. Worth confirming a repaired
component gets its state back, and that ordinary damage still applies - the
handler sits in the damage path for everything.

The accumulator refills on any repair, having no hitpoint of its own. That is
correct while nothing else charges it: the recharge path off the accessory drive
works, but a ground cart or hand pump is not implemented.

**Overtorque with no drivetrain declared.** The top-level ratings damage
`hithrotor` and `hitvrotor` directly, since no role claims them. Never flown.

**Everything now runs from the pack.** `fn_perFrame` calls systemsUpdate,
coreUpdate, coreUpdateFlightModel, ctrlVisUpdate and repair. Four of those moved
out of `fza_ah64_controls`, and `ctrlVisUpdate` moved from a Draw3D context to
per-frame.

**What still is not standalone:** the scheduler that calls `fn_perFrame` lives in
`fza_ah64_controls` and is gated on `vehicle player` and
`isKindOf "fza_ah64base"`. So a second airframe needs its own, and AI or
unoccupied aircraft run no systems at all.

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

**A store must compare against OTHER sources, not the whole node.** Storage asks
whether anything else already supplies its output circuit before feeding it. Once
contributions persist between frames - which is what lets a component sleep - a
store reading the node total reads its OWN supply back, decides it is covered,
and cuts its feed. The battery did this to `BATT`, dropping it at the instant the
APU evaluated its gate, so the APU would not start while the panel showed every
gate passing. Read `bmkhs_sysProducerFeed_<circuit>`, never
`bmkhs_fnc_systemCircuit`.

**A debug panel that re-derives conditions can disagree with the component.** The
panel evaluated gates live while the component evaluated them when it ran; both
looked correct alone. Have the component record the terms it actually used.

**`_x` is rebound by every inner `forEach`.** Any component-field read after a
loop over gates or outputs must use a captured `_comp`, and `_forEachIndex` must
be captured too. This was fixed in three kind files and then reintroduced twice
in the graph builder written one commit later.

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
