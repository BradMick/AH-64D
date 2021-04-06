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

//Empty masses
_heli setVariable ["fza_ah64d_emptyMassFCR",    6609]; //kg
_heli setVariable ["fza_ah64d_emptyMassNonFCR", 6314]; //kg

//Fuel tanks
_heli setVariable ["fza_ah64d_maxFwdFuelMass", 473];	//1043lbs in kg
//_heli setVariable ["fza_ah64d_maxCtrFuelMass", 300];	//663lbs in kg, net yet implemented, center robbie
_heli setVariable ["fza_ah64d_maxAftFuelMass", 669]; 	//1474lbs in kg

//Rotors
_heli setVariable ["fza_ah64d_idleRPM",    0.55];
_heli setVariable ["fza_ah64d_desiredRPM", 1.01];
_heli setVariable ["fza_ah64d_tqMulti", 0.00437];

_heli setVariable ["fza_ah64d_mainRotorPos", [0.0, 0.0, 2.068]];
_heli setVariable ["fza_ah64d_mainRotorRadius", 7.315];
_heli setVariable ["fza_ah64d_mainRotorThrustMulti", 8.61];
_heli setVariable ["fza_ah64d_mainRotorThrustPerRPM", 16336.63];

_heli setVariable ["fza_ah64d_tailRotorPos", [-0.875, -9.15, 1.221]];
_heli setVariable ["fza_ah64d_tailRotorRadius", 1.402];
_heli setVariable ["fza_ah64d_tailRotorWeight", 0.25];
_heli setVariable ["fza_ah64d_tailRotorThrustMulti", 1.00];
_heli setVariable ["fza_ah64d_tailRotorThrustPerRPM", 4950.50];

//Wings & Stabilators
_heli setVariable ["fza_ah64d_stabPos", [0.0, -8.783, -0.50]];
_heli setVariable ["fza_ah64d_stabWidth", 3.22];  //m
_heli setVariable ["fza_ah64d_stabLength", 1.07]; //m


[_heli] call fza_fnc_sfmplusSetFuel;
[_heli] call fza_fnc_sfmplusSetMass;

