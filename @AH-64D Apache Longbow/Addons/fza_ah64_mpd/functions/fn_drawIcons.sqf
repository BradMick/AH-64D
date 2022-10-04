/* ----------------------------------------------------------------------------
Function: fza_mpd_fnc_drawIcons

Description:
	Draws the points inputted on the right hand MPD, performing all necessary positioning

Parameters:
	_heli - The helicopter to draw this on (the player must be in it)
	_points - the points to draw on the screen. An array with arrays in it that fit the following schema
	    [_posMode, _pos, _tex, _color, _textMode, _text1, _text2, _objType]
		where:
		    _posMode is how to read the position, either MPD_POSMODE_WORLD or MPD_POSMODE_SCREEN
			_pos is 2d position of the point, in the aforementioned mode
			_tex is the texture to apply to the centre of the point
			_color is the color to apply (MPD_ICON_COLOR_GREEN .. MPD_ICON_COLOR_YELLOW)
			_textMode is the text mode (MPD_ICON_TYPE_A .. G)
			_text1 is the first part of text
			_text2 is the second part of text, where applicable
			_objType is the type of object to be used to display graphic and text information (MPD_OBJ_TYPE_A, ASE, B...E, FCR, PPOS)
	_display - 1 if right, 0 if left
	_scale - (optional) Ratio to apply to scale from the world's size to the MPD size. Defaults to *fza_ah64_rangesetting x 0.75*
	_center - (optional) Where in the screen should be where the "helicopter" should be when converting from world. Defaults to [0.5, 0.25]

Returns:
	Nothing

Examples:

Author:
	mattysmith22
---------------------------------------------------------------------------- */
params ["_heli", "_points", "_display", ["_scale", -1], ["_center", [0.5, 0.75]], ["_heading", direction (_this # 0)], ["_heliPos", getPosASL (_this # 0)]];
#include "\fza_ah64_controls\headers\selections.h"
#include "\fza_ah64_dms\headers\constants.h"

private _validChars = createHashmapFromArray [
	["0", "\fza_ah64_mpd\font\0_ca.paa"],
	["1", "\fza_ah64_mpd\font\1_ca.paa"],
	["2", "\fza_ah64_mpd\font\2_ca.paa"],
	["3", "\fza_ah64_mpd\font\3_ca.paa"],
	["4", "\fza_ah64_mpd\font\4_ca.paa"],
	["5", "\fza_ah64_mpd\font\5_ca.paa"],
	["6", "\fza_ah64_mpd\font\6_ca.paa"],
	["7", "\fza_ah64_mpd\font\7_ca.paa"],
	["8", "\fza_ah64_mpd\font\0_ca.paa"],
	["9", "\fza_ah64_mpd\font\9_ca.paa"],
	["A", "\fza_ah64_mpd\font\A_ca.paa"],
	["B", "\fza_ah64_mpd\font\B_ca.paa"],
	["C", "\fza_ah64_mpd\font\C_ca.paa"],
	["D", "\fza_ah64_mpd\font\D_ca.paa"],
	["E", "\fza_ah64_mpd\font\E_ca.paa"],
	["F", "\fza_ah64_mpd\font\F_ca.paa"],
	["G", "\fza_ah64_mpd\font\G_ca.paa"],
	["H", "\fza_ah64_mpd\font\H_ca.paa"],
	["I", "\fza_ah64_mpd\font\I_ca.paa"],
	["J", "\fza_ah64_mpd\font\J_ca.paa"],
	["K", "\fza_ah64_mpd\font\K_ca.paa"],
	["L", "\fza_ah64_mpd\font\L_ca.paa"],
	["M", "\fza_ah64_mpd\font\M_ca.paa"],
	["N", "\fza_ah64_mpd\font\N_ca.paa"],
	["O", "\fza_ah64_mpd\font\O_ca.paa"],
	["P", "\fza_ah64_mpd\font\P_ca.paa"],
	["Q", "\fza_ah64_mpd\font\Q_ca.paa"],
	["R", "\fza_ah64_mpd\font\R_ca.paa"],
	["S", "\fza_ah64_mpd\font\S_ca.paa"],
	["T", "\fza_ah64_mpd\font\T_ca.paa"],
	["U", "\fza_ah64_mpd\font\U_ca.paa"],
	["V", "\fza_ah64_mpd\font\V_ca.paa"],
	["W", "\fza_ah64_mpd\font\W_ca.paa"],
	["X", "\fza_ah64_mpd\font\X_ca.paa"],
	["Y", "\fza_ah64_mpd\font\Y_ca.paa"],
	["Z", "\fza_ah64_mpd\font\Z_ca.paa"]
];

if (_scale == -1) then {
	_scale = (0.125 * 5 / (_heli getVariable "fza_ah64_rangesetting"));
};

#define MPD_X_MIN 0.1
#define MPD_X_MAX 0.9
#define MPD_Y_MIN 0.1
#define MPD_Y_MAX 0.9

private _pointsWithPos = _points apply {
	private _pos = _x # 1;
	private _theta = [_heli, _heliPos # 0, _heliPos # 1,  _pos # 0, _pos # 1, _heading] call fza_fnc_relativeDirection;
	if (_x # 0) then {
		private _targxpos = _center # 0 + (sin _theta) * ((_heliPos distance2D _pos) * _scale);
		private _targypos = _center # 1 - (cos _theta) * ((_heliPos distance2D _pos) * _scale);
		_pos = [_targxpos, _targypos];
	};

	[_pos, _x];
};

private _filter = {
	(_x # 0) params ["_tx", "_ty"];
	(MPD_X_MIN < _tx && _tx < MPD_X_MAX && MPD_Y_MIN < _ty && _ty < MPD_Y_MAX);
};

_pointsWithPos = [_pointsWithPos, [_heli], {_center distance2D _x # 0}, "ASCEND", _filter] call BIS_fnc_sortBy;

#define SETTEXTURE(_ind, _tex) _heli setObjectTexture [_ind, _tex]
#define SETICONTEXTURE(_ind, _tex) SETTEXTURE(_ind + _offset, _tex)

private _prefix = [["pl", "pr"] select _display, ["cl", "cr"] select _display] select (gunner _heli == player);

private _writeText = {
	params ["_heli", "_offset", "_inds", "_text", "_rightJustified"];
	private _textLen = count _text;
	if (_rightJustified) then {
		_text = reverse _text;
		reverse _inds;
	};

	{
		if (_forEachIndex >= _textLen) then {
			SETICONTEXTURE(_x, "");
			continue;
		};
		private _char = _text select [_forEachIndex,1];
		private _tex = _validChars getOrDefault [_char, ""];
		SETICONTEXTURE(_x, _tex);
	} forEach _inds;
};

private _displayOffset = [0, 512] select _display;

_pointsWithPos # _i # 1 params ["","", "_tex", "_color", "_textMode", "_text1", "_text2", "_objType"];

switch(_objType) do {
	case MPD_OBJ_TYPE_A : {
		for "_i" from 0 to 4 do {
			switch(_textMode) do {
				case MPD_ICON_TYPE_G : {
					[_heli, _offset, [SEL_MPD_OBJ01_A_DIGIT01, SEL_MPD_OBJ01_A_DIGIT02], _text1, false] call _writeText;
					// Set point texture
					SETICONTEXTURE(SEL_MPD_OBJ01_A_ICON, _tex);

					// Set point position
					_heli animate [format ["%1_mpdObj%2%3_%4_x", _prefix, ["", "0"] select (_i < 8), _i + 1], _pos # 0, "A"];
					_heli animate [format ["%1_mpdObj%2%3_%4_y", _prefix, ["", "0"] select (_i < 8), _i + 1], _pos # 1, "A"];
				};			
			};
		};
	};
	case MPD_OBJ_TYPE_ASE : {
		for "_i" from 0 to 6 do {
			switch(_textMode) do {
				case MPD_ICON_TYPE_G : {
					[_heli, _offset, [SEL_MPD_OBJ01_ASE_DIGIT01, SEL_MPD_OBJ01_ASE_DIGIT02], _text1, false] call _writeText;
					// Set point texture
					SETICONTEXTURE(SEL_MPD_OBJ01_ASE_ICON, _tex);

					// Set point position
					_heli animate [format ["%1_mpdObj%2%3_%4_x", _prefix, ["", "0"] select (_i < 8), _i + 1], _pos # 0, "ASE"];
					_heli animate [format ["%1_mpdObj%2%3_%4_y", _prefix, ["", "0"] select (_i < 8), _i + 1], _pos # 1, "ASE"];
				};			
			};
		};
	};
	case MPD_OBJ_TYPE_B : {
		for "_i" from 0 to 4 do {
			switch(_textMode) do {
				case MPD_ICON_TYPE_C : {
					[_heli, _offset, [SEL_MPD_OBJ01_C_DIGIT01, SEL_MPD_OBJ01_C_DIGIT02], _text1, false] call _writeText;
					// Set point texture
					SETICONTEXTURE(SEL_MPD_OBJ01_C_ICON, _tex);

					// Set point position
					_heli animate [format ["%1_mpdObj%2%3_%4_x", _prefix, ["", "0"] select (_i < 8), _i + 1], _pos # 0, "C"];
					_heli animate [format ["%1_mpdObj%2%3_%4_y", _prefix, ["", "0"] select (_i < 8), _i + 1], _pos # 1, "C"];
				};			
			};
		};
	};
	case MPD_OBJ_TYPE_C : {
		for "_i" from 0 to 4 do {
			switch(_textMode) do {
				case MPD_ICON_TYPE_F : {
					[_heli, _offset, [SEL_MPD_OBJ01_C_DIGIT01, SEL_MPD_OBJ01_C_DIGIT02, SEL_MPD_OBJ01_C_DIGIT03], _text1, false] call _writeText;

					// Set point position
					_heli animate [format ["%1_mpdObj%2%3_%4_x", _prefix, ["", "0"] select (_i < 8), _i + 1], _pos # 0, "C"];
					_heli animate [format ["%1_mpdObj%2%3_%4_y", _prefix, ["", "0"] select (_i < 8), _i + 1], _pos # 1, "C"];
				};			
			};
		};
	};
	case MPD_OBJ_TYPE_D : {
		for "_i" from 0 to 4 do {
			switch(_textMode) do {
				case MPD_ICON_TYPE_B : {
					[_heli, _offset, [SEL_MPD_OBJ01_D_DIGIT01, SEL_MPD_OBJ01_D_DIGIT02, SEL_MPD_OBJ01_D_DIGIT03], _text1, false] call _writeText;
					// Set point texture
					SETICONTEXTURE(SEL_MPD_OBJ01_D_ICON, _tex);

					// Set point position
					_heli animate [format ["%1_mpdObj%2%3_%4_x", _prefix, ["", "0"] select (_i < 8), _i + 1], _pos # 0, "D"];
					_heli animate [format ["%1_mpdObj%2%3_%4_y", _prefix, ["", "0"] select (_i < 8), _i + 1], _pos # 1, "D"];
				};			
			};
		};
	};
	case MPD_OBJ_TYPE_E : {
		for "_i" from 0 to 4 do {
			switch(_textMode) do {
				case MPD_ICON_TYPE_A : {
					[_heli, _offset, [SEL_MPD_OBJ01_E_DIGIT01, SEL_MPD_OBJ01_E_DIGIT02, SEL_MPD_OBJ01_E_DIGIT03], _text1, false] call _writeText;
					SETICONTEXTURE(SEL_MPD_OBJ01_E_DIGIT04, "");
					SETICONTEXTURE(SEL_MPD_OBJ01_E_DIGIT05, "");
					SETICONTEXTURE(SEL_MPD_OBJ01_E_DIGIT06, "");
					SETICONTEXTURE(SEL_MPD_OBJ01_E_DIGIT07, "");
					SETICONTEXTURE(SEL_MPD_OBJ01_E_DIGIT08, "");
					SETICONTEXTURE(SEL_MPD_OBJ01_E_DIGIT09, "");
					SETICONTEXTURE(SEL_MPD_OBJ01_E_DIGIT10, "");
					SETICONTEXTURE(SEL_MPD_OBJ01_E_DIGIT11, "");
					// Set point texture
					SETICONTEXTURE(SEL_MPD_OBJ01_E_ICON, _tex);

					// Set point position
					_heli animate [format ["%1_mpdObj%2%3_%4_x", _prefix, ["", "0"] select (_i < 8), _i + 1], _pos # 0, "E"];
					_heli animate [format ["%1_mpdObj%2%3_%4_y", _prefix, ["", "0"] select (_i < 8), _i + 1], _pos # 1, "E"];
				};
				case MPD_ICON_TYPE_D : {
					[_heli, _offset, [SEL_MPD_OBJ01_E_DIGIT02, SEL_MPD_OBJ01_E_DIGIT03, SEL_MPD_OBJ01_E_DIGIT04, SEL_MPD_OBJ01_E_DIGIT05, SEL_MPD_OBJ01_E_DIGIT06], _text1, false] call _writeText;
					SETICONTEXTURE(SEL_MPD_OBJ01_E_DIGIT01, "");
					SETICONTEXTURE(SEL_MPD_OBJ01_E_DIGIT07, "");
					SETICONTEXTURE(SEL_MPD_OBJ01_E_DIGIT08, "");
					SETICONTEXTURE(SEL_MPD_OBJ01_E_DIGIT09, "");
					SETICONTEXTURE(SEL_MPD_OBJ01_E_DIGIT10, "");
					SETICONTEXTURE(SEL_MPD_OBJ01_E_DIGIT11, "");
					// Set point texture
					SETICONTEXTURE(SEL_MPD_OBJ01_E_ICON, _tex);

					// Set point position
					_heli animate [format ["%1_mpdObj%2%3_%4_x", _prefix, ["", "0"] select (_i < 8), _i + 1], _pos # 0, "E"];
					_heli animate [format ["%1_mpdObj%2%3_%4_y", _prefix, ["", "0"] select (_i < 8), _i + 1], _pos # 1, "E"];
				};
				case MPD_ICON_TYPE_E : {
					[_heli, _offset, [SEL_MPD_OBJ01_E_DIGIT04, SEL_MPD_OBJ01_E_DIGIT05, SEL_MPD_OBJ01_E_DIGIT06], _text1, false] call _writeText;
					SETICONTEXTURE(SEL_MPD_OBJ01_E_DIGIT01, "");
					SETICONTEXTURE(SEL_MPD_OBJ01_E_DIGIT02, "");
					SETICONTEXTURE(SEL_MPD_OBJ01_E_DIGIT03, "");
					SETICONTEXTURE(SEL_MPD_OBJ01_E_DIGIT07, "");
					SETICONTEXTURE(SEL_MPD_OBJ01_E_DIGIT08, "");
					SETICONTEXTURE(SEL_MPD_OBJ01_E_DIGIT09, "");
					SETICONTEXTURE(SEL_MPD_OBJ01_E_DIGIT10, "");
					SETICONTEXTURE(SEL_MPD_OBJ01_E_DIGIT11, "");
					// Set point texture
					SETICONTEXTURE(SEL_MPD_OBJ01_E_ICON, _tex);

					// Set point position
					_heli animate [format ["%1_mpdObj%2%3_%4_x", _prefix, ["", "0"] select (_i < 8), _i + 1], _pos # 0, "E"];
					_heli animate [format ["%1_mpdObj%2%3_%4_y", _prefix, ["", "0"] select (_i < 8), _i + 1], _pos # 1, "E"];
				};			
			};
		};
	};
	case MPD_OBJ_TYPE_FCR : {
		for "_i" from 0 to 4 do {
			switch(_textMode) do {
				case MPD_ICON_TYPE_H : {
					// Set point texture
					SETICONTEXTURE(SEL_MPD_OBJ01_FCR_ICON, _tex);

					// Set point position
					_heli animate [format ["%1_mpdObj%2%3_%4_x", _prefix, ["", "0"] select (_i < 8), _i + 1], _pos # 0, "FCR"];
					_heli animate [format ["%1_mpdObj%2%3_%4_y", _prefix, ["", "0"] select (_i < 8), _i + 1], _pos # 1, "FCR"];
				};
			};
		};
	};
	case MPD_OBJ_TYPE_PPOS : {
		for "_i" from 0 to 4 do {
			switch(_textMode) do {
				case MPD_ICON_TYPE_I : {
					// Set point texture
					SETICONTEXTURE(SEL_MPD_OBJ01_PPOS_ICON, _tex);

					// Set point position
					_heli animate [format ["%1_mpdObj%2%3_%4_x", _prefix, ["", "0"] select (_i < 8), _i + 1], _pos # 0, "PPOS"];
					_heli animate [format ["%1_mpdObj%2%3_%4_y", _prefix, ["", "0"] select (_i < 8), _i + 1], _pos # 1, "PPOS"];
				};
			};
		};
	};
	default {
		["Invalid text type %1", _textMode] call BIS_fnc_error;
	};
};

/*
for "_i" from 0 to 31 do {
	private _offset = (_i * 16) + _displayOffset;
	if (_i >= count _pointsWithPos) then {
		//Wipe all textures
		SETICONTEXTURE(SEL_MPD_OBJ1_A_DIGIT01, "");
		SETICONTEXTURE(SEL_MPD_OBJ1_ASE_DIGIT02, "");
		SETICONTEXTURE(SEL_MPD_OBJ1_B_DIGIT03, "");
		SETICONTEXTURE(SEL_MPD_OBJ1_C_DIGIT04, "");
		SETICONTEXTURE(SEL_MPD_OBJ1_D_DIGIT05, "");
		SETICONTEXTURE(SEL_MPD_OBJ1_E_DIGIT06, "");
		SETICONTEXTURE(SEL_MPD_OBJ1_FCR_DIGIT07, "");
		SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT08, "");
		SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT09, "");
		SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT10, "");
		SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT11, "");
		SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT12, "");
		SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT13, "");
		SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT14, "");
		SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT15, "");
		SETICONTEXTURE(SEL_MPD_OBJ1_ICON, "");
		continue;
	};
	private _pos = _pointsWithPos # _i # 0;
	_pointsWithPos # _i # 1 params ["","", "_tex", "_color", "_textMode", "_text1", "_text2", "_objType"];
	// Set point texture
	SETICONTEXTURE(SEL_MPD_OBJ1_ICON, _tex);
	
	// Set point position
	_heli animate [format ["%1_mpdObj%2%3_x", _prefix, ["", "0"] select (_i < 8), _i + 1], _pos # 0];
	_heli animate [format ["%1_mpdObj%2%3_y", _prefix, ["", "0"] select (_i < 8), _i + 1], _pos # 1];

	switch (_textMode) do {
		case MPD_ICON_TYPE_A : {
			//[_heli, _offset, _inds, _text1, _rightJustified] call _writeText;
			[_heli, _offset, [SEL_MPD_OBJ1_DIGIT01, SEL_MPD_OBJ1_DIGIT02, SEL_MPD_OBJ1_DIGIT03], _text1, true] call _writeText;
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT04, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT05, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT06, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT07, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT08, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT09, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT10, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT11, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT12, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT13, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT14, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT15, "");
		};
		case MPD_ICON_TYPE_B : {
			[_heli, _offset, [SEL_MPD_OBJ1_DIGIT09, SEL_MPD_OBJ1_DIGIT10, SEL_MPD_OBJ1_DIGIT11], _text1, false] call _writeText;
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT01, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT02, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT03, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT04, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT05, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT06, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT07, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT08, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT12, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT13, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT14, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT15, "");
		};
		case MPD_ICON_TYPE_C : {
			[_heli, _offset, [SEL_MPD_OBJ1_DIGIT14, SEL_MPD_OBJ1_DIGIT15], _text1, false] call _writeText;
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT01, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT02, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT03, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT04, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT05, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT06, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT07, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT08, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT09, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT10, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT11, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT12, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT13, "");
		};
		case MPD_ICON_TYPE_D : {
			[_heli, _offset, [SEL_MPD_OBJ1_DIGIT01, SEL_MPD_OBJ1_DIGIT02, SEL_MPD_OBJ1_DIGIT03], _text1, true] call _writeText;
			[_heli, _offset, [SEL_MPD_OBJ1_DIGIT04, SEL_MPD_OBJ1_DIGIT05, SEL_MPD_OBJ1_DIGIT06], _text2, false] call _writeText;
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT07, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT08, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT09, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT10, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT11, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT12, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT13, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT14, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT15, "");
		};
		case MPD_ICON_TYPE_E : {
			[_heli, _offset, [SEL_MPD_OBJ1_DIGIT04, SEL_MPD_OBJ1_DIGIT05, SEL_MPD_OBJ1_DIGIT06], _text1, false] call _writeText;
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT01, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT02, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT03, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT07, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT08, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT09, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT10, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT11, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT12, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT13, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT14, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT15, "");
		};
		case MPD_ICON_TYPE_F : {
			[_heli, _offset, [SEL_MPD_OBJ1_DIGIT12, SEL_MPD_OBJ1_DIGIT13], _text1, false] call _writeText;
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT01, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT02, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT03, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT04, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT05, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT06, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT09, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT07, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT08, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT10, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT11, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT14, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT15, "");
		};
		case MPD_ICON_TYPE_G : {
			[_heli, _offset, [SEL_MPD_OBJ1_DIGIT07, SEL_MPD_OBJ1_DIGIT08], _text1, false] call _writeText;
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT01, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT02, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT03, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT04, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT05, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT06, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT09, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT10, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT11, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT12, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT13, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT14, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT15, "");
		};
		case MPD_ICON_TYPE_H : {
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT01, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT02, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT03, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT04, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT05, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT06, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT07, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT08, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT09, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT10, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT11, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT12, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT13, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT14, "");
			SETICONTEXTURE(SEL_MPD_OBJ1_DIGIT15, "");
		};
		default {
			["Invalid text type %1", _textMode] call BIS_fnc_error;
		};
	};
};
*/