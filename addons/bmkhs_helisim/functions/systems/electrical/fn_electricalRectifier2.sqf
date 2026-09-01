/* ----------------------------------------------------------------------------
Function: bmkhs_fnc_electricalRectifier2

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

private _gen2On      = _heli getVariable "bmkhs_gen2On";

private _rect2On     = _heli getVariable "bmkhs_rect2On";
private _rect2Damage = [_heli, "rectifiers", 1] call bmkhs_fnc_damageGet;

//Set RTRU 2 state
if (_gen2On && _rect2Damage <= SYS_RECT_DMG_THRESH) then {
    _rect2On = true;
} else {
    _rect2On = false;
};
_heli setVariable ["bmkhs_rect2On", _rect2On];
