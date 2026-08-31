#include "\bmkhs_helisim\functions\core\core.hpp"
#include "\bmkhs_helisim\functions\fuel\fuel.hpp"
params ["_heli"];

private _fwdCellWeight       = _heli getVariable "bmkhs_fuelTank1Mass";
private _ctrFuelWeight       = _heli getVariable "bmkhs_fuelTank2Mass";
private _aftCellWeight       = _heli getVariable "bmkhs_fuelTank3Mass";

private _stn1FuelWeight      = _heli getVariable "bmkhs_auxTank1Mass";
private _stn2FuelWeight      = _heli getVariable "bmkhs_auxTank2Mass";
private _stn3FuelWeight      = _heli getVariable "bmkhs_auxTank3Mass";
private _stn4FuelWeight      = _heli getVariable "bmkhs_auxTank4Mass";

private _mainFuelCellWeight  = _fwdCellWeight + _aftCellWeight;
private _totalFuelCellWeight = _fwdCellWeight + _ctrFuelWeight + _aftCellWeight + _stn1FuelWeight + _stn2FuelWeight + _stn3FuelWeight + _stn4FuelWeight;
_fwdCellWeight       = _fwdCellWeight * KG_TO_LBS;
_ctrFuelWeight       = _ctrFuelWeight * KG_TO_LBS;
_aftCellWeight       = _aftCellWeight * KG_TO_LBS;
_mainFuelCellWeight  = _mainFuelCellWeight * KG_TO_LBS;
_totalFuelCellWeight = _totalFuelCellWeight * KG_TO_LBS;

//bmkhs_engFF is kg/s straight off the engine's engFFTable, so the display conversion is
//seconds-to-hours then kg-to-lbs. It is NOT a 0-1 fraction of some rated flow.
#define KGS_TO_LBS_PER_HOUR (3600 * KG_TO_LBS)

private _eng1FF = _heli getVariable "bmkhs_engFF" select 0;
private _eng2FF = _heli getVariable "bmkhs_engFF" select 1;

private _eng1FuelCons = 0;
private _eng1State    = _heli getVariable "bmkhs_engState" select 0;
if (_eng1State == "ON") then {
    _eng1FuelCons = _eng1FF * KGS_TO_LBS_PER_HOUR;
} else {
    _eng1FuelCons = 0;
};

private _eng2FuelCons = 0;
private _eng2State    = _heli getVariable "bmkhs_engState" select 1;
if (_eng2State == "ON") then {
    _eng2FuelCons = _eng2FF * KGS_TO_LBS_PER_HOUR;
} else {
    _eng2FuelCons = 0;
};
//private _totalFuelConsumption  = _engineFuelConsumption # 0 + _engineFuelConsumption # 1;
private _totalFuelConsumption = _eng1FuelCons + _eng2FuelCons;

private _mainEnduranceNumber = if(_totalFuelConsumption > 0) then {
    private _enduranceTotal = 599 min (_mainFuelCellWeight / _totalFuelConsumption * 60); //Minutes
    private _enduranceMinutes = _enduranceTotal % 60;
    private _enduranceHours = floor(_enduranceTotal / 60);
    format["%1:%2", _enduranceHours toFixed 0, [_enduranceMinutes, 2] call CBA_fnc_formatNumber];
} else {"9:99"};

private _totalEnduranceNumber = if(_totalFuelConsumption > 0) then {
    private _enduranceTotal = 599 min (_totalFuelCellWeight / _totalFuelConsumption * 60); //Minutes
    private _enduranceMinutes = _enduranceTotal % 60;
    private _enduranceHours = floor(_enduranceTotal / 60);
    format["%1:%2", _enduranceHours toFixed 0, [_enduranceMinutes, 2] call CBA_fnc_formatNumber];
} else {"9:99"};

// Specific Fuel Range (nm per lb): airspeed (kts) / fuel flow (lb/hr)
// Shown blank when groundspeed < 10 kts or no fuel flow
private _sfrText = "";
private _groundspeedKts = _heli getVariable ["bmkhs_gndSpeed", 0];
if (_groundspeedKts >= 10 && _totalFuelConsumption > 0) then {
    private _sfr = (_groundspeedKts / _totalFuelConsumption) toFixed 2;
    _sfrText = if (_sfr select [0, 2] == "0.") then { _sfr select [1] } else { _sfr };
};

[_fwdCellWeight, _ctrFuelWeight, _aftCellWeight, _mainFuelCellWeight, _totalFuelCellWeight, _eng1FuelCons, _eng2FuelCons, _totalFuelConsumption, _mainEnduranceNumber, _totalEnduranceNumber, _sfrText]
