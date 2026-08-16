/* ----------------------------------------------------------------------------
Function: fza_sfmplus_fnc_tunerOverlay

Description:
    Toggles and drives the non-blocking data overlay (RscTitles
    fza_sfmplus_tunerOverlay). Unlike the main tuner dialog, this lets you FLY
    while watching the live balancer / master-tuner output. Call with no / "toggle"
    to flip it; it installs a per-frame handler that refreshes the text lines from
    the same variables the tuner GUI reads.

Parameters:
    _mode - "toggle" (default), "on", or "off" [String].

Returns:
    Nothing.

Author:
    BradMick
---------------------------------------------------------------------------- */
params [["_mode", "toggle"]];

private _open = !(isNull (uiNamespace getVariable ["fza_sfmplus_tunerOverlay", displayNull]));
private _want = switch (_mode) do { case "on": {true}; case "off": {false}; default { !_open } };

if (!_want) exitWith {
    //Close: remove the layer and the PFH, and stop the force log (the master
    //auto-tuner re-enables it itself while it is nulling yaw, so this only turns
    //off the overlay-driven logging).
    "fza_sfmplus_tunerOverlay" cutText ["", "PLAIN"];
    fza_sfmplus_forceLogOn = false;
    private _p = uiNamespace getVariable ["fza_sfmplus_tunerOverlayPfh", -1];
    if (_p >= 0) then { [_p] call CBA_fnc_removePerFrameHandler; uiNamespace setVariable ["fza_sfmplus_tunerOverlayPfh", -1]; };
};

//Open the overlay layer.
"fza_sfmplus_tunerOverlay" cutRsc ["fza_sfmplus_tunerOverlay", "PLAIN", 0, false];

//Guard against stacking a second refresh PFH if already open.
private _existing = uiNamespace getVariable ["fza_sfmplus_tunerOverlayPfh", -1];
if (_existing >= 0) exitWith {};

