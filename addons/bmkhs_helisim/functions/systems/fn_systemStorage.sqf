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

    private _comp2  = _x;
    //A gate is a switch variable, or a {circuit, threshold} pair read live. The variable
    //form is a frame stale for anything the solve itself publishes, which deadlocks a
    //start: the APU gates on the battery bus, and that is published after producers run.
    //_comp, not _x - the inner forEach rebinds it.
    private _gateOn = true;
    {
        private _ok = if (_x isEqualType []) then {
            ([_heli, _x select 0] call bmkhs_fnc_systemCircuit) >= (_x select 1)
        } else {
            _heli getVariable [_x, false]
        };
        if (!_ok) exitWith { _gateOn = false };
    } forEach (_comp2 get "gates");

    //Leaking is separate from discharging - a holed store empties with nothing drawing
    //from it. Rate ramps from the onset threshold to full damage.
    private _leakStart = _x get "leakStartDmg";
    if (_settle && _leakStart > 0 && _damage > _leakStart) then {
        if (_damage >= 1) then {
            //Destroyed holds nothing at all rather than draining out.
            _charge = 0;
        } else {
            private _frac = ((_damage - _leakStart) / (1 - _leakStart)) min 1;
            private _rate = _x get "leakRate";
            _charge = (_charge - (_rate * _frac * _deltaTime)) max 0;
        };
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

    //Anything else holding its nodes up makes the store a reserve, not a supply. On the
    //settle pass a node already carries this store's own supply, so compare against what
    //the producers put there rather than the total.
    private _outputs  = _x get "outputs";
    private _elseFeed = 0;
    {
        private _c = _x get "circuit";
        if (_c != "") then {
            private _feed = if (_settle) then {_heli getVariable ["bmkhs_sysProducerFeed_" + _c, 0]}
                                         else {_circuits getOrDefault [_c, 0]};
            _elseFeed = _elseFeed max _feed;
        };
    } forEach _outputs;

    private _live      = !_damaged && _gateOn && _charge > _spentFrac;

    //Drains while nothing is covering for it. That is its charging source where it has
    //one - a battery runs down whenever the bus that charges it is dead - and otherwise
    //whatever else feeds its output.
    private _rechargedBy = _x get "rechargedBy";
    private _covered     = if (_rechargedBy != "") then {
        ([_heli, _rechargedBy] call bmkhs_fnc_systemCircuit) > (_x get "minRecharge")
    } else {
        _elseFeed > 0
    };

    if (_settle && _live && !_covered) then {
        private _drain = _x get "emerRate";
        if (_drain > 0) then { _charge = (_charge - (_drain * _deltaTime)) max 0 };
    };

    //Refills whenever something is covering for it, and never from the node it supplies.
    if (_settle && _covered && _rechargedBy != "" && _charge < 1.0) then {
        //Over the usable band rather than the whole range, so the configured time is what
        //it actually takes - a store only ever refills from its floor.
        private _rate = (_x get "rechargeRate") * (1 - _spentFrac);
        if (_rate > 0) then { _charge = (_charge + (_rate * _deltaTime)) min 1.0 };
    };

    //Whether it is up, as a property of the component rather than of any node - the same
    //publish a producer does.
    private _stateVar = _x get "stateVar";
    if (_stateVar != "") then {
        [_heli, format ["bmkhs_%1", _stateVar], (_charge * _nominal) >= (_x get "stateAbove")]
            call bmkhs_fnc_utilUpdateNetworkGlobal;
    };

    _heli setVariable [_varName + "Charge", _charge];
    private _published = _charge * _nominal;
    if (_x get "networked") then {
        [_heli, _varName, _published] call bmkhs_fnc_utilUpdateNetworkGlobal;
    } else {
        _heli setVariable [_varName, _published];
    };

    //Only feeds while it is the one supplying.
    if (_live && _elseFeed <= 0) then {
        {
            private _c = _x get "circuit";
            if (_c != "") then {
                private _fixed = _x get "nominal";
                private _val   = if (_fixed > 0) then {_fixed} else {_charge * _nominal * (_x get "ratio")};
                _circuits set [_c, (_circuits getOrDefault [_c, 0]) max _val];
            };
        } forEach _outputs;
    };
} forEach _storage;

_heli setVariable ["bmkhs_sysCircuits", _circuits];
