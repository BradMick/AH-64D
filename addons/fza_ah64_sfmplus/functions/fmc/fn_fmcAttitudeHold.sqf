params ["_heli"];
#include "\fza_ah64_sfmplus\headers\core.hpp"

//Live-tunable gains (read + set[] each frame so the PID auto-tuner / SCAS tab can dial them live).
//pos/vel use pid_roll/pid_pitch (posRoll/posPitch gains); att uses pid_roll_att/pid_pitch_att (attRoll/attPitch).
//Roll
private _pidRoll      = _heli getVariable "fza_sfmplus_pid_roll";
_pidRoll set ["kp", _heli getVariable "fza_sfmplus_tune_posRoll_kp"];
_pidRoll set ["ki", _heli getVariable "fza_sfmplus_tune_posRoll_ki"];
_pidRoll set ["kd", _heli getVariable "fza_sfmplus_tune_posRoll_kd"];
private _pidRoll_att  = _heli getVariable "fza_sfmplus_pid_roll_att";
_pidRoll_att set ["kp", _heli getVariable "fza_sfmplus_tune_attRoll_kp"];
_pidRoll_att set ["ki", _heli getVariable "fza_sfmplus_tune_attRoll_ki"];
_pidRoll_att set ["kd", _heli getVariable "fza_sfmplus_tune_attRoll_kd"];

//Pitch
private _pidPitch     = _heli getVariable "fza_sfmplus_pid_pitch";
_pidPitch set ["kp", _heli getVariable "fza_sfmplus_tune_posPitch_kp"];
_pidPitch set ["ki", _heli getVariable "fza_sfmplus_tune_posPitch_ki"];
_pidPitch set ["kd", _heli getVariable "fza_sfmplus_tune_posPitch_kd"];
private _pidPitch_att = _heli getVariable "fza_sfmplus_pid_pitch_att";
_pidPitch_att set ["kp", _heli getVariable "fza_sfmplus_tune_attPitch_kp"];
_pidPitch_att set ["ki", _heli getVariable "fza_sfmplus_tune_attPitch_ki"];
_pidPitch_att set ["kd", _heli getVariable "fza_sfmplus_tune_attPitch_kd"];

//Position & Velocity hold
private _subMode  = _heli getVariable "fza_ah64_attHoldSubMode";

((_heli getVariable "fza_sfmplus_velModelSpaceNoWind"))
    params [
             "_velX"
           , "_velY"
           , "_velZ"
           ];

((_heli getVariable "fza_sfmplus_angVelModelSpace"))
    params [
             "_angVelX"
           , "_angVelY"
           , "_angVelZ"
           ];

private _deltaTime = _heli getVariable "fza_sfmplus_deltaTime";
private _gndSpeed  = (_heli getVariable "fza_sfmplus_gndSpeed") * KNOTS_TO_MPS;

//Attitude hold
private _curAtt   = _heli call BIS_fnc_getPitchBank;
private _curPitch = _curAtt # 0;
private _curRoll  = _curAtt # 1;

private _attHoldCycPitchOut = 0.0;
private _attHoldCycRollOut  = 0.0;

//Submode selection: normally speed-driven. A manual LOCK (fza_ah64_attHoldSubModeLock, set by the
//pos/vel/att keybinds: "" = auto, else "pos"/"vel"/"att") OVERRIDES the speed logic and PINS the
//submode - so a tuning run can't be kicked out of its submode if the aircraft goes haywire and you
//fly it back through a speed band.
private _subLock = _heli getVariable ["fza_ah64_attHoldSubModeLock", ""];
if (_subLock != "") then {
    [_heli, "fza_ah64_attHoldSubMode", _subLock] call fza_fnc_updateNetworkGlobal;
} else {
    //Position hold
    if (_gndSpeed <= POS_HOLD_SPEED_SWITCH) then {
        [_heli, "fza_ah64_attHoldSubMode", "pos"] call fza_fnc_updateNetworkGlobal;
    };
    //Velocity hold
    //This needs to check if accelerating or decelerating...really it's
    //5 to 40 knots accelerating, 30 to 5 knots decelerating
    if (_gndSpeed > POS_HOLD_SPEED_SWITCH && _gndSpeed <= VEL_HOLD_SPEED_SWITCH_ACCEL) then {
        [_heli, "fza_ah64_attHoldSubMode", "vel"] call fza_fnc_updateNetworkGlobal;
    };
    //Attitude hold
    if (_gndSpeed > VEL_HOLD_SPEED_SWITCH_ACCEL) then {
        [_heli, "fza_ah64_attHoldSubMode", "att"] call fza_fnc_updateNetworkGlobal;
    };
};

