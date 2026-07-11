/* ----------------------------------------------------------------------------
Function: fza_sfmplus_fnc_tunerInterpolate

Description:
    Linearly interpolates EVERY dragtable's per-band values between two ANCHOR
    bands, en masse. You set two bands (e.g. hover and 90 kt) by hand on each
    table; this fills every band strictly BETWEEN them by straight-line
    interpolation of that table's own two anchor values, leaving the anchors and
    any bands outside the range untouched. A tuning aid so you don't have to
    hand-dial every intermediate band on every table.

    Operates on the tuner WORKING MAP (uiNamespace "fza_sfmplus_tunerValues"):
    groups all spec entries of type "dragtable" by their target table variable,
    and for each table reads the two anchors' current working values and writes the
    interpolated in-between values back through fza_sfmplus_fnc_tunerSetValue (so
    each change applies live to the aircraft and persists in the working map).

Parameters:
    _fromIdx - Lower anchor band INDEX (0..8) [Number].
    _toIdx   - Upper anchor band INDEX (0..8) [Number].

Returns:
    [tablesTouched, bandsChanged] [Array]; [-1,-1] on invalid input.

Author:
    BradMick
---------------------------------------------------------------------------- */
params ["_fromIdx", "_toIdx"];

private _spec   = uiNamespace getVariable ["fza_sfmplus_tunerSpec", []];
private _values = uiNamespace getVariable ["fza_sfmplus_tunerValues", createHashMap];

//Only the FORCE/TUNING tables are interpolated. Two kinds of dragtable are EXCLUDED:
//  1. Flight-control TARGET tables (var name contains "_target"): these hold the real
//     AH-64 flight-test data (cyclic/pedal/attitude positions). Interpolating them
//     would overwrite known measured values with straight-line guesses - never touch.
//  2. Fuselage front/side DRAG CD tables: indexed by pressure ALTITUDE, not airspeed
//     band, so filling them across airspeed anchors is meaningless.
private _excluded =
[
    "fza_sfmplus_fuselageFrontDragCoefTable",
    "fza_sfmplus_fuselageSideDragCoefTable"
];

//Group every ELIGIBLE dragtable spec row by its table variable: tableVar -> [[band,key],...].
private _byTable = createHashMap;
{
    if ((_x get "type") == "dragtable") then {
        (_x get "target") params ["_tv", "_ri"];
        //Skip flight-test target tables (known data) and the altitude-indexed drag tables.
        if (!(_tv in _excluded) && {!(_tv find "_target" >= 0)}) then {
            private _rows = _byTable getOrDefault [_tv, []];
            _rows pushBack [_ri, _x get "key"];
            _byTable set [_tv, _rows];
        };
    };
} forEach _spec;

if (count _byTable == 0) exitWith { [-1, -1] };

//Normalise the anchor indices once (same anchors applied to every table).
_fromIdx = round _fromIdx;
_toIdx   = round _toIdx;
if (_fromIdx > _toIdx) then { private _t = _fromIdx; _fromIdx = _toIdx; _toIdx = _t; };
//Need at least one band strictly between the two anchors.
if ((_toIdx - _fromIdx) < 2 || _fromIdx < 0) exitWith { [-1, -1] };

private _tablesTouched = 0;
private _bandsChanged  = 0;

{
    private _rows = _byTable get _x;
    _rows sort true;   // by band index ascending
    private _n = count _rows;

    //Validate against THIS table's band count; skip tables that can't span it.
    if (_fromIdx >= 0 && _toIdx <= (_n - 1) && (_toIdx - _fromIdx) >= 2) then {
        private _keyFrom = (_rows select _fromIdx) select 1;
        private _keyTo   = (_rows select _toIdx)   select 1;
        private _valFrom = _values getOrDefault [_keyFrom, 1.0];
        private _valTo   = _values getOrDefault [_keyTo,   1.0];

        private _touched = false;
        for "_i" from (_fromIdx + 1) to (_toIdx - 1) do {
            private _f   = (_i - _fromIdx) / (_toIdx - _fromIdx);   // 0..1 across the span
            private _v   = _valFrom + ((_valTo - _valFrom) * _f);
            private _key = (_rows select _i) select 1;
            [_key, _v] call fza_sfmplus_fnc_tunerSetValue;   // applies live + updates map
            _bandsChanged = _bandsChanged + 1;
            _touched = true;
        };
        if (_touched) then { _tablesTouched = _tablesTouched + 1; };
    };
} forEach (keys _byTable);

[_tablesTouched, _bandsChanged]