//Refresh loop.
private _pfh = [{
    private _disp = uiNamespace getVariable ["fza_sfmplus_tunerOverlay", displayNull];
    if (isNull _disp) exitWith {};
    private _heli = vehicle player;
    if (isNull _heli) exitWith {};

    private _spd   = vectorMagnitude [(_heli getVariable ["fza_sfmplus_velModelSpace", [0,0,0]]) select 0,
                                      (_heli getVariable ["fza_sfmplus_velModelSpace", [0,0,0]]) select 1];
    private _spdKt = round (_spd * 1.94384);

    //Targets are read at the COMMANDED speed (masterTargetKt), NOT the live
    //speed. The whole point of the tuner is to tune to known table data at a
    //fixed commanded speed; interpolating against a drifting live speed makes
    //the targets move and the system never settles. Falls back to live speed
    //only when no speed is commanded (masterTargetKt == 0 => auto).
    private _tgtKt     = _heli getVariable ["fza_sfmplus_tune_masterTargetKt", 0];
    private _lookupSpd = if (_tgtKt >= 5.0) then { _tgtKt / 1.94384 } else { _spd };

    //Attitude vs target (pinned to commanded speed).
    (_heli call BIS_fnc_getPitchBank) params ["_curP", "_curR"];
    private _tgtP = [_heli getVariable ["fza_sfmplus_tune_targetPitchTable", [[0,0]]], _lookupSpd] call fza_fnc_linearInterp select 1;
    private _tgtR = [_heli getVariable ["fza_sfmplus_tune_targetRollTable",  [[0,0]]], _lookupSpd] call fza_fnc_linearInterp select 1;

    //Controls.
    private _coll  = (_heli getVariable ["fza_sfmplus_collectiveOutput", 0.0]) * 100;
    //Live control positions (the master commands these via force-trim toward the
    //known flight-test target positions).
    private _cycFA = _heli getVariable ["fza_ah64_forceTrimPosPitch", 0.0];
    private _cycLR = _heli getVariable ["fza_ah64_forceTrimPosRoll",  0.0];
    private _ped   = _heli getVariable ["fza_ah64_forceTrimPosYaw",   0.0];
    //Target control positions. At a hover (explicit IGE/OGE mode) show the dedicated
    //hover targets; otherwise the airspeed-banded flight-test positions.
    private _hovMode = "";
    if (_heli getVariable ["fza_sfmplus_tune_hoverIGE", false]) then { _hovMode = "IGE"; }
    else { if (_heli getVariable ["fza_sfmplus_tune_hoverOGE", false]) then { _hovMode = "OGE"; }; };
    private _tgtC = 0.0; private _tgtCycFA = 0.0; private _tgtCycLR = 0.0; private _tgtPed = 0.0;
    if (_hovMode != "") then {
        private _pfx = if (_hovMode == "IGE") then { "fza_sfmplus_tune_ige" } else { "fza_sfmplus_tune_oge" };
        _tgtC     = (_heli getVariable [_pfx + "Coll",     0.637]) * 100;
        _tgtCycFA =  _heli getVariable [_pfx + "CycPitch",-0.342];
        _tgtCycLR =  _heli getVariable [_pfx + "CycRoll",  -0.045];
        _tgtPed   =  _heli getVariable [_pfx + "Pedal",    -0.352];
    } else {
        _tgtC     = ([_heli getVariable ["fza_sfmplus_tune_targetCollTable",     [[0,0]]], _lookupSpd] call fza_fnc_linearInterp select 1) * 100;
        _tgtCycFA =  [_heli getVariable ["fza_sfmplus_tune_targetCycPitchTable", [[0,0]]], _lookupSpd] call fza_fnc_linearInterp select 1;
        _tgtCycLR =  [_heli getVariable ["fza_sfmplus_tune_targetCycRollTable",  [[0,0]]], _lookupSpd] call fza_fnc_linearInterp select 1;
        _tgtPed   =  [_heli getVariable ["fza_sfmplus_tune_targetPedalTable",    [[0,0]]], _lookupSpd] call fza_fnc_linearInterp select 1;
    };
    private _climb = _heli getVariable ["fza_sfmplus_velClimb", 0.0];

    //Yaw rate about the Z axis (deg/s). angVelModelSpace = [pitch, roll, yaw]
    //rate in rad/s. POSITIVE = nose yawing RIGHT (the right precession); zero =
    //heading steady.
    private _yawRateRad = (_heli getVariable ["fza_sfmplus_angVelModelSpace", [0,0,0]]) select 2;
    private _yawRate    = deg _yawRateRad;

    //Yaw ANGULAR ACCELERATION (deg/s^2) = change in yaw rate over dt. Physics:
    //moment = I * accel. So with NET yaw moment ~0, accel should be ~0 and the
    //rate holds CONSTANT (a standing precession is normal - zero moment does not
    //mean zero rate). If accel is NON-zero while net moment reads ~0, the log is
    //missing a torque. If accel OPPOSES the rate, the precession is decaying.
    private _dtOv     = _heli getVariable ["fza_sfmplus_deltaTime", 0.02];
    private _prevYawR = _heli getVariable ["fza_sfmplus_ovPrevYawRate", _yawRateRad];
    private _yawAccel = if (_dtOv > 0) then { deg ((_yawRateRad - _prevYawR) / _dtOv) } else { 0 };
    _heli setVariable ["fza_sfmplus_ovPrevYawRate", _yawRateRad];
    //Light smoothing so the readout is legible (raw accel is noisy frame-to-frame).
    private _yawAccelS = (0.9 * (_heli getVariable ["fza_sfmplus_ovYawAccelSm", 0])) + (0.1 * _yawAccel);
    _heli setVariable ["fza_sfmplus_ovYawAccelSm", _yawAccelS];

    //Force the force log ON while the overlay is up so the table has live data
    //(it is otherwise only enabled on the Forces tab).
    fza_sfmplus_forceLogOn = true;

    private _mAxis = _heli getVariable ["fza_sfmplus_master_axis", "off"];

    //Summary lines.
    (_disp displayCtrl 54311) ctrlSetText format ["Speed %1 kt   climb %2 fpm   yawRate %3 deg/s   yawAccel %4 deg/s2", _spdKt, round _climb, _yawRate toFixed 2, _yawAccelS toFixed 2];
    (_disp displayCtrl 54312) ctrlSetText format ["Pitch %1 (tgt %2)   Roll %3 (tgt %4)", _curP toFixed 1, _tgtP toFixed 1, _curR toFixed 1, _tgtR toFixed 1];
    (_disp displayCtrl 54313) ctrlSetText format ["Coll %1%% (tgt %2%%)", _coll toFixed 0, _tgtC toFixed 0];
    (_disp displayCtrl 54314) ctrlSetText format ["Cyc fwd+ %1 (tgt %2)  left+ %3 (tgt %4)  Ped rgt+ %5 (tgt %6)",
        _cycFA toFixed 2, _tgtCycFA toFixed 2, _cycLR toFixed 2, _tgtCycLR toFixed 2, _ped toFixed 2, _tgtPed toFixed 2];
    //Line 54315: shows the PID AUTO-TUNE per-axis status (SAS or HOLD tuner) WHEN a tuner is
    //running - the important thing to watch while flying - else the MASTER axis. The status var
    //is shared by both tuners; it packs all axes + each axis's settle state (n/N or SETTLED).
    private _pidStat  = _heli getVariable ["fza_sfmplus_pidAuto_status", "PID auto-tune idle"];
    private _pidOn    = (_heli getVariable ["fza_sfmplus_tune_pidAutoOn", false]) || (_heli getVariable ["fza_sfmplus_tune_holdAutoOn", false]);
    (_disp displayCtrl 54315) ctrlSetText (if (_pidOn) then { _pidStat } else { format ["MASTER: %1", _mAxis] });

    //The FORCE SCALARS the master is actually tuning, at the current speed. These
    //are the outputs of the tuner - what it's modifying on the four main force
    //generators. Read at the commanded speed so they match the band being tuned.
    private _fnScalar = {
        params ["_var"];
        private _t = _heli getVariable [_var, []];
        if (_t isEqualTo []) then { 1.0 } else { [_t, _lookupSpd] call fza_fnc_linearInterp select 1 }
    };
    //Model-aware: in BET mode the tuner drives the bet* output scalars, not the simple tables.
    private _isBet = (fza_ah64_sfmPlusRotorModel == 1);
    private _sMain = [if (_isBet) then { "fza_sfmplus_tune_betMainLiftTable"   } else { "fza_sfmplus_tune_mainThrustTable"  }] call _fnScalar;   // main rotor thrust
    private _sTail = [if (_isBet) then { "fza_sfmplus_tune_betTailLiftTable"   } else { "fza_sfmplus_tune_tailThrustTable"  }] call _fnScalar;   // tail rotor thrust
    private _sTorq = [if (_isBet) then { "fza_sfmplus_tune_betMainTorqueTable" } else { "fza_sfmplus_tune_rtrTqScalarTable" }] call _fnScalar;   // main rotor torque
    private _sStab = ["fza_sfmplus_tune_stabLiftScalarTable"] call _fnScalar;// stabilator lift
    private _sFuse = ["fza_sfmplus_tune_fuseSideScalarTable"] call _fnScalar; // fuselage side-force (manual)
    private _sFin  = ["fza_sfmplus_tune_finLiftScalarTable"]  call _fnScalar; // vertical fin lift (manual)
    //LIVE rotor disk roll-tilt: disk tilt is now a pilot-input effect, driven by the
    //cyclic ROLL trim (forceTrimPosRoll) that tilts the thrust vector. Show that live
    //value (+ = disk tilted right) rather than the retired base-tilt table.
    private _sTilt = _heli getVariable ["fza_ah64_forceTrimPosRoll", 0.0];
    (_disp displayCtrl 54316) ctrlSetText format ["SCALARS  mainThr %1  tailThr %2  torque %3  stabLift %4  fuseSide %5  fin %6  tilt %7",
        _sMain toFixed 3, _sTail toFixed 3, _sTorq toFixed 3, _sStab toFixed 3, _sFuse toFixed 3, _sFin toFixed 3, _sTilt toFixed 2];

    //Forces table (mirrors the tuner Forces tab). Header + per-generator rows +
    //NET + net-moment line. Numbers RIGHT-aligned (left-pad) so columns line up.
    private _log  = _heli getVariable ["fza_sfmplus_forceLogPublished", createHashMap];
    private _gens = ["Main Rotor","Tail Rotor","Right Wing","Left Wing","Vertical Fin","Stabilator","Fuselage Front","Fuselage Side","Fuselage Top","Yaw Damper"];
    private _netF = [0,0,0]; private _netM = [0,0,0];
    { private _e = _log getOrDefault [_x, [[0,0,0],[0,0,0]]]; _netF = _netF vectorAdd (_e select 0); _netM = _netM vectorAdd (_e select 1); } forEach _gens;

    //--- Forces TABLE: STATIC grid of cells (defined in overlay.hpp) ---------
    //cell idc = 54400 + row*10 + col. row: 0 header, 1..9 gens, 10 NET.
    //col: 0 label, 1..6 = Fx Fy Fz Mrol Mpit Myaw. Set text + colour per cell.
    private _rowLabels = ["Generator","Main Rotor","Tail Rotor","Right Wing","Left Wing","Vertical Fin","Stabilator","Fuselage Front","Fuselage Side","Fuselage Top","Yaw Damper","NET"];
    private _colHdrs   = ["Fx","Fy","Fz","Mrol","Mpit","Myaw"];

    {
        private _r     = _forEachIndex;
        private _label = _x;

        //Column 0: the row label.
        private _lblCtrl = _disp displayCtrl (54400 + _r * 10);
        _lblCtrl ctrlSetText _label;
        _lblCtrl ctrlSetTextColor (if (_r == 0) then { [0.88,0.82,0.38,1] } else { [0.70,0.85,1,1] });

        //Columns 1..6: values (header row shows the column titles).
        private _vals = if (_r == 0) then { _colHdrs } else {
            private _e = if (_r == 11) then { [_netF, _netM] } else { _log getOrDefault [_label, [[0,0,0],[0,0,0]]] };
            (_e select 0) params ["_fx","_fy","_fz"];
            (_e select 1) params ["_mp","_mr","_my"];   // model moment = [pitch, roll, yaw]
            [_fx, _fy, _fz, _mr, _mp, _my]
        };
        {
            private _cell = _disp displayCtrl (54400 + _r * 10 + (_forEachIndex + 1));
            if (_r == 0) then {
                _cell ctrlSetText _x;
                _cell ctrlSetTextColor [0.88,0.82,0.38,1];
            } else {
                private _v = if (_x isEqualType 0) then { _x } else { 0 };
                _cell ctrlSetText str (round _v);
                _cell ctrlSetTextColor (if (_v < 0) then { [1,0.33,0.33,1] } else { [0.33,1,0.33,1] });
            };
        } forEach _vals;
    } forEach _rowLabels;

    //--- SCALARS-by-band TABLE: static grid, idc 54600 + row*10 + col ------------
    //Row 0 = header, rows 1..9 = the 9 airspeed bands. Col 0 = band (kt), cols 1..6
    //= mainThr tailThr torque stabLift fuseSide fin - each table's value at that
    //band. Highlights the band nearest the current speed so you can see what's live.
    //Model-aware: BET mode shows the bet* output-scalar tables the tuner actually drives; the
    //shared aero (stab/fuse/fin) are the same for both models.
    private _sclTables = [
        if (_isBet) then { "fza_sfmplus_tune_betMainLiftTable"   } else { "fza_sfmplus_tune_mainThrustTable"  },
        if (_isBet) then { "fza_sfmplus_tune_betTailLiftTable"   } else { "fza_sfmplus_tune_tailThrustTable"  },
        if (_isBet) then { "fza_sfmplus_tune_betTailTrimTable"   } else { "fza_sfmplus_tune_tailTrimTable"    },
        if (_isBet) then { "fza_sfmplus_tune_betMainTorqueTable" } else { "fza_sfmplus_tune_rtrTqScalarTable" },
        "fza_sfmplus_tune_stabLiftScalarTable",
        "fza_sfmplus_tune_fuseSideScalarTable",
        "fza_sfmplus_tune_finLiftScalarTable"
    ];
    private _sclHdrs  = ["mainThr","tailThr","tailTrim","torque","stabLift","fuseSide","fin"];
    private _sclBands = [0.00, 10.29, 20.58, 36.01, 46.30, 51.44, 61.73, 66.88, 72.02];
    //Which band is nearest the current speed (to highlight the live row).
    private _liveBand = 0; private _bErr = 1e9;
    { private _e = abs (_spd - _x); if (_e < _bErr) then { _bErr = _e; _liveBand = _forEachIndex; }; } forEach _sclBands;

    //Header row (row 0).
    (_disp displayCtrl 54600) ctrlSetText "Band kt";
    (_disp displayCtrl 54600) ctrlSetTextColor [0.88,0.82,0.38,1];
    {
        private _hc = _disp displayCtrl (54600 + (_forEachIndex + 1));
        _hc ctrlSetText _x;
        _hc ctrlSetTextColor [0.88,0.82,0.38,1];
    } forEach _sclHdrs;

    //Band rows (rows 1..9).
    {
        private _bandIdx = _forEachIndex;              // 0..8 -> table row index
        private _bandMps = _x;
        private _rr      = _bandIdx + 1;               // grid row (1..9)
        private _isLive  = (_bandIdx == _liveBand);
        private _col     = if (_isLive) then { [0.4,1,1,1] } else { [0.70,0.85,1,1] };

        //Col 0: band airspeed in knots.
        private _bc = _disp displayCtrl (54600 + _rr * 10);
        _bc ctrlSetText str (round (_bandMps * 1.94384));
        _bc ctrlSetTextColor _col;

        //Cols 1..6: each scalar table's value at THIS band index.
        {
            private _cc  = _disp displayCtrl (54600 + _rr * 10 + (_forEachIndex + 1));
            private _tbl = _heli getVariable [_x, []];
            private _val = if (_bandIdx < count _tbl) then { (_tbl select _bandIdx) select 1 } else { 1.0 };
            _cc ctrlSetText (_val toFixed 3);
            _cc ctrlSetTextColor _col;
        } forEach _sclTables;
    } forEach _sclBands;

    //Crab angle (deg) = HEADING - GROUND TRACK (per the reference diagram).
    //Heading is where the nose points; ground track is the compass direction the
    //aircraft is actually travelling over the ground. Both in [0,360). The signed
    //difference is normalised to [-180,180]: negative = nose LEFT of track (left
    //crab), positive = nose RIGHT of track. This is the STEADY nose-vs-flightpath
    //offset - distinct from yaw RATE (rotation). Only meaningful with forward
    //speed, so hold at 0 below a few kt of ground speed.
    private _crab = 0;
    private _gndSpd = _spd;   // 2D model-space speed (m/s) computed above
    if (_gndSpd > 2.0) then {
        private _heading = getDir _heli;
        private _vel     = velocity _heli;
        //Ground track from the horizontal world velocity (deg, 0=North, CW).
        private _track   = (_vel select 0) atan2 (_vel select 1);
        if (_track < 0) then { _track = _track + 360; };
        _crab = _heading - _track;
        //Normalise to [-180, 180].
        if (_crab > 180)  then { _crab = _crab - 360; };
        if (_crab < -180) then { _crab = _crab + 360; };
    };
    (_disp displayCtrl 54328) ctrlSetText format ["Net Nm: roll %1  pitch %2  yaw %3    |    Crab %4 deg    yawRate %5 deg/s",
        round (_netM select 1), round (_netM select 0), round (_netM select 2),
        _crab toFixed 1, _yawRate toFixed 2];

}, 0.2] call CBA_fnc_addPerFrameHandler;
uiNamespace setVariable ["fza_sfmplus_tunerOverlayPfh", _pfh];
