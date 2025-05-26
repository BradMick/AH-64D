class CfgVehicles {
    class Logic;
    class Module_F: Logic
    {
        class AttributesBase
        {
			class Default;
			class Edit;					// Default edit box (i.e., text input field)
			class Combo;				// Default combo box (i.e., drop-down menu)
			class Checkbox;				// Default checkbox (returned value is Boolean)
			class CheckboxNumber;		// Default checkbox (returned value is Number)
			class ModuleDescription;	// Module description
			class Units;				// Selection of units on which the module is applied
        };

        class ModuleDescription
        {
            class AnyBrain;
        };
    };

    class routePoint: Logic {
        vehicleClass = fza_convoy;
        displayName  = "Route Point";
        icon         = "\a3\ui_f\data\igui\cfg\simpletasks\types\truck_ca.paa"; // Optional: Custom icon
        mapSize      = 1; // Size of the icon on the map

        class EventHandlers {
            init = "(_this select 0) setVariable ['CustomLogic', true];";
        };

        class Attributes {
            // Add custom attributes here if needed
        };
    };

    class routeManger: Logic {
        vehicleClass = fza_convoy;
        displayName  = "Route Manager";
        //icon         = "\a3\ui_f\data\igui\cfg\simpletasks\types\truck_ca.paa"; // Optional: Custom icon
        mapSize      = 1; // Size of the icon on the map

        class EventHandlers {
            init = "(_this select 0) setVariable ['CustomLogic', true];";
        };

        class Attributes {
            // Add custom attributes here if needed
        };
    };

    class vehicleManager: Logic {
        vehicleClass = fza_convoy;
        displayName  = "Vehicle Manager";
        //icon         = "\a3\ui_f\data\igui\cfg\simpletasks\types\truck_ca.paa"; // Optional: Custom icon
        mapSize      = 1; // Size of the icon on the map

        class EventHandlers {
            init = "(_this select 0) setVariable ['CustomLogic', true];";
        };

        class Attributes {
            // Add custom attributes here if needed
        };
    };
};