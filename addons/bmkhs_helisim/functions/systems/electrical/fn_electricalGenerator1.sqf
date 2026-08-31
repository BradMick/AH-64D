/* ----------------------------------------------------------------------------
Function: bmkhs_fnc_electricalGenerator1

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
params ["_heli", "_apuOn", "_rtrRPM"];
#include "\bmkhs_helisim\functions\systems\systems.hpp"

private _gen1On     = _heli getVariable "bmkhs_gen1On";
private _gen1Damage = _heli getHitPointDamage "hit_elec_generator1";

if (_apuOn || _rtrRPM > SYS_MIN_RPM) then {
    //Generator 1
    if (_gen1Damage <= SYS_GEN_DMG_THRESH) then {
        _gen1On = true;
    } else {
        _gen1On = false;
    };
} else {
    _gen1On = false;
};
_heli setVariable ["bmkhs_gen1On", _gen1On];
