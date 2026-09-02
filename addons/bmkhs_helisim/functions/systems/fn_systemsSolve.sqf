/* ----------------------------------------------------------------------------
Function: bmkhs_fnc_systemsSolve

Description:
    One pass over the component graph.

    Order matters and is fixed rather than sorted, because the dependency
    shape is the same on every aircraft:

      1. storage    charge is STATE, so a store can supply before anything
                    upstream is solved. This is what cuts the startup loop -
                    the accumulator starts the APU, the APU drives the pumps,
                    the pumps refill the accumulator - into something walkable.
      2. producers  gates, drives and consumables resolve against circuits the
                    stores have already put a value on.
      3. consumers  threshold whatever ended up on their circuits.

    Producers run twice. A producer driven by a circuit that another producer
    feeds - a backup pump behind the DC bus behind a generator - would
    otherwise read a stale value on the frame something changes. Two passes
    covers the depth this model actually has; it is cheaper than sorting a
    graph this small and it settles in one frame instead of two.

Parameters:
    _heli      - The helicopter [Object]
    _deltaTime - Frame time [Number]

Returns:
    Nothing

Author:
    BradMick
---------------------------------------------------------------------------- */
params ["_heli", "_deltaTime"];

//Circuits are rebuilt from scratch each pass - a node holds what its feeders put
//there this frame, never what they put there last frame.
private _circuits = createHashMap;
{ _circuits set [_x, 0] } forEach (keys (_heli getVariable ["bmkhs_sysCircuits", createHashMap]));

//Rotor speed comes from the flight model rather than from a component, so it is seeded
//onto its circuit before anything reads it. Everything mechanical hangs off this: the
//accessory drive, and through it the pumps and generators.
_circuits set ["ROTOR", [_heli] call bmkhs_fnc_stateRtrRPM];

_heli setVariable ["bmkhs_sysCircuits", _circuits];

[_heli, _deltaTime] call bmkhs_fnc_systemStorage;
[_heli, _deltaTime] call bmkhs_fnc_systemProducer;
//Second pass so a producer behind another producer's circuit sees this frame's value.
//deltaTime 0 - this pass re-resolves the dependencies WITHOUT advancing any ramp,
//which would otherwise integrate twice in one frame and double every rate.
[_heli, 0]         call bmkhs_fnc_systemProducer;
[_heli]            call bmkhs_fnc_systemConsumer;
