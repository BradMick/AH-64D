/* ----------------------------------------------------------------------------
Function: bmkhs_fnc_CoreUpdate

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
params ["_heli"];

if (CBA_missionTime < 0.1) exitWith {};
private _deltaTime = ["systems_deltaTime"] call BIS_fnc_deltaTime;

//Systems are all-or-nothing: an aircraft either models them or uses vanilla
//behaviour, in which case Core's optional-input defaults apply.
if !(_heli getVariable ["bmkhs_useSystems", false]) exitWith {};

[_heli, _deltaTime] call bmkhs_fnc_electricalController;
[_heli, _deltaTime] call bmkhs_fnc_apu;
[_heli, _deltaTime] call bmkhs_fnc_hydraulicsController;
[_heli, _deltaTime] call bmkhs_fnc_drivetrainController;
