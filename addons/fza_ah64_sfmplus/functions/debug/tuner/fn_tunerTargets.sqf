/* ----------------------------------------------------------------------------
Function: fza_sfmplus_fnc_tunerTargets

Description:
    Seeds and returns the TARGET ATTITUDE tables for the attitude-driven tuner:
    the pitch and roll angle (deg) the aircraft should hold at each airspeed band.
    These are the reference the (future) master auto-tuner drives the pitch/roll
    trim tables toward; for now they feed the attitude readout so pitch/roll can
    be hand-tuned to target.

    Bands (m/s) match the other airspeed tables:
        [0.00, 10.29, 20.58, 36.01, 46.30, 51.44, 61.73, 66.88, 72.02]
        (0, 20, 40, 70, 90, 100, 120, 130, 140 kt)

    Source arrays are the single source of truth: published into the live vars
    (fza_sfmplus_tune_targetPitchTable / _targetRollTable) when unset, so editing
    them here + reloading takes effect. Edit the pitch schedule to whatever the
    real AH-64 holds at each speed; roll target is 0 (wings level) by default.

Parameters:
    _heli - The aircraft [Object].

Returns:
    [targetPitchTable, targetRollTable, targetCollTable,
     targetCycPitchTable, targetCycRollTable, targetPedalTable]

Author:
    BradMick
---------------------------------------------------------------------------- */
params ["_heli"];

//Target PITCH (deg, + = nose up). Real AH-64 level-flight schedule (user data):
//  20kt +4, 40kt +3, 70kt +1, 90kt 0, 100kt -1, 120kt -3, 130kt -4, 140kt -5.
//Hover (0kt) extrapolated to ~+5 (deepest nose-up at low speed).
private _pitchTgt = _heli getVariable ["fza_sfmplus_tune_targetPitchTable", []];
if (_pitchTgt isEqualTo []) then {
    _pitchTgt =
    [
     [ 0.00,  0.0]   //   0 kt (extrapolated)
    ,[10.29, -1.0]// 4.0]   //  20 kt
    ,[20.58, -2.0]// 3.0]   //  40 kt
    ,[36.01, -3.0]// 1.0]   //  70 kt
    ,[46.30, -5.0]// 0.0]   //  90 kt
    ,[51.44, -6.0]//-1.0]   // 100 kt
    ,[61.73, -8.0]//-3.0]   // 120 kt
    ,[66.88, -9.0]//-4.0]   // 130 kt
    ,[72.02,-10.0]//-5.0]   // 140 kt
    ];
    _heli setVariable ["fza_sfmplus_tune_targetPitchTable", _pitchTgt];
};

//Target ROLL (deg, + = right wing down). Real AH-64 schedule (user data): right
//roll in the low-speed nose-to-tail trim (20kt +2, 40kt +1), wings level once
//coordinated from 70kt on. Hover (0kt) extrapolated to ~+2.5.
private _rollTgt = _heli getVariable ["fza_sfmplus_tune_targetRollTable", []];
if (_rollTgt isEqualTo []) then {
    _rollTgt =
    [
     [ 0.00, -2.5]   //   0 kt (extrapolated)
    ,[10.29, -2.0]   //  20 kt
    ,[20.58, -1.0]   //  40 kt
    ,[36.01, -0.6]   //  70 kt
    ,[46.30, -0.6]   //  90 kt
    ,[51.44, -0.6]   // 100 kt
    ,[61.73, -0.6]   // 120 kt
    ,[66.88, -0.6]   // 130 kt
    ,[72.02, -0.6]   // 140 kt
    ];
    _heli setVariable ["fza_sfmplus_tune_targetRollTable", _rollTgt];
};

//Target COLLECTIVE (0-1) for level flight vs airspeed. Real AH-64 flight-test
//control positions (18,000 lb, 8 Hellfire, 38 rockets, FCR): the power-required
//"bucket" - high in hover, min ~70 kt, climbing at high speed. 0 kt = OGE hover.
//The thrust calibration goal is: at THIS collective, the aircraft holds level.
private _collTgt = _heli getVariable ["fza_sfmplus_tune_targetCollTable", []];
if (_collTgt isEqualTo []) then {
    _collTgt =
    [
     [ 0.00, 0.637]   //   0 kt (OGE hover)
    ,[10.29, 0.612]   //  20 kt
    ,[20.58, 0.504]   //  40 kt
    ,[36.01, 0.450]   //  70 kt (min power)
    ,[46.30, 0.492]   //  90 kt
    ,[51.44, 0.532]   // 100 kt
    ,[61.73, 0.650]   // 120 kt
    ,[66.88, 0.724]   // 130 kt
    ,[72.02, 0.808]   // 140 kt
    ];
    _heli setVariable ["fza_sfmplus_tune_targetCollTable", _collTgt];
};

//--- CONTROL-POSITION targets (real flight-test data, normalised to Arma) --------
//The exact cyclic/pedal positions the real aircraft holds at each speed. The
//master COMMANDS these and tunes the forces until the aircraft is in equilibrium
//(zero rates/climb) at them. Arma convention: cyclic fwd+/left+ [-1..1], pedal
//right+ [-1..1]. 0 kt uses the 80 ft OGE hover positions.

