params ["_wcas", "_actWCA", "_fault", "_mpdText", "_ufdText"];

#include "\fza_ah64_controls\headers\wcaConstants.h"

_wcas pushBack [WCA_CAUTION, "_mpdText", "_ufdText"];

if ((_actWCA get "_fault") == false) then {
    _actWCA set ["_fault", true];
} else {
    _actWCA set ["_fault", false];
};

_wcas;