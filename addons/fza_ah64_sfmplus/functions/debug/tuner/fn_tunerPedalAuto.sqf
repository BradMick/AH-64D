/* ----------------------------------------------------------------------------
Function: fza_sfmplus_fnc_tunerPedalAuto

Description:
    PASSIVE AUTO-PEDAL auto-tuner. Run the SAS tuner FIRST (the yaw rate damper is the inner loop
    underneath the auto-pedal); this tunes the auto-pedal PID for whichever REGIME is LIVE right
    now. It never touches the controls and grades the LIVE error via the shared continuous engine
    (fn_tunerStepTune), exactly like the SAS and HOLD tuners.

    The auto-pedal has three regimes, each with its own error signal and units, so each is tuned
    separately by flying that regime (fn_getInput publishes the live regime + errors):

       HOVER (<~24kt GS, low)  -> "hdg"  : grade HEADING error (deg)      -> apHdg_*
       ACCEL <50ft AGL         -> "ntt"  : grade KINEMATIC sideslip (deg) -> apNtt_*
       CRUISE >50ft AGL        -> "aero" : grade LATERAL accel (g)        -> apAero_*

    WORKFLOW - fly each regime and let it settle before moving to the next:
       1. Hover in ground effect, let it settle    -> tunes "hdg"
       2. Accelerate and stay BELOW 50ft AGL       -> tunes "ntt"
       3. Climb through 50ft and cruise/turn       -> tunes "aero"
    The tuner only grades the regime that is live, so a regime you never fly is never tuned. Each
    regime reports COMPLETE on its own; the status line shows which regime is being graded.

    IMPORTANT: keep your feet OFF the pedals while it grades. Any pedal input trips the auto-pedal
    breakout in fn_getInput, which resets the PIDs - the tuner pauses while broken out so it never
    grades a window that the loop was not actually driving.

    Toggle with fza_sfmplus_tune_pedalAutoOn. Status -> fza_sfmplus_pidAuto_status.

Parameters:
    _heli - The aircraft [Object].

Author:
    BradMick / Claude
---------------------------------------------------------------------------- */
#include "\fza_ah64_sfmplus\headers\core.hpp"
params ["_heli"];

if (isNull _heli) exitWith {};

private _on    = _heli getVariable ["fza_sfmplus_tune_pedalAutoOn", false];
private _wasOn = _heli getVariable ["fza_sfmplus_pedalAuto_wasOn", false];

//Rising edge: reset step state for ALL pedal regimes so a re-run starts fresh.
if (_on && !_wasOn) then {
    private _fields = ["stage","errSm","winT","cross","ampMax","prevSgn","startMag","underT","settled","Ku"];
    {
        private _sk = format ["fza_sfmplus_step_%1_", _x];
        { _heli setVariable [_sk + _x, nil]; } forEach _fields;   // inner _x = field name
    } forEach ["apHdg","apNtt","apAero"];
    _heli setVariable ["fza_sfmplus_pedalAuto_exPeak", 0.0];
    _heli setVariable ["fza_sfmplus_pedalAuto_exRegime", ""];
    _heli setVariable ["fza_sfmplus_pidAuto_status", "PEDAL AUTO-TUNE: fly each regime - feet OFF the pedals"];
};
_heli setVariable ["fza_sfmplus_pedalAuto_wasOn", _on];

if !(_on) exitWith {};

//Never run alongside the other tuners.
if (_heli getVariable ["fza_sfmplus_tune_pidAutoOn", false]) exitWith {
    _heli setVariable ["fza_sfmplus_pidAuto_status", "PEDAL tuner waiting - SAS tuner is running"];
};
if (_heli getVariable ["fza_sfmplus_tune_holdAutoOn", false]) exitWith {
    _heli setVariable ["fza_sfmplus_pidAuto_status", "PEDAL tuner waiting - HOLD tuner is running"];
};

//The auto-pedal must actually be enabled, or there is no loop to grade.
if !(fza_ah64_sfmPlusAutoPedal) exitWith {
    _heli setVariable ["fza_sfmplus_pidAuto_status", "PEDAL tuner idle - enable Auto Pedal in CBA settings"];
};

private _dt = _heli getVariable ["fza_sfmplus_deltaTime", 0.0];
if (_dt <= 0.0) exitWith {};

