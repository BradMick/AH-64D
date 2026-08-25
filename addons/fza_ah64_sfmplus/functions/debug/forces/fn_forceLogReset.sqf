/* ----------------------------------------------------------------------------
Function: fza_sfmplus_fnc_forceLogReset

Description:
    Clears the per-frame force log accumulator (fza_sfmplus_forceLog) at the
    start of a flight-model update, so each frame's readout reflects only that
    frame's contributions. No-op when the force log is not being watched.

    Also snapshots the CoM and current body rates/attitude for the readout, so
    the GUI can correlate the net force/moment with the resulting motion.

Parameters:
    _heli - The aircraft [Object].

Returns:
    Nothing.

Author:
    BradMick
---------------------------------------------------------------------------- */
params ["_heli"];

if !(fza_sfmplus_forceLogOn) exitWith {};
if (isNull _heli) exitWith {};

//Publish the previous frame's completed log for the GUI to read (double buffer
//so the GUI never reads a half-filled frame), then start a fresh one.
_heli setVariable ["fza_sfmplus_forceLogPublished", _heli getVariable ["fza_sfmplus_forceLog", createHashMap]];
_heli setVariable ["fza_sfmplus_forceLog", createHashMap];
