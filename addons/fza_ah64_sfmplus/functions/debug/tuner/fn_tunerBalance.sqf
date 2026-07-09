/* ----------------------------------------------------------------------------
Function: fza_sfmplus_fnc_tunerBalance

Description:
    Balance-tab support. Two jobs, both passive (no torque applied - the master
    auto-tuner owns yaw/attitude via the force scalars):

      1. Mirrors the "Raw Airframe" toggle into fza_sfmplus_tune_suppressHold
         (read in fn_fmc.sqf) so the aircraft flies its true natural trimmed
         attitude without engaging the by-design actuator lag.
      2. Publishes a short-window average of the body rates (deg/s) under
         "fza_sfmplus_balance_rates" for the Balance-tab / overlay readout.

    The old per-axis trim-TORQUE (an unlogged addTorque the master could not see)
    and its auto-null integrator were removed: they applied a standing yaw torque
    that fought the master and caused an un-nullable heading precession.

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

//Raw-airframe diagnostic: when "Raw Airframe" is on, suppress the attitude-hold
//+ SAS CORRECTION (via fza_sfmplus_tune_suppressHold, read in fn_fmc.sqf) so the
//aircraft flies its true natural trimmed attitude - WITHOUT turning off the FMC
//flags, which would engage the by-design actuator lag and corrupt the controls.
_heli setVariable ["fza_sfmplus_tune_suppressHold", (_heli getVariable ["fza_sfmplus_tune_fmcYawOff", false])];

private _deltaTime = _heli getVariable ["fza_sfmplus_deltaTime", 0.0];
if (_deltaTime <= 0.0) exitWith {};

//Measured body rates (rad/s): [pitch, roll, yaw].
(_heli getVariable ["fza_sfmplus_angVelModelSpace", [0,0,0]]) params ["_rateP", "_rateR", "_rateY"];

//Publish a short-window average of the rates for the GUI readout (deg/s).
private _avg = _heli getVariable ["fza_sfmplus_balance_ratesRaw", [0,0,0]];
private _a   = 0.1;   // low-pass factor
_avg = [
    (_avg select 0) + (((deg _rateP) - (_avg select 0)) * _a),
    (_avg select 1) + (((deg _rateR) - (_avg select 1)) * _a),
    (_avg select 2) + (((deg _rateY) - (_avg select 2)) * _a)
];
_heli setVariable ["fza_sfmplus_balance_ratesRaw", _avg];
_heli setVariable ["fza_sfmplus_balance_rates",    _avg];
