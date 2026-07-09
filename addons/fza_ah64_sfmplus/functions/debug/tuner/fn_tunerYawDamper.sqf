/* ----------------------------------------------------------------------------
Function: fza_sfmplus_fnc_tunerYawDamper

Description:
    Optional yaw-rate DAMPER. When enabled (Balance-panel toggle
    fza_sfmplus_tune_yawRateDamp), applies a continuous yaw torque OPPOSING the
    yaw rate: torque_z = -kYawDamp * yawRate. This decays a standing yaw rate
    (residual precession) to zero - like the aerodynamic yaw damping of a real
    airframe. Nulling the net MOMENT (what the master tuner does) only stops yaw
    acceleration and leaves any existing rate; this damper actively removes the
    rate.

    The applied torque is ALSO logged to the force readout as its own generator
    ("Yaw Damper") so it appears in the forces table and counts in the NET moment.

    Runs every frame from fn_coreUpdateFlightModel (installed via PFH would drift;
    call it inline so it uses the same frame's rate). Cheap no-op when the toggle
    is off.

    Sign: force-log/model convention is +Myaw = nose-right. A +yaw rate (nose
    rotating right) is opposed by a NEGATIVE (nose-left) yaw torque -> torque_z is
    -kYawDamp * yawRate.

Parameters:
    _heli - The aircraft [Object].

Returns:
    Nothing.

Author:
    BradMick
---------------------------------------------------------------------------- */
params ["_heli"];

if (!local _heli) exitWith {};
if (currentPilot _heli != player) exitWith {};
if !(_heli getVariable ["fza_sfmplus_tune_yawRateDamp", false]) exitWith {};

private _deltaTime = _heli getVariable ["fza_sfmplus_deltaTime", 0.0];
if (_deltaTime <= 0.0) exitWith {};

//Nm of opposing yaw torque per rad/s of yaw rate.
private _kYawDamp = _heli getVariable ["fza_sfmplus_tune_yawDampGain", 20000.0];

private _yawRate = (_heli getVariable ["fza_sfmplus_angVelModelSpace", [0,0,0]]) select 2;   // rad/s, + = nose-right

//Opposing yaw torque (Nm), model space Z. + = nose-right, so -k*rate opposes.
private _torqueZ = -(_kYawDamp * _yawRate);
private _torque  = [0.0, 0.0, _torqueZ * _deltaTime];

if !([vectorMagnitude _torque] call fza_sfmplus_fnc_isNAN || {[vectorMagnitude _torque] call fza_sfmplus_fnc_isINF}) then {
    _heli addTorque (_heli vectorModelToWorld _torque);
    //Log the damper's own moment (per-second Nm) so it shows in the forces table.
    if (fza_sfmplus_forceLogOn) then {
        [_heli, "Yaw Damper", [0.0, 0.0, 0.0], [0.0, 0.0, _torqueZ]] call fza_sfmplus_fnc_forceLog;
    };
};
