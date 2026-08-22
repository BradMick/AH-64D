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
_heli setVariable ["fza_sfmplus_velWorldSpaceNoWind_prev", [0.0,0.0,0.0]];
_heli setVariable ["fza_sfmplus_velWorldSpaceX_avg",  [fza_sfmplus_movingAverageSize] call fza_sfmplus_fnc_smoothAverageInit];
_heli setVariable ["fza_sfmplus_velWorldSpaceY_avg",  [fza_sfmplus_movingAverageSize] call fza_sfmplus_fnc_smoothAverageInit];
_heli setVariable ["fza_sfmplus_velWorldSpaceZ_avg",  [fza_sfmplus_movingAverageSize] call fza_sfmplus_fnc_smoothAverageInit];
_heli setVariable ["fza_sfmplus_velClimb",            0.0];
_heli setVariable ["fza_sfmplus_angVelModelSpace",    [0.0,0.0,0.0]];
_heli setVariable ["fza_sfmplus_angVelModelSpaceX_avg", [fza_sfmplus_movingAverageSize] call fza_sfmplus_fnc_smoothAverageInit];
_heli setVariable ["fza_sfmplus_angVelModelSpaceY_avg", [fza_sfmplus_movingAverageSize] call fza_sfmplus_fnc_smoothAverageInit];
_heli setVariable ["fza_sfmplus_angVelModelSpaceZ_avg", [fza_sfmplus_movingAverageSize] call fza_sfmplus_fnc_smoothAverageInit];
_heli setVariable ["fza_sfmplus_angVelWorldSpace",    [0.0,0.0,0.0]];

_heli setVariable ["fza_sfmplus_worldAccel",        [0.0,0.0,0.0]];

//Smoothed worldAccel - slip ball only.
_heli setVariable ["fza_sfmplus_worldAccelFiltered", [0.0,0.0,0.0]];
_heli setVariable ["fza_sfmplus_worldAccelX_avg",   [fza_sfmplus_movingAverageSize] call fza_sfmplus_fnc_smoothAverageInit];
_heli setVariable ["fza_sfmplus_worldAccelY_avg",   [fza_sfmplus_movingAverageSize] call fza_sfmplus_fnc_smoothAverageInit];
_heli setVariable ["fza_sfmplus_worldAccelZ_avg",   [fza_sfmplus_movingAverageSize] call fza_sfmplus_fnc_smoothAverageInit];

_heli setVariable ["fza_sfmplus_velX_prev",         0.0];
_heli setVariable ["fza_sfmplus_accelX",            0.0];
_heli setVariable ["fza_sfmplus_accelX_avg",        [fza_sfmplus_movingAverageSize] call fza_sfmplus_fnc_smoothAverageInit];

_heli setVariable ["fza_sfmplus_velY_prev",         0.0];
_heli setVariable ["fza_sfmplus_accelY",            0.0];
_heli setVariable ["fza_sfmplus_accelY_avg",        [fza_sfmplus_movingAverageSize] call fza_sfmplus_fnc_smoothAverageInit];

