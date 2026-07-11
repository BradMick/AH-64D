/* ----------------------------------------------------------------------------
Function: fza_sfmplus_fnc_tunerVariables

Description:
    Single source of truth for the in-game flight model tuner. Builds and returns
    an ordered specification of every tuneable parameter. The apply logic, GUI
    generation, persistence and clipboard export all iterate this same spec so
    that sliders, defaults and exported code can never drift apart.

    Each spec entry is a HashMap with the following keys:
        tab       - the major section / selectable tab the parameter lives in.
                    The GUI shows one tab bar of the distinct tabs (in first-seen
                    order) and only builds rows for the active tab.
        key       - unique identifier used as the profileNamespace / values map key
        label     - human readable label shown in the GUI
        group     - sub-heading shown within the tab (rows sharing a group are
                    printed under one header). Often equal to the tab name.
        type      - one of:
                        "scalar"    - a numeric value applied to a heli variable
                        "bool"      - a checkbox flag applied to a heli variable
                        "dragtable" - one row of an airspeed/altitude-indexed table;
                                      apply rebuilds the whole [[band,value],...]
                                      table variable from all of its rows
        default   - the established mod value (GUI + apply fall back to this)
        min, max  - slider range. For scalar params this is default +/- 100%
                    (i.e. [0, default * 2]) unless an explicit range is supplied
                    for values that are zero-defaulted or may go negative.
        target    - where fnc_tunerApply writes the value:
                        scalar / bool : the heli variable name to setVariable
                        dragtable     : [tableVar, rowIndex, band]
        export    - descriptor used by fnc_tunerExport to emit a paste-ready line:
                        [sourceFile, codeTemplate]  (see fn_tunerExport.sqf)

Parameters:
    None.

Returns:
    Array of spec entry HashMaps, in display order.

Author:
    BradMick
---------------------------------------------------------------------------- */

// Helper: build a spec entry. Missing min/max default to +/- 100% of default.
private _fnMake = {
    params ["_tab", "_key", "_label", "_group", "_type", "_default", "_target", "_export", ["_min", nil], ["_max", nil]];

    //Auto range is default +/- 100%. When the default is exactly zero that
    //collapses to [0,0] and the slider would be unusable, so fall back to a
    //small positive range (suits near-zero PID gains). Params that legitimately
    //default to zero with a wider useful range (CoM offset, PA) pass explicit
    //min/max instead.
    //Only meaningful for numeric (scalar / pid) defaults; bool defaults have no
    //slider range, so guard against arithmetic on a Boolean.
    if (_default isEqualType 0) then {
        if (isNil "_min") then {
            _min = if (_default == 0) then { 0 } else { 0 min (_default * 2) };
        };
        if (isNil "_max") then {
            _max = if (_default == 0) then { 0.01 } else { 0 max (_default * 2) };
        };
    } else {
        if (isNil "_min") then { _min = 0 };
        if (isNil "_max") then { _max = 0 };
    };

    createHashMapFromArray
    [
        ["tab",     _tab],
        ["key",     _key],
        ["label",   _label],
        ["group",   _group],
        ["type",    _type],
        ["default", _default],
        ["min",     _min],
        ["max",     _max],
        ["target",  _target],
        ["export",  _export]
    ];
};

private _spec = [];

/////////////////////////////////////////////////////////////////////////////
// TAB: Airframe
// Fuselage drag is table-based: the Front and Side drag coefficient tables map
// pressure altitude -> CD. Expose each CD value per PA band so the whole drag
// curve can be shaped (a single scalar would be too blunt). Defaults mirror the
// config tables in fza_ah64_controls\config\cfgVehicles\sfmplus.hpp.
// (The Top surface uses the shared airfoilTable01 NACA data and is not tuned.)
// type "dragtable" target: [tableVariableName, rowIndex]; the value is the CD
// for that row. fnc_tunerApply rebuilds the table variable from all rows.
/////////////////////////////////////////////////////////////////////////////
private _dragBands   = [0, 2000, 4000, 6000, 8000];               // ft PA
private _frontDragCD = [0.200, 0.270, 0.300, 0.520, 0.750];
private _sideDragCD  = [0.200, 0.270, 0.300, 0.520, 0.750];

