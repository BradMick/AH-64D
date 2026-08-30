/* ----------------------------------------------------------------------------
Function: bmkhs_fnc_coreConfig

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
params ["_heli", ["_configIn", configNull]];

//Caller supplies the config; fall back to the vehicle class for legacy callers
private _config = if (isNull _configIn) then { configOf _heli >> "BMKHS_HeliSim" } else { _configIn };
bmkhs_movingAverageSize = 10;
bmkhs_liftLossTimer     = 0;

_heli setVariable ["bmkhs_kbStickyInterupt",     false];
_heli setVariable ["bmkhs_flightControlLockOut", false];

//Cyclic input
_heli setVariable ["bmkhs_heliCyclicForwardOut",   0.0];
_heli setVariable ["bmkhs_heliCyclicBackwardOut",  0.0];
_heli setVariable ["bmkhs_heliCyclicLeftOut",      0.0];
_heli setVariable ["bmkhs_heliCyclicRightOut",     0.0];
//Pedal input
_heli setVariable ["bmkhs_heliRudderLeftOut",      0.0];
_heli setVariable ["bmkhs_heliRudderRightOut",     0.0];
//Collective input
_heli setVariable ["bmkhs_heliCollectiveRaiseOut", 0.0];
_heli setVariable ["bmkhs_heliCollectiveLowerOut", 0.0];

_heli setVariable ["bmkhs_cyclicFwdAft",          0.0];
_heli setVariable ["bmkhs_cyclicPitchValue",      0.0];
_heli getVariable ["bmkhs_prevCyclicPitchValue",  0.0];

_heli setVariable ["bmkhs_cyclicLeftRight",       0.0];
_heli setVariable ["bmkhs_cyclicRollValue",       0.0];
_heli setVariable ["bmkhs_prevCyclicRollValue",   0.0];

_heli setVariable ["bmkhs_pedalLeftRight",        0.0];
_heli setVariable ["bmkhs_kbPedalLeftRight",      0.0];
_heli setVariable ["bmkhs_pedalYawValue",         0.0];
_heli setVariable ["bmkhs_prevPedalYawValue",     0.0];

_heli setVariable ["bmkhs_collectiveOutput",      0.0];

_heli setVariable ["bmkhs_previousTime",        0.0];
_heli setVariable ["bmkhs_deltaTime",           0.0];
_heli setVariable ["bmkhs_deltaTime_avg",       [bmkhs_movingAverageSize] call bmkhs_fnc_smoothAverageInit];

_heli setVariable ["bmkhs_gndSpeed",            0.0];
_heli setVariable ["bmkhs_vel2D",               0.0];
_heli setVariable ["bmkhs_vel3D",               0.0];
_heli setVariable ["bmkhs_velWindWorldSpace",   [0.0,0.0,0.0]];
_heli setVariable ["bmkhs_velWindModelSpace",   [0.0,0.0,0.0]];
_heli setVariable ["bmkhs_windDirFrom",         0];
_heli setVariable ["bmkhs_windSpeedKts",        0];
_heli setVariable ["bmkhs_velModelSpace",       [0.0,0.0,0.0]];
_heli setVariable ["bmkhs_velModelSpaceNoWind", [0.0,0.0,0.0]];
_heli setVariable ["bmkhs_velModelSpaceX_avg",  [bmkhs_movingAverageSize] call bmkhs_fnc_smoothAverageInit];
_heli setVariable ["bmkhs_velModelSpaceY_avg",  [bmkhs_movingAverageSize] call bmkhs_fnc_smoothAverageInit];
_heli setVariable ["bmkhs_velModelSpaceZ_avg",  [bmkhs_movingAverageSize] call bmkhs_fnc_smoothAverageInit];
_heli setVariable ["bmkhs_velWorldSpace",       [0.0,0.0,0.0]];
_heli setVariable ["bmkhs_velWorldSpaceNoWind", [0.0,0.0,0.0]];
_heli setVariable ["bmkhs_velWorldSpaceNoWind_prev", [0.0,0.0,0.0]];
_heli setVariable ["bmkhs_velWorldSpaceX_avg",  [bmkhs_movingAverageSize] call bmkhs_fnc_smoothAverageInit];
_heli setVariable ["bmkhs_velWorldSpaceY_avg",  [bmkhs_movingAverageSize] call bmkhs_fnc_smoothAverageInit];
_heli setVariable ["bmkhs_velWorldSpaceZ_avg",  [bmkhs_movingAverageSize] call bmkhs_fnc_smoothAverageInit];
_heli setVariable ["bmkhs_velClimb",            0.0];
_heli setVariable ["bmkhs_angVelModelSpace",    [0.0,0.0,0.0]];
_heli setVariable ["bmkhs_angVelModelSpaceX_avg", [bmkhs_movingAverageSize] call bmkhs_fnc_smoothAverageInit];
_heli setVariable ["bmkhs_angVelModelSpaceY_avg", [bmkhs_movingAverageSize] call bmkhs_fnc_smoothAverageInit];
_heli setVariable ["bmkhs_angVelModelSpaceZ_avg", [bmkhs_movingAverageSize] call bmkhs_fnc_smoothAverageInit];

_heli setVariable ["bmkhs_worldAccel",        [0.0,0.0,0.0]];

//Smoothed worldAccel - slip ball only.
_heli setVariable ["bmkhs_worldAccelFiltered", [0.0,0.0,0.0]];
_heli setVariable ["bmkhs_worldAccelX_avg",   [bmkhs_movingAverageSize] call bmkhs_fnc_smoothAverageInit];
_heli setVariable ["bmkhs_worldAccelY_avg",   [bmkhs_movingAverageSize] call bmkhs_fnc_smoothAverageInit];
_heli setVariable ["bmkhs_worldAccelZ_avg",   [bmkhs_movingAverageSize] call bmkhs_fnc_smoothAverageInit];

_heli setVariable ["bmkhs_velX_prev",         0.0];
_heli setVariable ["bmkhs_accelX",            0.0];
_heli setVariable ["bmkhs_accelX_avg",        [bmkhs_movingAverageSize] call bmkhs_fnc_smoothAverageInit];

_heli setVariable ["bmkhs_velY_prev",         0.0];
_heli setVariable ["bmkhs_accelY",            0.0];
_heli setVariable ["bmkhs_accelY_avg",        [bmkhs_movingAverageSize] call bmkhs_fnc_smoothAverageInit];

_heli setVariable ["bmkhs_velZ_prev",         0.0];
_heli setVariable ["bmkhs_accelZ",            0.0];
_heli setVariable ["bmkhs_accelZ_avg",        [bmkhs_movingAverageSize] call bmkhs_fnc_smoothAverageInit];


//Systems tuning - the aircraft supplies these, Core keeps damage thresholds fixed
_heli setVariable ["bmkhs_hydMinPsi",       getNumber (_config >> "hydMinPsi")];
_heli setVariable ["bmkhs_hydMinAccPsi",    getNumber (_config >> "hydMinAccPsi")];
_heli setVariable ["bmkhs_hydMinLevel",     getNumber (_config >> "hydMinLevel")];
_heli setVariable ["bmkhs_hydAccTimerMin",  getNumber (_config >> "hydAccTimerMin")];
_heli setVariable ["bmkhs_hydLeakTimerMin", getNumber (_config >> "hydLeakTimerMin")];
_heli setVariable ["bmkhs_elecBattTimerMin",getNumber (_config >> "elecBattTimerMin")];
_heli setVariable ["bmkhs_apuStartDelay",   getNumber (_config >> "apuStartDelay")];

//Drivetrain torque limits and timers
_heli setVariable ["bmkhs_ngbContTqLimit",    getNumber (_config >> "ngbContTqLimit")];
_heli setVariable ["bmkhs_ngbContTimer",      getNumber (_config >> "ngbContTimer")];
_heli setVariable ["bmkhs_ngbTransTqLimit",   getNumber (_config >> "ngbTransTqLimit")];
_heli setVariable ["bmkhs_ngbTransTimer",     getNumber (_config >> "ngbTransTimer")];
_heli setVariable ["bmkhs_ngbMaxTqLimit",     getNumber (_config >> "ngbMaxTqLimit")];
_heli setVariable ["bmkhs_xmsnContTqLimit",   getNumber (_config >> "xmsnContTqLimit")];
_heli setVariable ["bmkhs_xmsnTransTqLimit",  getNumber (_config >> "xmsnTransTqLimit")];
_heli setVariable ["bmkhs_xmsnTransTimer",    getNumber (_config >> "xmsnTransTimer")];
//Engine - power, governing and limits
_heli setVariable ["bmkhs_engContPwrKW",    getNumber (_config >> "engContPwrKW")];
_heli setVariable ["bmkhs_engCntgncyPwrKW", getNumber (_config >> "engCntgncyPwrKW")];
_heli setVariable ["bmkhs_engDesignRPM",    getNumber (_config >> "engDesignRPM")];
_heli setVariable ["bmkhs_engFriction",     getNumber (_config >> "engFriction")];
_heli setVariable ["bmkhs_engGovGain",      getNumber (_config >> "engGovGain")];
_heli setVariable ["bmkhs_engRunNG",        getNumber (_config >> "engRunNG")];
_heli setVariable ["bmkhs_engMaxTGT_DE",    getNumber (_config >> "engMaxTGT_DE")];
_heli setVariable ["bmkhs_engMaxTGT_SE",    getNumber (_config >> "engMaxTGT_SE")];
//Np/Ng references already exist as engIdleNP/engFlyNP/engOvrspdNP/engIdleNG/engFlyNG
_heli setVariable ["bmkhs_engIdleNP",       getNumber (_config >> "engIdleNP")];
_heli setVariable ["bmkhs_engFlyNP",        getNumber (_config >> "engFlyNP")];
_heli setVariable ["bmkhs_engOvrspdNP",     getNumber (_config >> "engOvrspdNP")];
_heli setVariable ["bmkhs_engIdleNG",       getNumber (_config >> "engIdleNG")];
_heli setVariable ["bmkhs_engFlyNG",        getNumber (_config >> "engFlyNG")];

//BET rotor - per-rotor arrays, index 0 = main, 1 = tail
_heli setVariable ["bmkhs_numRotors",          getNumber (_config >> "numRotors")];
_heli setVariable ["bmkhs_rotorType",          getArray  (_config >> "rotorType")];
_heli setVariable ["bmkhs_rotorDirection",     getArray  (_config >> "rotorDirection")];
_heli setVariable ["bmkhs_rotorNumBlades",     getArray  (_config >> "rotorNumBlades")];
_heli setVariable ["bmkhs_rotorNumElements",   getArray  (_config >> "rotorNumElements")];
_heli setVariable ["bmkhs_rotorMastLength",    getArray  (_config >> "rotorMastLength")];
_heli setVariable ["bmkhs_rotorGearRatioArr",  getArray  (_config >> "rotorGearRatio")];
_heli setVariable ["bmkhs_rotorAirfoil",       getArray  (_config >> "rotorAirfoil")];
_heli setVariable ["bmkhs_rotorBladeCutout",   getArray  (_config >> "rotorBladeCutout")];
_heli setVariable ["bmkhs_rotorBladeLength",   getArray  (_config >> "rotorBladeLength")];
_heli setVariable ["bmkhs_rotorBladeChordArr", getArray  (_config >> "rotorBladeChord")];
_heli setVariable ["bmkhs_rotorBladeTwist",    getArray  (_config >> "rotorBladeTwist")];
_heli setVariable ["bmkhs_rotorBladeMassArr",  getArray  (_config >> "rotorBladeMass")];
_heli setVariable ["bmkhs_rotorDelta3",        getArray  (_config >> "rotorDelta3")];
_heli setVariable ["bmkhs_rotorPitchMin",      getArray  (_config >> "rotorPitchMin")];
_heli setVariable ["bmkhs_rotorPitchMid",      getArray  (_config >> "rotorPitchMid")];
_heli setVariable ["bmkhs_rotorPitchMax",      getArray  (_config >> "rotorPitchMax")];
_heli setVariable ["bmkhs_rotorRollMin",       getArray  (_config >> "rotorRollMin")];
_heli setVariable ["bmkhs_rotorRollMid",       getArray  (_config >> "rotorRollMid")];
_heli setVariable ["bmkhs_rotorRollMax",       getArray  (_config >> "rotorRollMax")];
_heli setVariable ["bmkhs_rotorCollMin",       getArray  (_config >> "rotorCollMin")];
_heli setVariable ["bmkhs_rotorCollMid",       getArray  (_config >> "rotorCollMid")];
_heli setVariable ["bmkhs_rotorCollMax",       getArray  (_config >> "rotorCollMax")];
_heli setVariable ["bmkhs_rotorAnimSource",    getArray  (_config >> "rotorAnimSource")];
_heli setVariable ["bmkhs_rotorHitPoint",      getArray  (_config >> "rotorHitPoint")];

//Rotor geometry
_heli setVariable ["bmkhs_mainRtrPos",          getArray  (_config >> "mainRtrPos")];
_heli setVariable ["bmkhs_mainRtrHeightAgl",    getNumber (_config >> "mainRtrHeightAgl")];
_heli setVariable ["bmkhs_mainRtrDesignRpm",    getNumber (_config >> "mainRtrDesignRpm")];
_heli setVariable ["bmkhs_mainRtrRpmTrimVal",   getNumber (_config >> "mainRtrRpmTrimVal")];
_heli setVariable ["bmkhs_mainRtrNumBlades",    getNumber (_config >> "mainRtrNumBlades")];
_heli setVariable ["bmkhs_mainRtrBladeRadius",  getNumber (_config >> "mainRtrBladeRadius")];
_heli setVariable ["bmkhs_mainRtrBladeChord",   getNumber (_config >> "mainRtrBladeChord")];
_heli setVariable ["bmkhs_mainRtrBladeMass",    getNumber (_config >> "mainRtrBladeMass")];
_heli setVariable ["bmkhs_mainRtrBladeHingeOff",getNumber (_config >> "mainRtrBladeHingeOff")];
_heli setVariable ["bmkhs_mainRtrBladePitchMin",getNumber (_config >> "mainRtrBladePitchMin")];
_heli setVariable ["bmkhs_mainRtrBladePitchMax",getNumber (_config >> "mainRtrBladePitchMax")];
_heli setVariable ["bmkhs_mainRtrBaseThrust",   getNumber (_config >> "mainRtrBaseThrust")];
_heli setVariable ["bmkhs_mainRotorGearRatio",  getNumber (_config >> "mainRtrGearRatio")];

_heli setVariable ["bmkhs_tailRtrPos",          getArray  (_config >> "tailRtrPos")];
_heli setVariable ["bmkhs_tailRtrDesignRpm",    getNumber (_config >> "tailRtrDesignRpm")];
_heli setVariable ["bmkhs_tailRtrRpmTrimVal",   getNumber (_config >> "tailRtrRpmTrimVal")];
_heli setVariable ["bmkhs_tailRtrGearRatio",    getNumber (_config >> "tailRtrGearRatio")];
_heli setVariable ["bmkhs_tailRtrNumBlades",    getNumber (_config >> "tailRtrNumBlades")];
_heli setVariable ["bmkhs_tailRtrBladeRadius",  getNumber (_config >> "tailRtrBladeRadius")];
_heli setVariable ["bmkhs_tailRtrBladeChord",   getNumber (_config >> "tailRtrBladeChord")];
_heli setVariable ["bmkhs_tailRtrBaseThrust",   getNumber (_config >> "tailRtrBaseThrust")];

//Systems gate - all or nothing
_heli setVariable ["bmkhs_useSystems",          getNumber (_config >> "useSystems")          > 0];

_heli setVariable ["bmkhs_emptyMassFCR",       getNumber (_config >> "emptyMassFCR")];        //kg
_heli setVariable ["bmkhs_emptyMomFCR",        getNumber (_config >> "emptyMomFCR")];

_heli setVariable ["bmkhs_emptyMassNonFCR",    getNumber (_config >> "emptyMassNonFCR")];     //kg
_heli setVariable ["bmkhs_emptyMomNonFCR",     getNumber (_config >> "emptyMomNonFCR")];

_heli setVariable ["bmkhs_stabWidth",          getNumber (_config >> "stabWidth")];           //m
_heli setVariable ["bmkhs_stabLength",         getNumber (_config >> "stabLength")];          //m

_heli setVariable ["bmkhs_aerodynamicCenter",  getArray  (_config >> "aerodynamicCenter")];   //m

_heli setVariable ["bmkhs_maxFwdFuelMass",     getNumber (_config >> "maxFwdFuelMass")];  //1043lbs in kg
_heli setVariable ["bmkhs_maxCtrFuelMass",     getNumber (_config >> "maxCtrFuelMass")];  //663lbs in kg, net yet implemented, center robbie
_heli setVariable ["bmkhs_maxAftFuelMass",     getNumber (_config >> "maxAftFuelMass")];  //1474lbs in kg
_heli setVariable ["bmkhs_maxExtFuelMass",     getNumber (_config >> "maxExtFuelMass")];     //1541lbs in kg, not yet implemented, 230gal external tank

_heli setVariable ["bmkhs_fmcAttHoldCycPitchOut", 0.0];
_heli setVariable ["bmkhs_fmcSasPitchOut",        0.0];
_heli setVariable ["bmkhs_fmcSasRollOut",         0.0];
_heli setVariable ["bmkhs_fmcHdgHoldPedalYawOut", 0.0];
_heli setVariable ["bmkhs_fmcSasYawOut",          0.0];
_heli setVariable ["bmkhs_fmcAltHoldCollOut",     0.0];

//Position Hold
_heli setVariable ["bmkhs_pid_roll", (getArray (_config >> "pidRoll")) call bmkhs_fnc_pidCreate];
_heli setVariable ["bmkhs_pid_pitch", (getArray (_config >> "pidPitch")) call bmkhs_fnc_pidCreate];
//Attitude Hold
_heli setVariable ["bmkhs_pid_roll_att", (getArray (_config >> "pidRollAtt")) call bmkhs_fnc_pidCreate];
_heli setVariable ["bmkhs_pid_pitch_att", (getArray (_config >> "pidPitchAtt")) call bmkhs_fnc_pidCreate];
//Altitude Hold
_heli setVariable ["bmkhs_pid_radHold", (getArray (_config >> "pidRadAlt")) call bmkhs_fnc_pidCreate];
_heli setVariable ["bmkhs_pid_barHold", (getArray (_config >> "pidBarAlt")) call bmkhs_fnc_pidCreate];
//Heading Hold
_heli setVariable ["bmkhs_pid_hdgHold", (getArray (_config >> "pidHdgHold")) call bmkhs_fnc_pidCreate];
//Turn coordination / yaw slip loop. Error is LATERAL G (bmkhs_aero_beta_g); output is
//clamped to +-0.1 in fn_fmcHeadingHold, so size the gains against that, not the +-1 gauge.
_heli setVariable ["bmkhs_pid_trnCoord", (getArray (_config >> "pidTrnCoord")) call bmkhs_fnc_pidCreate];
//SAS - proportional rate DAMPING (output = -kp*rate).
_heli setVariable ["bmkhs_pid_sas_pitch", (getArray (_config >> "pidSasPitch")) call bmkhs_fnc_pidCreate];
_heli setVariable ["bmkhs_pid_sas_roll", (getArray (_config >> "pidSasRoll")) call bmkhs_fnc_pidCreate];
_heli setVariable ["bmkhs_pid_sas_yaw", (getArray (_config >> "pidSasYaw")) call bmkhs_fnc_pidCreate];

_heli setVariable ["bmkhs_pid_autoPedalHdg", (getArray (_config >> "pidAutoPedalHdg")) call bmkhs_fnc_pidCreate];
_heli setVariable ["bmkhs_pid_autoPedalNtt", (getArray (_config >> "pidAutoPedalNtt")) call bmkhs_fnc_pidCreate];
_heli setVariable ["bmkhs_pid_autoPedalAero", (getArray (_config >> "pidAutoPedalAero")) call bmkhs_fnc_pidCreate];

_heli setVariable ["bmkhs_posIntKp",    0.0200];
_heli setVariable ["bmkhs_posIntClamp", 0.2500];
_heli setVariable ["bmkhs_posIntX",     0.0];
_heli setVariable ["bmkhs_posIntY",     0.0];

_heli setVariable ["bmkhs_autoPedalHdg",       getDir _heli];
_heli setVariable ["bmkhs_autoPedalRegime",    "hdg"];   //hdg | ntt | aero (live regime)
_heli setVariable ["bmkhs_autoPedalRegimeWgt", 1.0];     //0-1, share of the pedal that regime owns
_heli setVariable ["bmkhs_autoPedalHdgErr",    0.0];     //deg, heading error
_heli setVariable ["bmkhs_autoPedalNttErr",    0.0];     //deg, kinematic sideslip
_heli setVariable ["bmkhs_autoPedalAeroErr",   0.0];     //g,   lateral accel
_heli setVariable ["bmkhs_autoPedalOut",       0.0];     //blended pedal output
_heli setVariable ["bmkhs_autoPedalPrevOut",   0.0];     //pilot-feet filter state (rate limit + lag)
//Aerodynamic State Variables
_heli setVariable ["bmkhs_aero_beta_deg",      0.0];
_heli setVariable ["bmkhs_aero_beta_g",        0.0];
_heli setVariable ["bmkhs_aero_beta_g_prev",   0.0];   //EGI low-pass filter state for the skid/slip (beta_g)
//Keyboard
_heli setVariable ["bmkhs_cyclicPitchValue",   0.0];
_heli setVariable ["bmkhs_cyclicRollValue",    0.0];
_heli setVariable ["bmkhs_pedalYawValue",      0.0];
//Fuel
[_heli] call bmkhs_fnc_fuelVariables;
[_heli] call bmkhs_fnc_fuelMgmtVariables;
[_heli] call bmkhs_fnc_fuelSet;
//Engines
private _engPidGains = getArray (_config >> "pidEngine");
_heli setVariable ["bmkhs_pid_engine", [ _engPidGains call bmkhs_fnc_pidCreate
                                       , _engPidGains call bmkhs_fnc_pidCreate]];
[_heli] call bmkhs_fnc_engineVariables;
//Fuselage
[_heli] call bmkhs_fnc_fuselageVariables;
//Transmission
[_heli] call bmkhs_fnc_transmissionVariables;
//Rotors
[_heli] call bmkhs_fnc_simpleRotorVariables;
[_heli] call bmkhs_fnc_rotorVariables;
//Performance
[_heli] call bmkhs_fnc_perfVariables;
//Actuators
[_heli] call bmkhs_fnc_actuatorVariables;
//Preston Pilot AI (machine pilot) - PIDs, targets and filter state.
[_heli] call bmkhs_fnc_prestonVariables;
