/* ----------------------------------------------------------------------------
Function: bmkhs_fnc_systemsDebug

Description:
    Shows what the component graph is doing - every circuit's value, every
    component's output, and whether it is awake or asleep.

    Turn it on in CBA settings - Addon Options, "Enable Systems Debugging",
    beside the FM one. It takes over the hint while up, so the flight model's
    panel is suppressed rather than the two overwriting each other.

    A component reading SLEEP is not being solved, because nothing it depends
    on changed. If something is stuck, look there first: asleep when it should
    be running means its input signature is missing whatever actually changed.

Parameters:
    _heli - The helicopter [Object]

Returns:
    Nothing

Author:
    BradMick
---------------------------------------------------------------------------- */
params ["_heli"];

if !(bmkhs_sysDebug) exitWith {};

private _txt = "== CIRCUITS ==<br/>";

private _feeds = _heli getVariable ["bmkhs_sysFeeds", createHashMap];
{
    private _node    = _feeds getOrDefault [_x, createHashMap];
    private _circuit = _x;
    private _sources = "";
    {
        private _v = _node get _x;
        if (_v > 0) then { _sources = _sources + format ["%1 ", _x] };
    } forEach (keys _node);
    _txt = _txt + format ["%1 = %2  [%3]<br/>",
        _circuit,
        ([_heli, _circuit] call bmkhs_fnc_systemCircuit) toFixed 2,
        _sources];
} forEach (keys (_heli getVariable ["bmkhs_sysCircuits", createHashMap]));

//Components. Awake or asleep is the thing to look at when something is stuck.
{
    _x params ["_list", "_label"];
    if !(_list isEqualTo []) then {
        _txt = _txt + format ["<br/>== %1 ==<br/>", _label];
        {
            private _v = _x get "varName";
            _txt = _txt + format ["%1 = %2  %3<br/>",
                _v,
                _heli getVariable [_v, 0],
                ["SLEEP", "awake"] select (parseNumber (_heli getVariable [_v + "Awake", true]))];
            //Which gate is holding it shut, if any.
            private _comp = _x;
            private _gs = "";
            {
                private _n = if (_x isEqualType []) then {_x select 0} else {_x};
                private _r = if (_x isEqualType []) then {
                    ([_heli, _x select 0] call bmkhs_fnc_systemCircuit) >= (_x select 1)
                } else {
                    _heli getVariable [_x, false]
                };
                _gs = _gs + format ["%1=%2 ", _n, _r];
            } forEach (_comp get "gates");
            if (_gs != "") then { _txt = _txt + format ["   gates: %1<br/>", _gs] };
        } forEach _list;
    };
} forEach [
    [_heli getVariable ["bmkhs_sysProducers",  []], "PRODUCERS"],
    [_heli getVariable ["bmkhs_sysConverters", []], "CONVERTERS"],
    [_heli getVariable ["bmkhs_sysStorage",    []], "STORAGE"]
];

//What the aircraft reads back out.
_txt = _txt + "<br/>== PUBLISHED ==<br/>";
{
    _txt = _txt + format ["%1 = %2<br/>", _x, _heli getVariable [_x, "nil"]];
} forEach ["bmkhs_apuBtnOn", "bmkhs_apuOn", "bmkhs_apuRPM_pct", "bmkhs_accHydPsiStartOk",
           "bmkhs_battSwitchOn", "bmkhs_battBusOn", "bmkhs_acBusOn", "bmkhs_dcBusOn",
           "bmkhs_pneuAvail", "bmkhs_accHydPsi", "bmkhs_priHydPsi", "bmkhs_utilHydPsi"];

hintSilent parseText _txt;
