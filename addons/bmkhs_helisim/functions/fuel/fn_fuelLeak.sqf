/* ----------------------------------------------------------------------------
Function: bmkhs_fnc_fuelLeak

Description:
    Drains damaged tanks. Each tank names its own leak hitpoint; the rate ramps
    linearly from the damage onset threshold to the maximum at full damage.

    Mutates _fuelMass in place.

Parameters:
    _heli      - The helicopter [Object]
    _fuelMass  - Per-tank masses, mutated [Array]
    _fuelTanks - Fuel tank table [Array]
    _deltaTime - Frame time [Number]

Returns:
    Nothing

Author:
    BradMick / FZA Development Team
---------------------------------------------------------------------------- */
#include "\bmkhs_helisim\functions\fuel\fuel.hpp"
params ["_heli", "_fuelMass", "_fuelTanks", "_deltaTime"];

{
    _x params ["", "", "", "_removable", "", "_leakPoint", "_varName"];
    private _idx = _forEachIndex;
    private _m   = _fuelMass param [_idx, 0];

    if (_leakPoint == "" || _m <= 0) then { continue };

    private _fitted = !_removable || {_heli getVariable [_varName + "Installed", false]};
    if (!_fitted) then { continue };

    private _dmg = (_heli getHitPointDamage _leakPoint) max 0;
    if (_dmg > TANK_LEAK_START_DMG) then {
        private _frac = ((_dmg - TANK_LEAK_START_DMG) / (1 - TANK_LEAK_START_DMG)) min 1;
        _fuelMass set [_idx, _m - ((TANK_LEAK_MAX_RATE_KGS * _frac * _deltaTime) min _m)];
    };
} forEach _fuelTanks;
