/* ----------------------------------------------------------------------------
Function: fza_sfmplus_fnc_tunerGui

Description:
    Populates and drives the flight model tuner dialog (class fza_sfmplus_tuner,
    see tunerGui.hpp). Called from the display onLoad with the display as its
    argument.

    Builds a tab bar (one button per major section defined by the spec "tab"
    field) and renders the rows for the active tab into the scrolling controls
    group. Switching tabs re-renders the group via fza_sfmplus_fnc_tunerBuildRows.

    The working values map (key -> value) is held in uiNamespace under
    "fza_sfmplus_tunerValues" and is initialised from persisted values via
    fza_sfmplus_fnc_tunerLoad. The active tab index is held under
    "fza_sfmplus_tunerActiveTab".

Parameters:
    _display - The tuner display [Display]. When called from onLoad, _this is
               [_display] so this function accepts either the display or an
               array whose first element is the display.

Returns:
    Nothing.

Author:
    BradMick
---------------------------------------------------------------------------- */
#include "tunerDefines.hpp"

params [["_arg", displayNull]];
private _display = if (_arg isEqualType displayNull) then { _arg } else { _arg param [0, displayNull] };
if (isNull _display) exitWith {};

//Target aircraft: the vehicle the player currently occupies.
private _heli = vehicle player;
uiNamespace setVariable ["fza_sfmplus_tunerHeli", _heli];

//Working values (key -> value): defaults, overlaid with persisted, overlaid with
//the aircraft's current live state - so reopening the dialog shows exactly what
//is applied now (including unsaved session edits).
private _values = [_heli] call fza_sfmplus_fnc_tunerLoad;
uiNamespace setVariable ["fza_sfmplus_tunerValues", _values];

private _spec = call fza_sfmplus_fnc_tunerVariables;
uiNamespace setVariable ["fza_sfmplus_tunerSpec", _spec];

//Distinct tabs in first-seen order (Airframe, Mass & Balance, Environment,
//Balance). The per-generator forces readout lives in the non-blocking overlay,
//not as a dialog tab.
private _tabs = [];
{ _tabs pushBackUnique (_x get "tab"); } forEach _spec;
uiNamespace setVariable ["fza_sfmplus_tunerTabs", _tabs];

//Active tab always starts at the first tab when the dialog is (re)opened.
uiNamespace setVariable ["fza_sfmplus_tunerActiveTab", 0];

//----------------------------------------------------------------------------
// Tab bar
//----------------------------------------------------------------------------
private _tabBar = _display displayCtrl FZA_SFMPLUS_TUNER_IDC_TABBAR;

private _tabBarW  = ctrlPosition _tabBar select 2;
private _tabCount = count _tabs;
private _tabW     = _tabBarW / _tabCount;

//Track the tab buttons on the tab-bar control so the click handler can recolour
//them (ctrlParent of a grouped control returns the display, not the group, so
//we cannot filter allControls by parent).
private _tabButtons = [];

{
    private _idx = _forEachIndex;
    private _btn = _display ctrlCreate ["fza_sfmplus_TunerButton", FZA_SFMPLUS_TUNER_TAB_IDC_BASE + _idx, _tabBar];
    _btn ctrlSetPosition [_idx * _tabW, 0.0, _tabW - 0.002, 0.038];
    _btn ctrlSetText _x;
    _btn ctrlSetFontHeight 0.024;
    _btn setVariable ["tabIndex", _idx];
    //Highlight the active (first) tab.
    if (_idx == 0) then {
        _btn ctrlSetBackgroundColor [0.35, 0.35, 0.15, 1];
    } else {
        _btn ctrlSetBackgroundColor [0.15, 0.15, 0.15, 0.9];
    };
    _btn ctrlCommit 0;
    _btn ctrlAddEventHandler ["ButtonClick", {
        params ["_ctrl"];
        private _idx     = _ctrl getVariable "tabIndex";
        private _display = ctrlParent _ctrl;
        uiNamespace setVariable ["fza_sfmplus_tunerActiveTab", _idx];
        //Recolour tab buttons.
        {
            if (!isNull _x) then {
                if ((_x getVariable ["tabIndex", -1]) == _idx) then {
                    _x ctrlSetBackgroundColor [0.35, 0.35, 0.15, 1];
                } else {
                    _x ctrlSetBackgroundColor [0.15, 0.15, 0.15, 0.9];
                };
            };
        } forEach (uiNamespace getVariable ["fza_sfmplus_tunerTabButtons", []]);
        //Rebuild rows for the newly active tab.
        _display call fza_sfmplus_fnc_tunerBuildRows;
    }];
    _tabButtons pushBack _btn;
} forEach _tabs;

uiNamespace setVariable ["fza_sfmplus_tunerTabButtons", _tabButtons];

//----------------------------------------------------------------------------
// Rows for the active tab
//----------------------------------------------------------------------------
_display call fza_sfmplus_fnc_tunerBuildRows;

