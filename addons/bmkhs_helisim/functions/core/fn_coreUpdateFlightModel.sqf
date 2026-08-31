#include "\bmkhs_helisim\headers\core.hpp"

params ["_heli"];

if (isGamePaused || CBA_missionTime < 0.1) exitWith {};

if (bmkhs_rotorModel == 1) then {
    // Blade Element Theory rotor model
    [_heli] call bmkhs_fnc_rotorUpdate;
} else {
    // Simple rotor model
    [_heli] call bmkhs_fnc_simpleRotorMain;
    [_heli] call bmkhs_fnc_simpleRotorTail;
};

//Fuselage
[_heli] call bmkhs_fnc_fuselage;

//Right Wing
//Lifting surfaces - wings, fins and the stabilator. Config declares as many as
//the aircraft has; an aircraft with none sets numWings = 0.
private _numWings           = _heli getVariable "bmkhs_numWings";
private _wingIsStabilator   = _heli getVariable "bmkhs_wingIsStabilator";
private _wingPos            = _heli getVariable "bmkhs_wingPos";
private _wingPitch          = _heli getVariable "bmkhs_wingPitch";
private _wingRoll           = _heli getVariable "bmkhs_wingRoll";
private _wingSpan           = _heli getVariable "bmkhs_wingSpan";
private _wingChord          = _heli getVariable "bmkhs_wingChord";
private _wingSweep          = _heli getVariable "bmkhs_wingSweep";
private _wingTwist          = _heli getVariable "bmkhs_wingTwist";
private _wingTipWidthScalar = _heli getVariable "bmkhs_wingTipWidthScalar";

for "_i" from 0 to (_numWings - 1) do {
    [ _heli
     ,_wingPos            select _i
     ,_wingPitch          select _i
     ,_wingRoll           select _i
     ,_wingSpan           select _i
     ,_wingChord          select _i
     ,_wingSweep          select _i
     ,_wingTwist          select _i
     ,_wingTipWidthScalar select _i
     ,(_wingIsStabilator  select _i) > 0
     ,_i
     ] call bmkhs_fnc_wing;
};
