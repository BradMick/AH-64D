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

//AH-64 equipment - not flight model state, so it lives here rather than in Core.
//Must be set before coreConfig: that calls bmkhs_fnc_fuelSet, which reads
//IAFSInstalled with no default to decide the tank split.
if (local _heli) then {
    _heli setVariable ["bmkhs_fuelTank2Installed", true,  true];
    _heli setVariable ["bmkhs_fuelTank2XferOn",    false, true];
};

[_heli] call bmkhs_fnc_coreInit;
[_heli, configOf _heli >> "BMKHS_HeliSim"] call bmkhs_fnc_coreConfig;
