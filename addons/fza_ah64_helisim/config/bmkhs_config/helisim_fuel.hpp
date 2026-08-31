/////////////////////////////////////////////////////////////////////////////////////////////
// Fuel //////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////
    //Initial fuel fraction, with and without the optional centre cell fitted.
    initFuelFracRobbie   = 0.39;
    initFuelFracNoRobbie = 0.22;

/////////////////////////////////////////////////////////////////////////////////////////////
// Fuel tanks ///////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////
    //A tank is a mass at a position that happens to hold fuel, so its arm, capacity and
    //caution threshold are defined together here; the mass model reads the same table for
    //the arm rather than keeping a second copy.
    //
    //  name      - short label for the FUEL page
    //  arm[]     - {lateral, longitudinal, vertical} in m, right-positive / nose-positive
    //  capacity  - kg of usable fuel
    //  lowFuelKg - low-level caution threshold in kg; 0 for no caution on this tank
    //  removable - 1 if the tank can be taken out (centre cell, ferry tank). Core tracks a
    //              per-tank installed state for these; removable = 0 is always fitted. The
    //              UH-60 and CH-47 carry removable INTERNAL cells, so this is not an
    //              external-tank-only concept.
    //              A tank that displaces a magazine bay needs nothing declared here: the
    //              aircraft config stops those rounds being loaded, so magazinesAmmo returns
    //              none and the magazine contributes no mass on its own.
    //  role      - what this tank IS to the fuel system, so Core never assumes a tank
    //              number. The AH-64's plumbing asks for its forward and aft mains and its
    //              transfer cell by role and gets whatever index those happen to be:
    //                "main"     - a primary cell an engine can draw from
    //                "transfer" - gravity/pump feeds the mains, engines never draw directly
    //              An aircraft with four mains gives all four role = "main".
    //  leakPoint - hitpoint whose damage makes this tank leak; "" for none.

    //XFER pump destinations, in main order. The pump moves fuel INTO the main whose label
    //the crew selected, so this maps the cockpit's labels onto the mains above. Core never
    //interprets the labels - "FWD"/"AFT" here could equally be "LH"/"RH".
    xferDestinations[] = {"FWD", "AFT"};

    numFuelTanks = 3;
    class FuelTanks {
        class FuelTank01 {
            name      = "FWD";
            arm[]     = {0.000, 2.542, 0.000};
            capacity  = 473.1;      //1043lbs
            lowFuelKg = 109.0;
            removable = 0;
            role      = "main";
            leakPoint = "hit_fuel_forward";
        };
        class FuelTank02 {          //centre cell (robbie), shares the ammo bay position
            name      = "CTR";
            arm[]     = {0.000, 0.944, 0.000};
            capacity  = 300.9;      //663lbs
            lowFuelKg = 0.0;
            removable = 1;
            role      = "transfer";
            leakPoint = "hit_msnEquip_magandrobbie";
        };
        class FuelTank03 {
            name      = "AFT";
            arm[]     = {0.000, -0.077, 0.000};
            capacity  = 668.6;      //1474lbs
            lowFuelKg = 118.0;
            removable = 0;
            role      = "main";
            leakPoint = "hit_fuel_aft";
        };
    };

    //AUXILIARY TANKS - fuel carried on a wing station. station is the 1-based station index
    //from helisim_mass.hpp, which supplies the arm, so no arm is repeated here.
    //  feedsTank - 1-based FuelTank index this tank transfers into
    //  requires  - 1-based AuxTank index that must be present first, or 0 for none. The
    //              AH-64's outboard tanks need the inboard one fitted for the pressurised
    //              air path, and this is how that dependency is declared rather than coded.
    //  group     - transfer switch that arms this tank. The AH-64 gangs its tanks left and
    //              right; an aircraft with one switch puts every tank in the same group.
    numAuxTanks = 4;
    class AuxTanks {
        class AuxTank01 { station = 1; capacity = 699.0; feedsTank = 1; requires = 2; group = "L"; };
        class AuxTank02 { station = 2; capacity = 699.0; feedsTank = 1; requires = 0; group = "L"; };
        class AuxTank03 { station = 3; capacity = 699.0; feedsTank = 3; requires = 0; group = "R"; };
        class AuxTank04 { station = 4; capacity = 699.0; feedsTank = 3; requires = 3; group = "R"; };
    };
