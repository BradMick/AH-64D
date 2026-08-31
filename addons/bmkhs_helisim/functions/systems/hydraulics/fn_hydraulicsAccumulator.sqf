/* ----------------------------------------------------------------------------
Function: bmkhs_fnc_hydraulicsAccumulator

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

private _priHydPSI     = _heli getVariable "bmkhs_priHydPsi";
private _utilHydPSI    = _heli getVariable "bmkhs_utilHydPsi";

private _accHydPSI_pct = _heli getVariable "bmkhs_accHydPSI_pct";
private _accHydPSI     = _heli getVariable "bmkhs_accHydPsi";
private _emerHydOn     = _heli getVariable "bmkhs_emerHydOn";
private _accTimer      = _heli getVariable "bmkhs_accTimer";

if (_priHydPSI < (_heli getVariable "bmkhs_hydMinPsi") && _utilHydPSI < (_heli getVariable "bmkhs_hydMinPsi")) then {
    if (_emerHydOn) then {
        _accHydPSI_pct = [_accHydPSI_pct, 0.0, (1 / _accTimer) * _deltaTime] call BIS_fnc_lerp;
    };
};
_accHydPSI = _accHydPSI_pct  * 3000.0;

if (_accHydPSI < (_heli getVariable "bmkhs_hydMinAccPsi")) then {
    _emerHydOn         = false;
    _accHydPSI_pct = 0.0;
};

_heli setVariable ["bmkhs_accHydPSI_pct",  _accHydPSI_pct];
_heli setVariable ["bmkhs_accHydPsi",      _accHydPSI];
_heli setVariable ["bmkhs_emerHydOn",          _emerHydOn];
