/* ----------------------------------------------------------------------------
Function: fza_sfmplus_fnc_forceLog

Description:
    Records one force generator's contribution for the tuner's force/moment
    readout. Called by each instrumented generator right where it applies its
    force, in MODEL space (the frame the generators already work in: X=right,
    Y=forward, Z=up). From the applied force and its application point this also
    derives the moment about the current centre of mass, so the readout can show
    both the force (X/Y/Z, N) and the moment (roll/pitch/yaw, Nm) each generator
    contributes.

    Logging is gated on the global fza_sfmplus_forceLogOn flag (set only while
    the tuner's Forces tab is open) so it costs nothing in normal play.

    Moment axis mapping (model space):
        M.x = moment about X (right)  -> PITCH moment
        M.y = moment about Y (forward)-> ROLL  moment
        M.z = moment about Z (up)     -> YAW   moment

    Note: pass the RAW per-second force (not the *deltaTime version the engine
    addForce call uses) so the readout is in Newtons, comparable across
    generators regardless of frame time. Generators typically build force then
    multiply by _deltaTime for addForce; log the pre-deltaTime value.

    forceLog is a DUMB STORE. It accepts the force and moment a component has
    already calculated and records them. It does NOT compute or derive anything -
    each component owns and passes its own force + moment values.

Parameters:
    _heli   - The aircraft [Object].
    _name   - Short generator label [String] (e.g. "Tail Rotor", "Right Wing").
    _force  - The component's force vector, model space [Array] [X, Y, Z].
    _moment - The component's moment vector, model space [Array] [pitch, roll, yaw].

Returns:
    Nothing.

Author:
    BradMick
---------------------------------------------------------------------------- */
params ["_heli", "_name", ["_force", [0,0,0]], ["_moment", [0,0,0]]];

if !(fza_sfmplus_forceLogOn) exitWith {};
if (isNull _heli) exitWith {};

private _log = _heli getVariable ["fza_sfmplus_forceLog", createHashMap];
//Accumulate per named generator (a generator may log several times per frame,
//e.g. the wing's element loop) so the entry is that generator's total.
private _entry = _log getOrDefault [_name, [[0,0,0],[0,0,0]]];
_log set [_name,
[
    (_entry select 0) vectorAdd _force,
    (_entry select 1) vectorAdd _moment
]];
_heli setVariable ["fza_sfmplus_forceLog", _log];