{
    private _band = _x;
    private _cd   = _frontDragCD select _forEachIndex;
    _spec pushBack ([
        "Airframe",
        format ["fza_sfmplus_tune_dragFront_%1", _band],
        format ["Front CD @ %1 ft", _band],
        "Front Drag (CD by alt)",
        "dragtable",
        _cd,
        ["fza_sfmplus_fuselageFrontDragCoefTable", _forEachIndex, _band],
        ["sfmplus.hpp", format ["// fuselageFrontDragCoefTable row %1 (PA %2): %3", _forEachIndex, _band, "%1"]]
    ] call _fnMake);
} forEach _dragBands;

{
    private _band = _x;
    private _cd   = _sideDragCD select _forEachIndex;
    _spec pushBack ([
        "Airframe",
        format ["fza_sfmplus_tune_dragSide_%1", _band],
        format ["Side CD @ %1 ft", _band],
        "Side Drag (CD by alt)",
        "dragtable",
        _cd,
        ["fza_sfmplus_fuselageSideDragCoefTable", _forEachIndex, _band],
        ["sfmplus.hpp", format ["// fuselageSideDragCoefTable row %1 (PA %2): %3", _forEachIndex, _band, "%1"]]
    ] call _fnMake);
} forEach _dragBands;

// Fuselage side-force scalar by AIRSPEED band. The fuselage produces a physical
// side force (and yaw moment) when flying crabbed; this scalar shapes how much,
// per airspeed, so the tail-trim requirement is realistic. Uses the same
// "dragtable" mechanism (rebuilds a [[band,value],...] table), keyed on the 9
// airspeed bands (m/s). Default 1.0. Reuses fza_sfmplus_tune_fuseSideScalarTable
// which fn_fuselageSide.sqf reads and the write-back exports/persists.
private _spdBands = [0.00, 10.29, 20.58, 36.01, 46.30, 51.44, 61.73, 66.88, 72.02];
{
    private _band = _x;
    _spec pushBack ([
        "Airframe",
        format ["fza_sfmplus_tune_fuseSide_%1", _band],
        format ["Fuse side @ %1 kt", round (_band * 1.94384)],
        "Fuselage Side-Force (by airspeed)",
        "dragtable",
        1.0,
        ["fza_sfmplus_tune_fuseSideScalarTable", _forEachIndex, _band],
        ["fn_fuselageSide.sqf", format ["// fuseSideScalarTable row %1 (%2 m/s): %3", _forEachIndex, _band, "%1"]],
        0.0, 3.0
    ] call _fnMake);
} forEach _spdBands;

// Vertical FIN lift scalar by AIRSPEED band. At cruise the fin weathervanes and
// should carry most of the anti-torque, offloading the tail rotor; boosting this
// per airspeed lets the fin produce more yaw authority so the tail isn't pinned
// at max. Default 1.0. fn_coreUpdateFlightModel passes this table into fn_wing for
// the "Vertical Fin" surface; the write-back exports/persists it.
{
    private _band = _x;
    _spec pushBack ([
        "Airframe",
        format ["fza_sfmplus_tune_fin_%1", _band],
        format ["Fin lift @ %1 kt", round (_band * 1.94384)],
        "Vertical Fin Lift (by airspeed)",
        "dragtable",
        1.0,
        ["fza_sfmplus_tune_finLiftScalarTable", _forEachIndex, _band],
        ["fn_coreUpdateFlightModel.sqf", format ["// finLiftScalarTable row %1 (%2 m/s): %3", _forEachIndex, _band, "%1"]],
        0.0, 3.0
    ] call _fnMake);
} forEach _spdBands;

