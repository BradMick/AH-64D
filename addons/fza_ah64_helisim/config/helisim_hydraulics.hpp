/////////////////////////////////////////////////////////////////////////////////////////////
// Hydraulics ///////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////
    hydMinPsi          = 1260;   //psi, below this the affected axis loses authority
    hydMinAccPsi       = 1650;   //psi, accumulator charge floor
    hydMinLevel        = 0.1;    //fraction, reservoir level below which the pump loses prime
    //Reservoir damage tiers - leak rate steps at each threshold
    hydResMinDmg       = 0.50;
    hydResModDmg       = 0.67;
    hydResHvyDmg       = 0.83;
    hydAccTimerMin     = 1.5;    //min, accumulator hold time
    hydLeakTimerMin    = 2.0;    //min, time to drain a leaking reservoir