//Cyclic PITCH position (fwd+).
private _cycPitchTgt = _heli getVariable ["fza_sfmplus_tune_targetCycPitchTable", []];
if (_cycPitchTgt isEqualTo []) then {
    //DEFLECTION from the Flat Pitch neutral index (survey abs - flatPitch). Flat Pitch
    //cyclic pitch = -0.27, so each survey value has +0.27 added -> true stick deflection
    //over -1..+1. This is what the tuner drives to (the cyclic offset from neutral), NOT
    //the old absolute survey position (which was referenced to a zero point that no longer
    //applies after the force-model rework). 0 kt = 80 ft OGE.
    _cycPitchTgt =
    [
     [ 0.00, -0.07]   //   0 kt (80 ft OGE hover)
    ,[10.29,  0.00]   //  20 kt
    ,[20.58,  0.02]   //  40 kt
    ,[36.01,  0.15]   //  70 kt
    ,[46.30,  0.26]   //  90 kt
    ,[51.44,  0.33]   // 100 kt
    ,[61.73,  0.50]   // 120 kt
    ,[66.88,  0.59]   // 130 kt
    ,[72.02,  0.68]   // 140 kt
    ];
    _heli setVariable ["fza_sfmplus_tune_targetCycPitchTable", _cycPitchTgt];
};

//Cyclic ROLL position (left+).
private _cycRollTgt = _heli getVariable ["fza_sfmplus_tune_targetCycRollTable", []];
if (_cycRollTgt isEqualTo []) then {
    //DEFLECTION from the Flat Pitch neutral index (survey abs - flatPitch). Flat Pitch
    //cyclic roll = -0.10, so each survey value has +0.10 added -> true stick deflection
    //(left+) over -1..+1. 0 kt = 80 ft OGE.
    _cycRollTgt =
    [
     [ 0.00,  0.06]   //   0 kt (80 ft OGE hover)
    ,[10.29,  0.24]   //  20 kt
    ,[20.58,  0.23]   //  40 kt
    ,[36.01,  0.15]   //  70 kt
    ,[46.30,  0.11]   //  90 kt
    ,[51.44,  0.11]   // 100 kt
    ,[61.73,  0.12]   // 120 kt
    ,[66.88,  0.13]   // 130 kt
    ,[72.02,  0.15]   // 140 kt
    ];
    _heli setVariable ["fza_sfmplus_tune_targetCycRollTable", _cycRollTgt];
};

//PEDAL position (right+).
private _pedalTgt = _heli getVariable ["fza_sfmplus_tune_targetPedalTable", []];
if (_pedalTgt isEqualTo []) then {
    _pedalTgt =
    [
     [ 0.00, -0.60]   //   0 kt (80 ft OGE hover)
    ,[10.29, -0.41]   //  20 kt
    ,[20.58, -0.21]   //  40 kt
    ,[36.01, -0.05]   //  70 kt
    ,[46.30,  0.00]   //  90 kt
    ,[51.44, -0.01]   // 100 kt
    ,[61.73, -0.10]   // 120 kt
    ,[66.88, -0.17]   // 130 kt
    ,[72.02, -0.01]   // 140 kt
    ];
    _heli setVariable ["fza_sfmplus_tune_targetPedalTable", _pedalTgt];
};

//--- HOVER control-position targets (IGE / OGE), EXPLICIT and SEPARATE ------------
//At a hover the airspeed bands can't distinguish ground effect, and the stabilator
//is inactive (no airflow), so hover is tuned as its own case: the pedal + cyclic go
//to these known positions, then tail-rotor thrust and main-rotor thrust are tuned.
//IGE (in ground effect, ~5 ft) needs LESS collective (more efficient rotor) than OGE
//(~80 ft). Each value is explicit and independently editable - set them to the real
//flight-test hover control positions. Arma convention: coll 0..1, cyc fwd+/left+,
//pedal right+ [-1..1]. Seeded from the OGE band-0 flight-test data; adjust IGE down.
private _fnHoverTgt = {
    params ["_var", "_default"];
    private _v = _heli getVariable [_var, -999];
    if (_v == -999) then { _v = _default; _heli setVariable [_var, _v]; };
    _v
};

//IGE hover (~5 ft): less collective in ground effect. Cyclic/pedal are DEFLECTION from Flat
//Pitch (same reference as the airspeed tables above), from the 5 ft IGE flight-test survey.
["fza_sfmplus_tune_igeColl",     0.56] call _fnHoverTgt;   // collective 0..1
["fza_sfmplus_tune_igeCycPitch",-0.07] call _fnHoverTgt;   // cyclic fwd+ (deflection)
["fza_sfmplus_tune_igeCycRoll",  0.03] call _fnHoverTgt;   // cyclic left+ (deflection)
["fza_sfmplus_tune_igePedal",   -0.49] call _fnHoverTgt;   // pedal right+ (deflection)

//OGE hover (~80 ft): the band-0 flight-test hover positions (80 ft OGE survey, deflection).
["fza_sfmplus_tune_ogeColl",     0.64] call _fnHoverTgt;   // collective 0..1
["fza_sfmplus_tune_ogeCycPitch",-0.07] call _fnHoverTgt;   // cyclic fwd+ (deflection)
["fza_sfmplus_tune_ogeCycRoll",  0.06] call _fnHoverTgt;   // cyclic left+ (deflection)
["fza_sfmplus_tune_ogePedal",   -0.60] call _fnHoverTgt;   // pedal right+ (deflection)

[_pitchTgt, _rollTgt, _collTgt, _cycPitchTgt, _cycRollTgt, _pedalTgt]
