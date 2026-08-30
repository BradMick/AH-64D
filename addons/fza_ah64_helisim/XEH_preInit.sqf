//HeliSim raises events; the aircraft decides what they mean. Audio is mod
//business, not Core's.
bmkhs_notifyHandler = {
    params ["_heli", "_event"];

    switch (_event) do {
        case "holdModeDisengaged": { [_heli] spawn fza_audio_fnc_flightTone; };
    };
};
