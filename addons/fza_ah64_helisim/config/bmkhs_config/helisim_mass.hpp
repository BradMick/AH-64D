/////////////////////////////////////////////////////////////////////////////////////////////
// Mass and Balance /////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////
    //FCR
    emptyMassFCR      = 6609; //kg
    emptyMomFCR       = 35608.268;   //-> 212.12 in
    //emptyCoMFCR[]     = {0.0, -1.121, 0.0};     //m
    //Non-FCR
    emptyMassNonFCR   = 6314; //kg
    emptyMomNonFCR    = 34179.229;   //-> 213.12 in
    //emptyCoMNonFCR[]  = {0.0, -1.117, 0.0};     //m

    //Fuselage station datum and CG limits
    fsDatum             = 6.4;      //m, station 0 reference
    fwdCgLimit          = 1.117;    //m
    aftCgLimit          = 0.964;    //m

/////////////////////////////////////////////////////////////////////////////////////////////
// Indexed mass items ///////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////
    //Every mass item is {arm, mass}: arm[] is {lateral, longitudinal, vertical} in metres,
    //right-positive / nose-positive, measured in the same surveyed frame as fsDatum.
    //Counts drive the loops in Core, so an airframe with no wing stations sets numStations = 0
    //and one with nine troop seats declares nine Seat classes.

    //SEATS. Occupancy is resolved against fullCrew, so an empty seat adds no mass and the CG
    //shifts to match who is actually aboard.
    //  role       - "driver" | "gunner" | "commander" | "turret" | "cargo"
    //  turret[]   - turret path for gunner/commander/turret seats; {} for the driver
    //  cargoIndex - cargo slot for role = "cargo"; -1 otherwise. NOTE: Arma assigns cargo
    //               indices by proxy order in the P3D, so the modeller must confirm which
    //               index is which physical seat - Core cannot verify this.
    numSeats = 2;
    class Seats {
        class Seat01 {  //CPG, front
            arm[]      = {0.000, 4.312, 0.000};
            mass       = 113.4;
            role       = "gunner";
            turret[]   = {0};
            cargoIndex = -1;
        };
        class Seat02 {  //PLT, rear
            arm[]      = {0.000, 2.760, 0.000};
            mass       = 113.4;
            role       = "driver";
            turret[]   = {};
            cargoIndex = -1;
        };
    };

    //FUEL TANKS. A tank is a mass at a position, so the arm lives here rather than being
    //inferred from a cell name. capacity is kg of usable fuel.
    //  station - wing station index for external tanks; 0 for internal tanks
    numTanks = 3;
    class Tanks {
        class Tank01 {
            name     = "FWD";
            arm[]    = {0.000, 2.542, 0.000};
            capacity = 473.1;
            station  = 0;
        };
        class Tank02 {  //centre cell shares the ammo bay position
            name     = "CTR";
            arm[]    = {0.000, 0.944, 0.000};
            capacity = 300.9;
            station  = 0;
        };
        class Tank03 {
            name     = "AFT";
            arm[]    = {0.000, -0.077, 0.000};
            capacity = 668.6;
            station  = 0;
        };
    };

    //WING STATIONS. pylons[] lists the Arma pylon indices this station carries, so Core can
    //total the ammo without hardcoded index ranges. Indices are 1-BASED, matching the
    //"pylonsN" names ammoOnPylon takes; getPylonMagazines is 0-based, so Core subtracts one
    //when looking a magazine up by index.
    numStations = 4;
    class Stations {
        class Station01 { arm[] = {-2.160, 1.345, 0.000}; pylons[] = { 1,  2,  3,  4}; };
        class Station02 { arm[] = {-1.500, 1.345, 0.000}; pylons[] = { 5,  6,  7,  8}; };
        class Station03 { arm[] = { 1.500, 1.345, 0.000}; pylons[] = { 9, 10, 11, 12}; };
        class Station04 { arm[] = { 2.160, 1.345, 0.000}; pylons[] = {13, 14, 15, 16}; };
    };

    //INTERNAL MAGAZINES. Rounds carried inside the airframe rather than on a pylon.
    //  match - substring tested against the magazine class name
    numMagazines = 1;
    class Magazines {
        class Mag01 {  //M230 30mm
            match       = "m230";
            arm[]       = {0.000, 0.944, 0.000};
            massPerRound = 0.35;
        };
    };

/////////////////////////////////////////////////////////////////////////////////////////////
// Store masses /////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////
    //What the aircraft's stores weigh. This is aircraft business, not flight-model business -
    //Core reads the table and matches, it does not know what a Hellfire is.
    //  match          - substring tested against the pylon magazine class name
    //  launcherMass   - kg of the launcher/rail itself, counted once if the station carries it
    //  massPerRound   - kg per remaining round
    //  isTank         - 1 if the store is a fuel tank, whose fuel mass comes from Tanks above
    numStores = 3;
    class Stores {
        class Store01 {  //M299 launcher + AGM-114 Hellfire
            match        = "agm114";
            launcherMass = 64.90;
            massPerRound = 46.71;   //103lbs (99-106lbs, average 102.5)
            isTank       = 0;
        };
        class Store02 {  //M261 pod + 2.75in Hydra
            match        = "275";
            launcherMass = 39.40;
            massPerRound = 10.40;   //23lbs M151; M255A1 27.5, M261 27.4, M257/M278 24.3
            isTank       = 0;
        };
        class Store03 {  //230gal auxiliary tank
            match        = "auxTank";
            launcherMass = 63.50;   //empty tank
            massPerRound = 0.00;
            isTank       = 1;
        };
    };
