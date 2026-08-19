/* ----------------------------------------------------------------------------
Function: fza_sfmplus_fnc_getInput

Description:
    Handles keyboard and HOTAS input for the simulation.

Parameters:
    _heli - The helicopter to get information from [Unit].

Returns:
    ...

Examples:
    ...

Author:
    BradMick
---------------------------------------------------------------------------- */
params ["_heli"];
#include "\fza_ah64_sfmplus\headers\core.hpp"
#include "\fza_ah64_systems\headers\systems.hpp"

if (currentPilot _heli != player || !local _heli) exitWith {};

private _paused             = isNull findDisplay 49;
private _chatting           = isNull findDisplay 24;
private _inDialog           = !dialog;
private _isZeus             = isNull findDisplay 312;
private _inMap              = !visibleMap;
private _inInventory        = isNull findDisplay 602;
private _mplannerApplying   = _heli getVariable ["fza_mplanner_applying", false];

private _isPlaying          = isGameFocused && _paused && _chatting && _inDialog && _isZeus && _inMap && _inInventory && !fza_ah64_lastFrameGetIn && !_mplannerApplying;

private _config             = configOf _heli >> "Fza_SfmPlus";
private _configVehicles     = configOf _heli;
private _inputLagValue      = getNumber (_config >> "inputLagValue");

private _hydFailure         = false;
private _tailRtrFixed       = false;

private _deltaTime          = _heli getVariable "fza_sfmplus_deltaTime";

//Keyboard
private _kbStickyInterupt   = _heli getVariable "fza_sfmplus_kbStickyInterupt";
private _fltControlLockout  = _heli getVariable "fza_sfmplus_flightControlLockOut";

//Auto-pedal hover->nose-to-tail handover speed: 12.35 m/s = ~24kts GS (5.14444 m/s = 10kts, x2.4).
//Below this the pedals hold heading; above it they hold the velocity vector on the nose.
private _kbYawSwitchVel     = 5.14444 * 2.4;
private _yawBreakout        = false;
private _kbPedalLeftRight   = _heli getVariable "fza_sfmplus_kbPedalLeftRight";

private _priHydPumpDamage   = _heli getHitPointDamage "hit_hyd_pripump";
private _priHydPSI          = _heli getVariable "fza_systems_priHydPsi";

private _utilHydPumpDamage  = _heli getHitPointDamage "hit_hyd_utilpump";
private _utilHydPSI         = _heli getVariable "fza_systems_utilHydPsi";
private _utilLevel_pct      = _heli getVariable "fza_systems_utilLevel_pct";

private _emerHydOn          = _heli getVariable "fza_ah64_emerHydOn";
private _apuOn              = _heli getVariable "fza_systems_apuOn";

/////////////////////////////////////////////////////////////////////////////////////////////
// Cyclic & Pedal Input /////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////
private _heliCyclicFwdOut   = _heli getVariable "fza_sfmplus_heliCyclicForwardOut";
private _heliCyclicBackOut  = _heli getVariable "fza_sfmplus_heliCyclicBackwardOut";
private _cyclicFwdAft       = _heliCyclicFwdOut - _heliCyclicBackOut;
_cyclicFwdAft               = [_cyclicFwdAft, -1.0, 1.0] call BIS_fnc_clamp;
//systemChat format ["_cyclicFwdAft = %1", _cyclicFwdAft toFixed 2];

private _heliCyclicLeftOut  = _heli getVariable "fza_sfmplus_heliCyclicLeftOut";
private _heliCyclicRightOut = _heli getVariable "fza_sfmplus_heliCyclicRightOut";
private _cyclicLeftRight    = _heliCyclicLeftOut - _heliCyclicRightOut;
_cyclicLeftRight            = [_cyclicLeftRight, -1.0, 1.0] call BIS_fnc_clamp;
//systemChat format ["_cyclicLeftRight = %1", _cyclicLeftRight toFixed 2];

private _heliRudderLeftOut  = _heli getVariable "fza_sfmplus_heliRudderLeftOut";
private _heliRudderRightOut = _heli getVariable "fza_sfmplus_heliRudderRightOut";
private _pedalLeftRight     = _heliRudderRightOut - _heliRudderLeftOut;
_pedalLeftRight             = [_pedalLeftRight, -1.0, 1.0] call BIS_fnc_clamp;
//systemChat format ["_pedalLeftRight = %1", _pedalLeftRight toFixed 2];

if (!_isPlaying || (freeLook && fza_ah64_sfmPlusMouseAsJoystick)) then {
    _cyclicFwdAft      = 0.0;
    _cyclicLeftRight   = 0.0;
};

