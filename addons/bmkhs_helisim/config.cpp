class CfgPatches
{
    class bmkhs_helisim
    {
        units[] = {};
        author = "BradMick";
        weapons[] = {};
        requiredVersion = 2.10;
        requiredAddons[] = {"fza_ah64_controls", "fza_ah64_model"};
        #include "version.hpp"
    };
};

#include "CfgFunctions.hpp"
#include "extendedEventHandlers.hpp"
#include "ui\RscCtrlVis.hpp"
