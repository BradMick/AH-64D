/* ----------------------------------------------------------------------------
Function: fza_sfmplus_fnc_tunerHoldAuto

Description:
    PASSIVE HOLD PID auto-tuner. Same method + engine as the SAS tuner (fn_tunerStepTune):
    it WATCHES the aircraft while YOU FLY and grades how the active HOLD recovers from natural
    disturbances, nudging that submode's PID gains up (sluggish) or down (overshoot). It never
    touches the controls and never drives toward instability. Run the SAS tuner FIRST.

    The hold has THREE speed-scheduled submodes, each with its own PID that is only live in its
    own speed band, so this tuner grades whichever submode is LIVE at your current ground speed:
        position  ( < 5 kt )   -> tunes posPitch / posRoll (velocity loop)   error = velocity
        velocity  ( 5..40 kt ) -> same posPitch / posRoll                    error = velocity
        attitude  ( > 40 kt )  -> tunes attPitch / attRoll                   error = attitude vs hold ref
    Fly a hover to tune position, ~20 kt to tune velocity, > 40 kt to tune attitude. Both the
    pitch and roll gain of the live submode tune concurrently. The overlay shows per-axis state.

    Toggle with fza_sfmplus_tune_holdAutoOn. Status -> fza_sfmplus_pidAuto_status.

Parameters:
    _heli - The aircraft [Object].

Author:
    BradMick / Claude
---------------------------------------------------------------------------- */
#include "\fza_ah64_sfmplus\headers\core.hpp"
params ["_heli"];

if (isNull _heli) exitWith {};

private _on   = _heli getVariable ["fza_sfmplus_tune_holdAutoOn", false];
private _wasOn = _heli getVariable ["fza_sfmplus_holdAuto_wasOn", false];

if (_on && !_wasOn) then {
    //Reset every hold axis's step state so a re-run starts fresh.
    private _fields = ["errSm","winT","cross","prevSgn","startMag","underT","settled"];
    {
        private _sk = format ["fza_sfmplus_step_%1_", _x];
        { _heli setVariable [_sk + _x, nil]; } forEach _fields;   // inner _x = field name
    } forEach ["posPitch","posRoll","attPitch","attRoll"];
    _heli setVariable ["fza_sfmplus_pidAuto_status", "HOLD AUTO-TUNE: fly the regime you want to tune"];
};
_heli setVariable ["fza_sfmplus_holdAuto_wasOn", _on];

//Tuner off -> make sure the pos-hold outer loop is CLOSED (interlock released) for normal flight.
if !(_on) exitWith { _heli setVariable ["fza_sfmplus_holdAuto_openOuter", false]; };

//Never run alongside the SAS tuner (shared step state prefixes are distinct, but keep it clean).
if (_heli getVariable ["fza_sfmplus_tune_pidAutoOn", false]) exitWith {
    _heli setVariable ["fza_sfmplus_holdAuto_openOuter", false];
    _heli setVariable ["fza_sfmplus_pidAuto_status", "HOLD tuner waiting - SAS tuner is running"];
};

private _dt = _heli getVariable ["fza_sfmplus_deltaTime", 0.0];
if (_dt <= 0.0) exitWith {};

//Engage the stabilising holds so the hold loop is actually live to be graded.
if !(_heli getVariable ["fza_ah64_attHoldActive", false]) then {
    _heli setVariable ["fza_ah64_attHoldActive",    true, true];
    _heli setVariable ["fza_ah64_attHoldDesiredPos", getPos _heli, true];
    (_heli call BIS_fnc_getPitchBank) params ["_p0", "_r0"];
    _heli setVariable ["fza_ah64_attHoldDesiredAtt", [_p0, _r0], true];
};
if !(_heli getVariable ["fza_ah64_hdgHoldActive", false]) then {
    _heli setVariable ["fza_ah64_hdgHoldActive",     true, true];
    _heli setVariable ["fza_ah64_hdgHoldDesiredHdg", getDir _heli, true];
};

//Which submode is live right now (speed-scheduled by fn_fmcAttitudeHold).
private _sub = _heli getVariable ["fza_ah64_attHoldSubMode", "pos"];

