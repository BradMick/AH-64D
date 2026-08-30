/* ----------------------------------------------------------------------------
Function: bmkhs_fnc_fuelVariables

Description:
    Defines the initial performance page variables and initializes them.

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

_heli setVariable ["bmkhs_fwdFuelMass",    0.0];
_heli setVariable ["bmkhs_ctrFuelMass",    0.0];
_heli setVariable ["bmkhs_aftFuelMass",    0.0];

_heli setVariable ["bmkhs_stn1FuelMass",   0.0];
_heli setVariable ["bmkhs_stn2FuelMass",   0.0];
_heli setVariable ["bmkhs_stn3FuelMass",   0.0];
_heli setVariable ["bmkhs_stn4FuelMass",   0.0];

_heli setVariable ["bmkhs_totFuelMass",    0.0];
_heli setVariable ["bmkhs_maxTotFuelMass", 0.0];
