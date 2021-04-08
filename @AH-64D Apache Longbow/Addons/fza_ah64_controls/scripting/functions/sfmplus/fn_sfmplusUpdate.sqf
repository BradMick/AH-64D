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

private _deltaTime = ["fza_ah64d_deltaTime"] call BIS_fnc_deltaTime;

[_heli] call fza_fnc_sfmplusGetInput;
[_heli, _deltaTime] call fza_fnc_sfmplusStabilator;