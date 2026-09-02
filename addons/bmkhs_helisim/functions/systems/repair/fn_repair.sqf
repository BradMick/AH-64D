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

if (([_heli, "engines", 0] call bmkhs_fnc_damageGet) == 0) then {
    [_heli, "bmkhs_engineOverspeed", 0.0, false, true] call bmkhs_fnc_utilSetArrayVariable;
    [_heli, "engines", 0.000001, 0] call bmkhs_fnc_damageSet
};
if (([_heli, "engines", 1] call bmkhs_fnc_damageGet) == 0) then {
    [_heli, "bmkhs_engineOverspeed", 1.0, false, true] call bmkhs_fnc_utilSetArrayVariable;
    [_heli, "engines", 0.000001, 1] call bmkhs_fnc_damageSet
};
if (([_heli, "batteries", 0] call bmkhs_fnc_damageGet) == 0) then {
    _heli setVariable ["bmkhs_battPower_pct", 1.0, true];
    [_heli, "batteries", 0.000001, 0] call bmkhs_fnc_damageSet
};
//Refill what a repair refills. Pressure is not reset - the pumps rebuild it themselves
//once they have fluid and drive again, which is the whole point of the ramp.
if (([_heli, "priReservoir"] call bmkhs_fnc_damageGet) == 0) then {
    _heli setVariable ["bmkhs_priLevel_pctCharge", 1.0, true];
    [_heli, "priReservoir", 0.000001] call bmkhs_fnc_damageSet
};
if (([_heli, "priPump"] call bmkhs_fnc_damageGet) == 0) then {
    [_heli, "priPump", 0.000001] call bmkhs_fnc_damageSet
};
if (([_heli, "utilReservoir"] call bmkhs_fnc_damageGet) == 0) then {
    _heli setVariable ["bmkhs_utilLevel_pctCharge", 1.0, true];
    _heli setVariable ["bmkhs_accHydPsiCharge",     1.0, true];
    [_heli, "utilReservoir", 0.000001] call bmkhs_fnc_damageSet
};
if (([_heli, "utilPump"] call bmkhs_fnc_damageGet) == 0) then {
    [_heli, "utilPump", 0.000001] call bmkhs_fnc_damageSet
};
