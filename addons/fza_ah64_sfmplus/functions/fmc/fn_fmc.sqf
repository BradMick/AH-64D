params ["_heli"];
#include "\fza_ah64_sfmplus\headers\core.hpp"
#include "\fza_ah64_systems\headers\systems.hpp"

private _mechanicalMixing = false;

//Control mixing
([_heli] call fza_sfmplus_fnc_fmcControlMixing)
    params ["_collToPitchOut", "_collToRollOut", "_collToYawOut", "_yawToPitchOut", "_yawToRollOut", "_collAirspeedToYawOut"];
//Attitude Hold
([_heli] call fza_sfmplus_fnc_fmcAttitudeHold)
    params ["_attHoldCycPitchOut", "_attHoldCycRollOut"];
//Altitude Hold
private _altHoldCollOut     = [_heli] call fza_sfmplus_fnc_fmcAltitudeHold;
//Heading Hold
private _hdgHoldPedalYawOut = [_heli] call fza_sfmplus_fnc_fmcHeadingHold;
//Stability Augmentation System (SAS)
([_heli] call fza_sfmplus_fnc_fmcSAS)
    params ["_SASPitchOutput", "_SASRollOutput", "_SASYawOutput"];

if (fza_ah64_sfmPlusSpringlessPedals || fza_ah64_sfmPlusAutoPedal) then {
    _hdgHoldPedalYawOut = 0.0;
};

if (!(_heli getVariable "fza_ah64_fmcPitchOn")) then {
    _attHoldCycPitchOut = 0.0;
    _SASPitchOutput     = 0.0;
    if (!_mechanicalMixing) then {
        _collToPitchOut = 0.0;
        _yawToPitchOut  = 0.0;
    };
};

if (!(_heli getVariable "fza_ah64_fmcRollOn")) then {
    _attHoldCycRollOut = 0.0;
    _SASRollOutput     = 0.0;
    if (!_mechanicalMixing) then {
        _collToRollOut = 0.0;
        _yawToRollOut  = 0.0;
    };
};

if (!(_heli getVariable "fza_ah64_fmcYawOn")) then {
    _hdgHoldPedalYawOut = 0.0;
    _SASYawOutput       = 0.0;
    if (!_mechanicalMixing) then {
        _collToYawOut         = 0.0;
        _collAirspeedToYawOut = 0.0;
    };
};

if (!(_heli getVariable "fza_ah64_fmcCollOn")) then {
    _altHoldCollOut = 0.0;
};

//PRIMARY HYDRAULICS: the FMC/SCAS operate THROUGH the primary hydraulic system. If primary
//hydraulics are lost, the FMC/SCAS can no longer function AT ALL - every augmentation output
//(SAS all axes + the FMC holds incl. collective/altitude) drops to zero, leaving only the raw
//mechanical control path (which still has its always-on actuator lag). Applies to all axes.
private _priHydLost = (_heli getHitPointDamage "hit_hyd_pripump") >= SYS_HYD_DMG_THRESH;
if (_priHydLost) then {
    _SASPitchOutput     = 0.0;
    _SASRollOutput      = 0.0;
    _SASYawOutput       = 0.0;

    _attHoldCycPitchOut = 0.0;
    _attHoldCycRollOut  = 0.0;
    _hdgHoldPedalYawOut = 0.0;
    _altHoldCollOut     = 0.0;
};

//Control mixing outputs
_heli setVariable ["fza_sfmplus_fmcCollectiveToPitch",         0.0];//_collToPitchOut];
_heli setVariable ["fza_sfmplus_fmcYawToPitch",                0.0];//_yawToPitchOut];
_heli setVariable ["fza_sfmplus_fmcCollectiveToRoll",          0.0];//_collToRollOut];
_heli setVariable ["fza_sfmplus_fmcYawToRoll",                 0.0];//_yawToRollOut];
_heli setVariable ["fza_sfmplus_fmcCollectiveToYaw",           0.0];//_collToYawOut];
_heli setVariable ["fza_sfmplus_fmcCollectiveAirspeedToYaw",   0.0];//_collAirspeedToYawOut];
//Flight Management Computer (FMC) outputs
_heli setVariable ["fza_sfmplus_fmcAttHoldCycPitchOut",        _attHoldCycPitchOut];
_heli setVariable ["fza_sfmplus_fmcAttHoldCycRollOut",         _attHoldCycRollOut];
_heli setVariable ["fza_sfmplus_fmcHdgHoldPedalYawOut",        _hdgHoldPedalYawOut];
_heli setVariable ["fza_sfmplus_fmcAltHoldCollOut",            _altHoldCollOut];
//Stability Augmentation System
_heli setVariable ["fza_sfmplus_fmcSasPitchOut",               _SASPitchOutput];
_heli setVariable ["fza_sfmplus_fmcSasRollOut",                _SASRollOutput];
_heli setVariable ["fza_sfmplus_fmcSasYawOut",                 _SASYawOutput];

//systemChat format ["%1 -- %2 -- %3 -- %4 -- %5", _collToPitchOut toFixed 2, _yawToPitchOut toFixed 2, _collToRollOut toFixed 2, _yawToRollOut toFixed 2, _collToYawOut toFixed 2];
