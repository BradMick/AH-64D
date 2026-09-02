/* ----------------------------------------------------------------------------
Function: bmkhs_fnc_systemConverter

Description:
    Runs every converter the aircraft declares. A converter consumes from one
    circuit and produces onto another - a rectifier taking AC and making DC, an
    inverter doing the reverse, a gearbox taking one shaft speed and giving
    another.

    It CREATES nothing. Without its input it has nothing to pass on, which is
    the whole difference between it and a source.

    Direction is data: swap input and output and a rectifier is an inverter, so
    a DC-generator aircraft needs no code here.

Parameters:
    _heli      - The helicopter [Object]
    _deltaTime - Frame time [Number]

Returns:
    Nothing - circuit values are accumulated into bmkhs_sysCircuits

Author:
    BradMick
---------------------------------------------------------------------------- */
params ["_heli", "_deltaTime"];
#include "\bmkhs_helisim\functions\systems\systems.hpp"

private _converters = _heli getVariable ["bmkhs_sysConverters", []];
if (_converters isEqualTo []) exitWith {};

private _circuits   = _heli getVariable ["bmkhs_sysCircuits", createHashMap];

{
    private _comp    = _x;
    private _varName = _x get "varName";

    private _damaged = ([_heli, _x get "damageRole", _x get "index"] call bmkhs_fnc_damageGet)
                            > SYS_COMP_DMG_THRESH;

    private _gateOn = true;
    {
        if !(_heli getVariable [_x, false]) exitWith { _gateOn = false };
    } forEach (_comp get "gates");

    //What it has to work with. Nothing in, nothing out.
    private _inVal = [_heli, _x get "input"] call bmkhs_fnc_systemCircuit;
    private _hasIn = _inVal > (_x get "minInput");

    //A fixed nominal converts to a level - a rectifier makes DC or it does not. Without
    //one it scales its input, which is what a gearbox ratio does.
    private _nominal = _x get "nominal";
    private _out     = 0;
    if (!_damaged && _gateOn && _hasIn) then {
        _out = if (_nominal > 0) then {_nominal} else {_inVal * (_x get "ratio")};
    };

    private _step = _x get "increment";
    if (_step > 0) then { _out = round (_out / _step) * _step };

    if (_x get "networked") then {
        [_heli, _varName, _out] call bmkhs_fnc_utilUpdateNetworkGlobal;
    } else {
        _heli setVariable [_varName, _out];
    };

    private _stateVar = _x get "stateVar";
    if (_stateVar != "") then {
        [_heli, format ["bmkhs_%1", _stateVar], _out >= (_x get "stateAbove")]
            call bmkhs_fnc_utilUpdateNetworkGlobal;
    };

    //Everything it feeds, with the same clutch and ratio rules a source has.
    {
        private _circuit = _x get "circuit";
        if (_circuit == "") then { continue };

        private _clutch = _x get "disengageOn";
        if (_clutch != "" && {([_heli, _clutch] call bmkhs_fnc_systemCircuit) >= (_x get "disengageAt")}) then {
            continue;
        };

        private _fixed = _x get "nominal";
        private _val   = if (_out <= 0) then {0} else {
            if (_fixed > 0) then {_fixed} else {_out * (_x get "ratio")}
        };

        _circuits set [_circuit, (_circuits getOrDefault [_circuit, 0]) max _val];
        private _feedVar = "bmkhs_sysProducerFeed_" + _circuit;
        _heli setVariable [_feedVar, (_heli getVariable [_feedVar, 0]) max _val];
    } forEach (_comp get "outputs");
} forEach _converters;

_heli setVariable ["bmkhs_sysCircuits", _circuits];
