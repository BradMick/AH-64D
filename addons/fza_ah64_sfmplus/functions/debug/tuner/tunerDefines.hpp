/* ----------------------------------------------------------------------------
    AH-64D Flight Model Tuner - shared IDC / IDD defines.

    Included by both tunerGui.hpp (config-side control definitions) and
    fn_tunerGui.sqf (runtime), so the two never disagree on control ids.
    Contains ONLY preprocessor defines - no class definitions - so it is safe to
    #include from an .sqf.
---------------------------------------------------------------------------- */

#define FZA_SFMPLUS_TUNER_IDD              54100

// Static / structural control IDCs
#define FZA_SFMPLUS_TUNER_IDC_BACKGROUND   54101
#define FZA_SFMPLUS_TUNER_IDC_TITLE        54102
#define FZA_SFMPLUS_TUNER_IDC_TABBAR       54105  // controls group hosting the tab buttons
#define FZA_SFMPLUS_TUNER_IDC_GROUP        54110  // scrolling controls group (row host)
#define FZA_SFMPLUS_TUNER_IDC_STATUS       54111

// Button bar IDCs
#define FZA_SFMPLUS_TUNER_IDC_BTN_SAVE     54120
#define FZA_SFMPLUS_TUNER_IDC_BTN_COPY     54121
#define FZA_SFMPLUS_TUNER_IDC_BTN_RESET    54122
#define FZA_SFMPLUS_TUNER_IDC_BTN_CLOSE    54124

// Runtime row IDC base (see fn_tunerGui.sqf)
#define FZA_SFMPLUS_TUNER_ROW_IDC_BASE     55000

// Runtime tab-button IDC base (tab index added on top; see fn_tunerGui.sqf)
#define FZA_SFMPLUS_TUNER_TAB_IDC_BASE     54200
