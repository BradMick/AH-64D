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
#include "\bmkhs_helisim\functions\systems\systems.hpp"

private _utilReservoirDamage = [_heli, "utilReservoir"] call bmkhs_fnc_damageGet;
private _utilHydLevel_pct    = _heli getVariable "bmkhs_utilLevel_pct";
private _curLeakTimer        = 0.0;
private _pylonLeak           = 0.0;
private _leakTimer           = _heli getVariable "bmkhs_hydLeakTimer";
private _gunDamage           = [_heli, "gunTurret"] call bmkhs_fnc_damageGet;

//Pylon damage - however many the aircraft declares, or none at all.
private _numPylons = [_heli, "pylons"] call bmkhs_fnc_damageCount;
for "_i" from 0 to (_numPylons - 1) do {
    if (([_heli, "pylons", _i] call bmkhs_fnc_damageGet) >= SYS_WPN_DMG_THRESH) then {
        _pylonLeak = _pylonLeak + 0.5;
    };
};
private _utilReservoirDamage = _utilReservoirDamage + _pylonLeak + _gunDamage;

//Small leak
if (_utilReservoirDamage > SYS_HYD_RES_MIN_DMG && _utilReservoirDamage <= SYS_HYD_RES_MOD_DMG) then {
    _curLeakTimer = _leakTimer;
};
//Medium leak
if (_utilReservoirDamage > SYS_HYD_RES_MOD_DMG && _utilReservoirDamage <= SYS_HYD_RES_HVY_DMG) then {
    _curLeakTimer = _leakTimer * 0.75;
};
//Large leak
if (_utilReservoirDamage > SYS_HYD_RES_HVY_DMG) then {
    _curLeakTimer = _leakTimer * 0.5;
};
//Leak
if (_utilReservoirDamage > SYS_HYD_RES_MIN_DMG) then {
    _utilHydLevel_pct = [_utilHydLevel_pct, 0.0, (1 / _curLeakTimer) * _deltaTime] call BIS_fnc_lerp;
};

if (_utilHydLevel_pct < (_heli getVariable "bmkhs_hydMinLevel")) then {
    //CALL WCA here
};

_heli setVariable ["bmkhs_utilLevel_pct",  _utilHydLevel_pct];
