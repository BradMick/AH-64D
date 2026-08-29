params["_name", "_value"];
if !(vehicle player isKindOf "fza_ah64base") exitWith {};
private _heli = vehicle player;

private _heliCyclicForwardOut   = _heli getVariable "bmkhs_heliCyclicForwardOut";
private _heliCyclicBackOut      = _heli getVariable "bmkhs_heliCyclicBackwardOut";
private _heliCyclicLeftOut      = _heli getVariable "bmkhs_heliCyclicLeftOut";
private _heliCyclicRightOut     = _heli getVariable "bmkhs_heliCyclicRightOut";
private _heliRudderLeftOut      = _heli getVariable "bmkhs_heliRudderLeftOut";
private _heliRudderRightOut     = _heli getVariable "bmkhs_heliRudderRightOut";
private _heliCollectiveRaiseOut = _heli getVariable "bmkhs_heliCollectiveRaiseOut";
private _heliCollectiveLowerOut = _heli getVariable "bmkhs_heliCollectiveLowerOut";

//When button pressed
switch (_name) do {
    case "fza_ah64_cyclicForward": {
        private _heliCyclicForwardDevices = [];
        {
            if ("JOYSTICK_AXIS" in (_x select 0 select 1)) then {
                _heliCyclicForwardDevices pushBackUnique _x;
            };
        } forEach actionKeysEx "fza_ah64_cyclicForward";

        _heliCyclicForwardOut = if (_heliCyclicForwardDevices isEqualTo []) then { 1.0; } else {1.0 / (count _heliCyclicForwardDevices); };
        _heliCyclicForwardOut = linearConversion [0.0, _heliCyclicForwardOut, _value, 0.0, 1.0, true];
        _heli setVariable ["bmkhs_heliCyclicForwardOut", _heliCyclicForwardOut];
    };
    case "fza_ah64_cyclicBackward": {
        private _heliCyclicBackDevices = [];
        {
            if ("JOYSTICK_AXIS" in (_x select 0 select 1)) then {
                _heliCyclicBackDevices pushBackUnique _x;
            };
        } forEach actionKeysEx "fza_ah64_cyclicBackward";

        _heliCyclicBackOut = if (_heliCyclicBackDevices isEqualTo []) then { 1.0; } else {1.0 / (count _heliCyclicBackDevices); };
        _heliCyclicBackOut = linearConversion [0.0, _heliCyclicBackOut, _value, 0.0, 1.0, true];
        _heli setVariable ["bmkhs_heliCyclicBackwardOut", _heliCyclicBackOut];
    };
    case "fza_ah64_cyclicLeft": {
        private _heliCyclicLeftDevices = [];
        {
            if ("JOYSTICK_AXIS" in (_x select 0 select 1)) then {
                _heliCyclicLeftDevices pushBackUnique _x;
            };
        } forEach actionKeysEx "fza_ah64_cyclicLeft";

        _heliCyclicLeftOut = if (_heliCyclicLeftDevices isEqualTo [])  then { 1.0; } else {1.0 / (count _heliCyclicLeftDevices); };
        _heliCyclicLeftOut = linearConversion [0.0, _heliCyclicLeftOut, _value, 0.0, 1.0, true];
        _heli setVariable ["bmkhs_heliCyclicLeftOut",  _heliCyclicLeftOut];
    };
    case "fza_ah64_cyclicRight": {
        private _heliCyclicRightDevices = [];
        {
            if ("JOYSTICK_AXIS" in (_x select 0 select 1)) then {
                _heliCyclicRightDevices pushBackUnique _x;
            };
        } forEach actionKeysEx "fza_ah64_cyclicRight";

        private _heliCyclicRightOut = if (_heliCyclicRightDevices isEqualTo []) then { 1.0; } else {1.0 / (count _heliCyclicRightDevices); };
        _heliCyclicRightOut         = linearConversion [0.0, _heliCyclicRightOut, _value, 0.0, 1.0, true];
        _heli setVariable ["bmkhs_heliCyclicRightOut", _heliCyclicRightOut];
    };
    case "fza_ah64_pedalLeft": {
        private _heliRudderLeftDevices = [];
        {
            if ("JOYSTICK_AXIS" in (_x select 0 select 1)) then {
                _heliRudderLeftDevices pushBackUnique _x;
            };
        } forEach actionKeysEx "fza_ah64_pedalLeft";

        _heliRudderLeftOut = if (_heliRudderLeftDevices isEqualTo []) then { 1.0; } else {1.0 / (count _heliRudderLeftDevices); };
        _heliRudderLeftOut = linearConversion [0.0, _heliRudderLeftOut, _value, 0.0, 1.0, true];
        _heli setVariable ["bmkhs_heliRudderLeftOut",  _heliRudderLeftOut];
    };
    case "fza_ah64_pedalRight": {
        private _heliRudderRightDevices = [];
        {
            if ("JOYSTICK_AXIS" in (_x select 0 select 1)) then {
                _heliRudderRightDevices pushBackUnique _x;
            };
        } forEach actionKeysEx "fza_ah64_pedalRight";

        _heliRudderRightOut = if (_heliRudderRightDevices isEqualTo [])  then { 1.0; } else {1.0 / (count _heliRudderRightDevices); };
        _heliRudderRightOut = linearConversion [0.0, _heliRudderRightOut, _value, 0.0, 1.0, true];
        _heli setVariable ["bmkhs_heliRudderRightOut", _heliRudderRightOut];
    };
    case "fza_ah64_collectiveUp": {
        bmkhs_keyboardCollective = false;

        private _heliCollectiveRaiseDevices = [];
        {
            if ("JOYSTICK_AXIS" in (_x select 0 select 1)) then {
                _heliCollectiveRaiseDevices pushBackUnique _x;
            };
        } forEach actionKeysEx "fza_ah64_collectiveUp";

        _heliCollectiveRaiseOut = if (_heliCollectiveRaiseDevices isEqualTo []) then { 1.0; } else {1.0 / (count _heliCollectiveRaiseDevices); };
        _heliCollectiveRaiseOut = linearConversion [0.0, _heliCollectiveRaiseOut, _value, 0.0, 1.0, true];

        _heli setVariable ["bmkhs_heliCollectiveRaiseOut", _heliCollectiveRaiseOut];
    };
    case "fza_ah64_collectiveDn": {
        bmkhs_keyboardCollective = false;

        private _heliCollectiveLowerDevices = [];
        {
            if ("JOYSTICK_AXIS" in (_x select 0 select 1)) then {
                _heliCollectiveLowerDevices pushBackUnique _x;
            };
        } forEach actionKeysEx "fza_ah64_collectiveDn";

        _heliCollectiveLowerOut = if (_heliCollectiveLowerDevices isEqualTo []) then { 1.0; } else {1.0 / (count _heliCollectiveLowerDevices); };
        _heliCollectiveLowerOut = linearConversion [0.0, _heliCollectiveLowerOut, _value, 0.0, 1.0, true];

        _heli setVariable ["bmkhs_heliCollectiveLowerOut", _heliCollectiveLowerOut];
    };
};
