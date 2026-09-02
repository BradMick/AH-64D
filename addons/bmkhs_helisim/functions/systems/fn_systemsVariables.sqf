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
params ["_heli", "_config"];

#include "\bmkhs_helisim\functions\systems\systems.hpp"

if (!(_heli getVariable ["bmkhs_systemsInitialised", false]) && local _heli) then {
    _heli setVariable ["bmkhs_systemsInitialised", true, true];

    //Electrical and APU are only modelled when the aircraft asks for them. Without
    //them the aircraft behaves like vanilla Arma: powered up and running, with no
    //start procedure - so everything downstream reads as already on.
    private _sys = _heli getVariable ["bmkhs_useSystems", false];

    //Switch states
    _heli setVariable ["bmkhs_battSwitchOn",      !_sys, true];

    //Electrical System
    //--Battery
    _heli setVariable ["bmkhs_battPower_pct",     1.0, true];
    //--Buses
    _heli setVariable ["bmkhs_battBusOn",         !_sys, true];
    _heli setVariable ["bmkhs_acBusOn",           !_sys, true];
    _heli setVariable ["bmkhs_dcBusOn",           !_sys, true];
    //--Gen 1 and RTRU 1
    _heli setVariable ["bmkhs_gen1On",            !_sys, true];
    _heli setVariable ["bmkhs_rect1On",           !_sys, true];
    //--Gen 2 and RTRU 2
    _heli setVariable ["bmkhs_gen2On",            !_sys, true];
    _heli setVariable ["bmkhs_rect2On",           !_sys, true];

    //APU - the engine controller shuts the engines down without it
    _heli setVariable ["bmkhs_apuBtnOn",          !_sys, true];
    _heli setVariable ["bmkhs_apuRPM_pct",        [1.0, 0.0] select _sys, true];
    _heli setVariable ["bmkhs_apuOn",             !_sys, true];


    //Hydraulics - reservoirs start full, and so does the accumulator, which is what
    //makes a cold aircraft startable. Pressure is NOT seeded: the pumps build it from
    //zero, which is both correct and what the ramp exists for.
    _heli setVariable ["bmkhs_priLevel_pctCharge",  1.0, true];
    _heli setVariable ["bmkhs_utilLevel_pctCharge", 1.0, true];
    _heli setVariable ["bmkhs_accHydPsiCharge",     1.0, true];
};

_heli setVariable ["bmkhs_apuFF_kgs",         0.0];
_heli setVariable ["bmkhs_dmgTimerCont",      0.0];
_heli setVariable ["bmkhs_dmgTimerTrans",     0.0];

_heli setVariable ["bmkhs_emerHydOn",         false, true];
_heli setVariable ["bmkhs_engineOverspeed",   [false, false], true];

//Systems tuning - the aircraft supplies these, Core keeps damage thresholds fixed
_heli setVariable ["bmkhs_hydMinPsi",       getNumber (_config >> "hydMinPsi")];
_heli setVariable ["bmkhs_hydMinAccPsi",    getNumber (_config >> "hydMinAccPsi")];
_heli setVariable ["bmkhs_hydMinLevel",     getNumber (_config >> "hydMinLevel")];
_heli setVariable ["bmkhs_hydAccTimerMin",  getNumber (_config >> "hydAccTimerMin")];
_heli setVariable ["bmkhs_hydLeakTimerMin", getNumber (_config >> "hydLeakTimerMin")];
_heli setVariable ["bmkhs_elecBattTimerMin",getNumber (_config >> "elecBattTimerMin")];
_heli setVariable ["bmkhs_apuStartDelay",   getNumber (_config >> "apuStartDelay")];

//Countdown timers, seeded full. These are DERIVED from the config values above, so they
//have to be set after them - reading them earlier returns nil and the multiply throws,
//which aborts the rest of this function and leaves the aircraft uninitialised.
_heli setVariable ["bmkhs_battTimer",    (_heli getVariable ["bmkhs_elecBattTimerMin", 0]) * 60];
_heli setVariable ["bmkhs_hydLeakTimer", (_heli getVariable ["bmkhs_hydLeakTimerMin", 0]) * 60];
_heli setVariable ["bmkhs_accTimer",     (_heli getVariable ["bmkhs_hydAccTimerMin",  0]) * 60];

//Drivetrain torque limits and timers
_heli setVariable ["bmkhs_ngbContTqLimit",    getNumber (_config >> "ngbContTqLimit")];
_heli setVariable ["bmkhs_ngbContTimer",      getNumber (_config >> "ngbContTimer")];
_heli setVariable ["bmkhs_ngbTransTqLimit",   getNumber (_config >> "ngbTransTqLimit")];
_heli setVariable ["bmkhs_ngbTransTimer",     getNumber (_config >> "ngbTransTimer")];
_heli setVariable ["bmkhs_ngbMaxTqLimit",     getNumber (_config >> "ngbMaxTqLimit")];
_heli setVariable ["bmkhs_xmsnContTqLimit",   getNumber (_config >> "xmsnContTqLimit")];
_heli setVariable ["bmkhs_xmsnTransTqLimit",  getNumber (_config >> "xmsnTransTqLimit")];
_heli setVariable ["bmkhs_xmsnTransTimer",    getNumber (_config >> "xmsnTransTimer")];
