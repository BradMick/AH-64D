/* ----------------------------------------------------------------------------
Function: fza_sfmplus_fnc_tunerBuildRows

Description:
    (Re)builds the parameter rows for the currently active tuner tab inside the
    scrolling controls group. Clears any existing rows first, then creates one
    row per spec entry whose "tab" matches the active tab, grouped under their
    "group" sub-headers. Each slider / edit / checkbox is wired so a change
    updates the working values map and applies it live via
    fza_sfmplus_fnc_tunerSetValue.

    Split out of fza_sfmplus_fnc_tunerGui so it can be re-run on tab switch and
    on "Reset All" without rebuilding the whole dialog.

Parameters:
    _display - The tuner display [Display].

Returns:
    Nothing.

Author:
    BradMick
---------------------------------------------------------------------------- */
#include "tunerDefines.hpp"

params [["_display", displayNull]];
if (isNull _display) exitWith {};

private _spec      = uiNamespace getVariable ["fza_sfmplus_tunerSpec", []];
private _values    = uiNamespace getVariable ["fza_sfmplus_tunerValues", createHashMap];
private _tabs      = uiNamespace getVariable ["fza_sfmplus_tunerTabs", []];
private _activeIdx = uiNamespace getVariable ["fza_sfmplus_tunerActiveTab", 0];
private _activeTab = _tabs param [_activeIdx, ""];

private _group = _display displayCtrl FZA_SFMPLUS_TUNER_IDC_GROUP;

//Clear existing rows. ctrlParent of a control created inside a controls group
//returns the display (not the group), so we cannot filter allControls by parent
//reliably; instead we track every row control we create on the group itself and
//delete exactly those on rebuild.
{
    if (!isNull _x) then { ctrlDelete _x; };
} forEach (_group getVariable ["rowControls", []]);
private _rowControls = [];

//Row IDC scheme: each row reserves a block so sub-controls have stable IDCs.
//  base + rowIndex*10 + 0 : label
//  base + rowIndex*10 + 1 : slider  (scalar / pid)
//  base + rowIndex*10 + 2 : edit    (scalar / pid)
//  base + rowIndex*10 + 3 : checkbox(bool)

private _rowH      = 0.032;
private _pad       = 0.006;
private _y         = 0.0;
private _grpW      = ctrlPosition _group select 2;
private _lastGroup = "";
private _rowIndex  = 0;

//Balance tab: a live attitude/rate readout + control-position readout at the very
//top, refreshed by the GUI PFH (see fn_tunerGui.sqf). Tracked in uiNamespace.
uiNamespace setVariable ["fza_sfmplus_tunerBalanceLabel", controlNull];
uiNamespace setVariable ["fza_sfmplus_tunerBalanceWarn",  controlNull];
if (_activeTab == "Balance") then {
    private _rate = _display ctrlCreate ["fza_sfmplus_TunerText", -1, _group];
    _rate ctrlSetPosition [0.0, _y, _grpW, _rowH];
    _rate ctrlSetFontHeight 0.028;
    _rate ctrlSetText "Body rates: gathering...";
    _rate ctrlSetTextColor [0.7, 0.9, 1, 1];
    _rate ctrlCommit 0;
    _rowControls pushBack _rate;
    uiNamespace setVariable ["fza_sfmplus_tunerBalanceLabel", _rate];
    _y = _y + _rowH + _pad;

    private _warn = _display ctrlCreate ["fza_sfmplus_TunerText", -1, _group];
    _warn ctrlSetPosition [0.0, _y, _grpW, _rowH];
    _warn ctrlSetFontHeight 0.028;
    _warn ctrlSetText "";
    _warn ctrlSetTextColor [1, 0.7, 0.3, 1];
    _warn ctrlCommit 0;
    _rowControls pushBack _warn;
    uiNamespace setVariable ["fza_sfmplus_tunerBalanceWarn", _warn];
    _y = _y + _rowH + _pad;
};

