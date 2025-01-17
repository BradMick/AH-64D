class CfgNonAIVehicles
{
	class ProxyWeapon;
	
	class Proxyfza_atas_2: ProxyWeapon
	{
		model	   = "\fza_ah64_us\fza_atas.p3d";
		simulation = "maverickweapon";
	};
	class Proxyfza_agm114l: ProxyWeapon
	{
		model = "\fza_ah64_us\fza_agm114l.p3d";
		simulation = "maverickweapon";
	};
	class Proxyfza_agm114k: ProxyWeapon
	{
		model = "\fza_ah64_us\fza_agm114k.p3d";
		simulation = "maverickweapon";
	};
	class Proxyfza_agm114c: ProxyWeapon
	{
		model = "\fza_ah64_us\fza_agm114c.p3d";
		simulation = "maverickweapon";
	};
	class Proxyfza_agm114a: ProxyWeapon
	{
		model = "\fza_ah64_us\fza_agm114a.p3d";
		simulation = "maverickweapon";
	};
	class Proxyfza_agm114m: ProxyWeapon
	{
		model = "\fza_ah64_us\fza_agm114m.p3d";
		simulation = "maverickweapon";
	};
	class Proxyfza_agm114n: ProxyWeapon
	{
		model = "\fza_ah64_us\fza_agm114n.p3d";
		simulation = "maverickweapon";
	};

	class Proxyfza_hydra_m151: ProxyWeapon
	{
		model = "\fza_ah64_us\fza_hydra_m151.p3d";
		simulation = "maverickweapon";
	};
	class Proxyfza_hydra_m229: ProxyWeapon
	{
		model = "\fza_ah64_us\fza_hydra_m229.p3d";
		simulation = "maverickweapon";
	};
	class Proxyfza_hydra_m261: ProxyWeapon
	{
		model = "\fza_ah64_us\fza_hydra_m261.p3d";
		simulation = "maverickweapon";
	};
	class Proxyfza_hydra_m257: ProxyWeapon
	{
		simulation = "maverickweapon";
	};
	class Proxyfza_hydra_m255: ProxyWeapon
	{
		simulation = "maverickweapon";
	};


	//Pylon proxies
	class Proxyfza_pod_zoneA: ProxyWeapon {
		model = \fza_ah64_us\weps\pylons\fza_pod_zoneA.p3d;
		simulation = "pylonpod";
	};
	class Proxyfza_pod_zoneB: ProxyWeapon {
		model = \fza_ah64_us\weps\pylons\fza_pod_zoneB.p3d;
		simulation = "pylonpod";
	};
	class Proxyfza_pod_zoneE: ProxyWeapon {
		model = \fza_ah64_us\weps\pylons\fza_pod_zoneE.p3d;
		simulation = "pylonpod";
	};
	class Proxyfza_rail_ll: ProxyWeapon {
		model = \fza_ah64_us\weps\pylons\fza_rail_ll.p3d;
		simulation = "pylonpod";
	};
	class Proxyfza_rail_lr: ProxyWeapon {
		model = \fza_ah64_us\weps\pylons\fza_rail_lr.p3d;
		simulation = "pylonpod";
	};
	class Proxyfza_rail_ul: ProxyWeapon {
		model = \fza_ah64_us\weps\pylons\fza_rail_ul.p3d;
		simulation = "pylonpod";
	};
	class Proxyfza_rail_ur: ProxyWeapon {
		model = \fza_ah64_us\weps\pylons\fza_rail_ur.p3d;
		simulation = "pylonpod";
	};

	class ProxyRetex;
	class Proxyfza_dam_D_cata: ProxyRetex
	{
		hiddenSelections[] = { "skin" };
		model = "\fza_ah64_us\prx\fza_dam_D_cata.p3d";
	};
	class Proxyfza_dam_hstab_debris: ProxyRetex
	{
		hiddenSelections[] = { "skin" };
		model = "\fza_ah64_us\prx\fza_dam_hstab_debris.p3d";
	};
	class Proxyfza_dam_tailboom_debris: ProxyRetex
	{
		hiddenSelections[] = { "skin" };
		model = "\fza_ah64_us\prx\fza_dam_tailboom_debris.p3d";
	};
	class Proxyfza_dam_vtail_debris: ProxyRetex
	{
		hiddenSelections[] = { "skin" };
		model = "\fza_ah64_us\prx\fza_dam_vtail_debris.p3d";
	};
	class Proxyfza_dam_ExtCpitB2: ProxyRetex
	{
		hiddenSelections[] = { "skin" };
		model = "\fza_ah64_us\prx\fza_dam_ExtCpitB2.p3d";
	};
	class Proxyfza_ah64db2_wreck: ProxyRetex
	{
		hiddenSelections[] = { "skin" };
		model = "\fza_ah64_us\prx\fza_ah64db2_wreck.p3d";
	};
	class Proxyfza_dam_longbow: ProxyRetex
	{
		hiddenSelections[] = { "skin_fcr" };
		model = "\fza_ah64_us\prx\fza_dam_longbow.p3d";
	};
};
