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

private _useSystems = _heli getVariable ["bmkhs_useSystems", false];
private _producers = _heli getVariable ["bmkhs_sysProducers", []];
if (_producers isEqualTo []) exitWith {};

private _circuits = _heli getVariable ["bmkhs_sysCircuits", createHashMap];

{
    //Not modelled with systems off - its state stays as seeded, which is the vanilla
    //contract: powered up, running, no start procedure.
    if ((_x get "needsSystems") && !_useSystems) then { continue };

    private _varName = _x get "varName";
    private _nominal = _x get "nominal";

    private _damaged = ([_heli, _x get "damageRole", _x get "index"] call bmkhs_fnc_damageGet)
                            > SYS_COMP_DMG_THRESH;

    //No gate means always armed, and every gate declared has to be on. A gated component
    //that is off is not failed - it just contributes nothing.
    private _gateOn = true;
    {
        if !(_heli getVariable [_x, false]) exitWith { _gateOn = false };
    } forEach (_x get "gates");

    //Per-component threshold: an autorotating rotor drives hydraulics at 0.45 but not
    //generators at 0.85.
    private _drivenBy = _x get "drivenBy";
    private _driven   = _drivenBy == ""
                     || {([_heli, _drivenBy] call bmkhs_fnc_systemCircuit) > (_x get "minDrive")};

    //A clutch drops out once something else is driving what it drives - an APU declutches
    //as the rotor comes up to speed and stops contributing.
    private _clutch = _x get "disengageOn";
    if (_clutch != "" && {([_heli, _clutch] call bmkhs_fnc_systemCircuit) >= (_x get "disengageAt")}) then {
        _driven = false;
    };

    //Scales rather than gates, so a leak shows as falling pressure. Still closes the
    //chain: no fluid is no pressure.
    private _requires = _x get "requires";
    private _supply   = if (_requires == "") then {1} else {
        //Full output down to the level where it loses prime, zero below that.
        private _level = _heli getVariable [_requires, 1];
        (linearConversion [_x get "requiresAbove", 1, _level, 0, 1, true])
    };

    //A shaft passes its drive speed along instead of a fixed value.
    private _out_val = if (_x get "passthrough") then {[_heli, _drivenBy] call bmkhs_fnc_systemCircuit} else {_nominal};

    //Something that spools follows its own speed rather than switching on at the end.
    private _driveFrom = _x get "driveFrom";
    if (_driveFrom != "") then {
        _out_val = _out_val * ((_heli getVariable [_driveFrom, 0]) max 0);
    };

    private _target  = ([0, _out_val] select (!_damaged && _gateOn && _driven)) * _supply;
    private _current = _heli getVariable [_varName, 0];

    //Nothing left to move means no pressure at once - a destroyed reservoir does not
    //bleed its pump down gently.
    private _rate = [_x get "rampRate", 0] select (_supply <= 0);
    private _out  = if (_rate <= 0) then {
        _target
    } else {
        private _step = _rate * _deltaTime;
        if (_current < _target) then {(_current + _step) min _target} else {(_current - _step) max _target};
    };

    //Gauges read in steps, not single units.
    private _step = _x get "increment";
    if (_step > 0) then { _out = round (_out / _step) * _step };

    if (_x get "networked") then {
        [_heli, _varName, _out] call bmkhs_fnc_utilUpdateNetworkGlobal;
    } else {
        _heli setVariable [_varName, _out];
    };

    //Highest feeder wins the node. Recorded separately too, so a store can tell whether
    //anything OTHER than itself is supplying its output.
    private _circuit = _x get "output";
    if (_circuit != "") then {
        _circuits set [_circuit, (_circuits getOrDefault [_circuit, 0]) max _out];
        private _feedVar = "bmkhs_sysProducerFeed_" + _circuit;
        _heli setVariable [_feedVar, (_heli getVariable [_feedVar, 0]) max _out];
    };
} forEach _producers;

_heli setVariable ["bmkhs_sysCircuits", _circuits];
