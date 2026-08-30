/* ----------------------------------------------------------------------------
Function: bmkhs_fnc_interactAPUButton

Description:
    Sets button state for the APU sim.

Parameters:
    _heli   - The helicopter to get information from [Unit].

Returns:
    Whether to register a click (boolean).

Examples:
    ...

Author:
    BradMick
---------------------------------------------------------------------------- */
params ["_heli"];

_heli setVariable ["bmkhs_apuBtnOn", !(_heli getVariable "bmkhs_apuBtnOn"), true];
