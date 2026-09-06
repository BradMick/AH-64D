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
    mainRtrBladePitchMin  = 1.0;     //deg
    mainRtrBladePitchMax  = 19.0;    //deg
    mainRtrBaseThrust     = 102306;  //N, max gross weight * g
    mainRtrGearRatio      = 72.291;  //shared with the transmission model

    //Flapback gain, deg of disc tilt per unit advance ratio. The advancing blade lifts more
    //than the retreating one, so the disc tilts as speed builds. The BET model derives this
    //from blade dynamics; the simple model needs it as a gain.
    //NOTE: longitudinal is NOT WIRED UP - see fn_simpleRotorMain. Lateral is active but its
    //sign was never verified in the air. Both want a tuning session.
    mainRtrFlapbackLon    = 0.0;     //deg per unit mu
    mainRtrFlapbackLat    = 10.0;    //deg per unit mu

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
    tailRtrDamageThresh   = 0.85;    //disc damage at which the rotor stops

    //Envelope speeds, m/s - the same values core.hpp holds as VEL_* macros.
    tailRtrVne            = 128.611;
    tailRtrVrs            = 24.384;
    tailRtrEtl            = 12.347;
