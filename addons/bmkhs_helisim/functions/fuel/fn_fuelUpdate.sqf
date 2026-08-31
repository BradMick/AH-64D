/* ----------------------------------------------------------------------------
Function: bmkhs_fnc_fuelUpdate

Description:
    Updates fuel cell masses each tick. Handles independent cell draw based on
    crossfeed valve position, XFER pump logic, IAFS gravity feed, and external
    tank transfer with outer/inner pressurisation dependency.

    Crossfeed NORM:  Eng1 draws from FWD, Eng2 draws from AFT.
    Crossfeed FWD:   Both engines draw from FWD.
    Crossfeed AFT:   Both engines draw from AFT.

    APU fuel source: Always AFT cell (independent of crossfeed selection).

    External transfer (pressurised air):
      stn2 (inner L) and stn3 (inner R) transfer independently.
      stn1 (outer L) requires stn2 to be present.
      stn4 (outer R) requires stn3 to be present.

Parameters:
    _heli - The helicopter to update [Unit].

Returns:
    None

Author:
    BradMick / FZA Development Team
---------------------------------------------------------------------------- */
#include "\bmkhs_helisim\functions\fuel\fuel.hpp"
params ["_heli"];

private _deltaTime     = _heli getVariable "bmkhs_deltaTime";
if (_deltaTime <= 0) exitWith {};

private _IAFSInstalled = _heli getVariable ["bmkhs_fuelTank2Installed", false];
if (isNil "_IAFSInstalled") exitWith {};

private _maxTotFuelMass = _heli getVariable "bmkhs_maxTotFuelMass";
if (_maxTotFuelMass <= 0) exitWith {};

// If Arma fuel was changed externally (e.g. editor/trigger script), resync
// internal tank masses so subsequent simulation ticks stay consistent.
private _armaFuelFrac = fuel _heli;
private _storedTotFuelMass = _heli getVariable ["bmkhs_totFuelMass", 0];
private _storedFuelFrac = if (_maxTotFuelMass > 0) then { _storedTotFuelMass / _maxTotFuelMass } else { 0 };
if (abs (_armaFuelFrac - _storedFuelFrac) > 0.01) then {
    [_heli] call bmkhs_fnc_fuelSet;
    _maxTotFuelMass = _heli getVariable "bmkhs_maxTotFuelMass";
};

//Tank state as arrays - index 0 is tank 1. The transfer logic below still names the
//AH-64's cells, but everything uniform (read, leak, clamp, total, write-back) loops.
private _fuelTanks = _heli getVariable ["bmkhs_fuelTanks", []];
private _auxTanks  = _heli getVariable ["bmkhs_auxTanks",  []];
private _nFuel     = count _fuelTanks;
private _nAux      = count _auxTanks;

private _fuelMass = [];
private _fuelMax  = [];
private _fuelLow  = [];
for "_i" from 1 to _nFuel do {
    _fuelMass pushBack (_heli getVariable [format ["bmkhs_fuelTank%1Mass", _i], 0]);
    _fuelMax  pushBack (_heli getVariable [format ["bmkhs_fuelTank%1Max",  _i], 0]);
    _fuelLow  pushBack (_heli getVariable [format ["bmkhs_fuelTank%1Low",  _i], 0]);
};

private _auxMass = [];
private _auxMax  = [];
for "_i" from 1 to _nAux do {
    _auxMass pushBack (_heli getVariable [format ["bmkhs_auxTank%1Mass", _i], 0]);
    _auxMax  pushBack (_heli getVariable [format ["bmkhs_auxTank%1Max",  _i], 0]);
};

//AIRCRAFT-SPECIFIC FROM HERE. The transfer topology below - which tank feeds which engine,
//the XFER modes, the IAFS gravity feed and the L/R aux ganging - is the AH-64's plumbing
//expressed as code. Generalising it needs a config-declared fuel network and is the next
//step of this refactor; until then these named locals are views onto the arrays above and
//are written back into them before the generic tail runs.
#define TANK_FWD 0
#define TANK_CTR 1
#define TANK_AFT 2

private _fwdFuelMass  = _fuelMass param [TANK_FWD, 0];
private _ctrFuelMass  = _fuelMass param [TANK_CTR, 0];
private _aftFuelMass  = _fuelMass param [TANK_AFT, 0];
private _maxFwdFuelMass = _fuelMax param [TANK_FWD, 0];
private _maxCtrFuelMass = _fuelMax param [TANK_CTR, 0];
private _maxAftFuelMass = _fuelMax param [TANK_AFT, 0];

