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
#include "\fza_ah64_sfmplus\headers\core.hpp"

if (!local _heli) exitWith {};

private _fs0            = 6.4;

private _fwdCg          = 1.117;
private _aftCg          = 0.964;

private _armCPG         = [ 0.000, 4.312];
private _armPLT         = [ 0.000, 2.760];
private _armFwdFuelCell = [ 0.000, 2.542];
private _armAmmoBay     = [ 0.000, 0.944];
private _armAftFuelCell = [ 0.000,-0.077];

private _armStation01   = [-2.160, 1.345];
private _armStation02   = [-1.500, 1.345];
private _armStation03   = [ 1.500, 1.345];
private _armStation04   = [ 2.160, 1.345];

private _curMass   = 0;
private _curMom    = 0;
private _emptyMass = 0;
private _emptyMom  = 0;

if (_heli animationPhase "fcr_enable" == 1) then {
    _emptyMass = _heli getVariable "fza_sfmplus_emptyMassFCR";
    _emptyMom  = (_emptyMass * _fs0) - (_heli getVariable "fza_sfmplus_emptyMomFCR");
} else {
    _emptyMass = _heli getVariable "fza_sfmplus_emptyMassNonFCR";
    _emptyMom  = (_emptyMass * _fs0) - (_heli getVariable "fza_sfmplus_emptyMomNonFCR");
};

private _cpgMass     = 113.4;   //kg - 250lbs
private _cpgMom      = _cpgMass * (_armCPG select 1);

private _pltMass     = 113.4;   //kg - 250lbs
private _pltMom      = _pltMass * (_armPLT select 1);

private _crewMass    = _cpgMass + _pltMass;//(count (fullcrew _heli)) * 113.4; //kg - 250lbs per individual

//Fuel
private _fwdFuelMass  = _heli getVariable "fza_sfmplus_fwdFuelMass";
private _aftFuelMass  = _heli getVariable "fza_sfmplus_aftFuelMass";
private _ctrFuelMass  = _heli getVariable "fza_sfmplus_ctrFuelMass";
private _stn1FuelMass = _heli getVariable "fza_sfmplus_stn1FuelMass";
private _stn2FuelMass = _heli getVariable "fza_sfmplus_stn2FuelMass";
private _stn3FuelMass = _heli getVariable "fza_sfmplus_stn3FuelMass";
private _stn4FuelMass = _heli getVariable "fza_sfmplus_stn4FuelMass";

private _fwdFuelMom   = _fwdFuelMass * (_armFwdFuelCell select 1);
private _ctrFuelMom   = _ctrFuelMass * (_armAmmoBay select 1);
private _aftFuelMom   = _aftFuelMass * (_armAftFuelCell select 1);

private _fuelMass     = _fwdFuelMass + _aftFuelMass;

//1200rd Magazine or Robbie Tank
private _magMass         = [_heli] call fza_sfmplus_fnc_massUpdateMagazine;
private _magMom          = _magMass * (_armAmmoBay select 1);

private _ammoBayMass     = _ctrFuelMass + _magMass;
private _ammoBayMom      = _ctrFuelMom + _magMom;

//Station 1
private _stn1Mass    = [_heli,  0,  1,  4, _stn1FuelMass] call fza_sfmplus_fnc_massUpdateStation;
private _stn1LatMom  = _stn1Mass * (_armStation01 select 0);
private _stn1LongMom = _stn1Mass * (_armStation01 select 1);
//Station 2
private _stn2Mass    = [_heli,  4,  5,  8, _stn2FuelMass] call fza_sfmplus_fnc_massUpdateStation;
private _stn2LatMom  = _stn2Mass * (_armStation02 select 0);
private _stn2LongMom = _stn2Mass * (_armStation02 select 1);
//Station 3
private _stn3Mass    = [_heli,  8,  9, 12, _stn3FuelMass] call fza_sfmplus_fnc_massUpdateStation;
private _stn3LatMom  = _stn3Mass * (_armStation03 select 0);
private _stn3LongMom = _stn3Mass * (_armStation03 select 1);
//Station 4
private _stn4Mass    = [_heli, 12, 13, 16, _stn4FuelMass] call fza_sfmplus_fnc_massUpdateStation;
private _stn4LatMom  = _stn4Mass * (_armStation04 select 0);
private _stn4LongMom = _stn4Mass * (_armStation04 select 1);

