/* ----------------------------------------------------------------------------
Function: fza_fnc_sfmplusGetInput

Description:

Parameters:
	_heli - The apache helicopter to get information from [Unit].

Returns:


Examples:


Author:
	BradMick
---------------------------------------------------------------------------- */
params ["_heli"];

//Cyclic
private _cyclicLeft     = inputAction "HeliCyclicLeft";
private _cyclicRight    = inputAction "HeliCyclicRight";
private _cyclicForward  = inputAction "HeliCyclicForward";
private _cyclicBackward = inputAction "HeliCyclicBack";

private _cyclicRollOut  =  _cyclicRight - _cyclicLeft;
private _cyclicPitchOut =  _cyclicForward - _cyclicBackward;

//Pedals
private _pedalLeft  = inputAction "HeliRudderLeft";
private _pedalRight = inputAction "HeliRudderRight";
private _pedalOut   = _pedalRight - _pedalLeft;

//Collective - HeliCollectiveLowerCont returns a value from 1 to 0, and HeliCollectiveRaiseCont returns a value from 0 to 1
private _collectiveLow  = inputAction "HeliCollectiveLowerCont";
private _collectiveHigh = inputAction "HeliCollectiveRaiseCont";
private _collectiveVal  = _collectiveHigh - _collectiveLow;
private _collectiveOut  = linearConversion[-1, 1, _collectiveVal, 0, 1];

_heli setVariable ["fza_ah64d_cyclicRollOut", _cyclicRollOut];
_heli setVariable ["fza_ah64d_cyclicPitchOut", _cyclicPitchOut];
_heli setVariable ["fza_ah64d_pedalOut", _pedalOut];
_heli setVariable ["fza_ah64d_collectiveOutput", _collectiveOut];

