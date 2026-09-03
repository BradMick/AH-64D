/* ----------------------------------------------------------------------------
Function: bmkhs_fnc_systemTorque

Description:
    Damages components run past their torque limits. A drive component is rated
    for a torque, and for how long it will take more than that - the limits are
    the aircraft's, since a gearbox is rated for what it is rated for, and
    accruing damage past one is Core's.

    Limits are declared worst-first as {torque, seconds}: how much it will take
    and how long before that starts costing it. A zero duration damages
    immediately.

    A component already damaged degrades further on its own, faster the worse
    it is, which is what makes an overtorqued gearbox a problem that grows
    rather than a threshold that trips once.

Parameters:
    _heli      - The helicopter [Object]
    _deltaTime - Frame time [Number]

Returns:
    Nothing

Author:
    BradMick
---------------------------------------------------------------------------- */
params ["_heli", "_deltaTime"];
#include "\bmkhs_helisim\functions\systems\systems.hpp"

//Damaged once, where the aircraft is local - this runs outside the solve, so it does not
//inherit the solve's guard.
if !(local _heli) exitWith {};

private _torqued = _heli getVariable ["bmkhs_sysTorqued", []];
if (_torqued isEqualTo []) exitWith {};

{
    private _comp    = _x;
    private _role    = _x get "damageRole";
    private _index   = _x get "index";
    //Single-engine ratings where the aircraft declares them, since one engine doing the
    //work of two is a different case from both sharing it.
    private _limits  = _x get "tqLimits";
    private _seLimits = _x get "tqLimitsSE";
    if ((count _seLimits) > 0 && {_heli getVariable ["bmkhs_isSingleEng", false]}) then {
        _limits = _seLimits;
    };

    //What this component is carrying. Per-member where the source is per-member, so
    //engine 2's torque is what nose gearbox 2 sees.
    private _tqVar = _x get "torqueFrom";
    private _tq    = 0;
    if (_tqVar != "") then {
        private _val = _heli getVariable [_tqVar, 0];
        //Summed where the component carries the lot - a transmission takes both engines'
        //output, while a nose gearbox takes only its own engine's.
        private _sums = _comp get "torqueSum";
        _tq = if !(_val isEqualType []) then {_val} else {
            if (_sums) then {
                private _total = 0;
                { _total = _total + _x } forEach _val;
                _total
            } else {
                _val param [_index, 0]
            };
        };
    };

    private _damage = [_heli, _role, _index] call bmkhs_fnc_damageGet;
    private _accrue = 0;


    //Worst limit first, so the harshest one that applies is the one that counts.
    {
        _x params ["_limit", "_seconds"];
        if (_tq > _limit) exitWith {
            if (_seconds <= 0) then {
                //No grace at all above this.
                _accrue = DMG_PER_SEC;
            } else {
                private _timerVar = format ["bmkhs_tqTimer_%1%2_%3", _role, _index, _forEachIndex];
                private _held = (_heli getVariable [_timerVar, 0]) + _deltaTime;
                _heli setVariable [_timerVar, _held];
                if (_held >= _seconds) then { _accrue = DMG_PER_SEC };
            };
        };
    } forEach _limits;

    //Below every limit, the clocks reset - a brief overtorque is not cumulative.
    if (_accrue <= 0) then {
        {
            _heli setVariable [format ["bmkhs_tqTimer_%1%2_%3", _role, _index, _forEachIndex], 0];
        } forEach _limits;
    };

    //Damage feeds itself: the worse it is, the faster it worsens.
    if (_damage > 0.25) then {
        _accrue = _accrue + (_damage / 600.0);
        if (_damage > 0.50) then { _accrue = _accrue + (_damage / 500.0) };
        if (_damage > 0.75) then { _accrue = _accrue + (_damage / 400.0) };
    };

    if (_accrue > 0) then {
        _damage = _damage + (_accrue * _deltaTime);
        [_heli, _role, _damage, _index] call bmkhs_fnc_damageSet;
    };

    //A destroyed component takes something else with it - a gearbox that has come apart
    //overspeeds the engine driving it.
    private _breaks = _comp get "breaksVar";
    if (_breaks != "") then {
        [_heli, _breaks, _index, _damage >= 1.0, false] call bmkhs_fnc_utilSetArrayVariable;
    };
} forEach _torqued;
