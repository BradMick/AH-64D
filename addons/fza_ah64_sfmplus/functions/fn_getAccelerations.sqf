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
params ["_heli"];

private _deltaTime  = _heli getVariable "fza_sfmplus_deltaTime";
if (_deltaTime < 0.0001) exitWith {};

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
//Gravity projected into the body frame via the mod's own rotation (pitch + roll).
//fza_sfmplus_fnc_vectorRotate signature: [inVec, pitch, roll, yaw]. Sign target (validated
//vs the two-bank reference): left bank -> gravBodyX NEGATIVE (~-5.3), right bank -> POSITIVE
//(~+5.9). If this rotation's convention comes out flipped, negate _curRoll here.
//fza_sfmplus_fnc_vectorRotate uses the OPPOSITE roll-sign convention to BIS_fnc_rotateVector3D
//(verified in-sim: at a left-roll hover, BIS gave gravX -0.30 but this fn gave +0.30). Negate
//roll so gravBodyX matches the validated sign: left bank -> NEGATIVE, right bank -> POSITIVE.
(_heli call BIS_fnc_getPitchBank) params ["_curPitch", "_curRoll"];
private _gravBody  = [[0.0, 0.0, -9.806], _curPitch, -_curRoll, 0.0] call fza_sfmplus_fnc_vectorRotate;

//LATERAL CENTRIPETAL term (turn acceleration) - the piece that CANCELS the gravity lateral
//component in a coordinated turn so the ball centers instead of pegging to the low side.
//The full transport cross-product vPQR x vUVW has lateral (X) component = (q*w - r*v):
//  vPQR = [p roll, q pitch, r yaw] (angVelModelSpace), vUVW = [u lat, v fwd, w vert] (velModelSpace).
//We take ONLY the -r*v piece (yaw rate * FORWARD velocity) = the centripetal turn term.
//We deliberately EXCLUDE the q*w piece (pitch rate * VERTICAL velocity) - that was the
//climb/descent-driven artifact that swung the ball on a collective change. Vertical excluded.
//SIGN (verify in-sim): must SUBTRACT so a coordinated turn nulls gravBodyX. If a coordinated
//turn pegs the ball HARDER instead of centering, flip the sign of _centripetalX.
private _vPQR      = _heli getVariable ["fza_sfmplus_angVelModelSpace", [0,0,0]];
private _vUVW      = _heli getVariable ["fza_sfmplus_velModelSpace", [0,0,0]];
private _r         = _vPQR # 2;   // yaw rate (rad/s)
private _vFwd      = _vUVW # 1;   // forward velocity (m/s)
private _centripetalX = -(_r * _vFwd);
private _bodyAccel = if (_mass > 0.0) then {
    private _acc = (_netForce vectorMultiply (1.0 / (_mass * _deltaTime))) vectorAdd _gravBody;
    _acc set [0, (_acc # 0) + _centripetalX];   // add lateral centripetal to X only
    _acc
} else { [0,0,0] };
_heli setVariable ["fza_sfmplus_bodyAccel", _bodyAccel];

//Clear for next frame (self-registering entries are re-written by whichever generators run).
_heli setVariable ["fza_sfmplus_forceAccum", createHashMap];