// STABILATOR lift scalar by AIRSPEED band. Shapes how much download/lift the
// stabilator carries per airspeed, setting the pitch trim. The master (PITCH axis)
// drives this so the aircraft holds the target pitch attitude at the flight-test
// cyclic position; you can also hand-edit it here. Default 1.0. fn_coreUpdateFlightModel
// passes fza_sfmplus_tune_stabLiftScalarTable into the stabilator surface; write-back
// exports/persists.
{
    private _band = _x;
    _spec pushBack ([
        "Airframe",
        format ["fza_sfmplus_tune_stabLift_%1", _band],
        format ["Stab lift @ %1 kt", round (_band * 1.94384)],
        "Stabilator Lift (by airspeed)",
        "dragtable",
        1.0,
        ["fza_sfmplus_tune_stabLiftScalarTable", _forEachIndex, _band],
        ["fn_coreUpdateFlightModel.sqf", format ["// stabLiftScalarTable row %1 (%2 m/s): %3", _forEachIndex, _band, "%1"]],
        0.2, 3.0
    ] call _fnMake);
} forEach _spdBands;

// RETREATING BLADE STALL pitch/roll AUTHORITY by airspeed (in pilot-cyclic input units).
// How much nose-up pitch + roll RBS commands at each airspeed; multiplied by the RBS
// SEVERITY (airspeed + collective) and added to the pilot moment via the same pitch/roll
// torque - so pilot authority is untouched but progressively overpowered by RBS. Signed:
// pitch + = nose DOWN (nose-up RBS is NEGATIVE), roll + = RIGHT roll (left-roll RBS is
// NEGATIVE - AH-64 RBS rolls left toward the retreating blade). Bands extend past the
// standard 9 to 160/180/200 kt where RBS really bites. fn_simpleRotorMain reads
// fza_sfmplus_tune_rbsPitchTable / _rbsRollTable; write-back exports/persists.
private _rbsBands = [0.00, 10.29, 20.58, 36.01, 46.30, 51.44, 61.73, 66.88, 72.02, 82.30, 92.59, 102.88];
private _rbsPitchDef = [0,0,0,0,0,0,0,0,0,-0.10,-0.30,-0.60];
private _rbsRollDef  = [0,0,0,0,0,0,0,0,0,-0.20,-0.60,-1.20];
{
    private _band = _x;
    _spec pushBack ([
        "Airframe",
        format ["fza_sfmplus_tune_rbsPitch_%1", _band],
        format ["RBS pitch @ %1 kt", round (_band * 1.94384)],
        "Retreating Blade Stall - Pitch (by airspeed)",
        "dragtable",
        _rbsPitchDef select _forEachIndex,
        ["fza_sfmplus_tune_rbsPitchTable", _forEachIndex, _band],
        ["fn_simpleRotorMain.sqf", format ["// rbsPitchTable row %1 (%2 m/s): %3", _forEachIndex, _band, "%1"]],
        -3.0, 3.0
    ] call _fnMake);
} forEach _rbsBands;
{
    private _band = _x;
    _spec pushBack ([
        "Airframe",
        format ["fza_sfmplus_tune_rbsRoll_%1", _band],
        format ["RBS roll @ %1 kt", round (_band * 1.94384)],
        "Retreating Blade Stall - Roll (by airspeed)",
        "dragtable",
        _rbsRollDef select _forEachIndex,
        ["fza_sfmplus_tune_rbsRollTable", _forEachIndex, _band],
        ["fn_simpleRotorMain.sqf", format ["// rbsRollTable row %1 (%2 m/s): %3", _forEachIndex, _band, "%1"]],
        -3.0, 3.0
    ] call _fnMake);
} forEach _rbsBands;

