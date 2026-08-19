/* ----------------------------------------------------------------------------
Function: fza_sfmplus_fnc_simpleRotorTail

Description:
    Simple rotor provides a simple, grounded in reality simulation of a
    helicopters rotor. Translational Lift, Ground Effect and Vortex Ring State
    are all simulated.

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

if (!local _heli) exitWith {};

private _deltaTime              = _heli getVariable "fza_sfmplus_deltaTime";//fza_ah64_fixedTimeStep;
private _heliCom                = getCenterOfMass _heli;

private _altitude               = _heli getVariable "fza_sfmplus_PA";
private _temperature            = _heli getVariable "fza_sfmplus_FAT";
private _dryAirDensity          = _heli getVariable "fza_sfmplus_rho";

private _hdgHoldPedalYawOut     = _heli getVariable "fza_sfmplus_fmcHdgHoldPedalYawOut";
private _sasYawOut              = _heli getVariable "fza_sfmplus_fmcSasYawOut";
private _fmcYawOut              = _hdgHoldPedalYawOut + _sasYawOut;
//_fmcYawOut                      = [_fmcYawOut, -0.15, 0.15] call BIS_fnc_clamp;

private _rtrPos                 = [-0.87, -6.98, -0.075];

private _rtrDesignRPM           = 1403.0;
private _rtrRPMTrimVal          = 1.01;
private _rtrGearRatio           = 14.90;
private _rtrNumBlades           = 4;

private _bladeRadius            = 1.402;   //m
private _bladeChord             = 0.253;   //m
//Pedal -> tail-thrust scalar. NORMALISED, PREDICTABLE symmetric ramp: left pedal (-) =
//full +1.0, right pedal (+) = full -1.0, crossing ZERO at center pedal. Deliberately
//"dumb" and dummy-proof: pedal maps straight to a -1..+1 authority fraction (flatter near
//the stops, ~linear through center). ALL magnitude/shaping lives in scalars downstream -
//the AIRSPEED authority (_rtrThrustScalarTable, now a flat constant that sets the OGE
//thrust point) and the FIN-OFFLOAD table (below, carries the forward-flight trim reversal).
//ASYMMETRIC: left pedal (-) has ~2x the authority of right (+). Physical for a CCW main
//rotor - the tail already makes strong RIGHT anti-torque thrust in trim, so LEFT pedal
//(which reduces/reverses it to yaw the nose left, against both the main-rotor nose-right
//tendency and the standing anti-torque) needs more range. Full left = +4.0, full right =
//-2.0. STEEPENED (was +2/-1) to raise max yaw rate toward ~30 deg/s (was ~15) - the ramp
//is PINNED near the surveyed hover pedal (-0.352 -> ~0.68, ~unchanged) so hover anti-torque
//trim holds, then steepens toward the stops so the trim->full-deflection SWING roughly
//doubles. Smooth + monotonic, continuous through zero. Reverse the asymmetry for a CW rotor.
private _bladePitchInducedThrustTable = [
    [-1.00,  4.0000]
   ,[-0.90,  3.4102]
   ,[-0.80,  2.8365]
   ,[-0.70,  2.2817]
   ,[-0.60,  1.7507]
   ,[-0.50,  1.2517]
   ,[-0.40,  0.8046]
   ,[-0.30,  0.5420]
   ,[-0.20,  0.3614]
   ,[-0.10,  0.1807]
   ,[ 0.00,  0.0000]
   ,[ 0.10, -0.2924]
   ,[ 0.20, -0.5689]
   ,[ 0.30, -0.8287]
   ,[ 0.40, -1.0705]
   ,[ 0.50, -1.2929]
   ,[ 0.60, -1.4940]
   ,[ 0.70, -1.6714]
   ,[ 0.80, -1.8211]
   ,[ 0.90, -1.9368]
   ,[ 1.00, -2.0000]
  ];
//Tail rotor authority (thrust) scalar vs airspeed. Now a FLAT CONSTANT across all bands:
//with the pedal ramp normalised to +-1.0 and the fin-offload table carrying the airspeed
//reversal, this only needs to set the overall tail-thrust MAGNITUDE (the OGE hover thrust
//point). Kept as a TABLE (not a single scalar) as a precaution so per-band control can be
//re-enabled if ever needed, but every band seeds to the same value. 0.0946 preserves the
//previously-tuned OGE hover thrust with the new +-1.0 ramp. Source array is the single
//source of truth: published into the live tuner var when unset (tuner reads/writes this).
private _rtrThrustScalarTable = _heli getVariable ["fza_sfmplus_tune_tailThrustTable", []];
if (_rtrThrustScalarTable isEqualTo []) then {
    _rtrThrustScalarTable =
    [
     [ 0.00, 0.136906]   // flat constant across all bands (OGE thrust point; fin-offload does the rest)
    ,[10.29, 0.136906]
    ,[20.58, 0.136906]
    ,[36.01, 0.136906]
    ,[46.30, 0.136906]
    ,[51.44, 0.136906]
    ,[61.73, 0.136906]
    ,[66.88, 0.136906]
    ,[72.02, 0.136906]
    ];
    _heli setVariable ["fza_sfmplus_tune_tailThrustTable", _rtrThrustScalarTable];
};
//Airspeed TRIM term for tail thrust (thrust-scalar units, ADDED to the pedal-driven
//thrust scalar below). WHY THIS EXISTS: the pedal->thrust map is a pure function of pedal
//position, but the real trimmed pedal schedule FOLDS BACK toward center at high speed
//(e.g. ~+0.25 at 90 kt, back to ~+0.015 at 140 kt) while the required tail thrust marches
//MONOTONICALLY negative (rotor reaction torque bottoms ~70 kt then the vertical fin's
//side-force keeps offloading the tail, past zero into reverse). No pedal-indexed table can
//represent that (it would need two thrust values at the same pedal). This AIRSPEED-indexed
//term carries exactly that: the residual between the required tail thrust and what the
//pedal ramp alone produces, so net tail thrust matches the yaw balance across the envelope
//and reverses monotonically. ZERO at hover (IGE/OGE tuning untouched). Seeded from the
//computed residual (reaction - fin - pedalRamp), in baseThrust-scalar units; the yaw tuner
//fine-tunes it live via fza_sfmplus_tune_tailTrimTable.
private _tailTrimTable = _heli getVariable ["fza_sfmplus_tune_tailTrimTable", []];
if (_tailTrimTable isEqualTo []) then {
    //Seeded to ZERO across all bands: the yaw auto-tuner MEASURES the real net yaw moment
    //in-game (real CoM, sideslip, air density) and fills these per-band values so the tail
    //balances - far more reliable than a hand-computed seed. Expect it to converge to a
    //hump: positive at low/mid speed, crossing negative ~130-140 kt (the monotonic reversal
    //the pedal fold-back can't produce). Edit here + reload only to hand-set a starting point.
    _tailTrimTable =
    [
     [ 0.00, 0.0000]   //   0 kt
    ,[10.29, 0.0000]   //  20 kt
    ,[20.58, 0.0000]   //  40 kt
    ,[36.01, 0.0000]   //  70 kt
    ,[46.30, 0.0000]   //  90 kt
    ,[51.44, 0.0000]   // 100 kt
    ,[61.73, 0.0000]   // 120 kt
    ,[66.88, 0.0000]   // 130 kt
    ,[72.02, 0.0000]   // 140 kt
    ];
    _heli setVariable ["fza_sfmplus_tune_tailTrimTable", _tailTrimTable];
};
private _rtrAirspeedVelocityMod = 0.4;
private _baseThrust             = 10230;  //N - max gross weight (kg) * gravity (9.806 m/s) * 10%

//Thrust produced
private _pedalLeftRight     = _heli getVariable "fza_sfmplus_pedalLeftRight";
private _pedalLeftRightTrim = 0.0;
_pedalLeftRightTrim         = _heli getVariable "fza_ah64_forceTrimPosYaw";

private _pedalInput         = ([_pedalLeftRight, _pedalLeftRightTrim] call fza_sfmplus_fnc_getInterpInput) + _fmcYawOut;
_pedalInput                 = [_pedalInput, -1.0, 1.0] call BIS_fnc_clamp;
//Publish the total tail-rotor yaw input (manual pedal + trim + FMC) so the
//yaw-balance tuner can read the full standing yaw command, not just the FMC part.
_heli setVariable ["fza_sfmplus_tailPedalInput", _pedalInput];
private _bladePitchInducedThrustScalar = [_bladePitchInducedThrustTable, _pedalInput] call fza_fnc_linearInterp select 1;//linearConversion [_bladePitch_min, _bladePitch_max, _bladePitch_cur, _rtrThrustScalar_min, _rtrThrustScalar_max, true];
//systemChat format ["_bladePitchInducedThrustScalar = %1 -- _pedalInput = %2", _bladePitchInducedThrustScalar toFixed 3, _pedalInput];
(_heli getVariable "fza_sfmplus_engPctNP")
    params ["_eng1PctNP", "_eng2PctNp"];
private _inputRPM                  = _eng1PctNP max _eng2PctNp;
//Rotor induced thrust as a function of RPM
private _rtrRPMInducedThrustScalar = _inputRPM / _rtrRPMTrimVal;

//Thrust scalar as a result of altitude
private _airDensityThrustScalar    = _dryAirDensity / ISA_STD_DAY_AIR_DENSITY;
//Additional thrust gained from increasing forward airspeed
private _deltaPos                  = _rtrPos vectorDiff _heliCom;

//HUB-LOCAL VELOCITY. velModelSpace is the velocity of the CG, but the tail hub sits ~7 m AFT of
//it - so whenever the aircraft rotates, the hub is moving through the air at a different velocity
//than the CG is. The rigid-body relation is:
//
//      v_hub = v_cg + (omega x r)        r = hub position relative to the CG (_deltaPos)
//
//Without the (omega x r) term the tail rotor is fed the CG's velocity, which is WRONG in exactly
//the way that matters here: _velX drives _inducedVelocityScalar below, and that scalar MULTIPLIES
//the entire thrust output. So a yaw rate produced a thrust error PROPORTIONAL TO THAT YAW RATE -
//a feedback path, and one with the sign structure that sustains an oscillation instead of damping
//it. That is a physics error in the model, not something any controller gain could fix, which is
//why tuning the heading-hold PID never settled it.
//
//At a 7 m arm the lateral term is r_yaw * 6.98: small in trimmed flight (~0.19 m/s at 1.5 deg/s)
//but growing directly with yaw rate, so it feeds itself once a divergence starts.
//
//CROSS-PRODUCT ORDER: written (r x omega), NOT the textbook (omega x r). Verified against the
//physical case rather than the formula: with the nose yawing RIGHT about a CG ~7 m forward of the
//tail, the TAIL swings LEFT, so the hub's lateral velocity must be NEGATIVE. (omega x r) gives
//+0.29 m/s there and (r x omega) gives -0.29, so this model's angVelModelSpace uses the opposite
//handedness to the standard convention. Match the aircraft, not the textbook.
private _angVel                    = _heli getVariable ["fza_sfmplus_angVelModelSpace", [0,0,0]];
private _velRot                    = _deltaPos vectorCrossProduct _angVel;
private _velHub                    = (_heli getVariable "fza_sfmplus_velModelSpace") vectorAdd _velRot;

private _velY                      = _velHub select 1;
private _velZ                      = _velHub select 2;
private _velWindY                  = _heli getVariable "fza_sfmplus_velWindModelSpace" select 1;
private _velWindX                  = _heli getVariable "fza_sfmplus_velWindModelSpace" select 0;
if (_velWindY < 0.0) then {
    _velWindY = 0.0;
};
private _velYZ                     = vectorMagnitude [_velY + _velWindY, _velZ] min VEL_VNE;
private _airspeedVelocityScalar    = (1 + (_velYZ / VEL_VBE)) ^ (_rtrAirspeedVelocityMod);
//Induced flow handler - lateral flow through the disk, at the HUB.
private _velX                      = _velHub select 0;
_velX = _velX;// * sin (_heli getVariable "fza_sfmplus_aero_beta_deg");
_velX = _velX + _velWindX;

private _inducedVelocityScalar     = 1.0;
if (_velX < -VEL_VRS && _velYZ < VEL_ETL) then {
    _inducedVelocityScalar = 0.0;
} else {
    _inducedVelocityScalar = 1 - (_velX / VEL_VRS);
};
//Finally, multiply all the scalars above to arrive at the final thrust scalar
private _rtrThrustScalar   = _bladePitchInducedThrustScalar * _rtrRPMInducedThrustScalar * _airDensityThrustScalar * _airspeedVelocityScalar * _inducedVelocityScalar;
private _rtrThrust         = _baseThrust * _rtrThrustScalar;

private _axisX = [1.0, 0.0, 0.0];
private _axisY = [0.0, 1.0, 0.0];
private _axisZ = [0.0, 0.0, 1.0];

//Tail rotor authority: airspeed-indexed thrust multiplier (yaw balance knob).
//Fold it into _totThrust so the thrust vector, moment AND the force-log readout
//all use the scaled value.
private _tailAuthority   = [_rtrThrustScalarTable, _velYZ] call fza_fnc_linearInterp select 1;
//Airspeed trim term (baseThrust-scalar units), ADDED after authority so it is INDEPENDENT
//of the authority knob - it carries the monotonic reversal the pedal ramp cannot (see the
//_tailTrimTable note above). At hover it is 0, so IGE/OGE is unaffected.
private _tailTrim        = [_tailTrimTable, _velYZ] call fza_fnc_linearInterp select 1;
private _totThrust       = (_rtrThrust * _tailAuthority) + (_baseThrust * _tailTrim);
//systemChat format ["_totThrust %1", _totThrust toFixed 0];

private _thrustVector  = _axisX vectorMultiply (_totThrust * _deltaTime);
private _moment        = _thrustVector vectorCrossProduct _deltaPos;

private _tailRtrDamage = _heli getHitPointDamage "hitvrotor";
private _IGBDamage     = _heli getHitPointDamage "hit_drives_intermediategearbox";
private _TGBDamage     = _heli getHitPointDamage "hit_drives_tailrotorgearbox";

private _outThrust = [0.0, 0.0, 0.0];
private _outTq     = [0.0, 0.0, 0.0];

if ([vectorMagnitude _thrustVector] call fza_sfmplus_fnc_isNAN || [vectorMagnitude _thrustVector] call fza_sfmplus_fnc_isINF) then { _thrustVector = [0.0, 0.0, 0.0]; };

if (_tailRtrDamage < 0.85 && _IGBDamage < SYS_IGB_DMG_THRESH && _TGBDamage < SYS_TGB_DMG_THRESH) then {
    if (currentPilot _heli == player) then {
        //if ( fza_ah64_sfmplusRealismSetting == REALISTIC) then {
            //Tail rotor thrust
            _heli addForce [_heli vectorModelToWorld _thrustVector, _rtrPos];
            //Tail rotor torque
            //_moment set [1, (_moment select 1) * TEST];
            _heli addTorque (_heli vectorModelToWorld _moment);
        /*
        } else {
            //Tail rotor thrust
            _heli addForce [_heli vectorModelToWorld _thrustVector, _heliCom];
            //Tail rotor torque
            _heli addTorque (_heli vectorModelToWorld _moment);
        };
        */
        //Net-force accumulator (ALWAYS on): total applied tail force this frame, model
        //space, post-deltaTime (getAccelerations undoes dt). Feeds body accel.
        [_heli, "Tail Rotor", _thrustVector] call fza_sfmplus_fnc_accumForce;

        //Tuner force readout
        if (fza_sfmplus_forceLogOn) then {
            [_heli, "Tail Rotor", _thrustVector, _moment] call fza_sfmplus_fnc_forceLog;
        };
    };
};

