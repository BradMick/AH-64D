/* ----------------------------------------------------------------------------
Function: fza_systems_fnc_electricalController

Description:
	Updates all of the modules core functions.
	
Parameters:
	_heli - The helicopter to get information from [Unit].

Returns:
	...

Examples:
	...

Author:
	BradMick
---------------------------------------------------------------------------- */
params ["_heli", "_deltaTime"];

private _configVehicles = configFile >> "CfgVehicles" >> typeof _heli;
private _flightModel    = getText (_configVehicles >> "flightModel");

private _apuOn  = _heli getVariable "fza_systems_apuOn";
private _rtrRPM = 0.0; 
if (_flightModel == "SFMPlus") then {
	_rtrRPM = ((_heli animationPhase "mainRotorRPM") * 1.08) / 10;
} else {
	(_heli getVariable "fza_sfmplus_engPctNP") 
		params ["_e1Np", "_e2Np"];
	_rtrRPM = _e1Np max _e2Np;
};

//Update the Battery
[_heli, _deltaTime] call fza_systems_fnc_electricalBattery;
//Update Generator 1
[_heli, _apuOn, _rtrRPM] call fza_systems_fnc_electricalGenerator1;
//Update Rectifier 1
[_heli] call fza_systems_fnc_electricalRectifier1;
//Update Generator 2
[_heli, _apuOn, _rtrRPM] call fza_systems_fnc_electricalGenerator2;
//Update Rectifier 2
[_heli] call fza_systems_fnc_electricalRectifier2;
//Update AC Bus
[_heli] call fza_systems_fnc_electricalACBus;
//Update DC Bus
[_heli] call fza_systems_fnc_electricalDCBus;