params ["_heli"];

if (_heli getVariable "bmkhs_altHoldActive" || _heli getVariable "bmkhs_attHoldActive") then {
    [_heli] spawn fza_audio_fnc_flightTone;
};

//De-activate attitude hold and set the reference back to 0
[_heli, "bmkhs_attHoldActive", false] call fza_fnc_updateNetworkGlobal;
[_heli, "bmkhs_attHoldDesiredVel", [0.0, 0.0]] call fza_fnc_updateNetworkGlobal;
[_heli, "bmkhs_attHoldDesiredAtt", [0.0, 0.0]] call fza_fnc_updateNetworkGlobal;

//De-activate altitude hold and set the reference back to 0
[_heli, "bmkhs_altHoldActive", false] call fza_fnc_updateNetworkGlobal;
[_heli, "bmkhs_altHoldDesiredAlt", 0.0] call fza_fnc_updateNetworkGlobal;