_heli setVariable ["fza_sfmplus_velZ_prev",         0.0];
_heli setVariable ["fza_sfmplus_accelZ",            0.0];
_heli setVariable ["fza_sfmplus_accelZ_avg",        [fza_sfmplus_movingAverageSize] call fza_sfmplus_fnc_smoothAverageInit];


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
//Turn coordination / yaw slip loop. Error is LATERAL G (fza_sfmplus_aero_beta_g); output is
//clamped to +-0.1 in fn_fmcHeadingHold, so size the gains against that, not the +-1 gauge.
_heli setVariable ["fza_sfmplus_pid_trnCoord",       [0.2500, 0.0600, 0.3000, 0.1500] call fza_fnc_pidCreate];
//SAS - proportional rate DAMPING (output = -kp*rate).
_heli setVariable ["fza_sfmplus_pid_sas_pitch",      [0.1500, 0.0000, 0.0020, 0.0000] call fza_fnc_pidCreate];
_heli setVariable ["fza_sfmplus_pid_sas_roll",       [0.1000, 0.0000, 0.0020, 0.0000] call fza_fnc_pidCreate];
_heli setVariable ["fza_sfmplus_pid_sas_yaw",        [0.3000, 0.0500, 0.0250, 0.0500] call fza_fnc_pidCreate];
//Auto pedal - THREE REGIMES, each its own PID and error units. Live- and auto-tunable.
//  HDG  (hover)     : heading error (deg)
//  NTT  (<50ft AGL) : kinematic sideslip (deg) - velocity vector on the nose
//  AERO (>50ft AGL) : lateral accel (g) - ball centred
//The 4th arg is ki_clamp, bounding the raw integral accumulator; the integral's contribution is
//ki * clamp. Sized so that product is ~0.15 - the standing pedal a hover holds against torque.
_heli setVariable ["fza_sfmplus_pid_autoPedalHdg",   [0.1000, 0.0050, 0.0500, 30.000] call fza_fnc_pidCreate];
_heli setVariable ["fza_sfmplus_pid_autoPedalNtt",   [0.0300, 0.0080, 0.0100, 18.750] call fza_fnc_pidCreate];
//AERO kp is per-G, scaled so full-scale slip (0.15g) gives full pedal. kd is small - beta_g is
//already filtered, so derivative action on it is mostly lag.
_heli setVariable ["fza_sfmplus_pid_autoPedalAero",  [6.6700, 0.5000, 0.4000, 0.3000] call fza_fnc_pidCreate];

//LIVE-TUNABLE augmentation gains. The fmc functions read these each frame and set[] them onto
//their PID, so the tuner can dial kp/ki/kd while flying. Seeded from the pidCreate values above.
//SAS rate dampers
_heli setVariable ["fza_sfmplus_tune_sasPitch_kp", 0.1500]; _heli setVariable ["fza_sfmplus_tune_sasPitch_ki", 0.0000]; _heli setVariable ["fza_sfmplus_tune_sasPitch_kd", 0.0020];
_heli setVariable ["fza_sfmplus_tune_sasRoll_kp",  0.1000]; _heli setVariable ["fza_sfmplus_tune_sasRoll_ki",  0.0000]; _heli setVariable ["fza_sfmplus_tune_sasRoll_kd",  0.0020];
_heli setVariable ["fza_sfmplus_tune_sasYaw_kp",   0.3000]; _heli setVariable ["fza_sfmplus_tune_sasYaw_ki",   0.0500]; _heli setVariable ["fza_sfmplus_tune_sasYaw_kd",   0.0250];
//Attitude hold. Deliberately weak: these sit ON TOP of the SAS rate damper, so they only trim
//the slow attitude error. Tune UP from here via the SCAS tab.
_heli setVariable ["fza_sfmplus_tune_attPitch_kp", 0.0200]; _heli setVariable ["fza_sfmplus_tune_attPitch_ki", 0.0008]; _heli setVariable ["fza_sfmplus_tune_attPitch_kd", 0.0040];
_heli setVariable ["fza_sfmplus_tune_attRoll_kp",  0.0100]; _heli setVariable ["fza_sfmplus_tune_attRoll_ki",  0.0005]; _heli setVariable ["fza_sfmplus_tune_attRoll_kd",  0.0020];
//Position + Velocity hold (shared pid_pitch / pid_roll - pos uses setpoint 0, vel uses desired
//vel). Output is hard-clamped to +-0.1 (the SAS servo limit) and must never saturate, so normal
//drift should use only a fraction of it.
_heli setVariable ["fza_sfmplus_tune_posPitch_kp", 0.0300]; _heli setVariable ["fza_sfmplus_tune_posPitch_ki", 0.0000]; _heli setVariable ["fza_sfmplus_tune_posPitch_kd", 0.0600];
_heli setVariable ["fza_sfmplus_tune_posRoll_kp",  0.0150]; _heli setVariable ["fza_sfmplus_tune_posRoll_ki",  0.0000]; _heli setVariable ["fza_sfmplus_tune_posRoll_kd",  0.0600];
//Position INTEGRAL (pos hold only): bounded integral of position error biasing the velocity
//setpoint. The clamp is the ceiling on commanded return velocity (m/s), so it must exceed the
//residual drift or the loop is outrun and can never null it - at 0.072 it was asking for 0.072 m/s
//against a measured 0.138 m/s drift and settled into a band instead of reaching the datum.
_heli setVariable ["fza_sfmplus_tune_posIntKp",    0.0200];
_heli setVariable ["fza_sfmplus_tune_posIntClamp", 0.2500];
_heli setVariable ["fza_sfmplus_posIntX",          0.0];
_heli setVariable ["fza_sfmplus_posIntY",          0.0];

