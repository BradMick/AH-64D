params ["_heli", "_num", "_pos", "_length", "_angle", "_radius"];

private _tractionForce  = 10000;

private _base           = 6000000;
private _baseDamp       = _base * 0.8;
private _springTable    = [60000, 60000, 30000];
private _damperTable    = [1000,  1000,  630];

private _springConstant = _springTable select _num;
private _damperConstant = _damperTable select _num;

private _curSuspDist    = 0.0;
private _springVel      = 0.0;
private _springForce    = 0.0;
private _damperForce    = 0.0;
private _deltaTime      = _heli getVariable "fza_sfmplus_deltaTime";
private _prevSuspDist   = _heli getVariable "fza_sfmplus_wheelPrevSuspDistance" select _num;
private _velModelSpace  = _heli getVariable "fza_sfmplus_velModelSpace";

private _vectorRight    = [1.0, 0.0, 0.0];
private _vectorForward  = [0.0, 1.0, 0.0];
private _vectorUp       = [0.0, 0.0, 1.0];
private _direction      = [0.0, 0.0, 0.0];
private _tractionVector = [0.0, 0.0, 0.0];

private _strut          = [0.0, 0.0, -_length];
_strut                  = [_strut, _vectorRight, _angle] call fza_sfmplus_fnc_quaternion;
private _wheelPos       = _pos vectorAdd _strut;
private _contactPointPos = _wheelPos vectorAdd [0.0, 0.0, -_radius];
private _strutHeight    = ((_pos select 2) - (_wheelPos select 2)) + _radius;

private _heightOfTerrain    = 0.0;
private _heightAboveTerrain = 0.0;
private _posASL             = _heli modelToWorldWorld _pos;
private _wheelPosASL        = _heli modelToWorldWorld _wheelPos;
private _rayCastArray       = lineIntersectsSurfaces [_posASL, _posASL vectorAdd [0.0, 0.0, -_strutHeight], _heli, objNull, true, 1, "GEOM"];
if (count _rayCastArray > 0) then {
    _heightOfTerrain    = (_rayCastArray select 0 select 0) select 2;
    _heightAboveTerrain = (_posASL select 2) - _heightOfTerrain;
    _curSuspDist = _strutHeight - (_heightAboveTerrain - _radius);
    _springVel   = (_curSuspDist - _prevSuspDist) / _deltaTime;
    _springForce = (_springConstant * _curSuspDist) * _deltaTime;
    _damperForce = (_damperConstant * _springVel)   * _deltaTime;

    _heli addForce  [_heli vectorModelToWorld (_vectorUp vectorMultiply (_springForce + _damperForce)), _pos];

    //systemChat format ["wheel %1 _springForce %2 -- _damperForce %3", _num, _springForce toFixed 0, _damperForce toFixed 0];

    [_heli, "fza_sfmplus_wheelPrevSuspDistance", _num, _curSuspDist, true] call fza_fnc_setArrayVariable;
};

_direction = vectorNormalized [_velModelSpace select 0, _velModelSpace select 1];

if (vectorMagnitude _velModelSpace > 0.01) then {
    //_tractionVector = [(_direction select 0) * _tractionForce * _deltaTime, (_direction select 1) * _tractionForce * _deltaTime, 0.0];
    //_heli addForce [_heli vectorModelToWorld _tractionVector, _wheelPos];
};

systemChat format ["_tractionVector = %1 -- _direction =%2", _tractionVector, _direction];

#ifdef __A3_DEBUG__
//Wheel
[_heli, _pos, _wheelPos, "white"] call fza_fnc_debugDrawLine;
[_heli, 24, _wheelPos, _radius, 0, "white"]   call fza_fnc_debugDrawCircle;
[_heli, _wheelPos vectorDiff [0.00, _radius, 0.00], _wheelPos vectorAdd [0.00, _radius, 0.00], "green"] call fza_fnc_debugDrawLine;
[_heli, _wheelPos vectorDiff [0.00, 0.00, _radius], _wheelPos vectorAdd [0.00, 0.00, _radius], "blue"] call fza_fnc_debugDrawLine;

//Contact Point
[_heli, 24, _contactPointPos, 0.05, 0, "white"]   call fza_fnc_debugDrawCircle;
[_heli, 24, _contactPointPos, 0.05, 1, "white"]   call fza_fnc_debugDrawCircle;
[_heli, 24, _contactPointPos, 0.05, 2, "white"]   call fza_fnc_debugDrawCircle;
[_heli, _contactPointPos vectorDiff [0.05, 0.00, 0.00], _contactPointPos vectorAdd [0.05, 0.00, 0.00], "red"] call fza_fnc_debugDrawLine;
[_heli, _contactPointPos vectorDiff [0.00, 0.05, 0.00], _contactPointPos vectorAdd [0.00, 0.05, 0.00], "green"] call fza_fnc_debugDrawLine;
[_heli, _contactPointPos vectorDiff [0.00, 0.00, 0.05], _contactPointPos vectorAdd [0.00, 0.00, 0.05], "blue"] call fza_fnc_debugDrawLine;

//Ray
[_heli, _pos, _pos vectorAdd [0.0,0.0, -_strutHeight], "red"] call fza_fnc_debugDrawLine;
#endif