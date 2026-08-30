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

//AH-64 equipment - not flight model state, so it lives here rather than in Core
if (local _heli) then {
    _heli setVariable ["fza_ah64_IAFSInstalled", true,  true];
    _heli setVariable ["fza_ah64_IAFSOn",        false, true];
};
