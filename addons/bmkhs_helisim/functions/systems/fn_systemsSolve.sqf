/* ----------------------------------------------------------------------------
Function: bmkhs_fnc_systemsSolve

Description:
    One pass over the component graph, in a fixed order:

      1. storage    charge is state, so it supplies before anything is solved,
                    which cuts the accumulator -> APU -> pumps -> accumulator
                    startup loop
      2. producers  resolve against circuits the stores have fed
      3. consumers  threshold what ended up on theirs

    Producers run twice so one driven by another circuit does not read a stale
    value. Cheaper than sorting a graph this small.

Parameters:
    _heli      - The helicopter [Object]
    _deltaTime - Frame time [Number]

Returns:
    Nothing

Author:
    BradMick
---------------------------------------------------------------------------- */
params ["_heli", "_deltaTime"];

//Rebuilt each pass - a node holds only what its feeders put there this frame.
private _circuits = createHashMap;
{ _circuits set [_x, 0] } forEach (keys (_heli getVariable ["bmkhs_sysCircuits", createHashMap]));

//Nr comes from the flight model, not a component, so it is seeded before anything reads
//it. The accessory drive and everything mechanical hangs off it.
_circuits set ["ROTOR", [_heli] call bmkhs_fnc_stateRtrRPM];

_heli setVariable ["bmkhs_sysCircuits", _circuits];

[_heli, _deltaTime] call bmkhs_fnc_systemStorage;
[_heli, _deltaTime] call bmkhs_fnc_systemProducer;
//deltaTime 0: re-resolves dependencies without advancing a ramp twice in one frame.
[_heli, 0]         call bmkhs_fnc_systemProducer;
[_heli]            call bmkhs_fnc_systemConsumer;
