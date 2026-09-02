/* ----------------------------------------------------------------------------
Function: bmkhs_fnc_systemStorage

Description:
    Runs every store the aircraft declares - accumulators, batteries.

    Runs TWICE per solve. Charge is state rather than supply, so the first
    pass puts it onto circuits before anything upstream is solved, which is
    what cuts the startup loop. Charge itself can only move once the rest has
    solved, so draining and refilling happen on the settle pass - a store
    reading its own recharge circuit before the producers have run sees zero
    and never refills.

Parameters:
    _heli      - The helicopter [Object]
    _deltaTime - Frame time [Number]
    _settle    - false to put charge onto circuits, true to move charge from the
                 solved result [Bool]

Returns:
    Nothing - circuit values are accumulated into bmkhs_sysCircuits

Author:
    BradMick
---------------------------------------------------------------------------- */
params ["_heli", "_deltaTime", ["_settle", false]];
#include "\bmkhs_helisim\functions\systems\systems.hpp"

private _storage = _heli getVariable ["bmkhs_sysStorage", []];
if (_storage isEqualTo []) exitWith {};

private _circuits = _heli getVariable ["bmkhs_sysCircuits", createHashMap];

{
    private _varName = _x get "varName";
    private _nominal = _x get "nominal";
    private _charge  = _heli getVariable [_varName + "Charge", 1.0];

    private _damage  = [_heli, _x get "damageRole", _x get "index"] call bmkhs_fnc_damageGet;
    //Anything else that vents this store adds to its damage. _comp because the inner
    //forEach rebinds _x.
    private _comp = _x;
    {
        _damage = _damage + ([_heli, _x] call bmkhs_fnc_damageGet);
    } forEach (_comp get "drainedBy");
    private _damaged = _damage > SYS_COMP_DMG_THRESH;

    private _gate   = _x get "gate";
    private _gateOn = _gate == "" || {_heli getVariable [_gate, false]};

    //Leaking is separate from discharging - a holed store empties with nothing drawing
    //from it. Rate ramps from the onset threshold to full damage.
    private _leakStart = _x get "leakStartDmg";
    if (_settle && _leakStart > 0 && _damage > _leakStart) then {
        private _frac = ((_damage - _leakStart) / (1 - _leakStart)) min 1;
        private _rate = _x get "leakRate";
        _charge = (_charge - (_rate * _frac * _deltaTime)) max 0;
    };

    //Below this it is spent - for a gas-charged store this is the precharge, which is
    //not usable pressure.
    private _spentFrac = if (_nominal > 0) then {(_x get "stopBelow") / _nominal} else {0};

    //Spent once when the start gate rises, not per frame - the thing being cranked only
    //comes up seconds later, so a continuous drain empties the store before it does.
    //StartOk latches whether there was enough, since the draw itself drops the store
    //below startAbove and would cut the start it is paying for.
    private _startedBy = _x get "startedBy";
    if (_settle && _startedBy != "") then {
        private _latchVar = _varName + "Drawn";
        private _okVar    = _varName + "StartOk";
        if (_heli getVariable [_startedBy, false]) then {
            if !(_heli getVariable [_latchVar, false]) then {
                private _above = _x get "startAbove";
                private _ok    = _nominal <= 0 || {_charge * _nominal >= _above};
                //A start spends the usable charge, leaving the precharge behind.
                if (_ok && _nominal > 0) then {
                    _charge = _spentFrac;
                };
                _heli setVariable [_okVar,    _ok,  true];
                _heli setVariable [_latchVar, true, true];
            };
        } else {
            _heli setVariable [_latchVar, false, true];
            _heli setVariable [_okVar,    true,  true];
        };
    };

    //Anything else holding this node up makes the store a reserve, not a supply. On the
    //settle pass the node already carries this store own supply, so compare against what
    //the producers put there rather than the total.
    private _circuit  = _x get "output";
    private _elseFeed = if (_circuit == "") then {0} else {
        if (_settle) then {_heli getVariable ["bmkhs_sysProducerFeed_" + _circuit, 0]}
                     else {_circuits getOrDefault [_circuit, 0]}
    };

    private _live      = !_damaged && _gateOn && _charge > _spentFrac;

    if (_settle && _live && _elseFeed <= 0) then {
        private _drain = _x get "emerRate";
        if (_drain > 0) then { _charge = (_charge - (_drain * _deltaTime)) max 0 };
    };

    //Never from the node it supplies, or it would top itself up forever.
    private _rechargedBy = _x get "rechargedBy";
    if (_settle && _rechargedBy != "" && _charge < 1.0) then {
        //Needs its circuit properly up, not merely turning - a spooling APU is not yet
        //driving the pumps that do the refilling.
        if (([_heli, _rechargedBy] call bmkhs_fnc_systemCircuit) > (_x get "minRecharge")) then {
            private _rate = _x get "rechargeRate";
            if (_rate > 0) then { _charge = (_charge + (_rate * _deltaTime)) min 1.0 };
        };
    };

    _heli setVariable [_varName + "Charge", _charge];
    _heli setVariable [_varName, _charge * _nominal];

    //Only feeds the node while it is the one supplying it.
    if (_circuit != "" && _live && _elseFeed <= 0) then {
        _circuits set [_circuit, _elseFeed max (_charge * _nominal)];
    };
} forEach _storage;

_heli setVariable ["bmkhs_sysCircuits", _circuits];
