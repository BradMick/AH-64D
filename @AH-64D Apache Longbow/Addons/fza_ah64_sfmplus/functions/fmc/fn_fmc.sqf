params ["_heli", "_deltaTime"];

([_heli, _deltaTime] call fza_sfmplus_fnc_fmcAttitudeHold)
    params ["_attHoldCycPitchOut", "_attHoldCycRollOut"];

//systemChat format ["Att Hold Active = %1 -- Sub-Mode = %2", _heli getVariable "fza_ah64_attHoldActive", _heli getVariable "fza_ah64_attHoldSubMode"];
//systemChat format ["Pitch Out = %1 -- Roll Out = %2", _attHoldCycPitchOut toFixed 2, _attHoldCycRollOut toFixed 2];

private _hdgHoldPedalYawOut = 0.0;

private _altHoldCollOut = [_heli, _deltaTime] call fza_sfmplus_fnc_fmcAltitudeHold;

[_attHoldCycPitchOut, _attHoldCycRollOut, _hdgHoldPedalYawOut, _altHoldCollOut];