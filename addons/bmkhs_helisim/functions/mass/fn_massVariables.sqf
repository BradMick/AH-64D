/* ----------------------------------------------------------------------------
Function: bmkhs_fnc_massVariables

Description:
    Loads the mass and balance configuration - fuselage datum, CG limits,
    crew mass and the station arms.

Parameters:
    _heli   - The helicopter to get information from [Unit].
    _config - The aircraft's HeliSim config [Config].

Returns:
    Nothing
---------------------------------------------------------------------------- */
params ["_heli", "_config"];

//Mass and balance - datum, CG limits, crew mass and station arms
_heli setVariable ["bmkhs_fsDatum",        getNumber (_config >> "fsDatum")];
_heli setVariable ["bmkhs_fwdCgLimit",     getNumber (_config >> "fwdCgLimit")];
_heli setVariable ["bmkhs_aftCgLimit",     getNumber (_config >> "aftCgLimit")];
_heli setVariable ["bmkhs_crewMass",       getNumber (_config >> "crewMass")];
_heli setVariable ["bmkhs_armCpg",         getArray  (_config >> "armCpg")];
_heli setVariable ["bmkhs_armPlt",         getArray  (_config >> "armPlt")];
_heli setVariable ["bmkhs_armFwdFuelCell", getArray  (_config >> "armFwdFuelCell")];
_heli setVariable ["bmkhs_armAmmoBay",     getArray  (_config >> "armAmmoBay")];
_heli setVariable ["bmkhs_armAftFuelCell", getArray  (_config >> "armAftFuelCell")];
_heli setVariable ["bmkhs_armStation01",   getArray  (_config >> "armStation01")];
_heli setVariable ["bmkhs_armStation02",   getArray  (_config >> "armStation02")];
_heli setVariable ["bmkhs_armStation03",   getArray  (_config >> "armStation03")];
_heli setVariable ["bmkhs_armStation04",   getArray  (_config >> "armStation04")];

//Empty mass and moment
_heli setVariable ["bmkhs_emptyMassFCR",       getNumber (_config >> "emptyMassFCR")];        //kg
_heli setVariable ["bmkhs_emptyMomFCR",        getNumber (_config >> "emptyMomFCR")];
_heli setVariable ["bmkhs_emptyMassNonFCR",    getNumber (_config >> "emptyMassNonFCR")];     //kg
_heli setVariable ["bmkhs_emptyMomNonFCR",     getNumber (_config >> "emptyMomNonFCR")];
