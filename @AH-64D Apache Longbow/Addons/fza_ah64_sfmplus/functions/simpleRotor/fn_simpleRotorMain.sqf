/* ----------------------------------------------------------------------------
Function: fza_sfmplus_fnc_simpleRotorMain

Description:
    Simple rotor provides a simple, Gnded in reality simulation of a
    helicopters rotor. Translational Lift, Gnd Effect and Vortex Ring State
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
params ["_heli", "_deltaTime", "_altitude", "_temperature", "_dryAirDensity", "_attHoldCycPitchOut", "_attHoldCycRollOut", "_altHoldCollOut"];
#include "\fza_ah64_sfmplus\headers\core.hpp"

private _pos                  = [0.0, 2.06, 0.70];
private _rotorHeightAGL       = 3.606;      //m
private _designRPM            = 289.0;
private _gearRatio            = 72.29;
private _numBlades            = 4;
private _velBestEndurance     = 35.583;     //75kts

private _bladeLengthAt75Chord = 5.486;      //m
private _rotorDiameter        = 14.63;      //m
private _bladeArea            = 3.899;      //m^2

private _bladeLiftCoef_min    = 0.1590;
private _bladeDragCoef_min    = 0.0084;
private _bladeLiftDragTable   = [//  TAS----CL_max------CD_max 
                                 [  0.00,   0.3574,     0.0596]
                                ,[  2.57,   0.3804,     0.0572]
                                ,[  5.14,   0.3925,     0.0548]
                                ,[ 10.29,   0.4185,     0.0523]
                                ,[ 15.43,   0.4297,     0.0499]
                                ,[ 20.58,   0.4297,     0.0475]
                                ,[ 25.72,   0.4297,     0.0451]
                                ,[ 30.87,   0.4297,     0.0426]
                                ,[ 36.01,   0.4297,     0.0402]
                                ,[ 41.16,   0.4297,     0.0402]
                                ,[ 46.30,   0.4297,     0.0402]
                                ,[ 51.44,   0.4297,     0.0402]
                                ,[ 56.59,   0.4297,     0.0402]
                                ,[ 61.73,   0.4297,     0.0402]
                                ];
private _rotorGndEffModifier  = 0.1964;

private _pitchTorqueScalar    = 2.75;//2.25//1.75;//PITCH_SCALAR;
private _rollTorqueScalar     = 1.00;//0.75;//ROLL_SCALAR;
private _yawTorqueScalar      = 1.10; //0.95, 1.10


(velocityModelSpace _heli)
    params ["_modelVelX", "_modelVelY", "_modelVelZ"];
(velocity _heli)
    params ["_velX", "_velY", "_velZ"];

(_heli getVariable "fza_sfmplus_engPctNP")
    params ["_eng1PctNP", "_eng2PctNp"];

private _inputRPM               = _eng1PctNP max _eng2PctNp;
private _rotorRPM               = _inputRPM * _designRPM;

private _rotorOmega             = (2 * PI) * (_rotorRPM / 60);

private _velXY                  = vectorMagnitude [_modelVelX, _modelVelY];
private _bladeVelAt75Chord      = _rotorOmega * _bladeLengthAt75Chord;
/////////////////////////////////////////////////////////////////////////////////////////////
// Lift & Thrust           //////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////
private _bladeLiftCoef_max      = [_bladeLiftDragTable, _velXY] call fza_fnc_linearInterp select 1;

private _bladeLiftCoef          = _bladeLiftCoef_min + ((_bladeLiftCoef_max - _bladeLiftCoef_min) * (fza_sfmplus_collectiveOutput + _altHoldCollOut));
private _bladeLift              = _bladeLiftCoef * 0.5 * _dryAirDensity * _bladeArea * _bladeVelAt75Chord^2;

private _baseThrust             = _bladeLift   * _numBlades;
/////////////////////////////////////////////////////////////////////////////////////////////
// Drag & Torque           //////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////
private _bladeDragCoef_max      = [_bladeLiftDragTable, _velXY] call fza_fnc_linearInterp select 2;

private _bladeDragCoef          = _bladeDragCoef_min + ((_bladeDragCoef_max - _bladeDragCoef_min) * (fza_sfmplus_collectiveOutput + _altHoldCollOut));
private _bladeDrag              = _bladeDragCoef * 0.5 * _dryAirDensity * _bladeArea * _bladeVelAt75Chord^2;

private _bladeTorque            = _bladeDrag   * _bladeLengthAt75Chord;

private _rotorTorque            = _bladeTorque * _numBlades;
/////////////////////////////////////////////////////////////////////////////////////////////
// Induced Velocity        //////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////
private _rotorIndVelScalar      = 1.0;
if (_velZ < -VEL_VRS && _velXY < VEL_ETL) then { 
    _rotorIndVelScalar = 0.0;
} else {
    _rotorIndVelScalar = 1 - (_velZ / VEL_VRS);
};
/////////////////////////////////////////////////////////////////////////////////////////////
// Ground Effect           //////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////
private _heightAGL            = _rotorHeightAGL + (ASLToAGL getPosASL _heli #2);
private _rotorGndEffScalar    = 1 - (_heightAGL / _rotorDiameter);
_rotorGndEffScalar            = [_rotorGndEffScalar, 0.0, 1.0] call BIS_fnc_clamp;
private _rotorGndEffVelScalar = linearConversion [0.0, VEL_ETL, _velXY, 1.0, 0.0];
_rotorGndEffVelScalar         = [_rotorGndEffVelScalar, 0.0, 1.0] call BIS_fnc_clamp;
_rotorGndEffScalar            = _rotorGndEffScalar * _rotorGndEffVelScalar * _rotorGndEffModifier;
private _rotorGndEffThrust    = _baseThrust * _rotorGndEffScalar;
/////////////////////////////////////////////////////////////////////////////////////////////
// Outputs                 //////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////
private _finalThrust          = (_baseThrust * _rotorIndVelScalar) + _rotorGndEffThrust;
private _engineTorqueReq      = _rotorTorque / _gearRatio;
_heli setVariable ["fza_sfmplus_reqEngTorque", _engineTorqueReq];

private _axisX = [1.0, 0.0, 0.0];
private _axisY = [0.0, 1.0, 0.0];
private _axisZ = [0.0, 0.0, 1.0];

[_heli, "fza_sfmplus_rotorThrust", 0, _finalThrust, true] call fza_fnc_setArrayVariable;
private _thrustZ             = _axisZ vectorMultiply (_finalThrust * _deltaTime);

//Pitch torque
private _cyclicFwdAftTrim    = _heli getVariable "fza_ah64_forceTrimPosPitch";
private _torqueX             = ((_baseThrust * (fza_sfmplus_cyclicFwdAft + _cyclicFwdAftTrim + _attHoldCycPitchOut)) * _pitchTorqueScalar) * _deltaTime;
//Roll torque
private _cyclicLeftRightTrim = _heli getVariable "fza_ah64_forceTrimPosRoll";
private _torqueY             = ((_baseThrust * (fza_sfmplus_cyclicLeftRight + _cyclicLeftRightTrim + _attHoldCycRollOut)) * _rollTorqueScalar) * _deltaTime;
//Main rotor yaw torque
private _torqueZ             = (_rotorTorque  * _yawTorqueScalar) * _deltaTime;

private _mainRtrDamage       = _heli getHitPointDamage "HitHRotor";

//Rotor forces
if (currentPilot _heli == player) then {
    if (_mainRtrDamage < 0.99) then {
        //Main rotor thrust
        _heli addForce  [_heli vectorModelToWorld _thrustZ, _pos];
        private _torque = [0.0, 0.0, 0.0];

        //Main rotor torque
        if (fza_ah64_sfmplusEnableTorqueSim) then {
            _torque = [_torqueX, _torqueY, _torqueZ];
        } else {
            _torque = [_torqueX, _torqueY, 0.0];
        };
        _heli addTorque (_heli vectorModelToWorld _torque);
    };
};

if (cameraView == "INTERNAL") then {
    //Camera shake effect for ETL (16 to 24 knots)
    if (_velXY > 8.23 && _velXY < 12.35) then {
        enableCamShake true;
        setCamShakeParams [0.0, 0.5, 0.0, 0.0, true];
        addCamShake       [0.9, 0.4, 6.2];
        enableCamShake false;

        setCustomSoundController[_heli, "CustomSoundController3", 1.5];
        setCustomSoundController[_heli, "CustomSoundController4", 0.8];
    } else {
        setCustomSoundController[_heli, "CustomSoundController4", 0.0];
    };

    //Camera shake effect for vortex ring sate
    if (_velXY < 12.35) then {  //must be less than ETL
        //2000 fpm to 2933fpm
        if (_velZ < -10.16 && _velZ > -14.89) then {
            enableCamShake true;
            setCamShakeParams [0.0, 0.5, 0.0, 0.0, true];
            addCamShake       [2.5, 1, 5];
            enableCamShake false;

            setCustomSoundController[_heli, "CustomSoundController3", 6.4];
            setCustomSoundController[_heli, "CustomSoundController4", 1.8];
        };
        //2933 fpm to 3867 
        if (_velZ <= -14.89 && _velZ > -19.64) then {
            enableCamShake true;
            setCamShakeParams [0.0, 0.5, 0.0, 0.5, true];
            addCamShake       [3, 1, 5.5];
            enableCamShake false;

            setCustomSoundController[_heli, "CustomSoundController3", 6.4];
            setCustomSoundController[_heli, "CustomSoundController4", 1.8];
        };
        //3867fpm to 4800 fpm
        if (_velZ <= -19.64 && _velZ > -24.384) then {
            enableCamShake true;
            setCamShakeParams [0.0, 0.75, 0.0, 0.75, true];
            addCamShake       [3.5, 1, 6.0];
            enableCamShake false;

            setCustomSoundController[_heli, "CustomSoundController3", 6.4];
            setCustomSoundController[_heli, "CustomSoundController4", 1.8];
        };
        //> 4800fpm
        if (_velZ < -24.384) then {
            enableCamShake true;
            setCamShakeParams [0.0, 1.0, 0.0, 2.0, true];
            addCamShake       [4.0, 1, 6.5];
            enableCamShake false;

            setCustomSoundController[_heli, "CustomSoundController3", 6.4];
            setCustomSoundController[_heli, "CustomSoundController4", 1.8];
        };
    } else {
        setCustomSoundController[_heli, "CustomSoundController4", 0.0];
    };
};

#ifdef __A3_DEBUG__
[_heli, _pos, _pos vectorAdd _axisX, "red"]   call fza_fnc_debugDrawLine;
[_heli, _pos, _pos vectorAdd _axisY, "green"] call fza_fnc_debugDrawLine;
[_heli, _pos, _pos vectorAdd _axisZ, "blue"]  call fza_fnc_debugDrawLine;
[_heli, 24, _pos, _bladeRadius, 2, "white", 0]   call fza_fnc_debugDrawCircle;
#endif

//[_outThrust, _outTq];

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
                    \nPitch = %11", _rotorOmega, _bladeTipVel, _rotorPowerReq * 0.001, _reqEngTorque, (_reqEngTorque / 2) / 481, (_reqEngTorque / 2) / 481, _velZ, _inducedVelocityScalar, _gndEffScalar, fza_sfmplus_collectiveOutput, _heli call BIS_fnc_getPitchBank select 0];
                    */