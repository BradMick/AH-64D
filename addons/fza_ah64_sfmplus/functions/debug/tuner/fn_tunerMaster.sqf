/* ----------------------------------------------------------------------------
Function: fza_sfmplus_fnc_tunerMaster

Description:
    Master auto-tuner. YOU fly the aircraft (set the pitch/roll attitude and airspeed);
    the tuner adjusts the force SCALARS so the aircraft is trimmed and stable at the
    attitude you are holding. It does NOT move the cyclic - the only control it drives
    is the PEDAL (to a known position so the yaw axis can tune tail thrust against it).

    ONE AXIS AT A TIME. Sequence depends on flight state:
      forward flight:  YAW -> THRUST
      hover (IGE/OGE):  YAW -> VERT
    Each axis tunes its force(s) against a measured error and only advances once that
    error is in tolerance (see per-axis notes below). (The former PITCH/ROLL flapback-RBS
    axes are RETIRED: BET makes flapback naturally, and the simple model's flapback is now
    the advance-ratio disc tilt - not a tuned table. Their tuning cases were removed.)

      YAW   : drive PEDAL trim to the flight-test pedal position + freeze it, then
              null NET yaw moment. MAIN TORQUE (fza_sfmplus_tune_rtrTqScalarTable) is
              tuned ONLY at a hover and copied to ALL bands (a fixed reference). TAIL
              THRUST (fza_sfmplus_tune_tailThrustTable) carries the balance: half at
              hover (torque takes the rest), the FULL correction in forward flight
              (torque fixed). The VERTICAL FIN is hand-tuned (fixed lift properties),
              so the master does not touch it. Tuned FIRST so spin stops early. (Rotor
              disk tilt is a live pilot-input effect and is NOT tuned here.)
      (PITCH/ROLL flapback axes RETIRED - see note above.)
      THRUST (was LONGITUDINAL, forward flight): tune MAIN ROTOR THRUST
              (fza_sfmplus_tune_mainThrustTable) for level flight (climb -> 0). Pitch is
              owned by the flapback axis, so thrust settles on CLIMB alone. The STABILATOR
              is NO LONGER tuned by the master loop - it is a fixed hand-tuned aero surface
              (its scalar table stays editable in the GUI/overlay, but the loop never
              writes it).
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
    //then PITCH(flapback) (own the pitch trim envelope-wide), then ROLL (own the roll trim
    //envelope-wide, mirror of pitch), then THRUST (climb).
    //ROLL (case 2) now has a real balancing mechanism: the cyclic ROLL is driven to its
    //flight-test position + frozen (mirror of cyclic pitch), then the RBS ROLL AUTHORITY
    //table (rbsRollTable, already wired into the main rotor _momentY) is tuned so the ship
    //settles at target roll with the cyclic pinned there. It sits AFTER pitch so the
    //longitudinal trim is set before the lateral trim is dialled in.
    //At a hover the sequence is rebuilt to YAW -> VERT (flapback/roll need airspeed, so
    //they are not in the hover sequence). seqIdx walks seqOrder.
    ["seqOrder",  [3, 1]],       // YAW -> THRUST (rebuilt on frame 1; RBS pitch/roll axes retired)
    ["seqIsHover",false],       // which sequence seqOrder currently holds; rebuilt on mode change
    ["seqInit",   false],       // false until the first per-frame rebuild has run (forces a model-aware rebuild on frame 1)
    ["seqIdx",    0],
    ["axis",      3],           // start on YAW (tail thrust) to kill the spin first
    ["settleT",   0.0],
    ["passMoved", false],

    //--- FORCE-SCALAR tuning rates (the actual job). Each is a table-step per unit
    //error per second; applied *dt. Clamped per table below. ---
    //ALL force gains bumped ~2.75x (2026-07-17): the original values nulled each value over
    //~10 s, which - stacked across axes + the settle/transition overhead - made the whole
    //tune take so long the aircraft drifted before it could settle (esp. tail trim, which
    //moved but never converged in time to transition). ~2.75x targets ~3-4 s per value.
    //Watch for hunting/overshoot in sim and back down any that oscillate.
    ["kThrust",   8.0e-4],      // mainThrustTable step per ft/min of climb (VERT hover)
    //THRUST axis (forward flight): main thrust chases CLIMB (climb -> 0). Pitch is owned
    //by the PITCH(flapback) axis now, so thrust no longer takes a pitch share. The
    //stabilator is NOT tuned by the loop (fixed hand-tuned surface).
    ["kThrustCo", 8.0e-4],      // mainThrustTable step per ft/min of climb (THRUST axis)
    //Yaw is tuned against the NET yaw MOMENT (Nm) - what the scalars actually control
    //(rate is its integral; targeting rate saturates/runs away). Gains are table-step
    //per Nm of net yaw moment, so they are small (moment ~ hundreds Nm).
    //kTail/kTailTrim were bumped 10x (6e-5->6e-4, 1.5e-7->1.5e-6) when tail _baseThrust was
    //cut 10x (102302->10230, realistic 10%-of-max tail rotor). A 10x smaller base thrust
    //means each unit of authority/trim makes 10x less yaw moment, so the tuner had to move
    //the table 10x further per Nm of error - i.e. it tuned 10x too slow. The 10x gain bump
    //restores the original convergence speed. kTorque is unaffected (main rotor, own base).
    //HOVER yaw is tuned against the HEADING-HOLD pedal command (fmcHdgHoldPedalYawOut,
    //clamped +-0.1 pedal units), NOT net moment - the hold masks the moment (see case 3).
    //These gains are table-step per unit of HOLD OUTPUT (pedal units), so they are LARGE vs
    //the old per-Nm gains (the signal is ~100x smaller in magnitude). Target: drive the
    //hold command to ~0 (nothing for it to do) = tail thrust balances torque on its own.
    ["kTail",     1.5],         // tailThrustTable (authority) step per unit hold-out - HOVER ONLY
    ["kTorque",   0.3],         // rtrTqScalarTable step per unit hold-out - HOVER ONLY, then carried to all bands
    //Forward-flight airspeed TAIL TRIM (tailTrimTable). Now tuned against BETA_G (the slip
    //ball / lateral specific force in g's) - drive beta_g -> 0 = laterally coordinated / ball
    //centered. NOT net yaw moment, NOT yaw rate. Sign (verified in-sim): MORE tail thrust ->
    //MORE positive beta_g, so +beta_g -> DECREASE tailTrim (the step SUBTRACTS). beta_g is
    //small (~0.01-0.5 g), so the gain is large vs the old per-Nm gain. HOVER still tunes on
    //net yaw moment (beta_g at V~0 is gravity/roll-dominated, not yaw) - kTailTrim is fwd only.
    ["kBetaG",    2.0e-2],      // tailTrimTable step per unit beta_g (g) - FORWARD FLIGHT
    ["tBetaG",    0.02],        // beta_g tolerance (g) - "ball centered" / coordinated (loosened
                                //   from 0.01: 0.01 g was tighter than the beta_g noise floor, so
                                //   the loop never reached the stop-band and integrated forever)
    //--- YAW forward-flight RATE-LIMIT + SETTLE-GATE (anti-hunt) ---------------------
    //The forward-flight yaw tuner is an INTEGRATOR: it steps tailTrim every frame while
    //|beta_g| >= tBetaG. But beta_g is heavily low-pass filtered (k=0.05, ~0.5s lag) AND
    //the airframe's yaw response to a tailTrim change lags too. Stepping every frame
    //winds tailTrim far past the value that zeroes beta_g before beta_g even reflects the
    //change -> overshoot -> the nose slams back and forth. Fix: (1) only take a step every
    //yawStepIntv seconds (let the nose settle + beta_g catch up between BITES), and (2)
    //never step while the nose is still swinging (|yawRate| > yawRateGate). Together these
    //make the loop take small, spaced bites of a settled error instead of integrating a
    //stale, lagging one. yawStepT accumulates dt between bites (reset on each step).
    ["yawStepIntv", 0.6],       // seconds between tailTrim steps (>= the beta_g filter lag)
    ["yawRateGate", 0.06],      // rad/s (~3.4 deg/s): don't step while yawing faster than this
    ["yawStepT",    0.0],       // accumulator: time since last tailTrim step

    //PITCH(flapback) axis: the flapback/RBS pitch authority table (rbsPitchTable) is
    //tuned against the PITCH-ATTITUDE error while the cyclic sits at its flight-test
    //(forward-trim) position. rbsPitchTable is nose-up = NEGATIVE (source convention:
    //+pitch torque = nose DOWN). So when the nose sits TOO LOW vs target (err<0, nose
    //below target) we back the authority off toward zero (less negative); when the nose
    //is too HIGH (err>0) we deepen it (more negative). kFlapback is a table-step per deg
    //of pitch error. (Stabilator is NOT tuned by the loop - fixed hand-tuned surface.)
    ["kFlapback",  1.65e-2],    // rbsPitchTable step per deg of pitch error
    //ROLL(RBS roll) axis: the RBS roll authority table (rbsRollTable) is tuned against the
    //ROLL-ATTITUDE error while the cyclic roll sits at its flight-test position. Mirror of
    //kFlapback but per deg of ROLL error. Sign is derived at the tuning step (case 2) from
    //how rbsRollTable feeds _momentY in fn_simpleRotorMain.
    ["kRoll",      1.65e-2],    // rbsRollTable step per deg of roll error

    //Pitch/roll position hold is supplied externally (FMC pos hold); no gains here.
    //When yaw is not the active axis the pedal is FROZEN (not re-driven), so there is
    //no tuner yaw heading-hold gain - the FMC heading hold owns residual yaw drift.
    //Deliberate control-drive rate: the ACTIVE axis walks its force-trim toward the
    //flight-test control position by this fraction of the remaining gap per second
    //(exponential approach). 0.45 closes ~95% of the gap in ~5 s (was 0.05 = ~20 s, which
    //made the whole tune take so long the aircraft drifted before it settled). It's a walk
    //to a KNOWN position (not error-chasing), so faster doesn't cause hunting. NOTE: halved
    //in the ETL band by _driveRate = kDrive*(1-0.5*_etlFactor), so ~5 s applies outside ETL.
    ["kDrive",    0.45],        // fraction of (target - current) trim per second (~5 s to close)

    //Tolerances (error must be under this to count as settled / on-target).
    ["tPitch",    0.3],         // deg
    ["tRoll",     0.3],         // deg
    ["tYaw",      0.005],       // hold-out (pedal units) - "hold has nothing to do" tolerance (HOVER yaw)
    ["tClimb",    40.0],        // ft/min
    ["tCtl",      0.03],        // trim units - control must be within this of the flight-test position

    ["settleReq", 1.5]
];

[{
    params ["_args", "_pfh"];
    _args params ["_ctx"];
    private _heli = _ctx get "heli";

    //ROTOR-MODEL TABLE ABSTRACTION: the master tuner drives the SAME error signals and math for
    //both rotor models; only the TARGET force table differs. In BET mode the physics-derived
    //forces are trimmed via the bet* output scalars (fn_rotorBlade/fn_rotor); in simple mode the
    //simple force-scalar tables. Resolve the target var names ONCE here so the tuning cases below
    //are model-agnostic. NOTE: the RBS pitch/roll axes are SKIPPED in BET mode (BET produces
    //flapback naturally from blade dynamics) - the seqOrder handles that below.
    private _isBet = (fza_ah64_sfmPlusRotorModel == 1);
    private _varMainThrust = if (_isBet) then { "fza_sfmplus_tune_betMainLiftTable"   } else { "fza_sfmplus_tune_mainThrustTable"  };
    private _varMainTorque = if (_isBet) then { "fza_sfmplus_tune_betMainTorqueTable" } else { "fza_sfmplus_tune_rtrTqScalarTable"  };
    private _varTailThrust = if (_isBet) then { "fza_sfmplus_tune_betTailLiftTable"   } else { "fza_sfmplus_tune_tailThrustTable"   };
    private _varTailTrim   = if (_isBet) then { "fza_sfmplus_tune_betTailTrimTable"   } else { "fza_sfmplus_tune_tailTrimTable"     };

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
    //thrust for level flight (climb -> 0); the stabilator is NOT tuned. ROLL (case 2) is NOT
    //in the sequence yet - its balancing mechanism isn't built, so it would hang the tuner
    //(see seqOrder note above). Rebuild + reset the walk index only on a mode change so
    //seqIdx never desyncs from the array it indexes.
    private _wantHoverSeq = (_hoverState != "");
    //Rebuild on a hover<->forward MODE CHANGE, or on the FIRST frame (seqInit false) so the
    //model-aware forward sequence is picked even without a transition (BET must drop rbs from
    //the start). Both operands are booleans - no Number/Bool compare (that threw a generic error).
    if (!(_ctx get "seqInit") || {(_ctx get "seqIsHover") != _wantHoverSeq}) then {
        //Forward sequence: SIMPLE = YAW -> PITCH(flapback/rbs) -> ROLL(rbs) -> THRUST.
        //Forward sequence = YAW -> THRUST for BOTH models. The RBS pitch/roll axes (cases 4 & 2)
        //are DROPPED: BET makes flapback naturally, and the SIMPLE model's RBS was RETIRED (the
        //advance-ratio disc flapback owns flapback now - not a tuned table). Hover [3,0] shared.
        _ctx set ["seqOrder", if (_wantHoverSeq) then { [3, 0] } else { [3, 1] }];
        _ctx set ["seqIsHover", _wantHoverSeq];
        _ctx set ["seqInit", true];
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
    private _axisNow  = _ctx get "axis";   // 0 VERT/THRUST, 1 THRUST(climb, no stab), 2 ROLL, 3 YAW, 4 PITCH(flapback)
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
        _heli getVariable [(if (_hoverState == "IGE") then { "fza_sfmplus_tune_ige" } else { "fza_sfmplus_tune_oge" }) + "CycPitch", -0.07]
    } else {
        [_heli getVariable ["fza_sfmplus_tune_targetCycPitchTable", [[0,0]]], _lookupSpd] call fza_fnc_linearInterp select 1
    };
    //Flight-test CYCLIC ROLL target (left+). The ROLL axis drives the cyclic roll trim to
    //this position (the lateral cyclic the pilot holds), then tunes the RBS roll authority
    //so the ship holds target roll there. In hover, use the IGE/OGE hover cyclic-roll pos.
    private _tgtCycRoll = if (_hoverState != "") then {
        _heli getVariable [(if (_hoverState == "IGE") then { "fza_sfmplus_tune_ige" } else { "fza_sfmplus_tune_oge" }) + "CycRoll", 0.06]
    } else {
        [_heli getVariable ["fza_sfmplus_tune_targetCycRollTable", [[0,0]]], _lookupSpd] call fza_fnc_linearInterp select 1
    };
    //Flight-test PEDAL target (the only control the tuner drives - to a known pedal
    //position so the yaw axis can tune tail thrust against it). At a hover (explicit
    //IGE/OGE mode) it comes from the editable hover pedal target; else the airspeed
    //band. (Cyclic pitch/roll targets are NOT used - YOU fly pitch/roll; the tuner
    //never moves the cyclic.)
    private _tgtPed = if (_hoverState != "") then {
        _heli getVariable [(if (_hoverState == "IGE") then { "fza_sfmplus_tune_ige" } else { "fza_sfmplus_tune_oge" }) + "Pedal", -0.60]
    } else {
        [_heli getVariable ["fza_sfmplus_tune_targetPedalTable", [[0,0]]], _lookupSpd] call fza_fnc_linearInterp select 1
    };

    //Rate at which the pedal (YAW) walks toward its flight-test target (trim units
    //per second). Small + ETL-slowed so it's deliberate, never a lurch.
    private _driveRate = (_ctx get "kDrive") * (1.0 - 0.5 * _etlFactor);

    //PILOT OVERRIDE: the tuner drives the pedal/cyclic to flight-test positions, but the pilot
    //must always be able to override. If you actively displace a control past a small deadband,
    //the tuner YIELDS that axis (stops driving it toward target) so your input reaches the
    //controls; when you release, it resumes driving to target next frame. Deadband > the
    //center-trim/breakout noise so a resting control still lets the tuner work.
    private _ovrDB       = 0.05;
    private _pedOverride = (abs (_heli getVariable ["fza_sfmplus_pedalLeftRight", 0.0]))  > _ovrDB;
    private _pchOverride = (abs (_heli getVariable ["fza_sfmplus_cyclicFwdAft",   0.0]))  > _ovrDB;
    private _rolOverride = (abs (_heli getVariable ["fza_sfmplus_cyclicLeftRight",0.0]))  > _ovrDB;

    //--- CYCLIC PITCH: driven ONLY while PITCH(flapback) is the active axis (case 4),
    //exactly like the pedal is driven for YAW. Walk the pitch trim toward the flight-test
    //forward-cyclic position, then FREEZE (deadband = control tol) so it is rock-steady
    //while the flapback authority tunes the ship to target pitch against it. When PITCH is
    //NOT the active axis, LEAVE THE CYCLIC PITCH ALONE - it stays where the pitch tuning
    //put it (the flight-test position, balanced against the tuned flapback authority); a
    //later axis (thrust/roll) must not re-drive it. Any residual pitch drift is the FMC
    //attitude hold's job.
    if (_axisNow == 4 && !_pchOverride) then {
        private _pTrimCur = _heli getVariable ["fza_ah64_forceTrimPosPitch", 0.0];
        private _dCyc = _tgtCycPitch - _pTrimCur;
        if ((abs _dCyc) > (_ctx get "tCtl")) then {
            _heli setVariable ["fza_ah64_forceTrimPosPitch", ([_pTrimCur + ((_driveRate * _dCyc) * _dt),-1.0,1.0] call BIS_fnc_clamp), true];
        };
    };

    //--- CYCLIC ROLL: driven ONLY while ROLL is the active axis (case 2), exactly like the
    //cyclic pitch for PITCH. Walk the roll trim toward the flight-test lateral-cyclic
    //position, then FREEZE (deadband = control tol) so it is rock-steady while the RBS roll
    //authority tunes the ship to target roll against it. When ROLL is NOT the active axis,
    //LEAVE THE CYCLIC ROLL ALONE - it stays where the roll tuning put it. Any residual roll
    //drift is the FMC attitude hold's job.
    if (_axisNow == 2 && !_rolOverride) then {
        private _rTrimCur = _heli getVariable ["fza_ah64_forceTrimPosRoll", 0.0];
        private _dCycR = _tgtCycRoll - _rTrimCur;
        if ((abs _dCycR) > (_ctx get "tCtl")) then {
            _heli setVariable ["fza_ah64_forceTrimPosRoll", ([_rTrimCur + ((_driveRate * _dCycR) * _dt),-1.0,1.0] call BIS_fnc_clamp), true];
        };
    };

    //--- YAW: active -> drive pedal trim toward target, then FREEZE. When yaw is NOT
    //the active axis, LEAVE THE PEDAL ALONE - it stays exactly where the YAW-axis
    //tuning put it (the flight-test position, with tail/torque balanced there). The
    //tuner must NOT re-drive the pedal to chase yaw rate while a later axis (e.g. stab
    //lift) is tuning, or it would break the yaw tuning you already dialed in. Any
    //residual heading drift is the FMC heading hold's job, not the tuner's.
    if (_axisNow == 3 && !_pedOverride) then {
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
    //Set true by the hover-yaw case when its error signal (heading-hold output) is being
    //forced to zero (yaw FMC off / springless / auto pedals) and is therefore invalid to
    //tune against. Blocks the settle gate from falsely "converging" on a dead signal.
    private _hoverSignalDead = false;

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
                    then { _heli getVariable ["fza_sfmplus_tune_igeColl", 0.56] }
                    else { _heli getVariable ["fza_sfmplus_tune_ogeColl", 0.64] };
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
                    private _t = _heli getVariable [_varMainThrust, _bands apply {[_x,1.0]}];
                    private _v = ((_t select _bestIdx) select 1) - ((_ctx get "kThrust") * _err * _dt * _tuneRate);
                    _v = [_v,0.5,1.5] call BIS_fnc_clamp;
                    _t set [_bestIdx, [(_t select _bestIdx) select 0, _v]];
                    _heli setVariable [_varMainThrust, _t];
                    _scalarVal = _v;
                } else {
                    _scalarVal = ((_heli getVariable [_varMainThrust, _bands apply {[_x,1.0]}]) select _bestIdx) select 1;
                };
            };
        };
        case 1: {   //THRUST (was LONGITUDINAL): tune MAIN THRUST for level flight
            //(climb -> 0). The PITCH TARGET is owned by the PITCH(flapback) axis (case 4),
            //which drives the cyclic to the flight-test position + tunes flapback authority to
            //hold target pitch. So thrust here serves CLIMB only. The STABILATOR is NO LONGER
            //tuned by the master loop - it is a fixed hand-tuned aero surface; the tuner must
            //not touch stabLiftScalarTable (removed to stop it fighting the flapback axis for
            //pitch authority and drifting the stab scalar). Settle on CLIMB alone.
            _axisName = "THRUST: tuning MAIN THRUST (climb -> 0)";
            private _climbErr = _heli getVariable ["fza_sfmplus_velClimb", 0.0];   // ft/min
            _err  = _climbErr;                          // ft/min (PRIMARY)
            _tol  = _ctx get "tClimb";
            _scalarName = "thrust";

            //MAIN THRUST vs climb: +climb -> reduce thrust.
            if ((abs _climbErr) >= _tol) then {
                private _t = _heli getVariable [_varMainThrust, _bands apply {[_x,1.0]}];
                private _v = ((_t select _bestIdx) select 1) - ((_ctx get "kThrustCo") * _climbErr * _dt * _tuneRate);
                _v = [_v,0.5,1.5] call BIS_fnc_clamp;
                _t set [_bestIdx, [(_t select _bestIdx) select 0, _v]];
                _heli setVariable [_varMainThrust, _t];
                _scalarVal = _v;
            } else {
                _scalarVal = ((_heli getVariable [_varMainThrust, _bands apply {[_x,1.0]}]) select _bestIdx) select 1;
            };
            //Settle on CLIMB alone (primary); pitch is owned by the flapback axis, stab is fixed.
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
            private _isHoverYaw = (_hoverState != "");
            //ERROR SIGNAL depends on regime:
            //  HOVER: NET yaw MOMENT (Nm) from the force log - the yaw-balance signal that
            //    applies when V~0 (nose not spinning). +Myaw = nose-right; drive net -> 0.
            //  FORWARD FLIGHT: BETA_G (slip ball, lateral specific force in g's) - drive it to
            //    0 = laterally coordinated / ball centered. Yaw rate / net moment are NOT used.
            if (_isHoverYaw) then {
                //HOVER ERROR = the HEADING-HOLD pedal command (fmcHdgHoldPedalYawOut), NOT the
                //net yaw moment. WHY: at a hover the heading hold is ALWAYS active and rides the
                //SAME tail-thrust axis as the pedal (fn_simpleRotorTail: _fmcYawOut is added to
                //_pedalInput). It continuously adds/removes tail thrust to hold heading, so it
                //ABSORBS any torque imbalance - the net yaw MOMENT stays ~0 no matter what the
                //authority scalar is. Tuning against net moment is therefore blind: the scalar's
                //effect is masked by the hold, so the tuner never sees convergence and slams the
                //authority to the clamp. The RIGHT target is the one found by hand: tune the
                //authority so the HOLD HAS NOTHING TO DO (its pedal command -> 0). When the
                //standing tail thrust alone balances the torque, the hold output is zero.
                //Sign: fmcHdgHoldPedalYawOut rides the pedal axis (left/NEG pedal = MORE tail
                //thrust). Negative hold-out = hold is adding left pedal = it wants MORE thrust =
                //standing authority too LOW. So +authority step = -kTail*hdgOut (below).
                _err = _heli getVariable ["fza_sfmplus_fmcHdgHoldPedalYawOut", 0.0];  // pedal units, - = hold wants MORE thrust
                _tol = _ctx get "tYaw";
            } else {
                _err = _heli getVariable ["fza_sfmplus_aero_beta_g", 0.0];   // g, + = lateral accel right
                _tol = _ctx get "tBetaG";
            };
            //VALIDITY GUARD (hover only): fn_fmc.sqf FORCES fmcHdgHoldPedalYawOut to 0 when yaw
            //FMC is off, or when springless/auto pedals are active. A forced-zero signal would
            //look like "converged" and the tuner would tune nothing (or freeze wrong). If any of
            //those is set, the hold-out signal is INVALID for tuning - skip the step and tell the
            //user why, rather than trust a dead signal.
            if (_isHoverYaw) then {
                private _yawFmcOff  = !(_heli getVariable ["fza_ah64_fmcYawOn", true]);
                private _pedalsMask = fza_ah64_sfmPlusSpringlessPedals || fza_ah64_sfmPlusAutoPedal;
                if (_yawFmcOff || _pedalsMask) then {
                    _hoverSignalDead = true;
                    _heli setVariable ["fza_sfmplus_master_axis",
                        if (_yawFmcOff) then { "YAW (hover): HELD - yaw FMC (heading hold) is OFF, no error signal" }
                                        else { "YAW (hover): HELD - springless/auto pedals mask the heading-hold signal" }];
                    _heli setVariable ["fza_sfmplus_master_scalarName", "auth/torque"];
                };
            };
            _scalarName = if (_isHoverYaw) then { "auth/torque" } else { "tailTrim" };
            if (!_hoverSignalDead && {(abs _err) >= _tol}) then {
                if (_isHoverYaw) then {
                    //HOVER: tune the CONSTANT AUTHORITY (half the correction; torque takes the
                    //rest) so the HEADING-HOLD command (_err) -> 0, and write it to ALL bands so
                    //it stays a flat constant.
                    //Sign: _err = hold-out; NEGATIVE = hold adding left pedal = wants MORE tail
                    //thrust = authority too LOW. So authority step = -kTail*err (neg err ->
                    //INCREASE authority). Note this is MINUS (the net-moment version was PLUS;
                    //the error signal's sign convention flipped when we switched to hold-out).
                    private _tt = _heli getVariable [_varTailThrust, _bands apply {[_x,1.0]}];
                    private _vt = ((_tt select 0) select 1) - (0.5 * (_ctx get "kTail") * _err * _dt * _tuneRate);
                    _vt = [_vt, 0.01, 2.0] call BIS_fnc_clamp;
                    { _tt set [_forEachIndex, [_x select 0, _vt]]; } forEach _tt;
                    _heli setVariable [_varTailThrust, _tt];
                    _scalarVal = _vt;

                    //MAIN TORQUE: tuned ONLY at hover, then written to ALL bands (fixed ref).
                    //If the hold wants MORE tail thrust (err<0), the main torque reaction is too
                    //strong -> REDUCE torque. torque step = +kTorque*err (neg err -> DECREASE).
                    private _tq = _heli getVariable [_varMainTorque, _bands apply {[_x,1.0]}];
                    private _vq = ((_tq select 0) select 1) + (0.5 * (_ctx get "kTorque") * _err * _dt * _tuneRate);
                    _vq = [_vq, 0.5, 1.5] call BIS_fnc_clamp;
                    { _tq set [_forEachIndex, [_x select 0, _vq]]; } forEach _tq;
                    _heli setVariable [_varMainTorque, _tq];
                } else {
                    //FORWARD FLIGHT: tune the airspeed TAIL TRIM at this band on BETA_G. Sign
                    //(verified in-sim): MORE tail thrust -> MORE positive beta_g, so +beta_g ->
                    //DECREASE tailTrim (SUBTRACT the step). Drives the ball to centered.
                    //
                    //RATE-LIMIT + SETTLE-GATE (anti-hunt): don't integrate every frame - that
                    //winds up past the target while the filtered beta_g + the airframe lag catch
                    //up, and the nose oscillates. Only take a step when BOTH:
                    //  (a) the nose has settled: |yawRate| <= yawRateGate (not mid-swing), and
                    //  (b) a full yawStepIntv has elapsed since the last step (beta_g reflects it).
                    //Between bites we HOLD tailTrim (report current value) and let the ship settle.
                    private _trimTbl = _heli getVariable [_varTailTrim, _bands apply {[_x,0.0]}];
                    private _curTrim = (_trimTbl select _bestIdx) select 1;
                    private _yawRate = abs ((_heli getVariable ["fza_sfmplus_angVelModelSpace", [0,0,0]]) select 2);
                    _ctx set ["yawStepT", (_ctx get "yawStepT") + _dt];
                    private _settled  = _yawRate <= (_ctx get "yawRateGate");
                    private _elapsed  = _ctx get "yawStepT";
                    private _intvDone = _elapsed >= (_ctx get "yawStepIntv");
                    if (_settled && _intvDone) then {
                        //Bite sized to the ELAPSED interval (not a single frame's dt): one
                        //deliberate correction per interval, so the rate-limit doesn't also
                        //shrink each step ~30x. Same integrator gain, just spaced out.
                        private _vTrim = _curTrim - ((_ctx get "kBetaG") * _err * _elapsed * _tuneRate);
                        _vTrim = [_vTrim, -1.0, 1.0] call BIS_fnc_clamp;
                        _trimTbl set [_bestIdx, [(_trimTbl select _bestIdx) select 0, _vTrim]];
                        _heli setVariable [_varTailTrim, _trimTbl];
                        _ctx set ["yawStepT", 0.0];   // reset the between-bites timer
                        _scalarVal = _vTrim;
                    } else {
                        //Holding between bites: leave tailTrim alone, report the current value.
                        _scalarVal = _curTrim;
                    };
                };
            } else {
                _scalarVal = if (_isHoverYaw)
                    then { ((_heli getVariable [_varTailThrust, _bands apply {[_x,1.0]}]) select 0) select 1 }
                    else { ((_heli getVariable [_varTailTrim, _bands apply {[_x,0.0]}]) select _bestIdx) select 1 };
            };
            _axisName = if (_isHoverYaw) then { "YAW (hover): tuning AUTHORITY + TORQUE (both -> all bands)" }
                                        else { "YAW: tuning airspeed TAIL TRIM (authority/torque fixed)" };
            //(Rotor disk tilt is now a live pilot-input effect - the master does not
            //tune it. Any standing yaw rate is left to the pilot/FMC to trim out.)
        };
    };

    //Don't clobber the "HELD - signal dead" status the hover-yaw case published.
    if (!_hoverSignalDead) then { _heli setVariable ["fza_sfmplus_master_axis", _axisName]; };
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
    //CONTROL-POSITION GATE: the YAW axis drives the PEDAL, the PITCH(flapback) axis drives
    //the CYCLIC PITCH, and the ROLL axis drives the CYCLIC ROLL, so each gates on reaching
    //its flight-test position (the force/authority tuning isn't "done" until the control is
    //where it belongs AND the attitude/moment error is nulled there). VERT/THRUST has no
    //control-position target, so it gates on its error alone.
    private _ctlTol   = _ctx get "tCtl";
    private _ctlAtTgt = switch (_axisNow) do {
        case 2: { (abs ((_heli getVariable ["fza_ah64_forceTrimPosRoll",  0.0]) - _tgtCycRoll))  < _ctlTol };
        case 3: { (abs ((_heli getVariable ["fza_ah64_forceTrimPosYaw",   0.0]) - _tgtPed))      < _ctlTol };
        case 4: { (abs ((_heli getVariable ["fza_ah64_forceTrimPosPitch", 0.0]) - _tgtCycPitch)) < _ctlTol };
        default { true };
    };
    //Settled when the primary error AND any co-tune second error are both in tol,
    //and the driven control has reached the flight-test position. A DEAD hover-yaw signal
    //(forced-zero hold output) is NEVER "settled" - block the advance so the tuner waits on
    //yaw instead of skipping it on a false zero.
    private _inTol = (!_hoverSignalDead) && ((abs _err) < _tol) && ((abs _secondErr) < _secondTol) && _ctlAtTgt;
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
