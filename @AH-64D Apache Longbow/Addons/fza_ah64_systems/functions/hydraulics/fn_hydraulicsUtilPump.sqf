/* ----------------------------------------------------------------------------
Function: fza_systems_fnc_hydraulicsUtilPump

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

private _utilHydPumpDamage = _heli getHitPointDamage "hit_hyd_utilPump";
private _utilHydPSI_pct    = _heli getVariable "fza_systems_utilHydPSI_pct";
private _utilHydPSI        = _heli getVariable "fza_systems_utilHydPsi";

//The utility reservoir isolates the "extremeties" (pylons, gun, tail rotor) to
//preserve fluid for the lat/long and collective servos. Thus when the reservoir
//level goes to 0, the pressure remains.

if (_utilHydPumpDamage > SYS_HYD_DMG_THRESH) then {
    _utilHydPSI_pct = 0.0;
} else {
    _utilHydPSI_pct = 1.0;
};
_utilHydPSI = _utilHydPSI_pct * 3000.0;

if (_utilHydPSI < SYS_MIN_HYD_PSI) then {
    //CALL WCA here
};

_heli setVariable ["fza_systems_utilHydPSI_pct", _utilHydPSI_pct];
_heli setVariable ["fza_systems_utilHydPsi",     _utilHydPSI];