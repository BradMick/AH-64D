/* ----------------------------------------------------------------------------
Function: fza_sfmplus_fnc_tunerPidAuto

Description:
    Automatic PID gain tuner using the ZIEGLER-NICHOLS method. Runs as a per-frame
    state machine (CBA PFH), one PID at a time, walking a fixed dependency order
    (SAS rate dampers first, then the holds on the stabilised base). For each PID it:

      1. SETTLE  - zero the gains' I/D, hold the aircraft steady, wait to settle.
      2. RAMP_KP - with ki=kd=0, raise kp in small steps until the CONTROLLED VARIABLE
                   (body rate for SAS, attitude for att-hold, etc.) oscillates with a
                   sustained, roughly constant amplitude. That kp = the ultimate gain Ku,
                   and the measured oscillation period = Tu.
      3. APPLY   - set the PID from the classic ZN PID formula:
                       kp = 0.6*Ku,  ki = 1.2*Ku/Tu,  kd = 0.075*Ku*Tu
                   written to the live tunable gain vars (fza_sfmplus_tune_<pid>_k*).
      4. advance to the next PID.

    SAFETY (this method DELIBERATELY drives each axis to oscillation, which is risky on a
    nonlinear rotor): kp is raised in small increments; if the oscillation AMPLITUDE
    exceeds a per-axis hard ABORT limit (runaway, not a steady limit cycle), the tuner
    ABORTS that PID, caps Ku at the last safe kp, and uses that. Gains are hard-clamped.
    If anything goes wrong the PID is left at a safe conservative value, never a diverging one.

    Toggle with fza_sfmplus_tune_pidAutoOn. Publishes status to fza_sfmplus_pidAuto_status.

Parameters:
    _heli - The aircraft [Object].

Returns:
    Nothing (drives the tunable gain vars; runs per frame while enabled).

Author:
    BradMick / Claude
---------------------------------------------------------------------------- */
params ["_heli"];

if (isNull _heli) exitWith {};

//Rising-edge (OFF->ON) restart: whenever the toggle is switched on, start the schedule from
//the top (idx 0, INIT), so re-running after a completed pass works.
private _on   = _heli getVariable ["fza_sfmplus_tune_pidAutoOn", false];
private _wasOn = _heli getVariable ["fza_sfmplus_pidAuto_wasOn", false];
if (_on && !_wasOn) then {
    _heli setVariable ["fza_sfmplus_pidAuto_idx", 0];
    _heli setVariable ["fza_sfmplus_pidAuto_phase", "INIT"];
    _heli setVariable ["fza_sfmplus_pidAuto_t", 0.0];
};
_heli setVariable ["fza_sfmplus_pidAuto_wasOn", _on];

if !(_on) exitWith {};

private _dt = _heli getVariable ["fza_sfmplus_deltaTime", 0.0];
if (_dt <= 0.0) exitWith {};

//=== PID SCHEDULE ==========================================================
//Each entry describes one PID to tune, in dependency order (SAS dampers first).
//  keyBase   - the tunable-var prefix (fza_sfmplus_tune_<keyBase>_kp/_ki/_kd).
//  measure   - how to read the CONTROLLED VARIABLE this PID regulates (for osc detect).
//  kpStart   - starting kp for the ramp.
//  kpStep    - kp increment per ramp step.
//  kpMax     - hard ceiling for kp (never ramp past this - safety).
//  oscAmp    - amplitude (in the measured var's units) that counts as "oscillating".
//  abortAmp  - amplitude that means RUNAWAY -> abort, cap Ku at last safe kp.
//Measured-var units: SAS = rad/s (body rate); att = deg; posvel = m/s; hdg = deg; alt = m.
private _schedule =
[
     ["sasPitch", "rateX", 0.02, 0.02, 1.20, 0.06, 0.35]
    ,["sasRoll",  "rateY", 0.02, 0.02, 1.20, 0.06, 0.35]
    ,["sasYaw",   "rateZ", 0.02, 0.02, 1.50, 0.06, 0.35]
    ,["attPitch", "pitch", 0.01, 0.01, 0.40, 1.50, 8.00]
    ,["attRoll",  "roll",  0.01, 0.01, 0.40, 1.50, 8.00]
    ,["posPitch", "velY",  0.01, 0.01, 0.40, 1.00, 5.00]
    ,["posRoll",  "velX",  0.01, 0.01, 0.40, 1.00, 5.00]
    ,["hdg",      "hdgErr",0.01, 0.01, 0.40, 2.00, 15.0]
    ,["bar",      "alt",   0.0005,0.0005,0.02, 3.00, 25.0]
    ,["rad",      "alt",   0.005, 0.005, 0.20, 3.00, 25.0]
];

