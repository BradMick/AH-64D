/* ----------------------------------------------------------------------------
Function: bmkhs_fnc_systemsAPU

Description:
    Defines key values for the simulation.

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

private _apuBtnOn      = _heli getVariable "bmkhs_apuBtnOn";
private _battBusOn     = _heli getVariable "bmkhs_battBusOn";
private _apuOn         = _heli getVariable "bmkhs_apuOn";
private _apuDamage     = [_heli, "apu"] call bmkhs_fnc_damageGet;
private _apuStartDelay = _heli getVariable "bmkhs_apuStartDelay";
private _apuRPM_pct    = _heli getVariable "bmkhs_apuRPM_pct";
private _apuFF_kgs     = 0.0;
private _apuFuelAvail  = _heli getVariable ["bmkhs_apuFuelAvail", true];

if (_apuBtnOn && _battBusOn && _apuFuelAvail) then {
    _apuRPM_pct = [_apuRPM_pct, 1.0, (1.0 / _apuStartDelay) * _deltaTime] call BIS_fnc_lerp;
} else {
    _apuRPM_pct = [_apuRPM_pct, 0.0, _deltaTime] call BIS_fnc_lerp;
};
_heli setVariable ["bmkhs_apuRPM_pct", _apuRPM_pct];

//Set the APU state
if (_apuRPM_pct <= SYS_MIN_RPM) then {
    _apuOn = false;
};
if (_apuRPM_pct > SYS_MIN_RPM) then {
    if (_apuDamage <= SYS_APU_DMG_THRESH) then {
        _apuOn = true;
    } else {
        _apuOn = false;
    };
};
_heli setVariable ["bmkhs_apuOn", _apuOn];
//Cockpit indication is the aircraft's business - Core only reports the state
[_heli, "apuStateChanged"] call bmkhs_fnc_utilNotify;

if (_apuOn) then {
    _apuFF_kgs = 0.0220;//175pph
};
_heli setVariable ["bmkhs_apuFF_kgs", _apuFF_kgs];
