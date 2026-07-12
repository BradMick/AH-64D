/* ----------------------------------------------------------------------------
Function: fza_sfmplus_fnc_tunerMaster

Description:
    Master auto-tuner. YOU fly the aircraft (set the pitch/roll attitude and airspeed);
    the tuner adjusts the force SCALARS so the aircraft is trimmed and stable at the
    attitude you are holding. It does NOT move the cyclic - the only control it drives
    is the PEDAL (to a known position so the yaw axis can tune tail thrust against it).

    ONE AXIS AT A TIME. Sequence depends on flight state:
      forward flight:  YAW -> PITCH(flapback) -> THRUST -> ROLL
      hover (IGE/OGE):  YAW -> VERT  (stabilator inactive; flapback needs airspeed)
    Each axis tunes its force(s) against a measured error and only advances once that
    error is in tolerance (see per-axis notes below).

      YAW   : drive PEDAL trim to the flight-test pedal position + freeze it, then
              null NET yaw moment. MAIN TORQUE (fza_sfmplus_tune_rtrTqScalarTable) is
              tuned ONLY at a hover and copied to ALL bands (a fixed reference). TAIL
              THRUST (fza_sfmplus_tune_tailThrustTable) carries the balance: half at
              hover (torque takes the rest), the FULL correction in forward flight
              (torque fixed). The VERTICAL FIN is hand-tuned (fixed lift properties),
              so the master does not touch it. Tuned FIRST so spin stops early. (Rotor
              disk tilt is a live pilot-input effect and is NOT tuned here.)
      PITCH (flapback, forward flight): OWNS the pitch trim across the whole envelope.
              Drive CYCLIC PITCH trim to the flight-test forward position + freeze it
              (the forward cyclic the pilot holds to counter the constant nose-up), then
              tune the FLAPBACK/RBS PITCH AUTHORITY (fza_sfmplus_tune_rbsPitchTable) at
              this band so the ship settles at the TARGET PITCH with the cyclic pinned
              there. Models the rotor's nose-up flapback (dissymmetry of lift + gyroscopic
              precession + transverse flow) present from low speed on; the sharper RBS
              component at 150+ kt is HAND-SET later, so this axis only tunes the standard
              0-140 kt bands (addresses the rbsPitchTable row by matching band speed and
              leaves 160/180/200 kt alone). Sign: rbsPitchTable nose-up = NEGATIVE.
      THRUST (was LONGITUDINAL, forward flight): tune MAIN ROTOR THRUST
              (fza_sfmplus_tune_mainThrustTable) for level flight (climb -> 0), with the
              STABILATOR (fza_sfmplus_tune_stabLiftScalarTable) as a gentle longitudinal-
              trim ASSIST (small kStabAssist share of residual pitch error). Pitch is no
              longer owned here (the flapback axis owns it), so thrust settles on CLIMB
              alone.
      ROLL  : confirm the roll target is held. Tunes no force and moves no control -
              YOU set the roll; gates on the roll attitude error alone.
      VERT  : HOVER only - tune the IGE/OGE hover thrust var so holding the target
              collective yields level flight (climb -> 0). In forward flight thrust is
              handled by the THRUST axis, so VERT is not in the fwd sequence.

    Runs while fza_sfmplus_tune_masterOn is enabled. Fly stable at the commanded
    speed; it tunes the band you are in.

    Publishes for the GUI/overlay: fza_sfmplus_master_axis (string), _err, _band,
    and the live scalar being tuned (fza_sfmplus_master_scalar / _scalarName).

Parameters:
    _heli - The aircraft [Object].

Returns:
    Nothing (installs a per-frame handler; safe to call once per aircraft).

Author:
    BradMick
---------------------------------------------------------------------------- */
params ["_heli"];

if (isNull _heli) exitWith {};
if (_heli getVariable ["fza_sfmplus_masterOn", false]) exitWith {};
_heli setVariable ["fza_sfmplus_masterOn", true];

private _bands = [0.00, 10.29, 20.58, 36.01, 46.30, 51.44, 61.73, 66.88, 72.02];

