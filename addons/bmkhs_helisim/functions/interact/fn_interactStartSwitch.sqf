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

//Aircraft sets this if it has a rotor brake that inhibits engine operation
if (_heli getVariable ["bmkhs_rotorBrakeOn", false]) exitWith {};

private _engState = _heli getVariable "bmkhs_engState" select _engNum;

[_heli, "startSwitchPressed", [_engNum]] call bmkhs_fnc_notify;

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
