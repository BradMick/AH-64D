//AH-64D HeliSim configuration.
//Split along system/component lines; Core reads this class.

class BMKHS_HeliSim {
    //Model the aircraft's systems (electrical, APU, hydraulics, drivetrain).
    //Off means vanilla behaviour and Core's optional-input defaults.
    useSystems = 1;

    //Drivetrain ratings for useSystems = 0 ONLY - with systems on, the components carry
    //their own and these are not read at all. Same tiers the components declare, worst
    //first: {fraction of rated torque, grace seconds, divisor}.
    //The transmission sees BOTH engines combined, so 100% each is 2.00 and that is
    //continuous; it has no single-engine case, since one engine cannot overtorque what is
    //rated for two.
    xmsnTqLimits[]   = {{2.30, 0, 20}, {2.00, 6, 10}};
    //A nose gearbox carries its own engine only, so it is rated SINGLE-ENGINE ONLY - with
    //both running neither is carrying enough to hurt it, and there is no dual-engine table
    //for exactly that reason.
    ngbTqLimitsSE[]  = {{1.25, 0, 40}, {1.22, 6, 20}, {1.10, 150, 10}};

    #include "bmkhs_config\helisim_airfoils.hpp"
    #include "bmkhs_config\helisim_components.hpp"
    #include "bmkhs_config\helisim_engine.hpp"
    #include "bmkhs_config\helisim_flightControls.hpp"
    #include "bmkhs_config\helisim_fuel.hpp"
    #include "bmkhs_config\helisim_fuselage.hpp"
    #include "bmkhs_config\helisim_mass.hpp"
    #include "bmkhs_config\helisim_misc.hpp"
    #include "bmkhs_config\helisim_rotor.hpp"
    #include "bmkhs_config\helisim_simpleRotor.hpp"
    #include "bmkhs_config\helisim_wings.hpp"
};
