/* ----------------------------------------------------------------------------
Function: bmkhs_fnc_systemsComponents

Description:
    Reads the aircraft's declared components out of config once and publishes
    them for the per-frame kinds to walk.

    The AIRCRAFT declares what it has; Core declares nothing. Member count
    comes from the damage role, so a role nothing claims means the airframe
    does not have that component. Circuits are collected from what components
    reference - a node exists because something feeds or reads it.

Parameters:
    _heli   - The helicopter [Object]
    _config - The aircraft's BMKHS_HeliSim config [Config]

Returns:
    Nothing

Author:
    BradMick
---------------------------------------------------------------------------- */
params ["_heli", "_config"];
#include "\bmkhs_helisim\functions\systems\systems.hpp"

//Field reference and the networking rules: \bmkhs_helisim\components.hpp
#define COMPONENT_FIELDS(cfg) createHashMapFromArray [ \
    ["damageRole",   getText   (cfg >> "damageRole")], \
    ["variableName", getText   (cfg >> "variableName")], \
    ["gates",        (getArray (cfg >> "gate")) apply {_x}], \
    ["output",       getText   (cfg >> "output")], \
    ["drivenBy",     (getArray (cfg >> "drivenBy")) param [0, ""]], \
    ["disengageOn",  (getArray (cfg >> "disengageAbove")) param [0, ""]], \
    ["disengageAt",  (getArray (cfg >> "disengageAbove")) param [1, 0]], \
    ["minDrive",     (getArray (cfg >> "drivenBy")) param [1, 0]], \
    ["driveFrom",    getText   (cfg >> "driveFrom")], \
    ["requires",     getText   (cfg >> "requires")], \
    ["requiresAbove",getNumber (cfg >> "requiresAbove")], \
    ["nominal",      getNumber (cfg >> "nominal")], \
    ["rampRate",     if ((getNumber (cfg >> "rampSeconds")) > 0) \
                        then {(getNumber (cfg >> "nominal")) / (getNumber (cfg >> "rampSeconds"))} \
                        else {0}], \
    ["passthrough",  getNumber (cfg >> "passthrough") > 0], \
    ["increment",    getNumber (cfg >> "increment")], \
    ["networked",    getNumber (cfg >> "networked") > 0], \
    ["needsSystems", getNumber (cfg >> "needsSystems") > 0] \
]

private _circuits = createHashMap;

//Producers - pumps, generators, the APU. Anything that puts a value onto a circuit
//given whatever drives it.
private _producers = [];
{
    private _c    = COMPONENT_FIELDS(_x);
    private _role = _c get "damageRole";

    //No role is not the same as a role nothing claims: it means present but not
    //separately damageable, so one member that never fails.
    private _count = if (_role == "") then {1} else {[_heli, _role] call bmkhs_fnc_damageCount};
    for "_i" from 0 to (_count - 1) do {
        private _m = +_c;
        _m set ["index",   _i];
        //Numbered only when there is more than one: gen1On and gen2On, but priHydPsi.
        _m set ["varName", format ["bmkhs_%1%2", _c get "variableName", [_i + 1, ""] select (_count <= 1)]];
        _producers pushBack _m;
    };

    if ((_c get "output") != "") then { _circuits set [_c get "output", 0] };
} forEach ("true" configClasses (_config >> "Producers"));

//Storage - a producer holding a charge.
private _storage = [];
{
    private _c    = COMPONENT_FIELDS(_x);
    private _role = _c get "damageRole";

    _c set ["rechargedBy", (getArray (_x >> "rechargedBy")) param [0, ""]];
    _c set ["minRecharge", (getArray (_x >> "rechargedBy")) param [1, 0]];
    _c set ["stopBelow",   getNumber (_x >> "stopBelow")];
    _c set ["startedBy",   getText   (_x >> "startedBy")];
    _c set ["startAbove",  getNumber (_x >> "startAbove")];

    //Charge is a fraction, so a full-to-empty time converts straight to a rate.
    private _drainSecs = getNumber (_x >> "emerDischarge");
    private _leakSecs  = getNumber (_x >> "leakSeconds");
    _c set ["emerRate",  if (_drainSecs > 0) then {1 / _drainSecs} else {0}];
    _c set ["leakRate",  if (_leakSecs  > 0) then {1 / _leakSecs}  else {0}];
    private _rechargeSecs = getNumber (_x >> "startRecharge");
    _c set ["rechargeRate", if (_rechargeSecs > 0) then {1 / _rechargeSecs} else {1 / SYS_START_RECHARGE_SEC}];
    _c set ["leakStartDmg", getNumber (_x >> "leakStartDmg")];
    _c set ["drainedBy",    getArray  (_x >> "drainedBy")];

    //As above: no role means present but not separately damageable, not absent.
    private _count = if (_role == "") then {1} else {[_heli, _role] call bmkhs_fnc_damageCount};
    for "_i" from 0 to (_count - 1) do {
        private _m = +_c;
        _m set ["index",   _i];
        _m set ["varName", format ["bmkhs_%1%2", _c get "variableName", [_i + 1, ""] select (_count <= 1)]];
        _storage pushBack _m;
    };

    if ((_c get "output") != "") then { _circuits set [_c get "output", 0] };
} forEach ("true" configClasses (_config >> "Storage"));

//Consumers - suppliedBy is an OR by default, or an AND with needsAll.
private _consumers = [];
{
    private _c = createHashMapFromArray [
        ["variableName", getText  (_x >> "variableName")],
        ["needsAll",     getNumber (_x >> "needsAll") > 0],
        ["networked",    getNumber (_x >> "networked") > 0],
        ["needsSystems", getNumber (_x >> "needsSystems") > 0]
    ];
    _c set ["circuits", (getArray (_x >> "suppliedBy")) apply {[_x select 0, _x param [1, 0]]}];
    _c set ["varName", format ["bmkhs_%1", _c get "variableName"]];
    _consumers pushBack _c;

    { _circuits set [_x select 0, 0] } forEach (_c get "circuits");
} forEach ("true" configClasses (_config >> "Consumers"));

_heli setVariable ["bmkhs_sysProducers", _producers];
_heli setVariable ["bmkhs_sysStorage",   _storage];
_heli setVariable ["bmkhs_sysConsumers", _consumers];
_heli setVariable ["bmkhs_sysCircuits",  _circuits];

//No components means nothing to simulate, not failed systems - consumers fall back to
//their own defaults so the airframe still flies.
_heli setVariable ["bmkhs_sysModelled", (count _producers) + (count _storage) > 0];
