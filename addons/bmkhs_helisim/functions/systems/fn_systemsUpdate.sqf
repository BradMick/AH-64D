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

//Hydraulics and the drivetrain are flight-model infrastructure - control
//authority and torque limits - so they run regardless.
[_heli, _deltaTime] call bmkhs_fnc_hydraulicsController;
[_heli, _deltaTime] call bmkhs_fnc_drivetrainController;

//Electrical and APU are the startup systems. With useSystems off the aircraft
//behaves like vanilla: already running, buses powered, no start procedure.
if !(_heli getVariable ["bmkhs_useSystems", false]) exitWith {};

[_heli, _deltaTime] call bmkhs_fnc_electricalController;
[_heli, _deltaTime] call bmkhs_fnc_apu;
