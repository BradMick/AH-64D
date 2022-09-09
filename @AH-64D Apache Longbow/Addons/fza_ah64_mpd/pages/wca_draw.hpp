class wcaDraw {
    class outlines {
        type = line;
        width = 3;
        points[] = {
            //Center lines
            {{0.496, 0.174}, 1}, {{0.496, 0.832}, 1}, {},
            {{0.504, 0.174}, 1}, {{0.504, 0.832}, 1}, {},
            //Curved box
            MPD_POINTS_BOX(Null, (0.5 - MPD_TEXT_WIDTH * 6.5), 0.105, (13 * MPD_TEXT_WIDTH), MPD_TEXT_HEIGHT) 
        };
    };

    //T1
    MPD_ARROW_C(DTU, MPD_POS_BUTTON_TB_1_X, MPD_POS_BUTTON_T_Y, 3)
    MPD_TEXT_C(DTU, MPD_POS_BUTTON_TB_1_X, MPD_POS_BUTTON_T_Y, MPD_TEXT_STATIC("DTU"))
    //T2
    //MPD_ARROW_C(FAULT, MPD_POS_BUTTON_TB_2_X, MPD_POS_BUTTON_T_Y, 5)
    MPD_BOX_BAR_T(FAULT, MPD_POS_BUTTON_TB_2_X, MPD_POS_BUTTON_T_Y)
    MPD_TEXT_C(FAULT,    MPD_POS_BUTTON_TB_2_X, MPD_POS_BUTTON_T_Y, MPD_TEXT_STATIC("FAULT"))
    //T3
    //MPD_ARROW_C(IBIT, MPD_POS_BUTTON_TB_3_X, MPD_POS_BUTTON_T_Y, 4)
    MPD_BOX_BAR_T(IBIT, MPD_POS_BUTTON_TB_3_X, MPD_POS_BUTTON_T_Y)
    MPD_TEXT_C(IBIT, MPD_POS_BUTTON_TB_3_X, MPD_POS_BUTTON_T_Y, MPD_TEXT_STATIC("IBIT"))
    //T5
    //MPD_ARROW_C(VERS, MPD_POS_BUTTON_TB_5_X, MPD_POS_BUTTON_T_Y, 4)
    MPD_BOX_BAR_T(VERS, MPD_POS_BUTTON_TB_5_X, MPD_POS_BUTTON_T_Y)
    MPD_TEXT_C(VERS,    MPD_POS_BUTTON_TB_5_X, MPD_POS_BUTTON_T_Y, MPD_TEXT_STATIC("VERS"))
    //T6
    MPD_ARROW_C(UTIL, MPD_POS_BUTTON_TB_6_X, MPD_POS_BUTTON_T_Y, 4)
    MPD_TEXT_C(UTIL, MPD_POS_BUTTON_TB_6_X, MPD_POS_BUTTON_T_Y, MPD_TEXT_STATIC("UTIL"))

    //B1
    MPD_TEXT_C(ENG, MPD_POS_BUTTON_TB_1_X, MPD_POS_BUTTON_B_Y, MPD_TEXT_STATIC("ENG"))
    //B4
    MPD_TEXT_C(RESET, MPD_POS_BUTTON_TB_4_X, MPD_POS_BUTTON_B_Y, MPD_TEXT_STATIC("RESET"))
    //B6
    MPD_ARROW_C(WCA,    MPD_POS_BUTTON_TB_6_X, MPD_POS_BUTTON_B_Y, 3)
    MPD_BOX_TALL_C(WCA, MPD_POS_BUTTON_TB_6_X, MPD_POS_BUTTON_B_Y, 3)
    MPD_TEXT_C(WCA,     MPD_POS_BUTTON_TB_6_X, MPD_POS_BUTTON_B_Y, MPD_TEXT_STATIC("WCA"))

    MPD_TEXT_C(WCACenter, 0.5, 0.105, MPD_TEXT_STATIC("W/C/A HISTORY"))

    #define MPD_WCA_COLUMN_1_X (0.49 - 18 * MPD_TEXT_WIDTH)
    #define MPD_WCA_COLUMN_2_X 0.52
    #define MPD_WCA_COLUMN_Y 0.17
    #define MPD_WCA_COLUMN_SPACING (MPD_TEXT_HEIGHT + 0.015)

    #define MPD_WCA_ITEM(userNum, posX, posY, yIndex) class WcaItem##userNum { \
        color[] = {__EVAL("2 - user" + str (MFD_OFFSET + userNum)), __EVAL("user" + str (MFD_OFFSET + userNum)), __EVAL("0.02 * user" + str (MFD_OFFSET + userNum)) + " - 0.02", 1}; \
        MPD_TEXT_R(Text, posX, (posY + yIndex * MPD_WCA_COLUMN_SPACING), MPD_TEXT_USER(userNum)) \
    };

    MPD_WCA_ITEM(0, MPD_WCA_COLUMN_1_X, MPD_WCA_COLUMN_Y, 0)
    MPD_WCA_ITEM(1, MPD_WCA_COLUMN_1_X, MPD_WCA_COLUMN_Y, 1)
    MPD_WCA_ITEM(2, MPD_WCA_COLUMN_1_X, MPD_WCA_COLUMN_Y, 2)
    MPD_WCA_ITEM(3, MPD_WCA_COLUMN_1_X, MPD_WCA_COLUMN_Y, 3)
    MPD_WCA_ITEM(4, MPD_WCA_COLUMN_1_X, MPD_WCA_COLUMN_Y, 4)
    MPD_WCA_ITEM(5, MPD_WCA_COLUMN_1_X, MPD_WCA_COLUMN_Y, 5)
    MPD_WCA_ITEM(6, MPD_WCA_COLUMN_1_X, MPD_WCA_COLUMN_Y, 6)
    MPD_WCA_ITEM(7, MPD_WCA_COLUMN_1_X, MPD_WCA_COLUMN_Y, 7)
    MPD_WCA_ITEM(8, MPD_WCA_COLUMN_1_X, MPD_WCA_COLUMN_Y, 8)
    MPD_WCA_ITEM(9, MPD_WCA_COLUMN_2_X, MPD_WCA_COLUMN_Y, 0)
    MPD_WCA_ITEM(10, MPD_WCA_COLUMN_2_X, MPD_WCA_COLUMN_Y, 1)
    MPD_WCA_ITEM(11, MPD_WCA_COLUMN_2_X, MPD_WCA_COLUMN_Y, 2)
    MPD_WCA_ITEM(12, MPD_WCA_COLUMN_2_X, MPD_WCA_COLUMN_Y, 3)
    MPD_WCA_ITEM(13, MPD_WCA_COLUMN_2_X, MPD_WCA_COLUMN_Y, 4)
    MPD_WCA_ITEM(14, MPD_WCA_COLUMN_2_X, MPD_WCA_COLUMN_Y, 5)
    MPD_WCA_ITEM(15, MPD_WCA_COLUMN_2_X, MPD_WCA_COLUMN_Y, 6)
    MPD_WCA_ITEM(16, MPD_WCA_COLUMN_2_X, MPD_WCA_COLUMN_Y, 7)
    MPD_WCA_ITEM(17, MPD_WCA_COLUMN_2_X, MPD_WCA_COLUMN_Y, 8)
};