// MAIN ROTOR THRUST scalar by AIRSPEED band. Calibrates rotor thrust to the real
// power-required schedule so holding the target collective yields level flight
// (climb -> 0). The master (VERT axis) drives this in forward flight; hover uses the
// separate IGE/OGE hover-thrust vars below. Default 1.0. fn_simpleRotorMain reads
// fza_sfmplus_tune_mainThrustTable; write-back exports/persists.
{
    private _band = _x;
    _spec pushBack ([
        "Airframe",
        format ["fza_sfmplus_tune_mainThrust_%1", _band],
        format ["Main thrust @ %1 kt", round (_band * 1.94384)],
        "Main Rotor Thrust (by airspeed)",
        "dragtable",
        1.0,
        ["fza_sfmplus_tune_mainThrustTable", _forEachIndex, _band],
        ["fn_simpleRotorMain.sqf", format ["// mainThrustTable row %1 (%2 m/s): %3", _forEachIndex, _band, "%1"]],
        0.5, 1.5
    ] call _fnMake);
} forEach _spdBands;

// TAIL ROTOR THRUST scalar by AIRSPEED band. Sets anti-torque authority so the NET
// yaw moment balances at the flight-test pedal position. The master (YAW axis) drives
// this to null the net yaw moment (torque is a fixed hover-set reference; fin is hand-
// tuned). Default 1.0, wide range up to 10 (the tail carries the full correction in
// forward flight). fn_simpleRotorTail reads fza_sfmplus_tune_tailThrustTable.
{
    private _band = _x;
    _spec pushBack ([
        "Airframe",
        format ["fza_sfmplus_tune_tailThrust_%1", _band],
        format ["Tail thrust @ %1 kt", round (_band * 1.94384)],
        "Tail Rotor Thrust (by airspeed)",
        "dragtable",
        1.0,
        ["fza_sfmplus_tune_tailThrustTable", _forEachIndex, _band],
        ["fn_simpleRotorTail.sqf", format ["// tailThrustTable row %1 (%2 m/s): %3", _forEachIndex, _band, "%1"]],
        0.25, 10.0
    ] call _fnMake);
} forEach _spdBands;

// MAIN ROTOR TORQUE scalar by AIRSPEED band. Scales the main-rotor reaction torque
// (the yaw the tail must counter). The master (YAW axis) trims this slowly alongside
// tail thrust to drive the NET yaw moment -> 0. Default 1.0. fn_simpleRotorMain reads
// fza_sfmplus_tune_rtrTqScalarTable; write-back exports/persists.
{
    private _band = _x;
    _spec pushBack ([
        "Airframe",
        format ["fza_sfmplus_tune_rtrTq_%1", _band],
        format ["Torque @ %1 kt", round (_band * 1.94384)],
        "Main Rotor Torque (by airspeed)",
        "dragtable",
        1.0,
        ["fza_sfmplus_tune_rtrTqScalarTable", _forEachIndex, _band],
        ["fn_simpleRotorMain.sqf", format ["// rtrTqScalarTable row %1 (%2 m/s): %3", _forEachIndex, _band, "%1"]],
        0.5, 1.5
    ] call _fnMake);
} forEach _spdBands;

// HOVER thrust + target collective for IGE (in ground effect, ~5 ft) and OGE (out
// of ground effect, ~80 ft). Airspeed banding can't tell IGE/OGE apart (both 0 kt),
// so hover thrust is tuned per-height-state. The master tunes igeThrust/ogeThrust
// so the aircraft holds level at the matching target collective; fn_simpleRotorMain
// blends these two by AGL height in hover. Coll targets are the level-flight coll.
_spec pushBack (["Airframe", "fza_sfmplus_tune_igeThrust", "IGE Hover Thrust (5 ft)", "Hover (IGE / OGE)", "scalar",
    1.0, "fza_sfmplus_tune_igeThrust",
    ["fn_simpleRotorMain.sqf", "// IGE hover thrust scalar: %1"], 0.5, 1.5] call _fnMake);
_spec pushBack (["Airframe", "fza_sfmplus_tune_ogeThrust", "OGE Hover Thrust (80 ft)", "Hover (IGE / OGE)", "scalar",
    1.0, "fza_sfmplus_tune_ogeThrust",
    ["fn_simpleRotorMain.sqf", "// OGE hover thrust scalar: %1"], 0.5, 1.5] call _fnMake);