//PILOT BREAKOUT PAUSE: any pedal input resets the auto-pedal PIDs (fn_getInput), so the error we
//would grade is not the loop's own doing. Freeze grading (don't advance the window) while the
//pilot is on the pedals, and tell them why the tuner has stopped moving.
private _yawBreakoutVal = (inputAction "HeliRudderRight") - (inputAction "HeliRudderLeft");
if (_yawBreakoutVal < -0.01 || _yawBreakoutVal > 0.01) exitWith {
    _heli setVariable ["fza_sfmplus_pidAuto_status", "PEDAL tuner PAUSED - pilot pedal input (feet off to resume)"];
};

//TRANSITION GATE: the three regimes are blended, so in a transition (climbing through 50ft, or
//accelerating out of a hover) more than one PID drives the pedals at once. Grading one regime's
//error while another owns a big share of the command mis-attributes the response and tunes the
//wrong PID. Only grade when the live regime clearly OWNS the pedals; otherwise hold and say so.
private _regimeWgt = _heli getVariable ["fza_sfmplus_autoPedalRegimeWgt", 1.0];
if (_regimeWgt < 0.85) exitWith {
    _heli setVariable ["fza_sfmplus_pidAuto_status",
        format ["PEDAL tuner HOLDING - in a regime transition (%1%2 authority) - settle into one regime",
            round (_regimeWgt * 100), "%"]];
};

//Grade whichever regime fn_getInput says is live. Each regime tunes the SAME gains its PID actually
//uses, graded against that PID's own error signal and units:
//   hdg  : heading error (deg)      -> apHdg_*   band 1.0 deg
//   ntt  : kinematic sideslip (deg) -> apNtt_*   band 1.0 deg
//   aero : lateral accel (g)        -> apAero_*  band 0.01 g (the ball is visibly off ~0.02g)
//Staged P->D->I cfg = [band, evalWindow, kpStart, kpStep, kpMax, kdStep, kdMax, kiStep, kiMax, oscAmp, settleTime]
//Each axis entry: [key, errorSignal, kpVar, kiVar, kdVar, cfg]
private _regime = _heli getVariable ["fza_sfmplus_autoPedalRegime", "hdg"];

//GAIN CEILINGS ARE PINNED TO THE GUI SLIDER RANGE. The SCAS tab builds each slider as 0 .. 4x the
//seed (fn_tunerVariables), so every kpMax/kiMax/kdMax below is exactly 4x that regime's seed in
//fn_coreConfig. If a ceiling here exceeded the slider, the tuner could park a gain the GUI cannot
//display - and the next manual touch of that slider would silently clamp the tuned value back down.
//Keep these in sync with the seeds if the seeds change.
private _axes = switch (_regime) do {
    //Nose-to-tail: kinematic sideslip in deg. Gains are small (a deg of slip is a big error here)
    //and ki gets real room because a standing crab is exactly what the integral is there to remove.
    //Seeds 0.0300/0.0080/0.0100 -> ceilings 0.12/0.032/0.04.
    case "ntt": {
        private _err = _heli getVariable ["fza_sfmplus_autoPedalNttErr", 0.0];
        [["apNtt", _err, "fza_sfmplus_tune_apNtt_kp", "fza_sfmplus_tune_apNtt_ki", "fza_sfmplus_tune_apNtt_kd",
            [1.0, 1.5, 0.01, 0.01, 0.12, 0.002, 0.04, 0.0005, 0.032, 2.0, 3.0]]];
    };
    //Aerodynamic trim: lateral accel in g. beta_g is a SMALL number - a visible cruise skid is only
    //a few THOUSANDTHS of a g - so kp per unit error is far larger than the deg-based regimes.
    //Seeds 6.6700/0.5000/0.4000 -> ceilings 26.7/2.0/1.6. Band is 0.002g to match the real signal
    //scale (0.01g would never be reached and the excitation gate would never open).
    //kiStep is DELIBERATELY small: with the integral supplying the standing trim, an over-ramped ki
    //is what makes the pedals slam for a tiny error - it was observed winding to 1.5 and dominating.
    case "aero": {
        private _err = _heli getVariable ["fza_sfmplus_autoPedalAeroErr", 0.0];
        [["apAero", _err, "fza_sfmplus_tune_apAero_kp", "fza_sfmplus_tune_apAero_ki", "fza_sfmplus_tune_apAero_kd",
            [0.002, 1.5, 2.00, 1.00, 26.7, 0.05, 1.60, 0.010, 2.00, 0.004, 3.0]]];
    };
    //Hover heading hold: heading error in deg.
    //Seeds 0.1000/0.0050/0.0500 -> ceilings 0.4/0.02/0.2.
    default {
        private _err = _heli getVariable ["fza_sfmplus_autoPedalHdgErr", 0.0];
        [["apHdg", _err, "fza_sfmplus_tune_apHdg_kp", "fza_sfmplus_tune_apHdg_ki", "fza_sfmplus_tune_apHdg_kd",
            [1.0, 1.5, 0.02, 0.02, 0.40, 0.005, 0.20, 0.0005, 0.02, 2.0, 3.0]]];
    };
};

