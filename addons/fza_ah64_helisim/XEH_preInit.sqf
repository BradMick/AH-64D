//HeliSim raises events; the aircraft decides what they mean. Audio and cockpit
//animation are mod business, not Core's.
bmkhs_notifyHandler = {
    params ["_heli", "_event", ["_data", []]];

    switch (_event) do {
        case "holdModeDisengaged": { [_heli] spawn fza_audio_fnc_flightTone; };

        case "apuStateChanged": {
            private _on = _heli getVariable ["bmkhs_apuOn", false];
            _heli setObjectTexture ["in_lt_apu", ["", "\fza_ah64_model\tex\in\pushbut.paa"] select _on];
        };

        case "powerLeverMoved": {
            _data params ["_engNum", "_value"];
            private _anim = format ["fza_ah64_powerLever%1", _engNum + 1];
            if (_value == 1.0) then {
                //Slow enough that the rotor follows the lever rather than surging with it.
                [_heli, _anim, 1, 0.125] call fza_fnc_animSetValue;
            } else {
                [_heli, _anim, _value] call fza_fnc_animSetValue;
            };
        };

        case "startSwitchPressed": {
            _data params ["_engNum"];
            _heli animateSource [(["plt_eng1_start", "plt_eng2_start"] select _engNum), 0.5, 0.2];
        };
    };
};

//The pack drives Core. Nothing else calls into HeliSim, so a second airframe ships its
//own copy of this and needs no cockpit addon to schedule anything for it.
//
//Every LOCAL aircraft of this type, not just the one the player is sitting in - an AI
//Apache burns fuel and overtorques its gearboxes the same as a crewed one, and the solve
//guards on locality itself so multiplayer stays correct.
fza_ah64_helisim_frameHandler = addMissionEventHandler ["EachFrame", {
    {
        if (alive _x && {_x getVariable ["fza_ah64_aircraftInitialised", false]}) then {
            [_x] call fza_ah64_helisim_fnc_perFrame;
        };
    } forEach (vehicles select {local _x && {_x isKindOf "fza_ah64base"}});
}];
