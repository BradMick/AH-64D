class Extended_PreInit_EventHandlers {
    class bmkhs_preInit {
        init = "call compile preprocessFileLineNumbers 'bmkhs_helisim\functions\event\fn_eventPreInit.sqf';";
    };
};

class Extended_GetIn_EventHandlers {
    class fza_ah64base {
        class bmkhs_getin_eh {
            getIn = "_this call bmkhs_fnc_eventGetIn";
        };
    };
};
