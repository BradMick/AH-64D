//AH-64D HeliSim configuration.
//Split along system/component lines; Core reads this class.

class BMKHS_HeliSim {
    //Subsystem gates
    useSystems          = 1;
    useAPU              = 1;
    useElectricalSystem = 1;
    useHydraulicSystem  = 1;
    useDrivetrain       = 1;

    #include "helisim_mass.hpp"
    #include "helisim_flightControls.hpp"
    #include "helisim_simpleRotor.hpp"
    #include "helisim_fuselage.hpp"
    #include "helisim_fuel.hpp"
    #include "helisim_apu.hpp"
    #include "helisim_electrical.hpp"
    #include "helisim_hydraulics.hpp"
    #include "helisim_drivetrain.hpp"
    #include "helisim_engine.hpp"
    #include "helisim_stabilator.hpp"
    #include "helisim_airfoils.hpp"
    #include "helisim_misc.hpp"
};
