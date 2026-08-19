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

private _totVel   = _heli getVariable "fza_sfmplus_velModelSpace";
private _totVelX  = _totVel # 0;
private _totVelY  = _totVel # 1;
private _totVelZ  = _totVel # 2;

//Alpha (angle of attack): airflow angle in the pitch plane (vertical vs forward velocity).
private _alpha_deg   = if (_totVelY == 0) then { 0.0; } else { atan (_totVelZ / _totVelY); };
//Beta (sideslip): airflow angle in the yaw plane (lateral vs total velocity).
private _beta_deg    = if ((vectorMagnitude _totVel) == 0.0) then { 0.0; } else { asin (_totVelX / (vectorMagnitude _totVel)); };
//Beta (sideslip): lateral specific force in G - the trim ball.
//
//Use fza_sfmplus_bodyAccel (built in fn_getAccelerations), NOT a locally-derived figure. That
//signal is the real accelerometer model and carries three things this function cannot compute
//on its own:
//   1. net force / mass from the force accumulator (rotor thrust, tail thrust, aero side force)
//   2. gravity projected into the BODY frame, with the sign validated against a two-bank
//      reference (left bank -> negative, right bank -> positive, so the ball hangs low-side)
//   3. the lateral CENTRIPETAL term, which is what cancels gravity in a coordinated turn so the
//      ball centres instead of pegging to the low side
//
//This previously recomputed its own value from KINEMATIC acceleration (change in world velocity
//minus gravity). That is wrong in two different ways at once, which is why no single sign fixed
//it: kinematic accel is ~zero in ANY steady flight, so at a hover only the gravity term showed
//and the ball hung on the wrong side; in a turn the missing centripetal term meant it deflected
//when it should have centred. Hover and cruise disagreed because they were failing for
//different reasons.
//SIGN: NOT negated. CRUISE IS THE PRIORITY REGIME and it reads correctly this way - measured at
//-0.005 (level) and +0.015 (coordinated turn), i.e. centred, with the aircraft's natural crab
//left intact rather than being driven to nose-to-tail trim.
//
//Negating this puts the HOVER on the correct side (ball left of centre, per the real-aircraft
//reference) but reverses CRUISE, which is not acceptable. The two regimes trade with the sign and
//no single constant satisfies both - so hover remains a KNOWN DEFECT here rather than breaking the
//more important case. Do not "fix" hover by flipping this without solving the underlying trade.
private _bodyAccel   = _heli getVariable ["fza_sfmplus_bodyAccel", [0.0, 0.0, 0.0]];
private _accel_x     = _bodyAccel # 0;
private _beta_g_raw  = _accel_x / GRAVITY;

//DISPLAY LIMIT. The Apache's slip indicator is a DIGITAL readout driven from the EGI's inertial
//accelerations - not a fluid-damped ball - but it still has a finite scale and pins at the end of
//it rather than running away. Clamping keeps a transient from reading several times past the edge
//of the scale.
_beta_g_raw = [_beta_g_raw, -1.0, 1.0] call BIS_fnc_clamp;

//Light filter only. This is a digital instrument, so it should be responsive - the filter exists
//to take the frame-to-frame numerical noise off a force-derived signal, NOT to imitate mechanical
//damping the real instrument does not have.
//It also matters for control: the heading hold's yaw/trn sub-modes CONTROL on this signal, so a
//jittery measurement makes the loop chase noise.
private _k           = 0.05;
private _beta_g_prev = _heli getVariable "fza_sfmplus_aero_beta_g_prev";
private _beta_g      = _beta_g_prev + ((_beta_g_raw - _beta_g_prev) * _k);

_heli setVariable ["fza_sfmplus_aero_alpha_deg",   _alpha_deg, true];
_heli setVariable ["fza_sfmplus_aero_beta_deg",    _beta_deg,  true];
_heli setVariable ["fza_sfmplus_aero_beta_g",      _beta_g,    true];
_heli setVariable ["fza_sfmplus_aero_beta_g_prev", _beta_g,    true];
