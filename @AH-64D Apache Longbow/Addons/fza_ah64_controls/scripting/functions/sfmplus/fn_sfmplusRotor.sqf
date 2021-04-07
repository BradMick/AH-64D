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
params ["_heli", "_rtrType", "_rtrDir", "_curRPM", "_deltaTime"];

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
private _thrustForce  = 0;
private _reqEngTorque = 0;
private _tqMulti      = _heli getVariable "fza_ah64d_tqMulti";
private _objCtr       = _heli selectionPosition ["modelCenter", "Memory"]; //getCenterOfMass _heli;

//Input
private _cyclicRollOut  = _heli getVariable "fza_ah64d_cyclicRollOut";
private _cyclicPitchOut = _heli getVariable "fza_ah64d_cyclicPitchOut";
private _pedalOUt       = _heli getVariable "fza_ah64d_pedalOut";
private _collectiveOut  = _heli getVariable "fza_ah64d_collectiveOutput";

//               A
//               |
//               I
//               |
//               |
//  D----H-------E-------F----B
//               |
//               |
//               G				Points F, G, H and I define the force application
//               |				points for the blades. The 3/4 point was selected
//               C				to 
private _A = [0,0,0];
private _B = [0,0,0];
private _C = [0,0,0];
private _D = [0,0,0];
private _E = [0,0,0];
private _thrustVec = [0,0,0];

if (_rtrType == 0) then {
	//main rotor
	private _numBlades = _heli getVariable "fza_ah64d_mainRotorNumBlades";
	private _pos =  _heli getVariable "fza_ah64d_mainRotorPos";
	_rtrPos      = _objCtr vectorAdd _pos;
	_rtrRad      = _heli getVariable "fza_ah64d_mainRotorRadius";

	_thrustMulti  = _heli getVariable "fza_ah64d_mainRotorThrustMulti";
	_thrustPerRPM = _heli getVariable "fza_ah64d_mainRotorThrustPerRPM";

	_baseThrust   = _curRPM * _thrustPerRPM;
	_thrustForce  = _baseThrust * ((_collectiveOut * _thrustMulti) + 1);
	_reqEngTorque = _thrust * _tqMulti;

	//Cyclic pitch
	private _rtrDiscPitchAngle = 0;
	if (_cyclicPitchOut < 0) then
	{
		_rtrDiscPitchAngle = _heli getVariable "fza_ah64d_minCycPitch";
	};
	if (_cyclicPitchOut > 0) then {
		_rtrDiscPitchAngle = _heli getVariable "fza_ah64d_maxCycPitch";
	};
	_rtrDiscPitchAngle = _rtrDiscPitchAngle * (-_cyclicPitchOut);
	//Cyclic roll
	private _rtrDiscRollAngle  = 0;
	if (_cyclicRollOut < 0) then
	{
		_rtrDiscRollAngle = _heli getVariable "fza_ah64d_minCycRoll";
	};
	if (_cyclicRollOut > 0) then {
		_rtrDiscRollAngle = _heli getVariable "fza_ah64d_maxCycRoll";
	};
	_rtrDiscRollAngle = _rtrDiscRollAngle * (-_cyclicRollOut);
	/*
	hintSilent format ["Rotor disc pitch angle = %1
	                    \Rotor disc roll angle = %2", _rtrDiscPitchAngle, _rtrDiscRollAngle];
	*/
	_A = _rtrPos vectorAdd [0.0, cos _rtrDiscPitchAngle * _rtrRad, sin _rtrDiscPitchAngle * _rtrRad];
	_B = _rtrPos vectorAdd [cos _rtrDiscRollAngle * _rtrRad, 0.0, sin _rtrDiscRollAngle * _rtrRad];
	_C = _rtrPos vectorAdd [0.0, cos _rtrDiscPitchAngle * (-_rtrRad), sin _rtrDiscPitchAngle * (-_rtrRad)];
	_D = _rtrPos vectorAdd [cos _rtrDiscRollAngle * (-_rtrRad), 0.0, sin _rtrDiscRollAngle * (-_rtrRad)];
	_E = (_A vectorAdd _C) vectorMultiply 0.5;

	_thrustVec      = vectorNormalized ((_B vectorDiff _D) vectorCrossProduct (_A vectorDiff _C));
	private _thrust = _thrustVec vectorMultiply (_thrustForce * _deltaTime);

	_heli addForce[_heli vectorModelToWorld _thrust, _E];
	private _bladeForce = _thrustForce / _numBlades;
	//_heli addTorque(_heli vectorModelToWorld [-(_thrust select 0), -(_thrust select 1), 0.0]);
	private _rollForce  = ((_bladeForce * 2) * _cyclicRollOut) * _deltaTime;
	private _pitchForce = ((_bladeForce * 2) * _cyclicPitchOut) * _deltaTime;

	_heli addTorque(_heli vectorModelToWorld [_pitchForce, -_rollForce, 0]);
	/*
	hintSilent format ["Blade Force = %1
						\nRoll Force = %2
						\nPitch Force = %3", _bladeForce, _rollForce, _pitchForce];
	*/
} else {
	//tail rotor
	private _numBlades = _heli getVariable "fza_ah64d_tailRotorNumBlades";
	private _pos =  _heli getVariable "fza_ah64d_tailRotorPos";
	_rtrPos      = _objCtr vectorAdd _pos;
	_rtrRad      = _heli getVariable "fza_ah64d_tailRotorRadius";

	_weight       = _heli getVariable "fza_ah64d_tailRotorWeight";
	_thrustMulti  = _heli getVariable "fza_ah64d_tailRotorThrustMulti";
	_thrustPerRPM = _heli getVariable "fza_ah64d_tailRotorThrustPerRPM";

	_baseThrust   = _curRPM * _thrustPerRPM;
	_thrustForce  = _baseThrust * (((-_pedalOut) - _weight) * _thrustMulti);
	_reqEngTorque = _thrust * _tqMulti;

	_A = _rtrPos vectorAdd [0.0, _rtrRad, 0.0];
	_B = _rtrPos vectorAdd [0.0, 0.0, _rtrRad];
	_C = _rtrPos vectorAdd [0.0, -_rtrRad, 0.0];
	_D = _rtrPos vectorAdd [0.0, 0.0, -_rtrRad];
	_E = (_A vectorAdd _C) vectorMultiply 0.5;

	_thrustVec = vectorNormalized ((_A vectorDiff _C) vectorCrossProduct (_B vectorDiff _D));
	private _thrust = _thrustVec vectorMultiply (_thrustForce * _deltaTime);

	_heli addForce[_heli vectorModelToWorld _thrust, _E];
	//_heli addTorque (_heli vectorModelToWorld [0.0, 0.0, -(_thrust select 2)]);
};

