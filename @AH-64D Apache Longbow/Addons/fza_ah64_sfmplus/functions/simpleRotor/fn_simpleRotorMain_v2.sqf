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
params ["_heli", "_deltaTime", "_altitude", "_temperature", "_dryAirDensity", "_altHoldCollOut"];
#include "\fza_ah64_sfmplus\headers\core.hpp"

private _rtrPos          = [0.0, 2.06, 0.70];
private _rtrHeightAGL    = 3.606;   //m
private _rtrDesignRPM    = 289.0;
private _rtrRPMTrimVal   = 1.01;
private _rtrGearRatio    = 72.29;
private _rtrNumBlades    = 4;
private _rtrTorqueScalar = 1.00;

private _bladeRadius     = 7.315;   //m
private _bladeChord      = 0.533;   //m

private _rtrCoefTable  =
                        [ //  PA Gnd Eff  CL_min  CL_max  CD_min  CD_max
                          [    0, 0.3225, 0.0320, 0.4153, 0.0027, 0.0186]
                        , [ 2000, 0.3482, 0.0320, 0.4166, 0.0037, 0.0161]
                        , [ 4000, 0.2997, 0.0320, 0.4218, 0.0049, 0.0141]
                        , [ 6000, 0.3226, 0.0320, 0.4200, 0.0064, 0.0123]
                        , [ 8000, 0.2798, 0.0320, 0.4480, 0.0084, 0.0103]
                        ];

private _rtrGndEffCoef  = [_rtrCoefTable, _altitude] call fza_fnc_linearInterp select 1;
//Rotor lift coefficient min/max
private _rtrMinLiftCoef = [_rtrCoefTable, _altitude] call fza_fnc_linearInterp select 2;
private _rtrMaxLiftCoef = [_rtrCoefTable, _altitude] call fza_fnc_linearInterp select 3;
//Rotor drag coefficient min/max
private _rtrMinDragCoef = [_rtrCoefTable, _altitude] call fza_fnc_linearInterp select 4;
private _rtrMaxDragCoef = [_rtrCoefTable, _altitude] call fza_fnc_linearInterp select 5;

private _bladeArea      = _bladeRadius * _bladeChord;
private _rtrArea        = PI * _bladeRadius^2;

//Calculate and gather blade velocity
(_heli getVariable "fza_sfmplus_engPctNP")
    params ["_eng1PctNP", "_eng2PctNp"];