//Cyclic Pitch
if (fza_ah64_sfmPlusKeyboardStickyPitch) then {
    private _cyclicPitchValue     = _heli getVariable "fza_sfmplus_cyclicPitchValue";
    private _prevCyclicPitchValue = _heli getVariable "fza_sfmplus_prevCyclicPitchValue";

    if (_kbStickyInterupt) then {
        _cyclicFwdAft         = [_cyclicFwdAft, _prevCyclicPitchValue] call fza_sfmplus_fnc_getInterpInput;
    } else {
        if (_cyclicFwdAft > 0.1) then {
            _cyclicPitchValue = _cyclicPitchValue + 0.01;
        };
        if (_cyclicFwdAft < -0.1) then {
            _cyclicPitchValue = _cyclicPitchValue - 0.01;
        };

       //_cyclicPitcValue =

        _cyclicFwdAft         = [_cyclicPitchValue, -1.0, 1.0] call BIS_fnc_clamp;
        _heli setVariable ["fza_sfmplus_cyclicPitchValue",    [_cyclicPitchValue, -1.0, 1.0] call BIS_fnc_clamp];
        _heli setVariable ["fza_sfmplus_prevCyclicPitchValue", _cyclicPitchValue];
    };
};
//Cyclic Roll
if (fza_ah64_sfmPlusKeyboardStickyRoll) then {
    private _cyclicRollValue     = _heli getVariable "fza_sfmplus_cyclicRollValue";
    private _prevCyclicRollValue = _heli getVariable "fza_sfmplus_prevCyclicRollValue";

    if (_kbStickyInterupt) then {
        _cyclicLeftRight     = [_cyclicLeftRight, _prevCyclicRollValue] call fza_sfmplus_fnc_getInterpInput;
    } else {
        if (_cyclicLeftRight > 0.1) then {
            _cyclicRollValue = _cyclicRollValue + 0.01;
        };
        if (_cyclicLeftRight < -0.1) then {
            _cyclicRollValue = _cyclicRollValue - 0.01;
        };

        _cyclicLeftRight     = [_cyclicRollValue, -1.0, 1.0] call BIS_fnc_clamp;
        _heli setVariable ["fza_sfmplus_cyclicRollValue",    [_cyclicRollValue, -1.0, 1.0] call BIS_fnc_clamp];
        _heli setVariable ["fza_sfmplus_prevCyclicRollValue", _cyclicRollValue];
    };
};
//Pedal yaw
if (fza_ah64_sfmPlusKeyboardStickyYaw && !fza_ah64_sfmPlusAutoPedal) then {
    private _pedalYawValue     = _heli getVariable "fza_sfmplus_pedalYawValue";
    private _prevPedalYawValue = _heli getVariable "fza_sfmplus_prevPedalYawValue";

    if (_kbStickyInterupt) then {
        _pedalLeftRight    = [_pedalLeftRight, _prevPedalYawValue] call fza_sfmplus_fnc_getInterpInput;
    } else {
        if (_pedalLeftRight > 0.1) then {
            _pedalYawValue = _pedalYawValue + 0.01;
        };
        if (_pedalLeftRight < -0.1) then {
            _pedalYawValue = _pedalYawValue - 0.01;
        };

        _pedalLeftRight        = [_pedalYawValue, -1.0, 1.0] call BIS_fnc_clamp;
        _heli setVariable ["fza_sfmplus_pedalYawValue", [_pedalYawValue, -1.0, 1.0] call BIS_fnc_clamp];
        _heli setVariable ["fza_sfmplus_prevPedalYawValue", _pedalYawValue];
    };
};
/////////////////////////////////////////////////////////////////////////////////////////////
// KB Auto Pedal        /////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////
if (fza_ah64_sfmPlusAutoPedal) then {
    private _gndSpeed   = (_heli getVariable "fza_sfmplus_gndSpeed") * KNOTS_TO_MPS;
    /////////////////////////////////////////////////////////////////////////////////////////////
    // KB Pedal Yaw         /////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////
    private _yawBreakoutVal = (inputAction "HeliRudderRight") - (inputAction "HeliRudderLeft");
    if (_yawBreakoutVal < -0.01 || _yawBreakoutVal > 0.01) then {
        _yawBreakout = true;
    };

    //LIVE-TUNABLE gains: pull the tune vars onto each PID every frame so the SCAS tab and the
    //auto-pedal auto-tuner (fn_tunerPedalAuto) can dial these while flying. Seeded in fn_coreConfig.
    private _pidAutoPedalHdg  = _heli getVariable "fza_sfmplus_pid_autoPedalHdg";
    _pidAutoPedalHdg  set ["kp", _heli getVariable "fza_sfmplus_tune_apHdg_kp"];
    _pidAutoPedalHdg  set ["ki", _heli getVariable "fza_sfmplus_tune_apHdg_ki"];
    _pidAutoPedalHdg  set ["kd", _heli getVariable "fza_sfmplus_tune_apHdg_kd"];
    private _pidAutoPedalNtt  = _heli getVariable "fza_sfmplus_pid_autoPedalNtt";
    _pidAutoPedalNtt  set ["kp", _heli getVariable "fza_sfmplus_tune_apNtt_kp"];
    _pidAutoPedalNtt  set ["ki", _heli getVariable "fza_sfmplus_tune_apNtt_ki"];
    _pidAutoPedalNtt  set ["kd", _heli getVariable "fza_sfmplus_tune_apNtt_kd"];
    private _pidAutoPedalAero = _heli getVariable "fza_sfmplus_pid_autoPedalAero";
    _pidAutoPedalAero set ["kp", _heli getVariable "fza_sfmplus_tune_apAero_kp"];
    _pidAutoPedalAero set ["ki", _heli getVariable "fza_sfmplus_tune_apAero_ki"];
    _pidAutoPedalAero set ["kd", _heli getVariable "fza_sfmplus_tune_apAero_kd"];

    private _hdgOut        = 0.0;
    private _yawOutput     = 0.0;
    private _curHdg        = getDir _heli;
    private _desiredHdg    = _heli getVariable "fza_sfmPlus_autoPedalHdg";
    private _hdgError      = 0.0;

    //Heading capture. The setpoint is re-captured only while the pilot is actually on the pedals
    //(yaw breakout) - NOT every frame above 5kts as it used to be. Re-capturing continuously pinned
    //_hdgError to exactly zero at any speed above a hover, which both removed heading hold from the
    //5-24kt band AND fed the auto-tuner a structurally-zero error it would happily declare "settled".
    //Above the breakout the pedals are the pilot's; the heading PID re-engages against the heading
    //held at release (see the release-capture below).
    if (_yawBreakout) then {
        _desiredHdg       = getDir _heli;
        _heli setVariable ["fza_sfmPlus_autoPedalHdg",     _desiredHdg, true];
    };
    if (_yawBreakout || _gndSpeed > POS_HOLD_SPEED_SWITCH) then {
        _kbPedalLeftRight = [_kbPedalLeftRight, _pedalLeftRight, (1.0 / 0.1) * _deltaTime] call BIS_fnc_lerp;
        _kbPedalLeftRight = [_kbPedalLeftRight, -1.0, 1.0] call BIS_fnc_clamp;
        _pedalLeftRight   = _kbPedalLeftRight;

        _heli setVariable ["fza_sfmplus_kbPedalLeftRight", _kbPedalLeftRight];
    } else {
        _heli setVariable ["fza_sfmplus_kbPedalLeftRight", 0.0];
    };

    /////////////////////////////////////////////////////////////////////////////////////////////
    // THREE REGIMES. What the pedals are trying to achieve changes with the flight condition,
    // so each regime has its own error signal, its own units and its own PID:
    //
    //   HDG  (hover)          -> hold HEADING (deg). The trim ball is meaningless at a hover
    //                            (no meaningful airflow), so only where the nose points matters.
    //   NTT  (accel, <50ft)   -> NOSE-TO-TAIL trim: drive the KINEMATIC sideslip (beta_deg =
    //                            asin(velX/|vel|)) to zero, putting the velocity vector on the
    //                            nose. This is the regime the old code was missing entirely.
    //   AERO (>50ft AGL)      -> AERODYNAMIC trim: drive lateral accel (beta_g) to zero, i.e.
    //                            ball centered. This is the cruise/turn-coordination regime.
    //
    // Both transitions are BLENDED by weight, never switched, so the pedals don't step:
    //   hover->NTT over ground speed, NTT->AERO over AGL height across the 50ft boundary.
    //
    // ERROR SIGNS ARE THE VETTED ONES - do not "unify" them. Heading is (actual - desired); the
    // slip channels are NEGATED (desired - actual, desired = 0), exactly as the original slip
    // channel was. The two conventions differ because the underlying signals do: a heading error
    // and a lateral acceleration need opposite pedal sense to correct. NTT uses the same negated
    // form as AERO because beta_deg and beta_g share the same positive-right sense.
    /////////////////////////////////////////////////////////////////////////////////////////////
    //AERO uses the PER-VEHICLE filtered lateral accel, NOT the fza_ah64_sideslip global. That
    //global is the GAUGE signal: it is clamped to +-1 at 0.15g (so the controller would go BLIND
    //past 0.15g, seeing constant error however hard it skids) and fn_avionicsSlipIndicator exits
    //early unless the PLAYER is aboard, leaving a stale value from another aircraft for AI Apaches.
    private _betaG    = _heli getVariable "fza_sfmplus_aero_beta_g";     // g,   + = accel right
    private _betaDeg  = _heli getVariable "fza_sfmplus_aero_beta_deg";   // deg, + = flow from right
    //Radar altitude (feet) from the mod's altitude source of truth. Use the RAW (3rd) return, not the
    //displayed _radAlt - the displayed one is rounded to 10ft above 50ft, which would turn the regime
    //blend below into a staircase and chatter as the aircraft bobs across a step.
    ([_heli] call fza_sfmplus_fnc_getAltitude) params ["", "", "_radAltRaw"];

    //Setpoints are zero for both slip channels; the error is formed (desired - actual) to preserve
    //the original slip channel's sign. Heading keeps its own (actual - desired) form, unchanged.
    private _desiredSlip = 0.0;
    private _nttError    = _desiredSlip - _betaDeg;
    private _aeroError   = _desiredSlip - _betaG;

    //PILOT DEADBAND. A real pilot does not chase a ball that is a hair off centre - they accept a
    //small standing skid and only correct once it is actually visible. Feeding raw error straight to
    //the PID makes the pedals twitch at every tiny fluctuation in lateral g (which is noisy: it is a
    //filtered accelerometer, not a clean signal). Subtracting the deadband rather than zeroing inside
    //it keeps the response CONTINUOUS - no step at the edge of the band, the correction just starts
    //from zero once the error is worth correcting.
    if (abs _aeroError <= AUTOPEDAL_AERO_DEADBAND_G) then {
        _aeroError = 0.0;
    } else {
        _aeroError = _aeroError - (AUTOPEDAL_AERO_DEADBAND_G * ([1, -1] select (_aeroError < 0)));
    };
    if (abs _nttError <= AUTOPEDAL_NTT_DEADBAND_DEG) then {
        _nttError = 0.0;
    } else {
        _nttError = _nttError - (AUTOPEDAL_NTT_DEADBAND_DEG * ([1, -1] select (_nttError < 0)));
    };

    _hdgError            = [_curHdg - _desiredHdg] call CBA_fnc_simplifyAngle180;
    _hdgOut              = [_pidAutoPedalHdg,  _deltaTime, 0.0, _hdgError]  call fza_fnc_pidRun;
    private _nttOut      = [_pidAutoPedalNtt,  _deltaTime, 0.0, _nttError]  call fza_fnc_pidRun;
    private _aeroOut     = [_pidAutoPedalAero, _deltaTime, 0.0, _aeroError] call fza_fnc_pidRun;

    //Blend WEIGHTS.
    //
    //  wHover : 1 at a hover -> 0 by the hover handover speed. Owns the HEADING channel.
    //  wFast  : 0 below 50kt -> 1 above it.   "fast enough for aerodynamic trim"
    //  wHigh  : 0 below 50ft -> 1 above it.   "high enough for aerodynamic trim"
    //
    //AERODYNAMIC trim requires BOTH fast AND high - hence min(). Equivalently: if we are LOW **OR**
    //SLOW we hold NOSE-TO-TAIL trim (velocity vector on the nose). Altitude alone cannot decide it:
    //NOE flight can sit well above 50ft while masked behind terrain or trees and still be a
    //nose-to-tail regime, and a fast run down low is likewise nose-to-tail. Both must clear before
    //the ball becomes the thing being trimmed.
    //
    //And airspeed alone gates the HEADING channel: a 1kt hover at 200ft is still a hover, there is no
    //meaningful airflow to trim, so only heading matters there.
    private _wHover = 1.0 - (linearConversion [0.0, _kbYawSwitchVel, _gndSpeed, 0.0, 1.0, true]);
    private _wFast  = linearConversion [AUTOPEDAL_AERO_SPD_LO, AUTOPEDAL_AERO_SPD_HI, _gndSpeed,  0.0, 1.0, true];
    private _wHigh  = linearConversion [AUTOPEDAL_NTT_AGL_FT,  AUTOPEDAL_AERO_AGL_FT, _radAltRaw, 0.0, 1.0, true];
    //Aero share of the NON-hover authority: both gates must be open (min = logical AND).
    private _wCruise = _wFast min _wHigh;

    private _wHdg   = _wHover;
    private _wAero  = (1.0 - _wHover) * _wCruise;
    private _wNtt   = (1.0 - _wHover) * (1.0 - _wCruise);

    _yawOutput      = (_hdgOut * _wHdg) + (_nttOut * _wNtt) + (_aeroOut * _wAero);
    _yawOutput      = [_yawOutput, -1.0, 1.0] call BIS_fnc_clamp;

    /////////////////////////////////////////////////////////////////////////////////////////////
    // PILOT FEET MODEL. The auto-pedal stands in for a human on the pedals, and a human is not an
    // automaton: they do not apply a fresh PID solution 60 times a second. Two limits model that:
    //
    //   RATE LIMIT   - feet and legs have mass and the pedals have breakout force. A pilot cannot
    //                  step from one pedal position to another instantly; AUTOPEDAL_PEDAL_RATE caps
    //                  how much pedal travel can be added per second.
    //   SMOOTHING    - even within that rate, a pilot's correction is a smooth press, not a series
    //                  of micro-jabs. A first-order lag rolls off the high-frequency content the
    //                  PID produces from a noisy lateral-g signal.
    //
    // Applied to the BLENDED output so a regime handover is smoothed too. The PIDs still see the
    // true error - this shapes only how the "foot" delivers the correction, so tuning the gains
    // still does what you expect.
    /////////////////////////////////////////////////////////////////////////////////////////////
    //ORDER MATTERS: lag FIRST, then rate-limit the lagged result. Rate-limiting first and then
    //lagging takes only a fraction of an already-limited step, so the output converges to a fraction
    //of the commanded pedal and never actually reaches it - and the shortfall gets WORSE at higher
    //frame rates. Lag-then-limit is the correct order: the lag sets the smooth target, the rate limit
    //only intervenes when that target moves faster than a foot could follow.
    private _pedalPrev = _heli getVariable "fza_sfmplus_autoPedalPrevOut";
    //First-order lag toward the commanded pedal. Coefficient is frame-rate compensated so the feel
    //does not change with FPS.
    private _lagCoef   = [(_deltaTime / AUTOPEDAL_PEDAL_TAU), 0.0, 1.0] call BIS_fnc_clamp;
    private _pedalLag  = _pedalPrev + ((_yawOutput - _pedalPrev) * _lagCoef);
    //Rate limit: cap the per-frame CHANGE at what a foot could actually move in this timestep.
    private _maxStep   = AUTOPEDAL_PEDAL_RATE * _deltaTime;
    private _step      = [_pedalLag - _pedalPrev, -_maxStep, _maxStep] call BIS_fnc_clamp;
    _yawOutput         = [_pedalPrev + _step, -1.0, 1.0] call BIS_fnc_clamp;
    _heli setVariable ["fza_sfmplus_autoPedalPrevOut", _yawOutput];

    //Publish the live regime + errors for the auto-pedal auto-tuner and the tuner overlay to read.
    //The regime label is the regime that OWNS the pedals right now (largest blend weight), and the
    //weight itself is published alongside it: in a transition all three PIDs contribute, so grading
    //one regime's error while another drives a big share of the command would mis-attribute the
    //response. fn_tunerPedalAuto only grades when the dominant weight is high enough to be clean.
    private _regime = "hdg";
    private _wDom   = _wHdg;
    if (_wNtt  > _wDom) then { _regime = "ntt";  _wDom = _wNtt;  };
    if (_wAero > _wDom) then { _regime = "aero"; _wDom = _wAero; };

    _heli setVariable ["fza_sfmplus_autoPedalRegime",    _regime];
    _heli setVariable ["fza_sfmplus_autoPedalRegimeWgt", _wDom];
    //Publish the SAME error each PID is fed (not the raw beta), so the auto-tuner grades exactly
    //what the loop is acting on.
    _heli setVariable ["fza_sfmplus_autoPedalHdgErr",    _hdgError];
    _heli setVariable ["fza_sfmplus_autoPedalNttErr",    _nttError];
    _heli setVariable ["fza_sfmplus_autoPedalAeroErr",   _aeroError];
    _heli setVariable ["fza_sfmplus_autoPedalOut",       _yawOutput];

    private _hdgHoldBreakout     = (_pedalLeftRight <= -HDG_HOLD_BREAKOUT_VALUE && _pedalLeftRight < 0.0) || (_pedalLeftRight >= HDG_HOLD_BREAKOUT_VALUE && _pedalLeftRight > 0.0);
    private _prevHdgHoldBreakout = _heli getVariable ["fza_sfmplus_prevAutoPedalHdgBreakout", false];
    if (_yawBreakout) then {
        [_pidAutoPedalHdg]  call fza_fnc_pidReset;
        [_pidAutoPedalNtt]  call fza_fnc_pidReset;
        [_pidAutoPedalAero] call fza_fnc_pidReset;
        //Re-seed the pilot-feet filter to where the PILOT'S pedal actually is, so when they release
        //the auto-pedal picks up from that position instead of rate-limiting back from a stale one.
        _heli setVariable ["fza_sfmplus_autoPedalPrevOut", _pedalLeftRight];
    } else {
        //Release capture: on the falling edge of the pedal breakout, hold the heading the pilot let
        //go at. No longer gated to sub-5kt - the heading channel is live at every speed now, so the
        //setpoint has to be re-captured on release at every speed too, or the PID would fight to
        //recover a heading from before the pilot's pedal input.
        if (_prevHdgHoldBreakout && !_hdgHoldBreakout) then {
            _heli setVariable ["fza_sfmPlus_autoPedalHdg", getDir _heli, true];
        };
        _heli setVariable ["fza_ah64_forceTrimPosYaw", _yawOutput, true];
    };
    _heli setVariable ["fza_sfmplus_prevAutoPedalHdgBreakout", _hdgHoldBreakout];
};
/////////////////////////////////////////////////////////////////////////////////////////////
// KB Auto Attitude     /////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////
//Auto-attitude IS the pilot's hands on the cyclic, exactly as the auto-pedal is their feet - and
//specifically a MACHINE pilot: perfect, tireless, no use for hold modes. It owns the cyclic and
//positions it every frame; the pilot's keys say what to ACHIEVE, not where to put the stick. It
//neither drives nor defers to the FMC holds - those are realistic-only, for the human pilot.
//See the AUTO_ATT_* block in core.hpp for the three regimes and the gating rule.
private _autoAtt = fza_ah64_sfmplusRealismSetting != REALISTIC;

