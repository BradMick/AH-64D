/////////////////////////////////////////////////////////////////////////////////////////////
// Rotors ///////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////
//Physical rotor properties. Model shaping - VRS curve, hover/forward gate,
//airspeed response - stays in Core.

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

    //Tail rotor
    tailRtrPos[]          = {-0.87, -6.98, -0.075};  //m
    tailRtrDesignRpm      = 1403.0;
    tailRtrRpmTrimVal     = 1.01;
    tailRtrGearRatio      = 14.90;
    tailRtrNumBlades      = 4;
    tailRtrBladeRadius    = 1.402;   //m
    tailRtrBladeChord     = 0.253;   //m
    tailRtrBaseThrust     = 10230;   //N
