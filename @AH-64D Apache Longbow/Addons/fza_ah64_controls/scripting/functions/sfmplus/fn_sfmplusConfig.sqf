/* ----------------------------------------------------------------------------
Function: fza_fnc_sfmplusConfig
Description:
Parameters:
	_heli - The apache helicopter to get information from [Unit].
Returns:
Examples:
Author:
	BradMick
---------------------------------------------------------------------------- */
params ["_heli"];

//Wings & Stabilators
_heli setVariable ["fza_ah64d_stabPos", [0.0, -7.207, -0.50]];
_heli setVariable ["fza_ah64d_stabWidth", 3.22];  //m
_heli setVariable ["fza_ah64d_stabLength", 1.07]; //m

