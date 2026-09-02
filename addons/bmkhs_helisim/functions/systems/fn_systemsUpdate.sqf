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

//The component graph - whatever this airframe declared. Hydraulics live here now,
//as producers and storage rather than as functions Core wrote for them.
[_heli, _deltaTime] call bmkhs_fnc_systemsSolve;

//Drivetrain torque limits and damage timers are not part of the supply graph.
[_heli, _deltaTime] call bmkhs_fnc_drivetrainController;

//The APU is a startup system. With useSystems off the aircraft behaves like vanilla:
//already running, buses powered, no start procedure.
if !(_heli getVariable ["bmkhs_useSystems", false]) exitWith {};

[_heli] call bmkhs_fnc_apu;