private _stn1FuelMass = _auxMass param [0, 0];
private _stn2FuelMass = _auxMass param [1, 0];
private _stn3FuelMass = _auxMass param [2, 0];
private _stn4FuelMass = _auxMass param [3, 0];
private _maxTnkFuelMass = _auxMax param [0, 0];

// Fuel flow
private _apuFF_kgs  = _heli getVariable "bmkhs_apuFF_kgs";
private _engFF      = _heli getVariable "bmkhs_engFF";
private _eng1FF_kgs = _engFF select 0;
private _eng2FF_kgs = _engFF select 1;

private _engState = _heli getVariable "bmkhs_engState";
private _eng1On   = (_engState select 0) == "ON";
private _eng2On   = (_engState select 1) == "ON";

// Crossfeed draw — source-based with starvation
private _crossfeedMode = _heli getVariable ["bmkhs_crossfeedMode", "NORM"];

private _eng1Req = if (_eng1On) then { _eng1FF_kgs * _deltaTime } else { 0 };
private _eng2Req = if (_eng2On) then { _eng2FF_kgs * _deltaTime } else { 0 };
private _apuReq  = _apuFF_kgs * _deltaTime;

private _eng1Source = switch (_crossfeedMode) do {
    case "FWD": { "FWD" };
    case "AFT": { "AFT" };
    default     { "FWD" }; // NORM
};
private _eng2Source = switch (_crossfeedMode) do {
    case "FWD": { "FWD" };
    case "AFT": { "AFT" };
    default     { "AFT" }; // NORM
};

private _fwdReq = 0;
private _aftReq = _apuReq; // APU always draws from AFT
if (_eng1Source == "FWD") then { _fwdReq = _fwdReq + _eng1Req; } else { _aftReq = _aftReq + _eng1Req; };
if (_eng2Source == "FWD") then { _fwdReq = _fwdReq + _eng2Req; } else { _aftReq = _aftReq + _eng2Req; };

private _fwdFuelBefore = _fwdFuelMass;
private _aftFuelBefore = _aftFuelMass;

private _fwdDraw = _fwdReq min _fwdFuelMass;
private _aftDraw = _aftReq min _aftFuelMass;

_fwdFuelMass = (_fwdFuelMass - _fwdDraw) max 0;
_aftFuelMass = (_aftFuelMass - _aftDraw) max 0;

private _eps = 0.0001;
private _fwdFuelAvailLastFrame = _fwdFuelBefore > _eps;
private _aftFuelAvailLastFrame = _aftFuelBefore > _eps;

// XFER pump — Table 2-6 logic
private _xferStep   = XFER_RATE_KGS * _deltaTime;
private _fwdLow     = _fwdFuelMass < (_fuelLow param [TANK_FWD, 0]);
private _aftLow     = _aftFuelMass < (_fuelLow param [TANK_AFT, 0]);
private _apuOn      = _heli getVariable ["bmkhs_apuOn", false];
private _engBleedOn = _eng1On || _eng2On;
private _airAvail   = _apuOn || _engBleedOn;
private _xferMode   = _heli getVariable ["bmkhs_xferMode", "OFF"];
private _intercellTransferActive = false;
private _intercellTransferDir = 0;

private _doFwdToAft = false;
private _doAftToFwd = false;

switch (_xferMode) do {
    case "AFT": {
        if (_fwdFuelMass > _xferStep && _aftFuelMass < _maxAftFuelMass) then {
            _doFwdToAft = true;
        };
    };
    case "FWD": {
        if (_aftFuelMass > _xferStep && _fwdFuelMass < _maxFwdFuelMass) then {
            _doAftToFwd = true;
        };
    };
    case "AUTO": {
        private _aftMinusFwd = _aftFuelMass - _fwdFuelMass;
        private _fwdMinusAft = _fwdFuelMass - _aftFuelMass;

        private _aftLeadEnough = if (_aftFuelMass > AUTO_500_KG) then {
            _aftMinusFwd > AUTO_SPLIT_100_KG
        } else {
            _aftMinusFwd > AUTO_SPLIT_50_KG
        };
        private _fwdLeadEnough = if (_fwdFuelMass > AUTO_500_KG) then {
            _fwdMinusAft > AUTO_SPLIT_100_KG
        } else {
            _fwdMinusAft > AUTO_SPLIT_50_KG
        };

        // AUTO: AFT → FWD
        if ((_eng1On || _eng2On)
                && _airAvail
                && (_fwdFuelMass < AUTO_FILL_THRESH_KG)
                && !_aftLow
                && (_aftFuelMass > (_fuelLow param [TANK_FWD, 0]))
                && _aftLeadEnough
                // HALT guards
                && (_aftMinusFwd >= AUTO_SPLIT_STOP_KG) && (_fwdFuelMass < (_maxFwdFuelMass - 0.1))) then {
            _doAftToFwd = true;
        };

        // AUTO: FWD → AFT
        if (_eng1On && _eng2On
                && _airAvail
                && (_aftFuelMass < AUTO_FILL_THRESH_KG)
                && !_fwdLow
                && (_fwdFuelMass > AUTO_FWD_MIN_SRC_KG)
                && _fwdLeadEnough
                // HALT guards
                && (_fwdMinusAft >= AUTO_SPLIT_STOP_KG)) then {
            _doFwdToAft = true;
        };

        if (!_airAvail) then {
            _doAftToFwd = false;
            _doFwdToAft = false;
        };
    };
};

