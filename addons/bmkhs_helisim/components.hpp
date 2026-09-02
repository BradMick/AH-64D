#ifndef BMKHS_HELISIM_COMPONENTS_HPP
#define BMKHS_HELISIM_COMPONENTS_HPP

//BMKHS component model - what an airframe declares, and what Core does with it.
//
//The AIRCRAFT declares what it has; Core declares nothing and knows no airframe. A
//component names the damage role it answers to, and the hitpoints claiming that role ARE
//its members - so a third generator hitpoint gives a third generator with no code change.
//Declaring no role means the component exists but cannot be damaged separately.
//
//Circuits are named nodes carrying a value in whatever unit the domain uses - psi, volts,
//Nr as a fraction. The names are the aircraft's to choose; Core matches them as strings.
//Several feeders on one node take the HIGHEST value rather than summing.
//
//Every reference to a circuit carries its own threshold:
//
//    drivenBy[]    = {"ACCESSORY_DRIVE", 0.45};   //below this it has no drive
//    drivenBy[]    = {"AC"};                      //any value at all will do
//    suppliedBy[]  = {{"PRI_HYD", 1260}, {"UTIL_HYD", 1260}};
//
//Durations are in seconds, never rates - Core converts once at init.
//
/////////////////////////////////////////////////////////////////////////////////////////////
// ONE CLASS, MANY MEMBERS - how count works
/////////////////////////////////////////////////////////////////////////////////////////////
//
//A class is a KIND of component, not one of them. How many exist comes from the hitpoints
//claiming its damage role, so one declaration covers any count:
//
//    class Generator { damageRole = "generators"; variableName = "gen"; ... };
//
//    hit_elec_generator1  "generators" 0   ->  bmkhs_gen1
//    hit_elec_generator2  "generators" 1   ->  bmkhs_gen2
//    hit_elec_generator3  "generators" 2   ->  bmkhs_gen3
//
//Add the third hitpoint and there is a third generator - no config change here, no code
//change in Core. Declare none and the component does not exist on this airframe.
//
//Each member is independent: its own damage, its own state, its own contribution to the
//circuit. Two healthy generators and one destroyed still hold the bus up, because the
//highest feeder wins the node.
//
//ONE CLASS PER JOB, NOT PER UNIT. Two generators are two of the same thing on the same
//bus, so they are one class. The primary and utility pumps are different jobs feeding
//different circuits, so they are two classes even though both are pumps. The test is
//whether they share a damage role AND a circuit.
//
//Consumers are not per-member. acBusOn is one consumer of the AC circuit however many
//generators feed it, which is why adding one needs no consumer change.
//
//NAMING TRAP: the member number only appears when there IS more than one, so a single
//battery publishes bmkhs_battPower_pct and a second one would silently rename it to
//bmkhs_battPower_pct1 - breaking every external reader. Choose variableName for the count
//the role might reach, not the count it has today. "gen" is safe because it is already
//written as one of several; "priHydPsi" is safe because an airframe has exactly one
//primary pump by definition.
//
/////////////////////////////////////////////////////////////////////////////////////////////
// NETWORKING - read this before declaring anything a crew station displays
/////////////////////////////////////////////////////////////////////////////////////////////
//
//The graph is SOLVED on the machine the aircraft is local to. Every other machine reads
//the published results, so any state a crew station displays or acts on must be declared
//networked or it will be stale for everyone but the pilot.
//
//This fails SILENTLY in singleplayer: the gunner's page is correct locally and frozen in
//multiplayer. If a value is read outside the flight model, network it.
//
//    networked = 1;   an MPD page, a caution, a warning light, a weapon interlock
//    (default)        flight-model state consumed on the machine that computes it
//
//Networked state publishes through a change-gated helper, so it only sends when the value
//actually differs. Pair it with `increment` on anything continuous - rounding pressure to
//tens instead of single psi cuts traffic during a ramp by roughly a factor of ten.
//
/////////////////////////////////////////////////////////////////////////////////////////////
// PRODUCERS - pumps, generators, the APU: anything that feeds a circuit
/////////////////////////////////////////////////////////////////////////////////////////////
//
//  damageRole    hitpoint role whose members are this component's; "" for undamageable
//  variableName  what it publishes as, per member. Core owns the bmkhs_ prefix, and
//                numbers members only when there is more than one: gen1On, gen2On, but
//                priHydPsi on its own
//  output        circuit it feeds
//  drivenBy[]    circuit that must be turning or live, with its threshold
//  driveFrom     variable its output follows 0..1, for something that spools rather than
//                switching on - an APU drives its accessories as it comes up to speed
//  disengageAbove circuit and threshold above which it stops producing, for a clutch.
//                An APU declutches once the rotor is driving the accessories itself, so
//                it keeps running while contributing nothing. Compared live, not latched,
//                so it picks the load back up on the way down - an APU left running
//                through an engine failure carries the accessories again as Nr decays
//  passthrough   1 to pass its drive value along instead of nominal, for a shaft
//  requires      level variable it draws from; SCALES output rather than gating it, so a
//                leaking reservoir shows as falling pressure rather than a cliff
//  requiresAbove level below which it has nothing left to move and produces nothing
//  gate[]        switches that must ALL be on; omit for always armed. A gated component
//                that is off is not failed - it just contributes nothing. An APU needs
//                its button, the battery bus, fuel and accumulator pressure together
//  nominal       what it produces at full output
//  rampSeconds   zero to full; 0 is instant. A pump builds pressure, a contactor does not
//  increment     round the published value to this step, as a real gauge reads
//  stateName     publishes whether this component is RUNNING, which is a property of the
//                component and not of any circuit - an APU is on above a threshold, the
//                way an engine publishes its own state. Always networked
//  stateAbove    output at or above which it counts as running
//  networked     see above
//  needsSystems  1 if this is only modelled when the aircraft sets useSystems. With
//                systems off it is not simulated and its state stays as seeded, which is
//                the vanilla contract - powered up, running, no start procedure. Startup
//                systems set this; flight-model infrastructure does not
//
/////////////////////////////////////////////////////////////////////////////////////////////
// STORAGE - accumulators, batteries, reservoirs: a producer holding a charge
/////////////////////////////////////////////////////////////////////////////////////////////
//
//Charge is state rather than supply, so storage is solved FIRST and can feed a circuit
//before anything upstream has been solved. That is what makes a cold aircraft startable:
//an accumulator cranks the APU, and the APU turning the pumps refills it.
//
//A store DRAINS while nothing is covering for it - its charging circuit where it has one,
//otherwise whatever else feeds its output - and REFILLS when something is.
//
//Takes every producer field, plus:
//
//  rechargedBy[]  circuit that refills it, with its threshold. Never name the circuit it
//                 feeds, or it will top itself up forever
//  startedBy      gate of something it cranks; spends its usable charge when that rises
//  startAbove     value it must reach for that start to happen at all
//  stopBelow      value it stops discharging at. For a gas-charged store this is the
//                 precharge, which is not usable pressure
//  startRecharge  seconds to refill, once its recharge circuit is up
//  emerDischarge  seconds full to empty while supplying as an emergency source
//  leakStartDmg   damage at which it starts leaking; 0 for never
//  leakSeconds    full to empty at FULL damage, ramping from the threshold, so a light hit
//                 weeps and a bad one dumps. Destroyed empties at once
//  drainedBy[]    other damage roles that vent this store - a gun or pylons sharing a
//                 reservoir add to its damage rather than being a second mechanism
//
/////////////////////////////////////////////////////////////////////////////////////////////
// CIRCUITS - state Core publishes about a node
/////////////////////////////////////////////////////////////////////////////////////////////
//
//A bus being up is a fact about the circuit, not something drawing from it, so it is
//declared here rather than as a consumer. This is how acBusOn, apuOn and the rest reach
//everything outside Core.
//
//  variableName  what it publishes as
//  circuit       the node it reports on
//  minValue      value at or above which it reads as up
//  networked     see above
//  needsSystems  see above
//
/////////////////////////////////////////////////////////////////////////////////////////////
// CONSUMERS - anything that needs supply to work
/////////////////////////////////////////////////////////////////////////////////////////////
//
//Not for reporting a circuit - use a Circuit for that. A consumer is a thing that stops
//working without supply: flight controls, a tail rotor.
//
//  variableName  what it publishes as
//  suppliedBy[]  circuits that can feed it, each with its threshold
//  needsAll      1 to require all of them; default is ANY, so a consumer naming two
//                circuits survives losing one and a consumer naming one dies with it.
//                Entries may span units - a pressure and a level in the same set
//  networked     see above
//
//Core publishes whether a consumer has supply. What that MEANS is the aircraft's business:
//Core reports the primary circuit is at 0 psi, the aircraft decides whether that warrants
//a caution and whether it is expected on the ground.

#endif
