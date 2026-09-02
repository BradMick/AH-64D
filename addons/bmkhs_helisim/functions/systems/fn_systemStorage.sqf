/* ----------------------------------------------------------------------------
Function: bmkhs_fnc_systemStorage

Description:
    Runs every store the aircraft declares - accumulators, batteries. A store
    is a producer that holds a charge, so it can supply before anything
    upstream has been solved, and refills once something upstream is.

    That is what makes a cold aircraft startable: the accumulator is full at
    init, discharges to start the APU, and the APU turning the pumps is what
    refills it. The crew sees the low caution appear and then clear, which is
    nothing more than charge against spentBelow.

    Charge is state, not supply - which is why storage is evaluated FIRST, and
    why a start draw does not need anything else solved to be spent.

    A store DISCHARGES only while nothing else is supplying its output, so a
    healthy circuit leaves the reserve alone.

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

private _storage = _heli getVariable ["bmkhs_sysStorage", []];
if (_storage isEqualTo []) exitWith {};

private _circuits = _heli getVariable ["bmkhs_sysCircuits", createHashMap];

{
    private _varName = _x get "varName";
    private _nominal = _x get "nominal";
    private _charge  = _heli getVariable [_varName + "Charge", 1.0];

    private _damage  = [_heli, _x get "damageRole", _x get "index"] call bmkhs_fnc_damageGet;
    //Anything else that drains this store - a gun or pylons venting a shared reservoir -
    //adds to its damage rather than being a second mechanism. _comp, not _x: the inner
    //forEach rebinds _x to the role name.
    private _comp = _x;
    {
        _damage = _damage + ([_heli, _x] call bmkhs_fnc_damageGet);
    } forEach (_comp get "drainedBy");
    private _damaged = _damage > SYS_COMP_DMG_THRESH;

    private _gate   = _x get "gate";
    private _gateOn = _gate == "" || {_heli getVariable [_gate, false]};

    //A damaged store LEAKS, whatever it holds. Separate from discharging: a holed
    //reservoir empties whether or not anything is drawing from it, and the rate ramps
    //from the onset threshold to full damage rather than stepping through bands.
    private _leakStart = _x get "leakStartDmg";
    if (_leakStart > 0 && _damage > _leakStart) then {
        private _frac = ((_damage - _leakStart) / (1 - _leakStart)) min 1;
        private _rate = _x get "leakRate";
        _charge = (_charge - (_rate * _frac * _deltaTime)) max 0;
    };

    //Start draw - a source that cannot spin itself up takes a slug of stored energy
    //to get going. Debited ONCE on the gate rising, latched, or it would empty the
    //store in under a second. The latch clears when the gate drops, so a shutdown
    //re-arms the next start.
    private _startedBy = _x get "startedBy";
    if (_startedBy != "") then {
        private _latchVar  = _varName + "Drawn";
        private _startGate = _heli getVariable [_startedBy, false];
        if (_startGate) then {
            if !(_heli getVariable [_latchVar, false]) then {
                _charge = (_charge - (_x get "startDischarge")) max 0;
                _heli setVariable [_latchVar, true];
            };
        } else {
            _heli setVariable [_latchVar, false];
        };
    };

    //Is anything else already holding this node up? If so the store is a reserve
    //sitting in hand, not a supply.
    private _circuit  = _x get "output";
    private _elseFeed = if (_circuit == "") then {0} else {_circuits getOrDefault [_circuit, 0]};

    private _spentFrac = if (_nominal > 0) then {(_x get "spentBelow") / _nominal} else {0};
    private _live      = !_damaged && _gateOn && _charge > _spentFrac;

    if (_live && _elseFeed <= 0) then {
        private _drain = _x get "emerRate";
        if (_drain > 0) then { _charge = (_charge - (_drain * _deltaTime)) max 0 };
    };

    //Refill from whatever feeds it, which is never the node it supplies - a store
    //recharging from its own output would top itself up forever.
    private _rechargedBy = _x get "rechargedBy";
    if (_rechargedBy != "" && _charge < 1.0) then {
        if (([_heli, _rechargedBy] call bmkhs_fnc_systemCircuit) > 0) then {
            private _rate = _x get "rampRate";
            if (_rate > 0) then { _charge = (_charge + (_rate * _deltaTime)) min 1.0 };
        };
    };

    _heli setVariable [_varName + "Charge", _charge];
    _heli setVariable [_varName, _charge * _nominal];

    //Only contributes to the node while it is actually the one supplying it.
    if (_circuit != "" && _live && _elseFeed <= 0) then {
        _circuits set [_circuit, _elseFeed max (_charge * _nominal)];
    };
} forEach _storage;

_heli setVariable ["bmkhs_sysCircuits", _circuits];
