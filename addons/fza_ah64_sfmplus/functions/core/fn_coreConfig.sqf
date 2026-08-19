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
//Turn coordination / yaw slip loop. Error is LATERAL G (fza_sfmplus_aero_beta_g), and the output
//is clamped to +-0.1 in fn_fmcHeadingHold - so the gains have to be sized against that narrow
//range, not against the +-1 gauge signal this was originally tuned for.
//At kp 0.85 a mere 0.12 g of slip RAILED the output: the loop went full authority on a modest
//skid, overshot, railed the other way, and hunted without ever settling. kp 0.25 gives ~0.03 of
//pedal for 0.12 g, leaving the integral to close out the standing slip smoothly instead.
//kd raised relative to kp for damping; ki_clamp opened a little so the integral can actually
//carry the standing offset that holds the ball centred.
_heli setVariable ["fza_sfmplus_pid_trnCoord",       [0.2500, 0.0600, 0.3000, 0.1500] call fza_fnc_pidCreate];
//SAS Functions — proportional rate DAMPING (kp = per-rate opposition, output = -kp*rate).
//ROLL kp ramped 0.012 -> 0.10: it was ~12x below pitch, so the low-inertia roll axis was barely
//damped (twitchy). 0.10 brings it near pitch (0.15) firmness; dial to taste. Pitch/yaw unchanged.
_heli setVariable ["fza_sfmplus_pid_sas_pitch",      [0.1500, 0.0000, 0.0020, 0.0000] call fza_fnc_pidCreate];
_heli setVariable ["fza_sfmplus_pid_sas_roll",       [0.1000, 0.0000, 0.0020, 0.0000] call fza_fnc_pidCreate];
_heli setVariable ["fza_sfmplus_pid_sas_yaw",        [0.3000, 0.0500, 0.0250, 0.0500] call fza_fnc_pidCreate];
//Auto pedal - THREE REGIMES, each its own PID + its own error signal/units. All three are
//live-tunable (fn_getInput reads the tune vars onto these PIDs every frame) and auto-tunable
//(fn_tunerPedalAuto). Kept together here; the Slip PID used to live ~85 lines further down.
//  HDG (hover)      : error = heading error (deg).       Ball is IRRELEVANT in a hover.
//  NTT (<50ft AGL)  : error = kinematic sideslip (deg).  Nose-to-tail: velocity vector on the nose.
//  AERO (>50ft AGL) : error = lateral accel (g).         Ball centered = aerodynamic trim.
//SEEDS: NTT/AERO are NOT the old Slip gains. The old kp 1.5 was scaled for a +-1 normalized ball;
//these run on real units (deg / g) so they are rescaled - see fn_getInput for the error sources.
//AERO kp is per-g and g is a small number, hence the much larger kp on that channel.
//NOTE the 4th arg is ki_clamp - it bounds the raw INTEGRAL ACCUMULATOR, and the integral's actual
//contribution to the output is ki * clamp. Size that product to the standing pedal offset the
//aircraft genuinely needs (a hover holds on ~0.11-0.15 pedal against main-rotor torque) - NOT to
//full pedal. Too small and the loop can never hold a heading (the original 0.1 clamp with ki 0.005
//capped the integral at 0.0005, ~200x short). Too large and the integral becomes the whole output
//and commands huge pedal for a tiny error. Sized so ki * clamp ~= 0.15 on each channel.
_heli setVariable ["fza_sfmplus_pid_autoPedalHdg",   [0.1000, 0.0050, 0.0500, 30.000] call fza_fnc_pidCreate];
_heli setVariable ["fza_sfmplus_pid_autoPedalNtt",   [0.0300, 0.0080, 0.0100, 18.750] call fza_fnc_pidCreate];
//AERO kp is per-G. Scaled so FULL-SCALE slip gives FULL pedal: full scale is 0.15g (the slip gauge's
//own full-scale, fn_avionicsSlipIndicator), so kp = 1.0/0.15 = 6.67. A real cruise skid is only a few
//thousandths of a g, so proportional action is correctly gentle (~0.02 pedal) and the INTEGRAL
//supplies the standing trim - which is why its clamp below matters more than kp here.
//kd is small: beta_g is already low-pass filtered (k=0.08), so derivative action on it is mostly lag.
_heli setVariable ["fza_sfmplus_pid_autoPedalAero",  [6.6700, 0.5000, 0.4000, 0.3000] call fza_fnc_pidCreate];

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
//vel). At the committed baseline (0.030/0.015): stable but loose (slow drift at a hover). Raising
//kp to 0.10/0.06 made ENGAGE violent - it slammed cyclic and threw the aircraft into a roll/pitch
//(strong P response to the velocity present at engage + a big first-frame derivative spike).
//Pos-hold PID gains. The hold output is HARD-CLAMPED to +-0.1 (the SAS-servo mechanical limit,
//lines ~172) and must operate WITHIN it - it should use only a FRACTION of 0.1 for normal drift and
//NEVER saturate. Size so a small drift (~1-2 m) makes a fraction of the authority: kp*posErr, e.g.
//Position/velocity hold VELOCITY-NULL gains (pid_roll/pid_pitch). These null velocity smoothly and
//stay under the +-0.1 servo limit - the base of the pos hold and the whole vel hold. Kept gentle.
_heli setVariable ["fza_sfmplus_tune_posPitch_kp", 0.0300]; _heli setVariable ["fza_sfmplus_tune_posPitch_ki", 0.0000]; _heli setVariable ["fza_sfmplus_tune_posPitch_kd", 0.0600];
_heli setVariable ["fza_sfmplus_tune_posRoll_kp",  0.0150]; _heli setVariable ["fza_sfmplus_tune_posRoll_ki",  0.0000]; _heli setVariable ["fza_sfmplus_tune_posRoll_kd",  0.0600];
//Position INTEGRAL (pos hold only): slow, bounded integral of POSITION error biasing the velocity
//setpoint to trim the residual drift the velocity-null loop leaves (type-0 -> type-1). posIntKp =
//integral gain (auto-tuned). posIntClamp = anti-windup ceiling on the velocity-setpoint bias (m/s):
//kept TINY - near the loop's real working range (~0.01-0.02 m/s) so it can NEVER rail the +-0.1 servo
//or fight the velocity loop. The old 0.6 ceiling was ~60x too big and wound to its rail. posIntX/Y are
//the live accumulators (reset when the hold disengages).
_heli setVariable ["fza_sfmplus_tune_posIntKp",    0.0200];
_heli setVariable ["fza_sfmplus_tune_posIntClamp", 0.0720];
_heli setVariable ["fza_sfmplus_posIntX",          0.0];
_heli setVariable ["fza_sfmplus_posIntY",          0.0];

