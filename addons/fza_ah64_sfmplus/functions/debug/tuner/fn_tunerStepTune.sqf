/* ----------------------------------------------------------------------------
Function: fza_sfmplus_fnc_tunerStepTune

Description:
    STAGED PID auto-tuner for one axis, one frame. Used by BOTH the SAS tuner (fn_tunerPidAuto)
    and the HOLD tuner (fn_tunerHoldAuto). Tunes the FULL PID (kp, ki, kd) PASSIVELY off YOUR
    flying - it NEVER touches the controls and NEVER drives the axis toward instability. It only
    watches how the loop handles the disturbances you create and moves the gains AWAY from
    oscillation (the old Ziegler-Nichols relay method deliberately ramped P to sustained oscillation
    to find Ku - on a hold loop that meant its whole job was to make the aircraft oscillate hard;
    replaced).

    STAGES (per axis, advance when each criterion is met):
      P  : ki=kd=0. Gradient-seek kp from the RESPONSE each window: if it HUNTS (overshoots your
           input, >=2 zero-crossings) back kp OFF; if it's SLUGGISH (error lingers above band, no
           hunting) nudge kp UP a little; when it's responsive AND not hunting, go to D. Never
           ramps into oscillation.
      D  : hold kp. Ramp kd while the loop still overshoots; if it's hunting hard, shave a little P
           too. Done once no hunting AND amplitude shrinking (damped). Go to I.
      I  : hold kp,kd. Ramp ki until the STEADY-STATE error is driven into the band and stays
           (time-in-band >= settleTime). Go to DONE.
      DONE: hold all three. If it later drifts well out of band, drop back to I to re-trim.

    Detection signals: zero-crossings about the smoothed error (hunting/overshoot), |err| vs band
    (sluggish / steady-state), continuous time-in-band (settle). It NEVER touches the controls -
    it only reads the error the loop produces and writes the three gain vars.

    Per-axis state namespaced by _sk so several axes tune at once.

Parameters:
    _heli, _sk, _kpVar, _kiVar, _kdVar, _err, _dt, _cfg, _label
    _cfg: [band, evalWindow, kpStart, kpStep, kpMax, kdStep, kdMax, kiStep, kiMax, oscAmp, settleTime]

Returns:
    A short per-axis status string for the overlay (label, stage, gains).

Author:
    BradMick / Claude
---------------------------------------------------------------------------- */
params ["_heli", "_sk", "_kpVar", "_kiVar", "_kdVar", "_err", "_dt", "_cfg", "_label"];
_cfg params ["_band", "_evalWindow", "_kpStart", "_kpStep", "_kpMax",
             "_kdStep", "_kdMax", "_kiStep", "_kiMax", "_oscAmp", "_settleTime"];

//--- per-axis persistent state --------------------------------------------------------
private _stage    = _heli getVariable [_sk + "stage",    "P"];    // P | D | I | DONE
private _errSm    = _heli getVariable [_sk + "errSm",    _err];
private _winT     = _heli getVariable [_sk + "winT",     0.0];
private _cross    = _heli getVariable [_sk + "cross",    0];      // zero-crossings this window
private _ampMax   = _heli getVariable [_sk + "ampMax",   0.0];    // peak |err| this window
private _startMag = _heli getVariable [_sk + "startMag", abs _err];
private _prevSgn  = _heli getVariable [_sk + "prevSgn",  0];
private _underT   = _heli getVariable [_sk + "underT",   0.0];    // continuous time-in-band

//Current gains (seed from config on first touch).
private _kp = _heli getVariable [_kpVar, _kpStart];
private _ki = _heli getVariable [_kiVar, 0.0];
private _kd = _heli getVariable [_kdVar, 0.0];

//--- per-frame signal processing ------------------------------------------------------
_errSm = _errSm + 0.20 * (_err - _errSm);
private _mag = abs _errSm;
private _sgn = if (_errSm > 0) then {1} else { if (_errSm < 0) then {-1} else {0} };

//Zero-crossing (oscillation) detection about a small hunt floor (above jitter).
private _huntFloor = _band * 0.2;
private _crossed = (_sgn != 0 && _prevSgn != 0 && _sgn != _prevSgn && _mag > _huntFloor);
if (_crossed) then { _cross = _cross + 1; };
if (_sgn != 0) then { _prevSgn = _sgn; };

//Track peak amplitude + continuous time-in-band across the window.
_ampMax = _ampMax max _mag;
if (_mag < _band) then { _underT = _underT + _dt; } else { _underT = 0.0; };

_winT = _winT + _dt;
private _action = "";

