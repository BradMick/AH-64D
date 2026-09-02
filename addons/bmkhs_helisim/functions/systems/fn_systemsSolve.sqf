/* ----------------------------------------------------------------------------
Function: bmkhs_fnc_systemsSolve

Description:
    One pass over the component graph, in a fixed order:

      1. storage    charge is state, so it supplies before anything is solved,
                    which cuts the accumulator -> APU -> pumps -> accumulator
                    startup loop
      2. producers  resolve against circuits the stores have fed, and converters
                    move what they made onto other circuits
      3. storage    drains and refills from what actually solved
      4. circuits   publish the state of any node the aircraft named
      5. consumers  threshold what ended up on theirs

    Storage runs twice: once to put its charge onto circuits, once at the end to
    move that charge from the solved result. Producers run twice so one driven
    by another circuit does not read a stale value.

Parameters:
    _heli      - The helicopter [Object]
    _deltaTime - Frame time [Number]

Returns:
    Nothing

Author:
    BradMick
---------------------------------------------------------------------------- */
params ["_heli", "_deltaTime"];
#include "\bmkhs_helisim\functions\systems\systems.hpp"

//Solved once, where the aircraft is local. Everyone else reads the networked results,
//which is what stops every client computing the same state and fighting over it.
if !(local _heli) exitWith {};

//An aircraft that does not model systems does not solve them. Nothing is published, so
//every consumer falls back to its own default and the aircraft flies with full authority.
//That is the same path a bare airframe takes by declaring no components at all - a
//designer who only wants the flight model should not have to declare anything.
//
//Nothing is lost by not solving: a system exists because hitpoints declare it, so an
//airframe with no systems has nothing that could fail in the first place.
if !(_heli getVariable ["bmkhs_useSystems", false]) exitWith {};

//Rebuilt each pass - a node holds only what its feeders put there this frame.
private _circuits = createHashMap;
{ _circuits set [_x, 0] } forEach (keys (_heli getVariable ["bmkhs_sysCircuits", createHashMap]));

//Nr comes from the flight model, not a component, so it is seeded before anything reads
//it. The accessory drive and everything mechanical hangs off it.
_circuits set ["Nr", [_heli] call bmkhs_fnc_stateRtrRPM];

_heli setVariable ["bmkhs_sysCircuits", _circuits];

//Producer contributions are tracked per node so storage can tell its own supply apart.
{ _heli setVariable ["bmkhs_sysProducerFeed_" + _x, 0] } forEach (keys _circuits);

[_heli, _deltaTime]        call bmkhs_fnc_systemStorage;
[_heli, _deltaTime]        call bmkhs_fnc_systemProducer;
[_heli, _deltaTime]        call bmkhs_fnc_systemConverter;
//Re-resolved until the graph settles: a producer behind another producer's circuit reads
//a stale value otherwise, and the chains run deeper than one hop - the transmission feeds
//the accessory drive feeds the pumps, and a generator feeds AC feeds a rectifier feeds DC.
//deltaTime 0 so re-resolving does not advance a ramp more than once in a frame.
for "_i" from 1 to SYS_SOLVE_PASSES do {
    [_heli, 0] call bmkhs_fnc_systemProducer;
    [_heli, 0] call bmkhs_fnc_systemConverter;
};
//Charge moves last, off the solved result - a store reading its recharge circuit any
//earlier sees zero and never refills.
[_heli, _deltaTime, true]  call bmkhs_fnc_systemStorage;
[_heli]                    call bmkhs_fnc_systemCircuitState;
[_heli]                    call bmkhs_fnc_systemConsumer;
