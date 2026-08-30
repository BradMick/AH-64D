/* ----------------------------------------------------------------------------
Function: bmkhs_fnc_drivetrainTransmission

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
#include "\bmkhs_helisim\headers\systems.hpp"

if (!local _heli) exitWith {};

private _eng1PctTQ     = _heli getVariable "bmkhs_engPctTQ" select 0;
private _eng2PctTQ     = _heli getVariable "bmkhs_engPctTQ" select 1;
private _totEngTQ      = _eng1PctTQ + _eng2PctTQ;
private _xmsnHitPtDmg  = _heli getHitPointDamage "hit_drives_transmission";
private _dmgTimerCont  = _heli getVariable "bmkhs_dmgTimerCont";
private _dmgTimerTrans = _heli getVariable "bmkhs_dmgTimerTrans";
private _randomTq1     = _heli getVariable "bmkhs_randomTq" select 2;
private _randomTq2     = _heli getVariable "bmkhs_randomTq" select 3;
private _applyDamage   = false;

private _persistentDmg    = 0.0;
private _dynamicDmgStage1 = 0.0;
private _dynamicDmgStage2 = 0.0;
private _dynamicDmgStage3 = 0.0;

if (isEngineOn _heli) then {
    if (_totEngTQ <= 2.0) then {
        _dmgTimerTrans = 0;
        _heli setVariable ["bmkhs_dmgTimerTrans", _dmgTimerTrans];
    };
    //6 sec transient
        if (_totEngTQ > 2.0 && _totEngTQ <= 2.30) then {
        _dmgTimerTrans = _dmgTimerTrans + _deltaTime;

        if (_dmgTimerTrans >= 6) then {
            _dmgTimerTrans = 6;
            _applyDamage = true;
        };

        _heli setVariable ["bmkhs_dmgTimerTrans", _dmgTimerTrans];
    };
    if (_totEngTQ > 2.30) then {
        _applyDamage = true;
    };
};

if (_applyDamage) then {
    //--Dynamic damage
    if (_totEngTQ > 2.00) then {
        _dynamicDmgStage1 = (_totEngTQ - 2.00) / 10.0;
    };
    if (_totEngTQ > 2.30) then {
        _dynamicDmgStage2 = (_totEngTQ - 2.30) / 20.0;
    };
};
//--Persistent damage
if (_xmsnHitPtDmg > 0.25) then {
    _persistentDmg = _xmsnHitPtDmg / 600.0;
    _randomTq1     = _xmsnHitPtDmg * random[-0.10, 0, 0.10];
    _randomTq2     = _xmsnHitPtDmg * random[-0.10, 0, 0.10];
};
if (_xmsnHitPtDmg > 0.50) then {
    _persistentDmg = _xmsnHitPtDmg / 500.0;
};
if (_xmsnHitPtDmg > 0.75) then {
    _persistentDmg = _xmsnHitPtDmg / 400.0;
};

private _dmgPerSec = (_persistentDmg + _dynamicDmgStage1 + _dynamicDmgStage2) * _deltaTime;
private _dmg       = _xmsnHitPtDmg + _dmgPerSec;

_heli setHitPointDamage ["hit_drives_transmission", _dmg];

[_heli, "bmkhs_randomTq", 2, _randomTq1, false] call bmkhs_fnc_setArrayVariable;
[_heli, "bmkhs_randomTq", 3, _randomTq2, false] call bmkhs_fnc_setArrayVariable;

if (_xmsnHitPtDmg == 1.0) then {
    _heli setHitPointDamage ["hithrotor",           1.0];
    _heli setHitPointDamage ["hitvrotor",           1.0];
    _heli setHitPointDamage ["hit_elec_generator1", 1.0];
    _heli setHitPointDamage ["hit_elec_generator2", 1.0];
    _heli setHitPointDamage ["hit_hyd_priPump",     1.0];
    _heli setHitPointDamage ["hit_hyd_utilPump",    1.0];
};

//systemChat format ["%1 -- %2 -- %3 -- %4 -- %5 -- %6", _totEngTQ, _persistentDmg, _dynamicDmgStage1, _dynamicDmgStage2, _xmsnHitPtDmg, _dmgTimerTrans];
