/* ----------------------------------------------------------------------------
Function: bmkhs_fnc_systemProducer

Description:
    Runs every producer the aircraft declares - pumps, generators, the APU -
    whatever domain they belong to. A producer puts a value onto a circuit
    while all of:

        its own damage is below threshold
        AND its gate is open, or it has no gate
        AND whatever drives it is turning fast enough, or nothing drives it

    scaled by whatever it draws from, so a pump losing fluid makes falling
    pressure rather than full pressure until it abruptly makes none.

    Output RAMPS toward its target rather than snapping. A pump that starts
    turning builds pressure from where it is; one that stops bleeds down. The
    ramp is what makes a start look like a start.

    Damage is read AT THE MEMBER'S INDEX. Reading the role without one returns
    the worst of all members, which would take every generator offline because
    one of them is destroyed.

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

    //No gate declared means always armed. A gated component that is switched off is
    //not failed - it just contributes nothing.
    private _gate    = _x get "gate";
    private _gateOn  = _gate == "" || {_heli getVariable [_gate, false]};

    //Whatever drives it has to be turning fast enough. An autorotating rotor drives
    //the hydraulics at 0.45 but not the generators at 0.85, which is why the
    //threshold belongs to the component rather than to the circuit.
    private _drivenBy = _x get "drivenBy";
    private _driven   = _drivenBy == ""
                     || {([_heli, _drivenBy] call bmkhs_fnc_systemCircuit) > (_x get "minDrive")};

    //What it draws from SCALES what it makes, rather than gating it. A pump losing fluid
    //makes falling pressure, so the gauge trends down as the reservoir empties and the
    //crew can see a leak developing instead of being told about it only once it fails.
    //Not strictly how a pump behaves, but it is the readable version.
    //
    //Scaling subsumes the gate: no fluid is no pressure, so the leak chain still closes.
    private _requires = _x get "requires";
    private _supply   = if (_requires == "") then {1} else {
        //Full output down to the level where it loses prime, zero below that.
        private _level = _heli getVariable [_requires, 1];
        private _min   = _heli getVariable ["bmkhs_hydMinLevel", 0.1];
        (linearConversion [_min, 1, _level, 0, 1, true])
    };

    //A shaft passes its speed along rather than producing a fixed value - the accessory
    //drive turns at whatever is turning it, and the pumps threshold that themselves.
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