//EXCITATION GUARD. The staged engine grades how the loop RECOVERS from disturbances, so it needs
//disturbances to grade. Fed a signal that never moves it does not stall - it walks straight through
//P (not sluggish, not hunting) and D (the "amplitude shrinking" test is 0 < 0 = false, so kd ramps
//to its ceiling) and declares DONE with kd railed and ki zeroed. That is a confidently-wrong tune
//off no data. So require the axis to have actually been excited - some real error at some point in
//this window - before its grade is allowed to count. Track the peak seen since the last window.
private _exKey  = "fza_sfmplus_pedalAuto_exPeak";
(_axes # 0) params ["_axKey", "_axErr", "", "", "", "_axCfg"];
//Peak is per-regime: switching regimes clears it, so one regime's excitation can never unlock
//grading in another (the three errors are different signals in different units).
if ((_heli getVariable ["fza_sfmplus_pedalAuto_exRegime", ""]) != _regime) then {
    _heli setVariable ["fza_sfmplus_pedalAuto_exRegime", _regime];
    _heli setVariable [_exKey, 0.0];
};
private _exPeak = (_heli getVariable [_exKey, 0.0]) max (abs _axErr);
_heli setVariable [_exKey, _exPeak];
//Excited = peak error reached the axis's own band (cfg # 0) at least once. Below that the aircraft
//is simply sitting still and there is nothing to learn from it.
if (_exPeak < (_axCfg # 0)) exitWith {
    _heli setVariable ["fza_sfmplus_pidAuto_status",
        format ["PEDAL(%1) WAITING for a disturbance - manoeuvre a little (peak %2 / need %3)",
            _regime, _exPeak toFixed 3, (_axCfg # 0) toFixed 3]];
};

//Run the staged PID tuner for the live regime; collect status + settled state.
private _statuses = [];
private _nSettled = 0;
{
    _x params ["_key", "_err", "_kpVar", "_kiVar", "_kdVar", "_cfg"];
    private _sk = format ["fza_sfmplus_step_%1_", _key];
    private _s  = [_heli, _sk, _kpVar, _kiVar, _kdVar, _err, _dt, _cfg, _key] call fza_sfmplus_fnc_tunerStepTune;
    _statuses pushBack _s;
    if (_heli getVariable [_sk + "settled", false]) then { _nSettled = _nSettled + 1; };
} forEach _axes;

//How many of the three regimes are done overall - so the status line tells you what is left to fly.
private _doneList = [];
{
    if (_heli getVariable [format ["fza_sfmplus_step_%1_settled", _x], false]) then { _doneList pushBack _x; };
} forEach ["apHdg","apNtt","apAero"];

//This regime settled -> COMPLETE for this regime (fly another regime to tune it). Only turn the
//tuner OFF once all three are settled, so one toggle can tune the whole envelope in a single sortie.
if (_nSettled >= (count _axes)) then {
    if ((count _doneList) >= 3) then {
        _heli setVariable ["fza_sfmplus_pidAuto_status", "PEDAL AUTO-TUNE ** COMPLETE ** (all 3 regimes settled)"];
        _heli setVariable ["fza_sfmplus_tune_pedalAutoOn", false];
        if (_heli == vehicle player) then {
            hintSilent parseText "<t size='1.5' font='EtelkaMonospacePro' color='#66ff66'>Pedal Auto-Tune COMPLETE</t><br/><t size='1.0' color='#cccccc'>All three regimes settled</t>";
        };
        [_heli] spawn fza_audio_fnc_flightTone;
    } else {
        _heli setVariable ["fza_sfmplus_pidAuto_status",
            format ["PEDAL '%1' ** SETTLED ** (%2/3 done) - fly another regime", _regime, count _doneList]];
    };
} else {
    _heli setVariable ["fza_sfmplus_pidAuto_status",
        format ["PEDAL(%1)  %2   [%3/3 done]", _regime, _statuses joinString "  ", count _doneList]];
};
