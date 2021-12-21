class wptSto {
    class vabs {
        #include "..\components\vabs_top.hpp"
        #include "..\components\vabs_right.hpp"

        //L1
        MPD_TEXT_R(NOW,        MPD_POS_BUTTON_L_X, MPD_POS_BUTTON_LR_1_Y, MPD_TEXT_STATIC("NOW"))
        //L5
        MPD_BOX_R(STO,         MPD_POS_BUTTON_L_X, MPD_POS_BUTTON_LR_5_Y, 3)
        MPD_TEXT_R(STO,        MPD_POS_BUTTON_L_X, MPD_POS_BUTTON_LR_5_Y, MPD_TEXT_STATIC("STO"))
        //L5
        
        MPD_BOX_BAR_R(TYPE,    MPD_POS_BUTTON_L_X, MPD_POS_BUTTON_LR_6_Y)
        MPD_TEXT_R(TYPE_Label, MPD_POS_BUTTON_L_X, MPD_POS_BUTTON_LR_6_Y - 0.5 * MPD_TEXT_HEIGHT, MPD_TEXT_STATIC("TYPE"))
        MPD_BOX_R(TYPE,        MPD_POS_BUTTON_L_X, MPD_POS_BUTTON_LR_6_Y + 0.5 * MPD_TEXT_HEIGHT, 2)
        MPD_TEXT_R(TYPE,       MPD_POS_BUTTON_L_X, MPD_POS_BUTTON_LR_6_Y + 0.5 * MPD_TEXT_HEIGHT, MPD_TEXT_STATIC("WP"))

        /* <--This is only applicable for the THRT page
        class navPhase {
            condition = __EVAL(format["1 - user%1", MFD_IND_TSD_PHASE + MFD_OFFSET]);
            MPD_TEXT_R(TYPE,       MPD_POS_BUTTON_L_X, MPD_POS_BUTTON_LR_6_Y + 0.5 * MPD_TEXT_HEIGHT, MPD_TEXT_STATIC("WP"))
        };

        class atkPhase {
            condition = __EVAL(format["user%1", MFD_IND_TSD_PHASE + MFD_OFFSET]);
            MPD_TEXT_R(TYPE,       MPD_POS_BUTTON_L_X, MPD_POS_BUTTON_LR_6_Y + 0.5 * MPD_TEXT_HEIGHT, MPD_TEXT_STATIC("TG"))
        };*/
    };
};