//----------------------------------------------------------------------------
// Button bar wiring
//----------------------------------------------------------------------------
private _btnSave  = _display displayCtrl FZA_SFMPLUS_TUNER_IDC_BTN_SAVE;
private _btnCopy  = _display displayCtrl FZA_SFMPLUS_TUNER_IDC_BTN_COPY;
private _btnReset = _display displayCtrl FZA_SFMPLUS_TUNER_IDC_BTN_RESET;
private _btnClose = _display displayCtrl FZA_SFMPLUS_TUNER_IDC_BTN_CLOSE;

_btnSave ctrlAddEventHandler ["ButtonClick", {
    private _values = uiNamespace getVariable ["fza_sfmplus_tunerValues", createHashMap];
    [_values] call fza_sfmplus_fnc_tunerSave;
    private _status = (ctrlParent (_this select 0)) displayCtrl FZA_SFMPLUS_TUNER_IDC_STATUS;
    _status ctrlSetText "Saved to profile.";
}];

_btnCopy ctrlAddEventHandler ["ButtonClick", {
    private _values = uiNamespace getVariable ["fza_sfmplus_tunerValues", createHashMap];
    [_values] call fza_sfmplus_fnc_tunerExport;
    private _status = (ctrlParent (_this select 0)) displayCtrl FZA_SFMPLUS_TUNER_IDC_STATUS;
    _status ctrlSetText "Copied code to clipboard.";
}];

_btnReset ctrlAddEventHandler ["ButtonClick", {
    //Reset all values to defaults, apply, and rebuild the active tab.
    private _display = ctrlParent (_this select 0);
    private _spec    = call fza_sfmplus_fnc_tunerVariables;
    private _heli    = uiNamespace getVariable ["fza_sfmplus_tunerHeli", objNull];

    //EVERY airspeed table whose DEFAULT lives in a source .sqf (seeded when unset).
    //These must be cleared (setVariable nil) so the source functions republish their
    //edited-in-source arrays next frame - NOT overwritten by the tuner spec defaults.
    private _sourceTables =
    [
        "fza_sfmplus_tune_mainThrustTable", "fza_sfmplus_tune_rtrTqScalarTable",
        "fza_sfmplus_tune_tailThrustTable", "fza_sfmplus_tune_stabLiftScalarTable",
        "fza_sfmplus_tune_finLiftScalarTable", "fza_sfmplus_tune_fuseSideScalarTable",
        "fza_sfmplus_tune_targetPitchTable", "fza_sfmplus_tune_targetRollTable",
        "fza_sfmplus_tune_targetCollTable", "fza_sfmplus_tune_targetCycPitchTable",
        "fza_sfmplus_tune_targetCycRollTable", "fza_sfmplus_tune_targetPedalTable"
    ];

    //Build the reset values from spec defaults, but SKIP the source tables so
    //fza_sfmplus_fnc_tunerApply doesn't write spec defaults over them.
    private _values = createHashMap;
    {
        private _entry = _x;
        private _isSourceRow = ((_entry get "type") == "dragtable") &&
            { ((_entry get "target") select 0) in _sourceTables };
        if (!_isSourceRow) then { _values set [_entry get "key", _entry get "default"]; };
    } forEach _spec;
    uiNamespace setVariable ["fza_sfmplus_tunerValues", _values];
    [_heli, _values] call fza_sfmplus_fnc_tunerApply;

    //Now clear every source table so it republishes from its .sqf source next frame.
    { _heli setVariable [_x, nil]; } forEach _sourceTables;

    //The FORCE tables (main/tail/rbs/etc.) re-seed inside their per-frame source
    //functions (fn_simpleRotorMain/Tail, fn_coreUpdateFlightModel), which run every
    //frame and refill a nil var. But the flight-control TARGET tables are seeded ONLY
    //at aircraft init by fn_tunerTargets - it does NOT run per frame - so after nil-ing
    //them nothing would republish and every target would read [[0,0]] (all tgt = 0.00).
    //Re-call it here so the target tables refill immediately (it seeds only-when-unset,
    //so it's safe/idempotent - it just refills exactly the ones we cleared above).
    [_heli] call fza_sfmplus_fnc_tunerTargets;

    //CRITICAL: wipe the PERSISTED profile too. Otherwise fn_tunerLoad re-overlays the
    //saved values on the next GUI open, and fn_tunerApply re-writes the saved FORCE
    //TABLES onto the aircraft every spawn - so source edits would never take effect.
    //Clearing both saved keys makes the source arrays the effective values again.
    profileNamespace setVariable ["fza_sfmplus_tuner", []];
    profileNamespace setVariable ["fza_sfmplus_tuner_forceTables", []];
    saveProfileNamespace;

    _display call fza_sfmplus_fnc_tunerBuildRows;
    private _status = _display displayCtrl FZA_SFMPLUS_TUNER_IDC_STATUS;
    _status ctrlSetText "Reset - saved profile cleared, all tables reloaded from source.";
}];

