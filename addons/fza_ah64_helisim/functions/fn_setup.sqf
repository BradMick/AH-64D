/* ----------------------------------------------------------------------------
Function: fza_ah64_helisim_fnc_setup

Description:
    Initialises HeliSim Core for the AH-64 and hands it this aircraft's
    configuration. Called once per aircraft at init.

Parameters:
    _heli - The helicopter [Object]

Returns:
    Nothing
---------------------------------------------------------------------------- */
params ["_heli"];

[_heli] call bmkhs_fnc_init;
[_heli, configOf _heli >> "BMKHS_HeliSim"] call bmkhs_fnc_coreConfig;
