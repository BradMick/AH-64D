/* ----------------------------------------------------------------------------
Function: bmkhs_fnc_systemsComponents

Description:
    Reads the aircraft's declared system components out of config, once, and
    publishes them as hashmaps for the per-frame kinds to walk.

    The AIRCRAFT declares what it has; Core declares nothing. A component names
    the damage role it answers to, and the hitpoints claiming that role ARE its
    members - so declaring a third generator hitpoint gives a third generator
    with no change here. A component whose role nothing claims produces no
    members at all, which is how "this airframe does not model that system"
    is expressed.

    Hashmaps, not positional arrays, for the same reason the fuel tanks use
    them: adding a field cannot silently shift what every reader sees.

    Circuits are collected from what components reference rather than being
    declared separately - a node exists because something feeds or reads it.

Parameters:
    _heli   - The helicopter [Object]
    _config - The aircraft's BMKHS_HeliSim config [Config]

Returns:
    Nothing

Author:
    BradMick
---------------------------------------------------------------------------- */
params ["_heli", "_config"];

//Every kind reads these; the ones that do not apply are simply absent.
//  damageRole   which hitpoints are this component's members
//  variableName what it publishes as, per member, Core owning the bmkhs_ prefix
//  gate         crew switch that must be on, "" for always armed
//  output       circuit it pushes onto
//  drivenBy     circuit that has to be turning/live for it to work, "" for none
//  minDrive     value that circuit must reach - an autorotating rotor drives
//               hydraulics at 0.45 but not generators at 0.85
//  requires     store that must have contents left, "" for none
//  nominal      what it produces at full output
//  rampSeconds  how long zero to full takes, 0 = instant. Times, not rates - "one second
//               to full pressure" is something a person can reason about
//  passthrough  1 to output whatever drives it instead of nominal - a shaft passes its
//               speed along, so the accessory drive turns at whatever is turning it
#define COMPONENT_FIELDS(cfg) createHashMapFromArray [ \
    ["damageRole",   getText   (cfg >> "damageRole")], \
    ["variableName", getText   (cfg >> "variableName")], \
    ["gate",         getText   (cfg >> "gate")], \
    ["output",       getText   (cfg >> "output")], \
    ["drivenBy",     getText   (cfg >> "drivenBy")], \
    ["minDrive",     getNumber (cfg >> "minDrive")], \
    ["requires",     getText   (cfg >> "requires")], \
    ["nominal",      getNumber (cfg >> "nominal")], \
    ["rampRate",     if ((getNumber (cfg >> "rampSeconds")) > 0) \
                        then {(getNumber (cfg >> "nominal")) / (getNumber (cfg >> "rampSeconds"))} \
                        else {0}], \
    ["passthrough",  getNumber (cfg >> "passthrough") > 0] \
]

private _circuits = createHashMap;

//Producers - pumps, generators, the APU. Anything that puts a value onto a circuit
//given whatever drives it.
private _producers = [];
{
    private _c    = COMPONENT_FIELDS(_x);
    private _role = _c get "damageRole";

    //Member count comes from the damage role: the hitpoints claiming it ARE the members,
    //so a role nothing claims means this airframe does not have the component at all.
    //
    //Declaring NO role is different - it means the component exists but is not separately
    //damageable, like an accumulator with no selection of its own in the p3d. One member,
    //and bmkhs_fnc_damageGet returns 0 for the empty role, so it simply never fails.
    private _count = if (_role == "") then {1} else {[_heli, _role] call bmkhs_fnc_damageCount};
    for "_i" from 0 to (_count - 1) do {
        private _m = +_c;
        _m set ["index",   _i];
        //One variable per member, named by the aircraft: gen1On, gen2On, gen3On.
        _m set ["varName", format ["bmkhs_%1%2", _c get "variableName", _i + 1]];
        _producers pushBack _m;
    };

    if ((_c get "output") != "") then { _circuits set [_c get "output", 0] };
} forEach ("true" configClasses (_config >> "Producers"));

//Storage - accumulators, batteries. A producer that holds a charge, so it can
//supply before anything upstream is solved, and refills once something upstream is.
//  rechargedBy     circuit that refills it
//  spentBelow      value it stops discharging at
//  startedBy       what draws from it to start - names a COMPONENT, not a circuit
//  startDraw       fraction of full charge one start costs
//  drainSeconds    full to empty while discharging
//  rechargeSeconds empty to full once its recharge circuit is up
private _storage = [];
{
    private _c    = COMPONENT_FIELDS(_x);
    private _role = _c get "damageRole";

    _c set ["rechargedBy", getText   (_x >> "rechargedBy")];
    _c set ["spentBelow",  getNumber (_x >> "spentBelow")];
    _c set ["startedBy",   getText   (_x >> "startedBy")];
    _c set ["startDraw",   getNumber (_x >> "startDraw")];

    //Charge is a fraction, so a full-to-empty time converts straight to a rate.
    private _drainSecs    = getNumber (_x >> "drainSeconds");
    private _rechargeSecs = getNumber (_x >> "rechargeSeconds");
    _c set ["drainRate",  if (_drainSecs    > 0) then {1 / _drainSecs}    else {0}];
    _c set ["rampRate",   if (_rechargeSecs > 0) then {1 / _rechargeSecs} else {0}];

    private _count = if (_role == "") then {0} else {[_heli, _role] call bmkhs_fnc_damageCount};
    for "_i" from 0 to (_count - 1) do {
        private _m = +_c;
        _m set ["index",   _i];
        _m set ["varName", format ["bmkhs_%1%2", _c get "variableName", _i + 1]];
        _storage pushBack _m;
    };

    if ((_c get "output") != "") then { _circuits set [_c get "output", 0] };
} forEach ("true" configClasses (_config >> "Storage"));

//Consumers - things that need supply to work. suppliedBy is an OR: flight controls
//fed by primary AND utility keep working on either one alone.
private _consumers = [];
{
    private _c = createHashMapFromArray [
        ["variableName", getText  (_x >> "variableName")],
        ["suppliedBy",   getArray (_x >> "suppliedBy")],
        ["minValue",     getNumber(_x >> "minValue")]
    ];
    _c set ["varName", format ["bmkhs_%1", _c get "variableName"]];
    _consumers pushBack _c;

    { _circuits set [_x, 0] } forEach (_c get "suppliedBy");
} forEach ("true" configClasses (_config >> "Consumers"));

_heli setVariable ["bmkhs_sysProducers", _producers];
_heli setVariable ["bmkhs_sysStorage",   _storage];
_heli setVariable ["bmkhs_sysConsumers", _consumers];
_heli setVariable ["bmkhs_sysCircuits",  _circuits];

//An aircraft that declares no components is not an aircraft with failed systems -
//there is nothing to simulate. Consumers fall back to their own defaults, which is
//what keeps a no-hydraulics airframe flying rather than locking its controls.
_heli setVariable ["bmkhs_sysModelled", (count _producers) + (count _storage) > 0];
