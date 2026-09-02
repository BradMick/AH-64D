/////////////////////////////////////////////////////////////////////////////////////////////
// Components ///////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////
//What this airframe has and what it is wired to. Field reference, the networking rules
//and what Core does with any of it: bmkhs_helisim/components.hpp

    class Producers {
        //The accessory section, and the two things that turn it - highest wins. The APU
        //drives it directly and NOT the transmission, hence APU ground ops with the rotor
        //stopped.
        class ApuDrive {
            damageRole   = "apu";
            variableName = "apuDrive";
            output       = "ACCESSORY_DRIVE";
            //Turns the accessories as it spools, so the pumps come up with it rather than
            //snapping on once it is running.
            driveFrom    = "bmkhs_apuRPM_pct";
            nominal      = 1.0;
            rampSeconds  = 0;
        };
        //Turned by the engines, or by the rotor in an autorotation - same shaft either way,
        //so accessories keep turning with the engines dead.
        class XmsnDrive {
            damageRole   = "transmission";
            variableName = "xmsnDrive";
            output       = "ACCESSORY_DRIVE";
            drivenBy[]   = {"Nr"};        //any rotation; the pumps set their own floor
            passthrough  = 1;             //accessories turn at Nr, whatever Nr happens to be
            rampSeconds  = 0;
        };

        //Pumps hang off the accessory section, not the engines, and need fluid to move.
        class PriPump {
            damageRole   = "priPump";
            variableName = "priHydPsi";
            output       = "PRI_HYD";
            drivenBy[]   = {"ACCESSORY_DRIVE", 0.45};   //below this it loses drive
            requires     = "bmkhs_priLevel_pct";
            requiresAbove = 0.1;          //fraction - below this it loses prime
            nominal      = 3000;         //psi
            increment    = 10;            //gauges move in tens
            networked    = 1;             //MPD and WCA read these in the crew station
            rampSeconds  = 0.5;           //zero to full pressure - builds, does not snap
        };
        class UtilPump {
            damageRole   = "utilPump";
            variableName = "utilHydPsi";
            output       = "UTIL_HYD";
            drivenBy[]   = {"ACCESSORY_DRIVE", 0.45};
            requires     = "bmkhs_utilLevel_pct";
            requiresAbove = 0.1;
            nominal      = 3000;
            increment    = 10;
            networked    = 1;
            rampSeconds  = 0.5;
        };

        //Generators need far more shaft speed than the pumps, so an autorotation costs the
        //electrics but not the flight controls.
        class Generator {
            damageRole   = "generators";  //two hitpoints today -> gen1, gen2
            variableName = "gen";
            output       = "AC";
            drivenBy[]   = {"ACCESSORY_DRIVE", 0.85};
            nominal      = 1;             //on/off, not volts
            rampSeconds  = 0;             //a contactor closes, it does not spool
            needsSystems = 1;
        };
        class Rectifier {
            damageRole   = "rectifiers";  //two hitpoints today -> rect1, rect2
            variableName = "rect";
            output       = "DC";
            drivenBy[]   = {"AC"};        //any AC at all
            nominal      = 1;
            rampSeconds  = 0;
            needsSystems = 1;
        };
    };

    class Storage {
        //Reservoirs hold fluid rather than pressure - no output and no gate, since nothing
        //draws pressure from them. They only lose contents by leaking, ramping from the
        //onset threshold so a light hit weeps and a bad one dumps.
        class PriReservoir {
            damageRole      = "priReservoir";
            variableName    = "priLevel_pct";
            nominal         = 1.0;         //published as a fraction, which is what reads it
            networked       = 1;
            leakStartDmg    = 0.50;
            leakSeconds     = 120;
        };
        class UtilReservoir {
            damageRole      = "utilReservoir";
            variableName    = "utilLevel_pct";
            output          = "UTIL_HYD_LEVEL";   //so a consumer can read what is left
            nominal         = 1.0;
            networked       = 1;
            leakStartDmg    = 0.50;
            leakSeconds     = 120;
            //The gun and the pylons share the utility system, so hits on either vent it.
            drainedBy[]     = {"gunTurret", "pylons"};
        };

        //Feeds the battery route, and runs down whenever whatever charges it is dead.
        //rechargedBy is the airframe's choice - DC on an aircraft wired that way.
        class Battery {
            damageRole      = "batteries";
            variableName    = "battPower_pct";
            output          = "BATT";
            rechargedBy[]   = {"AC"};
            gate            = "bmkhs_battSwitchOn";
            nominal         = 1.0;        //published as a fraction
            stopBelow       = 0.25;       //too flat to hold a bus up
            startRecharge   = 60;         //sec off a live bus
            emerDischarge   = 720;        //12 min on the battery alone
            needsSystems    = 1;
        };

        //Discharges to start the APU and is refilled by the pumps it just started. Doubles
        //as emergency flight-control pressure, gated on the crew button.
        class Accumulator {
            //No damageRole - no selection in the p3d, so it cannot be shot out.
            variableName    = "accHydPsi";
            output          = "UTIL_HYD";
            networked       = 1;
            //Off the accessory drive, not UTIL_HYD - a store recharging from the node it
            //feeds would top itself up forever.
            rechargedBy[]   = {"ACCESSORY_DRIVE", 0.45};  //same drive the pumps need
            gate            = "bmkhs_emerHydOn";
            startedBy       = "bmkhs_apuBtnOn";
            nominal         = 3000;       //psi at full charge
            startAbove      = 2600;       //psi needed to turn the APU over at all
            startRecharge   = 8;          //sec to refill, once the pumps are turning
            stopBelow       = 1650;       //psi nitrogen precharge - only what is above it
                                          //is usable, and a start spends that band
            emerDischarge   = 90;         //sec of emergency pressure
        };
    };

    //Consumers here are read by the flight model on the pilot's machine only, so they stay
    //local. Anything a crew station draws sets networked.
    class Consumers {
        //What the crew stations read. A route is up when something is feeding it, however
        //that power got there.
        class AcBus {
            variableName = "acBusOn";
            needsSystems = 1;
            suppliedBy[] = {{"AC", 1}};
            networked    = 1;
        };
        class DcBus {
            variableName = "dcBusOn";
            needsSystems = 1;
            suppliedBy[] = {{"DC", 1}};
            networked    = 1;
        };
        class BattBus {
            variableName = "battBusOn";
            needsSystems = 1;
            suppliedBy[] = {{"BATT", 0.25}};
            networked    = 1;
        };
        //Either circuit alone keeps the controls moving, so losing one side is a
        //degradation rather than a loss of control.
        class FlightControls {
            variableName = "fltCtrlsSupplied";
            suppliedBy[] = {{"PRI_HYD", 1260}, {"UTIL_HYD", 1260}};   //psi
        };
        //The tail rotor needs primary pressure OR utility fluid - it is lost only when
        //both are gone, so this one is an AND across two different units.
        class TailRotor {
            variableName = "tailRtrSupplied";
            needsAll     = 0;             //either one keeps it
            suppliedBy[] = {{"PRI_HYD", 1260}, {"UTIL_HYD_LEVEL", 0.1}};
        };
    };
