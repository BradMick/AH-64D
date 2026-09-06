/////////////////////////////////////////////////////////////////////////////////////////////
// Simple Rotor /////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////
//Field reference: \bmkhs_helisim\simpleRotor.hpp
//Airspeed in KNOTS, power in kW, thrust in N, torque in Nm, angles in degrees.

    class Rotors {
        class MainRotor {
            rotorType         = "MAIN";
            thrustAxis        = "Z";
            direction         = "CCW";
            position[]        = {0.0, 2.06, 0.70};

            bladeRadius       = 7.315;
            rotorInertia      = 5152;     //(1/3)*72.108*7.315^2*4
            bladePitchMin     = 1.0;
            bladePitchMax     = 19.0;
            designRpm         = 289.0;
            gearRatio         = 72.291;
            rpmTrimVal        = 1.01;
            heightAgl         = 3.606;

            baseThrust        = 102306;   //max gross weight * g
            maxPower          = 2133;     //both engines
            refRpm            = 20900;

            groundEffectGain  = 0.31;
            climbGain         = 0.73;
            autoroTorque      = 5.0;

            //Multiples of baseThrust, not Nm. 3.17674 = the old 100000*3.25
            //against baseThrust 102306, so authority is unchanged.
            pitchAuthority    = 3.17674;
            rollAuthority     = 0.95302;
            yawAuthority      = 1.0;

            rollCouple        = 0.0;
            thrustTiltRoll    = -6.0;
            //Lon was never wired up in the old model; lat ran with an unverified
            //sign. Both want air time.
            flapbackLon       = 0.0;
            flapbackLat       = 10.0;

            vne               = 250;
            vbe               = 75;
            etl               = 24;

            //Translational lift. Trough at 70 kt, recovered by 140.
            thrustVsAirspeed[] = {
                {  0, 1.164}, { 20, 1.059}, { 40, 0.953}, { 70, 0.848},
                { 90, 0.889}, {100, 0.890}, {120, 0.947}, {130, 0.990},
                {140, 1.043}
            };

            //Linear in the old model.
            thrustVsCollective[] = {
                {0.00, 0.032},
                {1.00, 1.000}
            };

            //Power required. Bucket bottoms out at Vbe.
            powerVsAirspeed[] = {
                {  0, 0.94}, {  5, 0.93}, { 10, 0.90}, { 15, 0.87},
                { 20, 0.82}, { 25, 0.78}, { 40, 0.62}, { 50, 0.54},
                { 60, 0.50}, { 70, 0.49}, { 80, 0.50}, { 90, 0.52},
                {100, 0.56}, {110, 0.64}, {120, 0.72}, {130, 0.85},
                {140, 1.01}, {150, 1.18}
            };

            powerVsCollective[] = {
                {0.000, 0.000}, {0.050, 0.760}, {0.225, 0.798},
                {0.250, 1.000}, {0.850, 1.000}, {1.000, 1.500}
            };
        };

        class TailRotor {
            rotorType         = "TAIL";
            thrustAxis        = "X";
            direction         = "CCW";
            position[]        = {-0.87, -6.98, -0.075};

            bladeRadius       = 1.402;
            rotorInertia      = 0;        //not on the Nr integration path
            designRpm         = 1403.0;
            gearRatio         = 14.90;
            rpmTrimVal        = 1.01;
            refRpm            = 20900;

            baseThrust        = 10230;

            //~8% of total power at hover, more on a pedal input because it
            //scales off the tail's own thrust.
            torqueScalar      = 0.008;

            rollCouple        = 0.25;

            vne               = 250;
            vbe               = 75;
            etl               = 24;

            //Flat - OGE thrust point, fin offload does the rest.
            thrustVsAirspeed[] = {
                {0, 1.0}, {140, 1.0}
            };

            //2:1 asymmetric - left pedal has double the authority of right.
            thrustVsCollective[] = {
                {-1.00,  2.0000}, {-0.90,  1.9600}, {-0.80,  1.8500},
                {-0.70,  1.7000}, {-0.60,  1.5000}, {-0.50,  1.2500},
                {-0.40,  0.9600}, {-0.30,  0.6800}, {-0.20,  0.4000},
                {-0.10,  0.1700}, { 0.00,  0.0000}, { 0.10, -0.1700},
                { 0.20, -0.3200}, { 0.30, -0.4600}, { 0.40, -0.5900},
                { 0.50, -0.7000}, { 0.60, -0.7900}, { 0.70, -0.8600},
                { 0.80, -0.9200}, { 0.90, -0.9600}, { 1.00, -1.0000}
            };
        };
    };
