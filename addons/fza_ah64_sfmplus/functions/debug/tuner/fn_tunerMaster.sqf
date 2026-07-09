/* ----------------------------------------------------------------------------
Function: fza_sfmplus_fnc_tunerMaster

Description:
    Master auto-tuner. It DRIVES the controls to the real AH-64 flight-test positions
    itself - deliberately, ONE axis at a time - and tunes the force scalars so the
    aircraft is trimmed and stable AT those positions. The aircraft is kept in a stable
    hover meanwhile by the FMC attitude hold (pos submode, fn_fmcAttitudeHold); the
    master does not run or force any pitch/roll hold of its own.

    Deliberate ONE-AXIS-AT-A-TIME drive. Sequence depends on flight state:
      forward flight:  YAW -> PITCH -> ROLL -> VERT
      hover (IGE/OGE):  YAW -> VERT  (stabilator inactive - PITCH not tuned)
    The ACTIVE axis slowly walks its force-trim toward the flight-test control
    position while its force scalar is tuned. An axis is "done" only when its control
    has reached the real position AND its force is trimmed there.

      YAW   : drive PEDAL trim to the flight-test pedal position; tune tail-rotor
              thrust (fza_sfmplus_tune_tailThrustTable) + main-rotor torque
              (fza_sfmplus_tune_rtrTqScalarTable) so NET yaw moment -> 0, and the
              rotor disk tilt (fza_sfmplus_tune_rotorTiltTable) so yaw RATE -> 0.
              Tuned FIRST so the aircraft stops spinning before anything else.
      PITCH : drive CYCLIC-PITCH trim to the flight-test position; tune stabilator
              lift (fza_sfmplus_tune_stabLiftScalarTable) so the aircraft holds the
              target pitch attitude AT that cyclic position.
      ROLL  : drive CYCLIC-ROLL trim to the flight-test position and hold steady.
              Tunes no force directly (roll balance comes from the disk tilt tuned
              in the YAW axis); gates on being at the real position + target roll.
      VERT  : tune MAIN ROTOR THRUST (fza_sfmplus_tune_mainThrustTable, or the
              IGE/OGE hover thrust var) so holding the target collective yields
              level flight (climb -> 0). No control-position target (you can't
              "position" thrust); gates on climb only.

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
    //Axis case ids: 0 VERT(thrust), 1 PITCH(stab), 2 ROLL, 3 YAW(tail thrust).
    //Tuning SEQUENCE (priority order): tune YAW (tail thrust) first to stop the spin,
    //then PITCH (stab lift) and ROLL, then VERT (thrust). At a hover the sequence is
    //rebuilt to YAW -> VERT only (see the hover-state block). seqIdx walks seqOrder.
    ["seqOrder",  [3, 1, 2, 0]], // YAW -> PITCH -> ROLL -> VERT (forward flight)
    ["seqIsHover",false],       // which sequence seqOrder currently holds; rebuilt on mode change
    ["seqIdx",    0],
    ["axis",      3],           // start on YAW (tail thrust) to kill the spin first
    ["settleT",   0.0],
    ["passMoved", false],

    //--- FORCE-SCALAR tuning rates (the actual job). Each is a table-step per unit
    //error per second; applied *dt. Clamped per table below. ---
    ["kThrust",   3.0e-4],      // mainThrustTable step per ft/min of climb
    ["kStab",     2.0e-3],      // stabLiftScalarTable step per deg of pitch error
    //Yaw is tuned against the NET yaw MOMENT (Nm) - what the scalars actually control
    //(rate is its integral; targeting rate saturates/runs away). Gains are table-step
    //per Nm of net yaw moment, so they are small (moment ~ hundreds Nm).
    ["kTail",     6.0e-5],      // tailThrustTable step per Nm of net yaw moment (primary)
    ["kTorque",   9.0e-6],      // rtrTqScalarTable step per Nm of net yaw moment (slow trim)

    //Pitch/roll position hold is supplied externally (user PIDs in the hold block);
    //no gains for it here.
    ["kYawHold",  0.80],        // yaw heading-hold: trim per rad/s of yaw rate (stops spin)
    //Deliberate control-drive rate: the ACTIVE axis walks its force-trim toward the
    //flight-test control position by this fraction of the remaining gap per second.
    //Small = slow/deliberate (never a lurch); ~5%/s closes the gap over ~20 s.
    ["kDrive",    0.05],        // fraction of (target - current) trim per second

    //Tolerances (error must be under this to count as settled / on-target).
    ["tPitch",    0.3],         // deg
    ["tRoll",     0.3],         // deg
    ["tYaw",      120.0],       // Nm net yaw moment - "yaw balanced" tolerance
    ["kTilt",     40.0],        // deg of disk tilt per rad/s of yaw rate (nulls the standing rate)
    ["tYawRateT", 0.004],       // rad/s (~0.23 deg/s) - only tune tilt when rate exceeds this
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

    //TUNING SEQUENCE depends on hover vs forward flight. At a HOVER the stabilator is
    //inactive (no airflow) so PITCH is NOT tuned, and ROLL has no force to tune - the
    //only things to tune are the pedal-then-tail-thrust (YAW) and main thrust (VERT):
    //   hover:   YAW -> VERT
    //   forward: YAW -> PITCH -> ROLL -> VERT
    //Rebuild + reset the walk index only when the mode actually changes, so seqIdx
    //never desyncs from the array it indexes.
    private _wantHoverSeq = (_hoverState != "");
    if ((_ctx get "seqIsHover") != _wantHoverSeq) then {
        _ctx set ["seqOrder", if (_wantHoverSeq) then { [3, 0] } else { [3, 1, 2, 0] }];
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
    //aircraft is kept stable meanwhile by the EXTERNAL position hold (BradMick's FMC
    //pos-hold PIDs, wired in separately) - this function no longer runs its own hold.
    (_heli getVariable ["fza_sfmplus_angVelModelSpace", [0,0,0]]) params ["_wP","_wR","_wY"];

    private _axisNow  = _ctx get "axis";   // 0 VERT, 1 PITCH, 2 ROLL, 3 YAW
    private _curPitch = (_heli call BIS_fnc_getPitchBank) select 0;
    private _curRoll  = (_heli call BIS_fnc_getPitchBank) select 1;
    //Target ATTITUDE (deg) - the force tuning uses these as its error signal (tune
    //stab lift so the ship settles at target pitch; gate roll on target roll).
    private _tgtPitch = [_heli getVariable ["fza_sfmplus_tune_targetPitchTable", [[0,0]]], _lookupSpd] call fza_fnc_linearInterp select 1;
    private _tgtRoll  = [_heli getVariable ["fza_sfmplus_tune_targetRollTable",  [[0,0]]], _lookupSpd] call fza_fnc_linearInterp select 1;
    //Flight-test control-position targets (the positions the ACTIVE axis is driven to).
    //At a hover (explicit IGE/OGE mode) these come from the dedicated, editable hover
    //targets instead of the airspeed bands - so you get a distinct control target for
    //IGE vs OGE that you can set explicitly.
    private _tgtCycP  = 0.0; private _tgtCycR = 0.0; private _tgtPed = 0.0;
    if (_hoverState != "") then {
        private _pfx = if (_hoverState == "IGE") then { "fza_sfmplus_tune_ige" } else { "fza_sfmplus_tune_oge" };
        _tgtCycP = _heli getVariable [_pfx + "CycPitch", -0.342];
        _tgtCycR = _heli getVariable [_pfx + "CycRoll",  -0.045];
        _tgtPed  = _heli getVariable [_pfx + "Pedal",    -0.352];
    } else {
        _tgtCycP = [_heli getVariable ["fza_sfmplus_tune_targetCycPitchTable", [[0,0]]], _lookupSpd] call fza_fnc_linearInterp select 1;
        _tgtCycR = [_heli getVariable ["fza_sfmplus_tune_targetCycRollTable",  [[0,0]]], _lookupSpd] call fza_fnc_linearInterp select 1;
        _tgtPed  = [_heli getVariable ["fza_sfmplus_tune_targetPedalTable",    [[0,0]]], _lookupSpd] call fza_fnc_linearInterp select 1;
    };

    //Rate at which the ACTIVE axis walks its control toward the flight-test target
    //(trim units per second). Small + ETL-slowed so it's deliberate, never a lurch.
    private _driveRate = (_ctx get "kDrive") * (1.0 - 0.5 * _etlFactor);

    //--- ACTIVE-AXIS control drive: when PITCH or ROLL is the axis being tuned, walk
    //its cyclic trim toward the flight-test control position (deliberate, per-frame).
    if (_axisNow == 1) then {
        private _pTrimCur = _heli getVariable ["fza_ah64_forceTrimPosPitch", 0.0];
        _heli setVariable ["fza_ah64_forceTrimPosPitch", ([_pTrimCur + ((_driveRate * (_tgtCycP - _pTrimCur)) * _dt),-1.0,1.0] call BIS_fnc_clamp), true];
    };
    if (_axisNow == 2) then {
        private _rTrimCur = _heli getVariable ["fza_ah64_forceTrimPosRoll", 0.0];
        _heli setVariable ["fza_ah64_forceTrimPosRoll", ([_rTrimCur + ((_driveRate * (_tgtCycR - _rTrimCur)) * _dt),-1.0,1.0] call BIS_fnc_clamp), true];
    };

    //Pitch/roll are held at a stable hover by the FMC attitude hold (pos submode,
    //fn_fmcAttitudeHold) running on the normal FMC path - the master no longer runs
    //or forces any pitch/roll hold of its own.

    //--- YAW: active -> drive pedal trim toward target, then FREEZE; else heading-hold.
    //The pedal walks to the flight-test target and, once within tolerance, STOPS
    //moving (holds that exact position) so the tail-thrust tuning sees a fixed pedal
    //and can converge the net yaw moment against it.
    private _yTrimCur = _heli getVariable ["fza_ah64_forceTrimPosYaw", 0.0];
    private _yStep = 0.0;
    if (_axisNow == 3) then {
        private _dPed = _tgtPed - _yTrimCur;
        //Freeze once at target (dead-band = the control tolerance) so the pedal is
        //rock-steady while tail thrust tunes.
        if ((abs _dPed) > (_ctx get "tCtl")) then { _yStep = _driveRate * _dPed; };
    } else {
        _yStep = -((_ctx get "kYawHold") * _wY);
    };
    _heli setVariable ["fza_ah64_forceTrimPosYaw", ([_yTrimCur + (_yStep * _dt),-1.0,1.0] call BIS_fnc_clamp), true];

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
        case 1: {   //PITCH: cyclic-pitch trim is being driven to the flight-test
            //position (above); here we tune STAB LIFT so that AT that position the
            //ship holds the target pitch attitude. err = current pitch - target.
            //+ = nose too high. More stab (down) lift lowers the nose, so +err ->
            //increase stab lift scalar.
            _axisName = "PITCH: tuning STAB LIFT";
            _err = _curPitch - _tgtPitch;
            _tol = _ctx get "tPitch";
            _scalarName = "stabLift";
            if ((abs _err) >= _tol) then {
                private _t = _heli getVariable ["fza_sfmplus_tune_stabLiftScalarTable", _bands apply {[_x,1.0]}];
                private _v = ((_t select _bestIdx) select 1) + ((_ctx get "kStab") * _err * _dt * _tuneRate);
                _v = [_v,0.2,3.0] call BIS_fnc_clamp;
                _t set [_bestIdx, [(_t select _bestIdx) select 0, _v]];
                _heli setVariable ["fza_sfmplus_tune_stabLiftScalarTable", _t];
                _scalarVal = _v;
            } else {
                _scalarVal = ((_heli getVariable ["fza_sfmplus_tune_stabLiftScalarTable", _bands apply {[_x,1.0]}]) select _bestIdx) select 1;
            };
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
        case 3: {   //YAW: pedal trim is being driven to the flight-test position
            //(above). Tune TAIL THRUST and MAIN TORQUE together, 50/50, so the NET
            //yaw moment -> 0 at that pedal position. Both scalars are driven by the
            //SAME net-moment error every frame, each carrying half the correction.
            _axisName = "YAW: tuning TAIL + TORQUE (50/50)";
            //Error = NET yaw MOMENT (Nm) summed from the force log - the quantity
            //the scalars directly control. Force the log on so it has live data.
            //Sign convention (confirmed): +Myaw = nose turning RIGHT, - = LEFT.
            //Main rotor logs + (nose-right CCW reaction), tail logs - (nose-left).
            //We drive the net -> 0.
            fza_sfmplus_forceLogOn = true;
            private _fLog = _heli getVariable ["fza_sfmplus_forceLogPublished", createHashMap];
            private _netYaw = 0;
            {
                _netYaw = _netYaw + ((_fLog getOrDefault [_x, [[0,0,0],[0,0,0]]]) select 1 select 2);
            } forEach ["Main Rotor","Tail Rotor","Right Wing","Left Wing","Vertical Fin","Stabilator","Fuselage Front","Fuselage Side","Fuselage Top","Yaw Damper"];
            _err = _netYaw;   // Nm, + = nose-right; drive net -> 0
            _tol = _ctx get "tYaw";
            _scalarName = "tail/torque";
            if ((abs _err) >= _tol) then {
                //+net (nose-right) needs MORE tail thrust (tail Myaw is negative =
                //nose-left, so more tail lowers the net) and LESS main torque (main
                //Myaw is positive = nose-right, so less torque lowers the net).
                //=> tail steps +err, torque steps -err. 50/50 split.
                private _tt = _heli getVariable ["fza_sfmplus_tune_tailThrustTable", _bands apply {[_x,1.0]}];
                private _vt = ((_tt select _bestIdx) select 1) + (0.5 * (_ctx get "kTail") * _err * _dt * _tuneRate);
                _vt = [_vt, 0.25, 3.0] call BIS_fnc_clamp;
                _tt set [_bestIdx, [(_tt select _bestIdx) select 0, _vt]];
                _heli setVariable ["fza_sfmplus_tune_tailThrustTable", _tt];

                //Main-rotor torque: -err lowers the net when it's too high.
                private _tq = _heli getVariable ["fza_sfmplus_tune_rtrTqScalarTable", _bands apply {[_x,1.0]}];
                private _vq = ((_tq select _bestIdx) select 1) - (0.5 * (_ctx get "kTorque") * _err * _dt * _tuneRate);
                _vq = [_vq, 0.5, 1.5] call BIS_fnc_clamp;
                _tq set [_bestIdx, [(_tq select _bestIdx) select 0, _vq]];
                _heli setVariable ["fza_sfmplus_tune_rtrTqScalarTable", _tq];

                //Report tail thrust as the representative scalar for the readout.
                _scalarVal = _vt;
            } else {
                _scalarVal = ((_heli getVariable ["fza_sfmplus_tune_tailThrustTable", _bands apply {[_x,1.0]}]) select _bestIdx) select 1;
            };

            //ROTOR DISK TILT nulls the standing yaw RATE. Tail/torque balance the
            //net MOMENT (stops acceleration) but can't remove an existing rate; the
            //disk tilt provides a coupled yaw moment (via lateral thrust at the hub)
            //that actively decelerates the rotation to zero. Tune the tilt table at
            //this band against the yaw RATE. Sign: +yawRate (nose-right) needs a tilt
            //that produces a nose-LEFT coupled moment -> step tilt by -k*yawRate
            //(verified/adjustable). Only tune when the rate is meaningfully non-zero.
            private _yawRateNow = (_heli getVariable ["fza_sfmplus_angVelModelSpace", [0,0,0]]) select 2;   // rad/s, + = nose-right
            if ((abs _yawRateNow) >= (_ctx get "tYawRateT")) then {
                private _rtT = _heli getVariable ["fza_sfmplus_tune_rotorTiltTable", _bands apply {[_x,0.0]}];
                private _vTilt = ((_rtT select _bestIdx) select 1) - ((_ctx get "kTilt") * _yawRateNow * _dt * _tuneRate);
                _vTilt = [_vTilt, -10.0, 10.0] call BIS_fnc_clamp;
                _rtT set [_bestIdx, [(_rtT select _bestIdx) select 0, _vTilt]];
                _heli setVariable ["fza_sfmplus_tune_rotorTiltTable", _rtT];
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
    //CONTROL-POSITION GATE: an axis is only "done" when BOTH its force error is in
    //tolerance AND the control (force-trim) it drives has actually reached the real
    //flight-test position for this speed. That is the whole point of the deliberate
    //drive - the aircraft must be trimmed AT the real control position, not just at
    //some position that happens to balance. Pitch/roll/yaw check their driven trim
    //against the target; VERT has no control-position target so it gates on force only.
    private _ctlTol   = _ctx get "tCtl";
    private _ctlAtTgt = switch (_axisNow) do {
        case 1: { (abs ((_heli getVariable ["fza_ah64_forceTrimPosPitch", 0.0]) - _tgtCycP)) < _ctlTol };
        case 2: { (abs ((_heli getVariable ["fza_ah64_forceTrimPosRoll",  0.0]) - _tgtCycR)) < _ctlTol };
        case 3: { (abs ((_heli getVariable ["fza_ah64_forceTrimPosYaw",   0.0]) - _tgtPed )) < _ctlTol };
        default { true };   // VERT (0): no control-position target
    };
    private _inTol = ((abs _err) < _tol) && _ctlAtTgt;
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
