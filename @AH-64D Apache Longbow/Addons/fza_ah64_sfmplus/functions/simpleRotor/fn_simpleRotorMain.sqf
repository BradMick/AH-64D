/* ----------------------------------------------------------------------------
Function: fza_sfmplus_fnc_simpleRotorMain

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
params ["_heli", "_deltaTime", "_altitude", "_temperature", "_dryAirDensity", "_attHoldCycPitchOut", "_attHoldCycRollOut", "_altHoldCollOut"];
#include "\fza_ah64_sfmplus\headers\core.hpp"

private _rtrPos                 = [0.0, 2.06, 0.70];
private _rtrHeightAGL           = 3.606;   //m
private _rtrDesignRPM           = 289.0;
private _gearRatio              = 72.29;
private _yawTorqueScalar        = 0.85; //0.95, 1.10
private _pitchTorqueScalar      = 2.75;//2.25//1.75;//PITCH_SCALAR;
private _rollTorqueScalar       = 1.00;//0.75;//ROLL_SCALAR;
private _numBlades              = 4;

private _bladeRadius            = 7.315;   //m
private _bladeChord             = 0.533;   //m
private _bladePitch_min         = 1.0;     //deg
private _bladePitch_max         = 7.9341;  //deg
private _bladeLiftCurveSlope    = 5.7;

private _tipLossAndGndEffScalarTable = 
[//-GWT-----Tip-----Gnd
 [ 6804, 1.0126, 1.2060]
,[ 7711, 1.0058, 1.1949]
,[ 8165, 1.0000, 1.2086]
,[ 8618, 0.9948, 1.2028]
,[ 9525, 0.9964, 1.2036]
];

private _bladeLiftCoefScalarTable =
[//-m/s-------SL--2k ft--4k ft--6k ft--8k ft-
 [  0.0,  0.5412]
,[  5.14, 0.5269]
,[ 10.29, 0.5343]
,[ 20.58, 0.5734]
,[ 27.78, 0.5724]
,[ 36.01, 0.5732]
,[ 38.07, 0.5776]
,[ 46.30, 0.5342]
,[ 51.44, 0.5046]
,[ 56.59, 0.4734]
,[ 61.73, 0.4456]
,[ 66.88, 0.4393]
,[ 69.96, 0.4557]
,[ 72.02, 0.4904]
];

private _profileScalar_min = 0.1800;
private _profileScalar_max = 0.2800;

private _inducedScalarTable =
[//--Coll--Ind-Min-Ind-Max
  [ 0.000, 0.7280, 0.2025]
, [ 1.000, 1.3170, 1.0715]
];

private _vel_vbe     =  38.583;
private _vel_vne     = 128.611;
//Get the current collective value
private _collectiveOut     = fza_sfmplus_collectiveOutput + _altHoldCollOut;
//Gather velocities
private _velXY             = vectorMagnitude [velocityModelSpace _heli # 0, velocityModelSpace _heli # 1];
private _velZ              = velocityModelSpace _heli # 2;
//Get the current gross weight
private _curGWT_kg         = _heli getVariable "fza_sfmplus_GWT";
//Get engine RPM
(_heli getVariable "fza_sfmplus_engPctNP")
    params ["_eng1PctNP", "_eng2PctNp"];
private _inputRPM          = _eng1PctNP max _eng2PctNp;
//Calculate omega
private _omega             = (2.0 * PI) * ((_rtrDesignRPM * _inputRPM) / 60);

//Profile power scalar
private _profileScalar     = _profileScalar_min + ((_profileScalar_max - _profileScalar_min) / _vel_vne) * _velXY;
//Induced power scalar
private _inducedScalar_min = [_inducedScalarTable, _collectiveOut] call fza_fnc_linearInterp select 1;
_inducedScalar_min         = _inducedScalar_min *  _collectiveOut;
private _inducedScalar_max = [_inducedScalarTable, _collectiveOut] call fza_fnc_linearInterp select 2;
private _inducedScalar     = ((_inducedScalar_min - _inducedScalar_max) / _vel_vbe) * _velXY + _inducedScalar_min;
//Total power
private _powerScalar       = _profileScalar + _inducedScalar;

private _power_req         = _powerScalar * 2133;
private _torque_req        = (_power_req / 0.001) / 0.105 / 21109;
private _rtrTorque         = _torque_req * _gearRatio;

//Blade Pitch Angle
private _bladePitchAngleAt75PctChord = _bladePitch_min + (_bladePitch_max - _bladePitch_min) * _collectiveOut;
//Lift coefficient scalars
private _bladeLiftCoefScalar         = [_bladeLiftCoefScalarTable,    _velXY] call fza_fnc_linearInterp select 1;
private _bladeTipLossScalar          = [_tipLossAndGndEffScalarTable, _curGWT_kg] call fza_fnc_linearInterp select 1;
//Ground Effect Scalar
private _groundEffectScalar_val      = [_tipLossAndGndEffScalarTable, _curGWT_kg] call fza_fnc_linearInterp select 2;
private _heightAGL                   = ASLToAGL getPosASL _heli # 2;
private _groundEffectScalar          = linearConversion[0.0, _bladeRadius * 2.0, _heightAGL, _groundEffectScalar_val, 1.0];
_groundEffectScalar                  = [_groundEffectScalar, 1.0, _groundEffectScalar_val] call BIS_fnc_clamp;

//Calculate the final lift coefficient
private _bladeLiftCoef               = (rad _bladePitchAngleAt75PctChord) * _bladeLiftCurveSlope; 
_bladeLiftCoef                       = _bladeLiftCoef * _bladeLiftCoefScalar * _bladeTipLossScalar * _groundEffectScalar;

private _bladeLengthAt75PctChord     = _bladeRadius * 0.75;
private _bladeArea                   = _bladeRadius * _bladeChord;
private _bladeVelAt75PctChord        = (_bladeLengthAt75PctChord * _omega) + _velXY;
//Calculate blade lift
private _bladeLift                   = _bladeLiftCoef * 0.5 * _dryAirDensity * _bladeArea * _bladeVelAt75PctChord^2;
//Induced velocity scalar
private _inducedVelocityScalar     = 1.0;
if (_velZ < -VEL_VRS && _velXY < VEL_ETL) then { 
    _inducedVelocityScalar = 0.0;
} else {
    _inducedVelocityScalar = 1 - (_velZ / VEL_VRS);
};
//Calculate total thrust
private _thrust = _bladeLift * _numBlades;
_thrust         = _thrust * _inducedVelocityScalar;

/*
hintsilent format ["Collective Out = %1
                   \nProfile Scalar = %2
                   \nInduced Scalar Min = %3
                   \nInduced Scalar Max = %4
                   \nPower Scalar = %5
                   \nBlade Pitch Angle = %6
                   \nBlade Lift Coef Scalar = %7
                   \nBlade Tip Loss Scalar = %8
                   \nBlade Ground Effect Scalar = %9
                   \nBlade Lift Coef = %10
                   \nThrust = %11", _collectiveOut, _profileScalar, _inducedScalar_min, _inducedScalar_max, _powerScalar, _bladePitchAngleAt75PctChord, _bladeLiftCoefScalar, _bladeTipLossScalar, _groundEffectScalar, _bladeLiftCoef, _thrust];
*/

