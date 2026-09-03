/* ----------------------------------------------------------------------------
Function: bmkhs_fnc_systemsDebug

Description:
    Shows what the component graph is doing - circuits, components, and why a
    component is or is not producing.

    Turn it on in CBA settings - Addon Options, "Enable Systems Debugging",
    beside the FM one. It takes over the hint while up, so the flight model's
    panel is suppressed rather than the two overwriting each other.

    Reading it: a component shows its output, then a flag per condition.
    Lowercase and red means that condition is what is holding it shut.

        G/g  gates    every crew switch and gated circuit
        D/d  drive    whatever turns it, above its own threshold
        F/f  fluid    what it draws from, above empty
        H/h  health   below its damage threshold
        *    awake    still moving toward its target

    So "GDFH *" is running and settling, and "GdFH" has lost its drive.

Parameters:
    _heli - The helicopter [Object]

Returns:
    Nothing

Author:
    BradMick
---------------------------------------------------------------------------- */
params ["_heli"];

if !(bmkhs_sysDebug) exitWith {};

//Values read better rounded - 7.4257e-07 is noise, not information.
private _fmt = {
    params ["_n"];
    if (!(_n isEqualType 0)) exitWith {str _n};
    if (abs _n < 0.001) exitWith {"0"};
    if (abs _n >= 100)  exitWith {str round _n};
    _n toFixed 2
};
private _flag = {
    params ["_ok", "_yes", "_no"];
    if (_ok) then {_yes} else {format ["<t color='#ff7070'>%1</t>", _no]}
};

private _txt = "<t size='0.75'><t color='#88ccff'>CIRCUITS</t><br/>";

private _feeds = _heli getVariable ["bmkhs_sysFeeds", createHashMap];
{
    private _c    = _x;
    private _node = _feeds getOrDefault [_c, createHashMap];
    private _from = "";
    {
        if ((_node get _x) > 0.001) then { _from = _from + (_x select [6]) + " " };
    } forEach (keys _node);

    _txt = _txt + format ["%1 = %2   %3<br/>",
        _c,
        [[_heli, _c] call bmkhs_fnc_systemCircuit] call _fmt,
        _from];
} forEach (keys (_heli getVariable ["bmkhs_sysCircuits", createHashMap]));

{
    _x params ["_list", "_label"];
    if !(_list isEqualTo []) then {
        _txt = _txt + format ["<br/><t color='#88ccff'>%1</t><br/>", _label];
        {
            private _comp = _x;
            private _v    = _comp get "varName";

            private _gOk  = true;
            private _shut = "";
            {
                private _r = if (_x isEqualType []) then {
                    ([_heli, _x select 0] call bmkhs_fnc_systemCircuit) >= (_x select 1)
                } else {
                    _heli getVariable [_x, false]
                };
                if (!_r) then {
                    _gOk = false;
                    private _n = if (_x isEqualType []) then {_x select 0} else {_x select [6]};
                    _shut = _shut + _n + " ";
                };
            } forEach (_comp get "gates");

            private _drv = _comp get "drivenBy";
            private _dOk = _drv == ""
                        || {([_heli, _drv] call bmkhs_fnc_systemCircuit) > (_comp get "minDrive")};

            private _req = _comp get "requires";
            private _fOk = _req == ""
                        || {(_heli getVariable [_req, 1]) > (_comp get "requiresAbove")};

            private _hOk = ([_heli, _comp get "damageRole", _comp get "index"]
                                call bmkhs_fnc_damageGet) <= 0.85;

            _txt = _txt + format ["%1 = %2   %3%4%5%6%7<br/>",
                _v select [6],
                [_heli getVariable [_v, 0]] call _fmt,
                [_gOk, "G", "g"] call _flag,
                [_dOk, "D", "d"] call _flag,
                [_fOk, "F", "f"] call _flag,
                [_hOk, "H", "h"] call _flag,
                ["", " *"] select (parseNumber (_heli getVariable [_v + "Awake", true]))];
            //Name the gates that are shut, so the blocker is on screen.
            if (_shut != "") then {
                _txt = _txt + format ["   <t color='#ff7070'>shut: %1</t><br/>", _shut];
            };
            //Target vs output, which is what the ramp and the awake flag work from.
            if (_label == "PRODUCERS") then {
                _txt = _txt + format ["   tgt %1  ramp %2<br/>",
                    [_heli getVariable [_v + "Tgt", -1]] call _fmt,
                    _comp get "rampRate"];
            };
        } forEach _list;
    };
} forEach [
    [_heli getVariable ["bmkhs_sysProducers",  []], "PRODUCERS"],
    [_heli getVariable ["bmkhs_sysConverters", []], "CONVERTERS"],
    [_heli getVariable ["bmkhs_sysStorage",    []], "STORAGE"]
];

_txt = _txt + "<br/><t color='#88ccff'>PUBLISHED</t><br/>";
{
    {
        _txt = _txt + format ["%1 %2   ", _x select [6], _heli getVariable [_x, "nil"]];
    } forEach _x;
    _txt = _txt + "<br/>";
} forEach [
    ["bmkhs_apuBtnOn", "bmkhs_apuOn", "bmkhs_pneuAvail"],
    ["bmkhs_battSwitchOn", "bmkhs_battBusOn", "bmkhs_acBusOn", "bmkhs_dcBusOn"],
    ["bmkhs_accHydPsiStartOk"]
];

hintSilent parseText (_txt + "</t>");
