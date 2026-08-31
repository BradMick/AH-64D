/////////////////////////////////////////////////////////////////////////////////////////////
// Fuel //////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////
    //Initial fuel fraction, with and without the optional centre cell fitted.
    initFuelFracRobbie   = 0.39;
    initFuelFracNoRobbie = 0.22;

    //Engine fuel flow at 100% - drives the FUEL page consumption readout
    fuelFlowLbsPerHour = 7936.64;

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
    numFuelTanks = 3;
    class FuelTanks {
        class FuelTank01 {
            name      = "FWD";
            arm[]     = {0.000, 2.542, 0.000};
            capacity  = 473.1;      //1043lbs
            lowFuelKg = 109.0;
            removable = 0;
        };
        class FuelTank02 {          //centre cell (robbie), shares the ammo bay position
            name      = "CTR";
            arm[]     = {0.000, 0.944, 0.000};
            capacity  = 300.9;      //663lbs
            lowFuelKg = 0.0;
            removable = 1;
        };
        class FuelTank03 {
            name      = "AFT";
            arm[]     = {0.000, -0.077, 0.000};
            capacity  = 668.6;      //1474lbs
            lowFuelKg = 118.0;
            removable = 0;
        };
    };

    //AUXILIARY TANKS - fuel carried on a wing station. station is the 1-based station index
    //from helisim_mass.hpp, which supplies the arm, so no arm is repeated here.
    numAuxTanks = 4;
    class AuxTanks {
        class AuxTank01 { station = 1; capacity = 699.0; };  //1541lbs, 230gal
        class AuxTank02 { station = 2; capacity = 699.0; };
        class AuxTank03 { station = 3; capacity = 699.0; };
        class AuxTank04 { station = 4; capacity = 699.0; };
    };
