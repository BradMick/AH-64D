#include "\bmkhs_helisim\headers\core.hpp"

#define BMKHS_SETTINGS_CATEGORY "BradMick's HeliSim"

[
    "bmkhs_helisimRealismSetting",
    "LIST",
    [(localize "STR_FZA_AH64_SETTINGS_HELISIM_REALISM"), (localize "STR_FZA_AH64_SETTINGS_HELISIM_REALISM_INFO")],
    [BMKHS_SETTINGS_CATEGORY, "Flight model"],
    [[CASUAL, REALISTIC],[(localize "STR_FZA_AH64_SETTINGS_REALISM_CASUAL"), (localize "STR_FZA_AH64_SETTINGS_REALISM_REALISTIC")],0],
    0
] call CBA_fnc_addSetting;

[
    "bmkhs_cyclicCenterTrimMode",
    "CHECKBOX",
    [(localize "STR_FZA_AH64_SETTINGS_CYCLIC_CENTER_TRIM_MODE"), (localize "STR_FZA_AH64_SETTINGS_CYCLIC_CENTER_TRIM_MODE_INFO")],
    [BMKHS_SETTINGS_CATEGORY, "Flight model"],
    [false],
    2
] call CBA_fnc_addSetting;

[
    "bmkhs_pedalCenterTrimMode",
    "CHECKBOX",
    [(localize "STR_FZA_AH64_SETTINGS_PEDAL_CENTER_TRIM_MODE"), (localize "STR_FZA_AH64_SETTINGS_PEDAL_CENTER_TRIM_MODE_INFO")],
    [BMKHS_SETTINGS_CATEGORY, "Flight model"],
    [false],
    2
] call CBA_fnc_addSetting;

[
    "fza_ah64_sfmPlusSpringlessCyclic",
    "CHECKBOX",
    [(localize "STR_FZA_AH64_SETTINGS_SPRINGLESS_CYCLIC"), (localize "STR_FZA_AH64_SETTINGS_SPRINGLESS_CYCLIC_INFO")],
    [BMKHS_SETTINGS_CATEGORY, "Flight model"],
    [false],
    2
] call CBA_fnc_addSetting;

[
    "fza_ah64_sfmPlusSpringlessPedals",
    "CHECKBOX",
    [(localize "STR_FZA_AH64_SETTINGS_SPRINGLESS_PEDALS"), (localize "STR_FZA_AH64_SETTINGS_SPRINGLESS_PEDALS_INFO")],
    [BMKHS_SETTINGS_CATEGORY, "Flight model"],
    [false],
    2
] call CBA_fnc_addSetting;

[
    "fza_ah64_sfmPlusKeyboardStickyPitch",
    "CHECKBOX",
    [(localize "STR_FZA_AH64_SETTINGS_KEYBOARD_STICKY_PITCH"), (localize "STR_FZA_AH64_SETTINGS_KEYBOARD_STICKY_PITCH_INFO")],
    [BMKHS_SETTINGS_CATEGORY, "Flight model"],
    [false],
    2
] call CBA_fnc_addSetting;

[
    "fza_ah64_sfmPlusKeyboardStickyRoll",
    "CHECKBOX",
    [(localize "STR_FZA_AH64_SETTINGS_KEYBOARD_STICKY_ROLL"), (localize "STR_FZA_AH64_SETTINGS_KEYBOARD_STICKY_ROLL_INFO")],
    [BMKHS_SETTINGS_CATEGORY, "Flight model"],
    [false],
    2
] call CBA_fnc_addSetting;

[
    "fza_ah64_sfmPlusKeyboardStickyYaw",
    "CHECKBOX",
    [(localize "STR_FZA_AH64_SETTINGS_KEYBOARD_STICKY_YAW"), (localize "STR_FZA_AH64_SETTINGS_KEYBOARD_STICKY_YAW_INFO")],
    [BMKHS_SETTINGS_CATEGORY, "Flight model"],
    [false],
    2
] call CBA_fnc_addSetting;

[
    "fza_ah64_sfmPlusAutoPedal",
    "CHECKBOX",
    [(localize "STR_FZA_AH64_SETTINGS_KEYBOARD_AUTO_PEDAL"), (localize "STR_FZA_AH64_SETTINGS_KEYBOARD_AUTO_PEDAL_INFO")],
    [BMKHS_SETTINGS_CATEGORY, "Flight model"],
    [true],
    2
] call CBA_fnc_addSetting;

//NOTE: there is deliberately no "Auto Pitch"/"Auto Roll" setting here. Keyboard auto-attitude is
//intrinsic to the CASUAL flight model - always on there, always off on REALISTIC - so the realism
//setting above is its only gate and every consumer tests that directly. The old Auto Pitch
//checkbox was both redundant (the assist was already gated on casual, so it did nothing on
//realistic) and a trap: it defaulted ON while the pitch-SAS gate keyed off the checkbox alone, so
//a realistic pilot who left it ticked lost pitch SAS to an assist that never ran.

