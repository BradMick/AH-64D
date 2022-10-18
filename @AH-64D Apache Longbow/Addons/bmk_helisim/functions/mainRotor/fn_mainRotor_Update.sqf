params ["_heli", "_rotorParams"];

_rotorParams params ["_a", "_b", "_R", "_c", "_theta1", "_m", "_eR", "_e", "_gearRatio", "_s"];

private _RPM    =  _heli getVariable "bmk_helisim_mainRotor_RPM";
private _omega  = ((2.0 * pi) * _RPM) / 60.0;
private _omegaR = _omega * _R;

//21109 needs to pull from the current transmission RPM
_RPM = 21109 / _gearRatio;
_heli setVariable ["bmk_helisim_mainRotor_RPM", _RPM];

//systemChat format ["OmegaR: %1", _omegaR];

[_omega, _omegaR];