//Live-refresh the Balance-tab readout while the dialog is open: attitude vs
//target, body rates, control positions, and the MASTER auto-tuner status.
private _recoPfh = [{
    private _heli = uiNamespace getVariable ["fza_sfmplus_tunerHeli", objNull];
    if (isNull _heli) exitWith {};

    //Balance tab live readout: body rates (deg/s) + current-vs-TARGET attitude.
    private _rateLbl = uiNamespace getVariable ["fza_sfmplus_tunerBalanceLabel", controlNull];
    if (!isNull _rateLbl) then {
        (_heli getVariable ["fza_sfmplus_balance_rates", [0,0,0]]) params ["_rP", "_rR", "_rY"];
        //Current attitude and target attitude at the current airspeed.
        (_heli call BIS_fnc_getPitchBank) params ["_curPitch", "_curRoll"];
        private _spd = vectorMagnitude [(_heli getVariable ["fza_sfmplus_velModelSpace", [0,0,0]]) select 0,
                                        (_heli getVariable ["fza_sfmplus_velModelSpace", [0,0,0]]) select 1];
        private _tgtP = [_heli getVariable ["fza_sfmplus_tune_targetPitchTable", [[0,0]]], _spd] call fza_fnc_linearInterp select 1;
        private _tgtR = [_heli getVariable ["fza_sfmplus_tune_targetRollTable",  [[0,0]]], _spd] call fza_fnc_linearInterp select 1;
        private _errP = _curPitch - _tgtP;
        private _errR = _curRoll  - _tgtR;
        //Master auto-tune status prefix, when it's running.
        private _mAxis = _heli getVariable ["fza_sfmplus_master_axis", "off"];
        private _mPrefix = if (_heli getVariable ["fza_sfmplus_tune_masterOn", false]) then { format ["[MASTER: %1]  ", _mAxis] } else { "" };
        _rateLbl ctrlSetText format ["%1Pitch %2 (tgt %3, err %4)   Roll %5 (tgt %6, err %7)   rates p%8 r%9 y%10",
            _mPrefix,
            _curPitch toFixed 1, _tgtP toFixed 1, _errP toFixed 1,
            _curRoll toFixed 1, _tgtR toFixed 1, _errR toFixed 1,
            _rP toFixed 1, _rR toFixed 1, _rY toFixed 1];
        //Green when both attitude errors are small and rates are near zero.
        private _onTgt = (abs _errP < 0.5) && {abs _errR < 0.5} && {abs _rP < 0.3} && {abs _rR < 0.3} && {abs _rY < 0.3};
        _rateLbl ctrlSetTextColor (if (_onTgt) then { [0.5, 1, 0.5, 1] } else { [0.7, 0.9, 1, 1] });
    };
    //Control-position diagnostic: at a trimmed attitude the cyclic/pedal should
    //sit near center. If a control is far from center while holding attitude, the
    //attitude is being held by an out-of-place control - flags a deeper issue
    //(CoM / stabilator / tail authority) rather than something to trim around.
    private _warnLbl = uiNamespace getVariable ["fza_sfmplus_tunerBalanceWarn", controlNull];
    if (!isNull _warnLbl) then {
        private _coll  = (_heli getVariable ["fza_sfmplus_collectiveOutput", 0.0]) * 100;
        private _cycFA = _heli getVariable ["fza_sfmplus_cyclicFwdAft",    0.0];   // + fwd, - aft
        private _cycLR = _heli getVariable ["fza_sfmplus_cyclicLeftRight", 0.0];   // + left, - right
        private _ped   = _heli getVariable ["fza_sfmplus_pedalLeftRight",  0.0];   // + right, - left
        //Target collective at current speed (from user power-required schedule).
        private _spd2  = vectorMagnitude [(_heli getVariable ["fza_sfmplus_velModelSpace", [0,0,0]]) select 0,
                                          (_heli getVariable ["fza_sfmplus_velModelSpace", [0,0,0]]) select 1];
        private _tgtColl = ([_heli getVariable ["fza_sfmplus_tune_targetCollTable", [[0,0]]], _spd2] call fza_fnc_linearInterp select 1) * 100;
        private _msg = format ["Coll %1%% (tgt %2%%)   cyc fwd+ %3  left+ %4   ped rgt+ %5",
            _coll toFixed 0, _tgtColl toFixed 0, _cycFA toFixed 2, _cycLR toFixed 2, _ped toFixed 2];
        //Flag any cyclic/pedal held well off center in what should be trimmed flight.
        private _off = 0.20;
        if (abs _cycFA > _off) then { _msg = _msg + "  | cyclic FA off-center - check CoM/stab"; };
        if (abs _cycLR > _off) then { _msg = _msg + "  | cyclic LR off-center - check lateral CoM"; };
        if (abs _ped   > _off) then { _msg = _msg + "  | pedal off-center - check tail authority"; };
        _warnLbl ctrlSetText _msg;
        private _flagged = (abs _cycFA > _off) || {abs _cycLR > _off} || {abs _ped > _off};
        _warnLbl ctrlSetTextColor (if (_flagged) then { [1, 0.6, 0.3, 1] } else { [0.7, 0.7, 0.7, 1] });
    };

}, 0.5] call CBA_fnc_addPerFrameHandler;
uiNamespace setVariable ["fza_sfmplus_tunerRecoPfh", _recoPfh];

_btnClose ctrlAddEventHandler ["ButtonClick", {
    (ctrlParent (_this select 0)) closeDisplay 0;
}];
