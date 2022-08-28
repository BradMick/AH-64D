
#define MFD_IND_BATT 0
#define MFD_IND_PAGE_LEFT 1
#define MFD_IND_PAGE_RIGHT 2
#define MFD_IND_KU_STATE 3

#define MFD_TEXT_IND_UFDTEXT0 0
#define MFD_TEXT_IND_KU 9
#define MFD_OFFSET_L 10
#define MFD_OFFSET_R 30

//Flight page
#define MFD_TEXT_IND_FLT_TORQUE       0
#define MFD_TEXT_IND_FLT_AIRSPEED     1
#define MFD_TEXT_IND_FLT_DESTINATION  2
#define MFD_TEXT_IND_FLT_GROUNDSPEED  3
#define MFD_TEXT_IND_FLT_DISTANCETOGO 4
#define MFD_TEXT_IND_FLT_TIMETOGO     5
#define MFD_TEXT_IND_FLT_BALT         6
#define MFD_TEXT_IND_FLT_GALT         7

#define MFD_IND_FLT_TURN 0
#define MFD_IND_FLT_SLIP 1
#define MFD_IND_FLT_COMMAND_HEADING 2
#define MFD_IND_FLT_FCR_CENTERLINE 3
#define MFD_IND_FLT_ALTERNATE_SENSOR 4
#define MFD_IND_FLT_FLY_TO_CUE_X 5
#define MFD_IND_FLT_FLY_TO_CUE_Y 6
#define MFD_IND_FLT_FLIGHT_PATH_X 7
#define MFD_IND_FLT_FLIGHT_PATH_Y 8

//Fuel page
#define MFD_TEXT_IND_FUEL_FWD 0
#define MFD_TEXT_IND_FUEL_AFT 1
#define MFD_TEXT_IND_FUEL_INT 2
#define MFD_TEXT_IND_FUEL_ENDR_INT 3
#define MFD_TEXT_IND_FUEL_FLOW_1 4
#define MFD_TEXT_IND_FUEL_FLOW_2 5
#define MFD_TEXT_IND_FUEL_FLOW_TOT 6

//Engine page
#define MFD_IND_ENG_TORQUE_1 0
#define MFD_IND_ENG_TORQUE_2 1
#define MFD_IND_ENG_TGT_1 2
#define MFD_IND_ENG_TGT_2 3
#define MFD_IND_ENG_NP_1 4
#define MFD_IND_ENG_NP_2 5
#define MFD_IND_ENG_NR 6
#define MFD_IND_ENG_TORQUE_BAR 7
#define MFD_IND_ENG_TGT_BAR 8
#define MFD_IND_ENG_MODE 9
#define MFD_IND_ENG_START 10

#define MFD_IND_ENG_WCA_1 11
#define MFD_IND_ENG_WCA_2 12
#define MFD_IND_ENG_WCA_3 13
#define MFD_IND_ENG_WCA_4 14
#define MFD_IND_ENG_WCA_5 15
#define MFD_IND_ENG_WCA_6 16
#define MFD_IND_ENG_WCA_7 17
#define MFD_IND_ENG_WCA_8 18

#define MFD_TEXT_IND_ENG_TORQUE_1 0
#define MFD_TEXT_IND_ENG_TORQUE_2 1
#define MFD_TEXT_IND_ENG_TGT_1 2
#define MFD_TEXT_IND_ENG_TGT_2 3
#define MFD_TEXT_IND_ENG_NP_1 4
#define MFD_TEXT_IND_ENG_NP_2 5
#define MFD_TEXT_IND_ENG_NR 6
#define MFD_TEXT_IND_ENG_NG_1 7
#define MFD_TEXT_IND_ENG_NG_2 8
#define MFD_TEXT_IND_ENG_OIL_PSI_1 9
#define MFD_TEXT_IND_ENG_OIL_PSI_2 10

#define MFD_TEXT_IND_ENG_WCA_1 11
#define MFD_TEXT_IND_ENG_WCA_2 12
#define MFD_TEXT_IND_ENG_WCA_3 13
#define MFD_TEXT_IND_ENG_WCA_4 14
#define MFD_TEXT_IND_ENG_WCA_5 15
#define MFD_TEXT_IND_ENG_WCA_6 16
#define MFD_TEXT_IND_ENG_WCA_7 17
#define MFD_TEXT_IND_ENG_WCA_8 18

//Weapon Page

// 0 when safe, 1 when armed.
#define MFD_IND_WPN_MASTER_ARM 0
#define MFD_IND_WPN_CHAFF_ARM 1

// 1-indexed position of the selected hellfire
#define MFD_IND_WPN_SELECTED_HF 2
// 1-indexed position of the selected rocket.
#define MFD_IND_WPN_SELECTED_RKT 3
// Current WASed/Selected weapon - 0 - None, 1 - Gun, 2 - Rkt, 3 - Msl, 4 - ATAS (joking)
#define MFD_IND_WPN_WAS 4
#define MFD_IND_WPN_SELECTED_WPN 5
// Whether that rocket pod is present. 0 - neither pod is present, 1 - only (1/2) is present, 2 - only (3/4) is present, 3 - (1/2) and (3/4) present
#define MFD_IND_WPN_RKT_1_4_STATE 6
#define MFD_IND_WPN_RKT_2_3_STATE 7

