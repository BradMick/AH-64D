//HeliSim hitpoint set. Core defines which hitpoints exist, what they are named
//and their fixed properties - they are the systems the flight model and its
//subsystems damage-check. Core is not user-modifiable.
//
//The aircraft supplies armor, radius and minimal hit per hitpoint by
//defining the matching <PREFIX>_HIT_* macros before this file is included.
//Names are fixed: Core's SQF looks hitpoints up by these exact strings, so a
//pack that renamed one would silently break its damage checks.
//The modeller must create selections matching each name.

#define BMKHS_HITPOINT(cls,nm,arm,rad,minr,expShl) \
    class cls { \
        name               = nm; \
        armor              = arm; \
        radius             = rad; \
        minimalHit         = minr; \
        explosionShielding = expShl; \
        material           = 51; \
        passThrough        = 0; \
    };

class HitPoints
{
    BMKHS_HITPOINT(hit_apu,"hit_apu",APU_HIT_ARMOR,APU_HIT_RADIUS,APU_HIT_MINRADIUS,0.3)
    BMKHS_HITPOINT(hit_drives_intermediategearbox,"hit_drives_intermediategearbox",IGB_HIT_ARMOR,IGB_HIT_RADIUS,IGB_HIT_MINRADIUS,0.34)
    BMKHS_HITPOINT(hit_drives_noseGearbox1,"hit_drives_noseGearbox1",NGB1_HIT_ARMOR,NGB1_HIT_RADIUS,NGB1_HIT_MINRADIUS,0.24)
    BMKHS_HITPOINT(hit_drives_noseGearbox2,"hit_drives_noseGearbox2",NGB2_HIT_ARMOR,NGB2_HIT_RADIUS,NGB2_HIT_MINRADIUS,0.24)
    BMKHS_HITPOINT(hit_drives_tailrotorgearbox,"hit_drives_tailrotorgearbox",TRGB_HIT_ARMOR,TRGB_HIT_RADIUS,TRGB_HIT_MINRADIUS,0.34)
    BMKHS_HITPOINT(hit_drives_transmission,"hit_drives_transmission",XMSN_HIT_ARMOR,XMSN_HIT_RADIUS,XMSN_HIT_MINRADIUS,0.3)
    BMKHS_HITPOINT(hit_elec_battery,"hit_elec_battery",BATTERY_HIT_ARMOR,BATTERY_HIT_RADIUS,BATTERY_HIT_MINRADIUS,0.24)
    BMKHS_HITPOINT(hit_elec_generator1,"hit_elec_generator1",GEN1_HIT_ARMOR,GEN1_HIT_RADIUS,GEN1_HIT_MINRADIUS,0.09)
    BMKHS_HITPOINT(hit_elec_generator2,"hit_elec_generator2",GEN2_HIT_ARMOR,GEN2_HIT_RADIUS,GEN2_HIT_MINRADIUS,0.09)
    BMKHS_HITPOINT(hit_elec_rectifier1,"hit_elec_rectifier1",RECT1_HIT_ARMOR,RECT1_HIT_RADIUS,RECT1_HIT_MINRADIUS,0.1)
    BMKHS_HITPOINT(hit_elec_rectifier2,"hit_elec_rectifier2",RECT2_HIT_ARMOR,RECT2_HIT_RADIUS,RECT2_HIT_MINRADIUS,0.1)
    BMKHS_HITPOINT(hitengine1,"hitengine1",ENGINE1_HIT_ARMOR,ENGINE1_HIT_RADIUS,ENGINE1_HIT_MINRADIUS,0.3)
    BMKHS_HITPOINT(hitengine2,"hitengine2",ENGINE2_HIT_ARMOR,ENGINE2_HIT_RADIUS,ENGINE2_HIT_MINRADIUS,0.3)
    //Keeps Arma's own engine hitpoint inert so the per-engine hitpoints
    //drive engine damage. Core owns this - not configurable.
    class hitengine
    {
        armor              = 999;
        depends            = "0.5 * (HitEngine1 + HitEngine2)";
        explosionShielding = 1;
        material           = 51;
        minimalHit         = 1;
        name               = "engine_hit";
        passThrough        = 0;
        radius             = 0.05;
    };
    BMKHS_HITPOINT(hit_fuel_aft,"hit_fuel_aft",FUELAFT_HIT_ARMOR,FUELAFT_HIT_RADIUS,FUELAFT_HIT_MINRADIUS,0.3)
    BMKHS_HITPOINT(hit_fuel_forward,"hit_fuel_forward",FUELFWD_HIT_ARMOR,FUELFWD_HIT_RADIUS,FUELFWD_HIT_MINRADIUS,0.3)
    BMKHS_HITPOINT(hit_msnEquip_magandrobbie,"hit_msnEquip_magandrobbie",AMMOBAY_HIT_ARMOR,AMMOBAY_HIT_RADIUS,AMMOBAY_HIT_MINRADIUS,0.3)
    BMKHS_HITPOINT(hit_hyd_prireservoir,"hit_hyd_prireservoir",PRIRES_HIT_ARMOR,PRIRES_HIT_RADIUS,PRIRES_HIT_MINRADIUS,0.2)
    BMKHS_HITPOINT(hit_hyd_priPump,"hit_hyd_priPump",PRIPUMP_HIT_ARMOR,PRIPUMP_HIT_RADIUS,PRIPUMP_HIT_MINRADIUS,0.15)
    BMKHS_HITPOINT(hit_hyd_utilreservoir,"hit_hyd_utilreservoir",UTILRES_HIT_ARMOR,UTILRES_HIT_RADIUS,UTILRES_HIT_MINRADIUS,0.2)
    BMKHS_HITPOINT(hit_hyd_utilPump,"hit_hyd_utilPump",UTILPUMP_HIT_ARMOR,UTILPUMP_HIT_RADIUS,UTILPUMP_HIT_MINRADIUS,0.15)
    BMKHS_HITPOINT(hithrotor,"hithrotor",MAINROTOR_HIT_ARMOR,MAINROTOR_HIT_RADIUS,MAINROTOR_HIT_MINRADIUS,0.8)
    BMKHS_HITPOINT(hit_msnEquip_gun_turret,"hit_msnEquip_gun_turret",GUNTURRET_HIT_ARMOR,GUNTURRET_HIT_RADIUS,GUNTURRET_HIT_MINRADIUS,0.8)
    BMKHS_HITPOINT(hit_msnEquip_pnvs_flir,"hit_msnEquip_pnvs_flir",PNVSFLIR_HIT_ARMOR,PNVSFLIR_HIT_RADIUS,PNVSFLIR_HIT_MINRADIUS,0.8)
    BMKHS_HITPOINT(hit_msnEquip_pnvs_turret,"hit_msnEquip_pnvs_turret",PNVSTURRET_HIT_ARMOR,PNVSTURRET_HIT_RADIUS,PNVSTURRET_HIT_MINRADIUS,0.8)
    BMKHS_HITPOINT(hit_msnEquip_pylon1,"hit_msnEquip_pylon1",PYLON1_HIT_ARMOR,PYLON1_HIT_RADIUS,PYLON1_HIT_MINRADIUS,0.8)
    BMKHS_HITPOINT(hit_msnEquip_pylon2,"hit_msnEquip_pylon2",PYLON2_HIT_ARMOR,PYLON2_HIT_RADIUS,PYLON2_HIT_MINRADIUS,0.8)
    BMKHS_HITPOINT(hit_msnEquip_pylon3,"hit_msnEquip_pylon3",PYLON3_HIT_ARMOR,PYLON3_HIT_RADIUS,PYLON3_HIT_MINRADIUS,0.8)
    BMKHS_HITPOINT(hit_msnEquip_pylon4,"hit_msnEquip_pylon4",PYLON4_HIT_ARMOR,PYLON4_HIT_RADIUS,PYLON4_HIT_MINRADIUS,0.8)
    BMKHS_HITPOINT(hit_msnEquip_tads_dtv,"hit_msnEquip_tads_dtv",TADSDTV_HIT_ARMOR,TADSDTV_HIT_RADIUS,TADSDTV_HIT_MINRADIUS,0.8)
    BMKHS_HITPOINT(hit_msnEquip_tads_flir,"hit_msnEquip_tads_flir",TADSFLIR_HIT_ARMOR,TADSFLIR_HIT_RADIUS,TADSFLIR_HIT_MINRADIUS,0.8)
    BMKHS_HITPOINT(hit_msnEquip_fcr,"hit_msnEquip_fcr",FCR_HIT_ARMOR,FCR_HIT_RADIUS,FCR_HIT_MINRADIUS,0.8)
    BMKHS_HITPOINT(hit_msnEquip_irJam,"hit_msnEquip_irJam",IRJAM_HIT_ARMOR,IRJAM_HIT_RADIUS,IRJAM_HIT_MINRADIUS,0.24)
    BMKHS_HITPOINT(hit_stabilator,"hit_stabilator",STABILATOR_HIT_ARMOR,STABILATOR_HIT_RADIUS,STABILATOR_HIT_MINRADIUS,0.8)
    BMKHS_HITPOINT(hitvrotor,"hitvrotor",TAILROTOR_HIT_ARMOR,TAILROTOR_HIT_RADIUS,TAILROTOR_HIT_MINRADIUS,0.8)
};