if (_doFwdToAft) then {
    private _amt = _fwdFuelMass min _xferStep min (_maxAftFuelMass - _aftFuelMass);
    _fwdFuelMass = _fwdFuelMass - _amt;
    _aftFuelMass = _aftFuelMass + _amt;
    if (_amt > 0) then {
        _intercellTransferActive = true;
        _intercellTransferDir = 1; // FWD -> AFT (down)
    };
};
if (_doAftToFwd) then {
    private _amt = _aftFuelMass min _xferStep min (_maxFwdFuelMass - _fwdFuelMass);
    _aftFuelMass = _aftFuelMass - _amt;
    _fwdFuelMass = _fwdFuelMass + _amt;
    if (_amt > 0) then {
        _intercellTransferActive = true;
        _intercellTransferDir = 2; // AFT -> FWD (up)
    };
};

// IAFS gravity feed — inhibited while any aux tank is transferring
private _lAuxOn = _heli getVariable ["bmkhs_lAuxOn", false];
private _rAuxOn = _heli getVariable ["bmkhs_rAuxOn", false];

private _anyAuxTransferring = (_lAuxOn && (_stn1FuelMass > EXT_EMPTY_ADV_THRESH_KG || _stn2FuelMass > EXT_EMPTY_ADV_THRESH_KG)) || (_rAuxOn && (_stn3FuelMass > EXT_EMPTY_ADV_THRESH_KG || _stn4FuelMass > EXT_EMPTY_ADV_THRESH_KG));

private _iafsAftFlowing = false;
private _iafsFwdFlowing = false;
if (_IAFSInstalled && (_heli getVariable ["bmkhs_fuelTank2XferOn", false]) && !_anyAuxTransferring) then {
    if (_ctrFuelMass > 0 && _aftFuelMass < _maxAftFuelMass) then {
        private _iafsFlow = _xferStep min _ctrFuelMass min (_maxAftFuelMass - _aftFuelMass);
        _ctrFuelMass = _ctrFuelMass - _iafsFlow;
        _aftFuelMass = _aftFuelMass + _iafsFlow;
        if (_iafsFlow > 0) then { _iafsAftFlowing = true; };
    };
    if (_ctrFuelMass > 0 && _fwdFuelMass < _maxFwdFuelMass) then {
        private _iafsFlow = _xferStep min _ctrFuelMass min (_maxFwdFuelMass - _fwdFuelMass);
        _ctrFuelMass = _ctrFuelMass - _iafsFlow;
        _fwdFuelMass = _fwdFuelMass + _iafsFlow;
        if (_iafsFlow > 0) then { _iafsFwdFlowing = true; };
    };
    // Auto-shutoff: turn off IAFS switch when CTR tank is empty
    if (_ctrFuelMass <= 0) then {
        _heli setVariable ["bmkhs_fuelTank2XferOn", false, true];
    };
};

//Fold the plumbing results back into the arrays.
_fuelMass set [TANK_FWD, _fwdFuelMass];
_fuelMass set [TANK_CTR, _ctrFuelMass];
_fuelMass set [TANK_AFT, _aftFuelMass];

