/* ----------------------------------------------------------------------------
Function: bmkhs_fnc_hydraulicsPriPump

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
#include "\bmkhs_helisim\functions\systems\systems.hpp"

private _priHydPumpDamage = _heli getHitPointDamage "hit_hyd_priPump";
private _priHydPSI_pct    = _heli getVariable "bmkhs_priHydPSI_pct";
private _priHydPSI        = _heli getVariable "bmkhs_priHydPsi";

if (_priHydPumpDamage > SYS_HYD_DMG_THRESH) then {
    _priHydPSI_pct = 0.0;
} else {
    _priHydPSI_pct = 1.0;
};
_priHydPSI  = _priHydPSI_pct  * 3000.0;

if (_priHydPSI < (_heli getVariable "bmkhs_hydMinPsi")) then {
    //CALL WCA here
};

_heli setVariable ["bmkhs_priHydPSI_pct",  _priHydPSI_pct];
_heli setVariable ["bmkhs_priHydPsi",      _priHydPSI];