/*
hintSilent format ["Cyclic roll out = %1
                    \nCyclic pitch out = %2
					\nPedal Out = %3
					\nCollective out = %4
					\nThrust = %5
					\nTorque = %6", _cyclicRollOut, _cyclicPitchOut, _pedalOut, _collectiveOut, _thrust, _reqEngTorque];
*/
[_heli, _A, _C, _colorWhite] call DRAW_LINE;
[_heli, _B, _D, _colorWhite] call DRAW_LINE;
//Draw the thrust vector
[_heli, _E, _E vectorAdd _thrustVec, _colorBlue] call DRAW_LINE;

for "_i" from 1 to 24 do {
	private _incr = 360 / 24;
	private _J = 0;
	private _K = 0;

	if (_rtrType == 0) then {
		_J = _rtrPos vectorAdd [_rtrRad * cos (_incr * _i), _rtrRad * sin (_incr * _i), 0.0];
		_K = _rtrPos vectorAdd [_rtrRad * cos (_incr * (_i + 1)), _rtrRad * sin (_incr * (_i + 1)), 0.0];
	} else {
		_J = _rtrPos vectorAdd [0.0, _rtrRad * sin (_incr * _i), _rtrRad * cos (_incr * _i)];
		_K = _rtrPos vectorAdd [0.0, _rtrRad * sin (_incr * (_i + 1)), _rtrRad * cos (_incr * (_i + 1))];
	};

	[_heli, _J, _K, _colorWhite] call DRAW_LINE;
};

//Return required TQ
_reqEngTorque;
