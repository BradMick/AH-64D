/* ----------------------------------------------------------------------------
Function: fza_sfmplus_fnc_tunerStepTune

Description:
    Shared CONTINUOUS trend-based gain grader for one axis, one frame. Used by BOTH the SAS
    tuner (fn_tunerPidAuto) and the HOLD tuner (fn_tunerHoldAuto).

    WHY continuous (not event-based): position/velocity hold is a CONTINUOUS regulation problem -
    the loop is always working against a nonzero error and may never reach a quiet "homeostasis".
    The old event model ("wait for a disturbance, grade the recovery") could never grade such a
    loop: it never saw a clean before/after, so it sat forever and the gain never moved. This model
    instead grades the LIVE error every evaluation window, regardless of whether a discrete event
    ever happens. It NEVER touches the controls - it only reads the error the loop is producing.

    EACH FRAME: smooth the error, accumulate window stats (zero-crossings = oscillation; whether
    |err| is shrinking; time spent under the "at-target" band). When the window elapses, decide:
        - OSCILLATING (>= 2 zero-crossings in the window, not shrinking) -> too much gain -> DOWN
          (fast, x downStep) - back off hard the instant it overcorrects.
        - NOT shrinking, NOT oscillating (|err| flat/large, one sign)   -> too weak  -> UP
          (gentle, x upStep).
        - shrinking cleanly / already small                              -> good, leave the gain.
    SETTLED when |err| stays under the band for settleTime continuously.

    Asymmetric by design: gentle UP, fast DOWN - approaching authority from below is safe, but the
    moment it starts oscillating it must retreat quickly (overcorrection has been the failure mode).

    Per-axis state is namespaced by _sk so several axes grade at once.

Parameters:
    _heli, _sk, _gainVar, _err, _dt, _cfg, _label
    _cfg: [band, evalWindow, upStep, downStep, gMin, gMax, settleTime]

Returns:
    A short per-axis status string for the overlay.

Author:
    BradMick / Claude
---------------------------------------------------------------------------- */
params ["_heli", "_sk", "_gainVar", "_err", "_dt", "_cfg", "_label"];
_cfg params ["_band", "_evalWindow", "_upStep", "_downStep", "_gMin", "_gMax", "_settleTime"];

//--- per-axis persistent state (seeded on first touch) --------------------------------
private _errSm    = _heli getVariable [_sk + "errSm",    _err];   // smoothed error
private _winT     = _heli getVariable [_sk + "winT",     0.0];    // time into current window
private _cross    = _heli getVariable [_sk + "cross",    0];      // zero-crossings this window
private _prevSgn  = _heli getVariable [_sk + "prevSgn",  0];
private _startMag = _heli getVariable [_sk + "startMag", abs _err]; // |err| at window start
private _underT   = _heli getVariable [_sk + "underT",   0.0];    // continuous time under band
private _settled  = _heli getVariable [_sk + "settled",  false];
private _gain     = _heli getVariable [_gainVar, _gMin];

//Smooth the raw error a little so frame noise doesn't create phantom crossings.
_errSm = _errSm + 0.20 * (_err - _errSm);
private _mag = abs _errSm;
private _sgn = if (_errSm > 0) then {1} else { if (_errSm < 0) then {-1} else {0} };

//--- continuous time-under-band (settle detection) ------------------------------------
if (_mag < _band) then { _underT = _underT + _dt; } else { _underT = 0.0; };
if (_underT >= _settleTime) then { _settled = true; };
//If it leaves the band by a clear margin after being settled, un-settle so it keeps grading
//(the axis is being disturbed again / drifting) - the tuner stays useful, doesn't lock out.
if (_settled && _mag > (_band * 3.0)) then { _settled = false; };

//--- accumulate window stats ----------------------------------------------------------
_winT = _winT + _dt;
//Count a zero-crossing only when the swing is meaningful (past the band) so jitter about
//zero near the target doesn't read as oscillation.
if (_sgn != 0 && _prevSgn != 0 && _sgn != _prevSgn && _mag > _band) then { _cross = _cross + 1; };
if (_sgn != 0) then { _prevSgn = _sgn; };

private _action = "";
//--- window elapsed: grade + adjust ---------------------------------------------------
if (_winT >= _evalWindow) then {
    if (!_settled) then {
        private _shrunk = (_mag < (_startMag * 0.7));   // |err| dropped >=30% across the window
        if (_cross >= 2 && !_shrunk) then {
            //Oscillating and not converging -> too much gain -> back off FAST.
            _gain = _gain * _downStep;
            _action = "DOWN";
        } else {
            if (!_shrunk && _mag > _band) then {
                //Not shrinking, not oscillating, still out of band -> too weak -> nudge UP gently.
                _gain = _gain * _upStep;
                _action = "UP";
            } else {
                //Shrinking cleanly (or already small) -> gain is doing its job, leave it.
                _action = "ok";
            };
        };
        _gain = [_gain, _gMin, _gMax] call BIS_fnc_clamp;
        _heli setVariable [_gainVar, _gain];
    } else {
        _action = "SET";
    };
    //Reset the window.
    _winT = 0.0; _cross = 0; _startMag = _mag;
} else {
    _action = if (_settled) then {"SET"} else {"..."};
};

//--- persist state --------------------------------------------------------------------
_heli setVariable [_sk + "errSm",    _errSm];
_heli setVariable [_sk + "winT",     _winT];
_heli setVariable [_sk + "cross",    _cross];
_heli setVariable [_sk + "prevSgn",  _prevSgn];
_heli setVariable [_sk + "startMag", _startMag];
_heli setVariable [_sk + "underT",   _underT];
_heli setVariable [_sk + "settled",  _settled];

format ["%1 %2 %3%4", _label, _gain toFixed 3, _action, (if (_settled) then {" OK"} else {""})]
