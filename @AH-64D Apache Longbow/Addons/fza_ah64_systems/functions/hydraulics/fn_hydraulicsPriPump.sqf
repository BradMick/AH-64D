/* ----------------------------------------------------------------------------
Function: fza_systems_fnc_hydraulicsPriPump

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
#include "\fza_ah64_systems\headers\systems.hpp"

private _priHydPumpDamage = _heli getHitPointDamage "hit_hyd_priPump";
private _priHydPSI_pct    = _heli getVariable "fza_systems_priHydPSI_pct";
private _priHydPSI        = _heli getVariable "fza_systems_priHydPsi";
//Reservoir level
private _priHydLevel_pct  = _heli getVariable "fza_systems_priLevel_pct";

if (_priHydPumpDamage > SYS_HYD_DMG_THRESH || _priHydLevel_pct < SYS_HYD_MIN_LVL) then {
    _priHydPSI_pct = 0.0;
} else {
    if (_priHydLevel_pct < (SYS_HYD_MIN_LVL + 0.10)) then {
        _priHydPSI_pct = linearConversion[0.20, 0.1, _priHydLevel_pct, 1.0, (1250 / 3000), true];
    }
    else {
        _priHydPSI_pct = 1.0;
    };
};
_priHydPSI  = _priHydPSI_pct  * 3000.0;

if (_priHydPSI < SYS_MIN_HYD_PSI) then {
    //CALL WCA here
};

_heli setVariable ["fza_systems_priHydPSI_pct",  _priHydPSI_pct];
_heli setVariable ["fza_systems_priHydPsi",      _priHydPSI];