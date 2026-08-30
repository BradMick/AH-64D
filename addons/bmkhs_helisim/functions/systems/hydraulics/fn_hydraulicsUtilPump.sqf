/* ----------------------------------------------------------------------------
Function: bmkhs_fnc_hydraulicsUtilPump

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
#include "\bmkhs_helisim\headers\systems.hpp"

private _utilHydPumpDamage = _heli getHitPointDamage "hit_hyd_utilPump";
private _utilHydPSI_pct    = _heli getVariable "bmkhs_utilHydPSI_pct";
private _utilHydPSI        = _heli getVariable "bmkhs_utilHydPsi";

if (_utilHydPumpDamage > SYS_HYD_DMG_THRESH) then {
    _utilHydPSI_pct = 0.0;
} else {
    _utilHydPSI_pct = 1.0;
};
_utilHydPSI = _utilHydPSI_pct * 3000.0;

if (_utilHydPSI < (_heli getVariable "bmkhs_hydMinPsi")) then {
    //CALL WCA here
};

_heli setVariable ["bmkhs_utilHydPSI_pct", _utilHydPSI_pct];
_heli setVariable ["bmkhs_utilHydPsi",     _utilHydPSI];
