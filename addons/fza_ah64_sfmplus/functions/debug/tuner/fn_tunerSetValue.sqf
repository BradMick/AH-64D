/* ----------------------------------------------------------------------------
Function: fza_sfmplus_fnc_tunerSetValue

Description:
    Updates a single value in the tuner working map (uiNamespace
    "fza_sfmplus_tunerValues") and applies it live to the tuned aircraft. Used by
    the GUI slider / edit / checkbox event handlers so a change is reflected on
    the flying aircraft immediately.

Parameters:
    _key   - Spec key to update [String].
    _value - New value [Number or Boolean].

Returns:
    Nothing.

Author:
    BradMick
---------------------------------------------------------------------------- */
params ["_key", "_value"];

private _values = uiNamespace getVariable ["fza_sfmplus_tunerValues", createHashMap];
_values set [_key, _value];

private _heli = uiNamespace getVariable ["fza_sfmplus_tunerHeli", objNull];
if (!isNull _heli) then {
    //Apply ONLY the changed key directly to its target - do NOT route through
    //fza_sfmplus_fnc_tunerApply, which iterates the WHOLE spec and resets every
    //other key to its map/default value. That whole-map apply clobbered live state
    //(e.g. re-applied a stale masterOn=false, turning the master off) whenever any
    //field was edited. Here we find just this key's spec entry and write its target.
    private _spec  = uiNamespace getVariable ["fza_sfmplus_tunerSpec", []];
    private _entry = _spec findIf { (_x get "key") == _key };
    if (_entry >= 0) then {
        private _e      = _spec select _entry;
        private _type   = _e get "type";
        private _target = _e get "target";
        switch (_type) do {
            case "scalar";
            case "bool": {
                _heli setVariable [_target, _value];
            };
            case "dragtable": {
                //Rebuild only THIS table from all its spec rows (the other rows'
                //current working-map values), so a single band edit updates the
                //table without touching any other tuner variable.
                _target params ["_tableVar"];
                private _rows = [];
                {
                    private _te = _x;
                    if ((_te get "type") == "dragtable") then {
                        (_te get "target") params ["_tv","_ri","_band"];
                        if (_tv == _tableVar) then {
                            private _v = _values getOrDefault [_te get "key", _te get "default"];
                            _rows pushBack [_ri, _band, _v];
                        };
                    };
                } forEach _spec;
                _rows sort true;
                _heli setVariable [_tableVar, _rows apply { [_x select 1, _x select 2] }];
            };
        };
    };
};
