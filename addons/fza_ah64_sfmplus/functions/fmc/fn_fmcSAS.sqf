params ["_heli"];
#include "\fza_ah64_sfmplus\headers\core.hpp"

//Live-tunable gains (dialled from the tuner GUI, SCAS tab). Read + set[] each frame.
private _pidSASPitch = _heli getVariable "fza_sfmplus_pid_sas_pitch";
_pidSASPitch set ["kp", _heli getVariable "fza_sfmplus_tune_sasPitch_kp"];
_pidSASPitch set ["ki", _heli getVariable "fza_sfmplus_tune_sasPitch_ki"];
_pidSASPitch set ["kd", _heli getVariable "fza_sfmplus_tune_sasPitch_kd"];
private _pidSASRoll  = _heli getVariable "fza_sfmplus_pid_sas_roll";
_pidSASRoll set ["kp", _heli getVariable "fza_sfmplus_tune_sasRoll_kp"];
_pidSASRoll set ["ki", _heli getVariable "fza_sfmplus_tune_sasRoll_ki"];
_pidSASRoll set ["kd", _heli getVariable "fza_sfmplus_tune_sasRoll_kd"];
private _pidSASYaw   = _heli getVariable "fza_sfmplus_pid_sas_yaw";
_pidSASYaw set ["kp", _heli getVariable "fza_sfmplus_tune_sasYaw_kp"];
_pidSASYaw set ["ki", _heli getVariable "fza_sfmplus_tune_sasYaw_ki"];
_pidSASYaw set ["kd", _heli getVariable "fza_sfmplus_tune_sasYaw_kd"];

((_heli getVariable "fza_sfmplus_angVelModelSpace"))
    params [
             "_angVelX"   // pitch rate (about model +X, right axis), rad/s
           , "_angVelY"   // roll rate  (about model +Y, fwd axis),   rad/s
           , "_angVelZ"   // yaw rate   (about model +Z, up axis),    rad/s
           ];

private _deltaTime      = _heli getVariable "fza_sfmplus_deltaTime";
private _sasPitchOutput = 0.0;
private _sasRollOutput  = 0.0;
private _sasYawOutput   = 0.0;

//SCAS = STABILITY augmentation = proportional RATE DAMPING (a "shock absorber" on body rate).
//The COMMAND term was removed: the SAS servo gives a "speed of light" crisp pilot path
//(fn_actuator returns input un-lagged when SCAS is available), so the pilot's crisp input IS the
//command. SCAS's job is purely STABILITY - it continuously opposes body rate, PROPORTIONALLY and
//ALWAYS (not a threshold/limiter): setpoint = 0, so pidRun error = 0 - rate = -rate, and the
//output = kp * -rate opposes any rotation. This adds the artificial damping the airframe lacks
//(helicopters are under-damped, esp. the low-inertia roll) so it feels solid - stop commanding
//and the rate bleeds off fast. Not a maneuver limit; you just hold a bit more input to sustain a
//rate. Runs ALWAYS (incl. force-trim interrupt); holds no attitude/heading reference (that's the
//holds). Authority 20% pitch, 10% roll/yaw. FMC-axis + primary-hydraulics gating in fn_fmc.
//Tune firmness per axis via the SAS PID kp (fn_coreConfig) - roll is the twitchy low-inertia one.

//SAS RUNS ON EVERY AXIS, ALWAYS - including when keyboard auto-attitude owns pitch and roll.
//
//An earlier version stood SAS down on those axes, on the reasoning that auto-attitude "owns" them.
//That was wrong and it made the auto-attitude loop oscillate violently: the two do DIFFERENT jobs
//and are complementary, not competing. SAS damps RATE (setpoint 0 on body rate, +-10-20% servo);
//auto-attitude commands ATTITUDE. An attitude loop with no rate damping underneath it has nothing
//opposing the overshoot it creates, so it hunts - and raising its gains to fix the sluggishness
//just made the hunt violent. Rate damping under an attitude loop is the standard arrangement and
//is exactly what lets the outer loop carry useful gain without ringing.
//
//SAS is also the cheaper of the two to leave running: it is a small, bounded, always-stabilising
//term that cannot fight an attitude command (it only ever opposes RATE, and a deliberate attitude
//change simply carries a little more input to sustain its rate).

//ROLL: proportional rate damping - oppose actual roll rate.
private _roll  = [_pidSASRoll, _deltaTime, 0.0, _angVelY] call fza_fnc_pidRun;
_roll          = [_roll,  -0.1, 0.1] call BIS_fnc_clamp;   // 10% SAS-servo authority (roll)
_sasRollOutput = _roll;

//YAW: proportional rate damping - oppose actual yaw rate. (Heading Hold is a separate
//reference-hold submode on top, in fn_fmcHeadingHold; not built here.)
private _yaw   = [_pidSASYaw, _deltaTime, 0.0, _angVelZ] call fza_fnc_pidRun;
_yaw           = [_yaw, -0.1, 0.1] call BIS_fnc_clamp;   // 10% SAS-servo authority (yaw)
_sasYawOutput  = _yaw;

//PITCH: proportional rate damping - oppose actual pitch rate. Runs always (see the note above).
private _pitch = [_pidSASPitch, _deltaTime, 0.0, _angVelX] call fza_fnc_pidRun;
_pitch         = [_pitch, -0.2, 0.2] call BIS_fnc_clamp;   // 20% SAS-servo authority (pitch)
_sasPitchOutput = _pitch;

//systemChat format ["Pitch SAS = %1 -- Roll SAS = %2", _SASPitchOutput, _SASRollOutput];
//systemChat format ["_cyclicFwdAft = %1 -- _cyclicLeftRight = %2 -- _pedalLeftRight = %3", _heli getVariable "fza_sfmplus_cyclicFwdAft" toFixed 2, _heli getVariable "fza_sfmplus_cyclicLeftRight" toFixed 2, _heli getVariable "fza_sfmplus_pedalLeftRight" toFixed 2];
//systemChat format ["_angVelX = %1 - _angVelY = %2 - _angVelZ = %3", _angVelX, _angVelY, _angVelZ];

[_sasPitchOutput, _sasRollOutput, _sasYawOutput];
