params ["_heli", "_engNum", "_deltaTime", "_engInput", "_maxTorqueScalar", "_controlInputs"];

_engInput
    params ["_refTq", "_gndIdleTq", "_fltIdleTq", "_flyTq", "_idleNg", "_flyNg", "_maxNg", "_gndIdleNp", "_fltIdleNp", "_flyNp"];

systemChat format ["Eng %1 state is ON", _engNum];

private _engThrottlePos      = _heli getVariable "bmk_helisim_engThrottlePos" select _engNum;
private _engState            = _heli getVariable "bmk_helisim_engState" select _engNum;
private _engThrottleSetPoint = _heli getVariable "bmk_helisim_engThrottleSetPoint" select _engNum;
private _engOutputNg         = _heli getVariable "bmk_helisim_engOutputNg" select _engNum;

if (_engThrottlePos == "OFF") then {
    _engState = "OFF";
    _engThrottleSetPoint = 0.0;
};

if (_engThrottlePos == "IDLE") then {
    _engThrottleSetPoint = 0.0;
};

if (_engThrottlePos == "FLY") then {
    _engThrottleSetPoint = 1.0;
};

_engOutputNg  = [_engOutputNg, _idleNg + ((_flyNg - _idleNg) * _engThrottleSetPoint), _deltaTime] call BIS_fnc_lerp;
    
[_heli, "bmk_helisim_engState",            _engNum, _engState] call fza_sfmplus_fnc_setArrayVariable;
[_heli, "bmk_helisim_engThrottleSetPoint", _engNum, _engThrottleSetPoint] call fza_sfmplus_fnc_setArrayVariable;
[_heli, "bmk_helisim_engOutputNg",         _engNum, _engOutputNg] call fza_sfmplus_fnc_setArrayVariable;