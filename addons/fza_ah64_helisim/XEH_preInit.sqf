//HeliSim raises events; the aircraft decides what they mean. Audio and cockpit
//animation are mod business, not Core's.

//How fast a CLICKED power lever travels. A multiplier on the animation's own animPeriod of
//1 second, so this is the whole sweep - slow enough that the rotor follows the lever rather
//than surging with it. An axis-bound lever ignores this and tracks the player's hand.
#define PWRLVR_CLICK_SPEED 0.125

bmkhs_notifyHandler = {
    params ["_heli", "_event", ["_data", []]];

    switch (_event) do {
        case "holdModeDisengaged": { [_heli] spawn fza_audio_fnc_flightTone; };

        case "apuStateChanged": {
            private _on = _heli getVariable ["bmkhs_apuOn", false];
            _heli setObjectTexture ["in_lt_apu", ["", "\fza_ah64_model\tex\in\pushbut.paa"] select _on];
        };

        //THE CONTROL DRIVES THE ANIMATION. A control publishes where it IS - the position's
        //value, 0 to 1 - and that value is the animation phase. Nothing here restates what
        //a position is worth; move a detent in config and the animation follows it.
        case "controlMoved": {
            _data params ["_name", "_idx", "_prevIdx", "_value", "_posName"];
            switch (_name) do {
                //Only the sweep to FLY is deliberately slow, so the rotor follows the lever
                //rather than surging with it. Everything else moves at the animation's rate.
                case "eng1PwrLvr";
                case "eng2PwrLvr": {
                    private _anim = ["fza_ah64_powerLever1", "fza_ah64_powerLever2"]
                                        select (_name == "eng2PwrLvr");
                    if (_value == 1.0) then {
                        [_heli, _anim, _value, PWRLVR_CLICK_SPEED] call fza_fnc_animSetValue;
                    } else {
                        [_heli, _anim, _value] call fza_fnc_animSetValue;
                    };
                };

                //Three positions over a 0..1 source: Oride at 0, Off centred, Start at 1.
                //The switch value is -1/0/+1, so it maps rather than passing through.
                case "eng1StartSw": { _heli animateSource ["plt_eng1_start", (_value + 1) / 2, 0.2]; };
                case "eng2StartSw": { _heli animateSource ["plt_eng2_start", (_value + 1) / 2, 0.2]; };

                //Off/brake/lock is 0/1/2 over a 0..1 source.
                case "rotorBrake": {
                    [_heli, "fza_ah64_rtrbrake", _value / 2] call fza_fnc_animSetValue;
                };
            };
        };

        //For an airframe that declares no Controls block - the interact functions do the
        //work themselves and this is the only thing animating the levers. Where controls
        //ARE declared, controlMoved has already handled it and this never fires.
        case "powerLeverMoved": {
            _data params ["_engNum", "_value"];
            private _anim = format ["fza_ah64_powerLever%1", _engNum + 1];
            if (_value == 1.0) then {
                [_heli, _anim, _value, PWRLVR_CLICK_SPEED] call fza_fnc_animSetValue;
            } else {
                [_heli, _anim, _value] call fza_fnc_animSetValue;
            };
        };

        //Superseded by controlMoved, which carries WHICH position was selected - this one
        //only ever knew the engine number, so it could not animate the right way.
        case "startSwitchPressed": {};
    };
};

//Every airframe any installed pack drives. A pack declares bmkhsBaseClass in its own
//CfgPatches entry and touches no SQF - and two packs both get scheduled, rather than
//whichever loaded first winning.
bmkhs_packBaseClasses = [];
{
    private _cls = getText (_x >> "bmkhsBaseClass");
    if (_cls != "" && {!(_cls in bmkhs_packBaseClasses)}) then {
        bmkhs_packBaseClasses pushBack _cls;
    };
} forEach ("isClass _x" configClasses (configFile >> "CfgPatches"));

//The pack drives Core. Nothing else calls into HeliSim, so a second airframe ships its
//own copy of this and needs no cockpit addon to schedule anything for it.
//
//Every LOCAL aircraft of this type, not just the one the player is sitting in - an AI
//Apache burns fuel and overtorques its gearboxes the same as a crewed one, and the solve
//guards on locality itself so multiplayer stays correct.
fza_ah64_helisim_frameHandler = addMissionEventHandler ["EachFrame", {
    {
        //Core's own init flag, not a cockpit addon's - the pack should not need one.
        if (alive _x && {_x getVariable ["bmkhs_initialised", false]}) then {
            [_x] call fza_ah64_helisim_fnc_perFrame;
        };
    } forEach (vehicles select {
        private _veh = _x;
        local _veh && {bmkhs_packBaseClasses findIf {_veh isKindOf _x} > -1}
    });
}];