//Airframe tab: a single EN-MASSE interpolation control set at the very top. You
//enter two anchor speeds (kt) and hit Interpolate; every airspeed-banded table has
//its bands BETWEEN those two anchors linearly filled from that table's own anchor
//values. One control, applies to ALL dragtables at once (not per-table).
if (_activeTab == "Airframe") then {
    private _bandsKt = [0, 20, 40, 70, 90, 100, 120, 130, 140];   // band -> kt (labels)
    uiNamespace setVariable ["fza_sfmplus_tunerInterpBandsKt", _bandsKt];

    private _lbl = _display ctrlCreate ["fza_sfmplus_TunerText", -1, _group];
    _lbl ctrlSetPosition [0.0, _y, _grpW * 0.30, _rowH];
    _lbl ctrlSetText "Interpolate all tables:";
    _lbl ctrlSetTextColor [1, 0.85, 0.4, 1];
    _lbl ctrlCommit 0;
    _rowControls pushBack _lbl;

    private _lblFrom = _display ctrlCreate ["fza_sfmplus_TunerText", -1, _group];
    _lblFrom ctrlSetPosition [_grpW * 0.30, _y, _grpW * 0.09, _rowH];
    _lblFrom ctrlSetText "from kt";
    _lblFrom ctrlCommit 0;
    _rowControls pushBack _lblFrom;

    private _edFrom = _display ctrlCreate ["fza_sfmplus_TunerEdit", -1, _group];
    _edFrom ctrlSetPosition [_grpW * 0.39, _y, _grpW * 0.10, _rowH];
    _edFrom ctrlSetText "0";
    _edFrom ctrlCommit 0;
    _rowControls pushBack _edFrom;
    uiNamespace setVariable ["fza_sfmplus_tunerInterpFrom", _edFrom];

    private _lblTo = _display ctrlCreate ["fza_sfmplus_TunerText", -1, _group];
    _lblTo ctrlSetPosition [_grpW * 0.50, _y, _grpW * 0.06, _rowH];
    _lblTo ctrlSetText "to kt";
    _lblTo ctrlCommit 0;
    _rowControls pushBack _lblTo;

    private _edTo = _display ctrlCreate ["fza_sfmplus_TunerEdit", -1, _group];
    _edTo ctrlSetPosition [_grpW * 0.56, _y, _grpW * 0.10, _rowH];
    _edTo ctrlSetText "90";
    _edTo ctrlCommit 0;
    _rowControls pushBack _edTo;
    uiNamespace setVariable ["fza_sfmplus_tunerInterpTo", _edTo];

    private _btn = _display ctrlCreate ["fza_sfmplus_TunerButton", -1, _group];
    _btn ctrlSetPosition [_grpW * 0.68, _y, _grpW * 0.30, _rowH];
    _btn ctrlSetText "Interpolate";
    _btn ctrlSetBackgroundColor [0.2, 0.3, 0.2, 1];
    _btn ctrlCommit 0;
    _rowControls pushBack _btn;
    _btn ctrlAddEventHandler ["ButtonClick", {
        params ["_ctrl"];
        private _display = ctrlParent _ctrl;
        private _bandsKt = uiNamespace getVariable ["fza_sfmplus_tunerInterpBandsKt", []];
        private _fromKt  = parseNumber (ctrlText (uiNamespace getVariable ["fza_sfmplus_tunerInterpFrom", controlNull]));
        private _toKt    = parseNumber (ctrlText (uiNamespace getVariable ["fza_sfmplus_tunerInterpTo",   controlNull]));
        //Map each entered speed to the NEAREST band index.
        private _fnNearest = {
            params ["_kt"];
            private _best = 0; private _bestErr = 1e9;
            { private _e = abs (_kt - _x); if (_e < _bestErr) then { _bestErr = _e; _best = _forEachIndex; }; } forEach _bandsKt;
            _best
        };
        private _fromIdx = [_fromKt] call _fnNearest;
        private _toIdx   = [_toKt]   call _fnNearest;
        ([_fromIdx, _toIdx] call fza_sfmplus_fnc_tunerInterpolate) params ["_tables", "_bands"];
        private _status = _display displayCtrl FZA_SFMPLUS_TUNER_IDC_STATUS;
        if (_tables < 0) then {
            _status ctrlSetText "Interpolate: pick two anchor speeds with bands between them.";
        } else {
            _status ctrlSetText format ["Interpolated %1 bands across %2 tables (%3-%4 kt).",
                _bands, _tables, _bandsKt select _fromIdx, _bandsKt select _toIdx];
            //Rebuild so the filled values show in the rows.
            _display call fza_sfmplus_fnc_tunerBuildRows;
        };
    }];

    _y = _y + _rowH + _pad;
};