// 1-indexed (from top) selected burst limit
#define MFD_IND_WPN_SELECTED_BURST_LIMIT 8
// 1-indexed (from top) selected burst limit
#define MFD_IND_WPN_SELECTED_RKT_INV 8
// 0 for SAL, 1 for RF
#define MFD_IND_WPN_SELECTED_MSL_TYPE 8
// 0-indexed missile channel selection for primary and alt
#define MFD_IND_WPN_SELECTED_PRI_CH 9
#define MFD_IND_WPN_SELECTED_ALT_CH 10

#define MFD_TEXT_IND_WPN_ACQ 0
#define MFD_TEXT_IND_WPN_SIGHT 1
#define MFD_TEXT_IND_WPN_CHAFF_QTY 2
#define MFD_TEXT_IND_WPN_RKT_1_4_TEXT 3
#define MFD_TEXT_IND_WPN_RKT_2_3_TEXT 4
#define MFD_TEXT_IND_WPN_GUN_ROUNDS 5

#define MFD_TEXT_IND_WPN_RKT_INV_1_NAME 6
#define MFD_TEXT_IND_WPN_RKT_INV_2_NAME 7
#define MFD_TEXT_IND_WPN_RKT_INV_3_NAME 8
#define MFD_TEXT_IND_WPN_RKT_INV_4_NAME 9
#define MFD_TEXT_IND_WPN_RKT_INV_5_NAME 10
#define MFD_TEXT_IND_WPN_RKT_INV_1_QTY 11
#define MFD_TEXT_IND_WPN_RKT_INV_2_QTY 12
#define MFD_TEXT_IND_WPN_RKT_INV_3_QTY 13
#define MFD_TEXT_IND_WPN_RKT_INV_4_QTY 14
#define MFD_TEXT_IND_WPN_RKT_INV_5_QTY 15
#define MFD_TEXT_IND_WPN_RKT_TOT_QTY 16
#define MFD_TEXT_IND_WPN_RKT_SALVO 17

#define MFD_TEXT_IND_WPN_MSL_TRAJ 6
#define MFD_TEXT_IND_WPN_MSL_PRI_CODE 7
#define MFD_TEXT_IND_WPN_MSL_ALT_CODE 8
#define MFD_TEXT_IND_WPN_MSL_CHAN_1_CODE 9
#define MFD_TEXT_IND_WPN_MSL_CHAN_2_CODE 10
#define MFD_TEXT_IND_WPN_MSL_CHAN_3_CODE 11
#define MFD_TEXT_IND_WPN_MSL_CHAN_4_CODE 12
#define MFD_TEXT_IND_WPN_MSL_SAL_SEL 13
//Text on selected missile
#define MFD_TEXT_IND_WPN_MSL_IMAGE_LINE_1 14
#define MFD_TEXT_IND_WPN_MSL_IMAGE_LINE_2 15

//TSD Root page indices
#define MFD_IND_TSD_ROOT_SHOW_WPT_DATA_CURRTE 0
#define MFD_IND_TSD_ROOT_SHOW_WIND 8
#define MFD_IND_TSD_ROOT_SHOW_ENDR 9

#define MFD_TEXT_IND_TSD_ROOT_ENDR 0
#define MFD_TEXT_IND_TSD_ROOT_WPDEST 1
#define MFD_TEXT_IND_TSD_ROOT_GROUNDSPEED 2
#define MFD_TEXT_IND_TSD_ROOT_WPDIST 3
#define MFD_TEXT_IND_TSD_ROOT_WPETA 4

//TSD Show page indices
#define MFD_IND_TSD_SHOW_WPT_DATA_CURRTE 0
#define MFD_IND_TSD_SHOW_ENEMY_UNITS 1
#define MFD_IND_TSD_SHOW_FRIENDLY_UNITS 2
#define MFD_IND_TSD_SHOW_RLWR 3
#define MFD_IND_TSD_SHOW_PLAN_TGTS 4
#define MFD_IND_TSD_SHOW_CTRLM 5
#define MFD_IND_TSD_SHOW_SHOT 6
#define MFD_IND_TSD_SHOW_HAZ 7
#define MFD_IND_TSD_SHOW_WIND 8
#define MFD_IND_TSD_SHOW_ENDR 9

//Drawing goes here 10 to 15
#define MFD_IND_TSD_SHOW_HSI 16
#define MFD_IND_TSD_SCALE_BOXES 17
#define MFD_IND_TSD_PHASE 18
#define MFD_IND_TSD_SUBPAGE 19

//TSD WPT page indices
#define MFD_IND_TSD_WPT_VARIANT 0
#define MFD_IND_TSD_WPT_ADD_TYPE 1

