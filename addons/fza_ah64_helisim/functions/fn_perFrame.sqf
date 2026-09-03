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

//Systems first - the flight model reads the hydraulic pressure the solve produces.
[_heli] call bmkhs_fnc_systemsUpdate;
[_heli] call bmkhs_fnc_coreUpdate;
[_heli] call bmkhs_fnc_coreUpdateFlightModel;

//Cockpit control visualisation, which reads what the above just published.
[_heli] call bmkhs_fnc_ctrlVisUpdate;

//Restores the state that goes with a repaired component. Exits immediately unless a
//HandleDamage event flagged one, so calling it every frame costs a variable read.
[_heli] call bmkhs_fnc_repair;
