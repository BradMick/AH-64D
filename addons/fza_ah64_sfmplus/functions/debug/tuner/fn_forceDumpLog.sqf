/* ----------------------------------------------------------------------------
Function: fza_sfmplus_fnc_forceDumpLog

Description:
    Per-frame CSV dump of EVERYTHING the live tuner overlay shows, plus the raw per-generator
    force and moment vectors, written to diag_log (the Arma .rpt).

    WHY: the on-screen tuner only ever shows the aftermath of a divergence - by the time you read
    it, the interesting frames are gone. This writes the same data every frame so an oscillation
    can be replayed and the cause found in the numbers rather than inferred from behaviour.

    PER GENERATOR (model space, straight from the force-log accumulator - these are the values
    each component registered for itself, so they are what the physics actually applied):
        Fx  = lateral   (+ right)
        Fy  = fore/aft  (+ forward)
        Fz  = vertical  (+ up)
        Mrol / Mpit / Myaw = moment vector
    Generators: Main Rotor, Tail Rotor, Right/Left Wing, Vertical Fin, Stabilator,
                Fuselage Front/Side/Top, Yaw Damper. Missing generator that frame reads 0.

    PLUS, mirroring the tuner overlay:
        state    - speed, climb, yaw rate, yaw accel, crab
        attitude - pitch/roll and their TARGETS, so error is directly visible
        controls - collective, cyclic fwd/aft + left/right, pedal, and their TARGETS
        scalars  - mainThr, tailThr, torque, stabLift, fuseSide, fin, tilt (what the master tunes)
        response - bodyAccel XYZ (specific force), kinematic accel XYZ, velocity, body rates
        slip     - beta_g (trim ball) and beta_deg (kinematic sideslip)

    Gated on fza_sfmplus_tune_forceDumpOn. NOTE it reads fza_sfmplus_forceLogPublished, the same
    snapshot the overlay uses, so fza_sfmplus_forceLogOn must also be on for the data to exist.

    Grep the .rpt for "FORCEDUMP" and pull it into a spreadsheet. Header emitted on the rising edge.

Parameters:
    _heli - The aircraft [Object].

Author:
    BradMick / Claude
---------------------------------------------------------------------------- */
params ["_heli"];
if (isNull _heli) exitWith {};

private _on    = _heli getVariable ["fza_sfmplus_tune_forceDumpOn", false];
private _wasOn = _heli getVariable ["fza_sfmplus_forceDump_wasOn", false];

private _gens = [
    "Main Rotor", "Tail Rotor", "Right Wing", "Left Wing", "Vertical Fin",
    "Stabilator", "Fuselage Front", "Fuselage Side", "Fuselage Top", "Yaw Damper"
];

if (_on && !_wasOn) then {
    private _hdr = "FORCEDUMP,t";
    {
        private _n = _x splitString " " joinString "";
        _hdr = _hdr + format [",%1_Fx,%1_Fy,%1_Fz,%1_Mrol,%1_Mpit,%1_Myaw", _n];
    } forEach _gens;
    _hdr = _hdr
        + ",NET_Fx,NET_Fy,NET_Fz,NET_Mrol,NET_Mpit,NET_Myaw"
        + ",spdKt,climbFpm,yawRate,yawAccel,crab"
        + ",pitch,pitchTgt,roll,rollTgt"
        + ",coll,collTgt,cycFA,cycFATgt,cycLR,cycLRTgt,ped,pedTgt"
        + ",ftPitch,ftRoll,ftPed"
        + ",sMainThr,sTailThr,sTorque,sStabLift,sFuseSide,sFin,sTilt"
        + ",bodyAccX,bodyAccY,bodyAccZ,accX,accY,accZ"
        + ",velX,velY,velZ,pRate,qRate,rRate"
        + ",betaG,betaDeg,hdgSub,hdgActive,attSub,gwt,getMass"
        //Trim-ball decomposition: kinematic and gravity terms separately, plus their sum (m/s2,
        //projected on model-right). Shows WHY the ball is where it is - attitude vs genuine slip.
        + ",ballKin,ballGrav,ballSum"
        //Hover hold internals: commanded vs actual velocity, PID output and integral per axis,
        //plus the regime weights. Shows whether the loop is asking for the right thing and
        //whether the integral is railed.
        + ",hovSetX,hovSetY,hovVelX,hovVelY,hovOutR,hovOutP,hovIntR,hovIntP,wPos,wVel,wAtt"
        ;
    diag_log _hdr;
};
_heli setVariable ["fza_sfmplus_forceDump_wasOn", _on];
if !(_on) exitWith {};

