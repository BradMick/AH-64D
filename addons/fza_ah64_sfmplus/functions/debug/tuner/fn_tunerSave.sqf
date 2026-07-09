/* ----------------------------------------------------------------------------
Function: fza_sfmplus_fnc_tunerSave

Description:
    Persists a set of tuner values to profileNamespace so they survive across
    sessions. Only values that differ from the spec default are stored, keeping
    the persisted footprint small and letting new defaults take effect for
    untouched parameters after a mod update.

    Persistence format is a flat array of [key, value] pairs.

Parameters:
    _values - HashMap of key -> value to persist.

Returns:
    Nothing.

Examples:
    [_values] call fza_sfmplus_fnc_tunerSave;

Author:
    BradMick
---------------------------------------------------------------------------- */
params [["_values", createHashMap]];

private _spec  = call fza_sfmplus_fnc_tunerVariables;
private _saved = [];

{
    private _key     = _x get "key";
    private _default = _x get "default";
    private _value   = _values getOrDefault [_key, _default];

    //Store only non-default values.
    if (!(_value isEqualTo _default)) then {
        _saved pushBack [_key, _value];
    };
} forEach _spec;

profileNamespace setVariable ["fza_sfmplus_tuner", _saved];

//Persist the master-tuned FORCE TABLES too. They live on the aircraft (not in
//_values), so read them straight off the vehicle. Stored as [var, table] pairs,
//separate key so a spec change never clobbers them. Only tables that were
//actually tuned (any band off 1.0) are stored.
private _heli = vehicle player;
if (!isNull _heli) then {
    (call fza_sfmplus_fnc_tunerForceTables) params ["_ftBands", "_ftTables"];
    private _savedTables = [];
    {
        _x params ["_var", "", "", "", ["_base", 1.0]];
        private _tbl = _heli getVariable [_var, []];
        if (!(_tbl isEqualTo [])) then {
            private _tuned = false;
            { if ((abs ((_x select 1) - _base)) > 0.0005) exitWith { _tuned = true; }; } forEach _tbl;
            if (_tuned) then { _savedTables pushBack [_var, _tbl]; };
        };
    } forEach _ftTables;
    profileNamespace setVariable ["fza_sfmplus_tuner_forceTables", _savedTables];
};

saveProfileNamespace;
