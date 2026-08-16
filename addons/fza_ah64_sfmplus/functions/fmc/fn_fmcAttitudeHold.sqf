params ["_heli"];
#include "\fza_ah64_sfmplus\headers\core.hpp"

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

//Position hold
if (_gndSpeed <= POS_HOLD_SPEED_SWITCH) then {
    //Re-capture the hold datum on the rising edge into pos mode (e.g. decelerating vel->pos) so
    //the outer loop holds WHERE THE AIRCRAFT SETTLED, not the far-off point where hold engaged.
    if (_subMode != "pos") then {
        _heli setVariable ["fza_ah64_attHoldDesiredPos", getPos _heli, true];
    };
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

if (_heli getVariable "fza_ah64_attHoldActive" && !(_heli getVariable "fza_ah64_forceTrimInterupted")) then {
    //Position hold - CASCADED: OUTER position-P loop -> velocity setpoint -> INNER velocity PID.
    //The inner loop alone only nulls velocity, which leaves a small steady residual -> slow creep.
    //The outer loop adds a POSITION reference: it drives the model-space position error (captured
    //datum - current pos) to zero by commanding a small RETURN velocity for the inner loop, so the
    //aircraft actually holds the POINT (zero drift), like the real pos hold. Outer is pure-P (an
    //integrator here would double-wind-up with the inner loop). Inner sign convention is UNCHANGED
    //from the working vel branch (roll setpoint vs -_velX, pitch vs +_velY).
    if (_subMode == "pos") then {
        //--- OUTER: model-space position error (datum - current), rotated by heading -----------
        private _desiredPos = _heli getVariable ["fza_ah64_attHoldDesiredPos", getPos _heli];
        private _dPos = _desiredPos vectorDiff (getPos _heli);
        private _dwX  = _dPos select 0;
        private _dwY  = _dPos select 1;
        private _hdg  = direction _heli;
        private _errX = (_dwX * cos _hdg) - (_dwY * sin _hdg);   // model X error, right+
        private _errY = (_dwX * sin _hdg) + (_dwY * cos _hdg);   // model Y error, fwd+

        private _pKp  = _heli getVariable "fza_sfmplus_tune_posOuter_kp";
        private _pMax = _heli getVariable "fza_sfmplus_tune_posOuter_maxVel";
        private _pDb  = _heli getVariable "fza_sfmplus_tune_posOuter_db";
        private _cmdVelX = if (abs _errX < _pDb) then { 0.0 } else { [_pKp * _errX, -_pMax, _pMax] call BIS_fnc_clamp };
        private _cmdVelY = if (abs _errY < _pDb) then { 0.0 } else { [_pKp * _errY, -_pMax, _pMax] call BIS_fnc_clamp };

        //TUNER INTERLOCK: while the hold auto-tuner is grading the INNER velocity loop, OPEN the
        //outer loop (command zero velocity) so the tuner rings out pure velocity-to-zero and the
        //two loops don't fight. Cleared when not tuning -> normal closed cascade returns to point.
        if (_heli getVariable ["fza_sfmplus_holdAuto_openOuter", false]) then {
            _cmdVelX = 0.0; _cmdVelY = 0.0;
        };

        //--- INNER: velocity PID drives measured velocity to the outer's setpoint --------------
        //Inner measures -_velX (roll) / +_velY (pitch). To command _velX = _cmdVelX the roll
        //setpoint is -_cmdVelX (matched to the -_velX measure); pitch setpoint is _cmdVelY.
        private _roll  = [_pidRoll,  _deltaTime, -_cmdVelX, -_velX] call fza_fnc_pidRun;
        _roll          = [_roll,  -1.0, 1.0] call BIS_fnc_clamp;
        private _pitch = [_pidPitch, _deltaTime,  _cmdVelY,  _velY] call fza_fnc_pidRun;
        _pitch         = [_pitch, -1.0, 1.0] call BIS_fnc_clamp;

        _attHoldCycPitchOut = _pitch;
        _attHoldCycRollOut  = _roll;
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
        //Hold the CAPTURED attitude (set on hold-enable / by the auto-tuner). The previous
        //SET_PITCH/SET_ROLL were undefined macros - this branch errored, so att-hold never
        //worked and could not be auto-tuned. Use the captured setpoint (the intended code).
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
};

//systemChat format ["Dist = %4 -- DistX = %1 -- DistY = %2 -- Dir = %3", _distX toFixed 2, _distY toFixed 2, _dir toFixed 2, _dist toFixed 2];
//systemChat format ["VelX = %1 -- VelY = %2 -- Pitch Out = %3 -- Roll Out = %4", _curVelX toFixed 2, _curVelY toFixed 2, _attHoldCycPitchOut toFixed 2, _attHoldCycRollOut toFixed 2];

_attHoldCycPitchOut = [_attHoldCycPitchOut, -0.1, 0.1] call BIS_fnc_clamp;
_attHoldCycRollOut  = [_attHoldCycRollOut, -0.1, 0.1] call BIS_fnc_clamp;

[_attHoldCycPitchOut, _attHoldCycRollOut]
