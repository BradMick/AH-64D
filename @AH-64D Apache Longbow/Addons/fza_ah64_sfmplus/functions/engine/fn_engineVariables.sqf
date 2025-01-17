/* ----------------------------------------------------------------------------
Function: fza_sfmplus_fnc_engineVariables

Description:
	Defines core engine variables.

Parameters:
	_heli - The helicopter to get information from [Unit].

Returns:
	...

Examples:
	...

Author:
	BradMick
---------------------------------------------------------------------------- */
params ["_heli"];

_heli setVariable ["fza_sfmplus_engPowerLeverState",  	["OFF", "OFF"]]; //OFF, IDLE, FLY
_heli setVariable ["fza_sfmplus_engState",            	["OFF", "OFF"]]; //OFF, STARTING, ON

if(isMultiplayer) then {
	_heli setVariable ["fza_sfmplus_lastTimePropagated", 0];
};

_heli setVariable ["fza_sfmplus_isSingleEng",			false];

//Outputs
_heli setVariable ["fza_sfmplus_engFF",               	[0.0, 0.0]];
_heli setVariable ["fza_sfmplus_engBaseNG",		   		[0.0, 0.0]];
_heli setVariable ["fza_sfmplus_engPctNG",            	[0.0, 0.0]];
_heli setVariable ["fza_sfmplus_engBaseNP",           	[0.0, 0.0]];
_heli setVariable ["fza_sfmplus_engPctNP",            	[0.0, 0.0]];
_heli setVariable ["fza_sfmplus_engBaseTQ",		   		[0.0, 0.0]];
_heli setVariable ["fza_sfmplus_engPctTQ",  		   	[0.0, 0.0]];
_heli setVariable ["fza_sfmplus_engBaseTGT",     	   	[0.0, 0.0]];
_heli setVariable ["fza_sfmplus_engTGT",        	   	[0.0, 0.0]];
_heli setVariable ["fza_sfmplus_engBaseOilPSI",	  		[0.0, 0.0]];
_heli setVariable ["fza_sfmplus_engOilPSI",		   		[0.0, 0.0]];