//INTERLOCK: while grading the INNER velocity loop (pos/vel submode), OPEN the pos-hold outer
//loop so the tuner rings out pure velocity-to-zero and the outer position loop doesn't feed a
//moving setpoint that the tuner would misread. att submode has no outer loop -> leave it closed.
_heli setVariable ["fza_sfmplus_holdAuto_openOuter", (_sub != "att")];

//Build the two axes to grade + their error signals for this submode.
//  att : error = current attitude - captured hold attitude (deg).
//  pos/vel : error = model-space velocity (m/s) - the loop is nulling/holding velocity.
//cfg (continuous grader): [band, evalWindow, upStep, downStep, gMin, gMax, settleTime]
private _axes = switch (_sub) do {
    case "att": {
        (_heli call BIS_fnc_getPitchBank) params ["_curP", "_curR"];
        (_heli getVariable ["fza_ah64_attHoldDesiredAtt", [_curP, _curR]]) params ["_setP", "_setR"];
        private _ePitch = [_curP - _setP] call CBA_fnc_simplifyAngle180;
        private _eRoll  = [_curR - _setR] call CBA_fnc_simplifyAngle180;
        //cfg (continuous grader): [band(deg), evalWindow, upStep, downStep, gMin, gMax, settleTime]
        [
             ["attPitch", _ePitch, "fza_sfmplus_tune_attPitch_kp", [1.0, 1.5, 1.02, 0.92, 0.002, 0.20, 3.0]]
            ,["attRoll",  _eRoll,  "fza_sfmplus_tune_attRoll_kp",  [1.0, 1.5, 1.02, 0.92, 0.002, 0.20, 3.0]]
        ];
    };
    default {   // pos / vel - velocity loop (pid_pitch/pid_roll via posPitch/posRoll gains)
        private _vel = _heli getVariable ["fza_sfmplus_velModelSpaceNoWind", [0,0,0]];
        //cfg (continuous grader): [band(m/s), evalWindow, upStep, downStep, gMin, gMax, settleTime]
        //band 0.4 m/s ~= 0.8 kt = "stopped". Velocity is the error the loop is nulling.
        [
             ["posPitch", (_vel # 1), "fza_sfmplus_tune_posPitch_kp", [0.4, 1.5, 1.02, 0.92, 0.005, 0.20, 3.0]]
            ,["posRoll",  (_vel # 0), "fza_sfmplus_tune_posRoll_kp",  [0.4, 1.5, 1.02, 0.92, 0.005, 0.20, 3.0]]
        ];
    };
};

//Run the passive engine for both axes of the live submode; collect status + settled count.
private _statuses = [];
private _nSettled = 0;
{
    _x params ["_key", "_err", "_gainVar", "_cfg"];
    private _sk = format ["fza_sfmplus_step_%1_", _key];
    private _s  = [_heli, _sk, _gainVar, _err, _dt, _cfg, _key] call fza_sfmplus_fnc_tunerStepTune;
    _statuses pushBack _s;
    if (_heli getVariable [_sk + "settled", false]) then { _nSettled = _nSettled + 1; };
} forEach _axes;

//Both axes of this submode settled? COMPLETE for this regime (unmistakable), turn off.
if (_nSettled >= (count _axes)) exitWith {
    _heli setVariable ["fza_sfmplus_pidAuto_status",
        format ["HOLD AUTO-TUNE ** COMPLETE ** for '%1' submode - fly another regime + re-run", _sub]];
    _heli setVariable ["fza_sfmplus_tune_holdAutoOn", false];
    if (_heli == vehicle player) then {
        hintSilent parseText format ["<t size='1.5' font='EtelkaMonospacePro' color='#66ff66'>HOLD Auto-Tune COMPLETE</t><br/><t size='1.0' color='#cccccc'>Tuned the '%1' submode</t>", _sub];
    };
    [_heli] spawn fza_audio_fnc_flightTone;
};

_heli setVariable ["fza_sfmplus_pidAuto_status", format ["HOLD(%1)  %2   |   %3", _sub, _statuses # 0, _statuses # 1]];
