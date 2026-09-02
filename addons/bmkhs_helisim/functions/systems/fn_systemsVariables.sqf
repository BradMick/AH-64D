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

    //Electrical - the buses are what everything outside Core reads, and with systems off
    //nothing solves them, so they stay as seeded.
    _heli setVariable ["bmkhs_battPower_pctCharge", 1.0, true];
    _heli setVariable ["bmkhs_battBusOn",         !_sys, true];
    _heli setVariable ["bmkhs_acBusOn",           !_sys, true];
    _heli setVariable ["bmkhs_dcBusOn",           !_sys, true];

    //APU - with systems off it reads as already running, and the graph does not touch it
    _heli setVariable ["bmkhs_apuBtnOn",          !_sys, true];
    _heli setVariable ["bmkhs_apuRPM_pct",        [1.0, 0.0] select _sys, true];
    _heli setVariable ["bmkhs_apuOn",             !_sys, true];
    _heli setVariable ["bmkhs_pneuAvail",         !_sys, true];


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

//Drivetrain torque limits and timers
_heli setVariable ["bmkhs_ngbContTqLimit",    getNumber (_config >> "ngbContTqLimit")];
_heli setVariable ["bmkhs_ngbContTimer",      getNumber (_config >> "ngbContTimer")];
_heli setVariable ["bmkhs_ngbTransTqLimit",   getNumber (_config >> "ngbTransTqLimit")];
_heli setVariable ["bmkhs_ngbTransTimer",     getNumber (_config >> "ngbTransTimer")];
_heli setVariable ["bmkhs_ngbMaxTqLimit",     getNumber (_config >> "ngbMaxTqLimit")];
_heli setVariable ["bmkhs_xmsnContTqLimit",   getNumber (_config >> "xmsnContTqLimit")];
_heli setVariable ["bmkhs_xmsnTransTqLimit",  getNumber (_config >> "xmsnTransTqLimit")];
_heli setVariable ["bmkhs_xmsnTransTimer",    getNumber (_config >> "xmsnTransTimer")];
