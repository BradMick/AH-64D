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
    //  variableName - the aircraft NAMES its own tank variables. Core prefixes bmkhs_ and
    //              appends the field, so variableName = "fwdTank" publishes
    //              bmkhs_fwdTankMass, bmkhs_fwdTankMax, bmkhs_fwdTankLow and
    //              bmkhs_fwdTankInstalled. What a display reads is then obvious from this
    //              file with no index arithmetic. Names must be unique; a duplicate is an
    //              error at load. Do not include the bmkhs_ prefix - Core adds it.
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
    //                "xfer"     - gravity/pump feeds the mains, engines never draw directly
    //              An aircraft with four mains gives all four role = "main".
    //  leakPoint - hitpoint whose damage makes this tank leak; "" for none.

    //CROSSFEED positions - which main tank each engine feeds from in each valve position.
    //Mains are referenced by position in the "main" tanks declared in helisim_fuel.hpp, so
    //nothing here means forward or aft; the aircraft's labels are its own.
    //  position     - the value bmkhs_crossfeedMode carries for this setting
    //  engSources[] - main index per engine, in engine order
    //The first entry is the default the valve starts in.
    numCrossfeedModes = 3;
    class CrossfeedModes {
        class Norm { position = "NORM"; engSources[] = {0, 1}; };   //each engine its own main
        class Fwd  { position = "FWD";  engSources[] = {0, 0}; };   //both from the first main
        class Aft  { position = "AFT";  engSources[] = {1, 1}; };   //both from the second
    };

    //Which main tank the APU draws from. Independent of the crossfeed valve.
    apuFuelSource = 1;

    //XFER pump destinations, in main order. The pump moves fuel INTO the main whose label
    //the crew selected, so this maps the cockpit's labels onto the mains above. Core never
    //interprets the labels - "FWD"/"AFT" here could equally be "LH"/"RH".
    xferDestinations[] = {"FWD", "AFT"};

    numFuelTanks = 3;
    class FuelTanks {
        class FuelTank01 {
            variableName = "fwdTank";
            arm[]     = {0.000, 2.542, 0.000};
            capacity  = 473.1;      //1043lbs
            lowFuelKg = 109.0;
            removable = 0;
            role      = "main";
            leakPoint = "hit_fuel_forward";
        };
        class FuelTank02 {          //centre cell (robbie), shares the ammo bay position
            variableName = "ctrTank";
            arm[]     = {0.000, 0.944, 0.000};
            capacity  = 300.9;      //663lbs
            lowFuelKg = 0.0;
            removable = 1;
            role      = "xfer";
            leakPoint = "hit_msnEquip_magandrobbie";
        };
        class FuelTank03 {
            variableName = "aftTank";
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
    //  variableName - names this tank's variables, exactly as for the fuel tanks above:
    //              "stn1Tank" publishes bmkhs_stn1TankMass and bmkhs_stn1TankMax.
    //  feedsTank - variableName of the fuel tank this one transfers into
    //  requires  - variableName of the aux tank that must be present first, or "" for none.
    //              The AH-64's outboard tanks need the inboard one fitted for the
    //              pressurised air path, declared here rather than coded.
    //  group     - transfer switch that arms this tank. The AH-64 gangs its tanks left and
    //              right; an aircraft with one switch puts every tank in the same group.
    numAuxTanks = 4;
    class AuxTanks {
        class AuxTank01 { variableName = "stn1Tank"; station = 1; capacity = 699.0; feedsTank = "fwdTank"; requires = "stn2Tank"; group = "L"; };
        class AuxTank02 { variableName = "stn2Tank"; station = 2; capacity = 699.0; feedsTank = "fwdTank"; requires = "";         group = "L"; };
        class AuxTank03 { variableName = "stn3Tank"; station = 3; capacity = 699.0; feedsTank = "aftTank"; requires = "";         group = "R"; };
        class AuxTank04 { variableName = "stn4Tank"; station = 4; capacity = 699.0; feedsTank = "aftTank"; requires = "stn3Tank"; group = "R"; };
    };
