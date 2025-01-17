/* ----------------------------------------------------------------------------
Function: fza_fnc_ihadssDraw

Description:
    Draws the IHADSS overlay for the player.

Parameters:
	_heli - The heli object to draw the IHADSS for

Returns:
    Nothing

Examples:
	--- Code
    [_heli] call fza_fnc_ihadssDraw
	---

Author:
    unknown
---------------------------------------------------------------------------- */
#include "\fza_ah64_controls\headers\systemConstants.h"
if (!(isNil "fza_ah64_notargeting")) exitwith {};
params ["_heli"];
_locktargstate = 0;
_modestate = 0;
_zoomstate = 0;
_targhead = 0;

_sensor = "R ";
_sensxm = "HMD";
_acqihadss = ""; //TEST ACQ TADS DISPLAY
_weapon = "GUN";
_weaponstate = "";
_rcd = "RCD      TADS";
_lsrcode = "A 1688";
_safemessage = "";
_rocketcode = "???";
_targrange = "0";
if (isNil "fza_ah64_shottimer") then {
    fza_ah64_shottimer = 0;
};
_laseron = 0;
///NAV/////
_waypointcode = "";
_gspdcode = "";

_curwpdir = 0;
_chevmark = 0;
_wpdistr = 0;
_bobhdg = 0;
_bobpos = [0, 0];
///NAV/////
///RANGES///
///0.00002// 50km//
///0.00004// 25km//
///0.0001// 10km//
///0.0002// 5km//
///0.0005// 2km//
///0.001// 1km//
_fcrantennafor = 0.5;
_radrange = "20";
_nolosbox = "";
_losbox = "";
_w = 0.0734;
_h = 0.1;
_apx = 0.036;
_apy = 0.05;
_fcrdir = 0.5;
_terrainintersect1 = [0, 0, 0];
_gunintpos2 = [0, 0, 0];
_TIST = 0;
_ins = [];
_ins1 = [];
_VMurangle = [];
_lrange = 0;
_wptime = 0;
_headsdown = false;
_aratio = getResolution select 4;

if (isNil "fza_ah64_helperinit") then {
    2 cutrsc["fza_ah64_click_helper", "PLAIN", 0.01, false];
    ((uiNameSpace getVariable "fza_ah64_click_helper") displayCtrl 602) ctrlSetTextColor[0, 1, 1, 1];
    if (isNil "fza_ah64_mousetracker") then {
        fza_ah64_mousetracker = (findDisplay 46) displayAddEventHandler["MouseMoving", "_this call fza_fnc_uiMouseMove"];
    };
    fza_ah64_helperinit = true;
};

if (isNull(uiNameSpace getVariable "fza_ah64_click_helper")) then {
    2 cutrsc["fza_ah64_click_helper", "PLAIN", 0.01, false];
    ((uiNameSpace getVariable "fza_ah64_click_helper") displayCtrl 602) ctrlSetTextColor[0, 1, 1, 1];
};

