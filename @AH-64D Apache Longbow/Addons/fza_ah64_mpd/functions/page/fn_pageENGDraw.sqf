#include "\fza_ah64_mpd\headers\mfdConstants.h"
#include "\fza_ah64_controls\headers\wcaConstants.h"
params ["_heli", "_mpdIndex"];

private _configVehicles = configOf _heli >> "CfgVehicles";
private _flightModel    = getText (_configVehicles >> "flightModel");

// #region ENGINE 1
private _e1np   = (_heli getVariable "fza_sfmplus_engPctNP" select 0) * 100;
private _e1ng   = (_heli getVariable "fza_sfmplus_engPctNG" select 0) * 1000;
private _e1tgt  = _heli getVariable "fza_sfmplus_engTGT" select 0;
private _e1trq  = (_heli getVariable "fza_sfmplus_engPctTQ" select 0) * 100;
private _e1opsi = (_heli getVariable "fza_sfmplus_engOilPSI" select 0) * 100;
if (_e1np <= (0.37 * 100)) then {
	_e1trq = 0;
};

_heli setUserMfdValue [MFD_INDEX_OFFSET(MFD_IND_ENG_TORQUE_1), round _e1trq];
_heli setUserMFDText [MFD_INDEX_OFFSET(MFD_TEXT_IND_ENG_TORQUE_1), _e1trq toFixed 0];

_heli setUserMfdValue [MFD_INDEX_OFFSET(MFD_IND_ENG_NP_1), round _e1np];
_heli setUserMFDText [MFD_INDEX_OFFSET(MFD_TEXT_IND_ENG_NP_1), _e1np toFixed 0];

_heli setUserMfdValue [MFD_INDEX_OFFSET(MFD_IND_ENG_TGT_1), round _e1tgt];
_heli setUserMFDText [MFD_INDEX_OFFSET(MFD_TEXT_IND_ENG_TGT_1), _e1tgt toFixed 0];

_heli setUserMFDText [MFD_INDEX_OFFSET(MFD_TEXT_IND_ENG_NG_1), (_e1ng/10) toFixed 1];
_heli setUserMFDText [MFD_INDEX_OFFSET(MFD_TEXT_IND_ENG_OIL_PSI_1), _e1opsi toFixed 0];

// #region ENGINE 2
private _e2np   = (_heli getVariable "fza_sfmplus_engPctNP" select 1) * 100;
private _e2ng   = (_heli getVariable "fza_sfmplus_engPctNG" select 1) * 1000;
private _e2tgt  = _heli getVariable "fza_sfmplus_engTGT" select 1;
private _e2trq  = (_heli getVariable "fza_sfmplus_engPctTQ" select 1) * 100;
private _e2opsi = (_heli getVariable "fza_sfmplus_engOilPSI" select 1) * 100;
if (_e2np <= (0.37 * 100)) then {
	_e2trq = 0;
};

_heli setUserMfdValue [MFD_INDEX_OFFSET(MFD_IND_ENG_TORQUE_2), round _e2trq];
_heli setUserMFDText [MFD_INDEX_OFFSET(MFD_TEXT_IND_ENG_TORQUE_2), _e2trq toFixed 0];

_heli setUserMfdValue [MFD_INDEX_OFFSET(MFD_IND_ENG_NP_2), round _e2np];
_heli setUserMFDText [MFD_INDEX_OFFSET(MFD_TEXT_IND_ENG_NP_2), _e2np toFixed 0];

_heli setUserMfdValue [MFD_INDEX_OFFSET(MFD_IND_ENG_TGT_2), round _e2tgt];
_heli setUserMFDText [MFD_INDEX_OFFSET(MFD_TEXT_IND_ENG_TGT_2), _e2tgt toFixed 0];

_heli setUserMFDText [MFD_INDEX_OFFSET(MFD_TEXT_IND_ENG_NG_2), (_e2ng/10) toFixed 1];
_heli setUserMFDText [MFD_INDEX_OFFSET(MFD_TEXT_IND_ENG_OIL_PSI_2), _e2opsi toFixed 0];

