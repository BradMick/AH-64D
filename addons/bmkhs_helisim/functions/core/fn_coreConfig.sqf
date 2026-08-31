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


//Systems gate - all or nothing
_heli setVariable ["bmkhs_useSystems",          getNumber (_config >> "useSystems")          > 0];

_heli setVariable ["bmkhs_emptyMassFCR",       getNumber (_config >> "emptyMassFCR")];        //kg
_heli setVariable ["bmkhs_emptyMomFCR",        getNumber (_config >> "emptyMomFCR")];

_heli setVariable ["bmkhs_emptyMassNonFCR",    getNumber (_config >> "emptyMassNonFCR")];     //kg
_heli setVariable ["bmkhs_emptyMomNonFCR",     getNumber (_config >> "emptyMomNonFCR")];


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

//Aerodynamic State Variables
_heli setVariable ["bmkhs_aero_beta_deg",      0.0];
_heli setVariable ["bmkhs_aero_beta_g",        0.0];
_heli setVariable ["bmkhs_aero_beta_g_prev",   0.0];   //EGI low-pass filter state for the skid/slip (beta_g)
//Keyboard
_heli setVariable ["bmkhs_cyclicPitchValue",   0.0];
_heli setVariable ["bmkhs_cyclicRollValue",    0.0];
_heli setVariable ["bmkhs_pedalYawValue",      0.0];
//Fuel
[_heli, _config] call bmkhs_fnc_inputVariables;
[_heli, _config] call bmkhs_fnc_massVariables;
[_heli, _config] call bmkhs_fnc_fmcVariables;
[_heli, _config] call bmkhs_fnc_systemsVariables;
[_heli, _config] call bmkhs_fnc_fuelVariables;
[_heli] call bmkhs_fnc_fuelMgmtVariables;
[_heli] call bmkhs_fnc_fuelSet;
//Engines
private _engPidGains = getArray (_config >> "pidEngine");
_heli setVariable ["bmkhs_pid_engine", [ _engPidGains call bmkhs_fnc_pidCreate
                                       , _engPidGains call bmkhs_fnc_pidCreate]];
[_heli, _config] call bmkhs_fnc_engineVariables;
//Fuselage
[_heli] call bmkhs_fnc_fuselageVariables;
[_heli, _config] call bmkhs_fnc_wingVariables;
//Transmission
[_heli] call bmkhs_fnc_transmissionVariables;
//Rotors
[_heli, _config] call bmkhs_fnc_simpleRotorVariables;
[_heli, _config] call bmkhs_fnc_rotorVariables;
//Performance
[_heli] call bmkhs_fnc_perfVariables;
//Actuators
[_heli] call bmkhs_fnc_actuatorVariables;
//Preston Pilot AI (machine pilot) - PIDs, targets and filter state.
[_heli] call bmkhs_fnc_prestonVariables;