_spec pushBack (["Airframe", "fza_sfmplus_tune_igeColl", "IGE Hover Target Coll (5 ft)", "Hover (IGE / OGE)", "scalar",
    0.555, "fza_sfmplus_tune_igeColl",
    ["fn_tunerMaster.sqf", "// IGE hover target collective: %1"], 0.0, 1.0] call _fnMake);
_spec pushBack (["Airframe", "fza_sfmplus_tune_ogeColl", "OGE Hover Target Coll (80 ft)", "Hover (IGE / OGE)", "scalar",
    0.640, "fza_sfmplus_tune_ogeColl",
    ["fn_tunerMaster.sqf", "// OGE hover target collective: %1"], 0.0, 1.0] call _fnMake);
// Hover CONTROL-POSITION targets (where to put the cyclic/pedal at the hover). The
// master drives the controls to these when the matching hover-tune toggle is on, and
// tunes tail + main thrust to trim there. Arma: cyc fwd+/left+, pedal right+ [-1..1].
_spec pushBack (["Airframe", "fza_sfmplus_tune_igeCycPitch", "IGE Cyclic Pitch (fwd+)", "Hover (IGE / OGE)", "scalar",
    -0.342, "fza_sfmplus_tune_igeCycPitch",
    ["fn_tunerMaster.sqf", "// IGE hover cyclic pitch: %1"], -1.0, 1.0] call _fnMake);
_spec pushBack (["Airframe", "fza_sfmplus_tune_igeCycRoll", "IGE Cyclic Roll (left+)", "Hover (IGE / OGE)", "scalar",
    -0.045, "fza_sfmplus_tune_igeCycRoll",
    ["fn_tunerMaster.sqf", "// IGE hover cyclic roll: %1"], -1.0, 1.0] call _fnMake);
_spec pushBack (["Airframe", "fza_sfmplus_tune_igePedal", "IGE Pedal (right+)", "Hover (IGE / OGE)", "scalar",
    -0.352, "fza_sfmplus_tune_igePedal",
    ["fn_tunerMaster.sqf", "// IGE hover pedal: %1"], -1.0, 1.0] call _fnMake);
_spec pushBack (["Airframe", "fza_sfmplus_tune_ogeCycPitch", "OGE Cyclic Pitch (fwd+)", "Hover (IGE / OGE)", "scalar",
    -0.342, "fza_sfmplus_tune_ogeCycPitch",
    ["fn_tunerMaster.sqf", "// OGE hover cyclic pitch: %1"], -1.0, 1.0] call _fnMake);
_spec pushBack (["Airframe", "fza_sfmplus_tune_ogeCycRoll", "OGE Cyclic Roll (left+)", "Hover (IGE / OGE)", "scalar",
    -0.045, "fza_sfmplus_tune_ogeCycRoll",
    ["fn_tunerMaster.sqf", "// OGE hover cyclic roll: %1"], -1.0, 1.0] call _fnMake);
_spec pushBack (["Airframe", "fza_sfmplus_tune_ogePedal", "OGE Pedal (right+)", "Hover (IGE / OGE)", "scalar",
    -0.352, "fza_sfmplus_tune_ogePedal",
    ["fn_tunerMaster.sqf", "// OGE hover pedal: %1"], -1.0, 1.0] call _fnMake);

// Target ROLL attitude (deg, + = right wing down) by AIRSPEED band. This is the
// roll angle the aircraft should hold at each speed - dial it in per band to
// balance the lateral trim. Reuses fza_sfmplus_tune_targetRollTable (seeded by
// fn_tunerTargets); shown on the Balance tab next to the pitch/roll readout.
// Defaults mirror fn_tunerTargets. Range covers a few degrees each way.
private _rollTgtDef = [-2.5, -2.0, -1.0, -0.6, -0.6, -0.6, -0.6, -0.6, -0.6];
{
    private _band = _x;
    _spec pushBack ([
        "Balance",
        format ["fza_sfmplus_tune_tgtRoll_%1", _band],
        format ["Roll tgt @ %1 kt", round (_band * 1.94384)],
        "Target Roll (deg, + = right wing down)",
        "dragtable",
        (_rollTgtDef select _forEachIndex),
        ["fza_sfmplus_tune_targetRollTable", _forEachIndex, _band],
        ["fn_tunerTargets.sqf", format ["// targetRollTable row %1 (%2 m/s): %3", _forEachIndex, _band, "%1"]],
        -8.0, 8.0
    ] call _fnMake);
} forEach _spdBands;

