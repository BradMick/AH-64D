//AH-64D HeliSim configuration.
//Split along system/component lines; Core reads this class.

class BMKHS_HeliSim {
    //Model the aircraft's systems (electrical, APU, hydraulics, drivetrain).
    //Off means vanilla behaviour and Core's optional-input defaults.
    useSystems = 1;

    //Drivetrain ratings, as fractions of rated torque, worst first: {torque, seconds}
    //saying how much it will take and for how long before that costs it. These apply
    //whether or not systems are modelled - an airframe does not get to ignore what its
    //drivetrain is rated for by declining to simulate the rest.
    xmsnTqLimits[]   = {{1.20, 0}, {1.00, 6}};                  //dual engine
    xmsnTqLimitsSE[] = {{1.30, 0}, {1.20, 6}, {1.10, 150}};     //single engine
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
