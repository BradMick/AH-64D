/* ----------------------------------------------------------------------------
Function: bmkhs_fnc_interactStartSwitch

Description:
    Sets start switch state for the engine sim.

Parameters:
    _heli   - The helicopter to get information from [Unit].
    _engNum - The desired engine.

Returns:
    Whether to register a click (boolean).

Examples:
    ...

Author:
    BradMick
---------------------------------------------------------------------------- */
params ["_heli", "_engNum", "_action"];

if (_heli getVariable "fza_ah64_rtrbrake") exitWith {};

private _engState = _heli getVariable "bmkhs_engState" select _engNum;

_heli animateSource [(["plt_eng1_start", "plt_eng2_start"] select _engNum), 0.5, 0.2];

switch (_action) do {
    case "START": {
        if (_engState isEqualTo "OFF") exitWith {
            [_heli, "bmkhs_engState", _engNum, "STARTING", true] call bmkhs_fnc_setArrayVariable;
        };
        true;
    };
    case "IGN ORDIE": {
        if (_engState isEqualTo "STARTING") exitWith {
            [_heli, "bmkhs_engState", _engNum, "OFF", true] call bmkhs_fnc_setArrayVariable;
        };
        true;
    };
    default {
        false;
    };
};
