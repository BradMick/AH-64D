/* ----------------------------------------------------------------------------
Function: fza_sfmplus_fnc_preston

Description:
    Preston Pilot AI module entry. Owns the machine pilot's control outputs and
    publishes them for fn_getInput to consume.

    Currently the hands (cyclic, fn_prestonPilot). The feet (auto-pedal) still
    live in fn_getInput and will move here.

    GATED OFF while the FMC holds are being tuned - see PRESTON_ENABLED below.

Parameters:
    _heli - The helicopter to get information from [Unit].

Returns:
    Nothing. Outputs are published as object variables:
        fza_sfmplus_prestonCycPitchOut / ...RollOut  - cyclic, or nil when idle
        fza_sfmplus_prestonActive                    - is Preston flying

Examples:
    ...

Author:
    BradMick
---------------------------------------------------------------------------- */
params ["_heli"];
#include "\fza_ah64_sfmplus\headers\core.hpp"

//DISABLED while the FMC holds are tuned. Remove the `false && ` to re-enable.
private _active = false && {fza_ah64_sfmplusRealismSetting != REALISTIC};

if (!_active) exitWith {
    //Idle: clear the flags so the readouts do not report Preston as flying.
    _heli setVariable ["fza_sfmplus_prestonActive",      false];
    _heli setVariable ["fza_sfmplus_prestonPitchActive", false];
    _heli setVariable ["fza_sfmplus_prestonRollActive",  false];
    _heli setVariable ["fza_sfmplus_prestonWPos",        0.0];
    _heli setVariable ["fza_sfmplus_prestonWVel",        0.0];
    _heli setVariable ["fza_sfmplus_prestonWAtt",        0.0];
};

_heli setVariable ["fza_sfmplus_prestonActive", true];

//HANDS - the cyclic. Reads the pilot's keys as commands and writes force-trim.
[_heli] call fza_sfmplus_fnc_prestonPilot;
