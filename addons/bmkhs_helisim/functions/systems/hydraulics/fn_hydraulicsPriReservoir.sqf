/* ----------------------------------------------------------------------------
Function: bmkhs_fnc_hydraulicsPriReservoir

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

private _priReservoirDamage = _heli getHitPointDamage "hit_hyd_priReservoir";
private _priHydLevel_pct    = _heli getVariable "bmkhs_priLevel_pct";
private _curLeakTimer       = 0.0;
private _leakTimer          = _heli getVariable "bmkhs_hydLeakTimer";

//Small leak
if (_priReservoirDamage > (_heli getVariable "bmkhs_hydResMinDmg") && _priReservoirDamage <= (_heli getVariable "bmkhs_hydResModDmg")) then {
    _curLeakTimer = _leakTimer;
};
//Medium leak
if (_priReservoirDamage > (_heli getVariable "bmkhs_hydResModDmg") && _priReservoirDamage <= (_heli getVariable "bmkhs_hydResHvyDmg")) then {
    _curLeakTimer = _leakTimer * 0.75;
};
//Large leak
if (_priReservoirDamage > (_heli getVariable "bmkhs_hydResHvyDmg")) then {
    _curLeakTimer = _leakTimer * 0.5;
};
//Leak
if (_priReservoirDamage > (_heli getVariable "bmkhs_hydResMinDmg")) then {
    _priHydLevel_pct = [_priHydLevel_pct, 0.0, (1 / _curLeakTimer) * _deltaTime] call BIS_fnc_lerp;
};

if (_priHydLevel_pct < (_heli getVariable "bmkhs_hydMinLevel")) then {
    //CALL WCA here
};

_heli setVariable ["bmkhs_priLevel_pct",  _priHydLevel_pct];
