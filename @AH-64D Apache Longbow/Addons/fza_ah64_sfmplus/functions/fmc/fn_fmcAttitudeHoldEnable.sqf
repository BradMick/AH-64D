params ["_heli"];
#include "\fza_ah64_sfmplus\headers\core.hpp"

if (_heli getVariable "fza_ah64_attHoldActive" == false) then {
    //Position hold
    if (fza_sfmplus_gndSpeed <= POS_HOLD_SPEED_SWITCH) then {
        _heli setVariable ["fza_ah64_attHoldSubMode",   "pos",         true];
        _heli setVariable ["fza_ah64_attHoldDesiredPos", getPos _heli, true];
    };
    //Velocity hold
    //This needs to check if accelerating or decelerating...really it's
    //5 to 40 knots accelerating, 30 to 5 knots decelerating
    if (fza_sfmplus_gndSpeed > POS_HOLD_SPEED_SWITCH && fza_sfmplus_gndSpeed <= VEL_HOLD_SPEED_SWITCH_ACCEL) then {
        _heli setVariable ["fza_ah64_attHoldSubMode", "vel", true];
        
        private _velX  = (fza_sfmplus_velModelSpace # 0) * -1.0;
        private _velY  =  fza_sfmplus_velModelSpace # 1;
        _heli setVariable ["fza_ah64_attHoldDesiredVel", [_velX, _velY], true];
    };
    //Attitude hold
    if (fza_sfmplus_gndSpeed > VEL_HOLD_SPEED_SWITCH_ACCEL) then {
        _heli setVariable ["fza_ah64_attHoldSubMode", "att", true];

        (_heli call BIS_fnc_getPitchBank)
            params ["_curPitch", "_curRoll"];
        _heli setVariable ["fza_ah64_attHoldDesiredAtt", [_curPitch, _curRoll], true];
    };

    _heli setVariable ["fza_ah64_attHoldActive", true, true];
} else {
    _heli setVariable ["fza_ah64_attHoldActive", false, true];
    [_heli] call fza_audio_fnc_flightTone;
};