/* ----------------------------------------------------------------------------
Function: bmkhs_fnc_rotorMain

Description:
    ...

Parameters:
    _heli - The helicopter to get information from [Unit].

Returns:
    _gndSpeed, kts
    _vel2D, kts, simulates velocity from pitot/static sources
    _vel3D, kts, simulates velocity from an air data sensor
    _velModelSpace, m/s, unified local velocity for the simulation to use
    _vel, m/s, unified velocity for the simulation to use

Examples:
    ...

Author:
    BradMick
---------------------------------------------------------------------------- */
params ["_heli", "_useWind"];
#include "\fza_ah64_sfmplus\headers\core.hpp"

private _gndSpeed = round(MPS_TO_KNOTS * (velocityModelSpace _heli select 1));

private _vel3D         = 0.0;
private _vel2D         = 0.0;
private _velModelSpace = [];
private _velWorldSpace = [];

if (_useWind) then {
    _vel3D         = round(MPS_TO_KNOTS * vectorMagnitude(velocityModelSpace _heli vectorDiff wind));
    _vel2D         = round(MPS_TO_KNOTS * ((velocityModelSpace _heli vectorDiff wind) select 1));
    _velModelSpace = velocityModelSpace _heli vectorDiff wind;
    _velWorldSpace = velocity _heli vectorDiff wind;
} else {
    _vel3D         = round(MPS_TO_KNOTS * vectorMagnitude(velocityModelSpace _heli));
    _vel2D         = round(MPS_TO_KNOTS * (velocityModelSpace _heli select 1));
    _velModelSpace = velocityModelSpace _heli;
    _velWorldSpace = velocity _heli;
};

private _velVert   = (velocity _heli select 2) * MPS_TO_FPM;

[_gndSpeed, _vel2D, _vel3D, _velVert, _velModelSpace, _velWorldSpace];