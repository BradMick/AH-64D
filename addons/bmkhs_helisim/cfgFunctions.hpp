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
    class bmkhs_helisim_project
    {
        tag = "bmkhs";
        class actuator {
            file = "\bmkhs_helisim\functions\actuator";
            class actuator {R;};
            class actuatorGetLagCoefA {R;};
            class actuatorGetLagCoefB {R;};
            class actuatorLag {R;};
            class actuatorVariables {R;};
        };
        class wing {
            file = "\bmkhs_helisim\functions\wing";
            class wing {R;};
        };
        class core {
            file = "\bmkhs_helisim\functions\core";
            class coreConfig {R;};
            class coreUpdate  {R;};
            class coreUpdateFlightModel {R;};
        };
        class damage {
            file = "\bmkhs_helisim\functions\damage";
            class damageApply {R;};
        };
        class engine {
            file = "\bmkhs_helisim\functions\engine";
            class engine  {R;};
            class engine2 {R;};
            class engineBET {R;};
            class engineController {R;};
            class engineVariables {R;};
        };
        class environment {
            file = "\bmkhs_helisim\functions\environment";
            class environment {R;};
        };
        class fmc  {
            file = "\bmkhs_helisim\functions\fmc";
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
            file = "\bmkhs_helisim\functions\prestonAi";
            class preston {R;};
            class prestonPedal {R;};
            class prestonPilot {R;};
            class prestonVariables {R;};
        };
        class fuselage {
            file = "\bmkhs_helisim\functions\fuselage";
            class fuselage {R;};
            class fuselageFront {R;};
            class fuselageSide {R;};
            class fuselageTop {R;};
            class fuselageVariables {R;};
        };
        class mass {
            file = "\bmkhs_helisim\functions\mass";
            class massUpdate {R;};
            class massUpdateMagazine {R;};
            class massUpdateStation {R;};
        };
        class math {
            file = "\bmkhs_helisim\functions\math";
            class getArea {R;};
            class linearInterp {R;};
            class linearInterpFromCenter {R;};
            class rotateVector {R;};
            class vectorRotate {R;};
            class vectorRotateAroundAxis {R;};
        };
        class pid {
            file = "\bmkhs_helisim\functions\pid";
            class pidCreate {R;};
            class pidReset {R;};
            class pidRun {R;};
        };
        class util {
            file = "\bmkhs_helisim\functions\util";
            class notify {R;};
            class setArrayVariable {R;};
            class setMultiArrayVariable {R;};
            class updateNetworkGlobal {R;};
        };
        class debug {
            file = "\bmkhs_helisim\functions\debug";
            class debugDrawCircle {R;};
            class debugDrawLine {R;};
        };
        class mathQuaternion {
            file = "\bmkhs_helisim\functions\math\quaternion";
            class quaternion {R;};
            class quaternionConjugate {R;};
            class quaternionFromVec3 {R;};
            class quaternionMultiply {R;};
            class quaternionNormalize {R;};
        };
        class mathSmoothAverage {
            file = "\bmkhs_helisim\functions\math\smoothAverage";
            class smoothAverageAdd {R;};
            class smoothAverageGet {R;};
            class smoothAverageInit {R;};
        };
        class performance {
            file = "\bmkhs_helisim\functions\performance";
            class perfData {R;};
            class perfVariables {R;};
        };
        class rotor {
            file = "\bmkhs_helisim\functions\rotor";
            class rotor {R;};
            class rotorBlade {R;};
            class rotorControl {R;};
            class rotorFlapDynamics {R;};
            class rotorUpdate {R;};
            class rotorVariables {R;};
        };
        class simpleRotor {
            file = "\bmkhs_helisim\functions\simpleRotor";
            class simpleRotorMain {R;};
            class simpleRotorTail {R;};
            class simpleRotorVariables {R;};
        };
        class transmission {
            file = "\bmkhs_helisim\functions\transmission";
            class transmission {R;};
            class transmissionVariables {R;};
        };
        class utility {
            file = "\bmkhs_helisim\functions";
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
