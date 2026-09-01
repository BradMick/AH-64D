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

private _IGBDamage  = _heli getHitPointDamage "hit_drives_intermediateGearbox";
private _TGBDamage  = _heli getHitPointDamage "hit_drives_tailRotorGearbox";

if (_IGBDamage >= SYS_IGB_DMG_THRESH || _TGBDamage >= SYS_TGB_DMG_THRESH) then {
    _heli setHitPointDamage ["hitvrotor", 1.0];
};