//TSD RTE page indices
#define MFD_IND_TSD_RTE_VARIANT 0

#define MFD_TEXT_IND_TSD_RTE_DIR_CURWPT 0

#define MFD_TEXT_IND_TSD_WPT_CURRENT_POINT 0
#define MFD_TEXT_IND_TSD_WPT_DETAILS_1 1
#define MFD_TEXT_IND_TSD_WPT_DETAILS_2 2
#define MFD_TEXT_IND_TSD_WPT_DETAILS_3 3

//TSD THRT page indices
#define MFD_IND_TSD_THRT_VARIANT 0
#define MFD_IND_TSD_THRT_ADD_TYPE 1

// FCR Indices
//--User value
#define MFD_IND_FCR_ANIM       0
#define MFD_IND_FCR_SCAN_TYPE  1
//--User text
#define MFD_TEXT_IND_FCR_COUNT 0
#define MFD_TEXT_IND_FCR_SSS   1
#define MFD_TEXT_IND_FCR_RRS   2
#define MFD_TEXT_IND_FCR_SS    3
#define MFD_TEXT_IND_FCR_WC    4
#define MFD_TEXT_IND_FCR_ACQ   5
#define MFD_TEXT_IND_FCR_WS    6

//ASE Indices
#define MFD_IND_ASE_CHAFF_STATE  0
#define MFD_IND_ASE_RLWR_PWR     1
#define MFD_IND_ASE_IRJAM_PWR    2
#define MFD_IND_ASE_IRJAM_STATE  3
#define MFD_IND_ASE_RFJAM_STATE  4
#define MFD_IND_ASE_AUTOPAGE     5
//--Azimuth
#define MFD_IND_ASE_OBJECT_01_AZ 6
#define MFD_IND_ASE_OBJECT_02_AZ 7
#define MFD_IND_ASE_OBJECT_03_AZ 8
#define MFD_IND_ASE_OBJECT_04_AZ 9
#define MFD_IND_ASE_OBJECT_05_AZ 10
#define MFD_IND_ASE_OBJECT_06_AZ 11
#define MFD_IND_ASE_OBJECT_07_AZ 12
//--Mode
#define MFD_IND_ASE_OBJECT_01_MD 13
#define MFD_IND_ASE_OBJECT_02_MD 14
#define MFD_IND_ASE_OBJECT_03_MD 15
#define MFD_IND_ASE_OBJECT_04_MD 16
#define MFD_IND_ASE_OBJECT_05_MD 17
#define MFD_IND_ASE_OBJECT_06_MD 18
#define MFD_IND_ASE_OBJECT_07_MD 19
//--Text
#define MFD_TEXT_IND_ASE_CHAFF_COUNT 0
#define MFD_TEXT_IND_ASE_RLWR_COUNT  1

//Perf page
//--Conditions & Weight
#define MFD_TEXT_IND_PERF_PA  0
#define MFD_TEXT_IND_PERF_FAT 1
#define MFD_TEXT_IND_PERF_GWT 2
//--Hover Torque (TQ)
#define MFD_TEXT_IND_PERF_HVR_TQ_IGE_OGE     3
#define MFD_TEXT_IND_PERF_GO_NOGO_TQ_IGE_OGE 4
#define MFD_TEXT_IND_PERF_GO_IND_TQ          5
//--Max Gross Weight
#define MFD_TEXT_IND_PERF_MAXGWT_DE_IGE_OGE 6
#define MFD_TEXT_IND_PERF_MAXGWT_SE_IGE_OGE 7
//--Max Torque (TQ)
#define MFD_TEXT_IND_PERF_MAX_TQ_DE 8
#define MFD_TEXT_IND_PERF_MAX_TQ_SE 9
//--Cruise
#define MFD_TEXT_IND_PERF_MAX_RNG_END_TQ 10
#define MFD_TEXT_IND_PERF_MAX_RNG_END_FF 11
//--TAS
#define MFD_TEXT_IND_PERF_VNE     12
#define MFD_TEXT_IND_PERF_VSSE    13
#define MFD_TEXT_IND_PERF_RNG_SPD 14
#define MFD_TEXT_IND_PERF_END_SPD 15

// PAGE INDEXES
#define MPD_PAGE_OFF  0
#define MPD_PAGE_MENU 1
#define MPD_PAGE_FLT  2
#define MPD_PAGE_WCA  3
#define MPD_PAGE_FUEL 4
#define MPD_PAGE_ENG  5
#define MPD_PAGE_WPN  6
#define MPD_PAGE_TSD  7
#define MPD_PAGE_DMS  8
#define MPD_PAGE_DTU  9
#define MPD_PAGE_FCR  10
#define MPD_PAGE_ASE  11
#define MPD_PAGE_PERF 12

#define BOOLTONUM [0,1] select
#define MFD_INDEX_OFFSET(num) (([MFD_OFFSET_L, MFD_OFFSET_R] select _mpdIndex) + (num))