if (_heli getVariable "fza_ah64_attHoldActive" && !(_heli getVariable "fza_ah64_forceTrimInterupted")) then {
    //Position hold = velocity-null loop + a SLOW, TIGHTLY-CLAMPED position-error integral that biases
    //the velocity SETPOINT (not the output) to trim out the standing drift a pure velocity-null loop
    //leaves (type-0 -> type-1: zero steady-state position error). The bias works THROUGH the velocity
    //loop, so velocity does all the actuation and the integral only re-aims it - it can't fight the loop.
    //Anti-windup: the accumulator is clamped to a tiny ceiling (posIntClamp) near the loop's real working
    //range so it physically cannot rail the +-0.1 servo (the old 0.6 ceiling was 60x too big -> railed).
    if (_subMode == "pos") then {
        private _desiredPos = _heli getVariable ["fza_ah64_attHoldDesiredPos", getPos _heli];
        private _dPos = _desiredPos vectorDiff (getPos _heli);
        private _hdg  = direction _heli;
        //model-space position error: X = right+, Y = fwd+
        private _posErrX = ((_dPos # 0) * cos _hdg) - ((_dPos # 1) * sin _hdg);
        private _posErrY = ((_dPos # 0) * sin _hdg) + ((_dPos # 1) * cos _hdg);

        private _posIkp    = _heli getVariable ["fza_sfmplus_tune_posIntKp",    0.0050];
        private _posIclamp = _heli getVariable ["fza_sfmplus_tune_posIntClamp", 0.0200];
        private _iX = (_heli getVariable ["fza_sfmplus_posIntX", 0.0]) + (_posErrX * _deltaTime * _posIkp);
        private _iY = (_heli getVariable ["fza_sfmplus_posIntY", 0.0]) + (_posErrY * _deltaTime * _posIkp);
        _iX = [_iX, -_posIclamp, _posIclamp] call BIS_fnc_clamp;
        _iY = [_iY, -_posIclamp, _posIclamp] call BIS_fnc_clamp;
        _heli setVariable ["fza_sfmplus_posIntX", _iX];
        _heli setVariable ["fza_sfmplus_posIntY", _iY];

        //Bias is a velocity SETPOINT (m/s toward datum). roll measures -velX so its setpoint = -_iX;
        //pitch measures +velY so its setpoint = +_iY (matches the un-negated pos convention).
        private _roll  = [_pidRoll,  _deltaTime, (-_iX), -_velX] call fza_fnc_pidRun;
        _roll          = [_roll,  -1.0, 1.0] call BIS_fnc_clamp;
        private _pitch = [_pidPitch, _deltaTime, ( _iY),  _velY] call fza_fnc_pidRun;
        _pitch         = [_pitch, -1.0, 1.0] call BIS_fnc_clamp;

        _attHoldCycPitchOut = _pitch;
        _attHoldCycRollOut  = _roll;

        //Publish pos-branch internals for the hold-chain logger.
        _heli setVariable ["fza_sfmplus_dbgPosErrX", _posErrX];
        _heli setVariable ["fza_sfmplus_dbgPosErrY", _posErrY];
        _heli setVariable ["fza_sfmplus_dbgDampRoll",  _iX];
        _heli setVariable ["fza_sfmplus_dbgDampPitch", _iY];
    };
    //Velocity hold
    if (_subMode == "vel") then {
        (_heli getVariable "fza_ah64_attHoldDesiredVel")
            params ["_setVelX", "_setVelY"];
        private _roll  = [_pidRoll,  _deltaTime, _setVelX, -_velX] call fza_fnc_pidRun;
        _roll          = [_roll,  -1.0, 1.0] call BIS_fnc_clamp;
        private _pitch = [_pidPitch, _deltaTime, _setVelY, _velY] call fza_fnc_pidRun;
        _pitch         = [_pitch, -1.0, 1.0] call BIS_fnc_clamp;

        _attHoldCycPitchOut = _pitch;
        _attHoldCycRollOut  = _roll;
    };
    //Attitude hold
    if (_subMode == "att") then {
       (_heli getVariable "fza_ah64_attHoldDesiredAtt")
              params ["_setPitch", "_setRoll"];
        private _pitchError = [_curPitch - _setPitch] call CBA_fnc_simplifyAngle180;
        private _rollError  = [_curRoll  - _setRoll]  call CBA_fnc_simplifyAngle180;

        private _roll  = [_pidRoll_att,  _deltaTime, 0.0, _rollError] call fza_fnc_pidRun;
        _roll          = [_roll,  -1.0, 1.0] call BIS_fnc_clamp;
        private _pitch = [_pidPitch_att, _deltaTime, 0.0, _pitchError] call fza_fnc_pidRun;
        _pitch         = [_pitch, -1.0, 1.0] call BIS_fnc_clamp;

        _attHoldCycPitchOut = _pitch * -1.0;
        _attHoldCycRollOut  = _roll  * -1.0;
    };
} else {
    //Position & Velocity hold
    [_pidRoll]  call fza_fnc_pidReset;
    [_pidPitch] call fza_fnc_pidReset;

    //Attitude hold
    [_pidRoll_att]  call fza_fnc_pidReset;
    [_pidPitch_att] call fza_fnc_pidReset;

    //Clear the position integral so re-engaging pos hold starts clean (no stale bias on engage).
    _heli setVariable ["fza_sfmplus_posIntX", 0.0];
    _heli setVariable ["fza_sfmplus_posIntY", 0.0];
};

//systemChat format ["Dist = %4 -- DistX = %1 -- DistY = %2 -- Dir = %3", _distX toFixed 2, _distY toFixed 2, _dir toFixed 2, _dist toFixed 2];
//systemChat format ["VelX = %1 -- VelY = %2 -- Pitch Out = %3 -- Roll Out = %4", _curVelX toFixed 2, _curVelY toFixed 2, _attHoldCycPitchOut toFixed 2, _attHoldCycRollOut toFixed 2];

_attHoldCycPitchOut = [_attHoldCycPitchOut, -0.1, 0.1] call BIS_fnc_clamp;
_attHoldCycRollOut  = [_attHoldCycRollOut, -0.1, 0.1] call BIS_fnc_clamp;

[_attHoldCycPitchOut, _attHoldCycRollOut]
