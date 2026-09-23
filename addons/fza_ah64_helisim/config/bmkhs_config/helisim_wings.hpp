/////////////////////////////////////////////////////////////////////////////////////////////
// Wings ////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////
//A lifting surface is a planform at a position and an angle, so its geometry, its section
//and what it does in flight are declared together here. Core loops over numWings, so an
//aircraft declares as many surfaces as it has - wings, fins, stabilators - or none at all.
//
//  isStabilator - 1 if Core schedules this surface's incidence from heliSimStabTable below
//                 rather than holding it fixed. A fixed surface declares 0.
//  pos[]        - {lateral, longitudinal, vertical} in m,
//                 right-positive / nose-positive / up-positive
//  pitch        - incidence, deg
//  roll         - deg; 90 stands the surface on edge, which is what makes a fin a fin
//  span         - m
//  chord        - m
//  sweep        - deg
//  twist        - washout, deg
//  tipWidthScalar - tip chord as a fraction of root chord; 1.0 is untapered
//  numElements  - spanwise strips the surface is cut into
//  airfoil      - section name, see helisim_airfoils.hpp
//  chordLinePos - where along the chord the force acts, as a fraction from the leading edge

    numWings = 4;
    class Wings {
        class Wing01 {
            name           = "right wing";
            isStabilator   = 0;
            pos[]          = {1.50, 1.90, -1.40};
            pitch          = 12.0;    //deg
            roll           = 0.0;
            span           = 2.00;    //m
            chord          = 1.00;    //m
            sweep          = 0.0;     //deg
            twist          = 0.0;     //deg
            tipWidthScalar = 1.0;
            numElements    = 4;
            airfoil        = "NACA 4418";
            chordLinePos   = 0.25;
        };
        class Wing02 {
            name           = "left wing";
            isStabilator   = 0;
            pos[]          = {-1.50, 1.90, -1.40};
            pitch          = 12.0;
            roll           = 0.0;
            span           = 2.00;
            chord          = 1.00;
            sweep          = 0.0;
            twist          = 0.0;
            tipWidthScalar = 1.0;
            numElements    = 4;
            airfoil        = "NACA 4418";
            chordLinePos   = 0.25;
        };
        class Wing03 {
            name           = "vertical fin";
            isStabilator   = 0;
            pos[]          = {0.00, -7.45, -0.75};
            pitch          = 0.0;
            roll           = 90.0;    //on edge, so its lift is a side force
            span           = 2.25;
            chord          = 0.95;
            sweep          = 1.4;
            twist          = 0.0;
            tipWidthScalar = 1.0;
            numElements    = 4;
            airfoil        = "NACA 4418";
            chordLinePos   = 0.25;
        };
        class Wing04 {
            name           = "stabilator";
            isStabilator   = 1;       //incidence scheduled, see heliSimStabTable
            pos[]          = {0.00, -6.45, -1.85};
            pitch          = 0.0;
            roll           = 0.0;
            span           = 3.22;
            chord          = 1.07;
            sweep          = 0.0;
            twist          = 0.0;
            tipWidthScalar = 1.0;
            numElements    = 4;
            airfoil        = "NACA 0012";   //symmetric, it works both ways
            chordLinePos   = 0.25;
        };
    };

    //Stabilator incidence schedule, deg. Rows are collective 0..1; columns are the airspeeds
    //in the header comment, KNOTS. Core drives any surface flagged isStabilator from this.
    //No header row - fn_wing interpolates the collective axis and pairs the result against
    //its own column speeds.
    //------------------------Coll---30.0---40.0---50.0---57.5---60.0---80.0---82.5---100.0---115.0---120.0---140.0---150.0---160.0---165.0---180.0
    heliSimStabTable[] =    {
                             {0.00,-25.00,-15.50, -6.00, -3.00, -3.00, -3.00, -3.00,  -3.00,  -3.00,  -3.00,  -3.00,  -3.00,  -3.00,  -3.00,  -3.00}
                            ,{0.25,-25.00,-17.50,-10.00, -6.00, -5.70, -3.30, -3.00,  -3.00,  -3.00,  -3.00,  -3.00,  -3.00,  -3.00,  -3.00,  -3.00}
                            ,{0.50,-25.00,-18.30,-11.60,-10.61,-10.28, -7.63, -7.30,  -4.98,  -3.00,  -3.00,  -3.00,  -3.00,  -3.00,  -3.00,  -3.00}
                            ,{0.75,-25.00,-21.73,-16.95,-16.00,-15.68,-13.15,-12.83, -10.61,  -8.71,  -8.07,  -5.54,  -4.27,  -3.00,  -3.00,  -3.00}
                            ,{1.00,-25.00,-26.50,-28.00,-23.00,-22.66,-19.97,-19.63, -17.27, -15.24, -14.57, -11.87, -10.52,  -9.17,  -8.50,  -8.50}
                            };