private _f2 = { (_this # 0) toFixed (_this # 1) };

//--- PER-GENERATOR FORCES + MOMENTS -----------------------------------------------------
//Read the PUBLISHED snapshot - the same one the overlay renders, so the log and the screen
//always agree. (fza_sfmplus_forceLog is cleared each frame as generators re-register.)
private _log  = _heli getVariable ["fza_sfmplus_forceLogPublished", createHashMap];
private _netF = [0,0,0];
private _netM = [0,0,0];
private _row  = format ["FORCEDUMP,%1", [CBA_missionTime, 2] call _f2];
{
    private _e = _log getOrDefault [_x, [[0,0,0],[0,0,0]]];
    private _f = _e select 0;
    private _m = _e select 1;
    _netF = _netF vectorAdd _f;
    _netM = _netM vectorAdd _m;
    _row = _row + format [",%1,%2,%3,%4,%5,%6",
        [_f # 0, 1] call _f2, [_f # 1, 1] call _f2, [_f # 2, 1] call _f2,
        [_m # 0, 1] call _f2, [_m # 1, 1] call _f2, [_m # 2, 1] call _f2];
} forEach _gens;
_row = _row + format [",%1,%2,%3,%4,%5,%6",
    [_netF # 0, 1] call _f2, [_netF # 1, 1] call _f2, [_netF # 2, 1] call _f2,
    [_netM # 0, 1] call _f2, [_netM # 1, 1] call _f2, [_netM # 2, 1] call _f2];

//--- STATE ------------------------------------------------------------------------------
private _gndSpd  = _heli getVariable ["fza_sfmplus_gndSpeed", 0];
private _spdKt   = _heli getVariable ["fza_sfmplus_vel2D", 0];
private _climb   = (_heli getVariable ["fza_sfmplus_velClimb", 0]) * 196.85;   //m/s -> fpm
private _angVel  = _heli getVariable ["fza_sfmplus_angVelModelSpace", [0,0,0]];
private _yawRate = (_angVel # 2) * 57.2958;
private _yawAcc  = _heli getVariable ["fza_sfmplus_yawAccel", 0];

//Crab: heading minus ground track, same construction as the overlay.
private _crab = 0.0;
if (_gndSpd > 2.0) then {
    private _vel   = velocity _heli;
    private _track = (_vel select 0) atan2 (_vel select 1);
    if (_track < 0) then { _track = _track + 360; };
    _crab = (getDir _heli) - _track;
    if (_crab > 180)  then { _crab = _crab - 360; };
    if (_crab < -180) then { _crab = _crab + 360; };
};

//--- ATTITUDE + TARGETS -----------------------------------------------------------------
(_heli call BIS_fnc_getPitchBank) params ["_curP", "_curR"];
private _tgtKt     = _heli getVariable ["fza_sfmplus_tune_masterTargetKt", 0];
private _lookupSpd = if (_tgtKt >= 5.0) then { _tgtKt / 1.94384 } else { _gndSpd };
private _fnTbl = {
    params ["_var"];
    private _t = _heli getVariable [_var, []];
    if (_t isEqualTo []) then { 0.0 } else { [_t, _lookupSpd] call fza_fnc_linearInterp select 1 }
};
private _tgtP = ["fza_sfmplus_tune_targetPitchTable"] call _fnTbl;
private _tgtR = ["fza_sfmplus_tune_targetRollTable"]  call _fnTbl;

//--- CONTROLS + TARGETS -----------------------------------------------------------------
private _coll  = (_heli getVariable ["fza_sfmplus_collectiveOutput", 0]) * 100;
private _cycFA =  _heli getVariable ["fza_sfmplus_cyclicFwdAft", 0];
private _cycLR =  _heli getVariable ["fza_sfmplus_cyclicLeftRight", 0];
private _ped   =  _heli getVariable ["fza_sfmplus_pedalLeftRight", 0];
private _tgtC     = (["fza_sfmplus_tune_targetCollTable"]     call _fnTbl) * 100;
private _tgtCycFA =  ["fza_sfmplus_tune_targetCycPitchTable"] call _fnTbl;
private _tgtCycLR =  ["fza_sfmplus_tune_targetCycRollTable"]  call _fnTbl;
private _tgtPed   =  ["fza_sfmplus_tune_targetPedalTable"]    call _fnTbl;

_row = _row + format [",%1,%2,%3,%4,%5",
    [_spdKt, 1] call _f2, [_climb, 0] call _f2,
    [_yawRate, 3] call _f2, [_yawAcc, 3] call _f2, [_crab, 2] call _f2];
_row = _row + format [",%1,%2,%3,%4",
    [_curP, 2] call _f2, [_tgtP, 2] call _f2, [_curR, 2] call _f2, [_tgtR, 2] call _f2];
_row = _row + format [",%1,%2,%3,%4,%5,%6,%7,%8",
    [_coll, 1] call _f2, [_tgtC, 1] call _f2,
    [_cycFA, 4] call _f2, [_tgtCycFA, 4] call _f2,
    [_cycLR, 4] call _f2, [_tgtCycLR, 4] call _f2,
    [_ped, 4] call _f2, [_tgtPed, 4] call _f2];
_row = _row + format [",%1,%2,%3",
    [_heli getVariable ["fza_ah64_forceTrimPosPitch", 0], 4] call _f2,
    [_heli getVariable ["fza_ah64_forceTrimPosRoll",  0], 4] call _f2,
    [_heli getVariable ["fza_ah64_forceTrimPosYaw",   0], 4] call _f2];

//--- FORCE SCALARS (what the master tuner is driving) -----------------------------------
private _isBet = (fza_ah64_sfmPlusRotorModel == 1);
private _sMain = [if (_isBet) then { "fza_sfmplus_tune_betMainLiftTable"   } else { "fza_sfmplus_tune_mainThrustTable"  }] call _fnTbl;
private _sTail = [if (_isBet) then { "fza_sfmplus_tune_betTailLiftTable"   } else { "fza_sfmplus_tune_tailThrustTable"  }] call _fnTbl;
private _sTorq = [if (_isBet) then { "fza_sfmplus_tune_betMainTorqueTable" } else { "fza_sfmplus_tune_rtrTqScalarTable" }] call _fnTbl;
private _sStab = ["fza_sfmplus_tune_stabLiftScalarTable"] call _fnTbl;
private _sFuse = ["fza_sfmplus_tune_fuseSideScalarTable"] call _fnTbl;
private _sFin  = ["fza_sfmplus_tune_finLiftScalarTable"]  call _fnTbl;
private _sTilt =  _heli getVariable ["fza_ah64_forceTrimPosRoll", 0.0];
_row = _row + format [",%1,%2,%3,%4,%5,%6,%7",
    [_sMain, 4] call _f2, [_sTail, 4] call _f2, [_sTorq, 4] call _f2, [_sStab, 4] call _f2,
    [_sFuse, 4] call _f2, [_sFin, 4] call _f2, [_sTilt, 4] call _f2];

//--- RESPONSE ---------------------------------------------------------------------------
private _bodyAcc = _heli getVariable ["fza_sfmplus_bodyAccel", [0,0,0]];
private _vel     = _heli getVariable ["fza_sfmplus_velModelSpace", [0,0,0]];
_row = _row + format [",%1,%2,%3,%4,%5,%6",
    [_bodyAcc # 0, 4] call _f2, [_bodyAcc # 1, 4] call _f2, [_bodyAcc # 2, 4] call _f2,
    [_heli getVariable ["fza_sfmplus_accelX", 0], 4] call _f2,
    [_heli getVariable ["fza_sfmplus_accelY", 0], 4] call _f2,
    [_heli getVariable ["fza_sfmplus_accelZ", 0], 4] call _f2];
_row = _row + format [",%1,%2,%3,%4,%5,%6",
    [_vel # 0, 3] call _f2, [_vel # 1, 3] call _f2, [_vel # 2, 3] call _f2,
    [_angVel # 0, 5] call _f2, [_angVel # 1, 5] call _f2, [_angVel # 2, 5] call _f2];

//--- SLIP + MODES -----------------------------------------------------------------------
//Log BOTH mass sources. RESOLVED 2026-08-20: getMass is fine - it logged 8165.0, exactly matching
//fza_sfmplus_GWT, across 4072 frames. The earlier 0.000 reading was a logging artefact, not a bad
//mass. Kept as two columns anyway: bodyAccel divides by getMass, so if they ever diverge again the
//accelerometer signal is immediately suspect.
_row = _row + format [",%1,%2,%3,%4,%5,%6,%7",
    [_heli getVariable ["fza_sfmplus_aero_beta_g",   0], 5] call _f2,
    [_heli getVariable ["fza_sfmplus_aero_beta_deg", 0], 3] call _f2,
    _heli getVariable ["fza_ah64_hdgHoldSubMode", "?"],
    _heli getVariable ["fza_ah64_hdgHoldActive", false],
    _heli getVariable ["fza_ah64_attHoldSubMode", "?"],
    [_heli getVariable ["fza_sfmplus_GWT", 0], 1] call _f2,
    [getMass _heli, 1] call _f2];

//--- TRIM BALL DECOMPOSITION ------------------------------------------------------------
//[kinematic, gravity, sum] - m/s2, projected on the model-right axis the ball reads.
private _bt = _heli getVariable ["fza_sfmplus_ballTerms", [0,0,0]];
_row = _row + format [",%1,%2,%3",
    [_bt # 0, 4] call _f2, [_bt # 1, 4] call _f2, [_bt # 2, 4] call _f2];

//--- HOVER HOLD INTERNALS ---------------------------------------------------------------
_row = _row + format [",%1,%2,%3,%4,%5,%6,%7,%8,%9,%10,%11",
    [_heli getVariable ["fza_sfmplus_dbgHovSetX", 0], 4] call _f2,
    [_heli getVariable ["fza_sfmplus_dbgHovSetY", 0], 4] call _f2,
    [_heli getVariable ["fza_sfmplus_dbgHovVelX", 0], 4] call _f2,
    [_heli getVariable ["fza_sfmplus_dbgHovVelY", 0], 4] call _f2,
    [_heli getVariable ["fza_sfmplus_dbgHovOutR", 0], 4] call _f2,
    [_heli getVariable ["fza_sfmplus_dbgHovOutP", 0], 4] call _f2,
    [_heli getVariable ["fza_sfmplus_dbgHovIntR", 0], 4] call _f2,
    [_heli getVariable ["fza_sfmplus_dbgHovIntP", 0], 4] call _f2,
    [_heli getVariable ["fza_sfmplus_prestonWPos", 0], 3] call _f2,
    [_heli getVariable ["fza_sfmplus_prestonWVel", 0], 3] call _f2,
    [_heli getVariable ["fza_sfmplus_prestonWAtt", 0], 3] call _f2];

diag_log _row;
