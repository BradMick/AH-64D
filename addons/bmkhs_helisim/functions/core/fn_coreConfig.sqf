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


//Subsystem gates - the aircraft config decides which systems Core runs
_heli setVariable ["bmkhs_useSystems",          getNumber (_config >> "useSystems")          > 0];
_heli setVariable ["bmkhs_useAPU",              getNumber (_config >> "useAPU")              > 0];
_heli setVariable ["bmkhs_useElectricalSystem", getNumber (_config >> "useElectricalSystem") > 0];
_heli setVariable ["bmkhs_useHydraulicSystem",  getNumber (_config >> "useHydraulicSystem")  > 0];
_heli setVariable ["bmkhs_useDrivetrain",       getNumber (_config >> "useDrivetrain")       > 0];

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
_heli setVariable ["bmkhs_pid_roll",           [0.0550, 0.0070, 0.0900, 0.0070] call bmkhs_fnc_pidCreate];
_heli setVariable ["bmkhs_pid_pitch",          [0.1500, 0.0070, 0.1200, 0.0070] call bmkhs_fnc_pidCreate];
//Attitude Hold
_heli setVariable ["bmkhs_pid_roll_att",       [0.0400, 0.0015, 0.0180, 0.0015] call bmkhs_fnc_pidCreate];
_heli setVariable ["bmkhs_pid_pitch_att",      [0.0925, 0.0025, 0.0450, 0.0025] call bmkhs_fnc_pidCreate];
//Altitude Hold
_heli setVariable ["bmkhs_pid_radHold",        [0.0500, 0.0001, 0.0050, 0.0001] call bmkhs_fnc_pidCreate];
_heli setVariable ["bmkhs_pid_barHold",        [0.0010, 0.0000, 0.0008, 0.0000] call bmkhs_fnc_pidCreate];
//Heading Hold
_heli setVariable ["bmkhs_pid_hdgHold",        [0.0750, 0.0200, 0.0050, 0.0200] call bmkhs_fnc_pidCreate];
//Turn coordination / yaw slip loop. Error is LATERAL G (bmkhs_aero_beta_g); output is
//clamped to +-0.1 in fn_fmcHeadingHold, so size the gains against that, not the +-1 gauge.
_heli setVariable ["bmkhs_pid_trnCoord",       [0.2500, 0.0600, 0.3000, 0.1500] call bmkhs_fnc_pidCreate];
//SAS - proportional rate DAMPING (output = -kp*rate).
_heli setVariable ["bmkhs_pid_sas_pitch",      [0.1500, 0.0000, 0.0020, 0.0000] call bmkhs_fnc_pidCreate];
_heli setVariable ["bmkhs_pid_sas_roll",       [0.1000, 0.0000, 0.0020, 0.0000] call bmkhs_fnc_pidCreate];
_heli setVariable ["bmkhs_pid_sas_yaw",        [0.3000, 0.0500, 0.0250, 0.0500] call bmkhs_fnc_pidCreate];

_heli setVariable ["bmkhs_pid_autoPedalHdg",   [0.1000, 0.0050, 0.0500, 30.000] call bmkhs_fnc_pidCreate];
_heli setVariable ["bmkhs_pid_autoPedalNtt",   [0.0300, 0.0080, 0.0100, 18.750] call bmkhs_fnc_pidCreate];
_heli setVariable ["bmkhs_pid_autoPedalAero",  [1.5000, 2.0000, 0.4000, 0.2000] call bmkhs_fnc_pidCreate];

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
_heli setVariable ["bmkhs_pid_engine",        [[0.7000, 0.0000, 0.0005, 0.0000] call bmkhs_fnc_pidCreate, [0.7000, 0.0000, 0.0005, 0.0000] call bmkhs_fnc_pidCreate]];
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
