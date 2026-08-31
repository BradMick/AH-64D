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

_heli setVariable ["bmkhs_totFuelMass",    0.0];
_heli setVariable ["bmkhs_maxTotFuelMass", 0.0];

_heli setVariable ["bmkhs_fuelFlowLbsPerHour", getNumber (_config >> "fuelFlowLbsPerHour")];

//Tanks. The table drives the loops; the per-tank numbered variables below are what the
//cockpit displays read, so a pack with more tanks gets more of them automatically.
private _numFuelTanks = getNumber (_config >> "numFuelTanks");
private _fuelTanks    = [];
for "_i" from 1 to _numFuelTanks do {
    private _t = (_config >> "FuelTanks") >> format ["FuelTank%1%2", ["0", ""] select (_i > 9), _i];
    private _capacity = getNumber (_t >> "capacity");
    private _removable = getNumber (_t >> "removable") > 0;

    _fuelTanks pushBack [
        getText  (_t >> "name"),
        getArray (_t >> "arm"),
        _capacity,
        getNumber (_t >> "lowFuelKg"),
        _removable
    ];

    _heli setVariable [format ["bmkhs_fuelTank%1Mass", _i], 0.0];
    _heli setVariable [format ["bmkhs_fuelTank%1Max",  _i], _capacity];
    _heli setVariable [format ["bmkhs_fuelTank%1Low",  _i], getNumber (_t >> "lowFuelKg")];
    //A removable tank starts absent; the aircraft installs it. Fixed tanks are always fitted.
    _heli setVariable [format ["bmkhs_fuelTank%1Installed", _i], !_removable];
};
_heli setVariable ["bmkhs_numFuelTanks", _numFuelTanks];
_heli setVariable ["bmkhs_fuelTanks",    _fuelTanks];

//Auxiliary tanks - fuel on a wing station. The arm comes from the station, not from here.
private _numAuxTanks = getNumber (_config >> "numAuxTanks");
private _auxTanks    = [];
for "_i" from 1 to _numAuxTanks do {
    private _t = (_config >> "AuxTanks") >> format ["AuxTank%1%2", ["0", ""] select (_i > 9), _i];
    private _capacity = getNumber (_t >> "capacity");

    _auxTanks pushBack [getNumber (_t >> "station"), _capacity];

    _heli setVariable [format ["bmkhs_auxTank%1Mass",       _i], 0.0];
    _heli setVariable [format ["bmkhs_auxTank%1Max",        _i], _capacity];
    _heli setVariable [format ["bmkhs_auxTank%1EmptyArmed", _i], false];
};
_heli setVariable ["bmkhs_numAuxTanks", _numAuxTanks];
_heli setVariable ["bmkhs_auxTanks",    _auxTanks];

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
