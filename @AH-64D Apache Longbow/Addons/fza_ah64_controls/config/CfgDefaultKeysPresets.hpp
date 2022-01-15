class CfgDefaultKeysPresets {
	class Arma2 {
		class Mappings {
			/*
				dik[] = 0xaaBBccDD
				aa		= combo KB key (second key of combo always keyboard)
				BB		= device type of first key (joy, mouse, KB,...) (or in case of combo, first half secondary combo type, second half main combo type)
				cc		= offset for joys or double tap info for KB
				DD		= key/button/axis identification

				BBccDD	= whole info about first key
				ccDD		= button info (doubleTap or joyID+btnID)
				DD		= button local ID
			*/	
			fza_ah64_sightSelectHMD[] = {0x2A130002}; //Shift+1
			fza_ah64_sightSelectTADS[] = {0x2A130003}; //Shift+2
			fza_ah64_sightSelectFXD[] = {0x2A130004}; //Shift+3
			fza_ah64_sightSelectFCR[] = {0x2A130005}; //Shift+4
			fza_ah64_symbologySelectUp[] = {0x2A130030}; //Shift+B
			fza_ah64_symbologySelectDown[] = {0x1D130030}; //Ctrl+B
			fza_ah64_symbologySelectPress[] = {0x30}; //B
			fza_ah64_laserDesig[] = {0x22}; //G
			fza_ah64_fcrSingleScan[] = {0x2A130013}; //Shift+R
			fza_ah64_targetStoreUpdate[] = {0x2A130022}; //Shift+G
			fza_ah64_crosshairInteract[] = {0x56}; // Backslash (\)
			fza_ah64_waypointIncrease[] = {0x2A130006}; //Shift+5
			fza_ah64_waypointDecrease[] = {0x1D130006}; //Ctrl+5
			fza_ah64_laserCycle[] = {0x38130014}; //Alt+T
			fza_ah64_countermeasure[] = {0x13}; //R
			fza_ah64_missileAdvance[] = {0x21}; //F
			fza_ah64_wasGun[] = {0x02}; // 1
			fza_ah64_wasRkt[] = {0x03}; // 2
			fza_ah64_wasMsl[] = {0x04}; // 3
			fza_ah64_masterSafe[] = {0x05}; // 4
		};
	};
	class Arma3: Arma2 {
		class Mappings: Mappings {
			fza_ah64_countermeasure[] = {0x2E}; //C
		}
	}
};