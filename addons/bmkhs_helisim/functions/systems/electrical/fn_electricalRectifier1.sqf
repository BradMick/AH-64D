/* ----------------------------------------------------------------------------
Function: bmkhs_fnc_electricalRectifier1

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

private _gen1On      = _heli getVariable "bmkhs_gen1On";

private _rect1On     = _heli getVariable "bmkhs_rect1On";
private _rect1Damage = [_heli, "rectifiers", 0] call bmkhs_fnc_damageGet;

//Set RTRU 1 state
if (_gen1On && _rect1Damage <= SYS_RECT_DMG_THRESH) then {
    _rect1On = true;
} else {
    _rect1On = false;
};
_heli setVariable ["bmkhs_rect1On", _rect1On];