//Master-tuned lateral CoM offset (m). Baked from the tuner export.
_heli setVariable ["fza_sfmplus_tune_comOffsetX",  0.1];

//ONE-TIME strip of stale PID gains from the persisted tuner profile, guarded by a bump flag: the
//profile overlays the seeds on load, so a badly auto-tuned PID would survive respawns. Clears only
//the _kp/_ki/_kd and posInt* keys; force tables are untouched. Bump the flag to clear again.
private _pidWipeFlag = "fza_sfmplus_pidWipeDone_v3";
if !(profileNamespace getVariable [_pidWipeFlag, false]) then {
    private _saved = profileNamespace getVariable ["fza_sfmplus_tuner", []];
    if (_saved isEqualType [] && {count _saved > 0}) then {
        private _kept = _saved select {
            _x params ["_k"];
            private _suffix = _k select [count _k - 3];
            private _isPid = (_suffix in ["_kp","_ki","_kd"]) || {(_k find "fza_sfmplus_tune_posInt") >= 0};
            !_isPid
        };
        profileNamespace setVariable ["fza_sfmplus_tuner", _kept];
    };
    profileNamespace setVariable [_pidWipeFlag, true];
    saveProfileNamespace;
};
//Hold submode LOCK: "" = auto (speed-driven pos/vel/att). Set to "pos"/"vel"/"att" by keybind to
//PIN the submode regardless of speed, so a tuning run can't be kicked out of its submode if the
//aircraft goes haywire and you fly it back through a speed band. fn_fmcAttitudeHold honors it.
_heli setVariable ["fza_ah64_attHoldSubModeLock", ""];
//Heading hold. Yaw is less twitchy (more inertia, firm yaw SAS kp 0.30) - moderate cut only.
_heli setVariable ["fza_sfmplus_tune_hdg_kp",      0.0300]; _heli setVariable ["fza_sfmplus_tune_hdg_ki",      0.0050]; _heli setVariable ["fza_sfmplus_tune_hdg_kd",      0.0030];
//Auto pedal, one row per REGIME (seeded from the pidCreate values above). fn_getInput set[]s these
//onto the three PIDs every frame, so the SCAS tab / fn_tunerPedalAuto can dial them live.
_heli setVariable ["fza_sfmplus_tune_apHdg_kp",    0.1000]; _heli setVariable ["fza_sfmplus_tune_apHdg_ki",    0.0050]; _heli setVariable ["fza_sfmplus_tune_apHdg_kd",    0.0500];
_heli setVariable ["fza_sfmplus_tune_apNtt_kp",    0.0300]; _heli setVariable ["fza_sfmplus_tune_apNtt_ki",    0.0080]; _heli setVariable ["fza_sfmplus_tune_apNtt_kd",    0.0100];
_heli setVariable ["fza_sfmplus_tune_apAero_kp",   6.6700]; _heli setVariable ["fza_sfmplus_tune_apAero_ki",   0.5000]; _heli setVariable ["fza_sfmplus_tune_apAero_kd",   0.4000];
//Altitude hold (barometric + radar). Collective->climb is slow/well-damped; left near stock.
_heli setVariable ["fza_sfmplus_tune_bar_kp",      0.0010]; _heli setVariable ["fza_sfmplus_tune_bar_ki",      0.0000]; _heli setVariable ["fza_sfmplus_tune_bar_kd",      0.0008];
_heli setVariable ["fza_sfmplus_tune_rad_kp",      0.0500]; _heli setVariable ["fza_sfmplus_tune_rad_ki",      0.0001]; _heli setVariable ["fza_sfmplus_tune_rad_kd",      0.0050];
//PID auto-tuners (Ziegler-Nichols) state - off by default; the PFHs only run when enabled.
//Two independent tuners share the pidAuto_ ZN scratch state (never on at once): the SAS
//tuner (pidAutoOn, tunes the 3 rate dampers) and the HOLD tuner (holdAutoOn, tunes the
//live submode's hold PID). Run SAS first, then holds.
_heli setVariable ["fza_sfmplus_tune_pidAutoOn",   false];  // SAS tuner toggle
_heli setVariable ["fza_sfmplus_tune_holdAutoOn",  false];  // HOLD tuner toggle
_heli setVariable ["fza_sfmplus_tune_pedalAutoOn", false];  // AUTO-PEDAL tuner toggle (3 regimes)
//Auto-pedal tuner excitation tracking: peak |error| seen in the regime currently being graded, and
//which regime that peak belongs to. Guards against "tuning" an axis that was never disturbed.
_heli setVariable ["fza_sfmplus_pedalAuto_exPeak",   0.0];
_heli setVariable ["fza_sfmplus_pedalAuto_exRegime", ""];
_heli setVariable ["fza_sfmplus_pidAuto_idx",    0];
_heli setVariable ["fza_sfmplus_pidAuto_phase",  "INIT"];
_heli setVariable ["fza_sfmplus_pidAuto_t",      0.0];
_heli setVariable ["fza_sfmplus_pidAuto_status", "PID auto-tune idle"];
_heli setVariable ["fza_sfmPlus_autoPedalHdg",       getDir _heli];
//Auto pedal live state, published by fn_getInput each frame and read by fn_tunerPedalAuto/overlay.
_heli setVariable ["fza_sfmplus_autoPedalRegime",    "hdg"];   //hdg | ntt | aero (live regime)
_heli setVariable ["fza_sfmplus_autoPedalRegimeWgt", 1.0];     //0-1, share of the pedal that regime owns
_heli setVariable ["fza_sfmplus_autoPedalHdgErr",    0.0];     //deg, heading error
_heli setVariable ["fza_sfmplus_autoPedalNttErr",    0.0];     //deg, kinematic sideslip
_heli setVariable ["fza_sfmplus_autoPedalAeroErr",   0.0];     //g,   lateral accel
_heli setVariable ["fza_sfmplus_autoPedalOut",       0.0];     //blended pedal output
_heli setVariable ["fza_sfmplus_autoPedalPrevOut",   0.0];     //pilot-feet filter state (rate limit + lag)
//Auto pitch (keyboard auto-attitude; see the AUTO_ATT_* block in core.hpp)
//Error is in DEGREES. Runs with no rate damping underneath it on pitch, so raise kp in small
//steps (0.02) and only alongside kd. kd is deliberately large relative to kp - it is what stops
//the overshoot - and dCoef is lifted off the 0.3 default so the filter does not remove that lead.
_heli setVariable ["fza_sfmplus_pid_autoPitch",      [0.1200, 0.0200, 0.1000, 5.0000] call fza_fnc_pidCreate];
(_heli getVariable "fza_sfmplus_pid_autoPitch") set ["dCoef", 0.5];
_heli setVariable ["fza_sfmplus_autoPitchActive",    true];
_heli setVariable ["fza_sfmplus_autoPitchTarget",    -6.0];
//Auto roll. ki is the term that matters - it absorbs the airframe's standing right-roll offset,
//which a rate-damping SAS cannot do. Roll is the LOW-INERTIA axis so it needs less gain than
//pitch, not more: a quicker axis reaches the same rate on less input.
_heli setVariable ["fza_sfmplus_pid_autoRoll",       [0.0700, 0.0200, 0.0900, 5.0000] call fza_fnc_pidCreate];
(_heli getVariable "fza_sfmplus_pid_autoRoll") set ["dCoef", 0.5];
_heli setVariable ["fza_sfmplus_autoRollActive",     true];
_heli setVariable ["fza_sfmplus_autoRollTarget",     0.0];
//Auto hover (HOVER regime of auto-attitude). Error is GROUND VELOCITY in m/s, not attitude.
//ki carries the standing cyclic offset that holds the hover. Pitch needs a larger offset than
//roll (CG sits aft), so the asymmetric ki_clamp is deliberate; 1.00 rails the integral.
_heli setVariable ["fza_sfmplus_pid_autoHoverX",     [0.0600, 0.2200, 0.0500, 0.2500] call fza_fnc_pidCreate];
_heli setVariable ["fza_sfmplus_pid_autoHoverY",     [0.0700, 0.2500, 0.0600, 0.5500] call fza_fnc_pidCreate];
(_heli getVariable "fza_sfmplus_pid_autoHoverX") set ["dCoef", 0.5];
(_heli getVariable "fza_sfmplus_pid_autoHoverY") set ["dCoef", 0.5];
//VEL regime (transition): ROLL nulls lateral drift, PITCH holds forward velocity. Same error
//units as the hover PIDs. The lateral channel stops the hands and the auto-pedal's feet fighting
//over a drifting velocity vector.
_heli setVariable ["fza_sfmplus_pid_autoVelX",       [0.0500, 0.0400, 0.1000, 1.0000] call fza_fnc_pidCreate];
_heli setVariable ["fza_sfmplus_pid_autoVelY",       [0.1000, 0.0200, 0.1200, 1.0000] call fza_fnc_pidCreate];
(_heli getVariable "fza_sfmplus_pid_autoVelX") set ["dCoef", 0.5];
(_heli getVariable "fza_sfmplus_pid_autoVelY") set ["dCoef", 0.5];
_heli setVariable ["fza_sfmplus_autoVelCmdFwd",      0.0];   //commanded forward velocity (m/s)
//Pilot HANDS filter state (lag + rate limit on the blended cyclic output). Re-seeded to the live
//trim position on breakout so the machine pilot resumes from where the stick actually is.
_heli setVariable ["fza_sfmplus_autoAttPrevPitch",   0.0];
_heli setVariable ["fza_sfmplus_autoAttPrevRoll",    0.0];
_heli setVariable ["fza_sfmplus_autoAttBreakout",    false];
_heli setVariable ["fza_sfmplus_autoHoverDatum",     getPos _heli];   //world-space position datum
_heli setVariable ["fza_sfmplus_autoHoverIntX",      0.0];            //position-error integral (right)
_heli setVariable ["fza_sfmplus_autoHoverIntY",      0.0];            //position-error integral (fwd)
//PRE-SEEDED hover integrals so the first pickup already carries the standing forward cyclic the
//aft CG needs; starting from zero it pitches back and drifts aft while the loop catches up.
//Overwritten by the learned values once the aircraft holds a steady hover.
_heli setVariable ["fza_sfmplus_autoHoverLearnedIntX", 0.0];
_heli setVariable ["fza_sfmplus_autoHoverLearnedIntY", 0.5500];
_heli setVariable ["fza_sfmplus_autoHoverWeight",    0.0];            //live blend weight (0=att, 1=hover)

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