// CONTROL-POSITION targets (real flight-test data, normalised to Arma). The master
// commands these exact cyclic/pedal positions and tunes the forces until the
// aircraft is trimmed at them. Editable per band. Arma: cyclic fwd+/left+, pedal
// right+ [-1..1]. Defaults from fn_tunerTargets (the flight-test schedule).
private _cycPitchDef = [-0.342,-0.271,-0.250,-0.121,-0.013, 0.057, 0.227, 0.321, 0.415];
private _cycRollDef  = [-0.045, 0.142, 0.133, 0.048, 0.013, 0.006, 0.015, 0.031, 0.052];
private _pedalDef    = [-0.352,-0.154, 0.044, 0.199, 0.250, 0.246, 0.152, 0.085, 0.015];
{
    private _band = _x;
    _spec pushBack (["Balance", format ["fza_sfmplus_tune_tgtCycP_%1", _band],
        format ["Cyc pitch tgt @ %1 kt", round (_band * 1.94384)], "Target Cyclic PITCH (fwd+)", "dragtable",
        (_cycPitchDef select _forEachIndex),
        ["fza_sfmplus_tune_targetCycPitchTable", _forEachIndex, _band],
        ["fn_tunerTargets.sqf", format ["// targetCycPitchTable row %1 (%2 m/s): %3", _forEachIndex, _band, "%1"]],
        -1.0, 1.0] call _fnMake);
} forEach _spdBands;
{
    private _band = _x;
    _spec pushBack (["Balance", format ["fza_sfmplus_tune_tgtCycR_%1", _band],
        format ["Cyc roll tgt @ %1 kt", round (_band * 1.94384)], "Target Cyclic ROLL (left+)", "dragtable",
        (_cycRollDef select _forEachIndex),
        ["fza_sfmplus_tune_targetCycRollTable", _forEachIndex, _band],
        ["fn_tunerTargets.sqf", format ["// targetCycRollTable row %1 (%2 m/s): %3", _forEachIndex, _band, "%1"]],
        -1.0, 1.0] call _fnMake);
} forEach _spdBands;
{
    private _band = _x;
    _spec pushBack (["Balance", format ["fza_sfmplus_tune_tgtPed_%1", _band],
        format ["Pedal tgt @ %1 kt", round (_band * 1.94384)], "Target PEDAL (right+)", "dragtable",
        (_pedalDef select _forEachIndex),
        ["fza_sfmplus_tune_targetPedalTable", _forEachIndex, _band],
        ["fn_tunerTargets.sqf", format ["// targetPedalTable row %1 (%2 m/s): %3", _forEachIndex, _band, "%1"]],
        -1.0, 1.0] call _fnMake);
} forEach _spdBands;

/////////////////////////////////////////////////////////////////////////////
// TAB: Mass & Balance
/////////////////////////////////////////////////////////////////////////////
// Center of mass offsets are applied additively on top of the computed CoM.
// Defaults are 0.0; use an explicit +/- range (metres) since default is zero.
_spec pushBack (["Mass & Balance", "fza_sfmplus_tune_comOffsetX", "CoM Offset X (lat, m)", "Center of Mass", "scalar",
    0.0, "fza_sfmplus_tune_comOffsetX",
    ["fn_massUpdate.sqf", "// CoM X offset: %1"], -1.0, 1.0] call _fnMake);
