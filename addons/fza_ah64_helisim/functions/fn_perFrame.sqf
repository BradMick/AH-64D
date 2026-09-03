/* ----------------------------------------------------------------------------
Function: fza_ah64_helisim_fnc_perFrame

Description:
    Per-frame tick. The pack owns the schedule; Core only crunches numbers.

Parameters:
    _heli - The helicopter [Object]

Returns:
    Nothing
---------------------------------------------------------------------------- */
params ["_heli"];

[_heli] call bmkhs_fnc_systemsUpdate;
[_heli] call bmkhs_fnc_coreUpdate;
[_heli] call bmkhs_fnc_coreUpdateFlightModel;