//The per-generator forces readout lives in the non-blocking overlay panel; it is
//not a dialog tab. Keep the force log OFF here so it only runs while the overlay
//is up (the overlay enables it itself).
{
    private _entry = _x;
    if ((_entry get "tab") == _activeTab) then {
        private _key     = _entry get "key";
        private _label   = _entry get "label";
        private _grpName = _entry get "group";
        private _type    = _entry get "type";
        private _default = _entry get "default";
        private _min     = _entry get "min";
        private _max     = _entry get "max";
        private _value   = _values getOrDefault [_key, _default];

        //Sub-group header when the group changes.
        if (_grpName != _lastGroup) then {
            _lastGroup = _grpName;
            private _hdr = _display ctrlCreate ["fza_sfmplus_TunerText", -1, _group];
            _hdr ctrlSetPosition [0.0, _y, _grpW, _rowH];
            _hdr ctrlSetFontHeight 0.028;
            _hdr ctrlSetText ("  " + _grpName);
            _hdr ctrlSetBackgroundColor [0.18, 0.18, 0.18, 0.9];
            _hdr ctrlSetTextColor [1, 0.85, 0.4, 1];
            _hdr ctrlCommit 0;
            _rowControls pushBack _hdr;
            _y = _y + _rowH + _pad;
        };

        private _idcBase = FZA_SFMPLUS_TUNER_ROW_IDC_BASE + _rowIndex * 10;

        //Label
        private _lbl = _display ctrlCreate ["fza_sfmplus_TunerText", _idcBase, _group];
        _lbl ctrlSetPosition [0.0, _y, _grpW * 0.46, _rowH];
        _lbl ctrlSetText _label;
        _lbl ctrlCommit 0;
        _rowControls pushBack _lbl;

        switch (_type) do {
            case "scalar";
            case "dragtable": {
                //Slider
                private _sld = _display ctrlCreate ["fza_sfmplus_TunerSlider", _idcBase + 1, _group];
                _sld ctrlSetPosition [_grpW * 0.47, _y, _grpW * 0.34, _rowH];
                _sld sliderSetRange [_min, _max];
                _sld sliderSetSpeed [(_max - _min) / 100, (_max - _min) / 20];
                _sld sliderSetPosition _value;
                _sld setVariable ["key", _key];
                _sld setVariable ["editIdc", _idcBase + 2];
                _sld ctrlCommit 0;
                _sld ctrlAddEventHandler ["SliderPosChanged", {
                    params ["_ctrl", "_val"];
                    private _k    = _ctrl getVariable "key";
                    private _eIdc = _ctrl getVariable "editIdc";
                    (ctrlParent _ctrl displayCtrl _eIdc) ctrlSetText (_val toFixed 5);
                    [_k, _val] call fza_sfmplus_fnc_tunerSetValue;
                }];
                _rowControls pushBack _sld;

                //Edit (manual entry)
                private _edt = _display ctrlCreate ["fza_sfmplus_TunerEdit", _idcBase + 2, _group];
                _edt ctrlSetPosition [_grpW * 0.82, _y, _grpW * 0.18, _rowH];
                _edt ctrlSetText (_value toFixed 5);
                _edt setVariable ["key", _key];
                _edt setVariable ["sliderIdc", _idcBase + 1];
                _edt ctrlCommit 0;
                _edt ctrlAddEventHandler ["KillFocus", {
                    params ["_ctrl"];
                    private _k    = _ctrl getVariable "key";
                    private _sIdc = _ctrl getVariable "sliderIdc";
                    private _val  = parseNumber (ctrlText _ctrl);
                    private _sld  = ctrlParent _ctrl displayCtrl _sIdc;
                    _sld sliderSetPosition _val;   // clamps to range visually
                    [_k, _val] call fza_sfmplus_fnc_tunerSetValue;
                }];
                _rowControls pushBack _edt;
            };
            case "bool": {
                private _cb = _display ctrlCreate ["fza_sfmplus_TunerCheckbox", _idcBase + 3, _group];
                _cb ctrlSetPosition [_grpW * 0.47, _y, _rowH, _rowH];
                _cb cbSetChecked _value;
                _cb setVariable ["key", _key];
                _cb ctrlCommit 0;
                _cb ctrlAddEventHandler ["CheckedChanged", {
                    params ["_ctrl", "_checked"];
                    private _k = _ctrl getVariable "key";
                    [_k, _checked > 0] call fza_sfmplus_fnc_tunerSetValue;
                }];
                _rowControls pushBack _cb;
            };
        };

        _y = _y + _rowH + _pad;
        _rowIndex = _rowIndex + 1;
    };
} forEach _spec;

//Remember the controls we created so the next rebuild can delete exactly these.
_group setVariable ["rowControls", _rowControls];

//The controls group derives its scrollable content height automatically from
//the bounding box of its child controls, so no explicit content sizing needed.
