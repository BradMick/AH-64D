/* ----------------------------------------------------------------------------
Function: fza_fnc_sfmplusRotor

Description:

Parameters:
	_heli - The apache helicopter to get information from [Unit].

Returns:


Examples:


Author:
	BradMick
---------------------------------------------------------------------------- */
params ["_heli", "_rtrType", "_rtrDir", "_curRPM"];

private _colorRed = [1,0,0,1]; private _colorGreen = [0,1,0,1]; private _colorBlue = [0,0,1,1]; private _colorWhite = [1,1,1,1];

DRAW_LINE = {
	params ["_heli", "_p1", "_p2", "_col"];
	drawLine3D [_heli modelToWorldVisual _p1, _heli modelToWorldVisual _p2, _col];
};

//Variables
private _rtrPos       = 0;
private _rtrRad       = 0;
private _weight       = 0;
private _thrustMulti  = 0;
private _thrustPerRPM = 0;
private _baseThrust   = 0;
private _thrust       = 0;
private _engineTorque = 0;
private _tqMulti      = _heli getVariable "fza_ah64d_tqMulti";
private _objCtr       = getCenterOfMass _heli;

//Input
private _cyclicRollOut  = _heli getVariable "fza_ah64d_cyclicRollOut";
private _cyclicPitchOut = _heli getVariable "fza_ah64d_cyclicPitchOut";
private _pedalOUt       = _heli getVariable "fza_ah64d_pedalOut";
private _collectiveOut  = _heli getVariable "fza_ah64d_collectiveOutput";

if (_rtrType == 0) then {
	//main rotor
	private _pos =  _heli getVariable "fza_ah64d_mainRotorPos";
	_rtrPos = _objCtr vectorAdd _pos;
	_rtrRad = _heli getVariable "fza_ah64d_mainRotorRadius";

	_thrustMulti  = _heli getVariable "fza_ah64d_mainRotorThrustMulti";
	_thrustPerRPM = _heli getVariable "fza_ah64d_mainRotorThrustPerRPM";

	_baseThrust = _curRPM * _thrustPerRPM;
	_thrust = _baseThrust * ((_collectiveOut * _thrustMulti) + 1);

	_engineTorque = _thrust * _tqMulti;
} else {
	//tail rotor
	private _pos =  _heli getVariable "fza_ah64d_tailRotorPos";
	_rtrPos = _objCtr vectorAdd _pos;
	_rtrRad = _heli getVariable "fza_ah64d_tailRotorRadius";

	_weight       = _heli getVariable "fza_ah64d_tailRotorWeight";
	_thrustMulti  = _heli getVariable "fza_ah64d_tailRotorThrustMulti";
	_thrustPerRPM = _heli getVariable "fza_ah64d_tailRotorThrustPerRPM";

	_baseThrust = _curRPM * _thrustPerRPM;
	_thrust = _baseThrust * ((_pedalOut - _weight) * _thrustMulti);

	_engineTorque = _thrust * _tqMulti;
};

/*
hintSilent format ["Cyclic roll out = %1
                    \nCyclic pitch out = %2
					\nPedal Out = %3
					\nCollective out = %4
					\nThrust = %5
					\nTorque = %6", _cyclicRollOut, _cyclicPitchOut, _pedalOut, _collectiveOut, _thrust, _engineTorque];
*/

private _vecUp    = [0.0, 0.0, 1.0];
private _vecRight = [1.0, 0.0, 0.0];

for "_i" from 1 to 24 do {
	private _incr = 360 / 24;
	private _A = 0;
	private _B = 0;

	if (_rtrType == 0) then {
		_A = _rtrPos vectorAdd [_rtrRad * cos (_incr * _i), _rtrRad * sin (_incr * _i), 0.0];
		_B = _rtrPos vectorAdd [_rtrRad * cos (_incr * (_i + 1)), _rtrRad * sin (_incr * (_i + 1)), 0.0];
	} else {
		_A = _rtrPos vectorAdd [0.0, _rtrRad * sin (_incr * _i), _rtrRad * cos (_incr * _i)];
		_B = _rtrPos vectorAdd [0.0, _rtrRad * sin (_incr * (_i + 1)), _rtrRad * cos (_incr * (_i + 1))];
	};

	[_heli, _A, _B, _colorWhite] call DRAW_LINE;
};
