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

//Each subsystem is gated by the aircraft config. Off means the aircraft uses
//vanilla behaviour and Core's optional-input defaults apply.
if (_heli getVariable ["bmkhs_useElectricalSystem", false]) then {
    [_heli, _deltaTime] call bmkhs_fnc_electricalController;
};
if (_heli getVariable ["bmkhs_useAPU", false]) then {
    [_heli, _deltaTime] call bmkhs_fnc_apu;
};
if (_heli getVariable ["bmkhs_useHydraulicSystem", false]) then {
    [_heli, _deltaTime] call bmkhs_fnc_hydraulicsController;
};
if (_heli getVariable ["bmkhs_useDrivetrain", false]) then {
    [_heli, _deltaTime] call bmkhs_fnc_drivetrainController;
};
