#include "\fza_ah64_controls\headers\script_common.hpp"
#include "\fza_ah64_controls\headers\selections.h"
params ["_heli", "_system", "_control"];

switch(_control) do {
	case "r1": {
		[_heli, "OUT"] call fza_fnc_mpdHandleZoom;
	};
	case "r2": {
		[_heli, "IN"] call fza_fnc_mpdHandleZoom;
	};
	case "r4": {
		_heli spawn fza_fnc_aseHandleRfcontrol;
	};
	case "r5": {
		_heli setVariable ["fza_ah64_rfjstate", (_heli getVariable "fza_ah64_rfjstate") + 1, true];
		if (_heli getVariable "fza_ah64_rfjstate" == 2) then {
			_heli setVariable ["fza_ah64_rfjstate", 0, true];
		};
	};
	case "r6": {
		_heli setVariable ["fza_ah64_rfJamOn", false, true];
	};
	case "l1": {
		switch (_heli getVariable "fza_ah64_aseautopage") do {
			case 0 : { _heli setVariable ["fza_ah64_aseautopage", 1] };
			case 1 : { _heli setVariable ["fza_ah64_aseautopage", 2] };
			case 2 : { _heli setVariable ["fza_ah64_aseautopage", 0] };
		};
	};
	case "l4": {
		_heli spawn fza_fnc_aseHandleIrcontrol;
	};
	case "l5": {
		_heli setVariable ["fza_ah64_irjstate", (_heli getVariable "fza_ah64_irjstate") + 1, true];
		if (_heli getVariable "fza_ah64_irjstate" == 2) then {
			_heli setVariable ["fza_ah64_irjstate", 0, true];
		};
	};
	case "l6": {
		_heli setVariable ["fza_ah64_irJamOn", false, true];
	};
	case "tsd": {
		[_heli, 1, "tsd"] call fza_fnc_mpdSetDisplay;
	};
	case "m": {
		[_heli, 1, "dms"] call fza_fnc_mpdSetDisplay;
	};
	case "fcr": {
		[_heli, 1, "fcr"] call fza_fnc_mpdSetDisplay;
	};
};