//SAS auto-tuner (Ziegler-Nichols). Per-frame state machine; only DOES anything while
//fza_sfmplus_tune_pidAutoOn is true. Tunes the 3 SAS rate dampers to their oscillation
//point. Runs as its own PFH.
[{ (_this select 0) params ["_heli"]; [_heli] call fza_sfmplus_fnc_tunerPidAuto; }, 0, [_heli]] call CBA_fnc_addPerFrameHandler;

//HOLD auto-tuner (Ziegler-Nichols). Only DOES anything while fza_sfmplus_tune_holdAutoOn is
//true (and the SAS tuner is off). Tunes the hold PID for whatever submode is live at the
//current ground speed (pos/vel/att). Run this AFTER the SAS tuner. Runs as its own PFH.
[{ (_this select 0) params ["_heli"]; [_heli] call fza_sfmplus_fnc_tunerHoldAuto; }, 0, [_heli]] call CBA_fnc_addPerFrameHandler;

//AUTO-PEDAL auto-tuner. Tunes whichever regime is live, so fly each one to tune it. Run AFTER
//the SAS tuner - yaw SAS is the inner loop beneath it.
[{ (_this select 0) params ["_heli"]; [_heli] call fza_sfmplus_fnc_tunerPedalAuto; }, 0, [_heli]] call CBA_fnc_addPerFrameHandler;
