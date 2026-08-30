//AH-64D HeliSim configuration.
//Split along system/component lines; Core reads this class.

class BMKHS_HeliSim {
    //Subsystem gates
    useSystems          = 1;
    useAPU              = 1;
    useElectricalSystem = 1;
    useHydraulicSystem  = 1;
    useDrivetrain       = 1;

    #include "bmkhs_config\helisim_airfoils.hpp"
    #include "bmkhs_config\helisim_apu.hpp"
    #include "bmkhs_config\helisim_drivetrain.hpp"
    #include "bmkhs_config\helisim_electrical.hpp"
    #include "bmkhs_config\helisim_engine.hpp"
    #include "bmkhs_config\helisim_flightControls.hpp"
    #include "bmkhs_config\helisim_fuel.hpp"
    #include "bmkhs_config\helisim_fuselage.hpp"
    #include "bmkhs_config\helisim_hydraulics.hpp"
    #include "bmkhs_config\helisim_mass.hpp"
    #include "bmkhs_config\helisim_misc.hpp"
    #include "bmkhs_config\helisim_rotor.hpp"
    #include "bmkhs_config\helisim_simpleRotor.hpp"
    #include "bmkhs_config\helisim_stabilator.hpp"
};
