params ["_heli", "_num", "_pos", "_restLength", "_springLength", "_springStiffness", "_damperStiffness", "_wheelRadius"];

private _sidewardFrictionForce = 5000;
private _forwardFrictionForce  = 5000;

private _deltaTime          = fza_ah64_fixedTimeStep;
private _heliCom            = getCenterOfMass _heli;
private _vectorRight        = [1.0, 0.0, 0.0];
private _vectorForward      = [0.0, 1.0, 0.0];
private _vectorUp           = [0.0, 0.0, 1.0];

private _lastLength         = _heli getVariable "fza_sfmplus_wheelSpringLength"   select _num;
private _springLength       = 0.0;//_heli getVariable "fza_sfmplus_wheelSpringLength" select _num;

private _minLength          = _restLength + _springLength;
private _maxLength          = _restLength - _springLength;

private _posASL             = _heli modelToWorldWorld _pos;
private _contactPosASL      = _heli modelToWorldWorld (_pos vectorDiff [0.0, 0.0, _maxLength + _wheelRadius]);
private _rayCastArray       = lineIntersectsSurfaces [_posASL, _contactPosASL, _heli, objNull, true, 1, "GEOM", "NONE"];

private _wheelPos           = _pos vectorDiff [0.0, 0.0, _springLength];
private _wheelContactPos    = _pos vectorDiff [0.0, 0.0, _springLength + _wheelRadius]; 

if (count _rayCastArray > 0) then {
    //private _hit             = _heli worldToModel (_rayCastArray select 0 select 0);
    private _hitDist         = (_rayCastArray select 0 select 0) select 2;//_pos vectorDistance _hit;
    _springLength            = _hitDist - _wheelRadius;
    _springLength            = [_springLength, _minLength, _maxLength] call BIS_fnc_clamp;

    private _springVelocity  = (_lastLength - _springLength) / _deltaTime;
    private _springForce     = _springStiffness * (_restLength - _springLength);
    private _damperForce     = _damperStiffness * _springVelocity;

    private _suspensionForce = _heli vectorModelToWorld ([0.0, 0.0, 1.0] vectorMultiply ((_springForce + _damperForce) * _deltaTime));

    private _fromContactPointToCom = _wheelContactPos vectorDiff _heliCom;
    private _angularVel            = (_heli getVariable "fza_sfmplus_angVelModelSpace");

    private _velModelSpace = _heli getVariable "fza_sfmplus_velModelSpace";
    private _localVel      = (vectorNormalized _angularVel) vectorCrossProduct (vectorNormalized _fromContactPointToCom);
    _localVel              = _localVel vectorMultiply -((vectorMagnitude _angularVel) * (vectorMagnitude _fromContactPointToCom));
    _localVelModelSpace    = _velModelSpace vectorAdd _localVel;

    private _f_x = (_localVelModelSpace select 0) * _sidewardFrictionForce * _deltaTime;
    private _f_y = (_localVelModelSpace select 1) * _forwardFrictionForce  * _deltaTime;

    private _forceVecX = _heli vectorModelToWorld ([-1.0, 0.0,0.0] vectorMultiply _f_x);
    private _forceVecY = _heli vectorModelToWorld ([ 0.0,-1.0,0.0] vectorMultiply _f_y);

    _heli addForce [_suspensionForce vectorAdd _forceVecX vectorAdd _forceVecY, _pos vectorDiff [0.0, 0.0, _springLength + _wheelRadius]];

    [_heli, "fza_sfmplus_wheelSpringLength",   _num, _springLength,   true] call fza_fnc_setArrayVariable;

    systemChat format ["_springLength = %1 -- _springVelocity = %2", _springLength, _springVelocity];
    systemChat format ["_springForce = %1 -- _damperForce = %2", _springForce, _damperForce];
    systemChat format ["_lastLength = %1 -- _hitDist = %2", _lastLength, _hitDist];
};

//private _onGround = [_heli] call fza_sfmplus_fnc_onGround;

//if (_onGround) then {
    //private _fromContactPointToCom = _wheelContactPos vectorDiff _heliCom;
    //private _angularVel            = (_heli getVariable "fza_sfmplus_angVelModelSpace");

    //private _localVel   = (vectorNormalized _angularVel) vectorCrossProduct (vectorNormalized _fromContactPointToCom);
    //_localVel           = _localVel vectorMultiply -((vectorMagnitude _angularVel) * (vectorMagnitude _fromContactPointToCom));
    //_localVelModelSpace = _velModelSpace vectorAdd _localVel;

    //private _f_x = (_localVelModelSpace select 0) * _sideFrictionForce    * _deltaTime;
    //private _f_y = (_localVelModelSpace select 1) * _forwardFrictionForce * _deltaTime;

    //private _forceVecX = _heli vectorModelToWorld ([-1.0, 0.0,0.0] vectorMultiply _f_x);
    //private _forceVecY = _heli vectorModelToWorld ([ 0.0,-1.0,0.0] vectorMultiply _f_y);

    //_heli addForce [_forceVecX vectorAdd _forceVecY, _wheelContactPos];
//};

#ifdef __A3_DEBUG__


// Wheel Debug Draw
[_heli, _pos, _wheelPos, "white"] call fza_fnc_debugDrawLine;
[_heli, 24, _wheelPos, _wheelRadius, 0, "white"] call fza_fnc_debugDrawCircle;
[_heli, _wheelPos vectorDiff [0.00, _wheelRadius, 0.00], _wheelPos vectorAdd [0.00, _wheelRadius, 0.00], "green"] call fza_fnc_debugDrawLine;
[_heli, _wheelPos vectorDiff [0.00, 0.00, _wheelRadius], _wheelPos vectorAdd [0.00, 0.00, _wheelRadius], "blue"] call fza_fnc_debugDrawLine;

// Contact Point Debug Draw
[_heli, 24, _wheelContactPos, 0.05, 0, "white"] call fza_fnc_debugDrawCircle;
[_heli, 24, _wheelContactPos, 0.05, 1, "white"] call fza_fnc_debugDrawCircle;
[_heli, 24, _wheelContactPos, 0.05, 2, "white"] call fza_fnc_debugDrawCircle;
[_heli, _wheelContactPos vectorDiff [0.05, 0.00, 0.00], _wheelContactPos vectorAdd [0.05, 0.00, 0.00], "red"] call fza_fnc_debugDrawLine;
[_heli, _wheelContactPos vectorDiff [0.00, 0.05, 0.00], _wheelContactPos vectorAdd [0.00, 0.05, 0.00], "green"] call fza_fnc_debugDrawLine;
[_heli, _wheelContactPos vectorDiff [0.00, 0.00, 0.05], _wheelContactPos vectorAdd [0.00, 0.00, 0.05], "blue"] call fza_fnc_debugDrawLine;

// Ray Debug Draw
[_heli, _pos, _wheelContactPos, "red"] call fza_fnc_debugDrawLine;
#endif