private _stnMass     = _stn1Mass + _stn2Mass + _stn3Mass + _stn4Mass;

//Calculate the total current mass of the helicopter
_curMass    = _emptyMass + _crewMass + _fuelMass + _ammoBayMass + _stnMass;
_curLongMom = _emptyMom + _cpgMom + _pltMom + _fwdFuelMom + _ammoBayMom + _aftFuelMom + _stn1LongMom + _stn2LongMom + _stn3LongMom + _stn4LongMom;
_curLongCG  = _curLongMom / _curMass;

_curLatMom  = _stn1LatMom + _stn2LatMom + _stn3LatMom + _stn4LatMom;
_curLatCG   = _curLatMom / _curMass;

//Tuner center of mass offsets (default 0.0 - no change)
private _comOffX = _heli getVariable ["fza_sfmplus_tune_comOffsetX", 0.0];
private _comOffY = _heli getVariable ["fza_sfmplus_tune_comOffsetY", 0.0];
private _comOffZ = _heli getVariable ["fza_sfmplus_tune_comOffsetZ", 0.0];

private _comDatum = boundingCenter _heli;
//systemChat format ["Datum [%1, %2, %3 ]", (_comDatum select 0) toFixed 3, (_comDatum select 1) toFixed 3, (_comDatum select 2) toFixed 3];

//if (fza_ah64_sfmplusRealismSetting == REALISTIC) then {
    _heli setCenterOfMass [
        _curLatCG  + _comOffX - (_comDatum select 0),
        _curLongCG + _comOffY - (_comDatum select 1),
                   + _comOffZ - (_comDatum select 2)
    ];
/*
} else {
    _heli setCenterOfMass [ 0.0 + _comOffX, _curLongCG + _comOffY, -1.34 + _comOffZ];
};
*/
//systemChat format ["Total Mass = %1 lbs (%2 kg) -- Total Moment = %3 -- Long CG = %4 in -- Lat CG = %5 in", (_curMass * 2.20462) toFixed 1, _curMass toFixed 1, _curLongMom toFixed 3, (_curLongCG * 39.3701) toFixed 1, (_curLatCG * 39.3701) toFixed 1];
//systemChat format ["Center of Mass = %1", getCenterOfMass _heli];

private _curCom = (getCenterOfMass _heli) vectorAdd _comDatum;

//_curMass = 4535;//8165;
//Tuner gross weight override - bypasses the computed mass when enabled
if (_heli getVariable ["fza_sfmplus_tune_gwtOverride", false]) then {
    _curMass = _heli getVariable ["fza_sfmplus_tune_gwtValue", _curMass];
};
_heli setMass _curMass;
//systemChat format ["_curMass %1 - _boundingBoxReal = %2 - _boundingCenter = %3", (getMass _heli) toFixed 0, boundingBoxReal [_heli, "Geometry"], boundingCenter _heli];

_heli setVariable ["fza_sfmplus_GWT", _curMass,   true];
_heli setVariable ["fza_sfmplus_CG",  _curLongCG, true];

#ifdef __A3_DEBUG__
private _vecX = [5.0, 0.0, 0.0];
private _vecY = [0.0, 5.0, 0.0];
private _vecZ = [0.0, 0.0, 5.0];

private _heliCoM = getCenterOfMass _heli;

[_heli, _heliCoM, _heliCoM vectorAdd _vecX, "red"]   call fza_fnc_debugDrawLine;
[_heli, _heliCoM, _heliCoM vectorAdd _vecY, "green"] call fza_fnc_debugDrawLine;
[_heli, _heliCoM, _heliCoM vectorAdd _vecZ, "blue"]  call fza_fnc_debugDrawLine;

[_heli, [0.0, _fs0   - (_comDatum select 1),-5], [0.0, _fs0   - (_comDatum select 1), 5], "green"]  call fza_fnc_debugDrawLine;
[_heli, [0.0, _fwdCg - (_comDatum select 1),-5], [0.0, _fwdCg - (_comDatum select 1), 5], "red"]  call fza_fnc_debugDrawLine;
[_heli, [0.0, _aftCg - (_comDatum select 1),-5], [0.0, _aftCg - (_comDatum select 1), 5], "red"]  call fza_fnc_debugDrawLine;

#endif
