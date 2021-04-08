/* ----------------------------------------------------------------------------
Function: fza_fnc_sfmplusStabilator

Description:

Parameters:
	_heli - The apache helicopter to get information from [Unit].

Returns:


Examples:


Author:
	BradMick
---------------------------------------------------------------------------- */
params ["_heli", "_deltaTime"];

private _collOut = _heli getVariable "fza_ah64d_collectiveOutput";

private _colorRed = [1,0,0,1]; private _colorGreen = [0,1,0,1]; private _colorBlue = [0,0,1,1]; private _colorWhite = [1,1,1,1];

DRAW_LINE = {
	params ["_heli", "_p1", "_p2", "_col"];
	drawLine3D [_heli modelToWorldVisual _p1, _heli modelToWorldVisual _p2, _col];
};

private _objCtr  = _heli selectionPosition ["modelCenter", "Memory"];
private _stabPos = _heli getVariable "fza_ah64d_stabPos";
private _stabPvt = _objCtr vectorAdd _stabPos;

private _stabOutputTable = [[15.43, -25.0],   //30kts
							[25.72, -13.5],   //50kts
							[36.01, -3.9],    //70kts
							[46.30, -6.9],    //90kts
							[56.58, -7.8],    //110kts
							[61.73, -11.0],   //120kts
							[66.87, -6.0],    //130kts
							[77.16,  5.0],    //150kts
							[92.60,  5.0]];   //180kts

private _V_mps = abs vectorMagnitude [velocity _heli select 0, velocity _heli select 1];
private _theta = [_stabOutputTable, _V_mps] call fza_fnc_linearInterp select 1;
//Stab coords    |     |
//               |-----|
//    A-------------H-------------B
//    |             |             |
//    E-------------G-------------F
//    |             |             |
//    D-------------I-------------C
private _width  = _heli getVariable "fza_ah64d_stabWidth";
private _length = _heli getVariable "fza_ah64d_stabLength";

private _halfWidth = _width / 2;

private _A = _stabPvt vectorAdd [-_halfWidth, 0, 0];
private _B = _stabPvt vectorAdd [_halfWidth, 0, 0];
private _C = _stabPvt vectorAdd [_halfWidth, cos _theta * (-_length), sin _theta * _length];
private _D = _stabPvt vectorAdd [-_halfWidth, cos _theta * (-_length), sin _theta * _length];

private _E = (_A vectorAdd _D) vectorMultiply 0.5;
private _F = (_B vectorAdd _C) vectorMultiply 0.5;
private _G = (_E vectorAdd _F) vectorMultiply 0.5;

private _H = (_A vectorAdd _B) vectorMultiply 0.5;
private _I = (_D vectorAdd _C) vectorMultiply 0.5;

private _liftLine  = _E vectorDiff _F;
private _chordLine = _H vectorDiff _I;

private _liftVec = vectorNormalized (_chordLine vectorCrossProduct _liftLine);
_liftVec = _liftVec;

private _stabLine = vectorNormalized _chordLine;
_stabLine = _stabLine;

private _relWind = vectornormalized(_heli vectorWorldToModel (velocity _heli));
_relWind = _relWind;

private _AoA = (_relWind # 2 atan2 _relWind # 1) + _theta;
_AoA = [_AoA] call CBA_fnc_simplifyAngle180;

private _AIRFOILTABLE =
[
//------AoA-[0]----------CL-[1]--------CD-[2]-------------
    [   -180.0,        0.0,           0.0        ],  //0  - DO NOT CHANGE!!
    [   -135.0,        0.5,           0.5        ],  //1  - DO NOT CHANGE!!
    [   -90.0,         0.0,           0.0        ],  //2  - DO NOT CHANGE!!
    [   -18.5,         -1.22580,      0.10236    ],  //3  -
    [   -17.5,         -1.30310,      0.07429    ],  //4  -
    [   -15.75,        -1.38680,      0.03865    ],  //5  -
    [   -10.0,         -1.08070,      0.01499    ],  //6  -
    [   -5.0,          -0.55710,      0.00847    ],  //7  -
    [   0.0,           0.00000,       0.00540    ],  //8  -
    [   5.0,           0.55720,       0.00847    ],  //9  -
    [   10.0,          1.08080,       0.01499    ],  //10 -
    [   15.75,         1.38810,       0.03863    ],  //11 -
    [   17.5,          1.30590,       0.07416    ],  //12 -
    [   18.5,          1.22840,       0.10229    ],  //13 -
    [   90.0,          0.0,           0.0        ],  //14 - DO NOT CHANGE!!
    [   135.0,         -0.5,          -0.5       ],  //15 - DO NOT CHANGE!!
    [   180.0,         0.0,           0.0        ]   //16 - DO NOT CHANGE!!
];

private _intAIRFOILTABLE = [_AIRFOILTABLE, _AoA] call fza_fnc_linearInterp;
private _CL = _intAIRFOILTABLE select 1;

private _area = [_A, _B, _C, _D] call fza_fnc_sfmplusGetArea;

private _liftForce = -_CL * 0.5 * 1.225 * _area * (_V_mps * _V_mps);

private _lift = _liftVec vectorMultiply (_liftForce * _deltaTime);
_heli addForce[_heli vectorModelToWorld _lift, _G];

/*DEBUG GRAPHICS
[_heli, _objCtr, _stabPvt, _colorWhite] call DRAW_LINE;

//Draw the stabilator
[_heli, _A, _B, _colorWhite] call DRAW_LINE;
[_heli, _B, _C, _colorWhite] call DRAW_LINE;
[_heli, _C, _D, _colorWhite] call DRAW_LINE;
[_heli, _D, _A, _colorWhite] call DRAW_LINE;
//Draw the fwd chord line originating from the pivot
[_heli, _H, _H vectorAdd _stabLine, _colorWhite] call DRAW_LINE;
//Draw the lift line
[_heli, _E, _F, _colorGreen] call DRAW_LINE;
//Draw the lift vector
[_heli, _G, _G vectorAdd _liftVec, _colorBlue] call DRAW_LINE;
//Draw the velocity vector
[_heli, _H, _H vectorAdd _relWind, _colorRed] call DRAW_LINE;
*/