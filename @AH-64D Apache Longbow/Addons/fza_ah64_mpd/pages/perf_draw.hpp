    class perf_draw {

    class lines {
        type = line;
        width = 3;
        points[] = {
            //Left side, vertical
            {{0.300, 0.982}, 1}, 
            {{0.300, 0.929}, 1}, {},
            //Left side, top horizontal
            {{0.300, 0.929}, 1}, 
            {{0.334, 0.929}, 1}, {},
        };
    };

    class vabs {
        ///////////////// T ///////////////
        MPD_ARROW_C(ENG, MPD_POS_BUTTON_TB_1_X, MPD_POS_BUTTON_T_Y, 3)
        MPD_TEXT_C(ENG,  MPD_POS_BUTTON_TB_1_X, MPD_POS_BUTTON_T_Y, MPD_TEXT_STATIC("ENG"))

        MPD_ARROW_C(FLT, MPD_POS_BUTTON_TB_2_X, MPD_POS_BUTTON_T_Y, 3)
        MPD_TEXT_C(FLT,  MPD_POS_BUTTON_TB_2_X, MPD_POS_BUTTON_T_Y, MPD_TEXT_STATIC("FLT"))

        MPD_ARROW_C(FUEL, MPD_POS_BUTTON_TB_3_X, MPD_POS_BUTTON_T_Y, 4)
        MPD_TEXT_C(FUEL,  MPD_POS_BUTTON_TB_3_X, MPD_POS_BUTTON_T_Y, MPD_TEXT_STATIC("FUEL"))

        MPD_ARROW_C(UTIL, MPD_POS_BUTTON_TB_6_X, MPD_POS_BUTTON_T_Y, 5)
        MPD_TEXT_C(UTIL,  MPD_POS_BUTTON_TB_6_X, MPD_POS_BUTTON_T_Y, MPD_TEXT_STATIC("UTIL"))

        ///////////////// L ///////////////
        MPD_BOX_BAR_R(PA, MPD_POS_BUTTON_L_X, MPD_POS_BUTTON_LR_1_Y)
        MPD_TEXT_R(PA,    MPD_POS_BUTTON_L_X, MPD_POS_BUTTON_LR_1_Y - 0.5*MPD_TEXT_HEIGHT, MPD_TEXT_STATIC("PA>"))
        MPD_TEXT_R(PA_IN, MPD_POS_BUTTON_L_X, MPD_POS_BUTTON_LR_1_Y + 0.5*MPD_TEXT_HEIGHT, MPD_TEXT_USER(MFD_TEXT_IND_PERF_PA))

        MPD_BOX_BAR_R(FAT, MPD_POS_BUTTON_L_X, MPD_POS_BUTTON_LR_2_Y)
        MPD_TEXT_R(FAT,    MPD_POS_BUTTON_L_X, MPD_POS_BUTTON_LR_2_Y - 0.5*MPD_TEXT_HEIGHT, MPD_TEXT_STATIC("FAT>"))
        MPD_TEXT_R(FAT_IN, MPD_POS_BUTTON_L_X, MPD_POS_BUTTON_LR_2_Y + 0.5*MPD_TEXT_HEIGHT, MPD_TEXT_USER(MFD_TEXT_IND_PERF_FAT))

        MPD_BOX_BAR_R(GWT, MPD_POS_BUTTON_L_X, MPD_POS_BUTTON_LR_3_Y)
        MPD_TEXT_R(GWT,    MPD_POS_BUTTON_L_X, MPD_POS_BUTTON_LR_3_Y - 0.5*MPD_TEXT_HEIGHT, MPD_TEXT_STATIC("GWT>"))
        MPD_TEXT_R(GWT_IN, MPD_POS_BUTTON_L_X, MPD_POS_BUTTON_LR_3_Y + 0.5*MPD_TEXT_HEIGHT, MPD_TEXT_USER(MFD_TEXT_IND_PERF_GWT))

        ///////////////// B ///////////////
        MPD_TEXT_C(PERF, MPD_POS_BUTTON_TB_1_X, MPD_POS_BUTTON_B_Y, MPD_TEXT_STATIC("PERF"))

        MPD_BOX_C(PERF,  MPD_POS_BUTTON_TB_2_X, MPD_POS_BUTTON_B_Y, 3)
        MPD_TEXT_C(CUR,  MPD_POS_BUTTON_TB_2_X, MPD_POS_BUTTON_B_Y, MPD_TEXT_STATIC("CUR"))
        MPD_TEXT_C(MAX,  MPD_POS_BUTTON_TB_3_X, MPD_POS_BUTTON_B_Y, MPD_TEXT_STATIC("MAX"))
        MPD_TEXT_C(PLAN, MPD_POS_BUTTON_TB_4_X, MPD_POS_BUTTON_B_Y, MPD_TEXT_STATIC("PLAN"))

        MPD_TEXT_C(MODE, MPD_POS_BUTTON_TB_3_X, MPD_POS_BUTTON_B_Y - 1.1*MPD_TEXT_HEIGHT, MPD_TEXT_STATIC("PERF MODE"))

        MPD_ARROW_C(HIT, MPD_POS_BUTTON_TB_5_X, MPD_POS_BUTTON_B_Y, 3)
        MPD_TEXT_C(HIT,  MPD_POS_BUTTON_TB_5_X, MPD_POS_BUTTON_B_Y, MPD_TEXT_STATIC("HIT"))

        MPD_TEXT_C(WT,   MPD_POS_BUTTON_TB_6_X, MPD_POS_BUTTON_B_Y, MPD_TEXT_STATIC("WT"))
    };
};