private _ctx = createHashMapFromArray
[
    ["heli",      _heli],
    ["bands",     _bands],
    ["prevSpd",   0.0],
    //Axis case ids: 0 VERT/THRUST(main thrust vs climb), 1 LONGITUDINAL(now thrust-for-
    //climb assist, stab co-tune), 2 ROLL, 3 YAW(tail thrust), 4 PITCH(flapback): drive
    //cyclic to the flight-test position + tune the RBS/flapback pitch authority to hold
    //target pitch, stab assists. SEQUENCE (forward flight): YAW first (stop the spin),
    //then PITCH(flapback) (own the pitch trim envelope-wide), then THRUST (climb).
    //ROLL (case 2) is DELIBERATELY OUT of the sequence: its balancing mechanism (cyclic-
    //roll drive vs RBS roll torque) isn't built yet, so it tunes nothing and moves no
    //control - leaving it in makes the tuner HANG on it forever waiting for a roll it
    //can't produce. Add it back to seqOrder once the roll axis actually does something.
    //At a hover the sequence is rebuilt to YAW -> VERT (flapback needs airspeed, so it is
    //not in the hover sequence). seqIdx walks seqOrder.
    ["seqOrder",  [3, 4, 1]],   // YAW -> PITCH(flapback) -> THRUST (roll axis not built yet)
    ["seqIsHover",false],       // which sequence seqOrder currently holds; rebuilt on mode change
    ["seqIdx",    0],
    ["axis",      3],           // start on YAW (tail thrust) to kill the spin first
    ["settleT",   0.0],
    ["passMoved", false],

    //--- FORCE-SCALAR tuning rates (the actual job). Each is a table-step per unit
    //error per second; applied *dt. Clamped per table below. ---
    ["kThrust",   3.0e-4],      // mainThrustTable step per ft/min of climb (VERT hover)
    //THRUST axis (forward flight): main thrust chases CLIMB (climb -> 0). Pitch is owned
    //by the PITCH(flapback) axis now, so thrust no longer takes a pitch share; the
    //stabilator only ASSISTS longitudinal trim (kStabAssist, below).
    ["kThrustCo", 3.0e-4],      // mainThrustTable step per ft/min of climb (THRUST axis)
    //Yaw is tuned against the NET yaw MOMENT (Nm) - what the scalars actually control
    //(rate is its integral; targeting rate saturates/runs away). Gains are table-step
    //per Nm of net yaw moment, so they are small (moment ~ hundreds Nm).
    ["kTail",     6.0e-5],      // tailThrustTable (constant authority) step per Nm - HOVER ONLY
    ["kTorque",   9.0e-6],      // rtrTqScalarTable step per Nm - HOVER ONLY, then carried to all bands
    //Forward-flight airspeed TAIL TRIM (tailTrimTable) step per Nm of net yaw moment. The
    //trim is in baseThrust-scalar units (1.0 trim ~ baseThrust N ~ hundreds of kNm of yaw
    //moment), so the gain is TINY. Sized to null a ~2 kNm error over ~10 s without lurching.
    ["kTailTrim", 1.5e-7],      // tailTrimTable step per Nm of net yaw moment (forward flight)

    //PITCH(flapback) axis: the flapback/RBS pitch authority table (rbsPitchTable) is
    //tuned against the PITCH-ATTITUDE error while the cyclic sits at its flight-test
    //(forward-trim) position. rbsPitchTable is nose-up = NEGATIVE (source convention:
    //+pitch torque = nose DOWN). So when the nose sits TOO LOW vs target (err<0, nose
    //below target) we back the authority off toward zero (less negative); when the nose
    //is too HIGH (err>0) we deepen it (more negative). kFlapback is a table-step per deg
    //of pitch error. Stabilator co-assists here (kStabAssist) for longitudinal trim.
    ["kFlapback",  6.0e-3],     // rbsPitchTable step per deg of pitch error
    ["kStabAssist",4.0e-3],     // stabLiftScalarTable step per deg (gentle longitudinal assist)

    //Pitch/roll position hold is supplied externally (FMC pos hold); no gains here.
    //When yaw is not the active axis the pedal is FROZEN (not re-driven), so there is
    //no tuner yaw heading-hold gain - the FMC heading hold owns residual yaw drift.
    //Deliberate control-drive rate: the ACTIVE axis walks its force-trim toward the
    //flight-test control position by this fraction of the remaining gap per second.
    //Small = slow/deliberate (never a lurch); ~5%/s closes the gap over ~20 s.
    ["kDrive",    0.05],        // fraction of (target - current) trim per second

    //Tolerances (error must be under this to count as settled / on-target).
    ["tPitch",    0.3],         // deg
    ["tRoll",     0.3],         // deg
    ["tYaw",      120.0],       // Nm net yaw moment - "yaw balanced" tolerance
    ["tClimb",    40.0],        // ft/min
    ["tCtl",      0.03],        // trim units - control must be within this of the flight-test position

    ["settleReq", 1.5]
];

