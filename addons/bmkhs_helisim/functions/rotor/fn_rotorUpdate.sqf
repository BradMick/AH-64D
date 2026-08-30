#include "\bmkhs_helisim\functions\rotor\rotor.hpp"

params ["_heli"];

if (!local _heli) exitWith {};

private _cfg           = configOf _heli;
private _sfmPlusConfig = _cfg >> "BMKHS_HeliSim";

private _numRotor	   = 2;
private _pivot         = [ [ 0.00,  2.06,  0.000]
                         , [ 0.00, -6.98, -0.075]];
private _rot           = [ [0.0,   0.0, 0.0]
                         , [0.0, 90.0, 0.0]];
private _type          = [ MAIN
                         , TAIL];
private _dir           = [ CCW
                         , CCW];
private _numBlades     = _heli getVariable "bmkhs_rotorNumBlades";
private _numElements   = _heli getVariable "bmkhs_rotorNumElements";
private _mastLength    = _heli getVariable "bmkhs_rotorMastLength";
private _gearRatio     = _heli getVariable "bmkhs_rotorGearRatioArr";
private _flapTimeConst = [ [2.0, 3.0]
                         , [0.5, 0.5]];
private _inflowAlpha   = [0.05, 0.01];
private _delta3        = _heli getVariable "bmkhs_rotorDelta3";
private _airfoilTable  = [ getArray (_sfmPlusConfig >> "airfoilTable02")
                         , getArray (_sfmPlusConfig >> "airfoilTable01")];
private _bladeCutout   = _heli getVariable "bmkhs_rotorBladeCutout";
private _bladeLength   = _heli getVariable "bmkhs_rotorBladeLength";
private _bladeChord    = _heli getVariable "bmkhs_rotorBladeChordArr";
private _bladeTwist    = _heli getVariable "bmkhs_rotorBladeTwist";
private _bladeMass     = _heli getVariable "bmkhs_rotorBladeMassArr";

private _pitchMin      = _heli getVariable "bmkhs_rotorPitchMin";
private _pitchMid      = [  0
                         ,  0];
private _pitchMax      = _heli getVariable "bmkhs_rotorPitchMax";
private _rollMin       = _heli getVariable "bmkhs_rotorRollMin";
private _rollMid       = [  0
                         ,  0];
private _rollMax       = _heli getVariable "bmkhs_rotorRollMax";
private _collMin       = _heli getVariable "bmkhs_rotorCollMin";
private _collMid       = [  0
                         ,  0];
private _collMax       = _heli getVariable "bmkhs_rotorCollMax";
private _animSource    = _heli getVariable "bmkhs_rotorAnimSource";
private _hitPoint      = _heli getVariable "bmkhs_rotorHitPoint";
private _dmgThreshold  = [ 0.99
                         , 0.85];

// Debug: draw CG position as a sphere with crosshair lines
private _cgPos = getCenterOfMass _heli;
private _cgR   = 5.0;
[_heli, 16, _cgPos, _cgR, 0, "red"]   call bmkhs_fnc_debugDrawCircle;
[_heli, 16, _cgPos, _cgR, 1, "red"]   call bmkhs_fnc_debugDrawCircle;
[_heli, 16, _cgPos, _cgR, 2, "red"]   call bmkhs_fnc_debugDrawCircle;
[_heli, _cgPos vectorAdd [-_cgR, 0, 0], _cgPos vectorAdd [_cgR, 0, 0], "white"] call bmkhs_fnc_debugDrawLine;
[_heli, _cgPos vectorAdd [0, -_cgR, 0], _cgPos vectorAdd [0, _cgR, 0], "white"] call bmkhs_fnc_debugDrawLine;
[_heli, _cgPos vectorAdd [0, 0, -_cgR], _cgPos vectorAdd [0, 0, _cgR], "white"] call bmkhs_fnc_debugDrawLine;

for "_rotorIndex" from 0 to (_numRotor - 1) do {
    [ _heli
    , _rotorIndex
    , _pivot         select _rotorIndex
    , _rot           select _rotorIndex
    , _type          select _rotorIndex
    , _dir           select _rotorIndex
    , _numBlades     select _rotorIndex
    , _numElements   select _rotorIndex
    , _mastLength    select _rotorIndex
    , _gearRatio     select _rotorIndex
    , _flapTimeConst select _rotorIndex
    , _inflowAlpha   select _rotorIndex
    , _delta3        select _rotorIndex
    , _airfoilTable  select _rotorIndex
    , _bladeCutout   select _rotorIndex
    , _bladeLength   select _rotorIndex
    , _bladeChord    select _rotorIndex
    , _bladeTwist    select _rotorIndex
    , _bladeMass     select _rotorIndex
    , _pitchMin      select _rotorIndex
    , _pitchMid      select _rotorIndex
    , _pitchMax      select _rotorIndex
    , _rollMin       select _rotorIndex
    , _rollMid       select _rotorIndex
    , _rollMax       select _rotorIndex
    , _collMin       select _rotorIndex
    , _collMid       select _rotorIndex
    , _collMax       select _rotorIndex
    , _animSource    select _rotorIndex
    , _hitPoint      select _rotorIndex
    , _dmgThreshold  select _rotorIndex
    ] call bmkhs_fnc_rotor;
};
