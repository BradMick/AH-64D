/* ----------------------------------------------------------------------------
Function: bmkhs_fnc_CoreUpdate

Description:
    Updates all of the modules core functions.

Parameters:
    _heli - The helicopter to get information from [Unit].

Returns:
    ...

Examples:
    ...

Author:
    BradMick
---------------------------------------------------------------------------- */
params ["_heli", "_deltaTime"];

//Update the Main Transmission
[_heli, _deltaTime] call bmkhs_fnc_drivetrainTransmission;
//Update the Tail Rotor Gearboxes
[_heli] call bmkhs_fnc_drivetrainTailRotorGearboxes;
//Update Nose Gearbox 1
[_heli, _deltaTime] call bmkhs_fnc_drivetrainNoseGearbox1;
//Update Nose Gearbox 2
[_heli, _deltaTime] call bmkhs_fnc_drivetrainNoseGearbox2;
