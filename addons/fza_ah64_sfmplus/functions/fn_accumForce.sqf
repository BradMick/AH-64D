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

//WORLD-SPACE MIRROR - for the accelerometer / slip ball ONLY. The model-space map above is
//unchanged and is still what the force table and every tuned scalar read.
//
//WHY: the FM computes forces in BODY axes and hands them to Arma, which applies them with
//vectorModelToWorld - so the aircraft's ATTITUDE is applied by that rotation, not by the FM. The
//body-space value therefore does not contain the lateral force a banked rotor actually produces:
//measured in a 27 deg turn, the accumulator held ~131 N of lateral where the physics applied
//~1560 N. Anything derived from the body-space sum is missing ~90% of the lateral force in a
//bank, which is why the ball read correctly upright and pegged in turns.
//
//Rotating each contribution here, at the moment it is registered, captures exactly what the
//engine was handed. No reconstruction formula, no tilt term, no scale factor to keep in sync with
//the flight model - the instrumentation reads the same numbers the physics does.
//
//ROTATE ONLY - do NOT use vectorModelToWorld here. That transforms a POSITION: it rotates AND
//TRANSLATES, adding the aircraft's world coordinates to the vector. For a force that is
//meaningless, and since the sum runs over ten generators it left nine copies of the aircraft's
//position in the total - which is why the lateral force came out ~12% of what a banked turn needs
//and the result was sign-inverted.
//
//A force is a DIRECTION, so it must be rotated by the aircraft's orientation with no translation.
//Build it from the orientation vectors directly: world = x*right + y*forward + z*up.
private _dirF  = vectorDir _heli;      //forward, world
private _upF   = vectorUp  _heli;      //up, world
private _rightF = _dirF vectorCrossProduct _upF;   //right, world
private _fWorld = (_rightF vectorMultiply (_force # 0))
    vectorAdd (_dirF vectorMultiply (_force # 1))
    vectorAdd (_upF  vectorMultiply (_force # 2));

private _mapW = _heli getVariable ["fza_sfmplus_forceAccumWorld", createHashMap];
_mapW set [_name, _fWorld];
_heli setVariable ["fza_sfmplus_forceAccumWorld", _mapW];
