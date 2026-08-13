/* ----------------------------------------------------------------------------
Function: fza_sfmplus_fnc_calculateAeroValues

Description:
    Calculates and returns _alpha (angle of attack) and _beta_g (sideslip) for the
    helicopter. 

    Reference: 
    https://www.mathworks.com/help/aeroblks/incidencesideslipairspeed.html
    https://trace.tennessee.edu/cgi/viewcontent.cgi?referer=&httpsredir=1&article=5851&context=utk_gradthes
    
Parameters:
    _heli - The apache helicopter to check.

Returns:
    _alpha (angle of attack) in degrees
    _beta_g (sideslip) in degrees

Examples:
    ...

Author:
    BradMick
---------------------------------------------------------------------------- */
params ["_heli"];

#include "\fza_ah64_sfmplus\headers\core.hpp"

//Gravity in model space
private _curAtt   = _heli call BIS_fnc_getPitchBank;
private _curPitch = _curAtt # 0;
private _curRoll  = _curAtt # 1;

private _grav     = [[0.0, 0.0, -9.806], _curRoll, 1] call BIS_fnc_rotateVector3D;//_heli vectorWorldToModel ([0.0, 0.0,-1.0] vectorMultiply 9.806);
private _gravX    = _grav # 0;
private _gravY    = _grav # 1;
private _gravZ    = _grav # 2;

private _totVel   = _heli getVariable "fza_sfmplus_velModelSpace";
private _totVelX  = _totVel # 0;
private _totVelY  = _totVel # 1;
private _totVelZ  = _totVel # 2;

//Alpha (angle of attack): airflow angle in the pitch plane (vertical vs forward velocity).
private _alpha_deg   = if (_totVelY == 0) then { 0.0; } else { atan (_totVelZ / _totVelY); };
//Beta (sideslip): airflow angle in the yaw plane (lateral vs total velocity).
private _beta_deg    = if ((vectorMagnitude _totVel) == 0.0) then { 0.0; } else { asin (_totVelX / (vectorMagnitude _totVel)); };
//Beta (sideslip) in g's: the SLIP-BALL reading = lateral specific force in g's.
//bodyAccel now INCLUDES the gravity lateral projection (see fn_getAccelerations): in a bank
//its X is dominated by gravBodyX - left bank NEGATIVE, right bank POSITIVE. The ball must
//fall to the LOW side (validated vs DCS reference: left bank -> ball left, right bank ->
//ball right), and the display driver moves the marker RIGHT on POSITIVE beta_g. So beta_g
//tracks bodyAccelX's sign DIRECTLY (no negation): left bank -> negative -> marker left;
//right bank -> positive -> marker right.
private _bodyAccel   = _heli getVariable ["fza_sfmplus_bodyAccel", [0,0,0]];
private _beta_g      = (_bodyAccel # 0) / GRAVITY;
private _k           = 0.05;
private _betaGPrev   = _heli getVariable ["fza_sfmplus_aero_beta_g_prev", 0.0];
_beta_g              = _betaGPrev + ((_beta_g - _betaGPrev) * _k);

//systemChat format ["beta_g=%1 bodyAccelX=%2 bodyAccelY=%3 gravX=%4", _beta_g toFixed 3, (_bodyAccel # 0) toFixed 3, (_bodyAccel # 1) toFixed 3, _gravX toFixed 3];
/*
private _turnRate  = if (_totVelY == 0.0) then { 0.0 } else { (GRAVITY * (tan _curRoll)) / _totVelY };
_beta_g            = (_totVelY * _turnRate) / GRAVITY; //_betaGPrev + ((_beta_g - _betaGPrev) * _k);
systemChat format ["beta_g=%1 bodyAccelX=%2 bodyAccelY=%3 gravX=%4", _beta_g toFixed 3, (_bodyAccel # 0) toFixed 3, (_bodyAccel # 1) toFixed 3, _gravX toFixed 3];
*/

_heli setVariable ["fza_sfmplus_aero_alpha_deg",   _alpha_deg, true];
_heli setVariable ["fza_sfmplus_aero_beta_deg",    _beta_deg,  true];
_heli setVariable ["fza_sfmplus_aero_beta_g",      _beta_g,    true];
_heli setVariable ["fza_sfmplus_aero_beta_g_prev", _beta_g,    true];
