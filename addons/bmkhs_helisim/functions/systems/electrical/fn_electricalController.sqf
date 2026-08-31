/* ----------------------------------------------------------------------------
Function: bmkhs_fnc_electricalController

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

private _configVehicles = configOf _heli;

private _apuOn  = _heli getVariable "bmkhs_apuOn";
private _rtrRPM = [_heli] call bmkhs_fnc_stateRtrRPM;

//Update the Battery
[_heli, _deltaTime] call bmkhs_fnc_electricalBattery;
//Update Generator 1
[_heli, _apuOn, _rtrRPM] call bmkhs_fnc_electricalGenerator1;
//Update Rectifier 1
[_heli] call bmkhs_fnc_electricalRectifier1;
//Update Generator 2
[_heli, _apuOn, _rtrRPM] call bmkhs_fnc_electricalGenerator2;
//Update Rectifier 2
[_heli] call bmkhs_fnc_electricalRectifier2;
//Update AC Bus
[_heli] call bmkhs_fnc_electricalACBus;
//Update DC Bus
[_heli] call bmkhs_fnc_electricalDCBus;
