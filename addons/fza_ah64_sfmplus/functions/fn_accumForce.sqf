/* ----------------------------------------------------------------------------
Function: fza_sfmplus_fnc_accumForce

Description:
    Records ONE force generator's total force for the frame into a shared, self-
    registering accumulator (the hashmap fza_sfmplus_forceAccum, keyed by generator
    name). fn_getAccelerations sums every entry in that map to get the net body
    force, then divides by mass to get the body-frame acceleration (the JSBSim
    vBodyAccel = Force/Mass model, gravity excluded - gravity is not applied by the
    generators, so the accumulated sum is force-only, matching JSBSim).

    SELF-CONTAINED per generator: each generator OVERWRITES its own named entry with
    its complete frame total (it accumulates its own elements into a LOCAL first,
    then writes once). Because it overwrites (not adds-across-frames), the map always
    holds the CURRENT frame's per-generator totals - no central per-frame reset is
    needed, and the accumulation is surface-agnostic. Adding a new surface just means
    calling this once with a new name; it appears in the map automatically.

    Pass the RAW per-second force (Newtons, NOT the *deltaTime value used for the
    engine addForce call), in MODEL space (X=right, Y=forward, Z=up), so Force/Mass
    is a true acceleration comparable across generators.

Parameters:
    _heli  - The aircraft [Object].
    _name  - Short generator label [String] (e.g. "Main Rotor", "Right Wing").
    _force - The generator's TOTAL raw force for this frame, model space [Array] [X,Y,Z].

Returns:
    Nothing.

Author:
    BradMick
---------------------------------------------------------------------------- */
params ["_heli", "_name", ["_force", [0,0,0]]];

if (isNull _heli) exitWith {};

private _map = _heli getVariable ["fza_sfmplus_forceAccum", createHashMap];

_map set [_name, _force];
_heli setVariable ["fza_sfmplus_forceAccum", _map];