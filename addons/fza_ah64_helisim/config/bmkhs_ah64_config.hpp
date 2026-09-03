//AH-64D HeliSim configuration.
//Split along system/component lines; Core reads this class.

class BMKHS_HeliSim {
    //Model the aircraft's systems (electrical, APU, hydraulics, drivetrain).
    //Off means vanilla behaviour and Core's optional-input defaults.
    useSystems = 1;

    //Drivetrain ratings for useSystems = 0 ONLY - with systems on, the components carry
    //their own. Worst first: {fraction of rated torque, seconds it will hold there}.
    //0 seconds damages immediately. SE sets are used single-engine.
    //Transmission sees BOTH engines combined, so 2.30 is the pair at full output and it
    //has no single-engine case - one engine can never overtorque it.
    xmsnTqLimits[]   = {{2.30, 0}, {2.00, 6}};
    //A nose gearbox carries its own engine only, which makes it the limiting part
    //single-engine: 1.25 is all it will absorb.
    ngbTqLimits[]    = {{1.15, 0}, {1.00, 6}};
    ngbTqLimitsSE[]  = {{1.25, 0}, {1.22, 6}, {1.10, 150}};

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
