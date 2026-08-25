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

    UNITS - IMPULSE (force * deltaTime), the SAME vector handed to addForce. Not raw
    Newtons.

    addForce takes newton-seconds (PxForceMode::eIMPULSE), so the impulse is what the
    aircraft actually receives - measuring anything else means measuring a number the
    physics never saw. Everything downstream (the force table, the accumulator, the
    accelerometer) works in these units, and gravity is expressed the same way
    (mass * 9.806 * deltaTime) so it can be summed with them directly.

    (This note previously asked for pre-deltaTime Newtons, but no generator ever passed
    them - every one passed the post-dt vector. The documentation was wrong, not the
    code. Readouts are therefore in impulse, and are smaller than Newtons by dt: at
    ~30 fps a 3000 N thrust logs as ~100.)

    forceLog is a DUMB STORE. It accepts the force and moment a component has
    already calculated and records them. It does NOT compute or derive anything -
    each component owns and passes its own force + moment values.

Parameters:
    _heli   - The aircraft [Object].
    _name   - Short generator label [String] (e.g. "Tail Rotor", "Right Wing").
    _force  - The component's IMPULSE (force * deltaTime), model space [Array] [X, Y, Z].
    _moment - The component's ANGULAR IMPULSE (torque * deltaTime), model space
              [Array] [pitch, roll, yaw].

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
