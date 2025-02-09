params ["_platformAltitude", "_targetElevation", "_rangeToTarget", "_muzzleVelocity"];

private _effectiveTargetElevation = _platformAltitude - _targetElevation;
private _elevationAngle           = atan((_effectiveTargetElevation * _muzzleVelocity^2) / (_rangeToTarget * 9.806));

_elevationAngle;