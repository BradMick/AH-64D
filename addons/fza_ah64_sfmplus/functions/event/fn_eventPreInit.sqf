fza_sfmplus_keyboardCollective         = true;
fza_sfmplus_keyboardCollectivePrevious = true;

//Force/moment readout logging - off until the tuner's Forces tab enables it.
fza_sfmplus_forceLogOn = false;

//Flight model tuner - keybind to open the in-game tuner dialog. No default key
//is assigned; bind it under Configure > Controls > Addons (AH-64D). Only opens
//while the player is aboard an AH-64 and no dialog is already open.
//Uses CBA's public keybind API directly (the project's fza_fnc_addKeybind
//wrapper is not used elsewhere and trips a CBA hash zero-divisor on first use).
["AH-64D", "OpenFlightModelTuner", ["Open Flight Model Tuner", "Opens the in-game flight model tuner dialog"],
    {
        if (!isNull findDisplay 54100) exitWith { false };
        private _veh = vehicle player;
        if (_veh isKindOf "fza_ah64base" || {_veh getVariable ["fza_ah64_sfmPlusInitialised", false]}) then {
            createDialog "fza_sfmplus_tuner";
        };
        false
    },
    {false},
    [0, [false, false, false]]
] call CBA_fnc_addKeybind;

//Tuner DATA OVERLAY - non-blocking, fly while watching balancer output. Bind a
//key under Configure > Controls > Addons (AH-64D). Toggles the RscTitles overlay.
["AH-64D", "ToggleFMTunerOverlay", ["Toggle FM Tuner Overlay", "Non-blocking live balancer data (fly with it open)"],
    {
        private _veh = vehicle player;
        if (_veh isKindOf "fza_ah64base" || {_veh getVariable ["fza_ah64_sfmPlusInitialised", false]}) then {
            ["toggle"] call fza_sfmplus_fnc_tunerOverlay;
        };
        false
    },
    {false},
    [0, [false, false, false]]
] call CBA_fnc_addKeybind;

//MASTER AUTO-TUNER on/off - toggle the master auto-tuner without opening the panel.
//Flips fza_sfmplus_tune_masterOn on the aircraft; the master PFH (installed at
//aircraft init in fn_coreConfig) reads it every frame, so this takes effect at once.
//A hint confirms the new state. Bind a key under Configure > Controls > Addons (AH-64D).
["AH-64D", "ToggleFMMasterTuner", ["Toggle FM Master Auto-Tuner", "Turns the master auto-tuner on/off without opening the panel"],
    {
        private _veh = vehicle player;
        if (_veh isKindOf "fza_ah64base" || {_veh getVariable ["fza_ah64_sfmPlusInitialised", false]}) then {
            private _on = !(_veh getVariable ["fza_sfmplus_tune_masterOn", false]);
            _veh setVariable ["fza_sfmplus_tune_masterOn", _on, true];
            hintSilent parseText format ["<t size='1.4' font='EtelkaMonospacePro' color='%1'>MASTER Auto-Tune %2</t>",
                (if (_on) then { "#66ff66" } else { "#ff6666" }), (if (_on) then { "ON" } else { "OFF" })];
        };
        false
    },
    {false},
    [0, [false, false, false]]
] call CBA_fnc_addKeybind;

//SAS AUTO-TUNER on/off - toggle the Ziegler-Nichols SAS rate-damper tuner without opening the
//panel. Flips fza_sfmplus_tune_pidAutoOn; the SAS-auto PFH (installed at aircraft init in
//fn_coreConfig) reads it every frame (rising edge restarts from SAS pitch). Run this FIRST to
//damp the airframe. A hint confirms the state. Bind a key (e.g. Ctrl+>) under Configure >
//Controls > Addons (AH-64D).
["AH-64D", "ToggleFMPidAutoTuner", ["Toggle FM SAS Auto-Tuner", "Turns the Ziegler-Nichols SAS rate-damper tuner on/off (run this first)"],
    {
        private _veh = vehicle player;
        if (_veh isKindOf "fza_ah64base" || {_veh getVariable ["fza_ah64_sfmPlusInitialised", false]}) then {
            private _on = !(_veh getVariable ["fza_sfmplus_tune_pidAutoOn", false]);
            _veh setVariable ["fza_sfmplus_tune_pidAutoOn", _on, true];
            hintSilent parseText format ["<t size='1.4' font='EtelkaMonospacePro' color='%1'>SAS Auto-Tune %2</t>",
                (if (_on) then { "#66ff66" } else { "#ff6666" }), (if (_on) then { "ON" } else { "OFF" })];
        };
        false
    },
    {false},
    [0, [false, false, false]]
] call CBA_fnc_addKeybind;

//HOLD AUTO-TUNER on/off - toggle the Ziegler-Nichols HOLD PID tuner without opening the panel.
//Flips fza_sfmplus_tune_holdAutoOn; the hold-auto PFH reads it every frame (rising edge restarts).
//It tunes the hold PID for whatever submode is LIVE at your ground speed (pos <5kt / vel 5-40kt /
//att >40kt) - fly the regime you want to tune. Run this AFTER the SAS tuner. Won't run while the
//SAS tuner is on. Bind a separate key under Configure > Controls > Addons (AH-64D).
["AH-64D", "ToggleFMHoldAutoTuner", ["Toggle FM Hold PID Auto-Tuner", "Tunes the hold PID for the submode live at your current ground speed (run after SAS)"],
    {
        private _veh = vehicle player;
        if (_veh isKindOf "fza_ah64base" || {_veh getVariable ["fza_ah64_sfmPlusInitialised", false]}) then {
            private _on = !(_veh getVariable ["fza_sfmplus_tune_holdAutoOn", false]);
            _veh setVariable ["fza_sfmplus_tune_holdAutoOn", _on, true];
            hintSilent parseText format ["<t size='1.4' font='EtelkaMonospacePro' color='%1'>HOLD Auto-Tune %2</t>",
                (if (_on) then { "#66ff66" } else { "#ff6666" }), (if (_on) then { "ON" } else { "OFF" })];
        };
        false
    },
    {false},
    [0, [false, false, false]]
] call CBA_fnc_addKeybind;

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
