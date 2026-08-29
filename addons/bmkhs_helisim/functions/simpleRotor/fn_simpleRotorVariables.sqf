/* ----------------------------------------------------------------------------
Function: bmkhs_fnc_simpleRotorVariables

Description:
    Defines required simple rotor variables and initializes them.

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

_heli setVariable ["bmkhs_reqEngTorque",   [0.0, 0.0]];

_heli setVariable ["bmkhs_vrsVelocityMin", 0.0];
_heli setVariable ["bmkhs_vrsVelocityMax", 0.0];

_heli setVariable ["bmkhs_rtrThrust",      [0.0, 0.0]];
_heli setVariable ["bmkhs_rtrRPM",         0.0];

_heli setVariable ["bmkhs_rtrMoi",         [0.0, 0.0]];
