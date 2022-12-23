params ["_heli", "_mu", "_lambda", "_theta0_deg", "_rotorParams", "_gamma"];
#include "\bmk_helisim\headers\core.hpp"

_rotorParams 
    params ["_a", "_type", "_b", "_h", "_R", "_c", "_theta1_deg", "_m", "_eR", "_e", "_gearRatio", "_thrustScalar", "_Ib", "_s", "_polarMOI", "_inputMaps"];

private _a0_deg = 0.0; private _a0_1 = 0.0; private _a0_2 = 0.0; private _a0_3 = 0.0;

_a0_1 = (1.0 / 6.0 + 0.04 * _mu^3)  * _lambda;
_a0_2 = (1.0 / 8.0 + 1.0 / 8.0 * _mu^2)   * (rad _theta0_deg);
_a0_3 = (1.0 / 10.0 + 1.0 / 12.0 * _mu^2) * (rad _theta1_deg);

_a0_deg = _gamma * (_a0_1 + _a0_2 + _a0_3);
_a0_deg = deg _a0_deg;

[_a0_deg];