private _inputRPM       = (_eng1PctNP max _eng2PctNp) / _rtrRPMTrimVal;
private _rtrRPM         = _rtrDesignRPM * (_inputRPM * _rtrRPMTrimVal);
private _omega          = (2 * PI) * (_rtrRPM / 60);
private _bladeTipVel    = _omega * _bladeRadius;
private _velXY          = vectorMagnitude [velocityModelSpace _heli # 0, velocityModelSpace _heli # 1];
private _velZ           = velocityModelSpace _heli # 2;
private _bladeVel       = _bladeTipVel + _velXY;

//Caclulate blade lift
private _bladeLiftCoef  = _rtrMinLiftCoef + (_rtrMaxLiftCoef - _rtrMinLiftCoef) * (fza_sfmplus_collectiveOutput + _altHoldCollOut);
private _bladeLift      = _bladeLiftCoef * 0.5 * _dryAirDensity * _bladeArea * _bladeVel^2;

//Calculate blade drag
private _bladeDragCoef  = _rtrMinDragCoef + (_rtrMaxDragCoef - _rtrMinDragCoef) * fza_sfmplus_collectiveOutput;
private _bladeDrag      = _bladeDragCoef * 0.5 * _dryAirDensity * _bladeArea * _bladeVel^2;

//Calculate rotor thrust
private _phi_deg        = _heli getVariable "fza_sfmplus_rtrMain_phi_deg";
private _rtrThrust      = _rtrNumBlades * (_bladeLift * (cos _phi_deg) - _bladeDrag * (sin _phi_deg));
private _rtrTorque      = _rtrNumBlades * ((_bladeLift * (sin _phi_deg) + _bladeDrag * (cos _phi_deg)) * _bladeRadius);

//Calcualte the required engine torque
private _reqEngTorque          = _rtrTorque / _rtrGearRatio;
_heli setVariable ["fza_sfmplus_reqEngTorque", _reqEngTorque];

//Calculate induced velocity
private _sign                  = [_rtrThrust] call fza_fnc_sign;
private _rtrInducedVelocity    = sqrt((abs _rtrThrust) / (2 * _dryAirDensity * _rtrArea)) * _sign;
//Gather the velocities required to determine the actual induced flow velocity using the newton-raphson method
private _w = _rtrInducedVelocity;
private _u = if (_w == 0) then { 0.0; } else { _velXY / _rtrInducedVelocity; };
private _n = if (_w == 0) then { 0.0; } else { _velZ  / _rtrInducedVelocity; };
private _rtrCorrInducedVelocity = if (_w == 0) then { 0.0; } else { [_w, _u, _n] call fza_sfmplus_fnc_simpleRotorNewtRaphSolver; };
_rtrCorrInducedVelocity         = _rtrCorrInducedVelocity * _rtrInducedVelocity;
//Update phi
private _totVelZ =_velZ + _rtrCorrInducedVelocity;
_phi_deg         = if (_bladeVel == 0.0) then { 0.0; } else { deg (_totVelZ / _bladeVel); };
_heli setVariable ["fza_sfmplus_rtrMain_phi_deg", _phi_deg];

//Calculate induced velocity scalar
private _inducedVelocityScalar     = 1.0;
if (_velZ < -VEL_VRS && _velXY < VEL_ETL) then { 
    _inducedVelocityScalar = 0.0;
} else { 
    _inducedVelocityScalar = 1 - (_velZ / VEL_VRS);
};

//Calculate ground effect thrust
private _heightAGL    = _rtrHeightAGL  + (ASLToAGL getPosASL _heli # 2);
private _rtrDiam      = _bladeRadius * 2;
private _gndEffScalar = (1 - (_heightAGL / _rtrDiam)) * _rtrGndEffCoef;
_gndEffScalar         = [_gndEffScalar, 0.0, 1.0] call BIS_fnc_clamp;
private _gndEffThrust = _rtrThrust * _gndEffScalar;

//Finally, determine the total thrust
private _totalThrust = (_rtrThrust * _inducedVelocityScalar) + _gndEffThrust;

//Axis vectors
private _axisX = [1.0, 0.0, 0.0];
private _axisY = [0.0, 1.0, 0.0];
private _axisZ = [0.0, 0.0, 1.0];

//Multiply thrust and torque by their respective axes
private _thrustZ      = _axisZ vectorMultiply (_totalThrust * _deltaTime);
private _torqueZ      = _axisZ vectorMultiply ((_rtrTorque  * _rtrTorqueScalar) * _deltaTime);

//Apply rotor thrust
_heli addForce [_heli vectorModelToWorld _thrustZ, _rtrPos];
//Apply main rotor torque
if (fza_ah64_sfmplusEnableTorqueSim) then {
    _heli addTorque (_heli vectorModelToWorld _torqueZ);
};

hintsilent format ["Input RPM = %1
                    \nRtr RPM = %2
                    \n----------
                    \nOmega = %3
                    \n----------
                    \nBlade Tip Vel = %4
                    \nBlade Vel = %5
                    \n----------
                    \nBlade Lift Coef = %6
                    \nBlade Drag Coef = %7
                    \n----------
                    \nBlade Lift = %8
                    \nBlade Drag = %9
                    \n----------
                    \nPhi = %10
                    \n----------
                    \nGnd Eff Scalar = %11
                    \nGnd Eff Thrust = %12
                    \n----------
                    \nCollective Out = %13"
                    ,_inputRPM
                    ,_rtrRPM
                    ,_omega
                    ,_bladeTipVel
                    ,_bladeVel
                    ,_bladeLiftCoef
                    ,_bladeDragCoef
                    ,_bladeLift
                    ,_bladeDrag
                    ,_phi_deg
                    ,_gndEffScalar
                    ,_gndEffThrust
                    ,fza_sfmplus_collectiveOutput];

#ifdef __A3_DEBUG__
[_heli, _rtrPos, _rtrPos vectorAdd _axisX, "red"]   call fza_fnc_debugDrawLine;
[_heli, _rtrPos, _rtrPos vectorAdd _axisY, "green"] call fza_fnc_debugDrawLine;
[_heli, _rtrPos, _rtrPos vectorAdd _axisZ, "blue"]  call fza_fnc_debugDrawLine;
[_heli, 24, _rtrPos, _bladeRadius, 2, "white", 0]   call fza_fnc_debugDrawCircle;
#endif