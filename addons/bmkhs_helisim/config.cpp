class CfgPatches
{
    class bmkhs_helisim
    {
        units[] = {};
        author = "$STR_FZA_AH64_DEVELOPMENT_TEAM";
        weapons[] = {};
        requiredVersion = 2.10;
        //fza_ah64_fuel omitted - it requires sfmplus, declaring it would cycle
        requiredAddons[] = {"fza_ah64_common", "fza_ah64_controls", "fza_ah64_systems", "fza_ah64_audio", "fza_ah64_model"};
        #include "version.hpp"
    };
};

#include "CfgFunctions.hpp"
#include "extendedEventHandlers.hpp"
