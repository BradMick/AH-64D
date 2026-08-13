/* ----------------------------------------------------------------------------
Function: fza_sfmplus_fnc_coreConfig

Description:
    Defines key values for the simulation.

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

private _config = configOf _heli >> "fza_sfmplus";
fza_sfmplus_movingAverageSize = 10;
fza_sfmplus_liftLossTimer     = 0;

_heli setVariable ["fza_sfmplus_kbStickyInterupt",     false];
_heli setVariable ["fza_sfmplus_flightControlLockOut", false];

//Cyclic input
_heli setVariable ["fza_sfmplus_heliCyclicForwardOut",   0.0];
_heli setVariable ["fza_sfmplus_heliCyclicBackwardOut",  0.0];
_heli setVariable ["fza_sfmplus_heliCyclicLeftOut",      0.0];  
_heli setVariable ["fza_sfmplus_heliCyclicRightOut",     0.0];
//Pedal input
_heli setVariable ["fza_sfmplus_heliRudderLeftOut",      0.0];
_heli setVariable ["fza_sfmplus_heliRudderRightOut",     0.0];
//Collective input
_heli setVariable ["fza_sfmplus_heliCollectiveRaiseOut", 0.0];
_heli setVariable ["fza_sfmplus_heliCollectiveLowerOut", 0.0];   

_heli setVariable ["fza_sfmplus_cyclicFwdAft",          0.0];
_heli setVariable ["fza_sfmplus_cyclicPitchValue",      0.0];
_heli getVariable ["fza_sfmplus_prevCyclicPitchValue",  0.0];

_heli setVariable ["fza_sfmplus_cyclicLeftRight",       0.0];
_heli setVariable ["fza_sfmplus_cyclicRollValue",       0.0];
_heli setVariable ["fza_sfmplus_prevCyclicRollValue",   0.0];

_heli setVariable ["fza_sfmplus_pedalLeftRight",        0.0];
_heli setVariable ["fza_sfmplus_kbPedalLeftRight",      0.0];
_heli setVariable ["fza_sfmplus_pedalYawValue",         0.0];
_heli setVariable ["fza_sfmplus_prevPedalYawValue",     0.0];

_heli setVariable ["fza_sfmplus_collectiveOutput",      0.0];
_heli setVariable ["fza_sfmplus_collectivePrevious",    0.0];
_heli setVariable ["fza_sfmplus_collectiveValue",       0.0];

_heli setVariable ["fza_sfmplus_currentTime",         0.0];
_heli setVariable ["fza_sfmplus_previousTime",        0.0];
_heli setVariable ["fza_sfmplus_deltaTime",           0.0];
_heli setVariable ["fza_sfmplus_deltaTime_avg",       [fza_sfmplus_movingAverageSize] call fza_sfmplus_fnc_smoothAverageInit];

_heli setVariable ["fza_sfmplus_gndSpeed",            0.0];
_heli setVariable ["fza_sfmplus_vel2D",               0.0];
_heli setVariable ["fza_sfmplus_vel3D",               0.0];
_heli setVariable ["fza_sfmplus_velWindWorldSpace",   [0.0,0.0,0.0]];
_heli setVariable ["fza_sfmplus_velWindModelSpace",   [0.0,0.0,0.0]];
_heli setVariable ["fza_sfmplus_windDirFrom",         0];
_heli setVariable ["fza_sfmplus_windSpeedKts",        0];
_heli setVariable ["fza_sfmplus_velModelSpace",       [0.0,0.0,0.0]];
_heli setVariable ["fza_sfmplus_velModelSpaceNoWind", [0.0,0.0,0.0]];
_heli setVariable ["fza_sfmplus_velModelSpaceX_avg",  [fza_sfmplus_movingAverageSize] call fza_sfmplus_fnc_smoothAverageInit];
_heli setVariable ["fza_sfmplus_velModelSpaceY_avg",  [fza_sfmplus_movingAverageSize] call fza_sfmplus_fnc_smoothAverageInit];
_heli setVariable ["fza_sfmplus_velModelSpaceZ_avg",  [fza_sfmplus_movingAverageSize] call fza_sfmplus_fnc_smoothAverageInit];
_heli setVariable ["fza_sfmplus_velWorldSpace",       [0.0,0.0,0.0]];
_heli setVariable ["fza_sfmplus_velWorldSpaceNoWind", [0.0,0.0,0.0]];
_heli setVariable ["fza_sfmplus_velWorldSpaceX_avg",  [fza_sfmplus_movingAverageSize] call fza_sfmplus_fnc_smoothAverageInit];
_heli setVariable ["fza_sfmplus_velWorldSpaceY_avg",  [fza_sfmplus_movingAverageSize] call fza_sfmplus_fnc_smoothAverageInit];
_heli setVariable ["fza_sfmplus_velWorldSpaceZ_avg",  [fza_sfmplus_movingAverageSize] call fza_sfmplus_fnc_smoothAverageInit];
_heli setVariable ["fza_sfmplus_velClimb",            0.0];
_heli setVariable ["fza_sfmplus_angVelModelSpace",    [0.0,0.0,0.0]];
_heli setVariable ["fza_sfmplus_angVelModelSpaceX_avg", [fza_sfmplus_movingAverageSize] call fza_sfmplus_fnc_smoothAverageInit];
_heli setVariable ["fza_sfmplus_angVelModelSpaceY_avg", [fza_sfmplus_movingAverageSize] call fza_sfmplus_fnc_smoothAverageInit];
_heli setVariable ["fza_sfmplus_angVelModelSpaceZ_avg", [fza_sfmplus_movingAverageSize] call fza_sfmplus_fnc_smoothAverageInit];
_heli setVariable ["fza_sfmplus_angVelWorldSpace",    [0.0,0.0,0.0]];

_heli setVariable ["fza_sfmplus_velX_prev",         0.0];
_heli setVariable ["fza_sfmplus_accelX",            0.0];
_heli setVariable ["fza_sfmplus_accelX_avg",        [fza_sfmplus_movingAverageSize] call fza_sfmplus_fnc_smoothAverageInit];

_heli setVariable ["fza_sfmplus_velY_prev",         0.0];
_heli setVariable ["fza_sfmplus_accelY",            0.0];
_heli setVariable ["fza_sfmplus_accelY_avg",        [fza_sfmplus_movingAverageSize] call fza_sfmplus_fnc_smoothAverageInit];

_heli setVariable ["fza_sfmplus_velZ_prev",         0.0];
_heli setVariable ["fza_sfmplus_accelZ",            0.0];
_heli setVariable ["fza_sfmplus_accelZ_avg",        [fza_sfmplus_movingAverageSize] call fza_sfmplus_fnc_smoothAverageInit];

_heli setVariable ["fza_sfmplus_forceAccum",         createHashMap];

_heli setVariable ["fza_sfmplus_emptyMassFCR",       getNumber (_config >> "emptyMassFCR")];        //kg
_heli setVariable ["fza_sfmplus_emptyMomFCR",        getNumber (_config >> "emptyMomFCR")];
_heli setVariable ["fza_sfmplus_emptyCoMFCR",        getArray (_config >> "emptyCoMFCR")];

_heli setVariable ["fza_sfmplus_emptyMassNonFCR",    getNumber (_config >> "emptyMassNonFCR")];     //kg
_heli setVariable ["fza_sfmplus_emptyMomNonFCR",     getNumber (_config >> "emptyMomNonFCR")];
_heli setVariable ["fza_sfmplus_emptyCoMNonFCR",     getArray (_config >> "emptyCoMNonFCR")];

_heli setVariable ["fza_sfmplus_stabPos",            getArray  (_config >> "stabPos")];
_heli setVariable ["fza_sfmplus_stabWidth",          getNumber (_config >> "stabWidth")];           //m
_heli setVariable ["fza_sfmplus_stabLength",         getNumber (_config >> "stabLength")];          //m

_heli setVariable ["fza_sfmplus_aerodynamicCenter",  getArray  (_config >> "aerodynamicCenter")];   //m
_heli setVariable ["fza_sfmplus_fuselageAreaFront",  getNumber (_config >> "fuselageAreaFront")];
_heli setVariable ["fza_sfmplus_fuselageAreaSide",   getNumber (_config >> "fuselageAreaSide")];
_heli setVariable ["fza_sfmplus_fuselageAreaBottom", getNumber (_config >> "fuselageAreaBottom")];

_heli setVariable ["fza_sfmplus_maxFwdFuelMass",     getNumber (_config >> "maxFwdFuelMass")];  //1043lbs in kg
_heli setVariable ["fza_sfmplus_maxCtrFuelMass",     getNumber (_config >> "maxCtrFuelMass")];  //663lbs in kg, net yet implemented, center robbie
_heli setVariable ["fza_sfmplus_maxAftFuelMass",     getNumber (_config >> "maxAftFuelMass")];  //1474lbs in kg
_heli setVariable ["fza_sfmplus_maxExtFuelMass",     getNumber (_config >> "maxExtFuelMass")];     //1541lbs in kg, not yet implemented, 230gal external tank

_heli setVariable ["fza_sfmplus_fmcAttHoldCycPitchOut", 0.0];
_heli setVariable ["fza_sfmplus_fmcSasPitchOut",        0.0];
_heli setVariable ["fza_sfmplus_fmcCttHoldCycRollOut",  0.0];
_heli setVariable ["fza_sfmplus_fmcSasRollOut",         0.0];
_heli setVariable ["fza_sfmplus_fmcHdgHoldPedalYawOut", 0.0];
_heli setVariable ["fza_sfmplus_fmcSasYawOut",          0.0];
_heli setVariable ["fza_sfmplus_fmcAltHoldCollOut",     0.0];

//Position Hold
_heli setVariable ["fza_sfmplus_pid_roll",           [0.0550, 0.0070, 0.0900, 0.0070] call fza_fnc_pidCreate];
_heli setVariable ["fza_sfmplus_pid_pitch",          [0.1500, 0.0070, 0.1200, 0.0070] call fza_fnc_pidCreate];
//Attitude Hold
_heli setVariable ["fza_sfmplus_pid_roll_att",       [0.0400, 0.0015, 0.0180, 0.0015] call fza_fnc_pidCreate];
_heli setVariable ["fza_sfmplus_pid_pitch_att",      [0.0925, 0.0025, 0.0450, 0.0025] call fza_fnc_pidCreate];
//Altitude Hold
_heli setVariable ["fza_sfmplus_pid_radHold",        [0.0500, 0.0001, 0.0050, 0.0001] call fza_fnc_pidCreate];
_heli setVariable ["fza_sfmplus_pid_barHold",        [0.0010, 0.0000, 0.0008, 0.0000] call fza_fnc_pidCreate];
//Heading Hold
_heli setVariable ["fza_sfmplus_pid_hdgHold",        [0.0750, 0.0200, 0.0050, 0.0200] call fza_fnc_pidCreate];
_heli setVariable ["fza_sfmplus_pid_trnCoord",       [0.8500, 0.0600, 0.2000, 0.0600] call fza_fnc_pidCreate];
//SAS Functions — proportional rate DAMPING (kp = per-rate opposition, output = -kp*rate).
//ROLL kp ramped 0.012 -> 0.10: it was ~12x below pitch, so the low-inertia roll axis was barely
//damped (twitchy). 0.10 brings it near pitch (0.15) firmness; dial to taste. Pitch/yaw unchanged.
_heli setVariable ["fza_sfmplus_pid_sas_pitch",      [0.1500, 0.0000, 0.0020, 0.0000] call fza_fnc_pidCreate];
_heli setVariable ["fza_sfmplus_pid_sas_roll",       [0.1000, 0.0000, 0.0020, 0.0000] call fza_fnc_pidCreate];
_heli setVariable ["fza_sfmplus_pid_sas_yaw",        [0.3000, 0.0500, 0.0250, 0.0500] call fza_fnc_pidCreate];
//Auto pedal
_heli setVariable ["fza_sfmplus_pid_autoPedalHdg",   [0.1000, 0.0010, 0.0500, 0.0010] call fza_fnc_pidCreate];

//LIVE-TUNABLE augmentation PID gains (SAS dampers + attitude/heading/altitude holds). The
//augmentation functions (fn_fmcSAS, fn_fmcAttitudeHold, fn_fmcHeadingHold, fn_fmcAltitudeHold)
//read these each frame and set[] them onto their PID, so the tuner GUI can dial kp/ki/kd live
//while flying (the hold/SAS PIDs were tuned for the SIMPLE model and are wrong for BET). Seeded
//from the pidCreate values above.
//SAS rate dampers
_heli setVariable ["fza_sfmplus_tune_sasPitch_kp", 0.1500]; _heli setVariable ["fza_sfmplus_tune_sasPitch_ki", 0.0000]; _heli setVariable ["fza_sfmplus_tune_sasPitch_kd", 0.0020];
_heli setVariable ["fza_sfmplus_tune_sasRoll_kp",  0.1000]; _heli setVariable ["fza_sfmplus_tune_sasRoll_ki",  0.0000]; _heli setVariable ["fza_sfmplus_tune_sasRoll_kd",  0.0020];
_heli setVariable ["fza_sfmplus_tune_sasYaw_kp",   0.3000]; _heli setVariable ["fza_sfmplus_tune_sasYaw_ki",   0.0500]; _heli setVariable ["fza_sfmplus_tune_sasYaw_kd",   0.0250];
//Attitude hold. CONSERVATIVE BET starting guesses (2026-08-10): the simple-model gains were
//saturating the +-0.1 clamp and driving a wild pitch/roll oscillation on BET. BET's disc is very
//responsive (low-inertia roll), and the holds sit ON TOP of the SAS rate damper (which handles
//the fast rate), so the holds only need to gently trim the slow attitude error. Started WEAK
//(kp ~4-5x down, kd cut hard - derivative amplifies oscillation on a fast/noisy rotor axis, ki
//near-zero - integral windup drove the saturation). A weak hold drifts slowly (flyable); tune UP
//from here via the SCAS tab. If it still oscillates, halve again; if it drifts, raise kp.
_heli setVariable ["fza_sfmplus_tune_attPitch_kp", 0.0200]; _heli setVariable ["fza_sfmplus_tune_attPitch_ki", 0.0008]; _heli setVariable ["fza_sfmplus_tune_attPitch_kd", 0.0040];
_heli setVariable ["fza_sfmplus_tune_attRoll_kp",  0.0100]; _heli setVariable ["fza_sfmplus_tune_attRoll_ki",  0.0005]; _heli setVariable ["fza_sfmplus_tune_attRoll_kd",  0.0020];
//Position + Velocity hold (shared pid_pitch / pid_roll - pos uses setpoint 0, vel uses desired
//vel). Same conservative cut as attitude hold - same responsive axes, same +-0.1 clamp.
_heli setVariable ["fza_sfmplus_tune_posPitch_kp", 0.0300]; _heli setVariable ["fza_sfmplus_tune_posPitch_ki", 0.0010]; _heli setVariable ["fza_sfmplus_tune_posPitch_kd", 0.0080];
_heli setVariable ["fza_sfmplus_tune_posRoll_kp",  0.0150]; _heli setVariable ["fza_sfmplus_tune_posRoll_ki",  0.0010]; _heli setVariable ["fza_sfmplus_tune_posRoll_kd",  0.0060];
//Heading hold. Yaw is less twitchy (more inertia, firm yaw SAS kp 0.30) - moderate cut only.
_heli setVariable ["fza_sfmplus_tune_hdg_kp",      0.0300]; _heli setVariable ["fza_sfmplus_tune_hdg_ki",      0.0050]; _heli setVariable ["fza_sfmplus_tune_hdg_kd",      0.0030];
//Altitude hold (barometric + radar). Collective->climb is slow/well-damped; left near stock.
_heli setVariable ["fza_sfmplus_tune_bar_kp",      0.0010]; _heli setVariable ["fza_sfmplus_tune_bar_ki",      0.0000]; _heli setVariable ["fza_sfmplus_tune_bar_kd",      0.0008];
_heli setVariable ["fza_sfmplus_tune_rad_kp",      0.0500]; _heli setVariable ["fza_sfmplus_tune_rad_ki",      0.0001]; _heli setVariable ["fza_sfmplus_tune_rad_kd",      0.0050];
//PID auto-tuner (Ziegler-Nichols) state - off by default; the PFH only runs when enabled.
_heli setVariable ["fza_sfmplus_tune_pidAutoOn", false];
_heli setVariable ["fza_sfmplus_pidAuto_idx",    0];
_heli setVariable ["fza_sfmplus_pidAuto_phase",  "INIT"];
_heli setVariable ["fza_sfmplus_pidAuto_t",      0.0];
_heli setVariable ["fza_sfmplus_pidAuto_status", "PID auto-tune idle"];
_heli setVariable ["fza_sfmplus_pid_autoPedalSlip",  [1.5000, 0.1000, 0.8000, 0.1000] call fza_fnc_pidCreate];
_heli setVariable ["fza_sfmPlus_autoPedalHdg",       getDir _heli];
//Auto pitch
_heli setVariable ["fza_sfmplus_pid_autoPitch",      [0.0500, 0.0200, 0.0100, 5.0000] call fza_fnc_pidCreate];
_heli setVariable ["fza_sfmplus_autoPitchActive",    true];
_heli setVariable ["fza_sfmplus_autoPitchTarget",    -6.0];
_heli setVariable ["fza_sfmplus_autoPitchHoldTimer", 0.0];
_heli setVariable ["fza_sfmplus_autoPitchBreakout",  false];

//Aerodynamic State Variables
_heli setVariable ["fza_sfmplus_aero_alpha_deg",     0.0];
_heli setVariable ["fza_sfmplus_aero_beta_deg",      0.0];
_heli setVariable ["fza_sfmplus_aero_beta_g",        0.0];
_heli setVariable ["fza_sfmplus_aero_beta_g_prev",   0.0];   //EGI low-pass filter state for the skid/slip (beta_g)

_heli setVariable ["fza_sfmplus_aero_prevVelX",      0.0];
_heli setVariable ["fza_sfmplus_aero_accelX",        0.0];

_heli setVariable ["fza_sfmplus_aero_prevVelY",      0.0];
_heli setVariable ["fza_sfmplus_aero_accelY",        0.0];

_heli setVariable ["fza_sfmplus_aero_prevVelZ",      0.0];
_heli setVariable ["fza_sfmplus_aero_accelZ",        0.0];

_heli setVariable ["fza_sfmplus_aero_accel",         [0.0, 0.0, 0.0]];

//Keyboard
_heli setVariable ["fza_sfmplus_cyclicPitchValue",   0.0];
_heli setVariable ["fza_sfmplus_cyclicRollValue",    0.0];
_heli setVariable ["fza_sfmplus_pedalYawValue",      0.0];

//Fuel
[_heli] call fza_fuel_fnc_fuelVariables;
[_heli] call fza_fuel_fnc_fuelMgmtVariables;
[_heli] call fza_fuel_fnc_fuelSet;

//Engines
_heli setVariable ["fza_sfmplus_pid_engine",        [[0.7000, 0.0000, 0.0005, 0.0000] call fza_fnc_pidCreate, [0.7000, 0.0000, 0.0005, 0.0000] call fza_fnc_pidCreate]];
[_heli] call fza_sfmplus_fnc_engineVariables;

//Fuselage
[_heli] call fza_sfmplus_fnc_fuselageVariables;
 
//Transmission
[_heli] call fza_sfmplus_fnc_transmissionVariables;

//Rotors
[_heli] call fza_sfmplus_fnc_simpleRotorVariables;
[_heli] call fza_sfmplus_fnc_rotorVariables;

//Performance
[_heli] call fza_sfmplus_fnc_perfVariables;

//Actuators
[_heli] call fza_sfmplus_fnc_actuatorVariables;

//Flight model tuner - restore persisted overrides and apply them live.
//Runs last so every heli variable and PID hashmap above already exists.
[_heli, call fza_sfmplus_fnc_tunerLoad] call fza_sfmplus_fnc_tunerApply;

//Seed the target-attitude tables (pitch/roll per airspeed) for the master tuner.
[_heli] call fza_sfmplus_fnc_tunerTargets;

//Start the master auto-tuner. It is the single automatic tuner - it tunes the
//force scalar tables (thrust/torque/tail/stab) against the target attitudes and
//owns yaw balance. Gated by the GUI toggles (on/off, FMC-off, target airspeed).
[_heli] call fza_sfmplus_fnc_tunerMaster;

//PID auto-tuner (Ziegler-Nichols). Per-frame state machine; only DOES anything while
//fza_sfmplus_tune_pidAutoOn is true. Tunes the augmentation PID gains automatically by
//ramping each to its oscillation point. Runs as its own PFH.
[{ (_this select 0) params ["_heli"]; [_heli] call fza_sfmplus_fnc_tunerPidAuto; }, 0, [_heli]] call CBA_fnc_addPerFrameHandler;