//--- window elapsed: evaluate the current stage ---------------------------------------
if (_winT >= _evalWindow) then {
    private _shrinking   = (_ampMax < (_startMag * 0.7));

    //PASSIVE grading of how the loop handled YOUR disturbances this window. NEVER drives the axis to
    //oscillation - it only moves gains AWAY from oscillation. Oscillation/overshoot => back off P;
    //sluggish (error lingers above band with no hunting) => nudge P up gently; quiet+in-band => converge.
    private _hunting  = (_cross >= 2);                        // it overshot/oscillated your input
    private _sluggish = (_ampMax >= (_band * 1.5)) && (_cross <= 1) && (_underT < (_dt * 2)); // lags, never settled

    switch (_stage) do {
        //=== STAGE P: gradient-seek kp from the response. Up if sluggish, DOWN if hunting. No Ku, no
        //   deliberate destabilise. Advance to D only once the response is neither hunting nor sluggish. ===
        case "P": {
            _ki = 0.0; _kd = 0.0;
            if (_hunting) then {
                _kp = (_kp - _kpStep * 1.5) max _kpStart;   // overshoot -> back P off harder than we add
                _action = format ["P hunting, back off kp=%1", _kp toFixed 3];
            } else {
                if (_sluggish) then {
                    _kp = (_kp + _kpStep) min _kpMax;       // too slow -> add a little P
                    _action = format ["P sluggish, kp=%1", _kp toFixed 3];
                } else {
                    _stage = "D";                            // responsive, not hunting -> add damping
                    _action = format ["P ok kp=%1 -> D", _kp toFixed 3];
                };
            };
        };
        //=== STAGE D: add kd while the loop still overshoots; if it hunts hard, ease P back a touch too.
        //   Done once no hunting AND amplitude is falling (damped). ===
        case "D": {
            if (_cross <= 1 && _shrinking) then {   // damped: few/no crossings AND amplitude falling
                _stage = "I";
                _action = format ["D done kd=%1 -> I", _kd toFixed 3];
            } else {
                _kd = (_kd + _kdStep) min _kdMax;
                if (_cross >= 3) then { _kp = (_kp - _kpStep) max _kpStart; }; // still hunting hard -> shave P
                _action = format ["D ramp kd=%1 (cross=%2)", _kd toFixed 3, _cross];
                if (_kd >= _kdMax) then { _stage = "I"; _action = format ["D hit max kd=%1 -> I", _kd toFixed 3]; };
            };
        };
        //=== STAGE I: hold kp,kd, ramp ki until steady-state error is in-band and stays -> DONE ===
        case "I": {
            if (_underT >= _settleTime) then {
                _stage = "DONE";
                _action = format ["I done ki=%1 -> DONE (settled)", _ki toFixed 3];
            } else {
                //Only add I while there is a standing error to remove; if oscillating, I is too high.
                if (_cross >= 2) then {
                    _ki = (_ki * 0.8) max 0.0;      // integral-induced hunt -> back ki off
                    _action = format ["I too high, ki=%1", _ki toFixed 3];
                } else {
                    _ki = (_ki + _kiStep) min _kiMax;
                    _action = format ["I ramp ki=%1", _ki toFixed 3];
                };
            };
        };
        //=== DONE: hold gains; if it drifts well out of band later, re-trim via I ===
        default {
            if (_mag > (_band * 3.0)) then { _stage = "I"; _underT = 0.0; _action = "re-trim -> I"; }
            else { _action = "DONE"; };
        };
    };

    //Write the gains + advance state; reset window accumulators.
    _kp = [_kp, 0.0, _kpMax] call BIS_fnc_clamp;
    _ki = [_ki, 0.0, _kiMax] call BIS_fnc_clamp;
    _kd = [_kd, 0.0, _kdMax] call BIS_fnc_clamp;
    _heli setVariable [_kpVar, _kp];
    _heli setVariable [_kiVar, _ki];
    _heli setVariable [_kdVar, _kd];
    _heli setVariable [_sk + "stage", _stage];

    _winT = 0.0; _cross = 0; _ampMax = 0.0; _startMag = _mag;
} else {
    _action = _stage;
};

//--- persist per-frame state ----------------------------------------------------------
_heli setVariable [_sk + "errSm",    _errSm];
_heli setVariable [_sk + "winT",     _winT];
_heli setVariable [_sk + "cross",    _cross];
_heli setVariable [_sk + "ampMax",   _ampMax];
_heli setVariable [_sk + "prevSgn",  _prevSgn];
_heli setVariable [_sk + "startMag", _startMag];
_heli setVariable [_sk + "underT",   _underT];

//"settled" flag the callers read = DONE stage.
_heli setVariable [_sk + "settled", (_stage == "DONE")];

format ["%1 [%2] kp=%3 ki=%4 kd=%5", _label, _stage, _kp toFixed 3, _ki toFixed 3, _kd toFixed 3]
