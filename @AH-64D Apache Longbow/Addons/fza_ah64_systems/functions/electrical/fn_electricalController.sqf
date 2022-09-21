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

private _apuState = _heli getVariable "fza_systems_apuState";
private _rtrRPM   = (_heli animationPhase "mainRotorRPM") / 10;

//Update the Battery
[_heli, _deltaTime] call fza_systems_fnc_electricalBattery;
//Update Generator 1
[_heli, _apuState, _rtrRPM] call fza_systems_fnc_electricalGenerator1;
//Update Rectifier 1
[_heli] call fza_systems_fnc_electricalRectifier1;
//Update Generator 2
[_heli, _apuState, _rtrRPM] call fza_systems_fnc_electricalGenerator2;
//Update Rectifier 2
[_heli] call fza_systems_fnc_electricalRectifier2;
//Update AC Bus
[_heli] call fza_systems_fnc_electricalACBus;
//Update DC Bus
[_heli] call fza_systems_fnc_electricalDCBus;