// #region ROTORS
private _rotorRpm = 0.0;
if (_flightModel == "SFMPlus") then {
 	_rotorRpm = ((_heli animationPhase "mainrotorRPM") * 1.08) * 10;
	_rotorRpm = [_rotorRpm, 0.0, _e1Np max _e2Np] call BIS_fnc_clamp;
} else {
	_rotorRpm = _e1Np max _e2Np;
};
_heli setUserMfdValue [MFD_INDEX_OFFSET(MFD_IND_ENG_NR), round _rotorRpm];
_heli setUserMFDText  [MFD_INDEX_OFFSET(MFD_TEXT_IND_ENG_NR), _rotorRpm toFixed 0];

//TODO: Change so sound occurs even if not in engine page
/*
if (_rotorRpm > 110 && isengineon _heli && (getpos _heli select 2) > 5 && !fza_ah64_warnHighRpm) then {
	[_heli, 1, "engineWarning", "fza_ah64_rotor_rpm_high", 1.5] call fza_audio_fnc_addASEMessage;
	
	fza_ah64_warnHighRpm = true;
};
if !(_rotorRpm > 110 && isengineon _heli && (getpos _heli select 2) > 5) then {
	fza_ah64_warnHighRpm = false;
};*/

private _airMode = getpos _heli select 2 > 1;
_heli setUserMfdValue [MFD_INDEX_OFFSET(MFD_IND_ENG_MODE), [0, 1] select _airMode];
_heli setUserMfdValue [MFD_INDEX_OFFSET(MFD_IND_ENG_TGT_BAR), 965];
_heli setUserMfdValue [MFD_INDEX_OFFSET(MFD_IND_ENG_TORQUE_BAR), 125];

private _engineStates = _heli getVariable "fza_sfmplus_engState";

private _engineStarted = 0;

if (_engineStates # 0 in ["STARTING", "STARTED"]) then {
    _engineStarted = 1;
};

if (_engineStates # 1 in ["STARTING", "STARTED"]) then {
    _engineStarted = 2;
};

_heli setUserMfdValue [MFD_INDEX_OFFSET(MFD_IND_ENG_START), _engineStarted];
if (_airMode) then {
	private _wcas = [_heli] call fza_fnc_coreGetWCAs;
	_wcas resize 6;
	_wcas = _wcas apply {[_x, [WCA_ADVISORY, ""]] select (isNil "_x")};
	{
		_heli setUserMFDText [MFD_INDEX_OFFSET(_forEachIndex + MFD_IND_ENG_WCA_1), _x # 1];
		_heli setUserMFDValue [MFD_INDEX_OFFSET(_forEachIndex + MFD_IND_ENG_WCA_1), _x # 0];
	} forEach _wcas;
};

//Hydraulics
private _priHydPSI       = round(_heli getVariable "fza_systems_priHydPsi");
private _priHydPSI_text  = format["%1", [str _priHydPSI, 4] call fza_fnc_padString];
private _utilHydPSI      = round(_heli getVariable "fza_systems_utilHydPsi");
private _utilHydPSI_text = format["%1", [str _utilHydPSI, 4] call fza_fnc_padString];
private _accHydPSI       = round((_heli getVariable "fza_systems_accHydPsi") / 10) * 10;
private _accHydPSI_text  = format["%1", [str _accHydPSI, 4] call fza_fnc_padString];

_heli setUserMFDText [MFD_INDEX_OFFSET(MFD_TEXT_IND_ENG_PRI_HYD_PSI),  _priHydPSI_text];
_heli setUserMFDText [MFD_INDEX_OFFSET(MFD_TEXT_IND_ENG_UTIL_HYD_PSI), _utilHydPSI_text];
_heli setUserMFDText [MFD_INDEX_OFFSET(MFD_TEXT_IND_ENG_ACC_HYD_PSI),  _accHydPSI_text];