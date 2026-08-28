fza_sfmplus_keyboardCollective         = true;
fza_sfmplus_keyboardCollectivePrevious = true;

//HOLD SUBMODE LOCK keybinds - PIN the hold submode (pos/vel/att) regardless of ground speed so a
//tuning run can't be kicked out of its submode if the aircraft goes haywire and you fly it back
//through a speed band. Each key TOGGLES: press to lock that submode; press again (same submode)
//to release back to AUTO (speed-driven). Locking one submode replaces any other lock. Read by
//fn_fmcAttitudeHold. Bind keys under Configure > Controls > Addons (AH-64D).
//GLOBAL helper (not a local private - CBA runs keybind handlers in their own scope, so a local
//would be out of reach). Toggles the hold submode lock for the requested submode.
fza_sfmplus_fnc_holdSubLock = {
    params ["_want"];
    private _veh = vehicle player;
    if (_veh isKindOf "fza_ah64base" || {_veh getVariable ["fza_ah64_sfmPlusInitialised", false]}) then {
        private _cur = _veh getVariable ["fza_ah64_attHoldSubModeLock", ""];
        private _new = if (_cur == _want) then { "" } else { _want };   // toggle off if re-pressed
        _veh setVariable ["fza_ah64_attHoldSubModeLock", _new, true];
        private _lbl = if (_new == "") then { "AUTO (speed-driven)" } else { format ["LOCKED %1", toUpper _new] };
        private _col = if (_new == "") then { "#ffcc44" } else { "#66ff66" };
        hintSilent parseText format ["<t size='1.4' font='EtelkaMonospacePro' color='%1'>Hold Submode: %2</t>", _col, _lbl];
    };
    false
};
["AH-64D", "HoldSubLockPos", ["Lock Hold Submode: POSITION", "Pin position hold (toggle; re-press = auto)"],
    { ["pos"] call fza_sfmplus_fnc_holdSubLock }, {false}, [0, [false, false, false]]] call CBA_fnc_addKeybind;
["AH-64D", "HoldSubLockVel", ["Lock Hold Submode: VELOCITY", "Pin velocity hold (toggle; re-press = auto)"],
    { ["vel"] call fza_sfmplus_fnc_holdSubLock }, {false}, [0, [false, false, false]]] call CBA_fnc_addKeybind;
["AH-64D", "HoldSubLockAtt", ["Lock Hold Submode: ATTITUDE", "Pin attitude hold (toggle; re-press = auto)"],
    { ["att"] call fza_sfmplus_fnc_holdSubLock }, {false}, [0, [false, false, false]]] call CBA_fnc_addKeybind;

//private _nonAnalogEvents = ["Activate", "Deactivate"];
//
//{
//    addUserActionEventHandler ["fza_ah64_kbCollectiveUp", _x, {fza_sfmplus_keyboardCollective = true;}];
//    addUserActionEventHandler ["fza_ah64_kbCollectiveDn", _x, {fza_sfmplus_keyboardCollective = true;}];
//} forEach _nonAnalogEvents;
//
//private _analogEvents = ["Analog"];
//
//{
//    addUserActionEventHandler ["fza_ah64_collectiveUp", _x, {fza_sfmplus_keyboardCollective = false;}];
//    addUserActionEventHandler ["fza_ah64_collectiveDn", _x, {fza_sfmplus_keyboardCollective = false;}];
//} forEach _analogEvents;
