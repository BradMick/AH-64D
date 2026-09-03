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

//A repair DETECTOR, not a repair action - it watches for damage reading exactly zero and
//restores the state that goes with it. Idempotent, so the slow tick is only to avoid a
//dozen damageGet calls a frame finding nothing. An Arma "Repaired" event handler would be
//better than polling.
if ((diag_tickTime - (missionNamespace getVariable ["bmkhs_repairTicker", 0])) > 2) then {
    missionNamespace setVariable ["bmkhs_repairTicker", diag_tickTime];
    [_heli] call bmkhs_fnc_repair;
};
