/////////////////////////////////////////////////////////////////////////////////////////////
// Drivetrain ///////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////
//Torque limits are fractions of rated torque. Above a limit the matching timer
//runs; when it expires the component starts taking damage. Damage rates and tiers
//are Core's.

    //Nose gearboxes - single-engine ratings
    ngbContTqLimit      = 1.10;   //continuous
    ngbContTimer        = 150;    //s, 2.5 min SE contingency
    ngbTransTqLimit     = 1.22;   //transient
    ngbTransTimer       = 6;      //s
    ngbMaxTqLimit       = 1.25;   //immediate damage above this

    //Main transmission - combined engine torque
    xmsnContTqLimit     = 2.00;   //continuous
    xmsnTransTqLimit    = 2.30;   //transient
    xmsnTransTimer      = 6;      //s

    //Main rotor gear ratio - shared by the rotor and transmission models
    mainRotorGearRatio  = 72.291;
