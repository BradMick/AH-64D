/* ----------------------------------------------------------------------------
    AH-64D Flight Model Tuner GUI

    Fully self-contained / containerized inside fza_ah64_sfmplus. No inheritance
    from or dependency on any external base-control library (MPD, controls, etc).
    Only the stock engine classes actually referenced are forward-declared; every
    tuner control class specifies all its attributes inline so the dialog renders
    identically regardless of what other addons define.

    Layout: a compact, repositionable panel placed toward the left so it does not
    block the flight view. The parameter rows live inside a scrolling controls
    group and are created at runtime by fza_sfmplus_fnc_tunerGui, so only the
    frame, the group and the button bar are declared here.
---------------------------------------------------------------------------- */

// Forward declarations of stock ENGINE classes (Arma's own base UI, not any
// third-party addon library). The checkbox in particular has a long list of
// required texture/colour states, so we inherit the stock RscCheckBox rather
// than reimplement it and chase missing-property errors.
class RscDisplay;
class RscCheckBox;
class RscEdit;
class RscXSliderH;

#include "tunerDefines.hpp"

// Runtime-created row controls use IDCs derived from FZA_SFMPLUS_TUNER_ROW_IDC_BASE +
// row index; the generator owns those, so they are not declared here.

class fza_sfmplus_Tuner_ctrlBase
{
    idc = -1;
    type = 0;
    style = 0;
    x = 0; y = 0; w = 0; h = 0;
    font = "PuristaMedium";
    sizeEx = 0.030;
    colorText[]       = {1, 1, 1, 1};
    colorBackground[] = {0, 0, 0, 0};
    text = "";
    shadow = 0;
    tooltip = "";
};

class fza_sfmplus_TunerText : fza_sfmplus_Tuner_ctrlBase
{
    type = 0;        // CT_STATIC
    style = 0;       // ST_LEFT
    colorBackground[] = {0, 0, 0, 0};
};

class fza_sfmplus_TunerFrame : fza_sfmplus_Tuner_ctrlBase
{
    type = 0;        // CT_STATIC
    style = 64;      // ST_FRAME
    colorText[]       = {1, 1, 1, 0.5};
    colorBackground[] = {0, 0, 0, 0};
};

class fza_sfmplus_TunerBackground : fza_sfmplus_Tuner_ctrlBase
{
    type = 0;
    style = 0;
    colorBackground[] = {0, 0, 0, 0.80};
};

// Inherit stock RscEdit / RscXSliderH (valid textures + full property sets) and
// override only sizing/colour. Same rationale as the checkbox above.
class fza_sfmplus_TunerEdit : RscEdit
{
    idc = -1;
    sizeEx = 0.030;
    colorText[]       = {1, 1, 1, 1};
    colorBackground[] = {0.05, 0.05, 0.05, 0.9};
    tooltip = "";
};

class fza_sfmplus_TunerSlider : RscXSliderH
{
    idc = -1;
    color[]       = {1, 1, 1, 0.9};
    colorActive[] = {1, 1, 1, 1};
    tooltip = "";
};

// Inherit the stock RscCheckBox (all texture/colour states already valid) and
// override only what we need. This avoids reimplementing the full checkbox
// property set from scratch.
class fza_sfmplus_TunerCheckbox : RscCheckBox
{
    idc = -1;
    checked = 0;
    colorBackground[] = {0.05, 0.05, 0.05, 0.9};
    tooltip = "";
};

class fza_sfmplus_TunerButton : fza_sfmplus_Tuner_ctrlBase
{
    type = 1;        // CT_BUTTON
    style = 2;       // ST_CENTER
    colorText[]              = {1, 1, 1, 1};
    colorBackground[]        = {0.15, 0.15, 0.15, 0.9};
    colorBackgroundActive[]  = {0.30, 0.30, 0.30, 1};
    colorBackgroundDisabled[]= {0.10, 0.10, 0.10, 0.6};
    colorFocused[]           = {0.25, 0.25, 0.25, 1};
    colorDisabled[]          = {0.4, 0.4, 0.4, 1};
    colorShadow[]            = {0, 0, 0, 0};
    colorBorder[]            = {0, 0, 0, 1};
    borderSize = 0;
    offsetX = 0; offsetY = 0; offsetPressedX = 0; offsetPressedY = 0;
    soundEnter[] = {"", 0, 1};
    soundPush[]  = {"", 0, 1};
    soundClick[] = {"", 0, 1};
    soundEscape[]= {"", 0, 1};
    action = "";
};

class fza_sfmplus_TunerGroup : fza_sfmplus_Tuner_ctrlBase
{
    type = 15;       // CT_CONTROLS_GROUP
    style = 0;
    class VScrollbar
    {
        color[] = {1, 1, 1, 0.6};
        width = 0.021;
        autoScrollEnabled = 0;
    };
    class HScrollbar
    {
        color[] = {1, 1, 1, 0};
        height = 0;
    };
    class Controls {};
};