[{
    params ["_args", "_pfh"];
    _args params ["_ctx"];
    private _heli = _ctx get "heli";

    if (isNull _heli || {!alive _heli}) exitWith {
        _heli setVariable ["fza_sfmplus_masterOn", false];
        [_pfh] call CBA_fnc_removePerFrameHandler;
    };

    if (vehicle player != _heli) exitWith {};

    if !(_heli getVariable ["fza_sfmplus_tune_masterOn", false]) exitWith {
        _heli setVariable ["fza_sfmplus_master_axis", "off"];
    };

    private _dt = _heli getVariable ["fza_sfmplus_deltaTime", 0.0];
    if (_dt <= 0.0) exitWith {};

    private _bands = _ctx get "bands";

    //Airspeed + steady gate.
    (_heli getVariable ["fza_sfmplus_velModelSpace", [0,0,0]]) params ["_vx", "_vy"];
    private _spd     = vectorMagnitude [_vx, _vy];
    private _prevSpd = _ctx get "prevSpd";
    _ctx set ["prevSpd", _spd];
    private _accel = (abs (_spd - _prevSpd)) / _dt;

    //ETL (Effective Translational Lift) transition factor (0..1). Through ~10-46
    //kt (~5-24 m/s) the aero changes rapidly (inflow, stabilator, translational
    //lift), so the trim point is twitchy/moving and the tuner struggles to settle.
    //_etlFactor peaks (=1) in the middle of the transition and tapers to 0 outside
    //it. Used to LOOSEN the speed gate, SLOW the force tuning, and ADD pitch
    //damping in that region so it converges instead of hunting.
    private _etlFactor = 0.0;
    if (_spd > 5.0 && _spd < 24.0) then {
        //Triangular: 0 at 5 m/s, 1 at ~14.5 m/s (28 kt), 0 at 24 m/s.
        _etlFactor = 1.0 - (abs (_spd - 14.5) / 9.5);
        _etlFactor = [_etlFactor, 0.0, 1.0] call BIS_fnc_clamp;
    };

    //Speed-steady gate, loosened in the ETL region (speed naturally wanders there).
    //NOTE: this gates the FORCE TUNING ONLY - it must NOT stop the position hold /
    //stabilization, which has to run EVERY frame so the aircraft stays put when you
    //perturb it (e.g. raise collective). We record it as a flag and apply it just
    //before the tuning switch, AFTER the stabilization below.
    private _accelGate  = 0.5 + (1.5 * _etlFactor);   // 0.5 normally, up to 2.0 in ETL
    private _tuningAllowed = true;
    private _waitReason    = "";
    if (_accel > _accelGate) then { _tuningAllowed = false; _waitReason = "wait: speed unsteady"; };

    //Target speed: EXPLICITLY LOCKED via fza_sfmplus_tune_masterTargetKt (knots).
    //The tuner locks to the band nearest that speed and always works that ONE band,
    //even if your actual speed drifts - it never jumps bands mid-tune. It only
    //tunes while you're within a window of the target; outside the window it waits
    //(so off-speed data never corrupts the band). 0 (or <5 kt) = auto/nearest.
    private _tgtKt = _heli getVariable ["fza_sfmplus_tune_masterTargetKt", 0.0];
    private _bestIdx = 0;
    if (_tgtKt >= 5.0) then {
        //Band nearest the requested target speed.
        private _tgtMps = _tgtKt / 1.94384;
        private _bestErr = 1e9;
        { private _e = abs (_tgtMps - _x); if (_e < _bestErr) then { _bestErr = _e; _bestIdx = _forEachIndex; }; } forEach _bands;
        //Only TUNE while actual speed is within +/- ~8 kt (4.1 m/s) of the target
        //(off-speed data would corrupt the band). Stabilization still runs; only the
        //force tuning is held off. Flag it - do NOT exit (that would kill the hold).
        if ((abs (_spd - _tgtMps)) > 4.1) then {
            _tuningAllowed = false;
            _waitReason = format ["HOLD %1 kt (now %2)", round _tgtKt, round (_spd * 1.94384)];
        };
    } else {
        //Auto: nearest band to current speed.
        private _bestErr = 1e9;
        { private _e = abs (_spd - _x); if (_e < _bestErr) then { _bestErr = _e; _bestIdx = _forEachIndex; }; } forEach _bands;
    };
    _heli setVariable ["fza_sfmplus_master_band", _bestIdx];

    //HOVER STATE (IGE / OGE) - EXPLICIT, selected by two mutually-exclusive GUI toggles
    //(hoverIGE / hoverOGE; IGE wins if both on; both off = forward flight, use airspeed
    //bands). When set, the tuner tunes hover as its own case: pedal + cyclic go to the
    //IGE/OGE hover positions, then tail-rotor and main-rotor thrust are tuned. The
    //stabilator is NOT tuned at a hover.
    private _hoverState = "";
    if (_heli getVariable ["fza_sfmplus_tune_hoverIGE", false]) then { _hoverState = "IGE"; }
    else { if (_heli getVariable ["fza_sfmplus_tune_hoverOGE", false]) then { _hoverState = "OGE"; }; };
    _heli setVariable ["fza_sfmplus_master_hoverState", _hoverState];

    //TUNING SEQUENCE depends on hover vs forward flight.
    //   hover:   YAW -> VERT                    (flapback needs airspeed; stab inactive)
    //   forward: YAW -> PITCH(flapback) -> THRUST
    //In forward flight PITCH(flapback) (case 4) OWNS the pitch trim: it drives the cyclic
    //to the flight-test forward position and tunes the flapback/RBS pitch authority so the
    //ship holds target pitch across the whole envelope (the nose wants to pitch up the
    //entire time; the pilot counters with forward cyclic). THRUST (case 1) then tunes main
    //thrust for level flight (climb -> 0), with the stab co-assisting. ROLL (case 2) is NOT
    //in the sequence yet - its balancing mechanism isn't built, so it would hang the tuner
    //(see seqOrder note above). Rebuild + reset the walk index only on a mode change so
    //seqIdx never desyncs from the array it indexes.
    private _wantHoverSeq = (_hoverState != "");
    if ((_ctx get "seqIsHover") != _wantHoverSeq) then {
        _ctx set ["seqOrder", if (_wantHoverSeq) then { [3, 0] } else { [3, 4, 1] }];
        _ctx set ["seqIsHover", _wantHoverSeq];
        _ctx set ["seqIdx", 0];
        _ctx set ["axis", 3];        // always (re)start on YAW - pedal + tail thrust first
        _ctx set ["settleT", 0.0];
    };

    //Target lookup speed: when a target speed is COMMANDED, all targets are read
    //at that FIXED speed (not the live, fluctuating airspeed) - so pitch/roll/coll
    //targets are constant while tuning that band and don't drift as your actual
    //speed wobbles. Auto mode falls back to live speed.
    private _lookupSpd = if (_tgtKt >= 5.0) then { _tgtKt / 1.94384 } else { _spd };

    //=== ACTIVE-AXIS CONTROL DRIVE ==========================================
    //The tuner drives the controls to the real flight-test positions ONE axis at a
    //time: the ACTIVE axis (being tuned) slowly walks its force-trim toward the target
    //control position while its force scalar is tuned so the ship trims there. The
    //aircraft is kept stable meanwhile by the EXTERNAL position hold (FMC pos hold);
    //this function no longer runs its own hold.
    private _axisNow  = _ctx get "axis";   // 0 VERT/THRUST, 1 LONGITUDINAL(stab assist), 2 ROLL, 3 YAW, 4 PITCH(flapback)
    private _curPitch = (_heli call BIS_fnc_getPitchBank) select 0;
    private _curRoll  = (_heli call BIS_fnc_getPitchBank) select 1;
    //Target ATTITUDE (deg) - the force tuning uses these as its error signal (tune
    //flapback authority so the ship settles at target pitch; gate roll on target roll).
    private _tgtPitch = [_heli getVariable ["fza_sfmplus_tune_targetPitchTable", [[0,0]]], _lookupSpd] call fza_fnc_linearInterp select 1;
    private _tgtRoll  = [_heli getVariable ["fza_sfmplus_tune_targetRollTable",  [[0,0]]], _lookupSpd] call fza_fnc_linearInterp select 1;
    //Flight-test CYCLIC PITCH target (fwd+). The PITCH(flapback) axis drives the cyclic
    //pitch trim to this position (the forward-cyclic the pilot holds to counter the
    //envelope-wide nose-up), then tunes the flapback authority so the ship holds target
    //pitch there. In hover, use the IGE/OGE hover cyclic-pitch position.
    private _tgtCycPitch = if (_hoverState != "") then {
        _heli getVariable [(if (_hoverState == "IGE") then { "fza_sfmplus_tune_ige" } else { "fza_sfmplus_tune_oge" }) + "CycPitch", -0.342]
    } else {
        [_heli getVariable ["fza_sfmplus_tune_targetCycPitchTable", [[0,0]]], _lookupSpd] call fza_fnc_linearInterp select 1
    };
    //Flight-test PEDAL target (the only control the tuner drives - to a known pedal
    //position so the yaw axis can tune tail thrust against it). At a hover (explicit
    //IGE/OGE mode) it comes from the editable hover pedal target; else the airspeed
    //band. (Cyclic pitch/roll targets are NOT used - YOU fly pitch/roll; the tuner
    //never moves the cyclic.)
    private _tgtPed = if (_hoverState != "") then {
        _heli getVariable [(if (_hoverState == "IGE") then { "fza_sfmplus_tune_ige" } else { "fza_sfmplus_tune_oge" }) + "Pedal", -0.352]
    } else {
        [_heli getVariable ["fza_sfmplus_tune_targetPedalTable", [[0,0]]], _lookupSpd] call fza_fnc_linearInterp select 1
    };

    //Rate at which the pedal (YAW) walks toward its flight-test target (trim units
    //per second). Small + ETL-slowed so it's deliberate, never a lurch.
    private _driveRate = (_ctx get "kDrive") * (1.0 - 0.5 * _etlFactor);

    //--- CYCLIC PITCH: driven ONLY while PITCH(flapback) is the active axis (case 4),
    //exactly like the pedal is driven for YAW. Walk the pitch trim toward the flight-test
    //forward-cyclic position, then FREEZE (deadband = control tol) so it is rock-steady
    //while the flapback authority tunes the ship to target pitch against it. When PITCH is
    //NOT the active axis, LEAVE THE CYCLIC PITCH ALONE - it stays where the pitch tuning
    //put it (the flight-test position, balanced against the tuned flapback authority); a
    //later axis (thrust/roll) must not re-drive it. Any residual pitch drift is the FMC
    //attitude hold's job. Cyclic ROLL is still not driven this pass (roll axis unchanged).
    if (_axisNow == 4) then {
        private _pTrimCur = _heli getVariable ["fza_ah64_forceTrimPosPitch", 0.0];
        private _dCyc = _tgtCycPitch - _pTrimCur;
        if ((abs _dCyc) > (_ctx get "tCtl")) then {
            _heli setVariable ["fza_ah64_forceTrimPosPitch", ([_pTrimCur + ((_driveRate * _dCyc) * _dt),-1.0,1.0] call BIS_fnc_clamp), true];
        };
    };

    //--- YAW: active -> drive pedal trim toward target, then FREEZE. When yaw is NOT
    //the active axis, LEAVE THE PEDAL ALONE - it stays exactly where the YAW-axis
    //tuning put it (the flight-test position, with tail/torque balanced there). The
    //tuner must NOT re-drive the pedal to chase yaw rate while a later axis (e.g. stab
    //lift) is tuning, or it would break the yaw tuning you already dialed in. Any
    //residual heading drift is the FMC heading hold's job, not the tuner's.
    if (_axisNow == 3) then {
        private _yTrimCur = _heli getVariable ["fza_ah64_forceTrimPosYaw", 0.0];
        private _dPed = _tgtPed - _yTrimCur;
        //Freeze once at target (dead-band = the control tolerance) so the pedal is
        //rock-steady while tail thrust tunes.
        if ((abs _dPed) > (_ctx get "tCtl")) then {
            _heli setVariable ["fza_ah64_forceTrimPosYaw", ([_yTrimCur + ((_driveRate * _dPed) * _dt),-1.0,1.0] call BIS_fnc_clamp), true];
        };
    };

    //=== TUNING GATE ========================================================
    //Stabilization above ALWAYS runs (so the ship holds position hands-off). The
    //FORCE TUNING below only runs when speed is steady AND we are at the target
    //band - otherwise we hold position and wait, without corrupting the tables.
    if (!_tuningAllowed) exitWith { _heli setVariable ["fza_sfmplus_master_axis", _waitReason]; };

    //=== FORCE-SCALAR TUNING (the actual job) ================================
    //One force axis at a time, sequentially, settling between so cross-coupling
    //washes out. Each case computes an error, tunes the matching scalar table at
    //the current band, and publishes the live scalar value for the overlay.
    private _axis = _ctx get "axis";
    private _err = 0.0; private _axisName = ""; private _tol = 0.0;
    private _scalarName = ""; private _scalarVal = 0.0;
    //Optional SECOND error for co-tune axes (e.g. longitudinal: pitch is _err, climb is
    //_secondErr). Default "already satisfied" so single-error axes are unaffected.
    private _secondErr = 0.0; private _secondTol = 1e9;

    //Slow the force-tuning steps in the ETL region so the tuner takes small, stable
    //bites of a moving target instead of over-stepping and hunting. 1.0 normally,
    //down to 0.4 at the peak of the transition.
    private _tuneRate = 1.0 - (0.6 * _etlFactor);

    switch (_axis) do {
        case 0: {   //VERT: tune MAIN ROTOR THRUST so climb -> 0 at target collective.
            //In HOVER, route to the IGE or OGE-specific target collective + thrust
            //value (they differ because ground effect changes the power required).
            //In forward flight, use the airspeed-banded thrust table + coll target.
            private _tgtColl = 0.0;
            if (_hoverState != "") then {
                _axisName = format ["VERT (%1 hover): tuning THRUST", _hoverState];
                _tgtColl = if (_hoverState == "IGE")
                    then { _heli getVariable ["fza_sfmplus_tune_igeColl", 0.555] }
                    else { _heli getVariable ["fza_sfmplus_tune_ogeColl", 0.640] };
            } else {
                _axisName = "VERT: tuning MAIN THRUST";
                _tgtColl = [_heli getVariable ["fza_sfmplus_tune_targetCollTable", [[0,1]]], _lookupSpd] call fza_fnc_linearInterp select 1;
            };
            private _curColl = _heli getVariable ["fza_sfmplus_collectiveOutput", 0.0];
            if ((abs (_curColl - _tgtColl)) > 0.03) exitWith {
                _heli setVariable ["fza_sfmplus_master_axis", format ["%1: set coll to %2 (now %3)", _axisName, _tgtColl toFixed 2, _curColl toFixed 2]];
                _heli setVariable ["fza_sfmplus_master_scalarName", "mainThrust"];
            };
            _err = _heli getVariable ["fza_sfmplus_velClimb", 0.0];   // ft/min
            _tol = _ctx get "tClimb";
            _scalarName = "mainThrust";
            //Tune: +climb -> reduce thrust. HOVER tunes the IGE/OGE hover thrust var;
            //forward flight tunes the airspeed-banded main thrust table.
            if (_hoverState != "") then {
                private _hVar = if (_hoverState == "IGE") then { "fza_sfmplus_tune_igeThrust" } else { "fza_sfmplus_tune_ogeThrust" };
                private _hv   = _heli getVariable [_hVar, 1.0];
                if ((abs _err) >= _tol) then {
                    _hv = [_hv - ((_ctx get "kThrust") * _err * _dt * _tuneRate), 0.5, 1.5] call BIS_fnc_clamp;
                    _heli setVariable [_hVar, _hv];
                };
                _scalarVal = _hv;
            } else {
                if ((abs _err) >= _tol) then {
                    private _t = _heli getVariable ["fza_sfmplus_tune_mainThrustTable", _bands apply {[_x,1.0]}];
                    private _v = ((_t select _bestIdx) select 1) - ((_ctx get "kThrust") * _err * _dt * _tuneRate);
                    _v = [_v,0.5,1.5] call BIS_fnc_clamp;
                    _t set [_bestIdx, [(_t select _bestIdx) select 0, _v]];
                    _heli setVariable ["fza_sfmplus_tune_mainThrustTable", _t];
                    _scalarVal = _v;
                } else {
                    _scalarVal = ((_heli getVariable ["fza_sfmplus_tune_mainThrustTable", _bands apply {[_x,1.0]}]) select _bestIdx) select 1;
                };
            };
        };
        case 1: {   //THRUST (was LONGITUDINAL): tune MAIN THRUST for level flight
            //(climb -> 0), with the STABILATOR as a gentle longitudinal-trim ASSIST. The
            //PITCH TARGET is no longer owned here - the PITCH(flapback) axis (case 4) owns
            //pitch trim envelope-wide (cyclic driven to the flight-test position + flapback
            //authority tuned to hold target pitch). So thrust here serves CLIMB only; the
            //stab takes only a SMALL share of any residual pitch error (kStabAssist) to help
            //longitudinal trim without fighting the flapback axis for pitch authority.
            //Settle on CLIMB (primary); pitch is a soft second-error at a loose tolerance
            //since the flapback axis is responsible for holding it precisely.
            _axisName = "THRUST: tuning MAIN THRUST (climb -> 0), stab assists";
            private _climbErr = _heli getVariable ["fza_sfmplus_velClimb", 0.0];   // ft/min
            _err  = _climbErr;                          // ft/min (PRIMARY)
            _tol  = _ctx get "tClimb";
            private _pitchErr = _curPitch - _tgtPitch;  // deg, + = nose too high (assist only)
            _scalarName = "thrust+stab";

            //MAIN THRUST vs climb: +climb -> reduce thrust.
            if ((abs _climbErr) >= _tol) then {
                private _t = _heli getVariable ["fza_sfmplus_tune_mainThrustTable", _bands apply {[_x,1.0]}];
                private _v = ((_t select _bestIdx) select 1) - ((_ctx get "kThrustCo") * _climbErr * _dt * _tuneRate);
                _v = [_v,0.5,1.5] call BIS_fnc_clamp;
                _t set [_bestIdx, [(_t select _bestIdx) select 0, _v]];
                _heli setVariable ["fza_sfmplus_tune_mainThrustTable", _t];
                _scalarVal = _v;
            } else {
                _scalarVal = ((_heli getVariable ["fza_sfmplus_tune_mainThrustTable", _bands apply {[_x,1.0]}]) select _bestIdx) select 1;
            };

            //STAB LIFT assist: +err (nose high) -> more stab (down) lift lowers nose.
            //Small step (kStabAssist) so it trims longitudinally without stealing pitch
            //authority from the flapback axis. Only nudges when pitch is out of tol.
            if ((abs _pitchErr) >= (_ctx get "tPitch")) then {
                private _ts = _heli getVariable ["fza_sfmplus_tune_stabLiftScalarTable", _bands apply {[_x,1.0]}];
                private _vs = ((_ts select _bestIdx) select 1) + ((_ctx get "kStabAssist") * _pitchErr * _dt * _tuneRate);
                _vs = [_vs,0.2,3.0] call BIS_fnc_clamp;
                _ts set [_bestIdx, [(_ts select _bestIdx) select 0, _vs]];
                _heli setVariable ["fza_sfmplus_tune_stabLiftScalarTable", _ts];
            };
            //Settle on CLIMB alone (primary); pitch is owned by the flapback axis.
        };
        case 2: {   //ROLL: cyclic-roll trim is being driven to the flight-test
            //position (above). No force is tuned here (roll balance comes from the
            //disk tilt tuned in the YAW axis); we just confirm we're at the real
            //position AND at target roll before advancing.
            _axisName = "ROLL: driving to flight-test position (no force tuned)";
            _err = _curRoll - _tgtRoll;
            _tol = _ctx get "tRoll";
            _scalarName = "-";
        };
        case 3: {   //YAW: pedal trim is driven to the flight-test position + frozen
            //(above). Drive the NET yaw moment -> 0 at that pedal position.
            //
            //TAIL model restructured: the pedal->thrust ramp is a normalised +-1 curve, the
            //tail AUTHORITY (tailThrustTable) is now a FLAT CONSTANT setting the overall
            //magnitude (the OGE hover thrust point), and an AIRSPEED TRIM term (tailTrimTable,
            //added after authority) carries the forward-flight balance + reversal the pedal
            //fold-back cannot. So the tuner tunes DIFFERENT knobs by regime:
            //  - HOVER (band 0): tune the CONSTANT AUTHORITY + main TORQUE against net yaw
            //    moment; the tuned authority is written to ALL bands (kept flat/constant),
            //    and the tuned torque is written to all bands (fixed reference).
            //  - FORWARD FLIGHT (bands 1..8): authority + torque are fixed; the master tunes
            //    the airspeed TAIL TRIM (tailTrimTable) per band to null the net moment. This
            //    is where the ~100 kt tail-thrust reversal gets dialled in from MEASURED data.
            //
            //Error = NET yaw MOMENT (Nm) from the force log. Sign (confirmed): +Myaw =
            //nose RIGHT, - = LEFT. Drive net -> 0: +net (nose-right) needs MORE tail thrust
            //(both the authority constant and the trim term add +X tail force, so +net ->
            //increase either), LESS torque (main +).
            fza_sfmplus_forceLogOn = true;
            private _fLog = _heli getVariable ["fza_sfmplus_forceLogPublished", createHashMap];
            private _netYaw = 0;
            {
                _netYaw = _netYaw + ((_fLog getOrDefault [_x, [[0,0,0],[0,0,0]]]) select 1 select 2);
            } forEach ["Main Rotor","Tail Rotor","Right Wing","Left Wing","Vertical Fin","Stabilator","Fuselage Front","Fuselage Side","Fuselage Top","Yaw Damper"];
            _err = _netYaw;   // Nm, + = nose-right; drive net -> 0
            _tol = _ctx get "tYaw";
            private _isHoverYaw = (_hoverState != "");
            _scalarName = if (_isHoverYaw) then { "auth/torque" } else { "tailTrim" };
            if ((abs _err) >= _tol) then {
                if (_isHoverYaw) then {
                    //HOVER: tune the CONSTANT AUTHORITY (half the correction; torque takes the
                    //rest) and write it to ALL bands so it stays a flat constant.
                    private _tt = _heli getVariable ["fza_sfmplus_tune_tailThrustTable", _bands apply {[_x,1.0]}];
                    private _vt = ((_tt select 0) select 1) + (0.5 * (_ctx get "kTail") * _err * _dt * _tuneRate);
                    _vt = [_vt, 0.01, 2.0] call BIS_fnc_clamp;
                    { _tt set [_forEachIndex, [_x select 0, _vt]]; } forEach _tt;
                    _heli setVariable ["fza_sfmplus_tune_tailThrustTable", _tt];
                    _scalarVal = _vt;

                    //MAIN TORQUE: tuned ONLY at hover, then written to ALL bands (fixed ref).
                    private _tq = _heli getVariable ["fza_sfmplus_tune_rtrTqScalarTable", _bands apply {[_x,1.0]}];
                    private _vq = ((_tq select 0) select 1) - (0.5 * (_ctx get "kTorque") * _err * _dt * _tuneRate);
                    _vq = [_vq, 0.5, 1.5] call BIS_fnc_clamp;
                    { _tq set [_forEachIndex, [_x select 0, _vq]]; } forEach _tq;
                    _heli setVariable ["fza_sfmplus_tune_rtrTqScalarTable", _tq];
                } else {
                    //FORWARD FLIGHT: tune the airspeed TAIL TRIM at this band (+net -> more
                    //+X tail force -> increase trim). Full correction; authority/torque fixed.
                    private _trimTbl = _heli getVariable ["fza_sfmplus_tune_tailTrimTable", _bands apply {[_x,0.0]}];
                    private _vTrim = ((_trimTbl select _bestIdx) select 1) + ((_ctx get "kTailTrim") * _err * _dt * _tuneRate);
                    _vTrim = [_vTrim, -1.0, 1.0] call BIS_fnc_clamp;
                    _trimTbl set [_bestIdx, [(_trimTbl select _bestIdx) select 0, _vTrim]];
                    _heli setVariable ["fza_sfmplus_tune_tailTrimTable", _trimTbl];
                    _scalarVal = _vTrim;
                };
            } else {
                _scalarVal = if (_isHoverYaw)
                    then { ((_heli getVariable ["fza_sfmplus_tune_tailThrustTable", _bands apply {[_x,1.0]}]) select 0) select 1 }
                    else { ((_heli getVariable ["fza_sfmplus_tune_tailTrimTable", _bands apply {[_x,0.0]}]) select _bestIdx) select 1 };
            };
            _axisName = if (_isHoverYaw) then { "YAW (hover): tuning AUTHORITY + TORQUE (both -> all bands)" }
                                        else { "YAW: tuning airspeed TAIL TRIM (authority/torque fixed)" };
            //(Rotor disk tilt is now a live pilot-input effect - the master does not
            //tune it. Any standing yaw rate is left to the pilot/FMC to trim out.)
        };
        case 4: {   //PITCH(flapback): OWN the pitch trim across the envelope. The cyclic
            //pitch trim is being driven to the flight-test forward position + frozen
            //(above); here we tune the FLAPBACK/RBS PITCH AUTHORITY (rbsPitchTable) at this
            //band so the ship settles at TARGET PITCH with the cyclic pinned there. This is
            //the rotor's nose-up flapback (dissymmetry of lift + precession + transverse
            //flow) that the pilot counters with forward cyclic the whole time; the RBS
            //component proper dominates at 150+ kt (those bands are hand-set later).
            //
            //Sign (source convention): rbsPitchTable nose-up = NEGATIVE (+pitch torque =
            //nose DOWN). Pitch err = cur - tgt (+ = nose too HIGH). Step = +kFlapback*err:
            //  - nose too HIGH (err>0): authority += positive -> less negative -> weaker
            //    nose-up flapback -> nose drops toward target.
            //  - nose too LOW  (err<0): authority += negative -> more negative -> stronger
            //    nose-up flapback -> nose rises toward target.
            //Only the STANDARD bands (0-140 kt) are tuned; the 160/180/200 kt rows are set
            //by hand, so we address the rbsPitchTable row by MATCHING the band SPEED (not a
            //raw index) and skip if no matching row exists.
            _axisName = "PITCH(flapback): tuning RBS PITCH AUTHORITY to pitch target";
            _err  = _curPitch - _tgtPitch;              // deg, + = nose too high
            _tol  = _ctx get "tPitch";
            _scalarName = "rbsPitch";

            private _bandSpd = _bands select _bestIdx;
            private _rp  = _heli getVariable ["fza_sfmplus_tune_rbsPitchTable", []];
            //Find the row whose speed matches this band (leaves 160/180/200 kt untouched).
            private _rowIdx = -1;
            { if ((abs ((_x select 0) - _bandSpd)) < 0.01) exitWith { _rowIdx = _forEachIndex; }; } forEach _rp;
            if (_rowIdx < 0) then {
                //No matching row (table not seeded yet, or band off-table) - just report.
                _scalarVal = 0.0;
            } else {
                if ((abs _err) >= _tol) then {
                    private _v = ((_rp select _rowIdx) select 1) + ((_ctx get "kFlapback") * _err * _dt * _tuneRate);
                    //Clamp: nose-up authority is negative; allow 0 (no flapback) down to a
                    //strong -2.5. Never let it go POSITIVE (that would command nose-down
                    //flapback, which is unphysical here).
                    _v = [_v, -2.5, 0.0] call BIS_fnc_clamp;
                    _rp set [_rowIdx, [(_rp select _rowIdx) select 0, _v]];
                    _heli setVariable ["fza_sfmplus_tune_rbsPitchTable", _rp];
                    _scalarVal = _v;
                } else {
                    _scalarVal = ((_heli getVariable ["fza_sfmplus_tune_rbsPitchTable", []]) select _rowIdx) select 1;
                };
            };
        };
    };

    _heli setVariable ["fza_sfmplus_master_axis",       _axisName];
    _heli setVariable ["fza_sfmplus_master_err",        _err];
    _heli setVariable ["fza_sfmplus_master_scalarName", _scalarName];
    _heli setVariable ["fza_sfmplus_master_scalar",     _scalarVal];

    //Settle condition. In tolerance -> settle then advance; else keep tuning.
    //The yaw axis settles on the NET MOMENT alone. It does NOT gate on yaw RATE:
    //once the net moment is ~0 the yaw is balanced and the scalars have done their
    //job; a residual standing rate is inertia/damping dynamics the scalars cannot
    //fix, so blocking on it would lock the tuner on yaw forever (never advancing to
    //the other checks). Advance on moment-in-tolerance.
    //
    //CONTROL-POSITION GATE: the YAW axis drives the PEDAL and the PITCH(flapback) axis
    //drives the CYCLIC PITCH, so both gate on reaching their flight-test position (the
    //force/authority tuning isn't "done" until the control is where it belongs AND the
    //attitude/moment error is nulled there). ROLL is flown by YOU and VERT/THRUST has no
    //control-position target, so those gate on their error alone.
    private _ctlTol   = _ctx get "tCtl";
    private _ctlAtTgt = switch (_axisNow) do {
        case 3: { (abs ((_heli getVariable ["fza_ah64_forceTrimPosYaw",   0.0]) - _tgtPed))      < _ctlTol };
        case 4: { (abs ((_heli getVariable ["fza_ah64_forceTrimPosPitch", 0.0]) - _tgtCycPitch)) < _ctlTol };
        default { true };
    };
    //Settled when the primary error AND any co-tune second error are both in tol,
    //and the driven control has reached the flight-test position.
    private _inTol = ((abs _err) < _tol) && ((abs _secondErr) < _secondTol) && _ctlAtTgt;
    if (_inTol) then {
        private _settleT = (_ctx get "settleT") + _dt;
        _ctx set ["settleT", _settleT];
        if (_settleT >= (_ctx get "settleReq")) then {
            _ctx set ["settleT", 0.0];
            //Advance through the priority sequence (seqOrder), not raw case order.
            private _seq     = _ctx get "seqOrder";
            private _nextSeq = ((_ctx get "seqIdx") + 1) mod (count _seq);
            if (_nextSeq == 0) then {
                //Completed a full pass through all axes.
                if !(_ctx get "passMoved") then {
                    _heli setVariable ["fza_sfmplus_master_axis", "CONVERGED - forces tuned to targets"];
                    _heli setVariable ["fza_sfmplus_tune_masterOn", false];
                };
                _ctx set ["passMoved", false];
            };
            _ctx set ["seqIdx", _nextSeq];
            _ctx set ["axis", _seq select _nextSeq];
        };
    } else {
        _ctx set ["settleT", 0.0];
        _ctx set ["passMoved", true];
    };

}, 0, [_ctx]] call CBA_fnc_addPerFrameHandler;