//END NEW ROTOR MODEL TESTING

//Calcualte the required engine torque
private _rtrRPMTorqueScalar        = 1.0;
private _onGnd                   = [_heli] call fza_sfmplus_fnc_onGround;
if (_inputRPM < 1.0 && !_onGnd) then {
    _rtrRPMTorqueScalar = _inputRPM;
};
_rtrRPMTorqueScalar                = [_rtrRPMTorqueScalar, EPSILON, 1.0] call BIS_fnc_clamp;
private _reqEngTorque              = (_rtrTorque / _gearRatio) / _rtrRPMTorqueScalar;
_heli setVariable ["fza_sfmplus_reqEngTorque", _reqEngTorque];

private _axisX = [1.0, 0.0, 0.0];
private _axisY = [0.0, 1.0, 0.0];
private _axisZ = [0.0, 0.0, 1.0];

[_heli, "fza_sfmplus_rtrThrust", 0, _thrust, true] call fza_fnc_setArrayVariable;
private _thrustZ             = _axisZ vectorMultiply (_thrust * _deltaTime);

//Pitch torque
private _cyclicFwdAftTrim    = _heli getVariable "fza_ah64_forceTrimPosPitch";
private _torqueX             = ((_thrust * (fza_sfmplus_cyclicFwdAft + _cyclicFwdAftTrim + _attHoldCycPitchOut)) * _pitchTorqueScalar) * _deltaTime;
//Roll torque
private _cyclicLeftRightTrim = _heli getVariable "fza_ah64_forceTrimPosRoll";
private _torqueY             = ((_thrust * (fza_sfmplus_cyclicLeftRight + _cyclicLeftRightTrim + _attHoldCycRollOut)) * _rollTorqueScalar) * _deltaTime;
//Main rotor yaw torque
private _torqueZ             = (_rtrTorque  * _yawTorqueScalar) * _deltaTime;

private _mainRtrDamage  = _heli getHitPointDamage "HitHRotor";

//Rotor forces
if (currentPilot _heli == player) then {
    if (_mainRtrDamage < 0.99) then {
        //Main rotor thrust
        _heli addForce  [_heli vectorModelToWorld _thrustZ, _rtrPos];
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
[_heli, _rtrPos, _rtrPos vectorAdd _axisX, "red"]   call fza_fnc_debugDrawLine;
[_heli, _rtrPos, _rtrPos vectorAdd _axisY, "green"] call fza_fnc_debugDrawLine;
[_heli, _rtrPos, _rtrPos vectorAdd _axisZ, "blue"]  call fza_fnc_debugDrawLine;
[_heli, 24, _rtrPos, _bladeRadius, 2, "white", 0]   call fza_fnc_debugDrawCircle;
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
                    \nPitch = %11", _rtrOmega, _bladeTipVel, _rtrPowerReq * 0.001, _reqEngTorque, (_reqEngTorque / 2) / 481, (_reqEngTorque / 2) / 481, _velZ, _inducedVelocityScalar, _gndEffScalar, fza_sfmplus_collectiveOutput, _heli call BIS_fnc_getPitchBank select 0];
                    */