// --- Display -------------------------------------------------------------- //
class fza_sfmplus_tuner : RscDisplay
{
    idd = FZA_SFMPLUS_TUNER_IDD;
    movingEnable = 1;                 // panel can be dragged
    enableSimulation = 1;             // keep the sim (and thus flight) running
    onLoad = "uiNamespace setVariable ['fza_sfmplus_tuner', _this select 0]; _this call fza_sfmplus_fnc_tunerGui;";
    onUnload = "fza_sfmplus_forceLogOn = false; uiNamespace setVariable ['fza_sfmplus_tuner', displayNull]; private _p = uiNamespace getVariable ['fza_sfmplus_tunerRecoPfh', -1]; if (_p >= 0) then { [_p] call CBA_fnc_removePerFrameHandler; uiNamespace setVariable ['fza_sfmplus_tunerRecoPfh', -1]; };";

    // Panel: wide, with everything kept comfortably inside the background so the
    // button bar never spills below the frame. Fonts bumped up for readability.
    class ControlsBackground
    {
        class TunerBackground : fza_sfmplus_TunerBackground
        {
            idc = FZA_SFMPLUS_TUNER_IDC_BACKGROUND;
            x = 0.02; y = 0.04; w = 0.63; h = 0.90;
            moving = 1;               // dragging the background moves the panel
        };
        class TunerFrame : fza_sfmplus_TunerFrame
        {
            idc = -1;
            x = 0.02; y = 0.04; w = 0.63; h = 0.90;
        };
    };

    class Controls
    {
        class TunerTitle : fza_sfmplus_TunerText
        {
            idc = FZA_SFMPLUS_TUNER_IDC_TITLE;
            style = 2;                // centered
            x = 0.02; y = 0.04; w = 0.63; h = 0.05;
            sizeEx = 0.042;
            text = "AH-64D FLIGHT MODEL TUNER";
            colorBackground[] = {0.10, 0.10, 0.10, 0.9};
            moving = 1;
        };

        // Tab bar host - one button per major section, created at runtime.
        class TunerTabBar : fza_sfmplus_TunerGroup
        {
            idc = FZA_SFMPLUS_TUNER_IDC_TABBAR;
            x = 0.03; y = 0.095; w = 0.61; h = 0.045;
            class VScrollbar { color[] = {1, 1, 1, 0}; width = 0; };
            class HScrollbar { color[] = {1, 1, 1, 0}; height = 0; };
        };

        // Scrolling host for runtime-generated parameter rows.
        class TunerGroup : fza_sfmplus_TunerGroup
        {
            idc = FZA_SFMPLUS_TUNER_IDC_GROUP;
            x = 0.03; y = 0.150; w = 0.61; h = 0.670;
        };

        // Status / hint line above the button bar.
        class TunerStatus : fza_sfmplus_TunerText
        {
            idc = FZA_SFMPLUS_TUNER_IDC_STATUS;
            x = 0.03; y = 0.828; w = 0.61; h = 0.035;
            sizeEx = 0.030;
            colorText[] = {0.7, 0.9, 1, 1};
            text = "";
        };

        // Button bar (kept inside the panel: bottom edge 0.87 + 0.05 = 0.92 < 0.94).
        class TunerBtnSave : fza_sfmplus_TunerButton
        {
            idc = FZA_SFMPLUS_TUNER_IDC_BTN_SAVE;
            x = 0.03; y = 0.870; w = 0.113; h = 0.05;
            text = "Save";
            tooltip = "Persist current values across sessions";
        };
        class TunerBtnCopy : fza_sfmplus_TunerButton
        {
            idc = FZA_SFMPLUS_TUNER_IDC_BTN_COPY;
            x = 0.150; y = 0.870; w = 0.128; h = 0.05;
            text = "Copy Code";
            tooltip = "Copy a paste-ready code block to the clipboard";
        };
        class TunerBtnReset : fza_sfmplus_TunerButton
        {
            idc = FZA_SFMPLUS_TUNER_IDC_BTN_RESET;
            x = 0.285; y = 0.870; w = 0.150; h = 0.05;
            text = "Reset All";
            tooltip = "Reset every value to the mod default";
        };
        class TunerBtnClose : fza_sfmplus_TunerButton
        {
            idc = FZA_SFMPLUS_TUNER_IDC_BTN_CLOSE;
            x = 0.442; y = 0.870; w = 0.208; h = 0.05;
            text = "Close";
            colorBackground[] = {0.25, 0.08, 0.08, 0.9};
        };
    };
};
