/* ----------------------------------------------------------------------------
Function: fza_sfmplus_fnc_tunerForceTables

Description:
    Single source of truth for the airspeed-indexed FORCE SCALAR TABLES that the
    master auto-tuner (fza_sfmplus_fnc_tunerMaster) writes live. These are NOT in
    the general tuner spec (fn_tunerVariables) because they are whole tables the
    master edits band-by-band, not single slider values - but they still need to
    be persisted and exported, or every tuning session evaporates on shutdown.

    Both fn_tunerSave (profileNamespace) and fn_tunerExport (clipboard) iterate
    this list so the write-back path can never drift from what the master tunes.

    Each entry is [variable, label, sourceFile, sourceHint]:
        variable   - the fza_sfmplus_tune_* heli variable the master writes / the
                     force function reads.
        label      - human-readable name for the export comment.
        sourceFile - the .sqf file whose source array this table should be pasted
                     back into (for the grouped export block).
        sourceHint - the local variable name in that file, so the export tells you
                     exactly what to replace.

    The band X-values (airspeed in m/s) are shared by every table and match the
    master's _bands and the source arrays in the force functions.

Parameters:
    None.

Returns:
    [_bands, _tables] where
        _bands  - array of band airspeeds (m/s)
        _tables - array of [variable, label, sourceFile, sourceHint] entries

Author:
    BradMick
---------------------------------------------------------------------------- */

private _bands =
[
     0.00
    ,10.29
    ,20.58
    ,36.01
    ,46.30
    ,51.44
    ,61.73
    ,66.88
    ,72.02
];

//Each entry: [variable, label, sourceFile, sourceHint, untunedBaseline]. The
//baseline is the "not tuned" value (1.0 for multiplier scalars, 0.0 for the
//additive disk-tilt table) so save/export can tell whether a table was changed.
private _tables =
[
     ["fza_sfmplus_tune_mainThrustTable",     "Main Rotor Thrust",  "fn_simpleRotorMain.sqf", "_rtrThrustScalarTable", 1.0]
    ,["fza_sfmplus_tune_rtrTqScalarTable",    "Main Rotor Torque",  "fn_simpleRotorMain.sqf", "_rtrTorqueScalarTable", 1.0]
    ,["fza_sfmplus_tune_tailThrustTable",     "Tail Rotor Thrust",  "fn_simpleRotorTail.sqf", "_rtrThrustScalarTable", 1.0]
    ,["fza_sfmplus_tune_stabLiftScalarTable", "Stabilator Lift",    "fn_coreUpdateFlightModel.sqf", "Stabilator lift-scalar arg", 1.0]
    ,["fza_sfmplus_tune_fuseSideScalarTable", "Fuselage Side-Force","fn_fuselageSide.sqf", "_sideForceScalarTable", 1.0]
    ,["fza_sfmplus_tune_finLiftScalarTable",  "Vertical Fin Lift",  "fn_coreUpdateFlightModel.sqf", "Vertical Fin lift-scalar arg", 1.0]
    ,["fza_sfmplus_tune_rotorTiltTable",       "Rotor Disk Roll-Tilt","fn_simpleRotorMain.sqf", "_rotorTiltTable", 0.0]
];

[_bands, _tables]
