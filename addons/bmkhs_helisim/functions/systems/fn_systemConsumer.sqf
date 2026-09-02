/* ----------------------------------------------------------------------------
Function: bmkhs_fnc_systemConsumer

Description:
    Answers, for everything that needs supply, whether it has any.

    suppliedBy is an OR over circuits: flight controls fed by primary AND
    utility keep working on either one alone, so losing one side is a
    degradation rather than a loss of control. Something that names a single
    circuit dies with that circuit - which is how selective failure falls out
    of the declarations instead of an if-chain naming this airframe's plumbing.

    Core publishes whether each consumer is supplied. What that MEANS is the
    aircraft's business: Core says the primary circuit is at 0 PSI, the
    aircraft decides whether that is worth a caution and whether it is
    expected on the ground.

Parameters:
    _heli - The helicopter [Object]

Returns:
    Nothing

Author:
    BradMick
---------------------------------------------------------------------------- */
params ["_heli"];

private _consumers = _heli getVariable ["bmkhs_sysConsumers", []];
if (_consumers isEqualTo []) exitWith {};

{
    private _min = _x get "minValue";

    //Any one of them is enough.
    private _supplied = false;
    {
        if (([_heli, _x] call bmkhs_fnc_systemCircuit) >= _min) exitWith { _supplied = true };
    } forEach (_x get "suppliedBy");

    _heli setVariable [_x get "varName", _supplied];
} forEach _consumers;