#ifdef __A3_DEBUG__
[_heli, _rtrPos, _rtrPos vectorAdd _axisX, "red"]   call fza_fnc_debugDrawLine;
[_heli, _rtrPos, _rtrPos vectorAdd _axisY, "green"] call fza_fnc_debugDrawLine;
[_heli, _rtrPos, _rtrPos vectorAdd _axisZ, "blue"]  call fza_fnc_debugDrawLine;
[_heli, 24, _rtrPos, _bladeRadius, 0, "white", 0]   call fza_fnc_debugDrawCircle;
#endif

[_outThrust, _outTq];

/*
hintsilent format ["v0.7 testing
                    \nRotor Omega = %1
                    \nBlade Tip Vel = %2
                    \nRotor Power Req = %3 kW
                    \nRotor Torque = %4 Nm
                    \nE1 Tq = %5 % E2 Tq = %6 %
                    \nVelZ = %7
                    \nInduced Vel Scalar = %8
                    \nGnd Eff Scalar = %9
                    \nStab = %10
                    \nPitch = %11", _rtrOmega, _bladeTipVel, _rtrPowerReq * 0.001, _reqEngTorque, (_reqEngTorque / 2) / 481, (_reqEngTorque / 2) / 481, _velZ, _inducedVelocityScalar, _gndEffScalar, (_heli getVariable "fza_sfmplus_collectiveOutput"), _heli call BIS_fnc_getPitchBank select 0];
                    */