//Read the controlled variable for a given measure key.
private _fnMeasure = {
    params ["_key"];
    private _pqr = _heli getVariable ["fza_sfmplus_angVelModelSpace", [0,0,0]];
    private _att = _heli call BIS_fnc_getPitchBank;
    private _vel = _heli getVariable ["fza_sfmplus_velModelSpaceNoWind", [0,0,0]];
    switch (_key) do {
        case "rateX": { _pqr # 0 };
        case "rateY": { _pqr # 1 };
        case "rateZ": { _pqr # 2 };
        case "pitch": { _att # 0 };
        case "roll":  { _att # 1 };
        case "velX":  { _vel # 0 };
        case "velY":  { _vel # 1 };
        case "hdgErr":{ [(getDir _heli) - (_heli getVariable ["fza_sfmplus_pidAuto_refHdg", getDir _heli])] call CBA_fnc_simplifyAngle180 };
        case "alt":   { (getPosASL _heli) # 2 };
        default { 0.0 };
    };
};

//=== STATE =================================================================
private _idx   = _heli getVariable ["fza_sfmplus_pidAuto_idx", 0];
private _phase = _heli getVariable ["fza_sfmplus_pidAuto_phase", "INIT"];
private _t     = (_heli getVariable ["fza_sfmplus_pidAuto_t", 0.0]) + _dt;

//Finished the whole schedule?
if (_idx >= (count _schedule)) exitWith {
    _heli setVariable ["fza_sfmplus_pidAuto_status", "PID AUTO-TUNE COMPLETE - export the SCAS tab to bake in"];
    _heli setVariable ["fza_sfmplus_tune_pidAutoOn", false];
};

(_schedule select _idx) params ["_keyBase", "_measure", "_kpStart", "_kpStep", "_kpMax", "_oscAmp", "_abortAmp"];
private _kpVar = format ["fza_sfmplus_tune_%1_kp", _keyBase];
private _kiVar = format ["fza_sfmplus_tune_%1_ki", _keyBase];
private _kdVar = format ["fza_sfmplus_tune_%1_kd", _keyBase];

private _meas = [_measure] call _fnMeasure;

switch (_phase) do {
    //--- INIT: zero I/D, set kp to start, capture heading ref, begin settle -------------
    case "INIT": {
        _heli setVariable [_kpVar, _kpStart];
        _heli setVariable [_kiVar, 0.0];
        _heli setVariable [_kdVar, 0.0];
        _heli setVariable ["fza_sfmplus_pidAuto_refHdg", getDir _heli];
        _heli setVariable ["fza_sfmplus_pidAuto_kpCur", _kpStart];
        _heli setVariable ["fza_sfmplus_pidAuto_kpSafe", _kpStart];
        _heli setVariable ["fza_sfmplus_pidAuto_ampMax", 0.0];
        _heli setVariable ["fza_sfmplus_pidAuto_prevMeas", _meas];
        _heli setVariable ["fza_sfmplus_pidAuto_prevSign", 0];
        _heli setVariable ["fza_sfmplus_pidAuto_crossT", []];   // recent zero-crossing times
        _heli setVariable ["fza_sfmplus_pidAuto_clock", 0.0];
        _phase = "SETTLE"; _t = 0.0;
    };

    //--- SETTLE: wait for the axis to be quiet before ramping ----------------------------
    case "SETTLE": {
        _heli setVariable ["fza_sfmplus_pidAuto_status",
            format ["AUTO-TUNE %1: settling (%2)", _keyBase, _t toFixed 1]];
        if (_t > 3.0 && (abs _meas) < (_oscAmp * 0.5)) then { _phase = "RAMP"; _t = 0.0; };
        //Give up settling after a while and ramp anyway.
        if (_t > 8.0) then { _phase = "RAMP"; _t = 0.0; };
    };

    //--- RAMP: raise kp until sustained oscillation (Ku) or abort ------------------------
    case "RAMP": {
        private _kpCur   = _heli getVariable ["fza_sfmplus_pidAuto_kpCur", _kpStart];
        private _ampMax  = _heli getVariable ["fza_sfmplus_pidAuto_ampMax", 0.0];
        private _clock   = (_heli getVariable ["fza_sfmplus_pidAuto_clock", 0.0]) + _dt;

        //Track amplitude of the controlled variable over this kp step.
        _ampMax = _ampMax max (abs _meas);

        //Zero-crossing detection (of the measured var about 0) to time the oscillation.
        private _prevMeas = _heli getVariable ["fza_sfmplus_pidAuto_prevMeas", _meas];
        private _sign     = if (_meas > 0) then {1} else { if (_meas < 0) then {-1} else {0} };
        private _prevSign = _heli getVariable ["fza_sfmplus_pidAuto_prevSign", 0];
        private _crossT   = _heli getVariable ["fza_sfmplus_pidAuto_crossT", []];
        if (_sign != 0 && _prevSign != 0 && _sign != _prevSign) then {
            _crossT pushBack _clock;
            if (count _crossT > 6) then { _crossT deleteAt 0; };  // keep the last few
        };

        //ABORT: runaway amplitude -> this axis is diverging, not limit-cycling. Cap Ku at
        //the LAST SAFE kp and go apply, so we never leave it in a divergent state.
        if (_ampMax > _abortAmp) exitWith {
            private _kpSafe = _heli getVariable ["fza_sfmplus_pidAuto_kpSafe", _kpStart];
            _heli setVariable ["fza_sfmplus_pidAuto_Ku", _kpSafe];
            //Tu from crossings if we have them, else a fallback from the axis (2 crossings = 1 period).
            private _tu = 0.5;
            if (count _crossT >= 3) then { _tu = 2.0 * (((_crossT select (count _crossT -1)) - (_crossT select 0)) / ((count _crossT) - 1)); };
            _heli setVariable ["fza_sfmplus_pidAuto_Tu", _tu];
            _heli setVariable ["fza_sfmplus_pidAuto_status",
                format ["AUTO-TUNE %1: ABORT (runaway amp %2) - using last-safe Ku=%3", _keyBase, _ampMax toFixed 2, _kpSafe toFixed 3]];
            _heli setVariable ["fza_sfmplus_pidAuto_phase", "APPLY"];
            _heli setVariable ["fza_sfmplus_pidAuto_t", 0.0];
            _heli setVariable [_kpVar, _kpStart];   // drop kp back to safe while applying
        };

        //SUSTAINED OSCILLATION detected: enough regular zero-crossings at a meaningful
        //amplitude -> we have Ku (current kp) and Tu (avg period from crossings).
        private _oscillating = (count _crossT >= 5) && (_ampMax >= _oscAmp);
        if (_oscillating) then {
            private _tu = 2.0 * (((_crossT select (count _crossT -1)) - (_crossT select 0)) / ((count _crossT) - 1));
            _heli setVariable ["fza_sfmplus_pidAuto_Ku", _kpCur];
            _heli setVariable ["fza_sfmplus_pidAuto_Tu", _tu];
            _heli setVariable ["fza_sfmplus_pidAuto_status",
                format ["AUTO-TUNE %1: Ku=%2 Tu=%3 -> applying ZN", _keyBase, _kpCur toFixed 3, _tu toFixed 2]];
            _phase = "APPLY"; _t = 0.0;
        } else {
            //Not oscillating yet: after holding this kp a moment, step it up (record last-safe).
            if (_clock > 1.5) then {
                _heli setVariable ["fza_sfmplus_pidAuto_kpSafe", _kpCur];
                private _kpNext = _kpCur + _kpStep;
                if (_kpNext > _kpMax) exitWith {
                    //Hit the ceiling without a clean oscillation - use the ceiling as Ku.
                    _heli setVariable ["fza_sfmplus_pidAuto_Ku", _kpMax];
                    _heli setVariable ["fza_sfmplus_pidAuto_Tu", 0.5];
                    _heli setVariable ["fza_sfmplus_pidAuto_status",
                        format ["AUTO-TUNE %1: hit kpMax %2 (no clean osc) - using it as Ku", _keyBase, _kpMax toFixed 3]];
                    _heli setVariable ["fza_sfmplus_pidAuto_phase", "APPLY"];
                    _heli setVariable ["fza_sfmplus_pidAuto_t", 0.0];
                };
                _heli setVariable ["fza_sfmplus_pidAuto_kpCur", _kpNext];
                _heli setVariable [_kpVar, _kpNext];
                _heli setVariable ["fza_sfmplus_pidAuto_ampMax", 0.0];   // reset amp for the new step
                _heli setVariable ["fza_sfmplus_pidAuto_clock", 0.0];
                _heli setVariable ["fza_sfmplus_pidAuto_crossT", []];
                _heli setVariable ["fza_sfmplus_pidAuto_status",
                    format ["AUTO-TUNE %1: ramp kp=%2 amp=%3", _keyBase, _kpNext toFixed 3, _ampMax toFixed 2]];
            } else {
                _heli setVariable ["fza_sfmplus_pidAuto_clock", _clock];
                _heli setVariable ["fza_sfmplus_pidAuto_ampMax", _ampMax];
                _heli setVariable ["fza_sfmplus_pidAuto_crossT", _crossT];
            };
        };
        _heli setVariable ["fza_sfmplus_pidAuto_prevMeas", _meas];
        if (_sign != 0) then { _heli setVariable ["fza_sfmplus_pidAuto_prevSign", _sign]; };
    };

    //--- APPLY: write the ZN gains, drop I/D back to 0 momentarily, next PID -------------
    case "APPLY": {
        private _ku = _heli getVariable ["fza_sfmplus_pidAuto_Ku", _kpStart];
        private _tu = _heli getVariable ["fza_sfmplus_pidAuto_Tu", 0.5];
        if (_tu < 0.05) then { _tu = 0.5; };   // guard bad Tu
        //Classic ZN PID. Use a slightly detuned kp (0.5 vs 0.6) for margin on the nonlinear rotor.
        private _kp = 0.50 * _ku;
        private _ki = 1.20 * _ku / _tu;
        private _kd = 0.075 * _ku * _tu;
        //Hard clamp to each PID's tunable range ceiling (kpMax*something) to avoid crazy values.
        _kp = [_kp, 0.0, _kpMax] call BIS_fnc_clamp;
        _ki = [_ki, 0.0, _kpMax] call BIS_fnc_clamp;
        _kd = [_kd, 0.0, _kpMax] call BIS_fnc_clamp;
        _heli setVariable [_kpVar, _kp];
        _heli setVariable [_kiVar, _ki];
        _heli setVariable [_kdVar, _kd];
        _heli setVariable ["fza_sfmplus_pidAuto_status",
            format ["AUTO-TUNE %1: SET kp=%2 ki=%3 kd=%4", _keyBase, _kp toFixed 3, _ki toFixed 3, _kd toFixed 3]];
        //Next PID.
        _idx = _idx + 1;
        _phase = "INIT"; _t = 0.0;
    };

    default { _phase = "INIT"; _t = 0.0; };
};

_heli setVariable ["fza_sfmplus_pidAuto_idx", _idx];
_heli setVariable ["fza_sfmplus_pidAuto_phase", _phase];
_heli setVariable ["fza_sfmplus_pidAuto_t", _t];
