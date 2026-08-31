/* ----------------------------------------------------------------------------
Function: bmkhs_fnc_fuelDraw

Description:
    Draws the engine and APU demand out of the main tanks and reports which
    consumers had fuel available.

    Each consumer names the MAIN it feeds from, by position in _mains - not by
    any fore/aft or left/right meaning, which is the aircraft's to assign:

      bmkhs_engFuelSource   main index per engine, default [0, 1]
      bmkhs_apuFuelSource   main index for the APU,  default 1

    The aircraft rewrites those when its crossfeed valve moves; with one main
    every consumer simply points at 0.

    Mutates _fuelMass in place.

Parameters:
    _heli      - The helicopter [Object]
    _fuelMass  - Per-tank masses, mutated [Array]
    _mains     - Indices of the tanks with role "main" [Array]
    _deltaTime - Frame time [Number]

Returns:
    [_eng1HadFuel, _eng2HadFuel, _apuHadFuel] [Array]

Author:
    BradMick / FZA Development Team
---------------------------------------------------------------------------- */
params ["_heli", "_fuelMass", "_mains", "_deltaTime"];

#define EPS 0.0001

if (_mains isEqualTo []) exitWith { [true, true, true] };

private _engFF    = _heli getVariable "bmkhs_engFF";
private _engState = _heli getVariable "bmkhs_engState";

//Demand per consumer, paired with the main it draws from.
private _engSource = _heli getVariable ["bmkhs_engFuelSource", [0, 1]];
private _apuSource = _heli getVariable ["bmkhs_apuFuelSource", 1];

private _demand = [];
{
    private _on  = (_engState select _forEachIndex) == "ON";
    private _idx = _mains param [_engSource param [_forEachIndex, 0], _mains select 0];
    _demand pushBack [_idx, [0, _x * _deltaTime] select _on];
} forEach _engFF;
_demand pushBack [
    _mains param [_apuSource, _mains select 0],
    (_heli getVariable "bmkhs_apuFF_kgs") * _deltaTime
];

//What each tank held BEFORE this frame, so a consumer that just emptied its tank is not
//reported starved until the next tick.
private _before = +_fuelMass;

{
    _x params ["_idx", "_req"];
    private _have = _fuelMass param [_idx, 0];
    _fuelMass set [_idx, (_have - (_req min _have)) max 0];
} forEach _demand;

_demand apply {
    _x params ["_idx", "_req"];
    (_req <= EPS) || {(_before param [_idx, 0]) > EPS}
}
