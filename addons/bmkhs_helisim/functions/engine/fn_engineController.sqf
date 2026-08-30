/* ----------------------------------------------------------------------------
Function: bmkhs_fnc_engineController

Description:
    Monitors and controls engine states.

Parameters:
    _heli      - The helicopter to get information from [Unit].

Returns:
    ...

Examples:
    ...

Author:
    BradMick
---------------------------------------------------------------------------- */
params ["_heli"];
#include "\bmkhs_helisim\headers\core.hpp"
#include "\bmkhs_helisim\headers\systems.hpp"

private _config         = configOf _heli >> "BMKHS_HeliSim";
private _configVehicles = configOf _heli;

private _apuOn     = _heli getVariable ["bmkhs_apuOn", true];
private _onGnd     = [_heli] call bmkhs_fnc_onGround;

private _engState  = _heli getVariable "bmkhs_engState";
private _eng1State = _engState select 0;
private _eng2State = _engState select 1;

private _engPwrLvrState  = _heli getVariable "bmkhs_engPowerLeverState";
private _eng1PwrLvrState = _engPwrLvrState select 0;
private _eng2PwrLvrState = _engPwrLvrState select 1;

private _eng1Np  = _heli getVariable "bmkhs_engPctNP" select 0;
private _eng2Np  = _heli getVariable "bmkhs_engPctNP" select 1;
private _rtrRPM  = _heli getVariable "bmkhs_rtrRPM";

private _eng1TQ   = _heli getVariable "bmkhs_engPctTQ" select 0;
private _eng2TQ   = _heli getVariable "bmkhs_engPctTQ" select 1;
private _engPctTQ = _eng1TQ max _eng2TQ;
private _eng1FuelAvail = _heli getVariable ["bmkhs_eng1FuelAvail", true];
private _eng2FuelAvail = _heli getVariable ["bmkhs_eng2FuelAvail", true];

private _shiftLocked = _heli getVariable "bmkhs_shiftLocked";
private _isSingleEng     = _heli getVariable "bmkhs_isSingleEng";
//private _isAutorotating  = _heli getVariable "bmkhs_isAutorotating";


if (local _heli) then {

    /*
    if ((_heli getHitPointDamage "hithrotor") < 1.0) then {
        private _lastRtdUpdate = _heli getVariable ["bmkhs_lastUpdate", 0];
        if (cba_missionTime > _lastRtdUpdate + MIN_TIME_BETWEEN_UPDATES) then {
            private _realRPM = (_heli animationPhase "mainRotorRPM") * 1.08 / 10;
            if (_realRPM > _rtrRPM && _rtrRPM < 0.9) then {
                _heli setHitPointDamage ["hithrotor", 0.9];
            } else {
                _heli setHitPointDamage ["hithrotor", 0.0];
                _heli engineOn true;
            };
            _heli setVariable ["bmkhs_lastUpdate", cba_missionTime];
        };
    } else {
        _heli engineOn false;
    };

    if (_eng1State == "OFF" && _eng2State == "OFF" && _rtrRPM < 0.5) then {
        _heli engineOn false;
        _heli setHitPointDamage ["hithrotor", 0.9];
    };
    */
    if ((_heli getHitPointDamage "hithrotor") > 0.9) then {
        _heli engineOn false;
    } else {
        if (_eng1State != "OFF" || _eng2State != "OFF" || _rtrRPM >= 0.5) then {
            _heli engineOn true;
        } else {
            _heli engineOn false;
        };
    };
    if (_eng1State == "OFF" && _eng2State == "OFF" && _rtrRPM < 0.1) then { //prevents player holding shift causing Rotor spinning
        _heli engineOn false;
        _heli setHitPointDamage ["hithrotor", 0.9];
        if (!_shiftLocked) then {
            _heli setVariable ["bmkhs_shiftLocked", true];
        };
    } else {
        if (_shiftLocked) then {
            _heli setVariable ["bmkhs_shiftLocked", false];
            _heli setHitPointDamage ["hithrotor", 0];
        };
    };
};


if !_apuOn then {
    if (_eng1State == "STARTING") then {
		[_heli, "bmkhs_engState", 0, "OFF", true] call bmkhs_fnc_setArrayVariable;
    };
    if (_eng2State == "STARTING") then {
		[_heli, "bmkhs_engState", 1, "OFF", true] call bmkhs_fnc_setArrayVariable;
    };
};

// Single engine when: one engine is OFF/damaged, or one power lever is at IDLE
// while the other is at FLY (lever-induced single engine operation).
private _eng1Active = (_eng1State in ["STARTING","ON"]) && (_eng1PwrLvrState == "FLY");
private _eng2Active = (_eng2State in ["STARTING","ON"]) && (_eng2PwrLvrState == "FLY");
_isSingleEng = !(_eng1Active && _eng2Active);
_heli setVariable ["bmkhs_isSingleEng", _isSingleEng];

if (isMultiplayer && (currentPilot _heli == player || local _heli) && (_heli getVariable "bmkhs_lastTimePropagated") + 0.1 < time) then {
    {
        _heli setVariable [_x, _heli getVariable _x, true];
    } forEach [
        "bmkhs_apuRPM_pct",
        "bmkhs_engFF",
        "bmkhs_engPctNG",
        "bmkhs_engPctNP",
        "bmkhs_engPctTQ",
        "bmkhs_engBaseTGT",
        "bmkhs_engTGT",
        "bmkhs_engBaseOilPSI",
        "bmkhs_engOilPSI",
        "bmkhs_engState",
        "bmkhs_engFF",
        "bmkhs_collectiveOutput",
        "bmkhs_xmsnOutputRpm",
        "bmkhs_xmsnDeltaRpm"
    ];
    _heli setVariable ["bmkhs_lastTimePropagated", time, true];
};

if (currentPilot _heli == player || local _heli) then {
    [_heli, 0] call bmkhs_fnc_engine;
    [_heli, 1] call bmkhs_fnc_engine;

    if (bmkhs_rotorModel == 1) then {
        [_heli, 0] call bmkhs_fnc_engineBET;
        [_heli, 1] call bmkhs_fnc_engineBET;
    } else {
        [_heli, 0] call bmkhs_fnc_engine2;
        [_heli, 1] call bmkhs_fnc_engine2;
    };
};

private _no1EngDmg = _heli getHitPointDamage "hitengine1";
private _no2EngDmg = _heli getHitPointDamage "hitengine2";

if (_no1EngDmg > SYS_ENG_DMG_THRESH || !_eng1FuelAvail) then {
	[_heli, "bmkhs_engState", 0, "OFF", true] call bmkhs_fnc_setArrayVariable;
};

if (_no2EngDmg > SYS_ENG_DMG_THRESH || !_eng2FuelAvail) then {
	[_heli, "bmkhs_engState", 1, "OFF", true] call bmkhs_fnc_setArrayVariable;
};

//Autorotation handler
/*
private _velXY = vectorMagnitude [velocityModelSpace _heli # 0, velocityModelSpace _heli # 1];
if (   _engPctTQ < 0.10
    && !_onGnd
    && _rtrRPM > EPSILON) then {
    _heli setVariable ["bmkhs_isAutorotating", true];
} else {
    _heli setVariable ["bmkhs_isAutorotating", false];
};
*/
//systemChat format ["_isAutorotating = %1", _heli getVariable "bmkhs_isAutorotating"];
//End Autorotation handler