//Master-tuned lateral CoM offset (m). Baked from the tuner export.
_heli setVariable ["fza_sfmplus_tune_comOffsetX",  0.1];

//ONE-TIME strip of stale PID gains from the PERSISTED tuner profile. The saved profile overlays the
//seeds on load, so a PID the auto-tuner had driven to a bad value (e.g. posPitch_kp 0.10 that
//saturated the servo) persisted across respawns. This clears ONLY the PID-gain keys (ending
//_kp/_ki/_kd, plus posInt*) ONCE - guarded by a bump flag - so after the one-time clear, normal
//Save/Load work again and GOOD tuned PIDs you save WILL persist. Bump the flag number to force
//another one-time clear later. Force-tables + other entries are never touched.
//v2: bumped for the auto-pedal rework. The three auto-pedal PIDs (apHdg/apNtt/apAero) replaced the
//old single slip channel and are on completely different error scales - apAero especially (kp 10.0
//per G, where the old channel ran on the +-1 normalized gauge). Any profile saved before this change
//holds gains that are meaningless against the new signals, so they must be cleared once.
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
//GAINS. Error is in DEGREES. The original kp 0.05 was too slow (a 5 deg error gave only 0.25 of
//control, and with the old slow trim slew the loop ran behind the aircraft and wobbled); kp 0.25
//was FAR too fast and produced violent oscillation. These sit between the two, closer to the slow
//end, because this loop runs with NO rate damping underneath it on the pitch axis by default -
//see the SAS note below. Raise kp in SMALL steps (0.02) and only alongside kd.
//
//kd is the damping / phase-lead term and is what stops the overshoot; it is deliberately large
//relative to kp here. dCoef is lifted off the 0.3 default (fn_pidRun) because that heavy filter
//exists for noisy lateral-g signals and was removing the lead this loop depends on - but not to
//0.8, which passed enough frame-to-frame noise into kd to contribute to the violence.
_heli setVariable ["fza_sfmplus_pid_autoPitch",      [0.1200, 0.0200, 0.1000, 5.0000] call fza_fnc_pidCreate];
(_heli getVariable "fza_sfmplus_pid_autoPitch") set ["dCoef", 0.5];
_heli setVariable ["fza_sfmplus_autoPitchActive",    true];
_heli setVariable ["fza_sfmplus_autoPitchTarget",    -6.0];
//Auto roll. The ki term is the part that actually matters here: it is what winds up to absorb
//the airframe's standing right-roll trim offset and hold wings-level. A rate-damping SAS cannot
//do this (zero setpoint on RATE = no attitude reference), which is why the roll persists without
//this loop. Gains mirror auto pitch; roll is the lower-inertia axis so kd carries a little more.
//Roll is the LOW-INERTIA axis - it responds faster than pitch, so it needs LESS gain, not more
//(the earlier 0.30 had this backwards: a quicker axis reaches the same rate on less input, so the
//same kp is effectively hotter there). Kept slightly below pitch for that reason.
_heli setVariable ["fza_sfmplus_pid_autoRoll",       [0.0700, 0.0200, 0.0900, 5.0000] call fza_fnc_pidCreate];
(_heli getVariable "fza_sfmplus_pid_autoRoll") set ["dCoef", 0.5];
_heli setVariable ["fza_sfmplus_autoRollActive",     true];
_heli setVariable ["fza_sfmplus_autoRollTarget",     0.0];
//Auto hover (the HOVER regime of auto-attitude - position hold on the cyclic). These PIDs act on
//GROUND VELOCITY (m/s), NOT attitude, so they keep their own gains - do not "unify" them with the
//attitude gains above, the error units are different and the numbers are not comparable.
//
//Seeded from the FMC position hold's real tuned values (tune_posPitch/_posRoll: kp 0.030/0.015,
//kd 0.060) and scaled up MODESTLY, because the output ranges differ: fn_fmcAttitudeHold clamps
//its result to +-0.1 (a 10% servo) before it leaves the function, while this writes force-trim
//over the full +-1.0 range - so the raw numbers give a fraction of the intended authority here.
//A full 10x scaling was tried and was far too hot (the attitude loops oscillated violently on an
//equivalent jump); ~3x is the conservative starting point. Raise in small steps if the hover
//drifts, and expect these to need their own tuning pass - they drive a different path than the
//loop they were seeded from.
//ki IS THE POINT OF THIS LOOP, not an afterthought. Pitch and bank can never be exactly zero at a
//hover - the aircraft settles wherever the forces balance (tail thrust, CG offset, wind) - so
//holding a hover means parking the cyclic at a STANDING OFFSET that cancels those forces. That
//offset is precisely what an integrator converges to. kp alone cannot hold it: with zero velocity
//error it commands zero cyclic and the aircraft drifts off again. ki_clamp is the ceiling on how
//much standing cyclic it may find (1.0 = full authority; it needs real room to do this job).
//Velocity-null gains. Error is m/s of ground drift. In-flight measurement showed the previous
//values had far too little authority: a 3.2 m/s aft drift produced only 0.203 of pitch command,
//with BOTH integrators pinned at the old 0.3 ki_clamp - saturated and unable to contribute more.
//kp is raised so a real drift produces a real correction, and ki_clamp opened up so the
//integrator has room to find the standing cyclic offset that holds the hover instead of railing.
//kd stays high relative to kp: it is the damping that keeps this from hunting, and the earlier
//violent divergence came from raising kp and the position clamp together, not from kd.
//History: 0.05/0.10 kp + 0.02 posclamp = too weak, drifted.
//         0.25/0.30 kp + 1.50 posclamp = violent (both raised at once).
//         0.04/0.05 kp + 0.40 posclamp = far too weak; position term saturated (measured).
//         0.12/0.14 kp + 1.00 ki_clamp = OUTPUT RAILED at 1.000 on both axes (measured) ->
//                    violent. A saturated controller can only slam between its limits.
//ki_clamp is back down: the roll integrator wound straight to 1.000 and by itself railed the
//output. The integrator only needs enough room for the standing hover offset (a few tenths of
//cyclic), not full authority - anything more is windup waiting to happen.
//kd REDUCED because the ACCELERATION LEAD (AUTO_ATT_ACCEL_LEAD, applied to the measurement in
//fn_getInput) now supplies the anticipation, and from a much cleaner signal - the airframe's own
//smoothed acceleration rather than a noisy derivative of velocity error. Leaving the old kd in
//alongside it double-counts the same physics and re-introduces the hunting it was meant to damp.
//ki RAISED 0.015 -> 0.25. This is the term that was actually missing, and the clamp chase was a
//red herring: raising ki_clamp 0.25 -> 0.60 let the integral reach 0.600, and the output moved by
//0.001. Decomposing the measured frame (set 1.500, vel -1.397, int 0.600, out 0.217) shows why -
//  kp * error = 0.070 * 2.897 = 0.203   (93.5% of the output)
//  ki * integ = 0.015 * 0.600 = 0.009   ( 4.1% of the output)
//The integral could not influence anything at that gain, so its cap never mattered. Holding a
//hover REQUIRES a standing cyclic offset, and the integral is the right term to carry it: it
//builds smoothly and, unlike kp, does not react to every small velocity fluctuation - which is
//why kp is the term that produced violent divergence and must stay where it is.
//PITCH ki_clamp 0.25 -> 0.55, ROLL LEFT ALONE.
//With ki finally meaningful, the clamp is now a real constraint rather than the red herring it
//was at ki 0.015. Measured: lateral drift 0.004 m/s (roll is SOLVED - do not touch the X gains),
//aft drift halved to -0.752 but persisting, with the pitch integrator pinned on 0.250.
//The AH-64 needs more standing FORWARD cyclic at a hover than lateral - the CG sits aft of the
//rotor mast and the aircraft trims nose-up - so it is expected that pitch needs a bigger standing
//offset than roll. Asymmetric clamps are correct here, not a smell.
//PITCH ki_clamp 0.55 - this is the KNOWN-GOOD value. It held a hover at vel 0.000/-0.001.
//
//Do NOT raise it to 1.00. That was tried and produced huge unprompted pitch excursions: the
//integral railed at 1.000, contributing 0.25 of cyclic on its own, and the total output reached
//0.964 - near-full forward stick - while STILL drifting aft at 2.9 m/s.
//
//The reasoning that led to 1.00 was wrong and is worth recording: the settled hover trim measured
//0.216, and that was treated as if the INTEGRAL alone had to supply it (0.216/ki = 0.864, so the
//clamp "needed" to be ~0.9). But the settled trim is the SUM of kp*error + ki*integral - the kp
//term supplies most of it. Sizing the clamp as though the integral carries the whole offset
//oversizes it several-fold.
_heli setVariable ["fza_sfmplus_pid_autoHoverX",     [0.0600, 0.2200, 0.0500, 0.2500] call fza_fnc_pidCreate];
_heli setVariable ["fza_sfmplus_pid_autoHoverY",     [0.0700, 0.2500, 0.0600, 0.5500] call fza_fnc_pidCreate];
(_heli getVariable "fza_sfmplus_pid_autoHoverX") set ["dCoef", 0.5];
(_heli getVariable "fza_sfmplus_pid_autoHoverY") set ["dCoef", 0.5];
//VEL regime (transition): ROLL nulls lateral drift, PITCH holds forward velocity. Same error
//units as the hover PIDs (m/s of ground velocity) so they start from the same numbers. The
//lateral channel matters most here - it is what stops the hands and the auto-pedal's feet
//fighting each other over a drifting velocity vector - and carries ki for the same reason the
//hover loop does: holding zero drift needs a standing cyclic offset, not just a proportional nudge.
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
//PRE-SEEDED hover integrals, so the very FIRST pickup already carries the standing cyclic offset.
//The AH-64 trims nose-up at a hover (CG aft of the mast), so holding station needs standing
//FORWARD cyclic. With the integral starting at zero that cyclic simply is not there while the
//aircraft comes off the ground - it pitches back as it gets light on the gear, drifts aft, and the
//loop only catches up afterwards (which is the oscillation). 0.550 is the value the pitch integral
//was MEASURED converging to in a settled hover; roll converges near zero, so it starts there.
//These are overwritten by the learned values (fza_sfmplus_autoHoverLearnedInt*) as soon as the
//aircraft holds a steady hover, so this is only the cold-start estimate.
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

//AUTO-PEDAL auto-tuner. Only DOES anything while fza_sfmplus_tune_pedalAutoOn is true (and the
//other two tuners are off). Tunes whichever of the three auto-pedal regimes is LIVE right now
//(hover heading / nose-to-tail below 50ft / aerodynamic trim above 50ft) - fly each regime to
//tune it. Run AFTER the SAS tuner (yaw SAS is the inner loop beneath it). Runs as its own PFH.
[{ (_this select 0) params ["_heli"]; [_heli] call fza_sfmplus_fnc_tunerPedalAuto; }, 0, [_heli]] call CBA_fnc_addPerFrameHandler;
