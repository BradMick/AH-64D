class Fza_SfmPlus {
    emptyMassFCR    = 6609; //kg
    emptyMassNonFCR = 6314; //kg

    stabPos[]  = {0.0, -7.207, -0.50};
    stabWidth  = 3.22;  //m
    stabLength = 1.07; //m

    initFuelFrac   = 0.22;
    maxFwdFuelMass = 473; //1043lbs in kg
    //maxCtrFuelMass = 300;	//663lbs in kg, net yet implemented, center robbie
    maxAftFuelMass = 669; 	//1474lbs in kg
    //maxExtFuelMass = 690;     //1541lbs in kg, not yet implemented, 230gal external tank

    //Engine Data
    engSimTime  = 8.0;

    engIdleTQ   = 0.055;
    engFlyTQ    = 0.18;

    engStartNG  = 0.23;
    engIdleNG   = 0.679;
    engFlyNG    = 0.834;
    engMaxNG    = 1.04;

    engStartNP  = 0.10;
    engIdleNP   = 0.57;
    engFlyNP    = 1.01;

    //----------------0-NG-----1-TGT----2-TQ----3-NP----4-Oil
    engBaseTable[] =	{{0.000,	  0,	0.00,	0.00,	0.00},		//Off
                         {0.262,      3,	0.01,	0.00,	0.01},	
                         {0.318,    244,	0.015,	0.00,	0.11},
                         {0.355,    339,	0.02,	0.00,	0.19},
                         {0.407,    435,	0.025,	0.00,	0.25},
                         {0.455,    513,	0.03,	0.00,	0.29},
                         {0.548,    622,	0.035,	0.01,	0.38},
                         {0.643,    678,	0.04,	0.02,	0.41},
                         {0.670,    582,	0.045,	0.03,	0.48},
                         {0.672,    565,	0.05,	0.12,	0.51},
                         {0.675,    530,	0.055,	0.20,	0.58},
                         {0.677,    505,	0.06,	0.37,	0.62},
                         {0.679,    500,	0.07,	0.55,	0.70},		//Idle
                         {0.698,    525,	0.08,	0.59,	0.71},
                         {0.718,    550,	0.09,	0.63,	0.73},
                         {0.737,    566,	0.10,	0.67,	0.77},
                         {0.757,    564,	0.11,	0.71,	0.81},
                         {0.776,    571,	0.12,	0.78,	0.82},
                         {0.795,    552,	0.13,	0.82,	0.84},
                         {0.815,    546,	0.14,	0.95,	0.86},
                         {0.834,    541,	0.15,	1.01,	0.88}};	    //Fly

    //--------------------GWT---IGE---OGE--
    hvrTqTable[] =      {{5896, 0.47, 0.59},    //13000lbs
                         {6350, 0.54, 0.66},    //14000lbs
                         {6803, 0.59, 0.72},    //15000lbs
                         {7257, 0.64, 0.79},    //16000lbs
                         {7711, 0.69, 0.86},    //17000lbs
                         {8164, 0.74, 0.94},    //18000lbs
                         {8618, 0.80, 1.01},    //19000lbs
                         {9071, 0.86, 1.09},    //20000lbs
                         {9525, 0.92, 1.17}};    //21000lbs

    //--------------------GWT---24kt--40kt--60kt--70kt--90kt--100kt-120kt-130kt-150kt
    cruiseTable[] =	    {{5897, 0.48, 0.39, 0.34, 0.34, 0.40, 0.44, 0.62, 0.72, 1.03},
                         {6804, 0.58, 0.47, 0.40, 0.40, 0.43, 0.48, 0.65, 0.77, 1.08},
                         {7711, 0.70, 0.56, 0.47, 0.46, 0.48, 0.53, 0.69, 0.82, 1.14},
                         {8618, 0.83, 0.67, 0.54, 0.53, 0.55, 0.60, 0.75, 0.88, 1.21},
                         {9525, 0.96, 0.78, 0.64, 0.61, 0.63, 0.68, 0.84, 1.00, 1.34}};

    //--------------------TQ----FF (kg/s)
    engFFTable[]  =     {{0.00, 0.0000},
                         {0.07, 0.0216},
                         {0.15, 0.0350},
                         {0.30, 0.0432},
                         {0.40, 0.0480},
                         {0.50, 0.0535},
                         {0.60, 0.0598},
                         {0.70, 0.0661},
                         {0.80, 0.0732},
                         {0.90, 0.0803},
                         {1.00, 0.0866},
                         {1.10, 0.0929},
                         {1.20, 0.0992},
                         {1.30, 0.1055},
                         {1.40, 0.1118}};

    //Stabilator Data
    stabKeyTheta = -5.5;

    //--------------------Coll----30kts--70kts--90kts--110kts--120kts-150kts
    stabTable[] =       {{0.00,  -25.00,  2.5,    5.0,   5.0,   5.0,   5.0},  
                         {0.67,  -25.00, -3.2,   -3.2,  -3.2,  -3.2,  -3.2},  
                         {0.71,  -25.00, -6.0,   -6.0,  -6.0,  -6.0,  -6.0},  
                         {0.81,  -25.00, -9.5,   -9.5,  -9.5,  -9.5,  -9.5},  
                         {0.89,  -25.00, -12.2, -12.2, -12.2, -12.2, -12.2},
                         {0.97,  -25.00, -14.5, -14.5, -14.5, -14.5, -14.5}};

    stabAirfoilTable[] =    //NACA 0012 Airfoil
    {
    //------AoA-{0}----------CL-{1}--------CD-{2}-------------
        {   -180.0,        0.0,           0.0        },  //0  - DO NOT CHANGE!!
        {   -135.0,        0.5,           0.5        },  //1  - DO NOT CHANGE!!
        {   -90.0,         0.0,           0.0        },  //2  - DO NOT CHANGE!!
        {   -18.5,         -1.22580,      0.10236    },  //3  -
        {   -17.5,         -1.30310,      0.07429    },  //4  -
        {   -15.75,        -1.38680,      0.03865    },  //5  -
        {   -10.0,         -1.08070,      0.01499    },  //6  -
        {   -5.0,          -0.55710,      0.00847    },  //7  -
        {   0.0,           0.00000,       0.00540    },  //8  -
        {   5.0,           0.55720,       0.00847    },  //9  -
        {   10.0,          1.08080,       0.01499    },  //10 -
        {   15.75,         1.38810,       0.03863    },  //11 -
        {   17.5,          1.30590,       0.07416    },  //12 -
        {   18.5,          1.22840,       0.10229    },  //13 -
        {   90.0,          0.0,           0.0        },  //14 - DO NOT CHANGE!!
        {   135.0,         -0.5,          -0.5       },  //15 - DO NOT CHANGE!!
        {   180.0,         0.0,           0.0        }   //16 - DO NOT CHANGE!!
    };
};