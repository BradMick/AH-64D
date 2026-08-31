/* ----------------------------------------------------------------------------
Function: bmkhs_fnc_massVariables

Description:
    Loads the mass and balance configuration - fuselage datum, CG limits, and
    the indexed seat, tank, station, magazine and store tables.

Parameters:
    _heli   - The helicopter to get information from [Unit].
    _config - The aircraft's HeliSim config [Config].

Returns:
    Nothing
---------------------------------------------------------------------------- */
params ["_heli", "_config"];

//Mass and balance - datum and CG limits
_heli setVariable ["bmkhs_fsDatum",        getNumber (_config >> "fsDatum")];
_heli setVariable ["bmkhs_fwdCgLimit",     getNumber (_config >> "fwdCgLimit")];
_heli setVariable ["bmkhs_aftCgLimit",     getNumber (_config >> "aftCgLimit")];
_heli setVariable ["bmkhs_crewMass",       getNumber (_config >> "crewMass")];

//Empty mass and moment
_heli setVariable ["bmkhs_emptyMassFCR",       getNumber (_config >> "emptyMassFCR")];        //kg
_heli setVariable ["bmkhs_emptyMomFCR",        getNumber (_config >> "emptyMomFCR")];
_heli setVariable ["bmkhs_emptyMassNonFCR",    getNumber (_config >> "emptyMassNonFCR")];     //kg
_heli setVariable ["bmkhs_emptyMomNonFCR",     getNumber (_config >> "emptyMomNonFCR")];

//Indexed mass items. Each table is flattened to a plain array at load so the per-frame
//massUpdate never touches config.
//Class names are zero-padded to two digits (Seat01, Store01) so they sort correctly.
private _readClass = {
    params ["_parent", "_prefix", "_count"];
    private _out = [];
    for "_i" from 1 to _count do {
        _out pushBack (_parent >> format ["%1%2", _prefix, (["0", ""] select (_i > 9)) + str _i]);
    };
    _out
};

//SEATS: [arm, mass, role, turretPath, cargoIndex]
private _seats = [];
{
    _seats pushBack [
        getArray  (_x >> "arm"),
        getNumber (_x >> "mass"),
        toLower getText (_x >> "role"),
        getArray  (_x >> "turret"),
        getNumber (_x >> "cargoIndex")
    ];
} forEach ([_config >> "Seats", "Seat", getNumber (_config >> "numSeats")] call _readClass);
_heli setVariable ["bmkhs_seats", _seats];

//TANKS: [name, arm, capacity, station]
private _tanks = [];
{
    _tanks pushBack [
        getText   (_x >> "name"),
        getArray  (_x >> "arm"),
        getNumber (_x >> "capacity"),
        getNumber (_x >> "station")
    ];
} forEach ([_config >> "Tanks", "Tank", getNumber (_config >> "numTanks")] call _readClass);
_heli setVariable ["bmkhs_tanks", _tanks];

//STATIONS: [arm, pylons]
private _stations = [];
{
    _stations pushBack [
        getArray (_x >> "arm"),
        getArray (_x >> "pylons")
    ];
} forEach ([_config >> "Stations", "Station", getNumber (_config >> "numStations")] call _readClass);
_heli setVariable ["bmkhs_stations", _stations];

//MAGAZINES: [match, arm, massPerRound]
private _magazines = [];
{
    _magazines pushBack [
        toLower getText (_x >> "match"),
        getArray  (_x >> "arm"),
        getNumber (_x >> "massPerRound")
    ];
} forEach ([_config >> "Magazines", "Mag", getNumber (_config >> "numMagazines")] call _readClass);
_heli setVariable ["bmkhs_magazines", _magazines];

//STORES: [match, launcherMass, massPerRound, isTank]
private _stores = [];
{
    _stores pushBack [
        toLower getText (_x >> "match"),
        getNumber (_x >> "launcherMass"),
        getNumber (_x >> "massPerRound"),
        getNumber (_x >> "isTank") > 0
    ];
} forEach ([_config >> "Stores", "Store", getNumber (_config >> "numStores")] call _readClass);
_heli setVariable ["bmkhs_stores", _stores];
