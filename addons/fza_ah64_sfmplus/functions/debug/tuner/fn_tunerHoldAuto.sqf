/* ----------------------------------------------------------------------------
Function: fza_sfmplus_fnc_tunerHoldAuto

Description:
    PASSIVE HOLD PID auto-tuner. Run the SAS tuner FIRST (it tunes the innermost rate loop); this
    tunes the HOLD loop for whatever submode is LIVE at your ground speed. It never touches the
    controls and grades the LIVE error via the shared continuous engine (fn_tunerStepTune).

    WORKFLOW (fly each regime, tune the submode that's live there):
       HOVER   -> pos submode -> tunes POSITION: grade position error (m)  -> pos*_kp (vel-null gain)
       20-30kt -> vel submode -> tunes VELOCITY: grade velocity (m/s)      -> pos*_kp
       >40 kt  -> att submode -> tunes ATTITUDE: grade attitude error (deg)-> att*_kp

    LOCK the submode you're tuning with the submode-lock keybind (fza_ah64_attHoldSubModeLock) so a
    haywire moment + fly-back can't switch the submode out from under the tuner. Each submode tunes
    its own defining loop; the inner loops beneath it (SAS, and for pos the velocity/attitude layers)
    use their already-tuned gains, so tune inner regimes first (SAS -> position -> velocity -> att).

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

//Rising edge: reset step state for ALL hold axes so a re-run starts fresh.
if (_on && !_wasOn) then {
    private _fields = ["stage","errSm","winT","cross","ampMax","prevSgn","startMag","underT","settled","Ku"];
    {
        private _sk = format ["fza_sfmplus_step_%1_", _x];
        { _heli setVariable [_sk + _x, nil]; } forEach _fields;   // inner _x = field name
    } forEach ["attPitch","attRoll","posPitch","posRoll","posInt"];
    //posInt is an I-ONLY trim (kp/kd forced 0). Start it directly in the I stage so the engine ramps
    //ki (=posIntKp) against position drift instead of getting stuck in P with a forced-zero kp.
    _heli setVariable ["fza_sfmplus_step_posInt_stage", "I"];
    _heli setVariable ["fza_sfmplus_clampWinT", 0.0];
    _heli setVariable ["fza_sfmplus_pidAuto_status", "HOLD AUTO-TUNE: tuning the LIVE submode - lock it while you fly"];
};
_heli setVariable ["fza_sfmplus_holdAuto_wasOn", _on];

if !(_on) exitWith {};

//Never run alongside the SAS tuner.
if (_heli getVariable ["fza_sfmplus_tune_pidAutoOn", false]) exitWith {
    _heli setVariable ["fza_sfmplus_pidAuto_status", "HOLD tuner waiting - SAS tuner is running"];
};

private _dt = _heli getVariable ["fza_sfmplus_deltaTime", 0.0];
if (_dt <= 0.0) exitWith {};

//Engage the stabilising holds so the loops are actually live to be graded.
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

//Tune whatever submode is LIVE (lock it with the submode-lock keybind so it can't switch out from
//under you). Each submode tunes the SAME gains its hold loop actually uses, graded against that
//loop's error - matching fn_fmcAttitudeHold:
//   pos : VELOCITY (m/s) -> pos*_kp   (pid_pitch/pid_roll; the combined vel+pos loop, vel dominates)
//   vel : VELOCITY (m/s) -> pos*_kp   (same PID objects, captured-velocity setpoint)
//   att : ATTITUDE err (deg) -> att*_kp (pid_*_att)
//Gain ranges match the hold gain scale (pos* ~0.015-0.03, att* ~0.01-0.02 -> gMax ~0.3).
//cfg (continuous grader): [band, evalWindow, upStep, downStep, gMin, gMax, settleTime]
private _sub = _heli getVariable ["fza_ah64_attHoldSubMode", "pos"];

//Staged P->D->I cfg = [band, evalWindow, kpStart, kpStep, kpMax, kdStep, kdMax, kiStep, kiMax, oscAmp, settleTime]
//Each axis entry: [key, errorSignal, kpVar, kiVar, kdVar, cfg]
private _axes = switch (_sub) do {
    case "att": {   // attitude hold -> grade ATTITUDE error (deg)
        (_heli call BIS_fnc_getPitchBank) params ["_curP", "_curR"];
        (_heli getVariable ["fza_ah64_attHoldDesiredAtt", [_curP, _curR]]) params ["_setP", "_setR"];
        private _eP = [_curP - _setP] call CBA_fnc_simplifyAngle180;   // deg
        private _eR = [_curR - _setR] call CBA_fnc_simplifyAngle180;   // deg
        [
             ["attPitch", _eP, "fza_sfmplus_tune_attPitch_kp", "fza_sfmplus_tune_attPitch_ki", "fza_sfmplus_tune_attPitch_kd", [0.5, 1.5, 0.01, 0.01, 0.30, 0.002, 0.06, 0.0005, 0.02, 1.0, 3.0]]
            ,["attRoll",  _eR, "fza_sfmplus_tune_attRoll_kp",  "fza_sfmplus_tune_attRoll_ki",  "fza_sfmplus_tune_attRoll_kd",  [0.5, 1.5, 0.01, 0.01, 0.30, 0.002, 0.06, 0.0005, 0.02, 1.0, 3.0]]
        ];
    };
    case "vel": {   // velocity hold -> grade VELOCITY (m/s)
        private _vel = _heli getVariable ["fza_sfmplus_velModelSpaceNoWind", [0,0,0]];
        [
             ["posPitch", (_vel # 1), "fza_sfmplus_tune_posPitch_kp", "fza_sfmplus_tune_posPitch_ki", "fza_sfmplus_tune_posPitch_kd", [0.4, 1.5, 0.01, 0.01, 0.30, 0.002, 0.06, 0.0005, 0.02, 0.5, 3.0]]
            ,["posRoll",  (_vel # 0), "fza_sfmplus_tune_posRoll_kp",  "fza_sfmplus_tune_posRoll_ki",  "fza_sfmplus_tune_posRoll_kd",  [0.4, 1.5, 0.01, 0.01, 0.30, 0.002, 0.06, 0.0005, 0.02, 0.5, 3.0]]
        ];
    };
    default {   // "pos": the hold runs pid_pitch/pid_roll as a VELOCITY-NULL loop (fed velocity) PLUS a
        //slow POSITION-INTEGRAL trim (posIntKp) biasing the velocity setpoint to kill residual drift.
        //Tune BOTH: (1) the velocity-null kp/ki/kd graded against VELOCITY (as the vel submode); and
        //(2) posIntKp graded against POSITION error - fed through the SAME staged engine but tuning only
        //its I slot (kp=kd->throwaway vars, forced 0 by the cfg's zero steps), so the I-stage ramps the
        //integral trim up while position drifts and backs it off if it hunts. That's exactly a slow
        //integral trim. Grade the WORST-drifting axis's position error so a single scalar posIntKp is
        //tuned against real drift (posIntKp is one shared gain for both axes).
        private _vel = _heli getVariable ["fza_sfmplus_velModelSpaceNoWind", [0,0,0]];
        private _desiredPos = _heli getVariable ["fza_ah64_attHoldDesiredPos", getPos _heli];
        private _dPos = _desiredPos vectorDiff (getPos _heli);
        private _hdg  = direction _heli;
        private _posErrX = ((_dPos # 0) * cos _hdg) - ((_dPos # 1) * sin _hdg);   // right+
        private _posErrY = ((_dPos # 0) * sin _hdg) + ((_dPos # 1) * cos _hdg);   // fwd+
        private _posErrWorst = if ((abs _posErrY) >= (abs _posErrX)) then { _posErrY } else { _posErrX };
        [
             ["posPitch", (_vel # 1), "fza_sfmplus_tune_posPitch_kp", "fza_sfmplus_tune_posPitch_ki", "fza_sfmplus_tune_posPitch_kd", [0.4, 1.5, 0.01, 0.01, 0.30, 0.002, 0.06, 0.0005, 0.02, 0.5, 3.0]]
            ,["posRoll",  (_vel # 0), "fza_sfmplus_tune_posRoll_kp",  "fza_sfmplus_tune_posRoll_ki",  "fza_sfmplus_tune_posRoll_kd",  [0.4, 1.5, 0.01, 0.01, 0.30, 0.002, 0.06, 0.0005, 0.02, 0.5, 3.0]]
            //posInt trim: grade POSITION err (m); tune ONLY ki -> posIntKp. kp/kd point at scratch vars and
            //have zero ramp steps so they stay 0. band 0.15m, ki ramps in fine 0.0005 steps up to 0.02.
            ,["posInt",  _posErrWorst, "fza_sfmplus_scratch_posIntKp", "fza_sfmplus_tune_posIntKp", "fza_sfmplus_scratch_posIntKd", [0.15, 2.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0005, 0.02, 999.0, 4.0]]
        ];
    };
};

//Run the staged PID tuner for each axis of the live submode; collect status + settled count.
private _statuses = [];
private _nSettled = 0;
{
    _x params ["_key", "_err", "_kpVar", "_kiVar", "_kdVar", "_cfg"];
    private _sk = format ["fza_sfmplus_step_%1_", _key];
    private _s  = [_heli, _sk, _kpVar, _kiVar, _kdVar, _err, _dt, _cfg, _key] call fza_sfmplus_fnc_tunerStepTune;
    _statuses pushBack _s;
    if (_heli getVariable [_sk + "settled", false]) then { _nSettled = _nSettled + 1; };
} forEach _axes;

//ADAPTIVE anti-windup ceiling (pos submode only). posIntKp can be maxed and the integral accumulator
//still RAILED at posIntClamp while position keeps drifting - that happens when the velocity-null loop
//leaves a standing velocity larger than the clamp can command (log: velX~0.08 vs clamp 0.02). Rather
//than guess the clamp, GROW it only when the integral is railed AND position is still out of band, and
//SHRINK it slowly when the integral sits comfortably inside it (so it self-sizes to the real residual
//and never larger). Hard-capped at 0.10 (it's a velocity SETPOINT, not the output, so it can't by
//itself exceed the +-0.1 servo). Runs once per eval window so it tracks the staged tuner's cadence.
if (_sub == "pos") then {
    private _clamp = _heli getVariable ["fza_sfmplus_tune_posIntClamp", 0.0200];
    private _iX = abs (_heli getVariable ["fza_sfmplus_posIntX", 0.0]);
    private _iY = abs (_heli getVariable ["fza_sfmplus_posIntY", 0.0]);
    private _iMax = _iX max _iY;                          // most-railed axis
    private _railed = (_iMax >= (_clamp * 0.95));
    //position error still out of band? reuse the posInt grader's band (0.15 m).
    private _drift  = ((abs (_heli getVariable ["fza_sfmplus_dbgPosErrX", 0.0]))
                   max (abs (_heli getVariable ["fza_sfmplus_dbgPosErrY", 0.0]))) > 0.15;
    private _winKey = "fza_sfmplus_clampWinT";
    private _cwT = (_heli getVariable [_winKey, 0.0]) + _dt;
    if (_cwT >= 1.0) then {                               // adjust ~1 Hz
        _cwT = 0.0;
        if (_railed && _drift) then {
            _clamp = (_clamp + 0.005) min 0.10;          // integral maxed + still drifting -> more ceiling
        } else {
            if (_iMax < (_clamp * 0.5)) then {
                _clamp = (_clamp - 0.002) max 0.0200;    // comfortably inside -> ease ceiling back toward seed
            };
        };
        _heli setVariable ["fza_sfmplus_tune_posIntClamp", _clamp];
    };
    _heli setVariable [_winKey, _cwT];
};

//All axes of this submode settled -> COMPLETE for this regime (fly + lock another to tune it).
if (_nSettled >= (count _axes)) then {
    _heli setVariable ["fza_sfmplus_pidAuto_status",
        format ["HOLD AUTO-TUNE ** COMPLETE ** ('%1' submode) - lock + fly another regime to tune it", _sub]];
    _heli setVariable ["fza_sfmplus_tune_holdAutoOn", false];
    if (_heli == vehicle player) then {
        hintSilent parseText format ["<t size='1.5' font='EtelkaMonospacePro' color='#66ff66'>HOLD Auto-Tune COMPLETE</t><br/><t size='1.0' color='#cccccc'>Tuned the '%1' submode</t>", _sub];
    };
    [_heli] spawn fza_audio_fnc_flightTone;
} else {
    _heli setVariable ["fza_sfmplus_pidAuto_status",
        format ["HOLD(%1)  %2", _sub, _statuses joinString "  "]];
};
