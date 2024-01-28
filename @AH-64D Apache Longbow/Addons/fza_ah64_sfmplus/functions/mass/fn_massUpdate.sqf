/* ----------------------------------------------------------------------------
Function: fza_sfmplus_fnc_massUpdate

Description:
    Updates the mass and moment of a wing station

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

private _armCPG         = [ 0.00, 2.09];
private _armPLT         = [ 0.00, 3.64];
private _armFwdFuelCell = [ 0.00, 3.51];
private _armAmmoBay     = [ 0.00, 5.32];
private _armAftFuelCell = [ 0.00, 6.79];

private _armStation01   = [-2.16, 4.72];
private _armStation02   = [-1.50, 4.72];
private _armStation03   = [ 1.50, 4.72];
private _armStation04   = [ 2.16, 4.72];

private _curMass   = 0;
private _curMom    = 0;
private _emptyMass = 0;
private _emptyMom  = 0;

if (_heli animationPhase "fcr_enable" == 1) then {
    _emptyMass = _heli getVariable "fza_sfmplus_emptyMassFCR";
    _emptyMom  = _heli getVariable "fza_sfmplus_emptyMomFCR";
} else {
    _emptyMass = _heli getVariable "fza_sfmplus_emptyMassNonFCR";
    _emptyMom  = _heli getVariable "fza_sfmplus_emptyMomNonFCR";
};

//Crew
private _cpgMass     = 113.4;   //kg - 250lbs
private _cpgMom      = _cpgMass * (_armCPG select 1);

private _pltMass     = 113.4;   //kg - 250lbs
private _pltMom      = _pltMass * (_armPLT select 1);

private _crewMass    = (count (fullcrew _heli)) * 113.4; //kg - 250lbs per individual

//Fwd and Aft Fuel Cells
private _fwdFuelMass = [_heli] call fza_sfmplus_fnc_fuelSet select 0;
private _fwdFuelMom  = _fwdFuelMass * (_armFwdFuelCell select 1);

private _ctrFuelMass = [_heli] call fza_sfmplus_fnc_fuelSet select 1;
private _ctrFuelMom  = _ctrFuelMass * (_armAmmoBay select 1);

private _aftFuelMass = [_heli] call fza_sfmplus_fnc_fuelSet select 2;
private _aftFuelMom  = _aftFuelMass * (_armAftFuelCell select 1);

private _fuelMass    = _fwdFuelMass + _ctrFuelMass + _aftFuelMass;

systemChat format ["Fuel Mass = %1 -- Fwd = %2 -- Ctr = %3 -- Aft = %3", _fuelMass, _fwdFuelMass, _ctrFuelMass, _aftFuelMass];

//1200rd Magazine or Robbie Tank
private _magMass         = [_heli] call fza_sfmplus_fnc_massUpdateMagazine;
private _magMom          = _magMass * (_armAmmoBay select 1);

//Station 1
private _station1Mass    = [_heli,  0,  1,  4] call fza_sfmplus_fnc_massUpdateStation;
private _station1LatMom  = _station1Mass * (_armStation01 select 0);
private _station1LongMom = _station1Mass * (_armStation01 select 1);
//Station 2
private _station2Mass    = [_heli,  4,  5,  8] call fza_sfmplus_fnc_massUpdateStation;
private _station2LatMom  = _station2Mass * (_armStation02 select 0);
private _station2LongMom = _station1Mass * (_armStation02 select 1);
//Station 3
private _station3Mass    = [_heli,  8,  9, 12] call fza_sfmplus_fnc_massUpdateStation;
private _station3LatMom  = _station3Mass * (_armStation03 select 0);
private _station3LongMom = _station3Mass * (_armStation03 select 1);
//Station 4
private _station4Mass    = [_heli, 12, 13, 16] call fza_sfmplus_fnc_massUpdateStation;
private _station4LatMom  = _station4Mass * (_armStation04 select 0);
private _station4LongMom = _station4Mass * (_armStation04 select 1);

private _stationMass     = _station1Mass + _station2Mass + _station3Mass + _station4Mass;

//Calculate the total current mass of the helicopter
_curMass    = _emptyMass + _crewMass + _fuelMass + _magMass + _stationMass;
_curLongMom = _emptyMom + _cpgMom + _pltMom + _fwdFuelMom + _ctrFuelMom + _aftFuelMom + _magMom + _station1LongMom + _station2LongMom + _station3LongMom + _station4LongMom;
_curLongCG  = _curLongMom / _curMass;

_curLatMom  = _station1LatMom + _station2LatMom + _station3LatMom + _station4LatMom;
_curLatCG   = _curLatMom / _curMass;

_heli setCenterOfMass [_curLatCG, 6.4 - _curLongCG, 0.0];

systemChat format ["Total Mass = %1 lbs (%2 kg) -- Total Moment = %3 -- Long CG = %4 -- Lat CG = %5", (_curMass * 2.20462) toFixed 1, _curMass toFixed 1, _curLongMom toFixed 3, _curLongCG toFixed 3, _curLatCG toFixed 3];

if (local _heli) then {
    _heli setMass _curMass;
};
_heli setVariable ["fza_sfmplus_GWT", _curMass];
