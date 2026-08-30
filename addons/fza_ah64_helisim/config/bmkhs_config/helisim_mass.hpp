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

    //Crew
    crewMass            = 113.4;    //kg per seat

    //Station arms, {lateral, longitudinal} in m, right-positive.
    //Crew seats first, then the internal cells, then the wing stations.
    armCpg[]            = { 0.000,  4.312};
    armPlt[]            = { 0.000,  2.760};
    armFwdFuelCell[]    = { 0.000,  2.542};
    armAmmoBay[]        = { 0.000,  0.944};
    armAftFuelCell[]    = { 0.000, -0.077};
    armStation01[]      = {-2.160,  1.345};
    armStation02[]      = {-1.500,  1.345};
    armStation03[]      = { 1.500,  1.345};
    armStation04[]      = { 2.160,  1.345};
