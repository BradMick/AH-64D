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


//BODY-FRAME SPECIFIC FORCE = the accelerometer / slip-ball signal.
//
//Base term: netForce/Mass (the sum of all GENERATOR forces / mass). Our generators bake
//dt into the force they store (Arma addForce impulse convention), so /(mass*dt) recovers
//the true force/mass. NO transport/Coriolis term (that belongs to vUVWdot, the velocity
//derivative Arma integrates for us - including it injected a climb-driven lateral artifact).
//
//PLUS gravity projected into the body lateral/vertical axes. WHY (this differs from JSBSim's
//literal vBodyAccel=Force/Mass): JSBSim's in.Force is the TOTAL body force incl. the aero/
//contact reaction that carries the aircraft's ATTITUDE relative to gravity. OUR generator
//forces are computed in the BODY frame and do NOT carry attitude - Arma applies gravity to
//the rigid body separately. So in a bank our netForce lateral sum is ~0 even at 32 deg,
//and the ball sat centered when it should slam to the low side. The real accelerometer's
//banked-slip deflection IS the gravity vector's lateral projection - so we add it back
//explicitly. gravBodyX is computed the SAME way as the validated debug readout (roll-rotated
//-9.806 up-vector): left bank -> gravX NEGATIVE (~-5.3), right bank -> POSITIVE (~+5.9),
//matching the reference where the ball falls to the LOW side. beta_g (in
//fn_calculateAeroValues) uses +bodyAccelX/g (no negation) so its sign tracks gravX -> the
//ball hangs to the low wing.
private _forceMap  = _heli getVariable ["fza_sfmplus_forceAccum", createHashMap];
private _netForce  = [0,0,0];
{ _netForce = _netForce vectorAdd _y; } forEach _forceMap;
private _mass      = getMass _heli;

//SPECIFIC FORCE, COMPUTED IN THE WORLD FRAME AND ONLY THEN ROTATED TO BODY.
//
//This ordering matters and is where the previous attempts went wrong. Rotating the force sum to
//world and immediately back to body is an IDENTITY - it returns the body vector you started with,
//so nothing is gained. The lateral force that a banked rotor produces exists in the WORLD frame;
//converting straight back to body removes it again.
//
//An accelerometer measures (applied force / mass) MINUS gravity, and that subtraction has to
//happen in the world frame where gravity is a fixed [0,0,-g]. Only the RESULT gets rotated into
//body axes for display. Do the subtraction in body axes instead and the gravity term no longer
//lines up with the force term once the aircraft is banked - which is exactly the failure the logs
//kept showing: predicted +3.78 vs actual -3.48, same magnitude, opposite sign.
private _forceMapW = _heli getVariable ["fza_sfmplus_forceAccumWorld", createHashMap];
private _netForceW = [0,0,0];
{ _netForceW = _netForceW vectorAdd _y; } forEach _forceMapW;
//GRAVITY, in the WORLD frame. It is a fixed [0,0,-g] here - no attitude maths, no sign convention
//to get wrong - and the subtraction happens in world BEFORE the result is rotated into body axes.
//That ordering is what makes it hold at any attitude: in a banked turn the tilted thrust and
//gravity cancel laterally in the world frame, so the body projection comes out near zero.
private _gravWorld = [0.0, 0.0, -9.806];

//LATERAL CENTRIPETAL term - REMOVED. It was added so a coordinated turn would null gravBodyX and
//centre the ball instead of pegging it to the low side, but measurement showed it DOUBLE-COUNTS
//and then dominates the whole signal.
//
//Why it double-counts: a real accelerometer measures SPECIFIC FORCE. In a coordinated turn the
//centripetal acceleration is already present in the aircraft's actual lateral force (netForce),
//so adding -(r*vFwd) on top counts the same physics twice.
//
//Measured in cruise (2214 logged frames, 60-104 kt) - see the FORCEDUMP analysis:
//    centripetal -(r*v) : rms 0.746, max 3.22, corr with bodyAccelX = +0.887
//    gravity lateral    : rms 0.303, max 1.06, corr with bodyAccelX = -0.053
//The term was ~2.5x larger than gravity and essentially WAS the ball reading. At cruise vFwd is
//~49 m/s, so even 1 deg/s of yaw contributes ~0.86 m/s^2 - swamping the real side force.
//
//The practical symptom: the ball tracked YAW RATE, not lateral force (corr yawRate->betaG -0.587,
//while pedal->betaG was -0.014, i.e. NO relationship). Pushing pedal to centre the ball generates
//yaw rate, which moved the ball further - so it could not be trimmed to zero at all.
//
//bodyAccel is now net force / mass + body-frame gravity, which is what an accelerometer actually
//reads. If coordinated turns peg the ball to the low side again, do NOT reinstate this at full
//strength - scale it down, or fix the underlying side force instead.
//SPECIFIC FORCE, in WORLD, then rotated to body for display.
//
//  a_world = netForceWorld/mass + gravityWorld      <- both terms in the same frame
//  a_body  = project a_world onto the body axes     <- rotation only, no translation
//
//In a coordinated turn the tilted rotor thrust and gravity cancel laterally IN THE WORLD FRAME, so
//the projection into body comes out near zero and the ball centres. In level flight the rotor is
//vertical, thrust cancels gravity, and the lateral projection is again zero. Both cases fall out of
//the same expression with no special-casing, no tilt reconstruction and no scale factor.
private _bodyAccel = if (_mass > 0.0) then {
    private _aWorld = (_netForceW vectorMultiply (1.0 / (_mass * _deltaTime))) vectorAdd _gravWorld;
    private _dirB   = vectorDir _heli;
    private _upB    = vectorUp  _heli;
    private _rightB = _dirB vectorCrossProduct _upB;
    [
        _aWorld vectorDotProduct _rightB,
        _aWorld vectorDotProduct _dirB,
        _aWorld vectorDotProduct _upB
    ]
} else { [0,0,0] };
_heli setVariable ["fza_sfmplus_bodyAccel", _bodyAccel];

//Clear for next frame (self-registering entries are re-written by whichever generators run).
//Both maps must be cleared together or the world mirror keeps stale entries from generators that
//stop running (e.g. a rotor that goes offline), and the accelerometer would read forces that are
//no longer being applied.
_heli setVariable ["fza_sfmplus_forceAccum",      createHashMap];
_heli setVariable ["fza_sfmplus_forceAccum",      createHashMap];
_heli setVariable ["fza_sfmplus_forceAccumWorld", createHashMap];
