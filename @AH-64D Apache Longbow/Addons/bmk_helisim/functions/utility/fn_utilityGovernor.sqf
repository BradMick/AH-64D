params ["_heli", "_setRPM", "_xmsnOutputRPM", "_engTrimVal", "_collTrimVal", "_collectiveVal"];

private _deltaRPM  = _setRPM - _xmsnOutputRPM;
private _govOutput = _deltaRPM * (_engTrimVal + (_collTrimVal * _collectiveVal));

[_govOutput];