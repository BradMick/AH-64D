/* ----------------------------------------------------------------------------
Function: bmkhs_fnc_systemConsumer

Description:
    Answers whether each consumer has supply. suppliedBy is an OR, so a
    consumer naming two circuits survives losing one and a consumer naming one
    dies with it - selective failure without Core knowing the plumbing.

    Core publishes the state; what it MEANS is the aircraft's business.

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
