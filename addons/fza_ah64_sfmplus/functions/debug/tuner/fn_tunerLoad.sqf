/* ----------------------------------------------------------------------------
Function: fza_sfmplus_fnc_tunerLoad

Description:
    Builds a complete tuner values HashMap (key -> value) in priority order:
        1. spec defaults        (always present, so the map is complete)
        2. persisted values     (profileNamespace, written by Save)
        3. live aircraft values (when a _heli is given) - reflects what is
           actually applied right now, including unsaved session edits.

    Passing the aircraft is what lets the GUI reopen showing the current live
    state instead of snapping back to the last-saved/default values.

    Persistence format in profileNamespace is a flat array of [key, value] pairs
    (arrays serialize reliably to profileNamespace; HashMaps do not).

Parameters:
    _heli - Optional aircraft to read current live values from [Object].
            If omitted / null, only defaults + persisted values are used.

Returns:
    HashMap of key -> value for every spec entry.

Examples:
    private _values = [_heli] call fza_sfmplus_fnc_tunerLoad;

Author:
    BradMick
---------------------------------------------------------------------------- */
params [["_heli", objNull]];

private _spec   = call fza_sfmplus_fnc_tunerVariables;
private _values = createHashMap;

//1. Seed with defaults so the map is always complete.
{
    _values set [_x get "key", _x get "default"];
} forEach _spec;

//2. Overlay persisted values (if any).
private _saved = profileNamespace getVariable ["fza_sfmplus_tuner", []];
if (_saved isEqualType [] && {count _saved > 0}) then {
    {
        _x params ["_key", "_value"];
        if (_key in _values) then {
            _values set [_key, _value];
        };
    } forEach _saved;
};

//3. Overlay the live values currently applied to the aircraft. This is the
//   inverse of fza_sfmplus_fnc_tunerApply and keeps the GUI in sync with reality
//   across close/reopen.
if (!isNull _heli) then {
    {
        private _key    = _x get "key";
        private _type   = _x get "type";
        private _target = _x get "target";

        switch (_type) do {
            case "scalar";
            case "bool": {
                private _live = _heli getVariable _target;
                if (!isNil "_live") then { _values set [_key, _live]; };
            };
            case "dragtable": {
                _target params ["_tableVar", "_rowIndex"];
                private _table = _heli getVariable _tableVar;
                if (!isNil "_table" && {_table isEqualType []} && {_rowIndex < count _table}) then {
                    //Row is [PA, CD]; the tuned value is the CD.
                    _values set [_key, (_table select _rowIndex) select 1];
                };
            };
        };
    } forEach _spec;
};

_values
