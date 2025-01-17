#include "\fza_ah64_controls\headers\script_common.hpp"
#include "\fza_ah64_controls\headers\selections.h"
params ["_heli", "_system", "_control"];

if(_heli getVariable "fza_ah64_tsdmode" == "nav") then {
	switch (_control) do {
		case "l1": {
			[_heli] execvm "\fza_ah64_controls\scripting\nav\waypointadd.sqf";
		};
		case "l2": {
			[_heli] execvm "\fza_ah64_controls\scripting\nav\waypointclear.sqf";
		};
		case "l3": {
			[_heli] execvm "\fza_ah64_controls\scripting\nav\waypointsave.sqf";
		};
		case "l6": {
			[_heli, true] call fza_fnc_navigationWaypointCycle;
		};
		case "b4": {
			//RMPD B4 BTN RTE
			if (count waypoints group(driver _heli) > 1) then {
				_waypoints = [_heli getVariable "fza_ah64_waypointdata" select 0];
				{
					if (_x select 1 > 0) then {
						_waypoints pushBack waypointPosition _x;
					};
				} foreach(waypoints group(driver _heli));
				_heli setVariable ["fza_ah64_waypointdata", _waypoints, true];
				_heli setVariable ["fza_ah64_curwpnum", 0, true];
			};
		};
	};
};
if(_heli getVariable "fza_ah64_tsdmode" == "atk") then {
	switch (_control) do {
		case "l1": {
			[_heli, _heli getVariable "fza_ah64_pfz_count"] spawn fza_fnc_pfzCreate;
		};
		case "l3": {
			[_heli] spawn fza_fnc_pfzSend;
		};
		case "l4": {
			[_heli] spawn fza_fnc_pfzReceive;
		};
	};
};
switch (_control) do {
	case "b1": {
		_heli setVariable ["fza_ah64_tsdmode", ["atk", "nav"] select (_heli getVariable "fza_ah64_tsdmode" == "atk")];
	};
	case "l5": {
		[_heli] call fza_fnc_targetingPFZCycle;
	};
	case "b3": {
		[_heli] spawn fza_fnc_tsdMap;
	};
	case "r1": {
		[_heli, "OUT"] call fza_fnc_mpdHandleZoom;
	};
	case "r2": {
		[_heli, "IN"] call fza_fnc_mpdHandleZoom;
	};
	case "r3": {
		[_heli] spawn fza_fnc_tsdFilter;
	};
	case "t2": {
		[_heli, 1, "ase"] call fza_fnc_mpdSetDisplay;
	};
	case "fcr": {
		[_heli, 1, "fcr"] call fza_fnc_mpdSetDisplay;
	};
	case "m": {
		[_heli, 1, "dms"] call fza_fnc_mpdSetDisplay;
	};
};
