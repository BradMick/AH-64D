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