private _clickHint = (uiNameSpace getVariable "fza_ah64_click_helper") displayCtrl 602;
if (fza_ah64_enableClickHelper) then {
    private _controls = [_heli] call fza_fnc_coreGetObjectsLookedAt;
    if (_controls isEqualTo []) then {
        _clickHint ctrlSetText "";
    } else {
        //If there are multiple controls in the range, make sure we use the closest one
        if(count _controls > 1) then {
            _controls = [_controls, [], {_x # 6}, "ASCEND"] call BIS_fnc_sortBy;
        };
        _clickHint ctrlSetText (_controls # 0 # 5);
    };
} else {
     _clickHint ctrlSetText "";
};
_clickHint ctrlCommit 0.001;

if (_heli getVariable "fza_ah64_ihadssoff" == 1) then {
    1 cuttext["", "PLAIN", 0.1];
};
if (_heli getVariable "fza_ah64_ihadssoff" == 0 && _heli getVariable "fza_ah64_monocleinbox") then {
    1 cuttext["", "PLAIN", 0.1];
};
if (isNull laserTarget _heli) then {
    4 cuttext["", "PLAIN", 0.1];
};



_targPos = [-100, -100];
if(!isNull fza_ah64_mycurrenttarget) then {
    _targPos = worldToScreen(getpos fza_ah64_mycurrenttarget);
    if (count _targPos < 1) then {
        _targPos = [-100, -100];
    } else {
        _targPos = [
            [_targPos # 0, 0, 1] call BIS_fnc_clamp,
            [_targPos # 1, 0, 1] call BIS_fnc_clamp];
    };
};

//PNVS HDU
if (_heli getVariable "fza_ah64_ihadss_pnvs_cam" && cameraView != "GUNNER" && alive player) then {
    if (_heli getVariable "fza_ah64_ihadss_pnvs_day") then {
        ((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 120) ctrlSetText "#(argb,512,512,1)r2t(fza_ah64_pnvscam2,1)"; //DTV HDU
    } else {
        ((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 120) ctrlSetText "#(argb,512,512,1)r2t(fza_ah64_pnvscam3,1)"; //NVG HDU
    };
} else {
    ((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 120) ctrlSetText "";
};

//A3TI FUNCTIONS
private _a3ti_vis = call A3TI_fnc_getA3TIVision;
private _a3ti_brt = call A3TI_fnc_getA3TIBrightnessContrast;

//TADS DISABLE IF ENGINE OFF
if (cameraView == "GUNNER" && player == gunner _heli && !isEngineOn _heli) then {
    fza_ah64_bweff ppEffectEnable true;
} else {
    fza_ah64_bweff ppEffectEnable false;
};

//IHADSS INIT
if (_heli animationphase "plt_apu" > 0.5 && !(_heli getVariable "fza_ah64_monocleinbox") || isEngineOn _heli && !(_heli getVariable "fza_ah64_monocleinbox") || !(_heli getVariable "fza_ah64_monocleinbox")) then {
    if (isNil "fza_ah64_ihadssinit") then {
        1 cutrsc["fza_ah64_raddisp", "PLAIN", 0.01, false];
        ((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 130) ctrlSetText "\fza_ah64_US\tex\HDU\ihadss.paa";

        _ihadssidx = 121;

        while {
            (_ihadssidx < 206)
        }
        do {
            ((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl _ihadssidx) ctrlSetTextColor fza_ah64_hducolor;
            _ihadssidx = _ihadssidx + 1;
        };

        _rocketcode = "???";
        fza_ah64_ihadssinit = true;
    };
};

if (!(_heli getVariable "fza_ah64_monocleinbox") && cameraView == "INTERNAL") then {
    3 cutrsc["fza_ah64_monocleinbox", "PLAIN", 0.01, false];
    ((uiNameSpace getVariable "fza_ah64_monocleinbox") displayCtrl 501) ctrlSetText "\fza_ah64_US\tex\HDU\monocle_solid.paa";
} else {
    3 cuttext["", "PLAIN"];
};

//1ST PERSON VIEW IHADSS BASIC FLIGHT INFO SETUP

if ((gunner _heli == player || driver _heli == player) && !(_heli getVariable "fza_ah64_monocleinbox") && _heli getVariable "fza_ah64_ihadssoff" == 0 && (cameraView == "INTERNAL" || cameraView == "GUNNER")) then {
    if ((isNull(uiNameSpace getVariable "fza_ah64_raddisp")) && (_heli animationphase "plt_apu" > 0.5 || isEngineOn _heli) && (cameraView == "INTERNAL" || cameraView == "GUNNER")) then {
        1 cutrsc["fza_ah64_raddisp", "PLAIN", 0.01, false];

        ((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 121) ctrlSetTextColor[0.1, 1, 0, 1];
        ((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 122) ctrlSetTextColor[0.1, 1, 0, 1];
        ((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 123) ctrlSetTextColor[0.1, 1, 0, 1];
        ((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 124) ctrlSetTextColor[0.1, 1, 0, 1];
        ((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 125) ctrlSetTextColor[0.1, 1, 0, 1];
        ((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 126) ctrlSetTextColor[0.1, 1, 0, 1];
        ((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 127) ctrlSetTextColor[0.1, 1, 0, 1];
        ((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 128) ctrlSetTextColor[0.1, 1, 0, 1];
        ((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 129) ctrlSetTextColor[0.1, 1, 0, 1];
        ((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 184) ctrlSetTextColor[0.1, 1, 0, 1];
        ((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 188) ctrlSetTextColor[0.1, 1, 0, 1];
        _rocketcode = "???";
    };
} else {
    if (cameraView == "EXTERNAL" || !(vehicle player isKindOf "fza_ah64base" || alive player)) then {
        1 cuttext["", "PLAIN"];
		2 cuttext["", "PLAIN"];
        3 cuttext["", "PLAIN"];
		4 cuttext["", "PLAIN"];
    };
};

if((vehicle player) animationphase "plt_apu" < 0.5 && !(isEngineOn _heli)) then {
    1 cuttext["", "PLAIN"];
    4 cuttext["", "PLAIN"];
};

//IHADSS FOR GUNNER HEADSDOWN
if (cameraView == "GUNNER" && player == gunner _heli && (_heli animationphase "plt_apu" > 0.5 || isEngineOn _heli)) then {

    if !(isNil "_a3ti_vis") then {
        if !(isNil "fza_ah64_bweff") then {
            fza_ah64_bweff ppEffectEnable false;
        };
    } else {
        fza_ah64_bweff = ppEffectCreate["colorCorrections", 4000];
        fza_ah64_bweff ppEffectAdjust[1, 1, 0, [0, 0, 0, 0], [1, 1, 1, 0], [0.33, 0.33, 0.33, 0], [0, 0, 0, 0, 0, 0, 4]]; //MONOCHROME TADS EXP
        fza_ah64_bweff ppEffectCommit 0;
        fza_ah64_bweff ppEffectEnable true;
    };

    _headsdown = true;

    ((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 130) ctrlSetText "\fza_ah64_US\tex\HDU\TADSmain_co.paa";
    ((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 130) ctrlSetTextColor[(fza_ah64_hducolor select 1), (fza_ah64_hducolor select 1), (fza_ah64_hducolor select 1), 1];
    ((uiNameSpace getVariable "fza_ah64_click_helper") displayCtrl 601) ctrlSetTextColor[1, 1, 1, 0];

    //ADD STATIC DATA TO TADS
    ((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 802) ctrlSetText _rcd;
    ((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 803) ctrlSetText _lsrcode;

    //COLOR WHITE TADS VIEW ACQ
    ((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 804) ctrlSetTextColor[(fza_ah64_hducolor select 1), (fza_ah64_hducolor select 1), (fza_ah64_hducolor select 1), 1];

    //HIDE CLICK HELPER FOR HEADSDOWN GUNNER
    ((uiNameSpace getVariable "fza_ah64_click_helper") displayCtrl 601) ctrlSetTextColor[1, 1, 1, 0];

    //COLOR SET THESE
    ((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 121) ctrlSetTextColor[(fza_ah64_hducolor select 1), (fza_ah64_hducolor select 1), (fza_ah64_hducolor select 1), 1];
    ((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 122) ctrlSetTextColor[(fza_ah64_hducolor select 1), (fza_ah64_hducolor select 1), (fza_ah64_hducolor select 1), 1];
    ((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 123) ctrlSetTextColor[(fza_ah64_hducolor select 1), (fza_ah64_hducolor select 1), (fza_ah64_hducolor select 1), 1];
    ((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 124) ctrlSetTextColor[(fza_ah64_hducolor select 1), (fza_ah64_hducolor select 1), (fza_ah64_hducolor select 1), 1];
    ((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 125) ctrlSetTextColor[(fza_ah64_hducolor select 1), (fza_ah64_hducolor select 1), (fza_ah64_hducolor select 1), 1];
    ((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 126) ctrlSetTextColor[(fza_ah64_hducolor select 1), (fza_ah64_hducolor select 1), (fza_ah64_hducolor select 1), 1];
    ((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 127) ctrlSetTextColor[(fza_ah64_hducolor select 1), (fza_ah64_hducolor select 1), (fza_ah64_hducolor select 1), 1];
    ((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 128) ctrlSetTextColor[(fza_ah64_hducolor select 1), (fza_ah64_hducolor select 1), (fza_ah64_hducolor select 1), 1];
    ((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 131) ctrlSetTextColor[(fza_ah64_hducolor select 1), (fza_ah64_hducolor select 1), (fza_ah64_hducolor select 1), 1];
    ((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 132) ctrlSetTextColor[(fza_ah64_hducolor select 1), (fza_ah64_hducolor select 1), (fza_ah64_hducolor select 1), 1];
    ((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 133) ctrlSetTextColor[(fza_ah64_hducolor select 1), (fza_ah64_hducolor select 1), (fza_ah64_hducolor select 1), 1];
    ((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 134) ctrlSetTextColor[(fza_ah64_hducolor select 1), (fza_ah64_hducolor select 1), (fza_ah64_hducolor select 1), 1];
    ((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 137) ctrlSetTextColor[(fza_ah64_hducolor select 1), (fza_ah64_hducolor select 1), (fza_ah64_hducolor select 1), 1];
    ((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 207) ctrlSetTextColor[(fza_ah64_hducolor select 1), (fza_ah64_hducolor select 1), (fza_ah64_hducolor select 1), 1];

    _ihadssidx = 146;
    while {
        (_ihadssidx < 207)
    }
    do {
        if (!(_ihadssidx == 135 || _ihadssidx == 136 || _ihadssidx == 182 || _ihadssidx == 186 || _ihadssidx == 123 || _ihadssidx == 124 || _ihadssidx == 125 || _ihadssidx == 120)) then {
            ((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl _ihadssidx) ctrlSetTextColor[(fza_ah64_hducolor select 1), (fza_ah64_hducolor select 1), (fza_ah64_hducolor select 1), 1];
        };
        _ihadssidx = _ihadssidx + 1;
    };

    //RELOCATE TEXTURES AS FOLLOWS
    ((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 123)
    ctrlsetposition[0.31, 0.345, 0.5, 0.12];
    ((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 123) ctrlCommit 0;
    ((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 124) ctrlsetposition[0.4, 0.7, 0.5, 0.12];
    ((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 124) ctrlCommit 0;
    ((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 125) ctrlsetposition[0.11, 0.7, 0.5, 0.12]; //TEST TADS RADAR ALTITUDE
    ((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 125) ctrlCommit 0;

    //HIDE THESE AS FOLLOWS
    ((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 135) ctrlSetTextColor[0, 0, 0, 0];
    ((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 136) ctrlSetTextColor[0, 0, 0, 0];
    ((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 182) ctrlSetTextColor[0, 0, 0, 0];
    ((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 186) ctrlSetTextColor[0, 0, 0, 0];
    ((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 129) ctrlSetTextColor[0, 0, 0, 0];
    ((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 188) ctrlSetTextColor[0, 0, 0, 0]; //HIDING BAROALT FT

    //LASER SYMBOLOGY FOR GUNNER
    if !(isNull laserTarget _heli) then {
        4 cutrsc["fza_ah64_laseit", "PLAIN", 0.01, false];
        ((uiNameSpace getVariable "fza_ah64_laseit") displayCtrl 701) ctrlSetText "\fza_ah64_US\tex\HDU\Apache_LaserOn.paa";
        ((uiNameSpace getVariable "fza_ah64_laseit") displayCtrl 701) ctrlSetTextColor[(fza_ah64_hducolor select 1), (fza_ah64_hducolor select 1), (fza_ah64_hducolor select 1), 1];
    };

} else {

    _headsdown = false;

    ((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 130) ctrlSetText "\fza_ah64_US\tex\HDU\ihadss.paa";
    ((uiNameSpace getVariable "fza_ah64_laseit") displayCtrl 701) ctrlSetText "";

    _ihadssidx = 121;

    while {
        (_ihadssidx < 208)
    }
    do {
        ((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl _ihadssidx) ctrlSetTextColor fza_ah64_hducolor;
        _ihadssidx = _ihadssidx + 1;
    };

    //REMOVE AND/OR RECOLOR TEXTURES ONCE HEADSUP
    ((uiNameSpace getVariable "fza_ah64_click_helper") displayCtrl 601)
    ctrlSetTextColor[1, 1, 1, 1];
    ((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 130) ctrlSetText "\fza_ah64_US\tex\HDU\ihadss.paa"; //TEST
    ((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 802) ctrlSetText "";
    ((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 803) ctrlSetText "";
    ((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 804) ctrlSetText "";
    ((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 804) ctrlSetTextColor[0.1, 1, 0, 1]; //DOES SET GREEN COLOR FOR IHADSS

    //1ST PERSON VIEW, REPOSITION TEXTURES FROM TADS VIEW TO IHADSS VIEW
    ((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 123) ctrlsetposition[0.31, 0.356, 0.5, 0.12];
    ((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 123) ctrlCommit 0;
    ((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 124) ctrlsetposition[0.31, 0.5, 0.5, 0.12];
    ((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 124) ctrlCommit 0;
    ((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 125) ctrlsetposition[0.18, 0.5, 0.5, 0.12];
    ((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 125) ctrlCommit 0;
    ((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 206) ctrlSetTextColor[0, 0, 0, 0];
};


_autohide = {
    _partid = _this select 0;
    _pitchid = _this select 1;
    _bankid = _this select 2;

    if ((_pitchid < -20 || _pitchid > 20)) then {
        ((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl _partid) ctrlSetPosition[100, 10, 100];
    } else {
        ((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl _partid) ctrlSetPosition[0.5 + (((_pitchid) * 0.00556) * (sin _bankid)), 10, 0.5 + (((_pitchid) * 0.00556) * (cos _bankid))];
    };

};

if ((_heli getVariable "fza_ah64_ldp_fail") && (_heli getVariable "fza_ah64_rdp_fail")) then {
    1 cuttext["", "PLAIN", 0.1];
    _heli setVariable ["fza_ah64_ihadssoff", 2];
};
if ((!(_heli getVariable "fza_ah64_ldp_fail") || !(_heli getVariable "fza_ah64_rdp_fail")) && _heli getVariable "fza_ah64_ihadssoff" == 2) then {
    _heli setVariable ["fza_ah64_ihadssoff", 1];
};

_gspdcode = format["%1", round(0.53996 * (speed _heli))] + "    " + format["%1:%2%3", fza_ah64_wptimhr, fza_ah64_wptimtm, fza_ah64_wptimsm];

_waypoint = (_heli getVariable "fza_ah64_waypointdata") select (_heli getVariable "fza_ah64_curwpnum");
_waypointcode = "W" + (format["%1",_heli getVariable "fza_ah64_curwpnum"]) + "    " + (format["%1", 0.1 * (round(0.01 * (_heli distance _waypoint)))]);

_reldir = ((_waypoint # 0) - (getposatl _heli select 0)) atan2((_waypoint # 1) - (getposatl _heli select 1));
if (_reldir < 0) then {
    _reldir = _reldir + 360;
};
_theta = (360 + (_reldir - (direction _heli))) Mod 360;

_targhead = _theta;

if (_theta >= 180) then {
    _targhead = _theta - 360;
} else {
    _targhead = _theta;
};

_curwpdir = _targhead;

/////////////////////////////////////////////////////////
switch (_heli getVariable "fza_ah64_agmode") do {
    case FCR_MODE_GND: {
        _sensor = "R ";
        _acqihadss = "FCR/G";
    };
    case FCR_MODE_AIR: {
        _sensor = "R ";
        _acqihadss = "FCR/A";
    }
};

_sight = [_heli] call fza_fnc_targetingGetSightSelect;
if (_heli iskindof "fza_ah64base") then {
    switch (_sight) do {
        case 0: {
            _sensxm = "FCR ";
        };
        case 1: {
            _sensxm = "HMD ";
        };
        case 2: {
            _sensxm  = "TADS";
        };
        case 3: {
            _sensxm = "FXD ";
        };
    };
};

_targrange = format["%1", ((round((_heli distance fza_ah64_mycurrenttarget) * 0.01)) * 0.1)];
if (isNull fza_ah64_mycurrenttarget) then {
    _targrange = "0.00";
};
if (!isNull laserTarget _heli) then {
    _targrange = format["*%1", round(_heli distance laserTarget _heli)];
};

_thetatarg = [_heli, (getposatl _heli select 0), (getposatl _heli select 1), (getposatl fza_ah64_mycurrenttarget select 0), (getposatl fza_ah64_mycurrenttarget select 1)] call fza_fnc_relativeDirection;

_aimpos = worldtoscreen(_heli modelToWorldVisual[0, +20, 0]);
if (count _aimpos < 1) then {
    _aimpos = [-3, -3];
};
_scPos = [-100, -100];
_heading = format["%1", round(_thetatarg)];
if (_heading == "scalar") then {
    _heading = "0";
};
if (_thetatarg >= 315) then {
    _targhead = _thetatarg - 360;
} else {
    _targhead = _thetatarg;
};
if (_thetatarg < 315 && _thetatarg >= 180) then {
    _targhead = -45;
};
if (_thetatarg > 45 && _thetatarg < 180) then {
    _targhead = 45;
};
_targxpos = (_targhead * 0.0027777777777777777777777777777778) + 0.945;
_targypos = ((_heli distance fza_ah64_mycurrenttarget) * (_heli getVariable "fza_ah64_rangesetting")) + 0.95;
if (_targypos < 0.63 || isNull fza_ah64_mycurrenttarget) then {
    _targypos = 0.63;
};
if (_targxpos > 1.07 || _targxpos < 0.82 || isNull fza_ah64_mycurrenttarget) then {
    _targxpos = 0.95;
};
_radrange = format["%1", (abs(1 / (_heli getVariable "fza_ah64_rangesetting"))) * 0.001];

//Use the perfGetData method to update the TQ in the HDU
_TQVal = (_heli getVariable "fza_sfmplus_engPctTQ" select 0) max (_heli getVariable "fza_sfmplus_engPctTQ" select 1);
_collective = format["%1", round(100 * _TQVal)];
if (_collective == "scalar") then {
    _collective = "0";
};
_speedkts = format["%1", round(1.94 * (sqrt(((velocity _heli select 0) + (0.836 * (abs(wind select 0) ^ 1.5))) ^ 2 + ((velocity _heli select 1) + (0.836 * (abs(wind select 2) ^ 1.5))) ^ 2 + ((velocity _heli select 2) + (0.836 * (abs(wind select 1) ^ 1.5))) ^ 2)))];
_radaltft = format["%1", round(3.28084 * (getpos _heli select 2))];
_baraltft = format["%1", round(3.28084 * (getposasl _heli select 2))];

_fcrDir = 0.125- abs((((_heli animationPhase "longbow")*30)%1.2*2-1.2)*(0.25/1.2));
_fcrantennafor = (_fcrDir * 0.48) + 0.5;
if (_fcrantennafor > 0.56) then {
    _fcrantennafor = 0.56;
};
if (_fcrantennafor < 0.44) then {
    _fcrantennafor = 0.44;
};
if !(_heli animationPhase "fcr_enable" == 1) then {
    _fcrantennafor = -100;
};
_sensorposx = (_heli animationphase "tads_tur") * -0.025;
_sensorposy = (_heli animationphase "tads") * -0.015;
if (_sensorposy < 0) then {
    _sensorposy = (_heli animationphase "tads") * -0.026;
};
_fcrdir = (_fcrDir * 1.6) + 0.5;
if (_fcrdir > 0.7) then {
    _fcrdir = 0.7;
};
if (_fcrdir < 0.3) then {
    _fcrdir = 0.3;
};
if !(_heli animationPhase "fcr_enable" == 1) then {
    _fcrdir = -100;
};
_slip = (fza_ah64_slip * 0.5) + 0.492;
if (_slip > 0.54) then {
    _slip = 0.54;
};
if (_slip < 0.44) then {
    _slip = 0.44;
};

_vvect = [_heli] call fza_fnc_velocityVector;
_vertvect = ((_vvect select 0) * -1) + 0.5;
_horvect = (_vvect select 1) + 0.485;

if (_vertvect > 0.65) then {
    _vertvect = 0.65;
};
if (_vertvect < 0.35) then {
    _vertvect = 0.35;
};
if (_horvect > 0.65) then {
    _horvect = 0.65;
};
if (_horvect < 0.35) then {
    _horvect = 0.35;
};

if (speed _heli < 5) then {
    _vertvect = -100;
    _horvect = -100;
};
private _was = _heli getVariable "fza_ah64_was";
if (_was == WAS_WEAPON_MSL) then {
    _weapon = "MSL";
    if (isManualFire _heli) then {
        _weapon = "PMSL";
    };
    private ["_mistargPos", "_radar"];
    if (_heli getVariable "fza_ah64_selectedMissile" == "fza_agm114l_wep") then {
        _mistargPos = fza_ah64_mycurrenttarget;
        _radar = true;
    } else {
        _mistargPos = _heli getVariable "fza_ah64_currentlase";
        _radar = false;
    };
    _scPos = worldToScreen(getpos _mistargPos);
    if (count _scpos < 1) then {
        _scPos = [-100, -100];
    } else {
        _scPos = [
            [_scPos # 0, 0, 1] call BIS_fnc_clamp,
            [_scPos # 1, 0, 1] call BIS_fnc_clamp
        ];
    };
    _targpos = _scPos;

    if (isNull _mistargPos) then {
        ((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 131) ctrlSetText "";
    } else {
        _terrainobscure = terrainIntersectasl[[(getPosASL _heli select 0) + ((sin getdir _heli) * 6), (getPosASL _heli select 1) + ((cos getdir _heli) * 6), (getPosASL _heli select 2)], [(getPosASL _mistargPos select 0), (getPosASL _mistargPos select 1), (getPosASL _mistargPos select 2) + 1]];
        _obscureobjs = lineIntersectsWith[[(getPosASL _heli select 0) + ((sin getdir _heli) * 6), (getPosASL _heli select 1) + ((cos getdir _heli) * 6), (getPosASL _heli select 2)], getPosASL _mistargPos, _heli, _mistargPos];

        _distOffAxis = abs ([[_heli, getPos _heli # 0, getPos _heli # 1, getPos _mistargPos # 0, getPos _mistargPos # 1] call fza_fnc_relativeDirection] call CBA_fnc_simplifyAngle180);
        
        if (!_terrainobscure && (_obscureobjs - nearestObjects [getpos _mistargPos, ["All"], 10]) isEqualTo [] && _distOffAxis < 40 && _heli ammo (_heli getVariable "fza_ah64_selectedMissile") > 0) then {
            _w = 0.2202;
            _h = 0.3;
            _apx = 0.108;
            _apy = 0.15;
            if (_distOffAxis < 20) then {
                ((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 131) ctrlSetText "\fza_ah64_us\tex\HDU\ah64_lobl.paa";
            } else {
                ((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 131) ctrlSetText "\fza_ah64_us\tex\HDU\ah64_lobl_nolos.paa";
            };
        } else {
            _w = 0.0734;
            _h = 0.1;
            _apx = 0.036;
            _apy = 0.05;
            _allowedDistOffAxis = [6.5, 20] select _radar;
            if (_distOffAxis < _allowedDistOffAxis) then {
                ((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 131) ctrlSetText "\fza_ah64_us\tex\HDU\f16_rsc_jhmcs_targ.paa";
            } else {
                ((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 131) ctrlSetText "\fza_ah64_us\tex\HDU\f16_rsc_jhmcs_targ_nolos.paa";
            };
        };
    };

    if (isManualFire _heli) then {
        _weapon = "PMSL";
    };
    switch (_heli getVariable "fza_ah64_hellfireTrajectory") do {
        case "dir": {
            _weaponstate = "DIR-MAN";
        };
        case "lo": {
            _weaponstate = "LO-MAN";
        };
        case "hi": {
            _weaponstate = "HI-MAN";
        };
    };
    _missileTOF = _heli getVariable "fza_ah64_shotmissile_list" select {!isNull _x && alive _x && !(isnull missileTarget (_x))};
    
    if (count _missileTOF > 0) then {
        _tof = (missileTarget (_missileTOF # 0) distance (_missileTOF # 0)) / 350;
        _weaponstate = _weaponstate + format[" TOF=%1", round _tof];
    };
} else {
    ((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 131) ctrlSetText "";
};

if (_was == WAS_WEAPON_RKT) then {
    //RKT FIX TADS AND/OR IHADSS DISPLAY
    _w = 0.0734*2;
    _h = 0.1*2;
    _apx = 0.036*2;
    _apy = 0.3/3;
    _weapon = "RKT";
    if (isManualFire _heli) then {
        _weapon = "PRKT";
    };
    _ammo = getText (configFile >> "CfgWeapons" >> (_heli getVariable "fza_ah64_selectedRocket") >> "fza_ammoType");
    _rocketcode = getText (configFile >> "CfgAmmo" >> _ammo >> "fza_shortCode");
    _weaponstate = format["%1 NORM %2", _rocketcode, _heli ammo(_heli getVariable "fza_ah64_selectedRocket")];
    ((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 131) ctrlSetText
    (["\fza_ah64_us\tex\HDU\ah64_rkt.paa", "\fza_ah64_us\tex\HDU\ah64_rkt_fxd"] select ([_heli] call fza_fnc_targetingGetSightSelect == 3));
    if (_sight == 3) then { //FXD
        _scPos = worldToScreen (_heli modelToWorldVisual [0, 1000, 0]);
        if (_scpos isEqualTo []) then {
            _scpos = [-100, -100];
        };
    } else {;
        _scPos = [ 0.5 - deg (_heli animationPhase "tads_tur")*3/64/4, 0.5-deg (_heli animationPhase "tads")*3/64/4];
    };
};

if (_was == WAS_WEAPON_NONE) then {
    _weapon = "";
    _weaponstate = "";
};

if (_was == WAS_WEAPON_GUN && player == driver _heli) then {
    ((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 131) ctrlSetText
        (["\fza_ah64_us\tex\HDU\ah64_gun.paa", "\fza_ah64_us\tex\HDU\ah64_gun_fxd.paa"] select ([_heli] call fza_fnc_targetingGetSightSelect == 3));
};

if (_was == WAS_WEAPON_GUN) then {
    _w = 0.0734;
    _h = 0.1;
    _apx = 0.036;
    _apy = 0.05;
    _angley = -0.5 * (_heli animationphase "maingun");
    _angley = _angley + 0.5;
    _anglex = -0.5 * (_heli animationphase "mainturret");
    _anglex = _anglex + 0.5;
    _gunpoint = worldtoscreen(_heli modelToWorldVisual[((sin(deg(_heli animationphase "mainturret") * (-1))) * (cos(deg(_heli animationphase "maingun"))) * 500), (((cos(deg(_heli animationphase "maingun")))) * (cos(deg(_heli animationphase "mainturret") * (-1))) * 500) + 4, ((sin(deg(_heli animationphase "maingun"))) * 500) - 1]);
    if (count _gunpoint < 1) then {
        _gunpoint = [0.5, 0.5];
    };
    _scPos = [(_gunpoint select 0), (_gunpoint select 1)];
    _weapon = "GUN";

    if (isManualFire _heli) then {
        _weapon = "PGUN";
    };

    _weaponstate = format["ROUNDS %1", _heli ammo "fza_m230"];
};

//CSCOPE
_targetsToDraw = ([_heli, fza_ah64_Cscopelist] call fza_fnc_targetingFilterType);
if (_heli getVariable "fza_ah64_fcrcscope") then {
    _num = 190; {
        if (_num > 205) exitwith {};
        _coords = worldtoscreen(getpos _x);
        _type = "\fza_ah64_US\tex\ICONS\ah64_hc_pfz.paa";

        _adaunit = [_x] call fza_fnc_targetIsADA;

        if (_x isKindOf "helicopter") then {
            _type = "\fza_ah64_US\tex\ICONS\ah64_hc_pfz.paa";
        };
        if (_x isKindOf "plane") then {
            _type = "\fza_ah64_US\tex\ICONS\ah64_ac.paa";
        };
        if (_x isKindOf "tank") then {
            _type = "\fza_ah64_US\tex\ICONS\ah64_tnk_pfz.paa";
        };
        if (_x isKindOf "car") then {
            _type = "\fza_ah64_US\tex\ICONS\ah64_whl_pfz.paa";
        };
        if (_adaunit) then {
            _type = "\fza_ah64_US\tex\ICONS\ah64_ada_pfz.paa";
        };
        if (!(_x isKindOf "car" || _x isKindOf "tank" || _x isKindOf "plane" || _x isKindOf "helicopter" || _adaunit)) then {
            _type = "\fza_ah64_US\tex\ICONS\ah64_gen_pfz.paa";
        };

        if (count _coords < 1) then {
            _coords = [-100, -100];
        };
        ((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl _num) ctrlSetText _type;
        ((uiNameSpace getVariable "fza_ah64_raddisp")displayCtrl _num) ctrlSetPosition (_coords call fza_fnc_compensateSafezone);
        ((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl _num) ctrlCommit 0;
        _num = _num + 1;
    }
    foreach _targetsToDraw;

    if (_num > (count _targetsToDraw + 189)) then {
        while {
            (_num < 206)
        }
        do {
            _coords = [-100, -100];
            ((uiNameSpace getVariable "fza_ah64_raddisp")displayCtrl _num) ctrlSetPosition (_coords call fza_fnc_compensateSafezone);
            ((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl _num) ctrlCommit 0;
            _num = _num + 1;
        };
    };

} else {
    _num = 190;
    while {
        (_num < 206)
    }
    do {
        _coords = [-100, -100];
        ((uiNameSpace getVariable "fza_ah64_raddisp")displayCtrl _num) ctrlSetPosition (_coords call fza_fnc_compensateSafezone);
        ((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl _num) ctrlCommit 0;
        _num = _num + 1;
    };
};

//IHADSS FLIGHT MODES

if (((_heli getVariable "fza_ah64_hmdfsmode") != "trans" && (_heli getVariable "fza_ah64_hmdfsmode") != "cruise") || (_headsdown)) then {
    _waypointcode = "";
    _gspdcode = "";
    _horvect = -100;
    _vertvect = -100;
};

if (_heli getVariable "fza_ah64_hmdfsmode" != "cruise") then {
    _baraltft = "";
};
_bobcoords = [-100, -100];
if (_heli getVariable "fza_ah64_hmdfsmode" == "bobup") then {

    _thetabob = (360 + ((_heli getVariable "fza_ah64_bobhdg") - direction _heli)) Mod 360;

    if (_thetabob >= 180) then {
        _thetabob = _thetabob - 360;
    } else {
        _thetabob = _thetabob;
    };

    _curwpdir = _thetabob;

    _bobcoordsx = (((_heli getVariable "fza_ah64_bobpos" select 0) - (getposasl _heli select 0)) * 0.017) + 0.480775;
    if (_bobcoordsx > 0.7) then {
        _bobcoordsx = 0.7;
    };
    if (_bobcoordsx < 0.3) then {
        _bobcoordsx = 0.3;
    };
    _bobcoordsy = (((getposasl _heli select 1) - (_heli getVariable "fza_ah64_bobpos" select 1)) * 0.017) + 0.475;
    if (_bobcoordsy > 0.7) then {
        _bobcoordsy = 0.7;
    };
    if (_bobcoordsy < 0.3) then {
        _bobcoordsy = 0.3;
    };
    _bobcoords = [_bobcoordsx, _bobcoordsy];
};

///HAD INHIBIT MESSAGES

if (fza_ah64_burst >= _heli getVariable "fza_ah64_burst_limit" && currentweapon _heli == "fza_m230") then {
    _heli selectweapon "fza_burstlimiter";
};

if (fza_ah64_gunheat > 0) then {
    fza_ah64_gunheat = fza_ah64_gunheat - 0.05;
};

if (fza_ah64_gunheat < 0) then {
    fza_ah64_gunheat = 0;
    fza_ah64_burst = 0;
};

if (time - fza_ah64_firekeypressed > 1 && currentweapon _heli == "fza_burstlimiter") then {
    fza_ah64_burst = 0;
    _heli selectWeapon "fza_m230";
};

if (_heli getVariable "fza_ah64_weaponInhibited" != "") then {
    _safemessage = _heli getVariable "fza_ah64_weaponInhibited";
};

//SET NUMBERS AND IDC
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 121) ctrlSetText _sensor + _targrange;
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 122) ctrlSetText _sensxm;

//VISION MODE CPG HEADSDOWN
if (cameraView == "GUNNER" && player == gunner _heli) then {
    private _visionTxt = "";

    if (isNil "_a3ti_vis") then {
        if (currentVisionMode player == 0) then {
            _visionTxt = "DTV";
        } else {
            _visionTxt = "FLIR";
        };
    } else {
        //_visionTxt = _a3ti_vis;
		_visionTxt = "FLIR";
    };

    ((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 123) ctrlSetText _visionTxt

} else {
    ((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 123) ctrlSetText _collective + "%";
};

if !(_heli animationPhase "fcr_enable" == 1) then {
    _acqihadss = "";
};

((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 124) ctrlSetText _speedkts;
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 125) ctrlSetText _radaltft;
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 126) ctrlSetText _weapon;
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 127) ctrlSetText _weaponstate;
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 128) ctrlSetText _safemessage;
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 129) ctrlSetText _waypointcode;
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 184) ctrlSetText _gspdcode;
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 188) ctrlSetText _baraltft;
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 804) ctrlSetText _acqihadss;
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 131) ctrlSetPosition[(_scPos select 0) - (_apx), (_scPos select 1) - (_apy), _w, _h];
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 131) ctrlCommit 0;
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 132) ctrlSetPosition ([(_targpos select 0)-0.036,(_targpos select 1)-0.05] call fza_fnc_compensateSafezone);
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 132) ctrlCommit 0;
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 133) ctrlSetPosition[(_sensorposx) + 0.4875, (_sensorposy) + 0.735];
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 133) ctrlCommit 0;
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 137) ctrlSetPosition[_fcrdir - 0.01, 0.31];
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 137) ctrlCommit 0;

private _headTrackerPos = worldToScreen (_heli modelToWorldVisual [0, 1000000, 0]);
if (_headTrackerPos isEqualTo []) then {
    _headTrackerPos = [-100, -100];
} else {
    _headTrackerPos = ([-0.019225, -0.025] vectorAdd _headTrackerPos) call fza_fnc_compensateSafezone;
};

((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 182) ctrlSetPosition (_headTrackerPos);
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 182) ctrlCommit 0;
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 183) ctrlSetPosition[_fcrantennafor, 0.72];
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 183) ctrlCommit 0;
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 185) ctrlSetPosition[_horvect, _vertvect];
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 185) ctrlCommit 0;
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 186) ctrlSetPosition[_slip, 0.695];
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 186) ctrlCommit 0;
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 187) ctrlSetPosition _bobcoords;
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 187) ctrlCommit 0;
_radalt = (getpos _heli select 2) * 0.0042;
if (_radalt > 0.26) then {
    _radalt = 0;
};
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 136) ctrlSetPosition[0.709, (0.6321 - _radalt), 0.01, _radalt];
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 136) ctrlCommit 0;
_fpm = (velocity _heli select 2) * 0.0255;
_fpm = [_fpm, -0.13, 0.13] call BIS_fnc_clamp;

((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 135) ctrlSetPosition[0.678, 0.49 - _fpm];
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 135) ctrlCommit 0;
_pbvar = _heli call fza_fnc_getPitchBank;

_pbvar set [0, _pbvar # 0 + 5];

//HUD HORIZON OBJECTS

if ((_heli getVariable "fza_ah64_hmdfsmode" != "trans" && _heli getVariable "fza_ah64_hmdfsmode" != "cruise") || (_headsdown)) then {
    {
        ((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl _x) ctrlSetPosition[100, 10, 100];
    }
    foreach[250, 251, 252, 253, 254, 255, 256, 257, 258, 259, 260, 261, 262, 263, 264, 265, 266, 267, 268, 269];
} else {
    if (_heli getVariable "fza_ah64_hmdfsmode" == "trans") then {
        [269, (_pbvar select 0), (_pbvar select 1)] call _autohide;
    } else {
        ((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 269) ctrlSetPosition[100, 10, 100];
    };

    if (_heli getVariable "fza_ah64_hmdfsmode" == "cruise") then {
        [250, (_pbvar select 0), (_pbvar select 1)] call _autohide;
        [251, (_pbvar select 0) - 10, (_pbvar select 1)] call _autohide;
        [252, (_pbvar select 0) - 20, (_pbvar select 1)] call _autohide;
        [253, (_pbvar select 0) - 30, (_pbvar select 1)] call _autohide;
        [254, (_pbvar select 0) - 40, (_pbvar select 1)] call _autohide;
        [255, (_pbvar select 0) - 50, (_pbvar select 1)] call _autohide;
        [256, (_pbvar select 0) - 60, (_pbvar select 1)] call _autohide;
        [257, (_pbvar select 0) - 70, (_pbvar select 1)] call _autohide;
        [258, (_pbvar select 0) - 80, (_pbvar select 1)] call _autohide;
        [259, (_pbvar select 0) - 90, (_pbvar select 1)] call _autohide;
        [260, (_pbvar select 0) + 10, (_pbvar select 1)] call _autohide;
        [261, (_pbvar select 0) + 20, (_pbvar select 1)] call _autohide;
        [262, (_pbvar select 0) + 30, (_pbvar select 1)] call _autohide;
        [263, (_pbvar select 0) + 40, (_pbvar select 1)] call _autohide;
        [264, (_pbvar select 0) + 50, (_pbvar select 1)] call _autohide;
        [265, (_pbvar select 0) + 60, (_pbvar select 1)] call _autohide;
        [266, (_pbvar select 0) + 70, (_pbvar select 1)] call _autohide;
        [267, (_pbvar select 0) + 80, (_pbvar select 1)] call _autohide;
        [268, (_pbvar select 0) + 90, (_pbvar select 1)] call _autohide;
    } else {
        {
            ((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl _x) ctrlSetPosition[100, 10, 100];
        }
        foreach[250, 251, 252, 253, 254, 255, 256, 257, 258, 259, 260, 261, 262, 263, 264, 265, 266, 267, 268];
    };

    _pitch = 0;
    _bank = (_pbvar select 1) * -1;

    _dir = 0;
    _vecdx = sin(_dir) * cos(_pitch);
    _vecdy = cos(_dir) * cos(_pitch);
    _vecdz = sin(_pitch);

    _vecux = cos(_dir) * cos(_pitch) * sin(_bank);
    _vecuy = sin(_dir) * cos(_pitch) * sin(_bank);
    _vecuz = cos(_pitch) * cos(_bank); {
        ((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl _x) ctrlSetModelDirAndUp[[_vecdx, _vecdy, _vecdz], [_vecux, _vecuy, _vecuz]];
    }
    foreach[250, 251, 252, 253, 254, 255, 256, 257, 258, 259, 260, 261, 262, 263, 264, 265, 266, 267, 268, 269];
};

//HUD HEADINGS

_helidir = (direction _heli);
_10dir = _helidir - 10;
_20dir = _helidir - 20;
_30dir = _helidir - 30;
_40dir = _helidir - 40;
_50dir = _helidir - 50;
_60dir = _helidir - 60;
_70dir = _helidir - 70;
_80dir = _helidir - 80;
_90dir = _helidir - 90;
_100dir = _helidir - 100;
_110dir = _helidir - 110;
_120dir = _helidir - 120;
_130dir = _helidir - 130;
_140dir = _helidir - 140;
_150dir = _helidir - 150;
_160dir = _helidir - 160;
_170dir = _helidir - 170;
_180dir = _helidir - 180;
_190dir = _helidir - 190;
_200dir = _helidir - 200;
_210dir = _helidir - 210;
_220dir = _helidir - 220;
_230dir = _helidir - 230;
_240dir = _helidir - 240;
_250dir = _helidir - 250;
_260dir = _helidir - 260;
_270dir = _helidir - 270;
_280dir = _helidir - 280;
_290dir = _helidir - 290;
_300dir = _helidir - 300;
_310dir = _helidir - 310;
_320dir = _helidir - 320;
_330dir = _helidir - 330;
_340dir = _helidir - 340;
_350dir = _helidir - 350;
if (_10dir < 0) then {
    _10dir = _10dir + 360;
};
if (_20dir < 0) then {
    _20dir = _20dir + 360;
};
if (_30dir < 0) then {
    _30dir = _30dir + 360;
};
if (_40dir < 0) then {
    _40dir = _40dir + 360;
};
if (_50dir < 0) then {
    _50dir = _50dir + 360;
};
if (_60dir < 0) then {
    _60dir = _60dir + 360;
};
if (_70dir < 0) then {
    _70dir = _70dir + 360;
};
if (_80dir < 0) then {
    _80dir = _80dir + 360;
};
if (_90dir < 0) then {
    _90dir = _90dir + 360;
};
if (_100dir < 0) then {
    _100dir = _100dir + 360;
};
if (_110dir < 0) then {
    _110dir = _110dir + 360;
};
if (_120dir < 0) then {
    _120dir = _120dir + 360;
};
if (_130dir < 0) then {
    _130dir = _130dir + 360;
};
if (_140dir < 0) then {
    _140dir = _140dir + 360;
};
if (_150dir < 0) then {
    _150dir = _150dir + 360;
};
if (_160dir < 0) then {
    _160dir = _160dir + 360;
};
if (_170dir < 0) then {
    _170dir = _170dir + 360;
};
if (_180dir < 0) then {
    _180dir = _180dir + 360;
};
if (_190dir < 0) then {
    _190dir = _190dir + 360;
};
if (_200dir < 0) then {
    _200dir = _200dir + 360;
};
if (_210dir < 0) then {
    _210dir = _210dir + 360;
};
if (_220dir < 0) then {
    _220dir = _220dir + 360;
};
if (_230dir < 0) then {
    _230dir = _230dir + 360;
};
if (_240dir < 0) then {
    _240dir = _240dir + 360;
};
if (_250dir < 0) then {
    _250dir = _250dir + 360;
};
if (_260dir < 0) then {
    _260dir = _260dir + 360;
};
if (_270dir < 0) then {
    _270dir = _270dir + 360;
};
if (_280dir < 0) then {
    _280dir = _280dir + 360;
};
if (_290dir < 0) then {
    _290dir = _290dir + 360;
};
if (_300dir < 0) then {
    _300dir = _300dir + 360;
};
if (_310dir < 0) then {
    _310dir = _310dir + 360;
};
if (_320dir < 0) then {
    _320dir = _320dir + 360;
};
if (_330dir < 0) then {
    _330dir = _330dir + 360;
};
if (_340dir < 0) then {
    _340dir = _340dir + 360;
};
if (_350dir < 0) then {
    _350dir = _350dir + 360;
};

// CAMERA HEADINGS FOR GUNNER

if (cameraView == "GUNNER" && player == gunner _heli) then {
    _tadsdir = (deg(_heli animationphase "tads_tur") * -1);
    _curwpdir = _tadsdir;
};
private _alternatesensorpan = (if (player == gunner _heli) then {(_heli animationPhase "pnvs")*120} else {-deg (_heli animationSourcePhase "tads_tur")}); 
private _alternatesensortilt = if (player == gunner _heli) then {linearConversion [-1, 1, (_heli animationPhase "pnvs_vert"), -45, 20]} else {deg (_heli animationSourcePhase "tads")}; 

private _modelAlternateSensorVect = [sin _alternatesensorpan, cos _alternatesensorpan, sin _alternatesensortilt];
private _worldAlternateSensorVect = (_heli modelToWorld _modelAlternateSensorVect) vectorDiff (_heli modelToWorld [0,0,0]);
private _alternatesensordir = (_worldAlternateSensorvect # 0) atan2(_worldAlternateSensorvect # 1);

_alternatesensordir = _alternatesensordir - direction _heli;

if (_alternatesensordir > 180) then {
    _alternatesensordir = _alternatesensordir - 360;
};
if (_alternatesensordir < -180) then {
    _alternatesensordir = _alternatesensordir + 360;
};

private _alternatesensor = (_alternatesensordir * (1 / 360)) + 0.5;

_chevmark = (_curwpdir * (1 / 360)) + 0.5;
_360mark = (_helidir * (-1 / 360)) + 1.5;
_10mark = (_10dir * (-1 / 360)) + 1.5;
_20mark = (_20dir * (-1 / 360)) + 1.5;
_30mark = (_30dir * (-1 / 360)) + 1.5;
_40mark = (_40dir * (-1 / 360)) + 1.5;
_50mark = (_50dir * (-1 / 360)) + 1.5;
_60mark = (_60dir * (-1 / 360)) + 1.5;
_70mark = (_70dir * (-1 / 360)) + 1.5;
_80mark = (_80dir * (-1 / 360)) + 1.5;
_90mark = (_90dir * (-1 / 360)) + 1.5;
_100mark = (_100dir * (-1 / 360)) + 1.5;
_110mark = (_110dir * (-1 / 360)) + 1.5;
_120mark = (_120dir * (-1 / 360)) + 1.5;
_130mark = (_130dir * (-1 / 360)) + 1.5;
_140mark = (_140dir * (-1 / 360)) + 1.5;
_150mark = (_150dir * (-1 / 360)) + 1.5;
_160mark = (_160dir * (-1 / 360)) + 1.5;
_170mark = (_170dir * (-1 / 360)) + 1.5;
_180mark = (_180dir * (-1 / 360)) + 1.5;
_190mark = (_190dir * (-1 / 360)) + 1.5;
_200mark = (_200dir * (-1 / 360)) + 1.5;
_210mark = (_210dir * (-1 / 360)) + 1.5;
_220mark = (_220dir * (-1 / 360)) + 1.5;
_230mark = (_230dir * (-1 / 360)) + 1.5;
_240mark = (_240dir * (-1 / 360)) + 1.5;
_250mark = (_250dir * (-1 / 360)) + 1.5;
_260mark = (_260dir * (-1 / 360)) + 1.5;
_270mark = (_270dir * (-1 / 360)) + 1.5;
_280mark = (_280dir * (-1 / 360)) + 1.5;
_290mark = (_290dir * (-1 / 360)) + 1.5;
_300mark = (_300dir * (-1 / 360)) + 1.5;
_310mark = (_310dir * (-1 / 360)) + 1.5;
_320mark = (_320dir * (-1 / 360)) + 1.5;
_330mark = (_330dir * (-1 / 360)) + 1.5;
_340mark = (_340dir * (-1 / 360)) + 1.5;
_350mark = (_350dir * (-1 / 360)) + 1.5;

if (_alternatesensor > 0.7) then {
    _alternatesensor = 0.7;
};
if (_alternatesensor < 0.3) then {
    _alternatesensor = 0.3;
};
if (_chevmark > 0.7) then {
    _chevmark = 0.7;
};
if (_chevmark < 0.3) then {
    _chevmark = 0.3;
};
if (_360mark > 0.7) then {
    _360mark = _360mark - 1;
};
if (_360mark < 0.3) then {
    _360mark = _360mark - 100;
};
if (_10mark > 0.7) then {
    _10mark = _10mark - 1;
};
if (_10mark < 0.3) then {
    _10mark = _10mark - 100;
};
if (_20mark > 0.7) then {
    _20mark = _20mark - 1;
};
if (_20mark < 0.3) then {
    _20mark = _20mark - 100;
};
if (_30mark > 0.7) then {
    _30mark = _30mark - 1;
};
if (_30mark < 0.3) then {
    _30mark = _30mark - 100;
};
if (_40mark > 0.7) then {
    _40mark = _40mark - 1;
};
if (_40mark < 0.3) then {
    _40mark = _40mark - 100;
};
if (_50mark > 0.7) then {
    _50mark = _50mark - 1;
};
if (_50mark < 0.3) then {
    _50mark = _50mark - 100;
};
if (_60mark > 0.7) then {
    _60mark = _60mark - 1;
};
if (_60mark < 0.3) then {
    _60mark = _60mark - 100;
};
if (_70mark > 0.7) then {
    _70mark = _70mark - 1;
};
if (_70mark < 0.3) then {
    _70mark = _70mark - 100;
};
if (_80mark > 0.7) then {
    _80mark = _80mark - 1;
};
if (_80mark < 0.3) then {
    _80mark = _80mark - 100;
};
if (_90mark > 0.7) then {
    _90mark = _90mark - 1;
};
if (_90mark < 0.3) then {
    _90mark = _90mark - 100;
};
if (_100mark > 0.7) then {
    _100mark = _100mark - 1;
};
if (_100mark < 0.3) then {
    _100mark = _100mark - 100;
};
if (_110mark > 0.7) then {
    _110mark = _110mark - 1;
};
if (_110mark < 0.3) then {
    _110mark = _110mark - 100;
};
if (_120mark > 0.7) then {
    _120mark = _120mark - 1;
};
if (_120mark < 0.3) then {
    _120mark = _120mark - 100;
};
if (_130mark > 0.7) then {
    _130mark = _130mark - 1;
};
if (_130mark < 0.3) then {
    _130mark = _130mark - 100;
};
if (_140mark > 0.7) then {
    _140mark = _140mark - 1;
};
if (_140mark < 0.3) then {
    _140mark = _140mark - 100;
};
if (_150mark > 0.7) then {
    _150mark = _150mark - 1;
};
if (_150mark < 0.3) then {
    _150mark = _150mark - 100;
};
if (_160mark > 0.7) then {
    _160mark = _160mark - 1;
};
if (_160mark < 0.3) then {
    _160mark = _160mark - 100;
};
if (_170mark > 0.7) then {
    _170mark = _170mark - 1;
};
if (_170mark < 0.3) then {
    _170mark = _170mark - 100;
};
if (_180mark > 0.7) then {
    _180mark = _180mark - 1;
};
if (_180mark < 0.3) then {
    _180mark = _180mark - 100;
};
if (_190mark > 0.7) then {
    _190mark = _190mark - 1;
};
if (_190mark < 0.3) then {
    _190mark = _190mark - 100;
};
if (_200mark > 0.7) then {
    _200mark = _200mark - 1;
};
if (_200mark < 0.3) then {
    _200mark = _200mark - 100;
};
if (_210mark > 0.7) then {
    _210mark = _210mark - 1;
};
if (_210mark < 0.3) then {
    _210mark = _210mark - 100;
};
if (_220mark > 0.7) then {
    _220mark = _220mark - 1;
};
if (_220mark < 0.3) then {
    _220mark = _220mark - 100;
};
if (_230mark > 0.7) then {
    _230mark = _230mark - 1;
};
if (_230mark < 0.3) then {
    _230mark = _230mark - 100;
};
if (_240mark > 0.7) then {
    _240mark = _240mark - 1;
};
if (_240mark < 0.3) then {
    _240mark = _240mark - 100;
};
if (_250mark > 0.7) then {
    _250mark = _250mark - 1;
};
if (_250mark < 0.3) then {
    _250mark = _250mark - 100;
};
if (_260mark > 0.7) then {
    _260mark = _260mark - 1;
};
if (_260mark < 0.3) then {
    _260mark = _260mark - 100;
};
if (_270mark > 0.7) then {
    _270mark = _270mark - 1;
};
if (_270mark < 0.3) then {
    _270mark = _270mark - 100;
};
if (_280mark > 0.7) then {
    _280mark = _280mark - 1;
};
if (_280mark < 0.3) then {
    _280mark = _280mark - 100;
};
if (_290mark > 0.7) then {
    _290mark = _290mark - 1;
};
if (_290mark < 0.3) then {
    _290mark = _290mark - 100;
};
if (_300mark > 0.7) then {
    _300mark = _300mark - 1;
};
if (_300mark < 0.3) then {
    _300mark = _300mark - 100;
};
if (_310mark > 0.7) then {
    _310mark = _310mark - 1;
};
if (_310mark < 0.3) then {
    _310mark = _310mark - 100;
};
if (_320mark > 0.7) then {
    _320mark = _320mark - 1;
};
if (_320mark < 0.3) then {
    _320mark = _320mark - 100;
};
if (_330mark > 0.7) then {
    _330mark = _330mark - 1;
};
if (_330mark < 0.3) then {
    _330mark = _330mark - 100;
};
if (_340mark > 0.7) then {
    _340mark = _340mark - 1;
};
if (_340mark < 0.3) then {
    _340mark = _340mark - 100;
};
if (_350mark > 0.7) then {
    _350mark = _350mark - 1;
};
if (_350mark < 0.3) then {
    _350mark = _350mark - 100;
};
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 207) ctrlSetPosition[_alternatesensor - 0.025, 0.31];
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 134) ctrlSetPosition[_chevmark - 0.025, 0.31];
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 146) ctrlSetPosition[_360mark - 0.02, 0.27];
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 147) ctrlSetPosition[_30mark - 0.02, 0.27];
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 148) ctrlSetPosition[_60mark - 0.02, 0.27];
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 149) ctrlSetPosition[_90mark - 0.02, 0.27];
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 150) ctrlSetPosition[_120mark - 0.02, 0.27];
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 151) ctrlSetPosition[_150mark - 0.02, 0.27];
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 152) ctrlSetPosition[_180mark - 0.02, 0.27];
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 153) ctrlSetPosition[_210mark - 0.02, 0.27];
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 154) ctrlSetPosition[_240mark - 0.02, 0.27];
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 155) ctrlSetPosition[_270mark - 0.02, 0.27];
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 156) ctrlSetPosition[_300mark - 0.02, 0.27];
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 157) ctrlSetPosition[_330mark - 0.02, 0.27];
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 158) ctrlSetPosition[_10mark, 0.29];
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 159) ctrlSetPosition[_20mark, 0.29];
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 160) ctrlSetPosition[_40mark, 0.29];
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 161) ctrlSetPosition[_50mark, 0.29];
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 162) ctrlSetPosition[_70mark, 0.29];
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 163) ctrlSetPosition[_80mark, 0.29];
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 164) ctrlSetPosition[_100mark, 0.29];
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 165) ctrlSetPosition[_110mark, 0.29];
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 166) ctrlSetPosition[_130mark, 0.29];
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 167) ctrlSetPosition[_140mark, 0.29];
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 168) ctrlSetPosition[_160mark, 0.29];
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 169) ctrlSetPosition[_170mark, 0.29];
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 170) ctrlSetPosition[_190mark, 0.29];
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 171) ctrlSetPosition[_200mark, 0.29];
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 172) ctrlSetPosition[_220mark, 0.29];
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 173) ctrlSetPosition[_230mark, 0.29];
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 174) ctrlSetPosition[_250mark, 0.29];
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 175) ctrlSetPosition[_260mark, 0.29];
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 176) ctrlSetPosition[_280mark, 0.29];
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 177) ctrlSetPosition[_290mark, 0.29];
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 178) ctrlSetPosition[_310mark, 0.29];
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 179) ctrlSetPosition[_320mark, 0.29];
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 180) ctrlSetPosition[_340mark, 0.29];
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 181) ctrlSetPosition[_350mark, 0.29];
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 207) ctrlCommit 0;
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 134) ctrlCommit 0;
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 146) ctrlCommit 0;
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 147) ctrlCommit 0;
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 148) ctrlCommit 0;
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 149) ctrlCommit 0;
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 150) ctrlCommit 0;
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 151) ctrlCommit 0;
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 152) ctrlCommit 0;
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 153) ctrlCommit 0;
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 154) ctrlCommit 0;
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 155) ctrlCommit 0;
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 156) ctrlCommit 0;
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 157) ctrlCommit 0;
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 158) ctrlCommit 0;
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 159) ctrlCommit 0;
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 160) ctrlCommit 0;
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 161) ctrlCommit 0;
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 162) ctrlCommit 0;
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 163) ctrlCommit 0;
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 164) ctrlCommit 0;
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 165) ctrlCommit 0;
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 166) ctrlCommit 0;
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 167) ctrlCommit 0;
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 168) ctrlCommit 0;
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 169) ctrlCommit 0;
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 170) ctrlCommit 0;
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 171) ctrlCommit 0;
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 172) ctrlCommit 0;
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 173) ctrlCommit 0;
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 174) ctrlCommit 0;
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 175) ctrlCommit 0;
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 176) ctrlCommit 0;
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 177) ctrlCommit 0;
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 178) ctrlCommit 0;
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 179) ctrlCommit 0;
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 180) ctrlCommit 0;
((uiNameSpace getVariable "fza_ah64_raddisp") displayCtrl 181) ctrlCommit 0;

if (vehicle player != _heli && !(vehicle player isKindOf "fza_ah64base") || !(alive _heli) && !(vehicle player isKindOf "fza_ah64base") || !(alive player)) then {
    1 cuttext["", "PLAIN"];
    2 cuttext["", "PLAIN"];
    3 cuttext["", "PLAIN"];
    4 cuttext["", "PLAIN"];
    fza_ah64_bweff ppEffectEnable false;
};
