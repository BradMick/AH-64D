//HeliSim raises events; the aircraft decides what they mean. Audio and cockpit
//indication are mod business, not Core's.
bmkhs_notifyHandler = {
    params ["_heli", "_event"];

    switch (_event) do {
        case "holdModeDisengaged": { [_heli] spawn fza_audio_fnc_flightTone; };
        case "apuStateChanged": {
            private _on = _heli getVariable ["bmkhs_apuOn", false];
            _heli setObjectTexture ["in_lt_apu", ["", "\fza_ah64_model\tex\in\pushbut.paa"] select _on];
        };
    };
};
