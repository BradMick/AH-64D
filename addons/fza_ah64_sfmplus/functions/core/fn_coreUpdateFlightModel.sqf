#include "\fza_ah64_sfmplus\headers\core.hpp"

params ["_heli"];

if (isGamePaused || CBA_missionTime < 0.1) exitWith {};

if (fza_ah64_sfmPlusRotorModel == 1) then {
    // Blade Element Theory rotor model
    [_heli] call fza_sfmplus_fnc_rotorUpdate;
} else {
    // Simple rotor model
    [_heli] call fza_sfmplus_fnc_simpleRotorMain;
    [_heli] call fza_sfmplus_fnc_simpleRotorTail;
};

//Fuselage
[_heli] call fza_sfmplus_fnc_fuselage;

//Right Wing
[ _heli
 ,[1.5,1.9,-1.4]
 ,12.0
 ,0.0
 ,2.00
 ,1.0
 ,0.0
 ,0.0
 ,1.0
 ,
 [
  [ 0.00, 1.000]
 ,[10.29, 1.000]
 ,[20.58, 1.000]
 ,[36.01, 1.000]
 ,[46.30, 1.000]
 ,[51.44, 1.000]
 ,[61.73, 1.000]
 ,[66.88, 1.000]
 ,[72.02, 1.000]
 ]
 ,false ] call fza_sfmplus_fnc_wing;
//Left Wing
[ _heli
 ,[-1.5,1.9,-1.4]
 ,12.0
 ,0.0
 ,2.00
 ,1.0
 ,0.0
 ,0.0
 ,1.0
 ,
  [
  [ 0.00, 1.000]
 ,[10.29, 1.000]
 ,[20.58, 1.000]
 ,[36.01, 1.000]
 ,[46.30, 1.000]
 ,[51.44, 1.000]
 ,[61.73, 1.000]
 ,[66.88, 1.000]
 ,[72.02, 1.000]
 ]
 ,false ] call fza_sfmplus_fnc_wing;

//Vertical fin
[ _heli
 ,[0.0, -7.45, -0.75]   //pos
 ,0.0                   //pitch
 ,90.0                  //roll
 ,2.25                  //span
 ,0.95                  //chord
 ,1.4                   //sweep
 ,0.0                   //twist
 ,1.0                   //tipWidthScalar
 ,
[
  [ 0.00, 1.000]
 ,[10.29, 1.000]
 ,[20.58, 1.000]
 ,[36.01, 1.000]
 ,[46.30, 1.000]
 ,[51.44, 1.000]
 ,[61.73, 1.000]
 ,[66.88, 1.000]
 ,[72.02, 1.000]
 ]
 ,false ] call fza_sfmplus_fnc_wing;

//Stabilator
[ _heli
 ,[0.0, -6.45, -1.85]
 ,0.0
 ,0.0
 ,(_heli getVariable "fza_sfmplus_stabWidth")
 ,(_heli getVariable "fza_sfmplus_stabLength")
 ,0.0
 ,0.0
 ,1.0
 ,
[
  [ 0.00, 1.000]
 ,[10.29, 1.000]
 ,[20.58, 1.000]
 ,[36.01, 1.000]
 ,[46.30, 1.000]
 ,[51.44, 1.000]
 ,[61.73, 1.000]
 ,[66.88, 1.000]
 ,[72.02, 1.000]
 ]
 ,true
 ] call fza_sfmplus_fnc_wing;
