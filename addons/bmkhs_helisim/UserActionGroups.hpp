//HeliSim's flight control actions, grouped for the controls menu.
class UserActionGroups {
    class bmkhs_flightControls {
        name = "HeliSim Flight Controls";
        group[] = {
            "bmkhs_cyclicForward",
            "bmkhs_cyclicBackward",
            "bmkhs_cyclicLeft",
            "bmkhs_cyclicRight",
            "bmkhs_pedalLeft",
            "bmkhs_pedalRight",
            "bmkhs_collectiveUp",
            "bmkhs_collectiveDn",
            "bmkhs_kbCollectiveUp",
            "bmkhs_kbCollectiveDn",
            "bmkhs_forceTrim",
            "bmkhs_forceTrimPanic",
            "bmkhs_holdModeAltitude",
            "bmkhs_holdModeAttitude",
            "bmkhs_holdModesOff",
            "bmkhs_stickyInterrupt"
        };
    };
};

class UserActionsConflictGroups {
    class bmkhs_flightControls {
        group[] = {
            "bmkhs_cyclicForward",
            "bmkhs_cyclicBackward",
            "bmkhs_cyclicLeft",
            "bmkhs_cyclicRight",
            "bmkhs_pedalLeft",
            "bmkhs_pedalRight",
            "bmkhs_collectiveUp",
            "bmkhs_collectiveDn",
            "bmkhs_kbCollectiveUp",
            "bmkhs_kbCollectiveDn",
            "bmkhs_forceTrim",
            "bmkhs_forceTrimPanic",
            "bmkhs_holdModeAltitude",
            "bmkhs_holdModeAttitude",
            "bmkhs_holdModesOff",
            "bmkhs_stickyInterrupt"
        };
    };
};
