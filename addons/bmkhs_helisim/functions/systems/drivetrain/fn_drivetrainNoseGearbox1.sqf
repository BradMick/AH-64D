/* ----------------------------------------------------------------------------
Function: bmkhs_fnc_drivetrainNoseGearbox1

Description:
    Updates all of the modules core functions.

Parameters:
    _heli - The helicopter to get information from [Unit].

Returns:
    ...

Examples:
    ...

Author:
    BradMick
---------------------------------------------------------------------------- */
params ["_heli", "_deltaTime"];
#include "\bmkhs_helisim\functions\systems\systems.hpp"

private _engPctTq         = _heli getVariable "bmkhs_engPctTQ" select 0;
private _isSingleEng      = _heli getVariable "bmkhs_isSingleEng";
private _grbxHitPtDmg     = [_heli, "noseGearboxes", 0] call bmkhs_fnc_damageGet;
private _dmgTimerCont     = _heli getVariable "bmkhs_dmgTimerCont";
private _dmgTimerTrans    = _heli getVariable "bmkhs_dmgTimerTrans";
private _randomTq         = _heli getVariable "bmkhs_randomTq" select 0;
private _applyDamage      = false;
private _engOverspeed     = false;

private _contTqLimit      = _heli getVariable "bmkhs_ngbContTqLimit";
private _contTimerLimit   = _heli getVariable "bmkhs_ngbContTimer";
private _transTqLimit     = _heli getVariable "bmkhs_ngbTransTqLimit";
private _transTimerLimit  = _heli getVariable "bmkhs_ngbTransTimer";
private _maxTqLimit       = _heli getVariable "bmkhs_ngbMaxTqLimit";

private _persistentDmg    = 0.0;
private _dynamicDmgStage1 = 0.0;
private _dynamicDmgStage2 = 0.0;
private _dynamicDmgStage3 = 0.0;

if (isEngineOn _heli) then {
    if (_isSingleEng) then {
        if (_engPctTQ <= _contTqLimit) then {
            _dmgTimerCont  = 0;
            _dmgTimerTrans = 0;
            _heli setVariable ["bmkhs_dmgTimerCont",  _dmgTimerCont];
            _heli setVariable ["bmkhs_dmgTimerTrans", _dmgTimerTrans];
        };
        //2.5 min SE contingency
        if (_engPctTQ > _contTqLimit && _engPctTQ <= _transTqLimit) then {
            _dmgTimerCont = _dmgTimerCont + _deltaTime;

            if (_dmgTimerCont >= _contTimerLimit) then {    //2.5 minutes = 150 sec
                _dmgTimerCont = _contTimerLimit;
                _applyDamage = true;
            };
            _heli setVariable ["bmkhs_dmgTimerCont", _dmgTimerCont];
        } else {
            _dmgTimerCont  = 0;
            _heli setVariable ["bmkhs_dmgTimerCont", _dmgTimerCont];
        };
        //6 sec transient
        if (_engPctTQ > _transTqLimit && _engPctTQ <= _maxTqLimit) then {
            _dmgTimerTrans = _dmgTimerTrans + _deltaTime;
            if (_dmgTimerTrans >= _transTimerLimit) then {
                _dmgTimerTrans = _transTimerLimit;
                _applyDamage = true;
            };
            _heli setVariable ["bmkhs_dmgTimerTrans", _dmgTimerTrans];
        } else {
            _dmgTimerTrans  = 0;
            _heli setVariable ["bmkhs_dmgTimerTrans", _dmgTimerTrans];
        };
        if (_engPctTQ > _maxTqLimit) then {
            _applyDamage = true;
        };
    };
};

if (_isSingleEng) then {
    if (_applyDamage) then {
        //--Dynamic damage
        if (_engPctTq > _contTqLimit) then {
            _dynamicDmgStage1 = (_engPctTq - _contTqLimit) / 10.0;
        };
        if (_engPctTq > _transTqLimit) then {
            _dynamicDmgStage2 = (_engPctTq - _transTqLimit) / 20.0;
        };
        if (_engPctTq > _maxTqLimit) then {
            _dynamicDmgStage3 = (_engPctTq - _maxTqLimit) / 40.0;
        };
    };
};
//--Persistent damage
if (_grbxHitPtDmg > 0.25) then {
    _persistentDmg = _grbxHitPtDmg / 600.0;
    _randomTq      = _grbxHitPtDmg * random[-0.10, 0, 0.10];
};
if (_grbxHitPtDmg > 0.50) then {
    _persistentDmg = _grbxHitPtDmg / 500.0;
};
if (_grbxHitPtDmg > 0.75) then {
    _persistentDmg = _grbxHitPtDmg / 400.0;
};

private _dmgPerSec = (_persistentDmg + _dynamicDmgStage1 + _dynamicDmgStage2 + _dynamicDmgStage3) * _deltaTime;
private _grbxDmg   = _grbxHitPtDmg + _dmgPerSec;

[_heli, "noseGearboxes", _grbxDmg, 0] call bmkhs_fnc_damageSet;

[_heli, "bmkhs_randomTq", 0, _randomTq, true] call bmkhs_fnc_utilSetArrayVariable;

if (_grbxHitPtDmg == 1.0) then {
    _engOverspeed = true;
    [_heli, "bmkhs_engineOverspeed", 0, _engOverspeed, false] call bmkhs_fnc_utilSetArrayVariable;
};