//REGIME WEIGHTS - POS (hover) / VEL (transition) / ATT (cruise). Blended, never switched.
//  wPos : 1 below 5kt -> 0 by 15kt.                    "stopped, so hold position"
//  wFast: 0 below 45kt -> 1 above 55kt.                "fast enough for attitude"
//  wHigh: 0 below 40ft -> 1 above 60ft.                "high enough for attitude"
//ATT requires BOTH fast AND high (min = logical AND) - the same LOW-OR-SLOW rule the auto-pedal
//uses. Whatever is left after POS and ATT have taken their share belongs to VEL.
private _autoAttWPos = 0.0;
private _autoAttWVel = 0.0;
private _autoAttWAtt = 0.0;
//Ground velocity in MODEL space (X = right+, Y = forward+), wind excluded - this is what the POS
//and VEL regimes null. velModelSpaceNoWind is the same signal the FMC position hold uses.
private _autoAttVelX = 0.0;
private _autoAttVelY = 0.0;
private _autoAttGS   = 0.0;
private _autoAttAGL  = 0.0;
if (_autoAtt) then {
    _autoAttGS = (_heli getVariable "fza_sfmplus_gndSpeed") * KNOTS_TO_MPS;
    //RAW radar altitude (3rd return), not the displayed one - the displayed value is rounded to
    //10ft above 50ft, which would turn this blend into a staircase as the aircraft bobs.
    ([_heli] call fza_sfmplus_fnc_getAltitude) params ["", "", "_aaRadAlt"];
    _autoAttAGL = _aaRadAlt;

    (_heli getVariable "fza_sfmplus_velModelSpaceNoWind") params ["_aaVelX", "_aaVelY"];
    _autoAttVelX = _aaVelX;
    _autoAttVelY = _aaVelY;

    _autoAttWPos = 1.0 - (linearConversion [AUTO_ATT_POS_SPD_LO, AUTO_ATT_POS_SPD_HI, _autoAttGS, 0.0, 1.0, true]);
    private _wFast = linearConversion [AUTO_ATT_ATT_SPD_LO, AUTO_ATT_ATT_SPD_HI, _autoAttGS,  0.0, 1.0, true];
    private _wHigh = linearConversion [AUTO_ATT_ATT_AGL_LO, AUTO_ATT_ATT_AGL_HI, _autoAttAGL, 0.0, 1.0, true];
    //ATT takes its share of whatever POS has left; VEL gets the remainder.
    _autoAttWAtt = (1.0 - _autoAttWPos) * (_wFast min _wHigh);
    _autoAttWVel = 1.0 - _autoAttWPos - _autoAttWAtt;

    _heli setVariable ["fza_sfmplus_autoAttWPos", _autoAttWPos];
    _heli setVariable ["fza_sfmplus_autoAttWVel", _autoAttWVel];
    _heli setVariable ["fza_sfmplus_autoAttWAtt", _autoAttWAtt];
};