_spec pushBack (["Mass & Balance", "fza_sfmplus_tune_comOffsetY", "CoM Offset Y (long, m)", "Center of Mass", "scalar",
    0.0, "fza_sfmplus_tune_comOffsetY",
    ["fn_massUpdate.sqf", "// CoM Y offset: %1"], -1.0, 1.0] call _fnMake);
_spec pushBack (["Mass & Balance", "fza_sfmplus_tune_comOffsetZ", "CoM Offset Z (vert, m)", "Center of Mass", "scalar",
    0.0, "fza_sfmplus_tune_comOffsetZ",
    ["fn_massUpdate.sqf", "// CoM Z offset: %1"], -1.0, 1.0] call _fnMake);

// Gross weight override: a checkbox flag plus the override value (kg).
_spec pushBack (["Mass & Balance", "fza_sfmplus_tune_gwtOverride", "Override Gross Weight", "Gross Weight", "bool",
    false, "fza_sfmplus_tune_gwtOverride",
    ["fn_massUpdate.sqf", "// GWT override enabled: %1"]] call _fnMake);
// Range covers empty-ish to overmax (kg). Default is a typical mid GWT (8165 kg).
_spec pushBack (["Mass & Balance", "fza_sfmplus_tune_gwtValue", "Gross Weight (kg)", "Gross Weight", "scalar",
    8165.0, "fza_sfmplus_tune_gwtValue",
    ["fn_massUpdate.sqf", "// GWT override value (kg): %1"], 4500.0, 10500.0] call _fnMake);

/////////////////////////////////////////////////////////////////////////////
// TAB: Environment
/////////////////////////////////////////////////////////////////////////////
_spec pushBack (["Environment", "fza_sfmplus_tune_paOverride", "Override Pressure Altitude", "Pressure Altitude", "bool",
    false, "fza_sfmplus_tune_paOverride",
    ["fn_environment.sqf", "// PA override enabled: %1"]] call _fnMake);
_spec pushBack (["Environment", "fza_sfmplus_tune_paValue", "Pressure Altitude (ft)", "Pressure Altitude", "scalar",
    0.0, "fza_sfmplus_tune_paValue",
    ["fn_environment.sqf", "// PA override value (ft): %1"], -1000.0, 15000.0] call _fnMake);
_spec pushBack (["Environment", "fza_sfmplus_tune_fatOverride", "Override Free Air Temp", "Free Air Temp", "bool",
    false, "fza_sfmplus_tune_fatOverride",
    ["fn_environment.sqf", "// FAT override enabled: %1"]] call _fnMake);
_spec pushBack (["Environment", "fza_sfmplus_tune_fatValue", "Free Air Temp (deg C)", "Free Air Temp", "scalar",
    15.0, "fza_sfmplus_tune_fatValue",
    ["fn_environment.sqf", "// FAT override value (C): %1"], -40.0, 55.0] call _fnMake);

// Wind override: when enabled, ignore the mission wind and use a fixed azimuth /
// speed for repeatable tuning. Speed 0 with the override on = "wind off".
// Direction is the azimuth the wind blows FROM (deg), matching windDir.
_spec pushBack (["Environment", "fza_sfmplus_tune_windOverride", "Override Wind", "Wind", "bool",
    false, "fza_sfmplus_tune_windOverride",
    ["fn_environment.sqf", "// wind override enabled: %1"]] call _fnMake);
_spec pushBack (["Environment", "fza_sfmplus_tune_windDirFrom", "Wind Direction (from, deg)", "Wind", "scalar",
    0.0, "fza_sfmplus_tune_windDirFrom",
    ["fn_environment.sqf", "// wind dir from (deg): %1"], 0.0, 360.0] call _fnMake);
_spec pushBack (["Environment", "fza_sfmplus_tune_windSpeedKts", "Wind Speed (kts)", "Wind", "scalar",
    0.0, "fza_sfmplus_tune_windSpeedKts",
    ["fn_environment.sqf", "// wind speed (kts): %1"], 0.0, 60.0] call _fnMake);

