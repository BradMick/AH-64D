/* ----------------------------------------------------------------------------
Function: bmkhs_fnc_repair

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
params ["_heli"];

if (_heli getHitPointDamage "hitengine1" == 0) then {
    [_heli, "bmkhs_engineOverspeed", 0.0, false, true] call bmkhs_fnc_setArrayVariable;
    _heli setHitPointDamage ["hitengine1", 0.000001, false]
};
if (_heli getHitPointDamage "hitengine2" == 0) then {
    [_heli, "bmkhs_engineOverspeed", 1.0, false, true] call bmkhs_fnc_setArrayVariable;
    _heli setHitPointDamage ["hitengine2", 0.000001, false]
};
if (_heli getHitPointDamage "hit_elec_battery" == 0) then {
    _heli setVariable ["bmkhs_battPower_pct", 1.0, true];
    _heli setHitPointDamage ["hit_elec_battery", 0.000001, false]
};
if (_heli getHitPointDamage "hit_hyd_prireservoir" == 0) then {
    _heli setVariable ["bmkhs_priLevel_pct", 1.0, true];
    _heli setHitPointDamage ["hit_hyd_prireservoir", 0.000001, false]
};
if (_heli getHitPointDamage "hit_hyd_priPump" == 0) then {
    _heli setVariable ["bmkhs_priHydPSI_pct", 1.0, true];
    _heli setHitPointDamage ["hit_hyd_priPump", 0.000001, false]
};
if (_heli getHitPointDamage "hit_hyd_utilreservoir" == 0) then {
    _heli setVariable ["bmkhs_utilLevel_pct", 1.0, true];
    _heli setVariable ["bmkhs_accHydPSI_pct", 1.0, true];
    _heli setHitPointDamage ["hit_hyd_utilreservoir", 0.000001, false]
};
if (_heli getHitPointDamage "hit_hyd_utilPump" == 0) then {
    _heli setVariable ["bmkhs_utilHydPSI_pct", 1.0, true];
    _heli setHitPointDamage ["hit_hyd_utilPump", 0.000001, false]
};