if (_autoAtt) then {
    /////////////////////////////////////////////////////////////////////////////////////////
    // PILOT AUTHORITY. Same contract as the auto-pedal: while the pilot is ON the cyclic they
    // have FULL, uncontested control - the auto modes never fight an input, they only restore
    // equilibrium once the pilot lets go. Concretely, a live key does three things:
    //   1. commands the regime directly (attitude target sweep / hover reposition velocity),
    //   2. suspends the HOVER position loop and holds its integral frozen (no windup while the
    //      pilot deliberately flies off the datum),
    //   3. on RELEASE, re-captures the datum wherever the aircraft now is - so the aircraft
    //      settles where the pilot left it instead of flying back to a stale point.
    /////////////////////////////////////////////////////////////////////////////////////////
    private _pitchKey = 0.0;
    private _rollKey  = 0.0;
    if ((abs _cyclicFwdAft)    > AUTO_ATT_KEY_DEADBAND) then { _pitchKey = _cyclicFwdAft;    };
    if ((abs _cyclicLeftRight) > AUTO_ATT_KEY_DEADBAND) then { _rollKey  = _cyclicLeftRight; };
    private _cyclicBreakout     = (_pitchKey != 0.0) || (_rollKey != 0.0);
    private _prevCyclicBreakout = _heli getVariable ["fza_sfmplus_autoAttBreakout", false];
    //Release capture: on the falling edge of the breakout, the datum becomes wherever we are now.
    if (_prevCyclicBreakout && !_cyclicBreakout) then {
        _heli setVariable ["fza_sfmplus_autoHoverDatum", getPos _heli];
        _heli setVariable ["fza_sfmplus_autoHoverIntX",  0.0];
        _heli setVariable ["fza_sfmplus_autoHoverIntY",  0.0];
    };
    //HANDS RE-SEED, same as the auto-pedal does for the feet: while the pilot is on the cyclic,
    //FREEZE the hands filter at the current trim position. Without this the filter state goes
    //stale during the breakout and, on release, the machine pilot rate-limits back from wherever
    //it was left rather than moving on from where the stick actually is - a visible lurch at
    //exactly the moment the pilot hands control back.
    if (_cyclicBreakout) then {
        _heli setVariable ["fza_sfmplus_autoAttPrevPitch", _heli getVariable ["fza_ah64_forceTrimPosPitch", 0.0]];
        _heli setVariable ["fza_sfmplus_autoAttPrevRoll",  _heli getVariable ["fza_ah64_forceTrimPosRoll",  0.0]];
    };
    _heli setVariable ["fza_sfmplus_autoAttBreakout", _cyclicBreakout];

    /////////////////////////////////////////////////////////////////////////////////////////
    // ATTITUDE REGIME - hold the swept pitch/roll target. Runs every frame regardless of the
    // blend weight so its PIDs never see a discontinuity; the weight only decides how much of
    // its output reaches the cyclic.
    /////////////////////////////////////////////////////////////////////////////////////////
    private _pidAutoPitch    = _heli getVariable "fza_sfmplus_pid_autoPitch";
    private _pidAutoRoll     = _heli getVariable "fza_sfmplus_pid_autoRoll";
    private _autoPitchTarget = _heli getVariable "fza_sfmplus_autoPitchTarget";
    private _autoRollTarget  = _heli getVariable "fza_sfmplus_autoRollTarget";
    (_heli call BIS_fnc_getPitchBank) params ["_curPitch", "_curRoll"];

    /////////////////////////////////////////////////////////////////////////////////////////
    // ENVELOPE. The keyboard technique is to MASH the key until the target hits the limit and
    // stays there, so these limits ARE the commanded attitude in normal use. Held sticky-control
    // -interrupt selects the EXPANDED envelope. See the AUTO_ATT_*LIMIT block in core.hpp.
    /////////////////////////////////////////////////////////////////////////////////////////
    //NOTE on the reuse of _kbStickyInterupt: it also drives the KeyboardSticky pitch/roll/yaw
    //branches near the top of this file, but those only run when their own settings are enabled -
    //and sticky control is a competing solution to the same problem auto-attitude solves, so a
    //player will not have both. If that ever changes, this needs its own action.
    //PITCH is ASYMMETRIC and SCHEDULED - nose-down authority is earned with height and speed, nose
    //up is not gated (nothing above the aircraft to hit). This is the ACCELERATION PROFILE: at a
    //3ft hover only 5 deg nose-down is available, opening to 10 with speed while still low, then
    //15 once above 50ft. Override expands BOTH directions to 30 and DOES bypass the nose-down
    //gates - if the pilot holds it at 3 feet and dives it in, that is their call.
    private _pitchUpLimit = AUTO_ATT_PITCH_UP_LIMIT;
    //Nose-down: speed schedule first (5 -> 10 deg), then the height gate opens it toward 15.
    private _dnBySpeed    = linearConversion [AUTO_ATT_PITCH_DN_SPD_LO, AUTO_ATT_PITCH_DN_SPD_HI, _autoAttGS, AUTO_ATT_PITCH_DN_LIMIT_GND, AUTO_ATT_PITCH_DN_LIMIT_LOW, true];
    private _dnByHeight   = linearConversion [AUTO_ATT_PITCH_GND_AGL, AUTO_ATT_ATT_AGL_HI, _autoAttAGL, 0.0, 1.0, true];
    private _pitchDnLimit = _dnBySpeed + ((AUTO_ATT_PITCH_DN_LIMIT_HI - _dnBySpeed) * _dnByHeight);
    //Within GND_AGL of the ground the ground clamp is absolute (no speed credit) - this is what
    //stops a fast, low pass from unlocking nose-down authority right above the deck.
    if (_autoAttAGL <= AUTO_ATT_PITCH_GND_AGL) then { _pitchDnLimit = AUTO_ATT_PITCH_DN_LIMIT_GND; };
    if (_kbStickyInterupt) then {
        _pitchUpLimit = AUTO_ATT_PITCH_LIMIT_EXP;
        _pitchDnLimit = AUTO_ATT_PITCH_LIMIT_EXP;
    };

    private _rollCap    = [AUTO_ATT_ROLL_LIMIT,  AUTO_ATT_ROLL_LIMIT_EXP]  select (_kbStickyInterupt);
    private _turnRate   = [AUTO_ATT_TURN_RATE,   AUTO_ATT_TURN_RATE_EXP]   select (_kbStickyInterupt);
    //Bank for the target turn rate at the current speed: bank = atan(V * omega / g), omega in
    //rad/s. Below ETL this collapses toward zero (no meaningful turn at a hover), so a floor keeps
    //some roll authority for repositioning; the hard cap bounds the top end at high speed.
    private _rateBank   = atan ((_autoAttGS * (_turnRate * (pi / 180.0))) / 9.806);
    private _rollLimit  = [(_rateBank max AUTO_ATT_TURN_MIN_BANK), 0.0, _rollCap] call BIS_fnc_clamp;

    //PITCH target sweep - PERSISTS on release (pitch attitude selects airspeed). The target is
    //only ever MOVED, never snapped, so it stays continuous across press and release alike.
    if (_pitchKey != 0.0) then {
        //Forward cyclic (+) commands nose DOWN, so the target moves negative.
        _autoPitchTarget = _autoPitchTarget - (_pitchKey * AUTO_ATT_PITCH_RATE * _deltaTime);
        _heli setVariable ["fza_sfmplus_autoPitchTarget", _autoPitchTarget];
    };
    //Clamp EVERY frame, not only while the key is down: the nose-down limit MOVES with height and
    //speed, so a 15 deg dive that was legal at 200ft has to be walked back as the aircraft
    //descends through 50ft - and releasing the override has to bring an expanded target back
    //inside. Asymmetric: -down for nose low, +up for nose high.
    _autoPitchTarget = [_autoPitchTarget, -_pitchDnLimit, _pitchUpLimit] call BIS_fnc_clamp;
    _heli setVariable ["fza_sfmplus_autoPitchTarget", _autoPitchTarget];

    //ROLL target sweep - DECAYS to wings-level on release (kills the standing right roll).
    //SIGN: _cyclicLeftRight is built as (heliCyclicLeftOut - heliCyclicRightOut) - but that name
    //is misleading. In this codebase that expression is the RIGHT-positive stick convention (the
    //same one _rollInput uses downstream in fn_simpleRotorMain), and BIS_fnc_getPitchBank also
    //reports bank RIGHT-positive. The two senses AGREE, so the key is ADDED, not subtracted.
    //Subtracting it inverted the commanded bank in the ATT regime while pitch stayed correct.
    if (_rollKey != 0.0) then {
        _autoRollTarget = _autoRollTarget + (_rollKey * AUTO_ATT_ROLL_RATE * _deltaTime);
    } else {
        //A RATE decay (not a snap, not an exponential) keeps the roll-out predictable and
        //identical from any bank.
        private _levelStep = AUTO_ATT_ROLL_LEVEL_RATE * _deltaTime;
        if ((abs _autoRollTarget) <= _levelStep) then {
            _autoRollTarget = 0.0;
        } else {
            _autoRollTarget = _autoRollTarget - (_levelStep * ([1, -1] select (_autoRollTarget < 0.0)));
        };
    };
    //Clamp EVERY frame (as with pitch). The roll limit MOVES with airspeed, so a bank that was
    //legal at 140kt is outside the envelope once the aircraft slows - holding the key must not
    //keep it there. The decay path is clamped too so releasing the expand key while banked hard
    //walks the target back inside rather than stranding it.
    _autoRollTarget = [_autoRollTarget, -_rollLimit, _rollLimit] call BIS_fnc_clamp;
    _heli setVariable ["fza_sfmplus_autoRollTarget", _autoRollTarget];

    //SIGN - follows the established convention in fn_fmcAttitudeHold's "att" branch: it forms
    //error = current - setpoint, runs the PID toward zero, then NEGATES. pidRun computes
    //(setpoint - measurement), so passing (target, current) yields (target - current) and the
    //negation makes the net command (current - target) - matching att hold exactly. Without it
    //the command drives attitude AWAY from the target: positive feedback that rolls the aircraft.
    //
    //A HOVER HAS NO CORRECT ATTITUDE. The aircraft sits at whatever pitch and bank BALANCES the
    //forces on it (tail thrust, CG offset, wind) - that attitude is an OUTPUT of holding position,
    //never a target to fly to. A real pilot at a hover moves the cyclic until the aircraft stops
    //moving over the ground; they do not fly to a pitch number. So while the hover regime owns the
    //axis, the attitude TARGET is slaved to actual attitude and the attitude PIDs are held reset.
    //
    //This fixes an orphaned-target bug: the attitude PIDs used to run at HoverW = 1.0 where their
    //output is multiplied by zero, integrating an error they were never allowed to correct. In a
    //stable hover that showed as APTarget -6.5 against ~0 actual pitch, never closing, with the
    //wound-up integral leaking into force-trim (forceTrimPosPitch parked at 0.22) - the position
    //loop was holding the hover correctly while a second loop fought it with stale windup.
    //
    //Slaving (rather than just zeroing) also makes the handover seamless: accelerating out of the
    //hover, the attitude regime picks up from the attitude the aircraft ALREADY has, so there is
    //no step and no stale target to chase.
    private _attPitchOut = 0.0;
    private _attRollOut  = 0.0;
    if (_autoAttWAtt > 0.0) then {
        _attPitchOut = [_pidAutoPitch, _deltaTime, _autoPitchTarget, _curPitch] call fza_fnc_pidRun;
        _attPitchOut = -([_attPitchOut, -1.0, 1.0] call BIS_fnc_clamp);
        _attRollOut  = [_pidAutoRoll,  _deltaTime, _autoRollTarget,  _curRoll]  call fza_fnc_pidRun;
        _attRollOut  = -([_attRollOut,  -1.0, 1.0] call BIS_fnc_clamp);
    } else {
        //Not in cruise: the attitude target is meaningless, so SLAVE it to actual and hold the
        //PIDs reset. Below cruise the aircraft sits at whatever attitude balances the forces -
        //that attitude is an OUTPUT of holding position/velocity, never a target to fly to.
        //Slaving also makes the handover seamless: accelerating into cruise, the attitude regime
        //picks up from the attitude the aircraft ALREADY has, so there is no step.
        _autoPitchTarget = _curPitch;
        _autoRollTarget  = _curRoll;
        _heli setVariable ["fza_sfmplus_autoPitchTarget", _autoPitchTarget];
        _heli setVariable ["fza_sfmplus_autoRollTarget",  _autoRollTarget];
        [_pidAutoPitch] call fza_fnc_pidReset;
        [_pidAutoRoll]  call fza_fnc_pidReset;
    };

    /////////////////////////////////////////////////////////////////////////////////////////
    // VEL REGIME (transition) - ROLL nulls LATERAL ground velocity, PITCH holds FORWARD
    // velocity. Roll is the critical half: in this regime the PEDALS are holding nose-to-tail
    // trim (velocity vector on the nose), so any lateral drift makes the pedals chase a
    // sideways velocity vector - the feet and the hands end up fighting each other. The hands
    // kill the drift with bank so the feet have something sane to trim to.
    //
    // SIGN: copied WHOLE from fn_fmcAttitudeHold's "vel" branch - roll measures -velX, pitch
    // measures +velY, output used AS-IS with NO negation. Do not add the "att" branch's
    // negation here; those two branches use different conventions and mixing them inverts
    // both axes (it commanded right cyclic instead of left picking up to a hover).
    /////////////////////////////////////////////////////////////////////////////////////////
    private _velPitchOut = 0.0;
    private _velRollOut  = 0.0;
    if (_autoAttWVel > 0.0) then {
        private _pidVelX = _heli getVariable "fza_sfmplus_pid_autoVelX";
        private _pidVelY = _heli getVariable "fza_sfmplus_pid_autoVelY";

        //Keys command a ground velocity. Lateral setpoint is ZERO unless the pilot is actively
        //asking for drift - the whole point of this regime is that sideward velocity is the
        //enemy. Forward setpoint is swept by the pitch key and PERSISTS, so the machine pilot
        //accelerates to a commanded speed and holds it.
        private _velCmdFwd = _heli getVariable ["fza_sfmplus_autoVelCmdFwd", 0.0];
        if (_pitchKey != 0.0) then {
            //Forward cyclic (+) = accelerate forward.
            _velCmdFwd = _velCmdFwd + (_pitchKey * AUTO_ATT_VEL_ACCEL_RATE * _deltaTime);
            _velCmdFwd = [_velCmdFwd, -AUTO_ATT_VEL_CMD_LIMIT, AUTO_ATT_VEL_CMD_LIMIT] call BIS_fnc_clamp;
        };
        _heli setVariable ["fza_sfmplus_autoVelCmdFwd", _velCmdFwd];
        //Lateral setpoint. SIGN: the reference (fn_fmcAttitudeHold "vel") passes its setpoint
        //PLAIN against a -velX measurement, because the stored setpoint is ALREADY negated when
        //captured (fn_fmcAttitudeHoldEnable line 18: velX * -1.0). So the setpoint must live in
        //that same negated frame - build it negated here and pass it plain, exactly as the
        //reference does. Negating it again at the call site (which is what was wrong) inverted
        //the roll axis while leaving pitch correct, since pitch is negated nowhere in this chain.
        //key +LEFT -> drift left -> velX negative -> negated frame: positive.
        private _velCmdLat = _rollKey * AUTO_ATT_HOVER_VEL_RATE;
        _velCmdLat = [_velCmdLat, -AUTO_ATT_HOVER_VEL_LIMIT, AUTO_ATT_HOVER_VEL_LIMIT] call BIS_fnc_clamp;

        //ACCELERATION LEAD - same anticipation as the POS regime (see the note there). Nulling
        //lateral drift is exactly the case that benefits: the hands should bank as the aircraft
        //STARTS to slide, not once it is already sliding and the pedals are chasing it.
        private _vLeadX = [(_heli getVariable ["fza_sfmplus_accelX", 0.0]) * AUTO_ATT_ACCEL_LEAD,
                           -AUTO_ATT_ACCEL_LEAD_CLAMP, AUTO_ATT_ACCEL_LEAD_CLAMP] call BIS_fnc_clamp;
        private _vLeadY = [(_heli getVariable ["fza_sfmplus_accelY", 0.0]) * AUTO_ATT_ACCEL_LEAD,
                           -AUTO_ATT_ACCEL_LEAD_CLAMP, AUTO_ATT_ACCEL_LEAD_CLAMP] call BIS_fnc_clamp;

        _velRollOut  = [_pidVelX, _deltaTime, ( _velCmdLat), (-(_autoAttVelX + _vLeadX))] call fza_fnc_pidRun;
        _velRollOut  = [_velRollOut,  -1.0, 1.0] call BIS_fnc_clamp;
        _velPitchOut = [_pidVelY, _deltaTime, ( _velCmdFwd), ( _autoAttVelY + _vLeadY)] call fza_fnc_pidRun;
        _velPitchOut = [_velPitchOut, -1.0, 1.0] call BIS_fnc_clamp;
    } else {
        [_heli getVariable "fza_sfmplus_pid_autoVelX"] call fza_fnc_pidReset;
        [_heli getVariable "fza_sfmplus_pid_autoVelY"] call fza_fnc_pidReset;
        //Seed the commanded forward velocity to actual, so entering VEL from either side starts
        //from what the aircraft is already doing instead of snapping to a stale command.
        _heli setVariable ["fza_sfmplus_autoVelCmdFwd", _autoAttVelY];
    };

    /////////////////////////////////////////////////////////////////////////////////////////
    // POS REGIME (hover) - hold POSITION over the ground. Structure follows the FMC position
    // hold (fn_fmcAttitudeHold "pos"): a velocity-null PID per axis, plus a slow, tightly-
    // clamped position-error integral that biases the velocity SETPOINT rather than the output.
    // The bias works THROUGH the velocity loop, so velocity does all the actuation and the
    // integral only re-aims it - it cannot fight the loop.
    //
    // The PID's OWN ki is what finds the standing cyclic offset that balances the forces on the
    // aircraft (tail thrust, CG, wind) - that is the thing a real pilot's hand does at a hover,
    // and kp alone cannot do it (zero velocity error commands zero cyclic and it drifts again).
    /////////////////////////////////////////////////////////////////////////////////////////
    private _hovPitchOut = 0.0;
    private _hovRollOut  = 0.0;
    if (_autoAttWPos > 0.0) then {
        private _pidHovX = _heli getVariable "fza_sfmplus_pid_autoHoverX";
        private _pidHovY = _heli getVariable "fza_sfmplus_pid_autoHoverY";

        //Commanded reposition velocity. A hovering pilot does not command an attitude, they
        //command a DRIFT - "slide left a bit". Key -> ground velocity setpoint, in m/s.
        //SIGN: the lateral setpoint lives in the NEGATED-X frame, because that is the frame the
        //roll channel works in throughout (measurement is -velX, and the reference stores its
        //captured setpoint pre-negated). Build it negated here, pass it PLAIN below - negating
        //again at the call site is what inverted the roll axis. Pitch is negated nowhere.
        private _setVelX = _rollKey  * AUTO_ATT_HOVER_VEL_RATE;   //key +LEFT, negated frame -> +
        private _setVelY = _pitchKey * AUTO_ATT_HOVER_VEL_RATE;   //key +FWD  -> velocity +Y (fwd)
        _setVelX = [_setVelX, -AUTO_ATT_HOVER_VEL_LIMIT, AUTO_ATT_HOVER_VEL_LIMIT] call BIS_fnc_clamp;
        _setVelY = [_setVelY, -AUTO_ATT_HOVER_VEL_LIMIT, AUTO_ATT_HOVER_VEL_LIMIT] call BIS_fnc_clamp;

        private _iX = _heli getVariable ["fza_sfmplus_autoHoverIntX", 0.0];
        private _iY = _heli getVariable ["fza_sfmplus_autoHoverIntY", 0.0];

        //Position integral runs ONLY when the pilot is off the cyclic. While they are flying it
        //the datum is meaningless (they are deliberately leaving it), so the integral is frozen -
        //not reset - and the datum is re-captured on release by the breakout handler above.
        if (!_cyclicBreakout) then {
            private _datum = _heli getVariable ["fza_sfmplus_autoHoverDatum", getPos _heli];
            private _dPos  = _datum vectorDiff (getPos _heli);
            private _hdg   = direction _heli;
            //World -> model space position error: X = right+, Y = forward+.
            private _posErrX = ((_dPos # 0) * cos _hdg) - ((_dPos # 1) * sin _hdg);
            private _posErrY = ((_dPos # 0) * sin _hdg) + ((_dPos # 1) * cos _hdg);
            //Deadband: do not chase sub-metre error. Subtracting (rather than zeroing inside the
            //band) keeps the response continuous - no step at the edge of the band.
            if ((abs _posErrX) <= AUTO_ATT_HOVER_POS_DEADBAND) then {
                _posErrX = 0.0;
            } else {
                _posErrX = _posErrX - (AUTO_ATT_HOVER_POS_DEADBAND * ([1, -1] select (_posErrX < 0.0)));
            };
            if ((abs _posErrY) <= AUTO_ATT_HOVER_POS_DEADBAND) then {
                _posErrY = 0.0;
            } else {
                _posErrY = _posErrY - (AUTO_ATT_HOVER_POS_DEADBAND * ([1, -1] select (_posErrY < 0.0)));
            };

            //PROPORTIONAL position recovery: metres of error -> m/s of commanded return.
            //This replaced an accumulating integral that SATURATED - measured in a real hover it
            //sat pinned at its clamp on both axes (setpoint 0.400, integral 0.300) while the
            //aircraft drifted aft at 3-5 m/s. It was asking to come home at 0.4 m/s against a
            //drift ten times faster, so the error grew without bound and it could never unwind:
            //the loop looked like it "never put in enough cyclic" because it was never ASKING
            //for enough. A proportional term cannot rail like that - the further off datum, the
            //faster the commanded return, up to the cap.
            _iX = [_posErrX * AUTO_ATT_HOVER_POS_PKP, -AUTO_ATT_HOVER_POS_PCLAMP, AUTO_ATT_HOVER_POS_PCLAMP] call BIS_fnc_clamp;
            _iY = [_posErrY * AUTO_ATT_HOVER_POS_PKP, -AUTO_ATT_HOVER_POS_PCLAMP, AUTO_ATT_HOVER_POS_PCLAMP] call BIS_fnc_clamp;
            _heli setVariable ["fza_sfmplus_autoHoverIntX", _iX];
            _heli setVariable ["fza_sfmplus_autoHoverIntY", _iY];

            //Off the cyclic the setpoint is purely the position-recovery bias. NEGATE the lateral
            //one: _iX comes from _posErrX in RAW model space (+X right), and the roll channel
            //works in the negated-X frame (see the setpoint note above). Pitch needs no negation.
            _setVelX = -_iX;
            _setVelY =  _iY;
        };

        //Velocity-null PIDs, copied WHOLE from the FMC position hold (fn_fmcAttitudeHold "pos"):
        //roll measures -velX, pitch measures +velY, output used AS-IS. Setpoints arrive already
        //in the correct frame (see the two notes above), so they are passed PLAIN.
        //
        //DO NOT add the attitude branch's output negation here. The two branches have DIFFERENT
        //conventions: the "att" branch forms error = current - setpoint and negates its output,
        //while the "pos"/"vel" branches feed the PID directly and do NOT negate (compare
        //fn_fmcAttitudeHold lines 104-110 against 137-143). Negating this one inverts BOTH axes -
        //picking up to a hover it commanded right cyclic instead of left, aft instead of forward.
        //ACCELERATION LEAD. The measurement fed to each PID is not raw velocity but a short-horizon
        //PREDICTION of it: vel + accel * horizon. This is what makes the machine pilot anticipate
        //rather than chase - it commands cyclic as the aircraft BEGINS to accelerate, before the
        //drift has built, which is how a human hand-flies a hover. accelX/Y are the smoothed
        //derivative of the very velocity being nulled (fn_getAccelerations), so they are already in
        //this frame and carry no separate sign convention. Clamped so an accel spike cannot rail
        //the command on its own.
        private _leadX = [(_heli getVariable ["fza_sfmplus_accelX", 0.0]) * AUTO_ATT_ACCEL_LEAD,
                          -AUTO_ATT_ACCEL_LEAD_CLAMP, AUTO_ATT_ACCEL_LEAD_CLAMP] call BIS_fnc_clamp;
        private _leadY = [(_heli getVariable ["fza_sfmplus_accelY", 0.0]) * AUTO_ATT_ACCEL_LEAD,
                          -AUTO_ATT_ACCEL_LEAD_CLAMP, AUTO_ATT_ACCEL_LEAD_CLAMP] call BIS_fnc_clamp;
        private _predVelX = _autoAttVelX + _leadX;
        private _predVelY = _autoAttVelY + _leadY;

        _hovRollOut  = [_pidHovX, _deltaTime, ( _setVelX), (-_predVelX)] call fza_fnc_pidRun;
        _hovRollOut  = [_hovRollOut,  -1.0, 1.0] call BIS_fnc_clamp;
        _hovPitchOut = [_pidHovY, _deltaTime, ( _setVelY), ( _predVelY)] call fza_fnc_pidRun;
        _hovPitchOut = [_hovPitchOut, -1.0, 1.0] call BIS_fnc_clamp;

        //LEARN the converged integral while the hover is genuinely settled, so the next entry (and
        //crucially the next PICKUP) can seed straight to it instead of climbing from near zero.
        //Only trusted when the aircraft is actually holding station on BOTH axes - otherwise the
        //integral is mid-transient and remembering it would bake in the error.
        if ((abs _autoAttVelX) < AUTO_ATT_HOVER_SEED_LEARN_VEL
         && (abs _autoAttVelY) < AUTO_ATT_HOVER_SEED_LEARN_VEL) then {
            _heli setVariable ["fza_sfmplus_autoHoverLearnedIntX", _pidHovX get "integral"];
            _heli setVariable ["fza_sfmplus_autoHoverLearnedIntY", _pidHovY get "integral"];
        };

        //DIAGNOSTIC - publish the hover loop's internals so the actual numbers can be read in the
        //debug hint instead of inferred from behaviour. Remove once this loop is settled.
        _heli setVariable ["fza_sfmplus_dbgHovSetX",  _setVelX];
        _heli setVariable ["fza_sfmplus_dbgHovSetY",  _setVelY];
        _heli setVariable ["fza_sfmplus_dbgHovVelX",  _autoAttVelX];
        _heli setVariable ["fza_sfmplus_dbgHovVelY",  _autoAttVelY];
        _heli setVariable ["fza_sfmplus_dbgHovOutR",  _hovRollOut];
        _heli setVariable ["fza_sfmplus_dbgHovOutP",  _hovPitchOut];
        _heli setVariable ["fza_sfmplus_dbgHovIntR",  _pidHovX get "integral"];
        _heli setVariable ["fza_sfmplus_dbgHovIntP",  _pidHovY get "integral"];
    } else {
        //Regime not in play. Keep the datum under the aircraft so the first frame back in hover
        //does not lurch, and clear the POSITION-recovery bias (that is a function of where the
        //datum is, and the datum just moved).
        _heli setVariable ["fza_sfmplus_autoHoverDatum", getPos _heli];
        _heli setVariable ["fza_sfmplus_autoHoverIntX",  0.0];
        _heli setVariable ["fza_sfmplus_autoHoverIntY",  0.0];

        //SEED the velocity PIDs' integrators from the CURRENT CYCLIC TRIM instead of resetting
        //them to zero.
        //
        //Zeroing them caused a violent entry transient: holding a hover REQUIRES a standing cyclic
        //offset (the AH-64 trims nose-up, so it needs standing forward cyclic), and the integral is
        //what carries it. Starting from zero, the loop had to WIND UP to ~0.55 while the aircraft
        //was already drifting - under-correcting the whole way, overshooting past the offset, then
        //ringing until it settled. Measured in flight as two large pitch oscillations on entry that
        //nearly put the aircraft in the ground before it stabilised.
        //
        //The cyclic trim the aircraft is ALREADY holding is a good estimate of that offset, so
        //seeding from it means the integral starts near the answer and only has to fine-tune. The
        //integral is divided by ki because pidRun multiplies it back by ki when forming the output
        //- we are seeding the RAW accumulator such that ki * integral equals the seeded trim.
        //
        //SEED_FRACTION exists because the settled trim is NOT all integral: it is kp*error plus
        //ki*integral, and kp supplies the larger share. Seeding the FULL trim into the integral
        //therefore over-seeds it several-fold, and the loop then adds its kp term on top of an
        //already-complete offset - which railed the integral and drove near-full forward cyclic.
        //Seed only the share the integral is actually expected to carry.
        //
        //PREFERRED SEED: the value the integral CONVERGED TO the last time this aircraft held a
        //steady hover (learned below, while settled). That beats any fraction guessed off the trim,
        //and it is what makes a PICKUP work: lifting to a hover is exactly when the integral is at
        //zero and has to climb, so without this the loop is short of forward cyclic through the
        //whole pickup, drifts aft, then overshoots catching up - the oscillation IS the catch-up.
        //Falls back to the trim fraction only before anything has been learned this session.
        private _pidHovXr = _heli getVariable "fza_sfmplus_pid_autoHoverX";
        private _pidHovYr = _heli getVariable "fza_sfmplus_pid_autoHoverY";
        [_pidHovXr] call fza_fnc_pidReset;
        [_pidHovYr] call fza_fnc_pidReset;

        private _kiX = _pidHovXr get "ki";
        private _kiY = _pidHovYr get "ki";
        //Roll trim is in the negated-X frame (see the setpoint notes above); pitch is not.
        private _seedFrac = AUTO_ATT_HOVER_SEED_FRAC;
        private _seedX = if (_kiX > 0.0) then { -(_heli getVariable ["fza_ah64_forceTrimPosRoll",  0.0]) * _seedFrac / _kiX } else { 0.0 };
        private _seedY = if (_kiY > 0.0) then {  (_heli getVariable ["fza_ah64_forceTrimPosPitch", 0.0]) * _seedFrac / _kiY } else { 0.0 };
        private _learnedX = _heli getVariable ["fza_sfmplus_autoHoverLearnedIntX", -9999];
        private _learnedY = _heli getVariable ["fza_sfmplus_autoHoverLearnedIntY", -9999];
        if (_learnedX != -9999) then { _seedX = _learnedX; };
        if (_learnedY != -9999) then { _seedY = _learnedY; };
        //Never seed outside the anti-windup clamp, or the first frame would start already railed.
        private _clX = _pidHovXr get "ki_clamp";
        private _clY = _pidHovYr get "ki_clamp";
        _pidHovXr set ["integral", [_seedX, -_clX, _clX] call BIS_fnc_clamp];
        _pidHovYr set ["integral", [_seedY, -_clY, _clY] call BIS_fnc_clamp];
    };

    /////////////////////////////////////////////////////////////////////////////////////////
    // BLEND + OUTPUT. Weighted mix of the three regimes (the weights sum to 1), then slewed
    // into force-trim so even a step in PID output reaches the swashplate as a ramp.
    /////////////////////////////////////////////////////////////////////////////////////////
    private _pitchGoal = (_hovPitchOut * _autoAttWPos) + (_velPitchOut * _autoAttWVel) + (_attPitchOut * _autoAttWAtt);
    private _rollGoal  = (_hovRollOut  * _autoAttWPos) + (_velRollOut  * _autoAttWVel) + (_attRollOut  * _autoAttWAtt);

    //PILOT HANDS: lag THEN rate-limit, exactly as the auto-pedal models the feet (see the
    //AUTO_ATT_CYCLIC_* note in core.hpp for why that order and not the reverse). This replaces the
    //old plain lerp-into-trim, which was a single smoothing stage with no rate limit.
    private _pitchPrev = _heli getVariable ["fza_sfmplus_autoAttPrevPitch", 0.0];
    private _rollPrev  = _heli getVariable ["fza_sfmplus_autoAttPrevRoll",  0.0];
    private _lagCoef   = [(_deltaTime / AUTO_ATT_CYCLIC_TAU), 0.0, 1.0] call BIS_fnc_clamp;
    private _maxStep   = AUTO_ATT_CYCLIC_RATE * _deltaTime;

    private _pitchLag  = _pitchPrev + ((_pitchGoal - _pitchPrev) * _lagCoef);
    private _pitchStep = [_pitchLag - _pitchPrev, -_maxStep, _maxStep] call BIS_fnc_clamp;
    private _pitchTrim = [_pitchPrev + _pitchStep, -1.0, 1.0] call BIS_fnc_clamp;

    private _rollLag   = _rollPrev + ((_rollGoal - _rollPrev) * _lagCoef);
    private _rollStep  = [_rollLag - _rollPrev, -_maxStep, _maxStep] call BIS_fnc_clamp;
    private _rollTrim  = [_rollPrev + _rollStep, -1.0, 1.0] call BIS_fnc_clamp;

    _heli setVariable ["fza_sfmplus_autoAttPrevPitch", _pitchTrim];
    _heli setVariable ["fza_sfmplus_autoAttPrevRoll",  _rollTrim];
    _heli setVariable ["fza_ah64_forceTrimPosPitch",   _pitchTrim, true];
    _heli setVariable ["fza_ah64_forceTrimPosRoll",    _rollTrim,  true];

    _heli setVariable ["fza_sfmplus_autoPitchActive", true];
    _heli setVariable ["fza_sfmplus_autoRollActive",  true];
};
/////////////////////////////////////////////////////////////////////////////////////////////
// Flight Ctrl Lockout  /////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////
if (_fltControlLockout) then {
    if (
        (_cyclicFwdAft    < CENTER_TRIM_VAL && _cyclicFwdAft    > -CENTER_TRIM_VAL) &&
        (_cyclicLeftRight < CENTER_TRIM_VAL && _cyclicLeftRight > -CENTER_TRIM_VAL) &&
        (_pedalLeftRight  < CENTER_TRIM_VAL && _pedalLeftRight  > -CENTER_TRIM_VAL)
       ) then {
            _heli setVariable ["fza_sfmplus_flightControlLockOut", false];
       };
       if (fza_sfmplus_cyclicCenterTrimMode) then {
            _cyclicFwdAft    = 0.0;
            _cyclicLeftRight = 0.0;
       };

       if (fza_sfmplus_pedalCenterTrimMode) then {
            _pedalLeftRight  = 0.0;
       };
};
//AUTO-ATTITUDE OWNS THE CYCLIC OUTRIGHT. When it is running, the pilot's cyclic key is a COMMAND
//TO THE MACHINE PILOT ("bank right", "accelerate"), not a control input - it has already been
//consumed above to sweep the attitude target / velocity setpoint. It must NOT also reach the rotor.
//
//Downstream (fn_rotorControl / fn_simpleRotorMain) the rotor sees stick + forceTrim + SAS summed
//together, so leaving the raw stick in meant the player pushed straight THROUGH the envelope
//limits: the target was clamped to 15 deg but their held key added unbounded control on top, so
//pitch and bank ran past every limit. Zeroing the stick here is what makes the limiter real - the
//ONLY path to the rotor becomes the force-trim the machine pilot writes, which is clamped.
if (_autoAtt) then {
    _cyclicFwdAft    = 0.0;
    _cyclicLeftRight = 0.0;
};
_cyclicFwdAft    = [_heli, "pitch", _cyclicFwdAft,    _inputLagValue] call fza_sfmplus_fnc_actuator;
_cyclicLeftRight = [_heli, "roll",  _cyclicLeftRight, _inputLagValue] call fza_sfmplus_fnc_actuator;
_pedalLeftRight  = [_heli, "yaw",   _pedalLeftRight,  _inputLagValue] call fza_sfmplus_fnc_actuator;

//systemChat format ["_cyclicFwdAft = %1 -- _cyclicLeftRight = %2 -- _pedalLeftRight = %3", _cyclicFwdAft, _cyclicLeftRight, _pedalLeftRight];
/////////////////////////////////////////////////////////////////////////////////////////////
// Collective           /////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////
//Keyboard collective
private _keyCollectiveUp = _heli getVariable "fza_sfmplus_kbHeliCollectiveRaiseOut";
private _keyCollectiveDn = _heli getVariable "fza_sfmplus_kbHeliCollectiveLowerOut";
//Joystick collective
private _joyCollectiveUp = _heli getVariable "fza_sfmplus_heliCollectiveRaiseOut";
private _joyCollectiveDn = _heli getVariable "fza_sfmplus_heliCollectiveLowerOut";

if (_priHydPSI < SYS_MIN_HYD_PSI && _utilHydPSI < SYS_MIN_HYD_PSI) then {
    _hydFailure = true;
};

if (_priHydPSI < SYS_MIN_HYD_PSI && _utilLevel_pct < SYS_HYD_MIN_LVL) then {
    _tailRtrFixed = true;
};

if (!_hydFailure || _emerHydOn) then {
    private _collectiveValue = _heli getVariable "fza_sfmplus_collectiveOutput";
    if (fza_sfmplus_keyboardCollective) then {
        if (_keyCollectiveUp > 0.1) then { _collectiveValue = _collectiveValue + ((1.0 / 4.0) * _deltaTime); };
        if (_keyCollectiveDn > 0.1) then { _collectiveValue = _collectiveValue - ((1.0 / 4.0) * _deltaTime); };
        _collectiveValue = (round (_collectiveValue / 0.005)) * 0.005;
        _collectiveValue = [_collectiveValue, 0.0, 1.0] call bis_fnc_clamp;
        //systemChat format ["KB collective! -- %1", (_heli getVariable "fza_sfmplus_collectiveOutput") toFixed 3];
    } else {
        _collectiveValue = _joyCollectiveUp - _joyCollectiveDn;
        _collectiveValue = [_collectiveValue, -1.0, 1.0] call BIS_fnc_clamp;
        _collectiveValue = linearConversion[ -1.0, 1.0, _collectiveValue, 0.0, 1.0];
        //systemChat format ["HOTAS collective! -- %1", (_heli getVariable "fza_sfmplus_collectiveOutput") toFixed 3];
    };
    if (_isPlaying) then {
        //Hydraulic actuator lag on collective (crisp with FMC/hydraulics good, lagged when not) -
        //same treatment as cyclic/pedal above.
        _collectiveValue = [_heli, "collective", _collectiveValue, _inputLagValue] call fza_sfmplus_fnc_actuator;
        _heli setVariable ["fza_sfmplus_collectiveOutput", _collectiveValue];
    };
};
/////////////////////////////////////////////////////////////////////////////////////////////
// Cyclic and Pedals    /////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////
if (_isZeus && (!_hydFailure || _emerHydOn)) then {
    if (fza_ah64_sfmPlusMouseAsJoystick) then {
        _heli setVariable ["fza_sfmplus_cyclicFwdAft",    _cyclicFwdAft    * fza_ah64_sfmPlusMouseSense];
        _heli setVariable ["fza_sfmplus_cyclicLeftRight", _cyclicLeftRight * fza_ah64_sfmPlusMouseSense];
    } else {
        _heli setVariable ["fza_sfmplus_cyclicFwdAft",    _cyclicFwdAft];
        _heli setVariable ["fza_sfmplus_cyclicLeftRight", _cyclicLeftRight];
    };
    if (!_tailRtrFixed) then {
        _heli setVariable ["fza_sfmplus_pedalLeftRight", _pedalLeftRight];
    };
} else {
    _heli setVariable ["fza_sfmplus_cyclicFwdAft",     0.0];
    _heli setVariable ["fza_sfmplus_cyclicLeftRight",  0.0];
    _heli setVariable ["fza_sfmplus_pedalLeftRight",   0.0];
};

if (fza_ah64_lastFrameGetIn) then {
    fza_ah64_lastFrameGetIn = false;
};
