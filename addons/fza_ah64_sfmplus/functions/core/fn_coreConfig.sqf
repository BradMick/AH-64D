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

_heli setVariable ["fza_sfmplus_emptyMassNonFCR",    getNumber (_config >> "emptyMassNonFCR")];     //kg
_heli setVariable ["fza_sfmplus_emptyMomNonFCR",     getNumber (_config >> "emptyMomNonFCR")];

_heli setVariable ["fza_sfmplus_stabWidth",          getNumber (_config >> "stabWidth")];           //m
_heli setVariable ["fza_sfmplus_stabLength",         getNumber (_config >> "stabLength")];          //m

_heli setVariable ["fza_sfmplus_aerodynamicCenter",  getArray  (_config >> "aerodynamicCenter")];   //m

_heli setVariable ["fza_sfmplus_maxFwdFuelMass",     getNumber (_config >> "maxFwdFuelMass")];  //1043lbs in kg
_heli setVariable ["fza_sfmplus_maxCtrFuelMass",     getNumber (_config >> "maxCtrFuelMass")];  //663lbs in kg, net yet implemented, center robbie
_heli setVariable ["fza_sfmplus_maxAftFuelMass",     getNumber (_config >> "maxAftFuelMass")];  //1474lbs in kg
_heli setVariable ["fza_sfmplus_maxExtFuelMass",     getNumber (_config >> "maxExtFuelMass")];     //1541lbs in kg, not yet implemented, 230gal external tank

_heli setVariable ["fza_sfmplus_fmcAttHoldCycPitchOut", 0.0];
_heli setVariable ["fza_sfmplus_fmcSasPitchOut",        0.0];
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

_heli setVariable ["fza_sfmplus_pid_autoPedalHdg",   [0.1000, 0.0050, 0.0500, 30.000] call fza_fnc_pidCreate];
_heli setVariable ["fza_sfmplus_pid_autoPedalNtt",   [0.0300, 0.0080, 0.0100, 18.750] call fza_fnc_pidCreate];
_heli setVariable ["fza_sfmplus_pid_autoPedalAero",  [1.5000, 2.0000, 0.4000, 0.2000] call fza_fnc_pidCreate];

_heli setVariable ["fza_sfmplus_posIntKp",    0.0200];
_heli setVariable ["fza_sfmplus_posIntClamp", 0.2500];
_heli setVariable ["fza_sfmplus_posIntX",     0.0];
_heli setVariable ["fza_sfmplus_posIntY",     0.0];

_heli setVariable ["fza_sfmPlus_autoPedalHdg",       getDir _heli];
_heli setVariable ["fza_sfmplus_autoPedalRegime",    "hdg"];   //hdg | ntt | aero (live regime)
_heli setVariable ["fza_sfmplus_autoPedalRegimeWgt", 1.0];     //0-1, share of the pedal that regime owns
_heli setVariable ["fza_sfmplus_autoPedalHdgErr",    0.0];     //deg, heading error
_heli setVariable ["fza_sfmplus_autoPedalNttErr",    0.0];     //deg, kinematic sideslip
_heli setVariable ["fza_sfmplus_autoPedalAeroErr",   0.0];     //g,   lateral accel
_heli setVariable ["fza_sfmplus_autoPedalOut",       0.0];     //blended pedal output
_heli setVariable ["fza_sfmplus_autoPedalPrevOut",   0.0];     //pilot-feet filter state (rate limit + lag)
//Aerodynamic State Variables
_heli setVariable ["fza_sfmplus_aero_beta_deg",      0.0];
_heli setVariable ["fza_sfmplus_aero_beta_g",        0.0];
_heli setVariable ["fza_sfmplus_aero_beta_g_prev",   0.0];   //EGI low-pass filter state for the skid/slip (beta_g)
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
//Preston Pilot AI (machine pilot) - PIDs, targets and filter state.
[_heli] call fza_sfmplus_fnc_prestonVariables;
