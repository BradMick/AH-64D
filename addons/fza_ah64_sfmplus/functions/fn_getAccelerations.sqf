/* ----------------------------------------------------------------------------
Function: fza_sfmplus_fnc_getAccelerations

Description:


Parameters:
    _heli - The helicopter to get information from [Unit].

Returns:


Examples:
    ...

Author:
    BradMick
---------------------------------------------------------------------------- */
#include "\fza_ah64_sfmplus\headers\core.hpp"

params ["_heli"];

private _deltaTime  = _heli getVariable "fza_sfmplus_deltaTime";
if (_deltaTime < 0.0001) exitWith {};

private _worldVel_prev = _heli getVariable "fza_sfmplus_velWorldSpaceNoWind_prev";
private _worldVel      = _heli getVariable "fza_sfmplus_velWorldSpaceNoWind";
private _worldAccel    = (_worldVel vectorDiff _worldVel_prev) vectorMultiply (1 / _deltaTime);

_heli setVariable ["fza_sfmplus_worldAccel", _worldAccel];
_heli setVariable ["fza_sfmplus_velWorldSpaceNoWind_prev", _worldVel];

private _wAccX_avg = _heli getVariable "fza_sfmplus_worldAccelX_avg";
private _wAccY_avg = _heli getVariable "fza_sfmplus_worldAccelY_avg";
private _wAccZ_avg = _heli getVariable "fza_sfmplus_worldAccelZ_avg";
private _worldAccelF = [
    [_wAccX_avg, _worldAccel # 0] call fza_sfmplus_fnc_getSmoothAverage,
    [_wAccY_avg, _worldAccel # 1] call fza_sfmplus_fnc_getSmoothAverage,
    [_wAccZ_avg, _worldAccel # 2] call fza_sfmplus_fnc_getSmoothAverage
];
_heli setVariable ["fza_sfmplus_worldAccelFiltered", _worldAccelF];

private _velX_prev  = _heli getVariable "fza_sfmplus_velX_prev";
private _accelX     = _heli getVariable "fza_sfmplus_accelX";
private _accelX_avg = _heli getVariable "fza_sfmplus_accelX_avg";

private _velY_prev  = _heli getVariable "fza_sfmplus_velY_prev";
private _accelY     = _heli getVariable "fza_sfmplus_accelY";
private _accelY_avg = _heli getVariable "fza_sfmplus_accelY_avg";

private _velZ_prev  = _heli getVariable "fza_sfmplus_velZ_prev";
private _accelZ     = _heli getVariable "fza_sfmplus_accelZ";
private _accelZ_avg = _heli getVariable "fza_sfmplus_accelZ_avg";

//X Axis Acceleration
private _velX = (_heli getVariable "fza_sfmplus_velModelSpaceNoWind") select 0;
_accelX       = [_accelX_avg, (_velX - _velX_prev) / _deltaTime] call fza_sfmplus_fnc_getSmoothAverage;
_velX_prev    = _velX;

//Y Axis Acceleration
private _velY = (_heli getVariable "fza_sfmplus_velModelSpaceNoWind") select 1;
_accelY       = [_accelY_avg, (_velY - _velY_prev) / _deltaTime] call fza_sfmplus_fnc_getSmoothAverage;
_velY_prev    = _velY;

//Z Axis Acceleration
private _velZ = (_heli getVariable "fza_sfmplus_velModelSpaceNoWind") select 2;
_accelZ       = [_accelZ_avg, (_velZ - _velZ_prev) / _deltaTime] call fza_sfmplus_fnc_getSmoothAverage;
_velZ_prev    = _velZ;

_heli setVariable ["fza_sfmplus_velX_prev", _velX_prev];
_heli setVariable ["fza_sfmplus_accelX",    _accelX];

_heli setVariable ["fza_sfmplus_velY_prev", _velY_prev];
_heli setVariable ["fza_sfmplus_accelY",    _accelY];

_heli setVariable ["fza_sfmplus_velZ_prev", _velZ_prev];
_heli setVariable ["fza_sfmplus_accelZ",    _accelZ];

private _aWorld = _worldAccelF vectorDiff [0.0, 0.0, -GRAVITY];
private _dirB   = vectorDir _heli;
private _upB    = vectorUp  _heli;
private _rightB = _dirB vectorCrossProduct _upB;

private _kLat = _worldAccelF vectorDotProduct _rightB;
private _gLat = [0.0, 0.0, GRAVITY] vectorDotProduct _rightB;
_heli setVariable ["fza_sfmplus_ballTerms", [_kLat, _gLat, _kLat + _gLat]];

_heli setVariable ["fza_sfmplus_bodyAccel", [
    _aWorld vectorDotProduct _rightB,
    _aWorld vectorDotProduct _dirB,
    _aWorld vectorDotProduct _upB
]];
