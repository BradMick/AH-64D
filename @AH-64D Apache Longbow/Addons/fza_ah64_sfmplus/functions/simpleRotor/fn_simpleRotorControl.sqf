params ["_heli", "_sfmPlusConfig", "_rtrNum", "_deltaTime", "_vel2D"];
#include "\fza_ah64_sfmplus\headers\core.hpp"

private _heliType            = getNumber (_sfmPlusConfig >> "heliType");
private _rtrType             = getArray  (_sfmPlusConfig >> "rotorType")         select _rtrNum;

private _collective_min      = getArray  (_sfmPlusConfig >> "collectivePitch")   select _rtrNum select 0;
private _collective_max      = getArray  (_sfmPlusConfig >> "collectivePitch")   select _rtrNum select 1;
//Add FMC input here

private _cyclicPitch_min     = getArray (_sfmPlusConfig >> "cyclicPitch")        select _rtrNum select 0;
private _cyclicPitch_max     = getArray (_sfmPlusConfig >> "cyclicPitch")        select _rtrNum select 1;
private _cyclicPitch_mix     = getArray (_sfmPlusConfig >> "cyclicPitch")        select _rtrNum select 2;
private _cyclicFwdAftTrim    = _heli getVariable "fza_sfmplus_forceTrimPosPitch";
//Add FMC input here

private _cyclicRoll_min      = getArray (_sfmPlusConfig >> "cyclicRoll")         select _rtrNum select 0;
private _cyclicRoll_max      = getArray (_sfmPlusConfig >> "cyclicRoll")         select _rtrNum select 1;
private _cyclicLeftRightTrim = _heli getVariable "fza_sfmplus_forceTrimPosRoll";
//Add FMC input here

private _pedal_min           = getArray (_sfmPlusConfig >> "collectivePitch")    select _rtrNum select 0;
private _pedal_max           = getArray (_sfmPlusConfig >> "collectivePitch")    select _rtrNum select 1;
private _pedal_mix           = getArray (_sfmPlusConfig >> "collectivePitch")    select _rtrNum select 2;
private _pedalLeftRightTrim  = _heli getVariable "fza_sfmplus_forceTrimPosPedal";
//Add FMC input here

private _AIC           = 0.0;
private _BIC           = 0.0;
private _theta0        = 0.0;
private _mastPitchRoll = [0.0,0.0];

([_heli, _deltaTime] call fza_sfmplus_fnc_fmc)
    params ["_attHoldCycPitchOut", "_attHoldCycRollOut", "_hdgHoldPedalYawOut", "_altHoldCollOut"];

switch (_heliType) do {
    case CONVENTIONAL: {
        if (_rtrType == MAIN) then {
            _theta0 = _collective_min + ((_collective_max - _collective_min) * (fza_sfmplus_collectiveOutput + _altHoldCollOut));
            _AIC    = linearConversion[-1.0, 1.0, fza_sfmplus_cyclicLeftRight + _cyclicLeftRightTrim + _attHoldCycRollOut,  _cyclicRoll_min,  _cyclicRoll_max,  true];
            _BIC    = linearConversion[-1.0, 1.0, fza_sfmplus_cyclicFwdAft    + _cyclicFwdAftTrim    + _attHoldCycPitchOut, _cyclicPitch_min, _cyclicPitch_max,  true];
            
            //systemChat format ["Collective Min = %1 -- Collective Max = %2", _collective_min, _collective_max];
            //systemChat format ["Cyclic Roll Min = %1 -- Cyclic Roll Max = %2", _cyclicRoll_min, _cyclicRoll_max];
            //systemChat format ["Cyclic Pitch Min = %1 -- Cyclic Pitch Max = %2", _cyclicPitch_min, _cyclicPitch_max];
        };

        if (_rtrType == TAIL) then {
            _theta0 = linearConversion[ 1.0,-1.0, fza_sfmplus_pedalLeftRight + _pedalLeftRightTrim + _hdgHoldPedalYawOut, _pedal_min,  _pedal_max,  true];

            //systemChat format ["Pedal Min = %1 -- Pedal Max = %2", _pedal_min, _pedal_max];
        };
    };
    case TANDEM: {

    };
    case COAXIAL: {

    };
    case TILTROTOR: {

    };
};

[_AIC, _BIC, _theta0, _mastPitchRoll];