/* ----------------------------------------------------------------------------
Function: fza_sfmplus_fnc_tunerApply

Description:
    Applies a set of tuner values to a helicopter. Iterates the tuner spec
    (fza_sfmplus_fnc_tunerVariables) and pushes each value onto its target:
        - "scalar" / "bool" -> _heli setVariable [target, value]
        - "dragtable"       -> rebuild a [[band, value], ...] table variable from
                               all of its per-band rows (target [tableVar, row, band])

    Tables are re-read from the heli variable each frame by the force functions,
    so setting them here takes effect live. Then restores the persisted master-
    tuned force tables (saved under a separate profile key by fn_tunerSave).

    Values not present in the supplied map fall back to the spec default, so a
    partial map (e.g. only the values the user changed) is valid.

Parameters:
    _heli   - The helicopter to apply the values to [Object].
    _values - HashMap of key -> value (key matches spec "key"). May be partial.

Returns:
    Nothing.

Examples:
    [_heli, _values] call fza_sfmplus_fnc_tunerApply;

Author:
    BradMick
---------------------------------------------------------------------------- */
params ["_heli", ["_values", createHashMap]];

if (isNull _heli) exitWith {};

private _spec = call fza_sfmplus_fnc_tunerVariables;

//Drag table rows are collected here and rebuilt into full tables in a second
//pass: tableVar -> array of [rowIndex, paBand, cd].
private _dragTables = createHashMap;

{
    private _entry   = _x;
    private _key     = _entry get "key";
    private _type    = _entry get "type";
    private _target  = _entry get "target";
    private _default = _entry get "default";
    private _value   = _values getOrDefault [_key, _default];

    switch (_type) do {
        case "scalar";
        case "bool": {
            _heli setVariable [_target, _value];
        };
        case "dragtable": {
            _target params ["_tableVar", "_rowIndex", "_paBand"];
            private _rows = _dragTables getOrDefault [_tableVar, []];
            _rows pushBack [_rowIndex, _paBand, _value];
            _dragTables set [_tableVar, _rows];
        };
    };
} forEach _spec;

//Second pass: rebuild each drag table variable in row order.
{
    private _tableVar = _x;
    private _rows     = _y;
    _rows sort true;   // by rowIndex (first element)
    private _table = _rows apply { [_x select 1, _x select 2] };  // [PA, CD]
    _heli setVariable [_tableVar, _table];
} forEach _dragTables;

//Restore the persisted master-tuned FORCE TABLES (saved by fn_tunerSave under a
//separate profile key). Written straight onto the aircraft - the force functions
//read these fza_sfmplus_tune_* variables directly, so restoring here at init
//makes the tuned tables the effective values from the first frame. Only tables
//that were actually saved (tuned off 1.0) are present, so untouched surfaces
//keep their source defaults.
private _savedTables = profileNamespace getVariable ["fza_sfmplus_tuner_forceTables", []];
if (_savedTables isEqualType [] && {count _savedTables > 0}) then {
    (call fza_sfmplus_fnc_tunerForceTables) params ["_ftBands", "_ftTables"];
    private _validVars = _ftTables apply { _x select 0 };
    {
        _x params ["_var", "_tbl"];
        //Guard: only restore known force-table vars with a well-formed table.
        if ((_var in _validVars) && {_tbl isEqualType []} && {count _tbl > 0}) then {
            _heli setVariable [_var, _tbl];
        };
    } forEach _savedTables;
};