// Tank leaks - onset at TANK_LEAK_START_DMG hitpoint damage, linear ramp to max rate.
//The hitpoint per tank is still named here; it belongs in the tank config with the topology.
{
    _x params ["_idx", "_hitPoint", "_gated"];
    private _m = _fuelMass param [_idx, 0];
    if (_gated && _m > 0) then {
        private _dmg = (_heli getHitPointDamage _hitPoint) max 0;
        if (_dmg > TANK_LEAK_START_DMG) then {
            private _frac = ((_dmg - TANK_LEAK_START_DMG) / (1 - TANK_LEAK_START_DMG)) min 1;
            _fuelMass set [_idx, _m - ((TANK_LEAK_MAX_RATE_KGS * _frac * _deltaTime) min _m)];
        };
    };
} forEach [
    [TANK_FWD, "hit_fuel_forward",           true],
    [TANK_CTR, "hit_msnEquip_magandrobbie",  _IAFSInstalled && _maxCtrFuelMass > 0],
    [TANK_AFT, "hit_fuel_aft",               true]
];
//Leaks ran on the arrays, so refresh the named views the aux transfer below still uses.
_fwdFuelMass = _fuelMass param [TANK_FWD, 0];
_ctrFuelMass = _fuelMass param [TANK_CTR, 0];
_aftFuelMass = _fuelMass param [TANK_AFT, 0];

// External tank transfer — L aux → FWD, R aux → AFT; outer requires inner present
//Presence per aux tank, from the pylons of the station it hangs on. A tank that is gone
//(jettisoned or never fitted) holds no fuel.
private _pylonMagazines = getPylonMagazines _heli;
private _stations       = _heli getVariable ["bmkhs_stations", []];
private _auxHasTank     = [];
{
    _x params ["_station"];
    private _pylons  = (_stations param [_station - 1, [[], []]]) param [1, []];
    private _present = _pylons findIf {
        ["auxTank", _pylonMagazines param [_x - 1, ""]] call BIS_fnc_inString
    } > -1;
    _auxHasTank pushBack _present;
    if (!_present) then { _auxMass set [_forEachIndex, 0] };
} forEach _auxTanks;

private _stn1HasTank = _auxHasTank param [0, false];
private _stn2HasTank = _auxHasTank param [1, false];
private _stn3HasTank = _auxHasTank param [2, false];
private _stn4HasTank = _auxHasTank param [3, false];
_stn1FuelMass = _auxMass param [0, 0];
_stn2FuelMass = _auxMass param [1, 0];
_stn3FuelMass = _auxMass param [2, 0];
_stn4FuelMass = _auxMass param [3, 0];

private _fwdRoom = _maxFwdFuelMass - _fwdFuelMass;
private _aftRoom = _maxAftFuelMass - _aftFuelMass;

// Left side: inner-L (stn2) then outer-L (stn1, requires stn2 for pressurised air path) → FWD
private _lAuxFlowTotal = 0;
if (_stn2HasTank && _lAuxOn && _stn2FuelMass > 0 && _fwdRoom > 0) then {
    private _flow = _xferStep min _stn2FuelMass min _fwdRoom;
    _stn2FuelMass  = _stn2FuelMass - _flow;
    _fwdFuelMass   = _fwdFuelMass  + _flow;
    _fwdRoom       = _fwdRoom      - _flow;
    _lAuxFlowTotal = _lAuxFlowTotal + _flow;
};
if (_stn1HasTank && _lAuxOn && _stn2HasTank && _stn1FuelMass > 0 && _fwdRoom > 0) then {
    private _flow = _xferStep min _stn1FuelMass min _fwdRoom;
    _stn1FuelMass  = _stn1FuelMass - _flow;
    _fwdFuelMass   = _fwdFuelMass  + _flow;
    _fwdRoom       = _fwdRoom      - _flow;
    _lAuxFlowTotal = _lAuxFlowTotal + _flow;
};
// Right side: inner-R (stn3) then outer-R (stn4, requires stn3 for pressurised air path) → AFT
private _rAuxFlowTotal = 0;
if (_stn3HasTank && _rAuxOn && _stn3FuelMass > 0 && _aftRoom > 0) then {
    private _flow = _xferStep min _stn3FuelMass min _aftRoom;
    _stn3FuelMass  = _stn3FuelMass - _flow;
    _aftFuelMass   = _aftFuelMass  + _flow;
    _aftRoom       = _aftRoom      - _flow;
    _rAuxFlowTotal = _rAuxFlowTotal + _flow;
};
if (_stn4HasTank && _rAuxOn && _stn3HasTank && _stn4FuelMass > 0 && _aftRoom > 0) then {
    private _flow = _xferStep min _stn4FuelMass min _aftRoom;
    _stn4FuelMass  = _stn4FuelMass - _flow;
    _aftFuelMass   = _aftFuelMass  + _flow;
    _rAuxFlowTotal = _rAuxFlowTotal + _flow;
};

private _lAuxFlowing = _lAuxFlowTotal > 0;
private _rAuxFlowing = _rAuxFlowTotal > 0;

