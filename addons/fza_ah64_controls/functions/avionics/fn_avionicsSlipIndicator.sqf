/* ----------------------------------------------------------------------------
Function: fza_fnc_avionicsSlipIndicator

Description:
    Updates *fza_ah64_dps* and *fza_ah64_sideslip* to be the degrees per second and slip for the respective helicopter.

    The first reading after switching helicopter / taking a reading for a while will always be inaccurate as these are both calculated as the difference between two readings of *direction*

Parameters:
    _heli - The apache helicopter to check.

Returns:
    Nothing

Examples:
    --- Code
    [_heli] call fza_fnc_avionicsSlipIndicator
    // fza_ah64_dps => 5
    // fza_ah64_sideslip => 3
    ---

Author:
    Unknown
---------------------------------------------------------------------------- */
params["_heli"];

if (!(player in _heli)) exitWith {};

private _beta_g = _heli getVariable "fza_sfmplus_aero_beta_g";

//Display sensitivity: the marker reaches FULL deflection (+-1) at beta_g = +-_fullScaleG.
//Larger = LESS sensitive (takes more lateral g to move the ball). Was 0.15 (full-scale at
//0.15 g), which over-reacted to small pedal inputs; 0.30 halves the sensitivity so it takes
//a real skid to peg and coordinated-flight jitter (~0.02-0.03 g) stays a subtle nudge.
private _fullScaleG = 0.30;
fza_ah64_sideslip = [_beta_g / _fullScaleG, -1.0, 1.0] call BIS_fnc_clamp;
