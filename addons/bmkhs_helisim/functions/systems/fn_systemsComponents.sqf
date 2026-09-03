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
    ["input",        (getArray (cfg >> "input")) param [0, ""]], \
    ["minInput",     (getArray (cfg >> "input")) param [1, 0]], \
    ["ratio",        [1, getNumber (cfg >> "ratio")] select (isNumber (cfg >> "ratio"))], \
    ["requires",     getText   (cfg >> "requires")], \
    ["requiresAbove",getNumber (cfg >> "requiresAbove")], \
    ["nominal",      getNumber (cfg >> "nominal")], \
    ["rampRate",     if ((getNumber (cfg >> "rampSeconds")) > 0) \
                        then {(getNumber (cfg >> "nominal")) / (getNumber (cfg >> "rampSeconds"))} \
                        else {0}], \
    ["increment",    getNumber (cfg >> "increment")], \
    ["networked",    getNumber (cfg >> "networked") > 0], \
    ["stateVar",     getText   (cfg >> "stateName")], \
    ["stateAbove",   getNumber (cfg >> "stateAbove")], \
    ["torqueFrom",   getText   (cfg >> "torqueFrom")], \
    ["tqLimits",     getArray  (cfg >> "tqLimits")], \
    ["breaksVar",    getText   (cfg >> "breaksOnFailure")], \
    ["tqLimitsSE",   getArray  (cfg >> "tqLimitsSE")], \
    ["torqueSum",    getNumber (cfg >> "torqueSum") > 0] \
]

private _circuits = createHashMap;

//What a component puts where. One entry per Outputs class, or the single output field
//for something that only feeds one circuit.
//  circuit         node it feeds
//  ratio           of its own value; 1 passes it straight through, as a shaft does
//  nominal         fixed value instead, for an output that does not scale with the source
//  disengageAbove  circuit and threshold above which THIS output drops out, for a clutch
private _readOutputs = {
    params ["_cfg"];
    private _outs = [];
    {
        _outs pushBack (createHashMapFromArray [
            ["circuit",     getText   (_x >> "circuit")],
            ["ratio",       [1, getNumber (_x >> "ratio")] select (isNumber (_x >> "ratio"))],
            ["nominal",     getNumber (_x >> "nominal")],
            ["disengageOn", (getArray (_x >> "disengageAbove")) param [0, ""]],
            ["disengageAt", (getArray (_x >> "disengageAbove")) param [1, 0]]
        ]);
        _circuits set [getText (_x >> "circuit"), 0];
    } forEach ("true" configClasses (_cfg >> "Outputs"));

    if (_outs isEqualTo [] && {(getText (_cfg >> "output")) != ""}) then {
        _outs pushBack (createHashMapFromArray [
            ["circuit",     getText (_cfg >> "output")],
            ["ratio",       1],
            ["nominal",     getNumber (_cfg >> "nominal")],
            ["disengageOn", ""],
            ["disengageAt", 0]
        ]);
        _circuits set [getText (_cfg >> "output"), 0];
    };
    _outs
};

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
        _m set ["outputs", [_x] call _readOutputs];
        _producers pushBack _m;
    };

    if ((_c get "output") != "") then { _circuits set [_c get "output", 0] };
} forEach ("true" configClasses (_config >> "Producers"));

//Converters - consume from one circuit and produce onto another. They create nothing.
private _converters = [];
{
    private _c    = COMPONENT_FIELDS(_x);
    private _role = _c get "damageRole";

    private _count = if (_role == "") then {1} else {[_heli, _role] call bmkhs_fnc_damageCount};
    for "_i" from 0 to (_count - 1) do {
        private _m = +_c;
        _m set ["index",   _i];
        _m set ["varName", format ["bmkhs_%1%2", _c get "variableName",
                                   [_i + 1, ""] select (_count <= 1)]];
        _m set ["outputs", [_x] call _readOutputs];
        _converters pushBack _m;
    };

    if ((_c get "input") != "") then { _circuits set [_c get "input", 0] };
} forEach ("true" configClasses (_config >> "Converters"));
_heli setVariable ["bmkhs_sysConverters", _converters];

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
        _m set ["outputs", [_x] call _readOutputs];
        _storage pushBack _m;
    };

    if ((_c get "output") != "") then { _circuits set [_c get "output", 0] };
} forEach ("true" configClasses (_config >> "Storage"));

