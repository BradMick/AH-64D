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

    //Switch states - cold and dark either way, the crew turns it on.
    _heli setVariable ["bmkhs_battSwitchOn",      false, true];

    //Electrical - with systems off nothing solves these, so they stay as seeded: the
    //aircraft is simply powered, with no buses to bring up.
    _heli setVariable ["bmkhs_battPower_pctCharge", 1.0, true];
    _heli setVariable ["bmkhs_battBusOn",         !_sys, true];
    _heli setVariable ["bmkhs_acBusOn",           !_sys, true];
    _heli setVariable ["bmkhs_dcBusOn",           !_sys, true];

    //APU - an aircraft with no systems has no APU to be on, so it reads OFF. Anything
    //that needed it, like an engine start, is not gated on it either.
    _heli setVariable ["bmkhs_apuBtnOn",          false, true];
    _heli setVariable ["bmkhs_apuRPM_pct",        0.0,   true];
    _heli setVariable ["bmkhs_apuOn",             false, true];
    //Bleed air defaults available without systems, so nothing that needs it is blocked.
    _heli setVariable ["bmkhs_pneuAvail",         !_sys, true];


    //Hydraulics - reservoirs and the accumulator start full.
    _heli setVariable ["bmkhs_priLevel_pctCharge",  1.0, true];
    _heli setVariable ["bmkhs_utilLevel_pctCharge", 1.0, true];
    _heli setVariable ["bmkhs_accHydPsiCharge",     1.0, true];

    //With systems the pumps build pressure from zero, which is what the ramp is for.
    //Without them nothing simulates it, so it sits at its running value.
    private _hydPsi = [3000.0, 0.0] select _sys;
    _heli setVariable ["bmkhs_priHydPsi",  _hydPsi, true];
    _heli setVariable ["bmkhs_utilHydPsi", _hydPsi, true];
    _heli setVariable ["bmkhs_accHydPsi",  3000.0,  true];
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
