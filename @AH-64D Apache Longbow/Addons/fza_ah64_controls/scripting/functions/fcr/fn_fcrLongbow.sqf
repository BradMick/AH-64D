/* ----------------------------------------------------------------------------
Function: fza_fnc_fcrLongbow

Description:
    Fire control Radar script that takes target from sens radar and adds it to 
    fza_ah64_targetlist & fza_ah64_fcrlist

Parameters:

Returns:
    Nothing
    
Examples:
    [_heli] spawn fza_fnc_fcrLongbow;

Author:
    Unknown
---------------------------------------------------------------------------- */
#define AGMODE_GND 0
#define AGMODE_AIR 1
#define AGMODE_FNI 2 //FCR Not Installed (FNI)

if (!(isNil "fza_ah64_nofcr")) exitwith {};
_heli = objNull;
_targetArray = [];
_detectchance = 0.00834;
_adaunit = false;
_datalinkArray = [];

while {
    (time > -1)
}
do {
    waituntil {
        (vehicle player) iskindof "fza_ah64base"
    };

    _heli = vehicle player;

    waitUntil {
        ((driver(vehicle player) == player || gunner(vehicle player) == player) && isengineon(vehicle player))
    };

    if (isVehicleRadarOn _heli && (typeOf _heli == "fza_ah64d_b2e") && !("fza_ah64_fcr_fail" in (_heli magazinesturret[-1]))) then {
        //add targets to master list
        //_targetArray = (list _radsweep);
        //_targetArray = vehicles - allDead;

        _datalinkArray = listRemoteTargets west;
        {
            _targetArray pushback(_x select 0);
        }
        foreach _datalinkArray;

        {
            if (alive _x && !(_x in fza_ah64_targetlist)) then {
                _rem = false;
                _i = _x;
                _adaunit = false; {
                    if (_i iskindof _x) then {
                        _adaunit = true;
                    };
                }
                foreach fza_ah64_ada_units;

                //In theory, this should hide the player helicopter...
                if (_i == _heli) then {
                    _targetArray = _targetArray - [_i];
                    _rem = true;    
                };

                if (_i distance _heli > 10000 || (_i iskindof "man") || !(alive _i)) then {
                    _targetArray = _targetArray - [_i];
                    _rem = true;
                };

                if ((_heli getVariable "fza_ah64_agmode" == AGMODE_GND || _heli getVariable "fza_ah64_agmode" == AGMODE_FNI) && (getpos _i select 2 >= 10)) then {
                    _targetArray = _targetArray - [_i];
                    _rem = true;
                };

                if (_heli getVariable "fza_ah64_agmode" == AGMODE_AIR && ((getpos _i select 2) < 10)) then {
                    _targetArray = _targetArray - [_i];
                    _rem = true;
                };

                //If what is detected isn't any of the items below, remove it from the list...
                if (!(_i isKindOf "helicopter" || _i isKindOf "plane" || _i isKindOf "car" || _i isKindOf "tank" || _i isKindOf "ship" || _i isKindOf "StaticCannon" || _adaunit)) then {
                    _targetArray = _targetArray - [_i];
                    _rem = true;
                };

                if (!(_rem)) then {
                    _randchance = random 100;
                    _detectchance = 0.00050;

                    if (_adaunit) then {
                        _detectchance = 0.00017;
                    };

                    if (((_i distance _heli) * _detectchance) > _randchance) then {
                        _targetArray = _targetArray - [_i];
                    };
                    //if((terrainIntersectasl [getposasl _heli, [(getPosASL _i select 0),(getPosASL _i select 1),(getPosASL _i select 2)+1]]) || (lineIntersects [getposasl _heli, getPosASL _i, _heli, _i])) then {_targetArray = _targetArray - [_i];};
                };
                sleep 0.03;
            };
        }
        foreach _targetArray;

        {
            if (!(_x in fza_ah64_targetlist)) then {
                fza_ah64_targetlist = fza_ah64_targetlist + [_x];
                _heli reveal _x;
            };
        }
        foreach _targetArray; {
            if (!(_x in fza_ah64_fcrlist)) then {
                fza_ah64_fcrlist = fza_ah64_fcrlist + [_x];
            };
        }
        foreach _targetArray;
    };
    sleep 2;
};

/****

[] spawn  
{ 
 runLoop = true; 
 while {runLoop} do  
 { 
    _targetList     = [];
    _targetListSize = 0;

    _targetList = (listRemoteTargets west select {_x # 1 > 6 && _x # 0 != vehicle player}) apply {_x # 0};
    _targetListSize = count _targetList;

    hintSilent format [ "Array Size = %1\n
                        Item Name = %2\n
                        Item Name = %3\n
                        Item Name = %4\n",
                        _targetListSize, _targetList select 0, _targetList select 1, _targetList select 2];

    sleep 0.03; 
 } 
};

[] spawn  
{ 
 runLoop = true; 
 while {runLoop} do  
 { 
    _targetList     = [];
    _targetListSize = 0;

    _dataLinkArray = listRemoteTargets west;
    {
        if ((_x select 1) > 6) then
        {
            _targetList pushBack(_x);
        }
    }
    foreach _dataLinkArray;

    _targetListSize = count _targetList;

    hintSilent format [ "Array Size = %1\n
                        Item Name = %2\n
                        Item Name = %3\n
                        Item Name = %4\n
                        Test = %5",
                        _targetListSize, _targetList select 0, _targetList select 1, _targetList select 2, _targetList select 0 select 1];


    _targetList deleteRange [0, _targetListSize];

    sleep 0.03; 
 } 
};
****/