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

    //THREE REGIMES, each with its own error signal, units and PID:
    //  HDG  (hover)        -> hold HEADING (deg); the ball is meaningless without airflow
    //  NTT  (accel, <50ft) -> NOSE-TO-TAIL: drive kinematic sideslip (beta_deg) to zero
    //  AERO (>50ft AGL)    -> AERODYNAMIC: drive lateral accel (beta_g) to zero, ball centred
    //Blended by weight, never switched: hover->NTT over ground speed, NTT->AERO over AGL.
    //
    //ERROR SIGNS ARE VETTED - do not unify them. Heading is (actual - desired); the slip channels
    //are negated, because a heading error and a lateral acceleration need opposite pedal sense.
    //
    //AERO uses the per-vehicle beta_g, NOT the fza_ah64_sideslip global - that one is clamped at
    //0.15g (the controller would go blind past it) and is stale for AI aircraft.
    private _betaG    = _heli getVariable "fza_sfmplus_aero_beta_g";     // g,   + = accel right
    private _betaDeg  = _heli getVariable "fza_sfmplus_aero_beta_deg";   // deg, + = flow from right
    //Use the RAW (3rd) return - the displayed radalt is rounded to 10ft above 50ft, which would
    //turn the blend below into a staircase.
    ([_heli] call fza_sfmplus_fnc_getAltitude) params ["", "", "_radAltRaw"];

    //Slip setpoints are zero, error formed (desired - actual). Heading keeps (actual - desired).
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
    //AERODYNAMIC trim requires BOTH fast AND high - hence min(). LOW **OR** SLOW means
    //nose-to-tail trim: NOE flight can sit above 50ft and still be nose-to-tail, as is a fast run
    //down low. Airspeed alone gates the HEADING channel - a 1kt hover at 200ft is still a hover.
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

    //PILOT FEET MODEL - a rate limit (feet have mass, pedals have breakout) and a first-order lag
    //(a press, not micro-jabs) applied to the BLENDED output, so handovers are smoothed too. The
    //PIDs still see true error; this only shapes delivery.
    //
    //ORDER MATTERS: lag FIRST, then rate-limit. The other way round takes a fraction of an
    //already-limited step, so the output converges short of the commanded pedal - and the
    //shortfall worsens at higher frame rates.
    private _pedalPrev = _heli getVariable "fza_sfmplus_autoPedalPrevOut";
    private _lagCoef   = [(_deltaTime / AUTOPEDAL_PEDAL_TAU), 0.0, 1.0] call BIS_fnc_clamp;
    private _pedalLag  = _pedalPrev + ((_yawOutput - _pedalPrev) * _lagCoef);
    //Rate limit: cap the per-frame CHANGE at what a foot could actually move in this timestep.
    private _maxStep   = AUTOPEDAL_PEDAL_RATE * _deltaTime;
    private _step      = [_pedalLag - _pedalPrev, -_maxStep, _maxStep] call BIS_fnc_clamp;
    _yawOutput         = [_pedalPrev + _step, -1.0, 1.0] call BIS_fnc_clamp;
    _heli setVariable ["fza_sfmplus_autoPedalPrevOut", _yawOutput];

    //Publish the dominant regime, its weight and the PID errors for the auto-tuner and overlay.
    //The weight matters because fn_tunerPedalAuto only grades when one regime clearly owns the
    //pedals - mid-transition all three contribute and the response is unattributable.
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
// Preston Pilot AI     /////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////
//The machine pilot's hands on the cyclic - see functions/prestonAi/fn_prestonPilot.sqf.
//GATED OFF while the FMC holds are tuned. Restore by removing the `false && `.
private _preston = false && {fza_ah64_sfmplusRealismSetting != REALISTIC};
if (_preston) then {
    ([_heli, _deltaTime, _cyclicFwdAft, _cyclicLeftRight, _kbStickyInterupt]
        call fza_sfmplus_fnc_prestonPilot) params ["_cyclicFwdAft", "_cyclicLeftRight"];
} else {
    //Not running: clear the active flags so the readouts do not report it as live (they seed
    //true in fn_coreConfig and are otherwise only ever set, never cleared).
    _heli setVariable ["fza_sfmplus_autoPitchActive", false];
    _heli setVariable ["fza_sfmplus_autoRollActive",  false];
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
