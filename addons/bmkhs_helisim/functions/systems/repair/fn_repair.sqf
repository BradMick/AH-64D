/* ----------------------------------------------------------------------------
Function: bmkhs_fnc_repair

Description:
    Updates all of the modules core functions.

Parameters:
    _heli - The helicopter to get information from [Unit].

Returns:
    ...

Examples:
    ...

Author:
    BradMick
---------------------------------------------------------------------------- */
params ["_heli"];
#include "\bmkhs_helisim\functions\systems\systems.hpp"

//Runs when a HandleDamage event saw a hitpoint go DOWN - a repair announces itself, so
//there is nothing to poll for. Each check below re-seeds to 0.000001 so a component that
//has been restored reads as not-exactly-zero and does not trigger again.
if !(_heli getVariable ["bmkhs_repairPending", false]) exitWith {};
_heli setVariable ["bmkhs_repairPending", false];

if (([_heli, "engines", 0] call bmkhs_fnc_damageGet) == 0) then {
    [_heli, "bmkhs_engineOverspeed", 0.0, false, true] call bmkhs_fnc_utilSetArrayVariable;
    [_heli, "engines", 0.000001, 0] call bmkhs_fnc_damageSet
};
if (([_heli, "engines", 1] call bmkhs_fnc_damageGet) == 0) then {
    [_heli, "bmkhs_engineOverspeed", 1.0, false, true] call bmkhs_fnc_utilSetArrayVariable;
    [_heli, "engines", 0.000001, 1] call bmkhs_fnc_damageSet
};
if (([_heli, "batteries", 0] call bmkhs_fnc_damageGet) == 0) then {
    _heli setVariable ["bmkhs_battPower_pctCharge", 1.0, true];
    [_heli, "batteries", 0.000001, 0] call bmkhs_fnc_damageSet
};
//A repair makes the aircraft serviceable, not running. Fluid and stored charge come
//back to full because those are quantities a repair replaces - but PRESSURE depends on
//whether anything is turning the pumps, so it is set to match the state the aircraft is
//actually in. Repair a running aircraft and it has pressure; repair a cold one and it
//has none until something spins up, which is what the crew would see either way.
private _pumpsTurning = ([_heli, "ACCESSORY_DRIVE"] call bmkhs_fnc_systemCircuit) > SYS_HYD_MIN_RTR_RPM;
private _hydPsi       = [0.0, 3000.0] select _pumpsTurning;

if (([_heli, "priReservoir"] call bmkhs_fnc_damageGet) == 0) then {
    _heli setVariable ["bmkhs_priLevel_pctCharge", 1.0, true];
    [_heli, "priReservoir", 0.000001] call bmkhs_fnc_damageSet
};
if (([_heli, "priPump"] call bmkhs_fnc_damageGet) == 0) then {
    _heli setVariable ["bmkhs_priHydPsi", _hydPsi, true];
    [_heli, "priPump", 0.000001] call bmkhs_fnc_damageSet
};
if (([_heli, "utilReservoir"] call bmkhs_fnc_damageGet) == 0) then {
    _heli setVariable ["bmkhs_utilLevel_pctCharge", 1.0, true];
    //The accumulator is a store, so it comes back charged whether or not anything is
    //running - that is what a serviced aircraft has waiting to start its APU.
    _heli setVariable ["bmkhs_accHydPsiCharge",     1.0, true];
    _heli setVariable ["bmkhs_accHydPsi",           3000.0, true];
    [_heli, "utilReservoir", 0.000001] call bmkhs_fnc_damageSet
};
if (([_heli, "utilPump"] call bmkhs_fnc_damageGet) == 0) then {
    _heli setVariable ["bmkhs_utilHydPsi", _hydPsi, true];
    [_heli, "utilPump", 0.000001] call bmkhs_fnc_damageSet
};