/////////////////////////////////////////////////////////////////////////////
// TAB: Balance
// The MASTER auto-tuner is the single automatic tuner. It tunes the force scalar
// tables (thrust / torque / tail / stab lift) against the target attitudes and
// owns yaw balance. This tab holds only its three controls: the on/off switch,
// the Raw-Airframe (stabilization-off) toggle it requires, and the commanded
// target speed it tunes against. The live per-generator forces + status are shown
// in the non-blocking overlay panel (bind "Toggle FM Tuner Overlay").
/////////////////////////////////////////////////////////////////////////////

// HOVER-tune mode: pick IGE or OGE to tune a hover (mutually exclusive; IGE wins if
// both on; both off = forward-flight tuning by airspeed band). When on, the tuner
// sequence is YAW -> VERT only (stabilator is NOT tuned at a hover) and it drives the
// controls to the matching ige*/oge* hover positions, then tunes tail + main thrust.
_spec pushBack (["Balance", "fza_sfmplus_tune_hoverIGE", "Hover Tune: IGE (5 ft)", "Master Auto-Tuner", "bool",
    false, "fza_sfmplus_tune_hoverIGE",
    ["(runtime toggle only)", "// hover-tune IGE: %1"]] call _fnMake);
_spec pushBack (["Balance", "fza_sfmplus_tune_hoverOGE", "Hover Tune: OGE (80 ft)", "Master Auto-Tuner", "bool",
    false, "fza_sfmplus_tune_hoverOGE",
    ["(runtime toggle only)", "// hover-tune OGE: %1"]] call _fnMake);

// Master auto-tuner on/off. When on it tunes the force scalar tables against the
// target attitudes/positions for the commanded speed band (or the hover state).
_spec pushBack (["Balance", "fza_sfmplus_tune_masterOn", "MASTER Auto-Tune (on/off)", "Master Auto-Tuner", "bool",
    false, "fza_sfmplus_tune_masterOn",
    ["(runtime toggle only)", "// master auto-tune enabled: %1"]] call _fnMake);
// Commanded target speed (kt). The tuner locks to the band nearest this speed and
// only tunes while you hold within ~+/-8 kt, so it never jumps bands or tunes on
// off-speed data. 0 = auto (tune the nearest band to your current speed).
_spec pushBack (["Balance", "fza_sfmplus_tune_masterTargetKt", "Target Speed (kt, 0=auto)", "Master Auto-Tuner", "scalar",
    0.0, "fza_sfmplus_tune_masterTargetKt",
    ["(runtime only)", "// master target speed kt: %1"], 0.0, 160.0] call _fnMake);

// Yaw-rate damping: when ON, the yaw tuner targets a small OPPOSING net moment
// proportional to the yaw rate (target = -k*yawRate) instead of net moment = 0.
// Nulling the moment alone stops yaw ACCELERATION but leaves a standing rate (a
// residual precession); this actively decays that rate to zero, then holds. Off =
// pure moment balancing (may leave a small standing yaw rate).
_spec pushBack (["Balance", "fza_sfmplus_tune_yawRateDamp", "Yaw-Rate Damping (kill precession)", "Master Auto-Tuner", "bool",
    false, "fza_sfmplus_tune_yawRateDamp",
    ["(runtime toggle only)", "// yaw-rate damping enabled: %1"]] call _fnMake);
// Yaw damper strength: Nm of opposing yaw torque per rad/s of yaw rate. Higher =
// faster precession decay (too high can overshoot/oscillate). Applied by
// fn_tunerYawDamper and logged as the "Yaw Damper" generator.
_spec pushBack (["Balance", "fza_sfmplus_tune_yawDampGain", "Yaw Damper Strength (Nm per rad/s)", "Master Auto-Tuner", "scalar",
    20000.0, "fza_sfmplus_tune_yawDampGain",
    ["fn_tunerYawDamper.sqf", "// yaw damper gain: %1"], 0.0, 80000.0] call _fnMake);

_spec
