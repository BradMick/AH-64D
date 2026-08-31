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

//Crossfeed valve -> which main each consumer draws from, as an index into Core's list of
//"main" tanks. Core has no idea what FWD or AFT mean; the AH-64 does.
//  NORM  Eng1 from main 0, Eng2 from main 1
//  FWD   both engines from main 0
//  AFT   both engines from main 1
//The APU always draws main 1, independent of the valve.
private _engSource = switch (_heli getVariable ["bmkhs_crossfeedMode", "NORM"]) do {
    case "FWD": { [0, 0] };
    case "AFT": { [1, 1] };
    default    { [0, 1] };
};
_heli setVariable ["bmkhs_engFuelSource", _engSource];
_heli setVariable ["bmkhs_apuFuelSource", 1];

[_heli] call bmkhs_fnc_coreUpdate;
[_heli] call bmkhs_fnc_coreUpdateFlightModel;
