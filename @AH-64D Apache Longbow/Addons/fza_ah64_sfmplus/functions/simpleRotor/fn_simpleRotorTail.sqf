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
params ["_heli", "_deltaTime", "_altitude", "_temperature", "_dryAirDensity", "_hdgHoldPedalYawOut"];
#include "\fza_ah64_sfmplus\headers\core.hpp"

private _rtrPos                 = [-0.87, -6.98, -0.075];
private _rtrDesignRPM           = 1403.0;
private _rtrRPMTrimVal          = 1.01;
private _rtrGearRatio           = 14.90;
private _rtrNumBlades           = 4;

private _bladeRadius            = 1.402;   //m
private _bladeChord             = 0.253;   //m
private _bladePitch_min         = -15.0;     //deg
private _bladePitch_max         =  27.0;    //deg
private _bladePitch_med         = (_bladePitch_min + _bladePitch_max) / 2;    

private _rtrPowerScalarTable    = [
                                   [   0, 1.777]
                                  ,[2000, 1.617]
                                  ,[4000, 1.530]
                                  ,[6000, 1.377]
                                  ,[8000, 1.284]
                                  ];
private _rtrThrustScalar_min    = 0.150;
private _rtrThrustScalar_max    = 0.390;   //20,200lbs @ 6700ft, 15 deg C and 0.9 collective
private _rtrThrustScalar_med    = (_rtrThrustScalar_min + _rtrThrustScalar_max) / 2;
private _rtrAirspeedVelocityMod = 0.4;
private _rtrTorqueScalar        = 0.25;

private _altitude_max           = 30000;   //ft
private _baseThrust             = 102302;  //N - max gross weight (kg) * gravity (9.806 m/s)

//Thrust produced

private _bladePitch_cur                = _bladePitch_med + ((fza_sfmplus_pedalLeftRight) / (2 / (_bladePitch_max - _bladePitch_min))); //+ _hdgHoldPedalYawOut;
_bladePitch_cur                        = [_bladePitch_cur, _bladePitch_min, _bladePitch_max] call BIS_fnc_clamp;
private _bladePitchInducedThrustScalar = _rtrThrustScalar_med + ((fza_sfmplus_pedalLeftRight) * ((_rtrThrustScalar_max - _rtrThrustScalar_min) / 2)); //+ _hdgHoldPedalYawOut;
(_heli getVariable "fza_sfmplus_engPctNP")
    params ["_eng1PctNP", "_eng2PctNp"];
