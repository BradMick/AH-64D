/* ----------------------------------------------------------------------------
Function: bmkhs_fnc_fuelVariables

Description:
    Loads the fuel configuration and initialises the fuel and fuel
    management state - tank quantities, capacities, valves and pumps.

Parameters:
    _heli   - The helicopter to get information from [Unit].
    _config - The aircraft's HeliSim config [Config].

Returns:
    ...

Examples:
    ...

Author:
    BradMick
---------------------------------------------------------------------------- */
params ["_heli", "_config"];

_heli setVariable ["bmkhs_fwdFuelMass",    0.0];
_heli setVariable ["bmkhs_ctrFuelMass",    0.0];
_heli setVariable ["bmkhs_aftFuelMass",    0.0];

_heli setVariable ["bmkhs_stn1FuelMass",   0.0];
_heli setVariable ["bmkhs_stn2FuelMass",   0.0];
_heli setVariable ["bmkhs_stn3FuelMass",   0.0];
_heli setVariable ["bmkhs_stn4FuelMass",   0.0];

_heli setVariable ["bmkhs_totFuelMass",    0.0];
_heli setVariable ["bmkhs_maxTotFuelMass", 0.0];

//Fuel
_heli setVariable ["bmkhs_fwdFuelLowKg",       getNumber (_config >> "fwdFuelLowKg")];
_heli setVariable ["bmkhs_aftFuelLowKg",       getNumber (_config >> "aftFuelLowKg")];
_heli setVariable ["bmkhs_fuelFlowLbsPerHour", getNumber (_config >> "fuelFlowLbsPerHour")];

//Tank capacities
_heli setVariable ["bmkhs_maxFwdFuelMass",     getNumber (_config >> "maxFwdFuelMass")];  //1043lbs in kg
_heli setVariable ["bmkhs_maxCtrFuelMass",     getNumber (_config >> "maxCtrFuelMass")];  //663lbs in kg, net yet implemented, center robbie
_heli setVariable ["bmkhs_maxAftFuelMass",     getNumber (_config >> "maxAftFuelMass")];  //1474lbs in kg
_heli setVariable ["bmkhs_maxExtFuelMass",     getNumber (_config >> "maxExtFuelMass")];     //1541lbs in kg, not yet implemented, 230gal external tank

// Crossfeed valve position: "NORM" | "FWD" | "AFT"
_heli setVariable ["bmkhs_crossfeedMode", "NORM"];

// XFER pump selection: "OFF" | "AFT" | "FWD" | "AUTO"
_heli setVariable ["bmkhs_xferMode", "AUTO"];

// Boost pump state
_heli setVariable ["bmkhs_boostOn", false];

// Fuel system status flags
_heli setVariable ["bmkhs_intercellTransferActive", false];
_heli setVariable ["bmkhs_intercellTransferDir", 0];
_heli setVariable ["bmkhs_eng1FuelAvail", true];
_heli setVariable ["bmkhs_eng2FuelAvail", true];
_heli setVariable ["bmkhs_apuFuelAvail",  true];

// AUX tank on/off — L controls all left-side stations, R controls all right-side stations
// Default OFF — crew must arm before transfer begins
_heli setVariable ["bmkhs_lAuxOn", false];
_heli setVariable ["bmkhs_rAuxOn", false];

// CHECK sub-mode
_heli setVariable ["bmkhs_checkMinutes",   15];
_heli setVariable ["bmkhs_checkRunning",   false];
_heli setVariable ["bmkhs_checkDone",      false];
_heli setVariable ["bmkhs_checkStartTime", 0];
_heli setVariable ["bmkhs_checkStartFuel", 0];
_heli setVariable ["bmkhs_checkActivePlt", false];
_heli setVariable ["bmkhs_checkActiveCpg", false];
_heli setVariable ["bmkhs_checkPendingAdvisory", false];
_heli setVariable ["bmkhs_checkStartZulu",   ""];
_heli setVariable ["bmkhs_checkBurnoutZulu", ""];
_heli setVariable ["bmkhs_checkVFRZulu",     ""];
_heli setVariable ["bmkhs_checkIFRZulu",     ""];

// CHECK computed display values (lb/hr, seconds elapsed)
_heli setVariable ["bmkhs_checkElapsedSec", 0];
_heli setVariable ["bmkhs_checkBurnRate",   0];
