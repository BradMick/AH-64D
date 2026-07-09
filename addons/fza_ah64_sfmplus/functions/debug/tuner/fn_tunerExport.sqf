/* ----------------------------------------------------------------------------
Function: fza_sfmplus_fnc_tunerExport

Description:
    Builds a paste-ready code block from the current tuner values and copies it
    to the clipboard. Only values that differ from the mod default are emitted.

    The block is designed to be pasted once into fn_coreConfig.sqf (which runs at
    aircraft init). Because every tuneable parameter reads its value with
    getVariable ["<key>", <default>], setting the variable at init makes the
    tuned value the effective baked-in default everywhere it is consumed - so the
    user does not have to hand-edit each scattered source line.

        - scalar / bool params  -> _heli setVariable ["<key>", <value>];
        - pid params            -> (_heli getVariable "<pidVar>") set ["<field>", <value>];
          (one set per tuned field; the PID hashmaps already exist by the time
          the tuner block runs at the end of fn_coreConfig.sqf)

Parameters:
    _values - HashMap of key -> value (the current working set).

Returns:
    The exported string (also placed on the clipboard).

Examples:
    [_values] call fza_sfmplus_fnc_tunerExport;

Author:
    BradMick
---------------------------------------------------------------------------- */
params [["_values", createHashMap]];

private _spec = call fza_sfmplus_fnc_tunerVariables;

//Helper: format a value as pasteable SQF (bool as true/false, number trimmed).
private _fnFmt = {
    params ["_v"];
    if (_v isEqualType true) then {
        if (_v) then { "true" } else { "false" };
    } else {
        //Trim trailing zeros for readability but keep enough precision.
        private _s = _v toFixed 6;
        while { (count _s > 1) && { (_s select [count _s - 1]) == "0" } } do {
            _s = _s select [0, count _s - 1];
        };
        if ((_s select [count _s - 1]) == ".") then { _s = _s + "0"; };
        _s
    };
};

private _scalarLines = [];

//Drag tables: gather all rows per table (whether or not each differs from
//default) so an edited table can be emitted whole. tableVar -> [[row,PA,CD,changed]]
private _dragTables    = createHashMap;
private _dragTableDirty = createHashMap;

{
    private _key     = _x get "key";
    private _type    = _x get "type";
    private _target  = _x get "target";
    private _default = _x get "default";
    private _value   = _values getOrDefault [_key, _default];
    private _changed = !(_value isEqualTo _default);

    switch (_type) do {
        case "scalar";
        case "bool": {
            if (_changed) then {
                _scalarLines pushBack format ["    _heli setVariable [""%1"", %2];", _target, [_value] call _fnFmt];
            };
        };
        case "dragtable": {
            _target params ["_tableVar", "_rowIndex", "_paBand"];
            private _rows = _dragTables getOrDefault [_tableVar, []];
            _rows pushBack [_rowIndex, _paBand, _value];
            _dragTables set [_tableVar, _rows];
            if (_changed) then { _dragTableDirty set [_tableVar, true]; };
        };
    };
} forEach _spec;

//Emit one full-table rebuild line per table that has any edited row.
private _dragLines = [];
{
    private _tableVar = _x;
    if (_dragTableDirty getOrDefault [_tableVar, false]) then {
        private _rows = _y;
        _rows sort true;   // by rowIndex
        private _pairs = _rows apply { format ["[%1, %2]", _x select 1, [_x select 2] call _fnFmt] };
        _dragLines pushBack format ["    _heli setVariable [""%1"", [%2]];", _tableVar, _pairs joinString ", "];
    };
} forEach _dragTables;

private _out = "// === AH-64D Flight Model Tuner - tuned values ===" + endl;
_out = _out + "// Paste this block near the end of fn_coreConfig.sqf to bake" + endl;
_out = _out + "// these values in as defaults." + endl;

if (count _scalarLines == 0 && count _dragLines == 0) then {
    _out = _out + "// (all values at default - nothing to export)" + endl;
} else {
    if (count _scalarLines > 0) then {
        _out = _out + endl + "// --- Flight model scalars / overrides ---" + endl;
        { _out = _out + _x + endl; } forEach _scalarLines;
    };
    if (count _dragLines > 0) then {
        _out = _out + endl + "// --- Fuselage tables ([band, value] rows) ---" + endl;
        { _out = _out + _x + endl; } forEach _dragLines;
    };
};

//--- FORCE SCALAR TABLES (master-tuned) --------------------------------------
//These airspeed-indexed tables are edited live by the master tuner, band by
//band. They are not in the general spec, so emit them here from the live heli
//variables. Each is written as a FULL table (all bands) so untuned bands keep
//their current value and the block is directly pasteable. Grouped/labelled by
//the source file + local variable they should replace.
private _heli = vehicle player;
if (!isNull _heli) then {
    (call fza_sfmplus_fnc_tunerForceTables) params ["_ftBands", "_ftTables"];

    //Only emit tables that differ from an all-ones (untuned) default, so a fresh
    //session doesn't dump four identity tables.
    private _ftLines = [];
    {
        _x params ["_var", "_label", "_srcFile", "_srcHint", ["_base", 1.0]];
        private _tbl = _heli getVariable [_var, []];
        if (!(_tbl isEqualTo [])) then {
            //Is any value meaningfully off its untuned baseline? (i.e. actually tuned)
            private _tuned = false;
            { if ((abs ((_x select 1) - _base)) > 0.0005) exitWith { _tuned = true; }; } forEach _tbl;
            if (_tuned) then {
                private _pairs = _tbl apply { format ["[%1, %2]", (_x select 0) toFixed 2, [_x select 1] call _fnFmt] };
                _ftLines pushBack format ["// %1  ->  %2 (%3)", _label, _srcFile, _srcHint];
                _ftLines pushBack format ["    _heli setVariable [""%1"", [%2]];", _var, _pairs joinString ", "];
            };
        };
    } forEach _ftTables;

    if (count _ftLines > 0) then {
        _out = _out + endl + "// --- Force scalar tables (master-tuned) ---" + endl;
        { _out = _out + _x + endl; } forEach _ftLines;
    };
};

copyToClipboard _out;
hint "Tuner values copied to clipboard.";

_out
