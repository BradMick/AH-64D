/* ----------------------------------------------------------------------------
Function: bmkhs_fnc_damageApply <-- rename me to perfLimit, move to engine

Description:
    Applies damage within a defined period of time after exceeding aircraft
    operating limits.

Parameters:
    _heli      - The helicopter to get information from [Unit].

Returns:
    ...

Examples:
    ...

Author:
    BradMick
---------------------------------------------------------------------------- */
params ["_heli"];

if (!local _heli) exitWith {};

private _pctNR       = (_heli getVariable "bmkhs_engPctNP" select 0) max (_heli getVariable "bmkhs_engPctNP" select 1);
private _eng1PctTQ   = _heli getVariable "bmkhs_engPctTQ" select 0;
private _eng2PctTQ   = _heli getVariable "bmkhs_engPctTQ" select 1;
private _engPctTQ    = _eng1PctTQ max _eng2PctTQ;
private _isSingleEng = _heli getVariable "bmkhs_isSingleEng";
private _maxTQ_DE    = _heli getVariable "bmkhs_maxTQ_DE";
private _maxTQ_SE    = _heli getVariable "bmkhs_maxTQ_SE";
private _droopRotor  = false;

if (isEngineOn _heli) then {
    //With the power levers at idle
    if (_pctNR <= 0.50 && _engPctTQ >= 0.30) then {
        _droopRotor = true;
    };

    if (_pctNR > 0.9) then {
        if (_isSingleEng) then {
            if (_engPctTQ > _maxTQ_SE) then {
                _droopRotor = true;
            } else {
                _droopRotor = false;
            };
        } else {
            if (_eng1PctTQ > _maxTQ_DE) then {
                _droopRotor = true;
            } else {
                _droopRotor = false;
            };
        };
    };
};

if (_droopRotor) then {
    bmkhs_liftLossTimer = (bmkhs_liftLossTimer + 0.01) max 0 min 1;
} else {
    bmkhs_liftLossTimer = (bmkhs_liftLossTimer - 0.05) max 0 min 1;
};
