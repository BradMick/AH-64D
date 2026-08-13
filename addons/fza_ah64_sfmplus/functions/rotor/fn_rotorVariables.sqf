/* ----------------------------------------------------------------------------
Function: fza_sfmplus_fnc_rotorVariables

Description:
    Defines core rotor variables.

Parameters:
    _heli - The helicopter to get information from [Unit].

Returns:
    ...

Examples:
    ...

Author:
    BradMick
---------------------------------------------------------------------------- */
params ["_heli"];

// Static arrays sized for up to 6 rotors, indexed by rotor index
// Per-blade accumulated aerodynamic flap moments (N·m), one 4-element array per rotor
_heli setVariable ["fza_sfmplus_rotorFlapMoment",  [[0.0,0.0,0.0,0.0]
                                                   ,[0.0,0.0,0.0,0.0]
                                                   ,[0.0,0.0,0.0,0.0]
                                                   ,[0.0,0.0,0.0,0.0]
                                                   ,[0.0,0.0,0.0,0.0]
                                                   ,[0.0,0.0,0.0,0.0]]];
// Azimuth (degrees) at which each virtual blade's moment was computed
_heli setVariable ["fza_sfmplus_rotorBladeAzimuth",[[0.0,0.0,0.0,0.0]
                                                   ,[0.0,0.0,0.0,0.0]
                                                   ,[0.0,0.0,0.0,0.0]
                                                   ,[0.0,0.0,0.0,0.0]
                                                   ,[0.0,0.0,0.0,0.0]
                                                   ,[0.0,0.0,0.0,0.0]]];
// Per-element induced inflow velocity (m/s) from previous frame — read during blade loop
_heli setVariable ["fza_sfmplus_rotorInducedFlow",      [[0.0,0.0,0.0,0.0]
                                                        ,[0.0,0.0,0.0,0.0]
                                                        ,[0.0,0.0,0.0,0.0]
                                                        ,[0.0,0.0,0.0,0.0]
                                                        ,[0.0,0.0,0.0,0.0]
                                                        ,[0.0,0.0,0.0,0.0]]];
// Accumulator reset each frame; averaged after blade loop then copied to rotorInducedFlow
_heli setVariable ["fza_sfmplus_rotorInducedFlowAccum", [[0.0,0.0,0.0,0.0]
                                                        ,[0.0,0.0,0.0,0.0]
                                                        ,[0.0,0.0,0.0,0.0]
                                                        ,[0.0,0.0,0.0,0.0]
                                                        ,[0.0,0.0,0.0,0.0]
                                                        ,[0.0,0.0,0.0,0.0]]];
// Accumulated aerodynamic drag torque reaction on fuselage (N·m), one scalar per rotor
_heli setVariable ["fza_sfmplus_rotorReactionTorque", [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]];
// Accumulated rotor thrust (N) per rotor — sum of all element lift across all blades this frame
_heli setVariable ["fza_sfmplus_rotorThrustAccum",    [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]];
// Net rotor FORCE and MOMENT (model space) per rotor — summed across every blade element for
// the force-log table + the force accumulator (bodyAccel/ball). One [x,y,z] vector per rotor.
_heli setVariable ["fza_sfmplus_rotorNetForce",       [[0,0,0], [0,0,0]]];
// Rotor rate-damping scalar (roll/pitch RATE damping from the airframe angular-velocity term
// in fn_rotorBlade). 0.1 tuned in-sim: anything much higher caused an aggressive, noticeable
// snap-back (the rotor over-damps and fights the return to center). Tunable live.
_heli setVariable ["fza_sfmplus_rotorRateDampScalar", 0.1];
// BET FORCE-OUTPUT TUNING SCALARS (per airspeed band). BET forces are physics-derived; these
// multiply the OUTPUT so the master tuner can trim BET the way it trims the simple model's
// tables. 1.0 = pure physics. LIFT scalar -> thrust; TORQUE scalar -> the reaction couple (yaw),
// SPLIT so thrust and yaw tune independently. Applied in fn_rotorBlade (lift) / fn_rotor (torque).
// Bands match the master tuner's _bands. Main rotor + tail rotor each get their own.
private _betBands = [0.00, 10.29, 20.58, 36.01, 46.30, 51.44, 61.73, 66.88, 72.02];
_heli setVariable ["fza_sfmplus_tune_betMainLiftTable",   _betBands apply {[_x, 1.0]}];  // main thrust
_heli setVariable ["fza_sfmplus_tune_betMainTorqueTable", _betBands apply {[_x, 1.0]}];  // main yaw torque
_heli setVariable ["fza_sfmplus_tune_betTailLiftTable",   _betBands apply {[_x, 1.0]}];  // tail thrust
_heli setVariable ["fza_sfmplus_tune_betTailTrimTable",   _betBands apply {[_x, 0.0]}];  // tail airspeed trim/reversal (added to tail thrust scalar)
// Fixed-frame flap coefficients (degrees) — updated each frame from decomposed blade moments
_heli setVariable ["fza_sfmplus_rotorBeta0",       [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]]; // collective coning
_heli setVariable ["fza_sfmplus_rotorA1",          [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]]; // longitudinal disc tilt
_heli setVariable ["fza_sfmplus_rotorB1",          [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]]; // lateral disc tilt
// Pre-filter targets — smoothed over one rotor revolution before the main disc tilt filter
_heli setVariable ["fza_sfmplus_rotorBeta0Target", [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]];
_heli setVariable ["fza_sfmplus_rotorA1Target",    [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]];
_heli setVariable ["fza_sfmplus_rotorB1Target",    [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]];
