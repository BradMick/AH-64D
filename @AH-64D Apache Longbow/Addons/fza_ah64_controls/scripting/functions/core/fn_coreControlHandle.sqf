#include "\fza_ah64_controls\headers\systemConstants.h"

params["_name", "_value"];

if !(vehicle player isKindOf "fza_ah64base") exitWith {};
private _heli = vehicle player;

if (_value) then {
	//When button pressed
	switch (_name) do {
		case "fza_ah64_crosshairInteract": {
			private _controls = [_heli] call fza_fnc_coreGetObjectsLookedAt;
			if (_controls isEqualTo []) exitWith {};
			
			//If there are multiple controls in the range, make sure we use the closest one
			if(count _controls > 1) then {
				_controls = [_controls, [], {_x # 6}, "ASCEND"] call BIS_fnc_sortBy;
			};
			
			(_controls # 0) params ["", "", "_system", "_control"];

			[_heli, _system, _control] call fza_fnc_coreCockpitInteract;
		};
		case "fza_ah64_laserDesig": {
			[_heli] call fza_fnc_laserArm;
		};
		case "fza_ah64_sightSelectHMD": {
			[_heli, SIGHT_HMD] call fza_fnc_targetingSetSightSelect;
		};
		case "fza_ah64_sightSelectTADS": {
			[_heli, SIGHT_TADS] call fza_fnc_targetingSetSightSelect;
		};
		case "fza_ah64_sightSelectFXD": {
			[_heli, SIGHT_FXD] call fza_fnc_targetingSetSightSelect;
		};
		case "fza_ah64_sightSelectFCR": {
			[_heli, SIGHT_FCR] call fza_fnc_targetingSetSightSelect;
		};
		case "fza_ah64_fcrModeGTM": {
			_heli setVariable ["fza_ah64_agmode", FCR_MODE_GND, true];
		};
		case "fza_ah64_fcrModeATM": {
			_heli setVariable ["fza_ah64_agmode", FCR_MODE_AIR, true];
		};
		case "fza_ah64_symbologySelectUp": {
			switch (_heli getVariable "fza_ah64_hmdfsmode") do {
				case "trans": {
					_heli setVariable ["fza_ah64_hmdfsmode", "cruise", true];
				};
				default {
					_heli setVariable ["fza_ah64_hmdfsmode", "trans", true];
				};
			};
		};
		case "fza_ah64_symbologySelectDown": {
			switch (_heli getVariable "fza_ah64_hmdfsmode") do {
				case "hover": {
					_heli setVariable ["fza_ah64_bobpos", [(getposasl _heli select 0), (getposasl _heli select 1)], true];
					_heli setVariable ["fza_ah64_bobhdg", getdir _heli, true];
					_heli setVariable ["fza_ah64_hmdfsmode", "bobup", true];
				};
				default {
					_heli setVariable ["fza_ah64_hmdfsmode", "hover", true];
				};
			};
		};
		case "fza_ah64_symbologySelectPress": {
			[_heli, 0, "flt"] call fza_fnc_mpdSetDisplay;
		};
		case "fza_ah64_fcrSingleScan": {
			player action ["ActiveSensorsOn", vehicle player];
			if (_heli getVariable "fza_ah64_agmode" == FCR_MODE_AIR) then {
				["fza_ah64_disableRadar", { player action ["ActiveSensorsOff", vehicle player]; }, 8, "seconds"] call BIS_fnc_runLater;
			} else {
				["fza_ah64_disableRadar", { player action ["ActiveSensorsOff", vehicle player]; }, 4, "seconds"] call BIS_fnc_runLater;
			};
		};
		case "fza_ah64_targetStoreUpdate": {

			private _position = screenToWorld [0.5, 0.5];
			
			if (_position distance (getPos _heli) > 7000) exitWith {};

			if (count (_heli getVariable "fza_ah64_waypointdata") > 30) exitwith {
				_heli vehiclechat "Waypoint limits reached.";
			};

			_heli setVariable ["fza_ah64_waypointdata", (_heli getVariable "fza_ah64_waypointdata") + [[_position # 0, _position # 1, 0]], true];
		};
		case "fza_ah64_waypointIncrease": {
			[_heli, true] call fza_fnc_navigationWaypointCycle;
		};
		case "fza_ah64_waypointDecrease": {
			[_heli, false] call fza_fnc_navigationWaypointCycle;
		};
		case "fza_ah64_laserCycle": {
			[_heli] call fza_fnc_laserCycle;
		};
		case "fza_ah64_missileAdvance": {
			if (_heli getVariable "fza_ah64_was" == WAS_WEAPON_MSL) then {
				[_heli] call fza_fnc_weaponMissileCycle
			};
		};
		case "fza_ah64_wasGun": {
			if (_heli getVariable "fza_ah64_was" == WAS_WEAPON_GUN) then {
				[_heli, WAS_WEAPON_NONE] call fza_fnc_weaponActionSwitch;
			} else {
				[_heli, WAS_WEAPON_GUN] call fza_fnc_weaponActionSwitch;
			};
		};
		case "fza_ah64_wasRkt": {
			if (_heli getVariable "fza_ah64_was" == WAS_WEAPON_RKT) then {
				[_heli, WAS_WEAPON_NONE] call fza_fnc_weaponActionSwitch;
			} else {
				[_heli, WAS_WEAPON_RKT] call fza_fnc_weaponActionSwitch;
			};
		};
		case "fza_ah64_wasMsl": {
			if (_heli getVariable "fza_ah64_was" == WAS_WEAPON_MSL) then {
				[_heli, WAS_WEAPON_NONE] call fza_fnc_weaponActionSwitch;
			} else {
				[_heli, WAS_WEAPON_MSL] call fza_fnc_weaponActionSwitch;
			};
		};
		case "fza_ah64_masterSafe": {
			_heli setVariable ["fza_ah64_armed", !(_heli getVariable "fza_ah64_armed"), true];
		};
		case "SwitchWeaponGrp1";
		case "SwitchWeaponGrp2";
		case "SwitchWeaponGrp3";
		case "SwitchWeaponGrp4";
		case "nextWeapon";
		case "prevWeapon": {
			["fza_ah64_weaponUpdate", {[vehicle player] call fza_fnc_weaponUpdateSelected}, 1, "frames"] call BIS_fnc_runLater;
		};
		case "launchCM": {
			if (player == gunner _heli) then {
				[_heli, "fza_CMFlareLauncher", [-1]] call BIS_fnc_fire;
			}
		};
	};
};

if !(_value) then {
	//When button releassed
	switch (_name) do {
		case "fza_ah64_laserDesig": {
			[_heli] call fza_fnc_laserDisarm;
		};
	};
};