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

//Every kind reads these; the ones that do not apply are simply absent.
//  damageRole   which hitpoints are this component's members
//  variableName what it publishes as, per member, Core owning the bmkhs_ prefix
//  gate         crew switch that must be on, "" for always armed
//  output       circuit it pushes onto
//  drivenBy     circuit that must be live for it to work, "" for none
//  driveFrom    variable its output follows, 0..1, for something that spools
//  minDrive     value that circuit must reach
//  requires     level variable it draws from, "" for none. Scales output, not gates it
//  requiresAbove  level below which it has nothing to move and makes nothing
//  nominal      what it produces at full output
//  rampSeconds  zero to full, 0 = instant
//  increment    round the published value to this step, 0 for none
//  passthrough  1 to output whatever drives it instead of nominal
#define COMPONENT_FIELDS(cfg) createHashMapFromArray [ \
    ["damageRole",   getText   (cfg >> "damageRole")], \
    ["variableName", getText   (cfg >> "variableName")], \
    ["gate",         getText   (cfg >> "gate")], \
    ["output",       getText   (cfg >> "output")], \
    ["drivenBy",     getText   (cfg >> "drivenBy")], \
    ["driveFrom",    getText   (cfg >> "driveFrom")], \
    ["minDrive",     getNumber (cfg >> "minDrive")], \
    ["requires",     getText   (cfg >> "requires")], \
    ["requiresAbove",getNumber (cfg >> "requiresAbove")], \
    ["nominal",      getNumber (cfg >> "nominal")], \
    ["rampRate",     if ((getNumber (cfg >> "rampSeconds")) > 0) \
                        then {(getNumber (cfg >> "nominal")) / (getNumber (cfg >> "rampSeconds"))} \
                        else {0}], \
    ["passthrough",  getNumber (cfg >> "passthrough") > 0], \
    ["increment",    getNumber (cfg >> "increment")] \
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

//Storage - accumulators, batteries, reservoirs. A producer holding a charge.
//  rechargedBy     circuit that refills it
//  minRecharge     value that circuit must reach before it does
//  startedBy       gate of the thing it cranks
//  startAbove      value needed for a start to happen at all
//  startRecharge   sec to refill once its recharge circuit is turning
//  stopBelow       value it stops discharging at
//  emerDischarge   sec full to empty as an emergency source
//  leakStartDmg    damage at which it starts leaking, 0 for never
//  leakSeconds     full to empty at FULL damage, ramping from the threshold
//  drainedBy[]     other damage roles that vent this store
private _storage = [];
{
    private _c    = COMPONENT_FIELDS(_x);
    private _role = _c get "damageRole";

    _c set ["rechargedBy", getText   (_x >> "rechargedBy")];
    _c set ["minRecharge", getNumber (_x >> "minRecharge")];
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

//Consumers - suppliedBy is an OR by default, or an AND with needsAll. An entry is a
//circuit name, or a name and its own threshold when one consumer spans different units.
private _consumers = [];
{
    private _min = getNumber (_x >> "minValue");
    private _c = createHashMapFromArray [
        ["variableName", getText  (_x >> "variableName")],
        ["minValue",     _min],
        ["needsAll",     getNumber (_x >> "needsAll") > 0]
    ];
    //Normalise to [circuit, threshold] so the kind does not have to test the shape.
    _c set ["circuits", (getArray (_x >> "suppliedBy")) apply {
        if (_x isEqualType []) then {[_x select 0, _x select 1]} else {[_x, _min]}
    }];
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
