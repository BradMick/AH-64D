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
    private _fields = ["errSm","winT","cross","prevSgn","startMag","underT","settled"];
    {
        private _sk = format ["fza_sfmplus_step_%1_", _x];
        { _heli setVariable [_sk + _x, nil]; } forEach _fields;   // inner _x = field name
    } forEach ["sasPitch","sasRoll","sasYaw"];
    _heli setVariable ["fza_sfmplus_pidAuto_status", "SAS AUTO-TUNE: fly normally - watching pitch/roll/yaw"];
};
_heli setVariable ["fza_sfmplus_pidAuto_wasOn", _on];

if !(_on) exitWith {};

private _dt = _heli getVariable ["fza_sfmplus_deltaTime", 0.0];
if (_dt <= 0.0) exitWith {};

//Body rates (rad/s): [pitch, roll, yaw].
private _pqr = _heli getVariable ["fza_sfmplus_angVelModelSpace", [0,0,0]];

//Per-axis config for the CONTINUOUS grader: [band, evalWindow, upStep, downStep, gMin, gMax, settleTime]
//  band      - body rate (rad/s) below which the axis is "quiet" (~1.7 deg/s = 0.03 rad/s).
//  evalWindow- seconds of live signal graded per gain decision.
//  upStep/downStep - gentle up (x1.02), fast down (x0.92) so it backs off hard when oscillating.
//  gMin/gMax - safe SAS kp range. settleTime - continuous s under band to call it settled.
private _axes =
[
     ["sasPitch", (_pqr # 0), "fza_sfmplus_tune_sasPitch_kp", [0.03, 1.0, 1.02, 0.92, 0.02, 0.60, 3.0]]
    ,["sasRoll",  (_pqr # 1), "fza_sfmplus_tune_sasRoll_kp",  [0.03, 1.0, 1.02, 0.92, 0.02, 0.60, 3.0]]
    ,["sasYaw",   (_pqr # 2), "fza_sfmplus_tune_sasYaw_kp",   [0.03, 1.0, 1.02, 0.92, 0.05, 0.80, 3.0]]
];

//Run the passive step-tune engine for each axis this frame; collect a status line each.
private _statuses = [];
private _nSettled = 0;
{
    _x params ["_key", "_err", "_gainVar", "_cfg"];
    private _sk = format ["fza_sfmplus_step_%1_", _key];
    private _s  = [_heli, _sk, _gainVar, _err, _dt, _cfg, _key] call fza_sfmplus_fnc_tunerStepTune;
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
