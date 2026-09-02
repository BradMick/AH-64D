/* ----------------------------------------------------------------------------
Function: bmkhs_fnc_systemCircuit

Description:
    What value a circuit is carrying, in whatever unit its domain uses - PSI,
    volts, RPM as a fraction. A circuit is a named node; it has no behaviour of
    its own beyond holding what its feeders put there.

    Several feeders on one node take the HIGHEST value rather than summing.
    Two pumps on one circuit give 3000 PSI, not 6000, and a failed one is
    simply outvoted by a healthy one. Capacity and load are deliberately not
    modelled - this is a behaviour replica, not a plant simulator.

Parameters:
    _heli    - The helicopter [Object]
    _circuit - Circuit name, as declared by whatever feeds or reads it [String]

Returns:
    The circuit's value, or 0 if nothing feeds it [Number]

Examples:
    [_heli, "UTIL_HYD"] call bmkhs_fnc_systemCircuit

Author:
    BradMick
---------------------------------------------------------------------------- */
params ["_heli", "_circuit"];

if (_circuit == "") exitWith {0};

(_heli getVariable ["bmkhs_sysCircuits", createHashMap]) getOrDefault [_circuit, 0]
