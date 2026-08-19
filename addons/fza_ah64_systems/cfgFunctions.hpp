// recompile = 1 UNCONDITIONALLY - required for -filePatching to work.
// This was gated behind `#ifdef __A3_DEBUG__`, which is DEAD CODE under HEMTT: that macro
// is hardcoded to 0 in a table the #ifdef existence check never consults, and cannot be
// defined (no project.toml key, no CLI flag). The #else branch always won, so every
// function was built compile-once-and-cache and patched .sqf files were never re-read.
// Costs nothing without -filePatching: no loose file exists, so it compiles the PBO copy
// once at mission start as before. See addons/fza_ah64_sfmplus/cfgFunctions.hpp for the
// full write-up, and .hemtt/project.toml for the matching .sqfc exclude (both are needed).
#define R recompile = 1
class CfgFunctions
{
    class fza_ah64_project_systems
    {
        tag = "FZA_systems";
        class apu {
            file = "\fza_ah64_systems\functions\apu";
            class apu {R;};
        };
        class core {
            file = "\fza_ah64_systems\functions\core";
            class coreUpdate {R;};
            class coreVariables {R;};
        };
        class drivetrain {
            file = "\fza_ah64_systems\functions\drivetrain";
            class drivetrainController {R;};
            class drivetrainNoseGearbox1 {R;};
            class drivetrainNoseGearbox2 {R;};
            class drivetrainTailRotorGearboxes {R;};
            class drivetrainTransmission {R;};
        };
        class electrical {
            file = "\fza_ah64_systems\functions\electrical";
            class electricalACBus {R;};
            class electricalBattery {R;};
            class electricalController {R;};
            class electricalDCBus {R;};
            class electricalGenerator1 {R;};
            class electricalGenerator2 {R;};
            class electricalRectifier1 {R;};
            class electricalRectifier2 {R;};
        };
        class hydraulics {
            file = "\fza_ah64_systems\functions\hydraulics";
            class hydraulicsAccumulator {R;};
            class hydraulicsController {R;};
            class hydraulicsPriPump {R;};
            class hydraulicsPriReservoir {R;};
            class hydraulicsUtilPump {R;};
            class hydraulicsUtilReservoir {R;};
        };
        class interact {
            file = "\fza_ah64_systems\functions\interact";
            class interactAPUButton {R;};
            class interactBattSwitch {R;};
        };
        class repair {
            file = "\fza_ah64_systems\functions\repair";
            class repair {R;};
        };
    };
};
