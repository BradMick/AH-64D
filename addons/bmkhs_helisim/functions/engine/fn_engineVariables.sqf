/* ----------------------------------------------------------------------------
Function: bmkhs_fnc_engineVariables

Description:
    Defines core engine variables.

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

if (!(_heli getVariable ["bmkhs_engineInitialised", false]) && local _heli) then {
    _heli setVariable ["bmkhs_engineInitialised", true, true];

    _heli setVariable ["bmkhs_engPowerLeverState",    ["OFF", "OFF"], true]; //OFF, IDLE, FLY
    _heli setVariable ["bmkhs_engState",              ["OFF", "OFF"], true]; //OFF, STARTING, ON
};

if(isMultiplayer) then {
    _heli setVariable ["bmkhs_lastTimePropagated", 0];
};

_heli setVariable ["bmkhs_shiftLocked",           false];
_heli setVariable ["bmkhs_isSingleEng",           false];
//_heli setVariable ["bmkhs_isAutorotating",        false];

//Outputs
_heli setVariable ["bmkhs_engFF",                 [0.0, 0.0]];
_heli setVariable ["bmkhs_engPctNG",              [0.0, 0.0]];
//SEEDS REQUIRED even though nothing READS these: bmkhs_fnc_setArrayVariable does
//`+(_heli getVariable _name)` then `set`, so the array must already exist or it
//throws "Type Number, expected Array". Written per-engine by fn_engine.
_heli setVariable ["bmkhs_engBaseNG",             [0.0, 0.0]];
_heli setVariable ["bmkhs_engBaseTGT",            [0.0, 0.0]];
_heli setVariable ["bmkhs_engBaseOilPSI",         [0.0, 0.0]];
_heli setVariable ["bmkhs_engTrimTq",             [0.0, 0.0]];
_heli setVariable ["bmkhs_engPctNP",              [0.0, 0.0]];
_heli setVariable ["bmkhs_engPctTQ",              [0.0, 0.0]];
_heli setVariable ["bmkhs_engTGT",                [0.0, 0.0]];
_heli setVariable ["bmkhs_engOilPSI",             [0.0, 0.0]];

_heli setVariable ["bmkhs_engOutputTq",           [0.0, 0.0]];

_heli setVariable ["bmkhs_randomTq",              [0.0, 0.0, 0.0, 0.0]];
