/* ----------------------------------------------------------------------------
Function: bmkhs_fnc_simpleRotorTail

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
#include "\bmkhs_helisim\headers\core.hpp"
#include "\bmkhs_helisim\headers\systems.hpp"

if (!local _heli) exitWith {};

private _deltaTime              = _heli getVariable "bmkhs_deltaTime";
private _heliCom                = getCenterOfMass _heli;

private _altitude               = _heli getVariable "bmkhs_PA";
private _temperature            = _heli getVariable "bmkhs_FAT";
private _dryAirDensity          = _heli getVariable "bmkhs_rho";

private _hdgHoldPedalYawOut     = _heli getVariable "bmkhs_fmcHdgHoldPedalYawOut";
private _sasYawOut              = _heli getVariable "bmkhs_fmcSasYawOut";
private _fmcYawOut              = _hdgHoldPedalYawOut + _sasYawOut;
//_fmcYawOut                      = [_fmcYawOut, -0.15, 0.15] call BIS_fnc_clamp;

private _rtrPos                 = _heli getVariable "bmkhs_tailRtrPos";

private _rtrDesignRPM           = _heli getVariable "bmkhs_tailRtrDesignRpm";
private _rtrRPMTrimVal          = _heli getVariable "bmkhs_tailRtrRpmTrimVal";
private _rtrGearRatio           = _heli getVariable "bmkhs_tailRtrGearRatio";
private _rtrNumBlades           = _heli getVariable "bmkhs_tailRtrNumBlades";

private _bladeRadius            = _heli getVariable "bmkhs_tailRtrBladeRadius";
private _bladeChord             = _heli getVariable "bmkhs_tailRtrBladeChord";

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

private _rtrThrustScalarTable =
[
 [ 0.00, 1.00]   // flat constant across all bands (OGE thrust point; fin-offload does the rest)
,[10.29, 1.00]
,[20.58, 1.00]
,[36.01, 1.00]
,[46.30, 1.00]
,[51.44, 1.00]
,[61.73, 1.00]
,[66.88, 1.00]
,[72.02, 1.00]
];

private _tailTrimTable =
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
private _rtrAirspeedVelocityMod = 0.4;
private _baseThrust             = _heli getVariable "bmkhs_tailRtrBaseThrust";

//Thrust produced
private _pedalLeftRight     = _heli getVariable "bmkhs_pedalLeftRight";
private _pedalLeftRightTrim = 0.0;
_pedalLeftRightTrim         = _heli getVariable "bmkhs_forceTrimPosYaw";

private _pedalInput         = ([_pedalLeftRight, _pedalLeftRightTrim] call bmkhs_fnc_getInterpInput) + _fmcYawOut;
_pedalInput                 = [_pedalInput, -1.0, 1.0] call BIS_fnc_clamp;
//Publish the total tail-rotor yaw input (manual pedal + trim + FMC) so the
private _bladePitchInducedThrustScalar = [_bladePitchInducedThrustTable, _pedalInput] call bmkhs_fnc_linearInterp select 1;//linearConversion [_bladePitch_min, _bladePitch_max, _bladePitch_cur, _rtrThrustScalar_min, _rtrThrustScalar_max, true];
//systemChat format ["_bladePitchInducedThrustScalar = %1 -- _pedalInput = %2", _bladePitchInducedThrustScalar toFixed 3, _pedalInput];
(_heli getVariable "bmkhs_engPctNP")
    params ["_eng1PctNP", "_eng2PctNp"];
private _inputRPM                  = _eng1PctNP max _eng2PctNp;
//Rotor induced thrust as a function of RPM
private _rtrRPMInducedThrustScalar = _inputRPM / _rtrRPMTrimVal;

//Thrust scalar as a result of altitude
private _airDensityThrustScalar    = _dryAirDensity / ISA_STD_DAY_AIR_DENSITY;
//Additional thrust gained from increasing forward airspeed
private _deltaPos                  = _rtrPos vectorDiff _heliCom;
private _angVel                    = _heli getVariable ["bmkhs_angVelModelSpace", [0,0,0]];
private _velRot                    = _deltaPos vectorCrossProduct _angVel;
private _velHub                    = (_heli getVariable "bmkhs_velModelSpace") vectorAdd _velRot;

private _velY                      = _velHub select 1;
private _velZ                      = _velHub select 2;
private _velWindY                  = _heli getVariable "bmkhs_velWindModelSpace" select 1;
private _velWindX                  = _heli getVariable "bmkhs_velWindModelSpace" select 0;
if (_velWindY < 0.0) then {
    _velWindY = 0.0;
};
private _velYZ                     = vectorMagnitude [_velY + _velWindY, _velZ] min VEL_VNE;
private _airspeedVelocityScalar    = (1 + (_velYZ / VEL_VBE)) ^ (_rtrAirspeedVelocityMod);
//Induced flow handler - lateral flow through the disk, at the HUB.
private _velX                      = _velHub select 0;
_velX = _velX;// * sin (_heli getVariable "bmkhs_aero_beta_deg");
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
private _tailAuthority   = [_rtrThrustScalarTable, _velYZ] call bmkhs_fnc_linearInterp select 1;
//Airspeed trim term (baseThrust-scalar units), ADDED after authority so it is INDEPENDENT
//of the authority knob - it carries the monotonic reversal the pedal ramp cannot (see the
//_tailTrimTable note above). At hover it is 0, so IGE/OGE is unaffected.
private _tailTrim        = [_tailTrimTable, _velYZ] call bmkhs_fnc_linearInterp select 1;
private _totThrust       = (_rtrThrust * _tailAuthority) + (_baseThrust * _tailTrim);
//systemChat format ["_totThrust %1", _totThrust toFixed 0];

private _thrustVector  = _axisX vectorMultiply (_totThrust * _deltaTime);
private _moment        = _thrustVector vectorCrossProduct _deltaPos;

private _tailRtrDamage = _heli getHitPointDamage "hitvrotor";
private _IGBDamage     = _heli getHitPointDamage "hit_drives_intermediategearbox";
private _TGBDamage     = _heli getHitPointDamage "hit_drives_tailrotorgearbox";

private _outThrust = [0.0, 0.0, 0.0];
private _outTq     = [0.0, 0.0, 0.0];

if ([vectorMagnitude _thrustVector] call bmkhs_fnc_isNAN || [vectorMagnitude _thrustVector] call bmkhs_fnc_isINF) then { _thrustVector = [0.0, 0.0, 0.0]; };

if (_tailRtrDamage < 0.85 && _IGBDamage < SYS_IGB_DMG_THRESH && _TGBDamage < SYS_TGB_DMG_THRESH) then {
    if (currentPilot _heli == player) then {
        if ( bmkhs_helisimRealismSetting == REALISTIC) then {
            //Tail rotor thrust
            _heli addForce [_heli vectorModelToWorld _thrustVector, _rtrPos];
            //Tail rotor torque
            _moment set [1, (_moment select 1) * 0.5];
            _heli addTorque (_heli vectorModelToWorld _moment);

        } else {
            //Tail rotor thrust
            _heli addForce [_heli vectorModelToWorld _thrustVector, _heliCom];
            //Tail rotor torque
            _moment set [1, 0];
            _heli addTorque (_heli vectorModelToWorld _moment);
        };
    };
};

if (BMKHS_FM_DEBUG) then {
[_heli, _rtrPos, _rtrPos vectorAdd _axisX, "red"]   call bmkhs_fnc_debugDrawLine;
[_heli, _rtrPos, _rtrPos vectorAdd _axisY, "green"] call bmkhs_fnc_debugDrawLine;
[_heli, _rtrPos, _rtrPos vectorAdd _axisZ, "blue"]  call bmkhs_fnc_debugDrawLine;
[_heli, 24, _rtrPos, _bladeRadius, 0, "white", 0]   call bmkhs_fnc_debugDrawCircle;
};

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
                    \nPitch = %11", _rtrOmega, _bladeTipVel, _rtrPowerReq * 0.001, _reqEngTorque, (_reqEngTorque / 2) / 481, (_reqEngTorque / 2) / 481, _velZ, _inducedVelocityScalar, _gndEffScalar, (_heli getVariable "bmkhs_collectiveOutput"), _heli call BIS_fnc_getPitchBank select 0];
                    */
