#include "BIS_AddonInfo.hpp"
class CfgPatches
{
	class fza_ah64_controls
	{
		units[] = {"fza_ah64base","fza_ah64d_b2e","fza_ah64d_b2e_nr","fza_ah64_pilot"};
		author="Franze, Nodunit, Voodooflies, Keplager, mattysmith22, BradMick, Rosd6(Dryden) & Community";
		weapons[] = {};
		requiredVersion = 2.06;
		requiredAddons[] = {"A3_Air_F_Beta","A3_Sounds_F","A3_Data_F", "cba_main", "cba_xeh", "fza_ah64_sfmplus", "fza_ah64_aiCrew"};
	};
};
class CfgAddons
{
	class PreloadBanks{};
	class PreloadAddons
	{
		class fza_ah64_controls
		{
			list[] = {"fza_ah64_controls", "fza_ah64_sfmplus", "fza_ah64_AICrew"};
		};
	};
};

/*extern*/ class SensorTemplateIR;
/*extern*/ class SensorTemplateVisual;
/*extern*/ class SensorTemplateActiveRadar;
/*extern*/ class SensorTemplatePassiveRadar;
/*extern*/ class SensorTemplateLaser;
/*extern*/ class SensorTemplateNV;
#include "config\defines.hpp"
#include "config\misc.hpp"
#include "config\CfgAnimationSourceSounds.hpp"
#include "config\CfgSounds.hpp"
#include "config\CfgRadio.hpp"
#include "config\CfgMoves.hpp"
#include "config\CfgAmmo.hpp"
#include "config\CfgWeapons.hpp"
#include "config\CfgMagazines.hpp"
#include "config\CfgNonAIVehicles.hpp"
#include "config\CfgVehicles.hpp"
#include "config\CfgCloudlets.hpp"

#include "config\CfgFunctions.hpp"
#include "config\extendedEventHandlers.hpp"

#include "config\CfgSound3DProcessors.hpp"
#include "config\CfgSoundCurves.hpp"
#include "config\cfgDistanceFilters.hpp"
#include "config\CfgSoundShaders.hpp"
#include "config\CfgSoundSets.hpp"

#include "uiConfig\defines.hpp"
#include "uiConfig\baseClasses.hpp"
#include "uiConfig\monocle.hpp"
#include "uiConfig\rscTitles.hpp"
#include "uiconfig\welcome.hpp"

#include "config\CfgUserActions.hpp"
#include "config\UserActionGroups.hpp"
#include "config\UserActionsConflictGroups.hpp"
#include "config\CfgDefaultKeysPresets.hpp"

#include "config\CfgVideoOptions.hpp"