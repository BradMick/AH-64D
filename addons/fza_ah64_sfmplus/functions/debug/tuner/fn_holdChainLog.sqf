/* ----------------------------------------------------------------------------
Function: fza_sfmplus_fnc_holdChainLog

Description:
    Per-frame DEBUG logger for the full hold/SAS control chain, written to diag_log (the Arma
    .rpt file) so the whole sequence can be reviewed AFTER the fact - unlike an on-screen readout,
    which only shows the aftermath of a divergence. One CSV line per frame while enabled, capturing
    the entire chain so cause and effect are visible frame by frame:

      PILOT      : raw cyclic/pedal + force-trim reference + forceTrimInterrupted
      HOLD       : submode, active, posErrX/Y (m), velX/Y (m/s), the hold's per-axis PID output and
                   velocity-damping term, and the final _attHoldCyc*Out
      SAS        : sasPitch/Roll/Yaw out
      RESULT     : pitch/roll (deg), yaw rate, resulting velocity - command vs aircraft response
      TUNER      : the live gains (posPitch/posRoll kp = vel-null, posIntKp = position integral) + status

    Gated on the HOLD AUTO-TUNER being active (fza_sfmplus_tune_holdAutoOn) - the log runs exactly
    when you're tuning the hold, no separate toggle. Costs nothing when the tuner is off. The hold
    pos-branch publishes its internals to fza_sfmplus_dbgPos* vars (this logger only READS).

    Grep the .rpt for "HOLDCHAIN" to extract the run. CSV header is emitted once on the rising edge.

Parameters:
    _heli - The aircraft [Object].

Author:
    BradMick / Claude
---------------------------------------------------------------------------- */
params ["_heli"];
if (isNull _heli) exitWith {};

//Log whenever the HOLD auto-tuner is running - that's exactly when this data is wanted. No separate
//toggle: turning the hold tuner on starts the log; turning it off stops it.
private _on = _heli getVariable ["fza_sfmplus_tune_holdAutoOn", false];
private _wasOn = _heli getVariable ["fza_sfmplus_holdLog_wasOn", false];
if (_on && !_wasOn) then {
    diag_log "HOLDCHAIN,hdr,cycFA,cycLR,ped,ftPitch,ftRoll,ftPed,ftIntr,sub,active,posErrX,posErrY,velX,velY,velNullPitch,velNullRoll,posIntY,posIntX,holdPitchOut,holdRollOut,sasPitch,sasRoll,sasYaw,pitchDeg,rollDeg,yawRate,posPitchKp,posRollKp,posIntKp,tuneStatus";
};
_heli setVariable ["fza_sfmplus_holdLog_wasOn", _on];
if !(_on) exitWith {};

private _fnN = { (_this # 0) toFixed (_this # 1) };   // number -> fixed string

//--- PILOT + force trim ---------------------------------------------------------------
private _cycFA = _heli getVariable ["fza_sfmplus_cyclicFwdAft", 0];
private _cycLR = _heli getVariable ["fza_sfmplus_cyclicLeftRight", 0];
private _ped   = _heli getVariable ["fza_sfmplus_pedalLeftRight", 0];
private _ftP   = _heli getVariable ["fza_ah64_forceTrimPosPitch", 0];
private _ftR   = _heli getVariable ["fza_ah64_forceTrimPosRoll", 0];
private _ftPed = _heli getVariable ["fza_ah64_forceTrimPosYaw", 0];
private _ftInt = _heli getVariable ["fza_ah64_forceTrimInterupted", false];

//--- HOLD internals (published by the pos branch; 0 when not in pos) ------------------
private _sub    = _heli getVariable ["fza_ah64_attHoldSubMode", "?"];
private _active = _heli getVariable ["fza_ah64_attHoldActive", false];
private _peX    = _heli getVariable ["fza_sfmplus_dbgPosErrX", 0];
private _peY    = _heli getVariable ["fza_sfmplus_dbgPosErrY", 0];
private _vel    = _heli getVariable ["fza_sfmplus_velModelSpaceNoWind", [0,0,0]];
private _pidP   = _heli getVariable ["fza_sfmplus_dbgPidPitch", 0];
private _pidR   = _heli getVariable ["fza_sfmplus_dbgPidRoll", 0];
private _dmpP   = _heli getVariable ["fza_sfmplus_dbgDampPitch", 0];
private _dmpR   = _heli getVariable ["fza_sfmplus_dbgDampRoll", 0];
private _hP     = _heli getVariable ["fza_sfmplus_fmcAttHoldCycPitchOut", 0];
private _hR     = _heli getVariable ["fza_sfmplus_fmcAttHoldCycRollOut", 0];

//--- SAS ------------------------------------------------------------------------------
private _sP = _heli getVariable ["fza_sfmplus_fmcSasPitchOut", 0];
private _sR = _heli getVariable ["fza_sfmplus_fmcSasRollOut", 0];
private _sY = _heli getVariable ["fza_sfmplus_fmcSasYawOut", 0];

//--- RESULT ---------------------------------------------------------------------------
(_heli call BIS_fnc_getPitchBank) params ["_pDeg", "_rDeg"];
private _yawR = deg ((_heli getVariable ["fza_sfmplus_angVelModelSpace", [0,0,0]]) # 2);

//--- TUNER ----------------------------------------------------------------------------
private _kpP  = _heli getVariable ["fza_sfmplus_tune_posPitch_kp", 0];
private _kpR  = _heli getVariable ["fza_sfmplus_tune_posRoll_kp", 0];
private _vDmp = _heli getVariable ["fza_sfmplus_tune_posIntKp", 0];   // position-integral gain
private _stat = _heli getVariable ["fza_sfmplus_pidAuto_status", ""];

diag_log format ["HOLDCHAIN,%1,%2,%3,%4,%5,%6,%7,%8,%9,%10,%11,%12,%13,%14,%15,%16,%17,%18,%19,%20,%21,%22,%23,%24,%25,%26,%27,%28,%29",
    [_cycFA,3] call _fnN, [_cycLR,3] call _fnN, [_ped,3] call _fnN,
    [_ftP,3] call _fnN, [_ftR,3] call _fnN, [_ftPed,3] call _fnN, _ftInt,
    _sub, _active,
    [_peX,2] call _fnN, [_peY,2] call _fnN, [_vel#0,2] call _fnN, [_vel#1,2] call _fnN,
    [_pidP,3] call _fnN, [_pidR,3] call _fnN, [_dmpP,3] call _fnN, [_dmpR,3] call _fnN,
    [_hP,3] call _fnN, [_hR,3] call _fnN,
    [_sP,3] call _fnN, [_sR,3] call _fnN, [_sY,3] call _fnN,
    [_pDeg,1] call _fnN, [_rDeg,1] call _fnN, [_yawR,2] call _fnN,
    [_kpP,4] call _fnN, [_kpR,4] call _fnN, [_vDmp,4] call _fnN, _stat];
