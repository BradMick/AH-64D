params ["_heli"];
#include "\fza_ah64_sfmplus\headers\core.hpp"

if (currentPilot _heli != player || !local _heli) exitWith {};

//Keyboard auto-attitude (CASUAL) OWNS the pitch and roll trim channels: it writes force-trim
//every frame as the output of an attitude PID. Setting force-trim from raw stick position here
//would stomp that write and leave the PID fighting a trim offset it did not command, so both
//owned axes are skipped. Same single gate as fn_getInput - realistic pilots are untouched, and
//yaw is never owned by auto-attitude so it always trims normally.
private _autoAttOwns = fza_ah64_sfmplusRealismSetting != REALISTIC;

//Cyclic pitch trim
if (!_autoAttOwns) then {
    private _curCyclicFwdAft  = (_heli getVariable "fza_sfmplus_cyclicFwdAft");
    private _prevCyclicFwdAft = _heli getVariable "fza_ah64_forceTrimPosPitch";
    private _pitchTrimVal     = [_curCyclicFwdAft, _prevCyclicFwdAft] call fza_sfmplus_fnc_getInterpInput;
    if (fza_ah64_sfmPlusSpringlessCyclic || fza_ah64_sfmPlusKeyboardStickyPitch) then {
        _heli setVariable ["fza_ah64_forceTrimPosPitch", 0.0];
    } else {
        _heli setVariable ["fza_ah64_forceTrimPosPitch", _pitchTrimVal, true];
    };
};
//Cyclic roll trim
if (!_autoAttOwns) then {
    private _curCyclicLeftRight  = (_heli getVariable "fza_sfmplus_cyclicLeftRight");
    private _prevCyclicLeftRight = _heli getVariable "fza_ah64_forceTrimPosRoll";
    private _rollTrimVal         = [_curCyclicLeftRight, _prevCyclicLeftRight] call fza_sfmplus_fnc_getInterpInput;
    if (fza_ah64_sfmPlusSpringlessCyclic || fza_ah64_sfmPlusKeyboardStickyRoll) then {
        _heli setVariable ["fza_ah64_forceTrimPosRoll",  0.0];
    } else {
        _heli setVariable ["fza_ah64_forceTrimPosRoll", _rollTrimVal, true];
    };
};
//Pedal trim
private _curPedalLeftRight  = (_heli getVariable "fza_sfmplus_pedalLeftRight");
private _prevPedalLeftRight = _heli getVariable "fza_ah64_forceTrimPosYaw";
private _pedalTrimVal       = [_curPedalLeftRight, _prevPedalLeftRight] call fza_sfmplus_fnc_getInterpInput;
if (fza_ah64_sfmplusSpringlessPedals || fza_ah64_sfmPlusKeyboardStickyYaw) then {
    _heli setVariable ["fza_ah64_forceTrimPosYaw", 0.0];
} else {
    _heli setVariable ["fza_ah64_forceTrimPosYaw", _pedalTrimVal, true];
};
