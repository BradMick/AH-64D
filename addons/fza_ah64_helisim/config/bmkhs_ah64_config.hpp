//AH-64D HeliSim configuration.
//Split along system/component lines; Core reads this class.

class BMKHS_HeliSim {
    //Model the aircraft's systems (electrical, APU, hydraulics, drivetrain).
    //Off means vanilla behaviour and Core's optional-input defaults.
    useSystems = 1;

    //Drivetrain ratings, worst first: {fraction of rated torque, seconds it will hold
    //there}. 0 seconds damages immediately. SE sets are used single-engine.
    xmsnTqLimits[]   = {{1.20, 0}, {1.00, 6}};
    xmsnTqLimitsSE[] = {{1.30, 0}, {1.20, 6}, {1.10, 150}};
    ngbTqLimits[]    = {{1.20, 0}, {1.00, 6}};
    ngbTqLimitsSE[]  = {{1.30, 0}, {1.20, 6}, {1.10, 150}};

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
