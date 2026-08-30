class Extended_PreInit_EventHandlers {
    class fza_ah64_helisim_preInit {
        init = "call compile preprocessFileLineNumbers 'fza_ah64_helisim\XEH_preInit.sqf';";
    };
};

class Extended_GetIn_EventHandlers {
    class fza_ah64base {
        class fza_ah64_helisim_getin_eh {
            getIn = "_this call bmkhs_fnc_eventGetIn";
        };
    };
};
