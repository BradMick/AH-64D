params ["_sensorAzimuthAngle", "_gunElevationAngle", "_muzzleVelocity"];

private _finalVelocity = [0.0, 0.0, 0.0];

private _vx = _muzzleVelocity * (cos _gunElevationAngle) * (cos _sensorAzimuthAngle);
private _vy = _muzzleVelocity * (cos _gunElevationAngle) * (sin _sensorAzimuthAngle);
private _vz = _muzzleVelocity * (sin _gunElevationAngle);

[_vx, _vy, _vz];