/* ----------------------------------------------------------------------------
Function: bmkhs_fnc_interactPowerLever

Description:
    Handles power lever animation

Parameters:
    _heli   - The helicopter to get information from [Unit].
    _engNum - The desired engine.
    _state  - The state of the power lever (OFF, IDLE, FLY).

Returns:
    ...

Examples:
    ...

Author:
    BradMick
---------------------------------------------------------------------------- */
params ["_heli", "_engNum", "_state"];

//Aircraft sets this if it has a rotor brake that inhibits engine operation
if (_heli getVariable ["bmkhs_rotorBrakeOn", false]) exitWith {};

private _engState = _heli getVariable "bmkhs_engState" select _engNum;

if (_state == "OFF") then {
    [_heli, "powerLeverMoved", [_engNum, 0.0]] call bmkhs_fnc_notify;
    [_heli, "bmkhs_engPowerLeverState", _engNum, _state, true] call bmkhs_fnc_setArrayVariable;

    if (_engState == "ON") then {
        [_heli, "bmkhs_engState", _engNum, "OFF", true] call bmkhs_fnc_setArrayVariable;
    };

    //HeliSim
    //[_heli, _engNum, 0.0] call bmk_fnc_engineSetThrottle;
};

if (_state == "IDLE") then {
    [_heli, "powerLeverMoved", [_engNum, 0.25]] call bmkhs_fnc_notify;
    [_heli, "bmkhs_engPowerLeverState", _engNum, _state, true] call bmkhs_fnc_setArrayVariable;

    //HeliSim
    //[_heli, _engNum, 0.25] call bmk_fnc_engineSetThrottle;
};

if (_state == "FLY") then {
    //0.063 sets the power levers to fly in 16 seconds
    [_heli, "powerLeverMoved", [_engNum, 1.0]] call bmkhs_fnc_notify;
    [_heli, "bmkhs_engPowerLeverState", _engNum, _state, true] call bmkhs_fnc_setArrayVariable;
};