[
    "fza_ah64_sfmPlusMouseAsJoystick",
    "CHECKBOX",
    [(localize "STR_FZA_AH64_SETTINGS_MOUSE_AS_JOYSTICK"), (localize "STR_FZA_AH64_SETTINGS_MOUSE_AS_JOYSTICK_INFO")],
    [BMKHS_SETTINGS_CATEGORY, "Flight model"],
    [false],
    2
] call CBA_fnc_addSetting;

[
    "fza_ah64_sfmPlusMouseSense",
    "SLIDER",
    [(localize "STR_FZA_AH64_SETTINGS_MOUSE_SENSITIVITY"), (localize "STR_FZA_AH64_SETTINGS_MOUSE_SENSITIVITY_INFO")],
    [BMKHS_SETTINGS_CATEGORY, "Flight model"],
    [0.1, 1.0, 1.0, 1],
    2
] call CBA_fnc_addSetting;

[
    "bmkhs_helisimEnvironment",
    "LIST",
    [(localize "STR_FZA_AH64_SETTINGS_ENVIRONMENT"), (localize "STR_FZA_AH64_SETTINGS_ENVIRONMENT_INFO")],
    [BMKHS_SETTINGS_CATEGORY, "Flight model"],
    [[ISA_STD, EUROPE_SUMMER, EUROPE_WINTER, MIDDLE_EAST, CENTRAL_ASIA_SUMMER, CENTRAL_ASIA_WINTER, ASIA],[(localize "STR_FZA_AH64_SETTINGS_ENVIRONMENT_STANDARD_DAY"), (localize "STR_FZA_AH64_SETTINGS_ENVIRONMENT_EUROPE_SUMMER"), (localize "STR_FZA_AH64_SETTINGS_ENVIRONMENT_EUROPE_WINTER"), (localize "STR_FZA_AH64_SETTINGS_ENVIRONMENT_MIDDLE_EAST"), (localize "STR_FZA_AH64_SETTINGS_ENVIRONMENT_CENTRAL_ASIA_SUMMER"), (localize "STR_FZA_AH64_SETTINGS_ENVIRONMENT_CENTRAL_ASIA_WINTER"), (localize "STR_FZA_AH64_SETTINGS_ENVIRONMENT_ASIA")],1],
    0
] call CBA_fnc_addSetting;

[
    "fza_ah64_sfmPlusVrsWarning",
    "CHECKBOX",
    [(localize "STR_FZA_AH64_SETTINGS_VRS_WARNING"), (localize "STR_FZA_AH64_SETTINGS_VRS_WARNING_INFO")],
    [BMKHS_SETTINGS_CATEGORY, "Flight model"],
    [false],
    2
] call CBA_fnc_addSetting;

[
    "fza_ah64_sfmPlusFmDebug",
    "CHECKBOX",
    [(localize "STR_FZA_AH64_SETTINGS_FM_DEBUG"), (localize "STR_FZA_AH64_SETTINGS_FM_DEBUG_INFO")],
    [BMKHS_SETTINGS_CATEGORY, "Flight model"],
    [false],
    2
] call CBA_fnc_addSetting;

[
    "fza_ah64_sfmPlusRotorModel",
    "LIST",
    [(localize "STR_FZA_AH64_SETTINGS_ROTOR_MODEL"), (localize "STR_FZA_AH64_SETTINGS_ROTOR_MODEL_INFO")],
    [BMKHS_SETTINGS_CATEGORY, "Flight model"],
    [[0, 1], [(localize "STR_FZA_AH64_SETTINGS_ROTOR_MODEL_SIMPLE"), (localize "STR_FZA_AH64_SETTINGS_ROTOR_MODEL_BET")], 0],
    0
] call CBA_fnc_addSetting;

bmkhs_keyboardCollective         = true;
bmkhs_keyboardCollectivePrevious = true;

//private _nonAnalogEvents = ["Activate", "Deactivate"];
//
//{
//    addUserActionEventHandler ["fza_ah64_kbCollectiveUp", _x, {bmkhs_keyboardCollective = true;}];
//    addUserActionEventHandler ["fza_ah64_kbCollectiveDn", _x, {bmkhs_keyboardCollective = true;}];
//} forEach _nonAnalogEvents;
//
//private _analogEvents = ["Analog"];
//
//{
//    addUserActionEventHandler ["fza_ah64_collectiveUp", _x, {bmkhs_keyboardCollective = false;}];
//    addUserActionEventHandler ["fza_ah64_collectiveDn", _x, {bmkhs_keyboardCollective = false;}];
//} forEach _analogEvents;
