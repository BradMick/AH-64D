// recompile = 1 UNCONDITIONALLY - this is what makes -filePatching work.
//
// This was previously gated behind `#ifdef __A3_DEBUG__`, which is DEAD CODE under HEMTT:
// __A3_DEBUG__ is one of HEMTT's "runtime macros", hardcoded to the value 0 in a lookup
// the #ifdef existence check never consults (libs/preprocessor/src/defines.rs). It cannot
// be defined - there is no project.toml key, no CLI flag, and no per-command scoping - so
// the #else branch always won and every function was built with recompile = 0.
//
// With recompile = 0 the engine compiles each function once and caches it forever, so a
// patched .sqf on disk is never re-read: file patching appears completely broken even with
// -filePatching enabled, correct addon junctions, and bytecode stripped from the PBO. There
// is no error; edits are simply ignored.
//
// Cost of leaving this on for release: effectively nothing. Without -filePatching there is
// no loose file to find, so the engine compiles the PBO's copy once at mission start exactly
// as it did before. This mirrors how CBA/ACE handle their dev-recompile switch (a runtime
// gate rather than a rapify-time define), adapted to a CfgFunctions-based project.
//
// NOTE: file patching only overrides paths that already exist in the built PBO - adding a
// BRAND NEW .sqf still requires a rebuild.
#define R recompile = 1

class CfgFunctions
{
    class fza_ah64_project_sfmplus
    {
        tag = "FZA_sfmplus";
        class actuator {
            file = "\fza_ah64_sfmplus\functions\actuator";
            class actuator {R;};
            class actuatorGetLagCoefA {R;};
            class actuatorGetLagCoefB {R;};
            class actuatorLag {R;};
            class actuatorVariables {R;};
        };
        class wing {
            file = "\fza_ah64_sfmplus\functions\wing";
            class wing {R;};
        };
        class core {
            file = "\fza_ah64_sfmplus\functions\core";
            class coreConfig {R;};
            class coreUpdate  {R;};
            class coreUpdateFlightModel {R;};
        };
        class damage {
            file = "\fza_ah64_sfmplus\functions\damage";
            class damageApply {R;};
        };
        class debug {
            file = "\fza_ah64_sfmplus\functions\debug\tuner";
            class tunerVariables {R;};
            class tunerApply {R;};
            class tunerSetValue {R;};
            class tunerLoad {R;};
            class tunerSave {R;};
            class tunerExport {R;};
            class tunerGui {R;};
            class tunerBuildRows {R;};
            class tunerInterpolate {R;};
            class tunerBalance {R;};
            class tunerTargets {R;};
            class tunerMaster {R;};
            class tunerPidAuto {R;};
            class tunerStepTune {R;};
            class tunerHoldAuto {R;};
            class tunerPedalAuto {R;};
            class forceDumpLog {R;};
            class holdChainLog {R;};
            class tunerYawDamper {R;};
            class tunerForceTables {R;};
            class tunerOverlay {R;};
            class forceLog {R;};
            class forceLogReset {R;};
        };
        class engine {
            file = "\fza_ah64_sfmplus\functions\engine";
            class engine  {R;};
            class engine2 {R;};
            class engineBET {R;};
            class engineController {R;};
            class engineVariables {R;};
        };
        class environment {
            file = "\fza_ah64_sfmplus\functions\environment";
            class environment {R;};
            class environmentVariables {R;};
        };
        class fmc  {
            file = "\fza_ah64_sfmplus\functions\fmc";
            class fmc {R;};
            class fmcAttitudeHold {R;};
            class fmcAltitudeHold {R;};
            class fmcAltitudeHoldEnable {R;};
            class fmcAttitudeHoldEnable {R;};
            class fmcControlMixing {R;};
            class fmcForceTrimSet {R;};
            class fmcHeadingHold {R;};
            class fmcHoldModesDisable {R;};
            class fmcSAS {R;};
        };
        class prestonAi {
            file = "\fza_ah64_sfmplus\functions\prestonAi";
            class prestonPilot {R;};
        };
        class fuselage {
            file = "\fza_ah64_sfmplus\functions\fuselage";
            class fuselage {R;};
            class fuselageFront {R;};
            class fuselageSide {R;};
            class fuselageTop {R;};
            class fuselageVariables {R;};
        };
        class interact {
            file = "\fza_ah64_sfmplus\functions\interact";
            class interactPowerLever {R;};
            class interactStartSwitch {R;};
        };
        class mass {
            file = "\fza_ah64_sfmplus\functions\mass";
            class massUpdate {R;};
            class massUpdateMagazine {R;};
            class massUpdateStation {R;};
        };
        class math {
            file = "\fza_ah64_sfmplus\functions\math";
            class linearInterpFromCenter {R;};
            class vectorRotate {R;};
            class vectorRotateAroundAxis {R;};
        };
        class mathQuaternion {
            file = "\fza_ah64_sfmplus\functions\math\quaternion";
            class quaternion {R;};
            class quaternionConjugate {R;};
            class quaternionFromVec3 {R;};
            class quaternionMultiply {R;};
            class quaternionNormalize {R;};
        };
        class mathSmoothAverage {
            file = "\fza_ah64_sfmplus\functions\math\smoothAverage";
            class smoothAverageAdd {R;};
            class smoothAverageGet {R;};
            class smoothAverageInit {R;};
        };
        class performance {
            file = "\fza_ah64_sfmplus\functions\performance";
            class perfData {R;};
            class perfVariables {R;};
        };
        class rotor {
            file = "\fza_ah64_sfmplus\functions\rotor";
            class rotor {R;};
            class rotorBlade {R;};
            class rotorControl {R;};
            class rotorFlapDynamics {R;};
            class rotorUpdate {R;};
            class rotorVariables {R;};
        };
        class simpleRotor {
            file = "\fza_ah64_sfmplus\functions\simpleRotor";
            class simpleRotorMain {R;};
            class simpleRotorNewtRaphSolver {R;};
            class simpleRotorTail {R;};
            class simpleRotorVariables {R;};
        };
        class transmission {
            file = "\fza_ah64_sfmplus\functions\transmission";
            class transmission {R;};
            class transmissionVariables {R;};
        };
        class utility {
            file = "\fza_ah64_sfmplus\functions";
            class analogHandler {R;};
            class calculateAeroValues {R;};
            class centerTrimMode {R;};
            class getAccelerations {R;};
            class getAltitude {R;};
            class getDeltaTime {R;};
            class getInput {R;};
            class getInterpInput {R;};
            class getRtrRPM {R;};
            class getSmoothAverage {R;};
            class getVelocities {R;};
            class init {R;};
            class isINF {R;};
            class isNAN {R;};
            class nonAnalogHandler {R;};
            class onGround {R;};
        };
    };
};
