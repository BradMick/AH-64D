params["_name", "_value"];
if !(vehicle player isKindOf "fza_ah64base") exitWith {};
private _heli = vehicle player;



if (_value) then {
    //When button pressed
    switch (_name) do {
        case "fza_ah64_kbCollectiveUp": {
            bmkhs_keyboardCollective = true;
            _heli setVariable ["bmkhs_kbHeliCollectiveRaiseOut", 1.0];
            //systemChat format ["increasing collective!"];
        };
        case "fza_ah64_kbCollectiveDn": {
            bmkhs_keyboardCollective = true;
            _heli setVariable ["bmkhs_kbHeliCollectiveLowerOut", 1.0];
            //systemChat format ["decreasing collective!"];
        };
    };
};

if !(_value) then {
    //When button releassed
    switch (_name) do {
        case "fza_ah64_kbCollectiveUp": {
            bmkhs_keyboardCollective = true;
            _heli setVariable ["bmkhs_kbHeliCollectiveRaiseOut", 0.0];
            //systemChat format ["no longer increasing collective!"];
        };
        case "fza_ah64_kbCollectiveDn": {
            bmkhs_keyboardCollective = true;
            _heli setVariable ["bmkhs_kbHeliCollectiveLowerOut", 0.0];
            //systemChat format ["no longer decreasing collective!"];
        };
    };
};
