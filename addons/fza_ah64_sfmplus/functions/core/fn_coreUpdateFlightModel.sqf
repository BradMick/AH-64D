#include "\fza_ah64_sfmplus\headers\core.hpp"

params ["_heli"];

if (isGamePaused || CBA_missionTime < 0.1) exitWith {};

//Reset the tuner force/moment log at the top of the frame (no-op unless the
//Forces readout is enabled) so it captures exactly this frame's contributions.
[_heli] call fza_sfmplus_fnc_forceLogReset;

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
 ,false
 ,"Right Wing" ] call fza_sfmplus_fnc_wing;
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
 ,false
 ,"Left Wing" ] call fza_sfmplus_fnc_wing;
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
 ,(_heli getVariable ["fza_sfmplus_tune_finLiftScalarTable",
 [
  [ 0.00, 2.1]   // master-tuned: flat 2.1 across all bands
 ,[10.29, 2.1]
 ,[20.58, 2.1]
 ,[36.01, 2.1]
 ,[46.30, 2.1]
 ,[51.44, 2.1]
 ,[61.73, 2.1]
 ,[66.88, 2.1]
 ,[72.02, 2.1]
 ]])
 ,false
 ,"Vertical Fin" ] call fza_sfmplus_fnc_wing;

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
 ,(_heli getVariable ["fza_sfmplus_tune_stabLiftScalarTable",
 [
  [ 0.00, 1.000]   // 0-90 kt tuned; 100-140 extrapolated (stab download ramps with speed)
 ,[10.29, 1.074]
 ,[20.58, 1.148]
 ,[36.01, 1.222]
 ,[46.30, 1.296]
 ,[51.44, 1.317]
 ,[61.73, 1.368]
 ,[66.88, 1.392]
 ,[72.02, 1.415]
 ]])
 ,true
 ,"Stabilator"
 ] call fza_sfmplus_fnc_wing;

//Force-balance trim - applied last so it adjusts the net of every generator.
[_heli] call fza_sfmplus_fnc_tunerBalance;

//Optional yaw-rate damper (Balance-panel toggle) - applies an opposing yaw torque
//to decay a standing precession, and logs it as its own "Yaw Damper" generator.
[_heli] call fza_sfmplus_fnc_tunerYawDamper;
