params ["_heli"];

//---New
_heli setVariable ["bmk_helisim_pitchPrev",          [0.0, 0.0]];
_heli setVariable ["bmk_helisim_rollPrev",           [0.0, 0.0]];
_heli setVariable ["bmk_helisim_yawPrev",            [0.0, 0.0]];

_heli setVariable ["bmk_helisim_rotorRPM",           [0.0, 0.0]];
_heli setVariable ["bmk_helisim_rotor_mu",           [0.0, 0.0]];
_heli setVariable ["bmk_helisim_rotor_nu",           [0.0, 0.0]];
_heli setVariable ["bmk_helisim_rotor_lambda",       [0.0, 0.0]];
_heli setVariable ["bmk_helisim_rotor_thrust",       [0.0, 0.0]];
_heli setVariable ["bmk_helisim_rotor_CT",           [0.0, 0.0]];

_heli setVariable ["bmk_helisim_rotor_outputTorque", [0.0, 0.0]];