//Fold the aux transfer results back into the arrays, then clamp every tank to its capacity.
_fuelMass set [TANK_FWD, _fwdFuelMass];
_fuelMass set [TANK_CTR, _ctrFuelMass];
_fuelMass set [TANK_AFT, _aftFuelMass];
_auxMass set [0, _stn1FuelMass];
_auxMass set [1, _stn2FuelMass];
_auxMass set [2, _stn3FuelMass];
_auxMass set [3, _stn4FuelMass];

{ _fuelMass set [_forEachIndex, 0 max _x min (_fuelMax param [_forEachIndex, 0])] } forEach _fuelMass;
{ _auxMass  set [_forEachIndex, 0 max _x min (_auxMax  param [_forEachIndex, 0])] } forEach _auxMass;

private _eng1FuelAvail = (_eng1Req <= _eps) || ([_aftFuelAvailLastFrame, _fwdFuelAvailLastFrame] select (_eng1Source == "FWD"));
private _eng2FuelAvail = (_eng2Req <= _eps) || ([_aftFuelAvailLastFrame, _fwdFuelAvailLastFrame] select (_eng2Source == "FWD"));
private _apuFuelAvail  = (_apuReq  <= _eps) || _aftFuelAvailLastFrame;

// 2-second starvation grace period
private _eng1StarvedSince = _heli getVariable ["bmkhs_eng1StarvedSince", -1];
if (!_eng1FuelAvail) then {
    if (_eng1StarvedSince < 0) then { _eng1StarvedSince = CBA_missionTime; _heli setVariable ["bmkhs_eng1StarvedSince", _eng1StarvedSince]; };
    _eng1FuelAvail = (CBA_missionTime - _eng1StarvedSince) < 2;
} else { _heli setVariable ["bmkhs_eng1StarvedSince", -1]; };

private _eng2StarvedSince = _heli getVariable ["bmkhs_eng2StarvedSince", -1];
if (!_eng2FuelAvail) then {
    if (_eng2StarvedSince < 0) then { _eng2StarvedSince = CBA_missionTime; _heli setVariable ["bmkhs_eng2StarvedSince", _eng2StarvedSince]; };
    _eng2FuelAvail = (CBA_missionTime - _eng2StarvedSince) < 2;
} else { _heli setVariable ["bmkhs_eng2StarvedSince", -1]; };

[_heli, "bmkhs_eng1FuelAvail", _eng1FuelAvail] call bmkhs_fnc_utilUpdateNetworkGlobal;
[_heli, "bmkhs_eng2FuelAvail", _eng2FuelAvail] call bmkhs_fnc_utilUpdateNetworkGlobal;
[_heli, "bmkhs_apuFuelAvail",  _apuFuelAvail]  call bmkhs_fnc_utilUpdateNetworkGlobal;

// Status flags
_heli setVariable ["bmkhs_intercellTransferActive", _intercellTransferActive];
_heli setVariable ["bmkhs_intercellTransferDir",    _intercellTransferDir];
_heli setVariable ["bmkhs_iafsFlowing",            _iafsAftFlowing || _iafsFwdFlowing];
_heli setVariable ["bmkhs_iafsAftFlowing",         _iafsAftFlowing];
_heli setVariable ["bmkhs_iafsFwdFlowing",         _iafsFwdFlowing];
_heli setVariable ["bmkhs_lAuxFlowing",            _lAuxFlowing];
_heli setVariable ["bmkhs_rAuxFlowing",            _rAuxFlowing];

// Write back
private _totFuelMass = 0;
{ _totFuelMass = _totFuelMass + _x } forEach (_fuelMass + _auxMass);
if (local _heli) then {
    _heli setFuel (_totFuelMass / _maxTotFuelMass);
};

{ _heli setVariable [format ["bmkhs_fuelTank%1Mass", _forEachIndex + 1], _x] } forEach _fuelMass;
{ _heli setVariable [format ["bmkhs_auxTank%1Mass",  _forEachIndex + 1], _x] } forEach _auxMass;
_heli setVariable ["bmkhs_totFuelMass", _totFuelMass];

//Whether the crew can see the fuel page is the aircraft's business - it sets this
//if it wants empty-tank advisories to re-arm only while the page is displayed.
private _fuelPageOpen = _heli getVariable ["bmkhs_fuelPageOpen", false];
{
    private _present = _auxHasTank param [_forEachIndex, false];
    private _var     = format ["bmkhs_auxTank%1EmptyArmed", _forEachIndex + 1];
    if (!_present || _x >= EXT_EMPTY_ADV_THRESH_KG) then {
        _heli setVariable [_var, true];
    } else {
        if (_fuelPageOpen) then { _heli setVariable [_var, false]; };
    };
} forEach _auxMass;