//Circuits that publish their own state - a bus being up is a fact about the node, not
//something drawing from it.
private _named = [];
{
    private _c = createHashMapFromArray [
        ["circuit",      getText   (_x >> "circuit")],
        ["minValue",     getNumber (_x >> "minValue")],
        ["networked",    getNumber (_x >> "networked") > 0]
    ];
    _c set ["varName", format ["bmkhs_%1", getText (_x >> "variableName")]];
    _named pushBack _c;
    _circuits set [_c get "circuit", 0];
} forEach ("true" configClasses (_config >> "Circuits"));
_heli setVariable ["bmkhs_sysNamed", _named];

//Consumers - suppliedBy is an OR by default, or an AND with needsAll.
private _consumers = [];
{
    private _c = createHashMapFromArray [
        ["variableName", getText  (_x >> "variableName")],
        ["needsAll",     getNumber (_x >> "needsAll") > 0],
        ["networked",    getNumber (_x >> "networked") > 0]
    ];
    _c set ["circuits", (getArray (_x >> "suppliedBy")) apply {[_x select 0, _x param [1, 0]]}];
    _c set ["varName", format ["bmkhs_%1", _c get "variableName"]];
    _consumers pushBack _c;

    { _circuits set [_x select 0, 0] } forEach (_c get "circuits");
} forEach ("true" configClasses (_config >> "Consumers"));

//Anything with torque limits, gathered from every kind - a gearbox is a converter and
//the transmission is a producer, but both are rated for a torque.
private _torqued = (_producers + _converters + _storage) select {(count (_x get "tqLimits")) > 0};

//An airframe that models no systems still has a drivetrain, and it does not get to ignore
//what that is rated for. The limits sit at the top level for exactly that case, so Core
//builds the drive components from them when nothing else declared any.
if (_torqued isEqualTo []) then {
    {
        _x params ["_role", "_torqueVar", "_sums", "_limits", "_limitsSE", "_breaks"];
        private _count = [_heli, _role] call bmkhs_fnc_damageCount;
        for "_i" from 0 to ((_count max 1) - 1) do {
            _torqued pushBack (createHashMapFromArray [
                ["damageRole", _role],
                ["index",      _i],
                ["torqueFrom", _torqueVar],
                ["torqueSum",  _sums],
                ["tqLimits",   _limits],
                ["tqLimitsSE", _limitsSE],
                ["breaksVar",  _breaks]
            ]);
        };
    } forEach [
        //The transmission carries both engines summed, and has no single-engine case -
        //one engine can never overtorque what is rated for two.
        ["transmission",  "bmkhs_engPctTQ", true,  getArray (_config >> "xmsnTqLimits"),
                          [], ""],
        //A nose gearbox carries its own engine, which makes it the limiting part when one
        //is doing the work of two.
        ["noseGearboxes", "bmkhs_engPctTQ", false, getArray (_config >> "ngbTqLimits"),
                          getArray (_config >> "ngbTqLimitsSE"), "bmkhs_engineOverspeed"]
    ];
    //Only the ones the aircraft actually gave limits for.
    _torqued = _torqued select {(count (_x get "tqLimits")) > 0 || {(count (_x get "tqLimitsSE")) > 0}};
};
_heli setVariable ["bmkhs_sysTorqued", _torqued];

_heli setVariable ["bmkhs_sysProducers", _producers];
_heli setVariable ["bmkhs_sysStorage",   _storage];
_heli setVariable ["bmkhs_sysConsumers", _consumers];
_heli setVariable ["bmkhs_sysCircuits",  _circuits];
