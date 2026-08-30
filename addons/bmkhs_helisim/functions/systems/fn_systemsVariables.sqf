/* ----------------------------------------------------------------------------
Function: bmkhs_fnc_variables

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
#include "\bmkhs_helisim\headers\systems.hpp"

if (!(_heli getVariable ["fza_ah64_aircraftSystemsInitialised", false]) && local _heli) then {
    _heli setVariable ["fza_ah64_aircraftSystemsInitialised", true, true];

    //Switch states
    _heli setVariable ["bmkhs_battSwitchOn",      false, true];

    //Electrical System
    //--Battery
    _heli setVariable ["bmkhs_battPower_pct",     1.0, true];
    //--Buses
    _heli setVariable ["bmkhs_battBusOn",         false, true];
    _heli setVariable ["bmkhs_acBusOn",           false, true];
    _heli setVariable ["bmkhs_dcBusOn",           false, true];
    //--Gen 1 and RTRU 1
    _heli setVariable ["bmkhs_gen1On",            false, true];
    _heli setVariable ["bmkhs_rect1On",           false, true];
    //--Gen 2 and RTRU 2
    _heli setVariable ["bmkhs_gen2On",            false, true];
    _heli setVariable ["bmkhs_rect2On",           false, true];

    //APU
    _heli setVariable ["bmkhs_apuBtnOn",          false, true];
    _heli setVariable ["bmkhs_apuRPM_pct",        0.0, true];
    _heli setVariable ["bmkhs_apuOn",             false, true];


    //Hydraulics
    _heli setVariable ["bmkhs_priHydPSI_pct",     1.0, true];
    _heli setVariable ["bmkhs_priLevel_pct",      1.0, true];
    _heli setVariable ["bmkhs_utilHydPSI_pct",    1.0, true];
    _heli setVariable ["bmkhs_utilLevel_pct",     1.0, true];
    _heli setVariable ["bmkhs_accHydPSI_pct",     1.0, true];
};

_heli setVariable ["bmkhs_apuStartDelay",     5.0];
_heli setVariable ["bmkhs_apuFF_kgs",         0.0];
_heli setVariable ["bmkhs_priHydPsi",         1.0];
_heli setVariable ["bmkhs_utilHydPsi",        1.0];
_heli setVariable ["bmkhs_dmgTimerCont",      0.0];
_heli setVariable ["bmkhs_dmgTimerTrans",     0.0];
_heli setVariable ["bmkhs_accHydPsi",         0.0];
private _battTime = SYS_BATT_TIMER * 60;
_heli setVariable ["bmkhs_battTimer",         _battTime];
private _leakTimer = SYS_LEAK_TIMER * 60;
_heli setVariable ["bmkhs_hydLeakTimer",      _leakTimer];
private _accTime = SYS_ACC_TIMER * 60;
_heli setVariable ["bmkhs_accTimer",          _accTime];
