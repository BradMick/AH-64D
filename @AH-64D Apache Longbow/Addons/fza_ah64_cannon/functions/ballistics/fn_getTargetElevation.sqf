params ["_platformAltitude", "_sensorLookdownAngle", "_rangeToTarget"];

private _targetElevation = _platformAltitude + (_rangeToTarget * rad (tan _sensorLookdownAngle));

_targetElevation;