private _inputRPM                  = _eng1PctNP max _eng2PctNp;
private _rtrRPMInducedThrustScalar = (_inputRPM / _rtrRPMTrimVal) * _rtrThrustScalar_max;
//Thrust scalar as a result of altitude
private _airDensityThrustScalar    = _dryAirDensity / ISA_STD_DAY_AIR_DENSITY;
//Additional thrust gained from increasing forward airspeed
private _velYZ                      = vectorMagnitude [velocityModelSpace _heli # 1, velocityModelSpace _heli # 2];
private _airspeedVelocityScalar    = (1 + (_velYZ / VEL_BEST_ENDURANCE)) ^ (_rtrAirspeedVelocityMod);
//Induced flow handler
private _velX                      = velocityModelSpace _heli # 0;
private _inducedVelocityScalar     = 1.0;
if (_velX < -VEL_VRS && _velYZ < VEL_ETL) then { 
    _inducedVelocityScalar = 0.0;
} else { 
    _inducedVelocityScalar = 1 - (_velX / VEL_VRS);
};
//Finally, multiply all the scalars above to arrive at the final thrust scalar
private _rtrThrustScalar           = _bladePitchInducedThrustScalar * _rtrRPMInducedThrustScalar * _airDensityThrustScalar * _airspeedVelocityScalar * _inducedVelocityScalar;
private _rtrThrust                 = _baseThrust * _rtrThrustScalar;

systemChat format ["Blade Pitch Cur = %1", _bladePitch_cur toFixed 2];
systemChat format ["Blade Pitch Induced Thrust Scalar = %1", _bladePitchInducedThrustScalar toFixed 2];
systemChat format ["Rotor Thrust Scalar = %1 -- %2", _rtrThrustScalar, _rtrThrust];

private _rtrOmega                  = (2.0 * PI) * ((_rtrDesignRPM * _inputRPM) / 60);
private _bladeTipVel               = _rtrOmega * _bladeRadius;
private _rtrArea                   = PI * _bladeRadius^2;
private _thrustCoef                = if (_rtrOmega == 0) then { 0.0; } else { _rtrThrust / (_dryAirDensity * _rtrArea * _rtrOmega^2 * _bladeRadius^2); };
_thrustCoef                        = if (_inducedVelocityScalar == 0.0) then { 0.0; } else { _thrustCoef / _inducedVelocityScalar; };

//Calculate the hover induced velocity
private _rtrInducedVelocity        = sqrt(_rtrThrust / (2 * _dryAirDensity * _rtrArea));
//Gather the velocities required to determine the actual induced flow velocity using the newton-raphson method
private _w = _rtrInducedVelocity;
private _u = if (_w == 0) then { 0.0; } else { _velYZ / _rtrInducedVelocity; };
private _n = if (_w == 0) then { 0.0; } else { _velX  / _rtrInducedVelocity; };
private _rtrCorrInducedVelocity    = if (_w == 0) then { 0.0; } else { [_w, _u, _n] call fza_sfmplus_fnc_simpleRotorNewtRaphSolver; };
_rtrCorrInducedVelocity            = _rtrCorrInducedVelocity * _rtrInducedVelocity;
//Calculate the required rotor power
private _rtrPowerScalar            = [_rtrPowerScalarTable, _altitude] call fza_fnc_linearInterp select 1;
private _rtrPowerReq               = (_rtrThrust * _velX + _rtrThrust * _rtrCorrInducedVelocity) * _rtrPowerScalar;
//Calculate the required rotor torque
private _rtrTorque                 = if (_rtrOmega == 0) then { 0.0; } else { _rtrPowerReq / _rtrOmega; };
//Calcualte the required engine torque
private _reqEngTorque              = _rtrTorque / _rtrGearRatio;
//_heli setVariable ["fza_sfmplus_reqEngTorque", _reqEngTorque];

private _axisX = [0.0, 0.0,-1.0];
private _axisY = [0.0, 1.0, 0.0];
private _axisZ = [1.0, 0.0, 0.0];

private _totalThrust  = _rtrThrust;
private _thrustZ      = _axisZ vectorMultiply ((_totalThrust * -1.0) * _deltaTime);
//private _torqueY      = _axisY vectorMultiply ((_rtrTorque  * _rtrTorqueScalar) * _deltaTime);

//Rotor thrust force
_heli addForce [_heli vectorModelToWorld _thrustZ, _rtrPos];
//Main rotor torque effect
//if (fza_ah64_sfmplusEnableTorqueSim) then {
//    _heli addTorque (_heli vectorModelToWorld _torqueY);
//};

#ifdef __A3_DEBUG__
[_heli, _rtrPos, _rtrPos vectorAdd _axisX, "red"]   call fza_fnc_debugDrawLine;
[_heli, _rtrPos, _rtrPos vectorAdd _axisY, "green"] call fza_fnc_debugDrawLine;
[_heli, _rtrPos, _rtrPos vectorAdd _axisZ, "blue"]  call fza_fnc_debugDrawLine;
[_heli, 24, _rtrPos, _bladeRadius, 0, "white", 0]   call fza_fnc_debugDrawCircle;
#endif

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
                    \nPitch = %11", _rtrOmega, _bladeTipVel, _rtrPowerReq * 0.001, _reqEngTorque, (_reqEngTorque / 2) / 481, (_reqEngTorque / 2) / 481, _velZ, _inducedVelocityScalar, _gndEffScalar, fza_sfmplus_collectiveOutput, _heli call BIS_fnc_getPitchBank select 0];
                    */