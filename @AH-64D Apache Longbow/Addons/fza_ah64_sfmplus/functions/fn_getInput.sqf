/* ----------------------------------------------------------------------------
Function: fza_sfmplus_fnc_getInput

Description:
	Handles keyboard and HOTAS input for the simulation.

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
#include "\fza_ah64_systems\headers\systems.hpp"

private _config            = configFile >> "CfgVehicles" >> typeof _heli >> "Fza_SfmPlus";
private _pitchTorque       = getNumber (_config >> "cyclicPitchTorque");
private _rollTorque        = getNumber (_config >> "cyclicRollTorque");
private _yawTorque         = getNumber (_config >> "pedalYawTorque");

private _tailRtrFixed      = false;

private _priHydPumpDamage  = _heli getHitPointDamage "hit_hyd_pripump";
private _priHydPSI         = _heli getVariable "fza_systems_priHydPsi";

private _utilHydPumpDamage = _heli getHitPointDamage "hit_hyd_utilpump";
private _utilLevel_pct     = _heli getVariable "fza_systems_utilLevel_pct";

private _accOn 		   	   = _heli getVariable "fza_systems_accOn";

private _collectiveVal     = _heli animationSourcePhase "collective";
private _cyclicFwdAft      = _heli animationSourcePhase "cyclicForward";
private _cyclicLeftRight   = _heli animationSourcePhase "cyclicAside";
private _pedalLeftRight    = (inputAction "HeliRudderRight") - (inputAction "HeliRudderLeft");

private _tailRtrDamage     = _heli getHitPointDamage "hitvrotor";

private _collectiveOut     = 0.0;
if (fza_ah64_sfmPlusKeyboardOnly) then {
	_collectiveVal = [_collectiveVal, 0.5, 1.0] call BIS_fnc_clamp;
	_collectiveOut = linearConversion[ 0.5, 1.0, _collectiveVal, 0.0, 2.0];

	private _V_mps            = abs vectorMagnitude [velocity _heli select 0, velocity _heli select 1];
	private _collectiveOutMod = linearConversion [0.00, 12.35, _V_mps, 0.775, 0.853, true];

	_collectiveOut = [_collectiveOut, 0.0, _collectiveOutMod] call BIS_fnc_clamp;
} else {
	_collectiveOut = linearConversion[-1.0, 1.0, _collectiveVal, 0.0, 1.0];
};

fza_sfmplus_collectiveOutput = _collectiveOut;

//Cyclic and Pedal Torque
_cyclicFwdAft    = [_cyclicFwdAft, -0.5, 0.5] call BIS_fnc_clamp;
_cyclicFwdAft    = linearConversion[-0.5, 0.5, _cyclicFwdAft, -1.0, 1.0];

//Experimenting with FMC off
//_cyclicFwdAft    = [0, _cyclicFwdAft, (1 / 0.15) * _deltaTime] call BIS_fnc_lerp;

_cyclicLeftRight = [_cyclicLeftRight, -0.5, 0.5] call BIS_fnc_clamp;
_cyclicLeftRight = linearConversion[-0.5, 0.5, _cyclicLeftRight, -1.0, 1.0];

//Experimenting with FMC off
//_cyclicLeftRight = [0, _cyclicLeftRight, (1 / 0.15) * _deltaTime] call BIS_fnc_lerp;

_pedalLeftRight  = [_pedalLeftRight, -0.5, 0.5] call BIS_fnc_clamp;
_pedalLeftRight  = linearConversion[-0.5, 0.5, _pedalLeftRight, -1.0, 1.0];

private _foreAftTorque   = 0.0;//_cyclicFwdAft    *  _pitchTorque;
private _leftRightTorque = 0.0;//_cyclicLeftRight * -_rollTorque;

if (_priHydPSI < SYS_MIN_HYD_PSI && _utilLevel_pct < SYS_HYD_MIN_LVL) then {
	_tailRtrFixed = true;
};

if (_tailRtrDamage == 1.0 || _tailRtrFixed == true) then {
	_yawTorque = 0.0;
};
private _pedalTorque     = 0.0;//_pedalLeftRight  * _yawTorque;

private _engPwrLvrState  = _heli getVariable "fza_sfmplus_engPowerLeverState";
private _eng1PwrLvrState = _engPwrLvrState select 0;
private _eng2PwrLvrState = _engPwrLvrState select 1;

if (_eng1PwrLvrState in ["IDLE","FLY"] || _eng2PwrLvrState in ["IDLE","FLY"]) then {
	//Primary and Utility Hydraulics
	if (_priHydPumpDamage < SYS_HYD_DMG_THRESH || _utilHydPumpDamage < SYS_HYD_DMG_THRESH) then {
		_heli addTorque (_heli vectorModelToWorld[_foreAftTorque, _leftRightTorque, _pedalTorque]);
	};
	//Emergency Hydraulics
	if (_accOn) then {
		_heli addTorque (_heli vectorModelToWorld[_foreAftTorque, _leftRightTorque, _pedalTorque]);
	};
};