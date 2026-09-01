/* ----------------------------------------------------------------------------
Function: bmkhs_fnc_drivetrainTailRotorGearboxes

Description:
    ...

Parameters:
    _heli      - The helicopter to get information from [Unit].

Returns:
    ...

Examples:
    ...

Author:
    BradMick
---------------------------------------------------------------------------- */
params ["_heli"];
#include "\bmkhs_helisim\functions\systems\systems.hpp"

private _IGBDamage  = [_heli, "intermediateGearbox"] call bmkhs_fnc_damageGet;
private _TGBDamage  = [_heli, "tailRotorGearbox"] call bmkhs_fnc_damageGet;

if (_IGBDamage >= SYS_IGB_DMG_THRESH || _TGBDamage >= SYS_TGB_DMG_THRESH) then {
    [_heli, "tailRotor", 1.0] call bmkhs_fnc_damageSet;
};
