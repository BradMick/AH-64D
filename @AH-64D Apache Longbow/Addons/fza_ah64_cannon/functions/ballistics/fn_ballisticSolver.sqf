params ["_heli"];

private _bulletMass           = 0.01;      //kg
private _dragCoefficient      = 0.1;
private _muzzleVelocity       = 805.0;

private _rangeToTarget = 1000.0;
if (!isNull laserTarget _heli) then {
    _rangeToTarget = _heli distance laserTarget _heli;
};
_rangeToTarget = [_rangeToTarget, 500.0, 9999.0] call BIS_fnc_clamp;

private _platformAltitude     = [_heli] call fza_sfmplus_fnc_getAltitude select 0;

private _sensorAzimuth        = _heli getVariable "fza_ah64_tadsAzimuth";
private _sensorElevation      = _heli getVariable "fza_ah64_tadsElevation";

private _targetElevation      = [_platformAltitude, _sensorElevation, _rangeToTarget] call fza_cannon_fnc_getTargetElevation;
private _reqGunElevationAngle = [_platformAltitude, _targetElevation, _rangeToTarget, _muzzleVelocity] call fza_cannon_fnc_getTurretElevationAngle;

//private _finalVelocity        = [_sensorAzimuth, _reqGunElevationAngle, _muzzleVelocity] call fza_cannon_fnc_getFinalVelocity;

[_heli, "usti hlavne", rad EL] call fza_fnc_updateAnimations;
[_heli, "mainTurret", rad -_sensorAzimuth] call fza_fnc_updateAnimations;
[_heli, "mainGun",    rad EL] call fza_fnc_updateAnimations;

hintSilent format ["_targetElevation = %1
                   \n_reqTurretElevationAngle = %2
                   \n_turretAzimuthAngle = %3
                   \n_turretLookDownAngle = %4
                   \n_rangeToTarget = %5
                   \n_finalVelocity = %6", 
                   _targetElevation,
                   _reqGunElevationAngle,
                   _sensorAzimuth,
                   _sensorElevation,
                   _rangeToTarget,
                   _finalVelocity];