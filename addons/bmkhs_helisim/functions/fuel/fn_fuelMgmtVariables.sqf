/* ----------------------------------------------------------------------------
Function: bmkhs_fnc_fuelMgmtVariables

Description:
    Initialises all fuel management state variables on a helicopter.
    Called from bmkhs_fnc_coreConfig after the SFM fuel variables.

Parameters:
    _heli - The helicopter to initialise [Unit].

Returns:
    None

Author:
    FZA Development Team
---------------------------------------------------------------------------- */
params ["_heli"];

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
