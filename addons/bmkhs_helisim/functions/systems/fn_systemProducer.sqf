/* ----------------------------------------------------------------------------
Function: bmkhs_fnc_systemProducer

Description:
    Runs every producer the aircraft declares - pumps, generators, the APU.
    A producer feeds its circuit while undamaged, gated on, and driven fast
    enough, scaled by whatever it draws from, ramping toward its target.

    Damage is read AT THE MEMBER'S INDEX - the role alone returns the worst
    member, which would fail every generator because one is destroyed.

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

private _producers = _heli getVariable ["bmkhs_sysProducers", []];
if (_producers isEqualTo []) exitWith {};

private _circuits = _heli getVariable ["bmkhs_sysCircuits", createHashMap];

{
    private _varName = _x get "varName";
    private _nominal = _x get "nominal";

    private _damaged = ([_heli, _x get "damageRole", _x get "index"] call bmkhs_fnc_damageGet)
                            > SYS_COMP_DMG_THRESH;

    //No gate means always armed. A gated component switched off is not failed.
    private _gate    = _x get "gate";
    private _gateOn  = _gate == "" || {_heli getVariable [_gate, false]};

    //Per-component threshold: an autorotating rotor drives hydraulics at 0.45 but not
    //generators at 0.85.
    private _drivenBy = _x get "drivenBy";
    private _driven   = _drivenBy == ""
                     || {([_heli, _drivenBy] call bmkhs_fnc_systemCircuit) > (_x get "minDrive")};

    //Scales rather than gates, so a leak shows as falling pressure. Still closes the
    //chain: no fluid is no pressure.
    private _requires = _x get "requires";
    private _supply   = if (_requires == "") then {1} else {
        //Full output down to the level where it loses prime, zero below that.
        private _level = _heli getVariable [_requires, 1];
        private _min   = _heli getVariable ["bmkhs_hydMinLevel", 0.1];
        (linearConversion [_min, 1, _level, 0, 1, true])
    };

    //A shaft passes its drive speed along instead of a fixed value.
    private _out_val = if (_x get "passthrough") then {[_heli, _drivenBy] call bmkhs_fnc_systemCircuit} else {_nominal};

    private _target  = ([0, _out_val] select (!_damaged && _gateOn && _driven)) * _supply;
    private _current = _heli getVariable [_varName, 0];

    //rampRate 0 means instant - a generator contactor closes, it does not spool.
    private _rate = _x get "rampRate";
    private _out  = if (_rate <= 0) then {
        _target
    } else {
        private _step = _rate * _deltaTime;
        if (_current < _target) then {(_current + _step) min _target} else {(_current - _step) max _target};
    };

    _heli setVariable [_varName, _out];

    //Highest feeder wins the node.
    private _circuit = _x get "output";
    if (_circuit != "") then {
        _circuits set [_circuit, (_circuits getOrDefault [_circuit, 0]) max _out];
    };
} forEach _producers;

_heli setVariable ["bmkhs_sysCircuits", _circuits];
