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
if (([_heli, "priReservoir"] call bmkhs_fnc_damageGet) == 0) then {
    _heli setVariable ["bmkhs_priLevel_pct", 1.0, true];
    [_heli, "priReservoir", 0.000001] call bmkhs_fnc_damageSet
};
if (([_heli, "priPump"] call bmkhs_fnc_damageGet) == 0) then {
    _heli setVariable ["bmkhs_priHydPSI_pct", 1.0, true];
    [_heli, "priPump", 0.000001] call bmkhs_fnc_damageSet
};
if (([_heli, "utilReservoir"] call bmkhs_fnc_damageGet) == 0) then {
    _heli setVariable ["bmkhs_utilLevel_pct", 1.0, true];
    _heli setVariable ["bmkhs_accHydPSI_pct", 1.0, true];
    [_heli, "utilReservoir", 0.000001] call bmkhs_fnc_damageSet
};
if (([_heli, "utilPump"] call bmkhs_fnc_damageGet) == 0) then {
    _heli setVariable ["bmkhs_utilHydPSI_pct", 1.0, true];
    [_heli, "utilPump", 0.000001] call bmkhs_fnc_damageSet
};
