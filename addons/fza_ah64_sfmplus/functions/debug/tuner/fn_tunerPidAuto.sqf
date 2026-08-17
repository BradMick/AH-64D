/* ----------------------------------------------------------------------------
Function: fza_sfmplus_fnc_tunerPidAuto

Description:
    PASSIVE SAS-damper auto-tuner. Tunes the three SAS rate-damper gains (pitch, roll, yaw)
    by WATCHING the aircraft while YOU FLY - it never touches the controls and never drives an
    axis toward instability (the old Ziegler-Nichols method did, which is why it was slow, scary
    and froze on yaw). Fly normally: give some inputs, make some turns, let gusts hit it. Each
    time an axis is disturbed, the passive step-response engine (fn_tunerStepTune) grades how
    the SAS damps it out and nudges that axis's gain up (sluggish) or down (overshoot). After a
    few clean recoveries the axis is marked SETTLED. All three axes tune concurrently.

    Tune the SAS FIRST; once it's settled, tune the holds (fn_tunerHoldAuto).

    Toggle with fza_sfmplus_tune_pidAutoOn. Per-axis status -> fza_sfmplus_pidAuto_status.

Parameters:
    _heli - The aircraft [Object].

Author:
    BradMick / Claude
---------------------------------------------------------------------------- */
params ["_heli"];

if (isNull _heli) exitWith {};

private _on   = _heli getVariable ["fza_sfmplus_tune_pidAutoOn", false];
private _wasOn = _heli getVariable ["fza_sfmplus_pidAuto_wasOn", false];

//Rising edge: reset every axis's step-tune state so a re-run starts fresh.
if (_on && !_wasOn) then {
    private _fields = ["stage","errSm","winT","cross","ampMax","prevSgn","startMag","underT","settled","Ku"];
    {
        private _sk = format ["fza_sfmplus_step_%1_", _x];
        { _heli setVariable [_sk + _x, nil]; } forEach _fields;   // inner _x = field name
    } forEach ["sasPitch","sasRoll","sasYaw"];
    _heli setVariable ["fza_sfmplus_pidAuto_status", "SAS AUTO-TUNE: staged P->D->I - fly normally"];
};
_heli setVariable ["fza_sfmplus_pidAuto_wasOn", _on];

if !(_on) exitWith {};

private _dt = _heli getVariable ["fza_sfmplus_deltaTime", 0.0];
if (_dt <= 0.0) exitWith {};

//Body rates (rad/s): [pitch, roll, yaw].
private _pqr = _heli getVariable ["fza_sfmplus_angVelModelSpace", [0,0,0]];

//Per-axis config for the STAGED P->D->I tuner. cfg = [band, evalWindow, kpStart, kpStep, kpMax,
//  kdStep, kdMax, kiStep, kiMax, oscAmp, settleTime]
//  band   - body rate (rad/s) below which the axis is "quiet" (~1.7 deg/s = 0.03 rad/s).
//  kpStart/kpStep/kpMax - P ramp: start, per-window step, ceiling.
//  kdStep/kdMax - D ramp (damps the oscillation P found). kiStep/kiMax - I ramp (zeros error);
//  SAS is a rate damper so I stays SMALL. oscAmp - amplitude (rad/s) that counts as oscillation.
//Each axis: [key, errorSignal, kpVar, kiVar, kdVar, cfg]
private _axes =
[
     ["sasPitch", (_pqr # 0), "fza_sfmplus_tune_sasPitch_kp", "fza_sfmplus_tune_sasPitch_ki", "fza_sfmplus_tune_sasPitch_kd", [0.03, 1.0, 0.02, 0.02, 0.60, 0.004, 0.10, 0.001, 0.02, 0.06, 3.0]]
    ,["sasRoll",  (_pqr # 1), "fza_sfmplus_tune_sasRoll_kp",  "fza_sfmplus_tune_sasRoll_ki",  "fza_sfmplus_tune_sasRoll_kd",  [0.03, 1.0, 0.02, 0.02, 0.60, 0.004, 0.10, 0.001, 0.02, 0.06, 3.0]]
    ,["sasYaw",   (_pqr # 2), "fza_sfmplus_tune_sasYaw_kp",   "fza_sfmplus_tune_sasYaw_ki",   "fza_sfmplus_tune_sasYaw_kd",   [0.03, 1.0, 0.05, 0.02, 0.80, 0.005, 0.10, 0.002, 0.05, 0.06, 3.0]]
];

//Run the staged PID tuner for each axis this frame; collect a status line each.
private _statuses = [];
private _nSettled = 0;
{
    _x params ["_key", "_err", "_kpVar", "_kiVar", "_kdVar", "_cfg"];
    private _sk = format ["fza_sfmplus_step_%1_", _key];
    private _s  = [_heli, _sk, _kpVar, _kiVar, _kdVar, _err, _dt, _cfg, _key] call fza_sfmplus_fnc_tunerStepTune;
    _statuses pushBack _s;
    if (_heli getVariable [_sk + "settled", false]) then { _nSettled = _nSettled + 1; };
} forEach _axes;

//All three settled? Announce COMPLETE (unmistakable: status + hint + tone) and turn off.
if (_nSettled >= (count _axes)) exitWith {
    _heli setVariable ["fza_sfmplus_pidAuto_status", "SAS AUTO-TUNE ** COMPLETE ** (all axes settled) - now run the HOLD tuner"];
    _heli setVariable ["fza_sfmplus_tune_pidAutoOn", false];
    if (_heli == vehicle player) then {
        hintSilent parseText "<t size='1.5' font='EtelkaMonospacePro' color='#66ff66'>SAS Auto-Tune COMPLETE</t><br/><t size='1.0' color='#cccccc'>All axes settled - now run the HOLD tuner</t>";
    };
    [_heli] spawn fza_audio_fnc_flightTone;
};

//Live status: show all three axes so you can see which are still adjusting vs settled.
_heli setVariable ["fza_sfmplus_pidAuto_status", format ["SAS  %1   |   %2   |   %3", _statuses # 0, _statuses # 1, _statuses # 2]];
