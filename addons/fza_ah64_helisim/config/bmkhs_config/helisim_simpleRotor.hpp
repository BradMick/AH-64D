/////////////////////////////////////////////////////////////////////////////////////////////
// Simple Rotor /////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////
//Control torques the simple rotor model applies. Not read by the BET rotor.

    cyclicPitchTorque = 4500.0; //Nm
    cyclicRollTorque  = 1500.0; //Nm
    pedalYawTorque    = 5000.0; //Nm

    //Main rotor
    mainRtrPos[]          = {0.0, 2.06, 0.70};  //m, x = right, y = forward, z = up
    mainRtrHeightAgl      = 3.606;   //m, hub height above ground on the wheels
    mainRtrDesignRpm      = 289.0;
    mainRtrRpmTrimVal     = 1.01;
    mainRtrNumBlades      = 4;
    mainRtrBladeRadius    = 7.315;   //m
    mainRtrBladeChord     = 0.533;   //m
    mainRtrBladeMass      = 72.108;  //kg
    mainRtrBladeHingeOff  = 0.038;   //fraction of blade radius
    mainRtrBaseThrust     = 102306;  //N, max gross weight * g
    mainRtrGearRatio      = 72.291;  //shared with the transmission model

    //Flapback gain, deg of disc tilt per unit advance ratio. The advancing blade lifts more
    //than the retreating one, so the disc tilts as speed builds. The BET model derives this
    //from blade dynamics; the simple model needs it as a gain.
    //NOTE: longitudinal is NOT WIRED UP - see fn_simpleRotorMain. Lateral is active but its
    //sign was never verified in the air. Both want a tuning session.
    mainRtrFlapbackLon    = 0.0;     //deg per unit mu
    mainRtrFlapbackLat    = 10.0;    //deg per unit mu


    /////////////////////////////////////////////////////////////////////////
    // Main rotor tables
    /////////////////////////////////////////////////////////////////////////

    //ground effect gain vs gross weight (kg)
    mainRtrGndEffTable[] = {
        {6804, 0.189}, {7711, 0.170}, {8165, 0.187},
        {8618, 0.310}, {9525, 0.509}
    };

    //tip loss vs gross weight (kg)
    mainRtrTipLossTable[] = {
        {6804, 1.108}, {7711, 1.050}, {8165, 1.000},
        {8618, 0.958}, {9525, 0.890}
    };

    //Thrust vs collective, by pressure altitude (ft). ONE 2-D surface: the old
    //blade-pitch ramp, its altitude-indexed floor, and the per-Nr altitude
    //table, evaluated together. Three terms became one; worst deviation
    //against the original is 123 N of 102306, and under 0.18% above 0.3
    //collective. Multiply by Nr fraction in the model, as before.
    mainRtrThrustVsCollective[] = {
        {   0, {{0.00, 0.0969}, {1.00, 1.1680}}},
        {2000, {{0.00, 0.1449}, {1.00, 1.4220}}},
        {4000, {{0.00, 0.1530}, {1.00, 1.7450}}},
        {6000, {{0.00, 0.1950}, {1.00, 2.1320}}},
        {8000, {{0.00, 0.2440}, {1.00, 2.5610}}}
    };

    //exponent on (1 + V/Vbe), vs airspeed (m/s)
    mainRtrVelExponentTable[] = {
        {0.00, 0.000}, {10.29, 0.209}, {20.58, 0.558},
        {36.01, 0.606}, {46.30, 0.497}, {51.44, 0.474},
        {61.73, 0.392}, {66.88, 0.397}, {72.02, 0.428}
    };

    //yaw torque scalar vs airspeed (m/s)
    mainRtrTorqueScalarTable[] = {
        {0.00, 1.00}, {10.29, 1.00}, {20.58, 1.00},
        {36.01, 1.00}, {46.30, 1.00}, {51.44, 1.00},
        {61.73, 1.00}, {66.88, 1.00}, {72.02, 1.00}
    };

    //thrust scalar vs airspeed (m/s)
    mainRtrThrustVsAirspeed[] = {
        {0.00, 1.164}, {10.29, 1.059}, {20.58, 0.953},
        {36.01, 0.848}, {46.30, 0.889}, {51.44, 0.890},
        {61.73, 0.947}, {66.88, 0.990}, {72.02, 1.043}
    };

    //induced power vs airspeed (m/s)
    mainRtrInducedPwrVelTable[] = {
        {0.00, 1.202}, {10.29, 0.970}, {20.58, 0.951},
        {36.01, 0.923}, {46.30, 0.904}, {51.44, 0.895},
        {61.73, 0.876}, {66.88, 0.867}, {69.96, 0.861},
        {72.02, 0.899}
    };

    //collective correction on induced power, vs airspeed (m/s)
    mainRtrInducedPwrCollTable[] = {
        {0.00, 0.649}, {10.29, 0.591}, {20.58, 0.602},
        {36.01, 0.760}, {46.30, 0.860}, {51.44, 0.871},
        {61.73, 0.860}, {66.88, 0.827}, {69.96, 0.799},
        {72.02, 0.840}
    };

    //torque correction vs collective
    mainRtrCollTorqueCorrTable[] = {
        {0.000, 0.000}, {0.050, 0.760}, {0.225, 0.798},
        {0.250, 1.000}, {0.850, 1.000}, {1.000, 1.500}
    };

    //driving torque vs descent rate (m/s)
    mainRtrAutoroTorqueTable[] = {
        {-20.32, -100.0}, {-15.24, -50.0}, {-12.70, -25.0},
        {-10.16, -10.0}, {-7.62, -5.0}, {0.00, 0.0}
    };

    //cruise torque reference vs airspeed (m/s)
    mainRtrCruiseTqTable[] = {
        {0.00, 0.94}, {2.57, 0.93}, {5.14, 0.90},
        {7.72, 0.87}, {10.29, 0.82}, {12.86, 0.78},
        {20.58, 0.62}, {25.72, 0.54}, {30.87, 0.50},
        {36.01, 0.49}, {41.16, 0.50}, {46.30, 0.52},
        {51.44, 0.56}, {56.59, 0.64}, {61.73, 0.72},
        {66.88, 0.85}, {72.02, 1.01}, {77.17, 1.18}
    };

    //climb thrust vs excess torque
    mainRtrTqRoCTable[] = {
        {0.0, 0.000}, {0.1, 0.078}, {0.2, 0.151},
        {0.3, 0.224}, {0.4, 0.297}, {0.5, 0.369},
        {0.6, 0.457}, {0.7, 0.517}, {0.8, 0.587}
    };

    //Tail rotor
    tailRtrPos[]          = {-0.87, -6.98, -0.075};  //m
    //How the rotor is pointed - {pitch, roll, yaw} deg applied to a mast that
    //starts vertical. Rolled 90 puts thrust along +X, which is what the model
    //used to hardcode. Everything else - which flow is through the disc, which
    //is across it, which way the moment goes - follows from this.
    tailRtrRotation[]     = {0.0, 90.0, 0.0};        //deg
    tailRtrDesignRpm      = 1403.0;
    tailRtrRpmTrimVal     = 1.01;
    tailRtrGearRatio      = 14.90;
    tailRtrNumBlades      = 4;
    tailRtrBladeRadius    = 1.402;   //m
    tailRtrBladeChord     = 0.253;   //m
    tailRtrBaseThrust     = 10230;   //N

    //Pedal to thrust. ASYMMETRIC - left pedal has roughly double the authority
    //of right, because the blade pitch range is not symmetric about zero.
    tailRtrPitchThrustTable[] = {
        {-1.00,  2.0000}, {-0.90,  1.9600}, {-0.80,  1.8500}, {-0.70,  1.7000},
        {-0.60,  1.5000}, {-0.50,  1.2500}, {-0.40,  0.9600}, {-0.30,  0.6800},
        {-0.20,  0.4000}, {-0.10,  0.1700}, { 0.00,  0.0000}, { 0.10, -0.1700},
        { 0.20, -0.3200}, { 0.30, -0.4600}, { 0.40, -0.5900}, { 0.50, -0.7000},
        { 0.60, -0.7900}, { 0.70, -0.8600}, { 0.80, -0.9200}, { 0.90, -0.9600},
        { 1.00, -1.0000}
    };

    //Thrust vs airspeed (m/s). ONE curve: the old flat authority table times
    //its (1 + V/Vbe)^0.4 term, evaluated at each breakpoint. Two terms became
    //one; worst interpolation error against the original is 0.17% at 9 kt.
    tailRtrThrustVsAirspeed[] = {
        { 0.00, 1.0000}, {10.29, 1.0992}, {20.58, 1.1865}, {36.01, 1.3017},
        {46.30, 1.3708}, {51.44, 1.4034}, {61.73, 1.4655}, {66.88, 1.4951},
        {72.02, 1.5239}
    };
    tailRtrRollCouple     = 0.25;    //fraction of the thrust moment reaching roll
