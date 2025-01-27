
params ["_heli"];

[_heli, 0, [ 1.2, 4.24,-1.9], 1.35, -38, 0.31] call fza_sfmplus_fnc_wheel;
[_heli, 1, [-1.2, 4.24,-1.9], 1.35, -38, 0.31] call fza_sfmplus_fnc_wheel;
[_heli, 2, [ 0.0,-6.28,-2.4], 1.20, 300, 0.16] call fza_sfmplus_fnc_wheel;

/*
([_heli, [ 1.1,  3.13, -2.72], 0.31] call fza_sfmplus_fnc_wheel)
    params ["_wheel1HeightAboveObj"];
([_heli, [-1.1,  3.13, -2.72], 0.31] call fza_sfmplus_fnc_wheel)
    params ["_wheel2HeightAboveObj"];
([_heli, [ 0.0, -7.38, -2.84], 0.16] call fza_sfmplus_fnc_wheel)
    params ["_wheel3HeightAboveObj"];


private _contactPointAverage = [
    ((_wheel1HeightAboveObj select 0) + (_wheel2HeightAboveObj select 0) + (_wheel3HeightAboveObj select 0)) / 3
   ,((_wheel1HeightAboveObj select 1) + (_wheel2HeightAboveObj select 1) + (_wheel3HeightAboveObj select 1)) / 3
   ,((_wheel1HeightAboveObj select 2) + (_wheel2HeightAboveObj select 2) + (_wheel3HeightAboveObj select 2)) / 3
];

systemChat format ["_wheel1HeightAboveObj = %1", _wheel1HeightAboveObj];
systemChat format ["_wheel2HeightAboveObj = %1", _wheel2HeightAboveObj];
systemChat format ["_wheel3HeightAboveObj = %1", _wheel3HeightAboveObj];
*/
//if ((_heliPos vectorDistance _lastPos) > 0.1) then {
    //_heli setPosATL [_heliPos select 0, _heliPos select 1, 0.5];
    //_heli setVelocity [0.0, 0.0, 0.0];
    //_lastPos = getPosATL _heli;
//};

//_heli setVariable ["fza_sfmplus_lastPos", _lastPos];