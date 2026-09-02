/////////////////////////////////////////////////////////////////////////////////////////////
// Components ///////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////
//What this airframe has and what it is wired to. Member count comes from damageRole, so a
//third generator hitpoint gives a third generator with no change here. Circuit names are
//ours to choose; Core matches them as strings.

    class Producers {
        //The accessory section, and the two things that turn it - highest wins. The APU
        //drives it directly and NOT the transmission, hence APU ground ops with the rotor
        //stopped.
        class ApuDrive {
            damageRole   = "apu";
            variableName = "apuDrive";
            output       = "ACCESSORY_DRIVE";
            drivenBy     = "";            //self-driven once running
            gate         = "bmkhs_apuOn";
            nominal      = 1.0;           //spins accessories at full working speed
            rampSeconds  = 0;             //bmkhs_apuOn already follows the APU's own spool
        };
        //Turned by the engines, or by the rotor in an autorotation - same shaft either way,
        //so accessories keep turning with the engines dead.
        class XmsnDrive {
            damageRole   = "transmission";
            variableName = "xmsnDrive";
            output       = "ACCESSORY_DRIVE";
            drivenBy     = "ROTOR";
            minDrive     = 0;             //any rotation at all; the pumps set their own floor
            passthrough  = 1;             //accessories turn at Nr, whatever Nr happens to be
            rampSeconds  = 0;
        };

        //Pumps hang off the accessory section, not the engines, and need fluid to move.
        class PriPump {
            damageRole   = "priPump";
            variableName = "priHydPsi";
            output       = "PRI_HYD";
            drivenBy     = "ACCESSORY_DRIVE";
            minDrive     = 0.45;         //Nr fraction - below this the pump loses drive
            requires     = "bmkhs_priLevel_pct";
            nominal      = 3000;         //psi
            rampSeconds  = 1;             //zero to full pressure - builds, does not snap
        };
        class UtilPump {
            damageRole   = "utilPump";
            variableName = "utilHydPsi";
            output       = "UTIL_HYD";
            drivenBy     = "ACCESSORY_DRIVE";
            minDrive     = 0.45;
            requires     = "bmkhs_utilLevel_pct";
            nominal      = 3000;
            rampSeconds  = 1;
        };

        //Generators need far more shaft speed than the pumps, so an autorotation costs the
        //electrics but not the flight controls.
        class Generator {
            damageRole   = "generators";  //two hitpoints today -> gen1, gen2
            variableName = "gen";
            output       = "AC";
            drivenBy     = "ACCESSORY_DRIVE";
            minDrive     = 0.85;
            nominal      = 1;             //on/off, not volts
            rampSeconds  = 0;             //a contactor closes, it does not spool
        };
        class Rectifier {
            damageRole   = "rectifiers";  //two hitpoints today -> rect1, rect2
            variableName = "rect";
            output       = "DC";
            drivenBy     = "AC";
            minDrive     = 0;             //any AC at all
            nominal      = 1;
            rampSeconds  = 0;
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
            leakStartDmg    = 0.50;
            leakSeconds     = 120;
        };
        class UtilReservoir {
            damageRole      = "utilReservoir";
            variableName    = "utilLevel_pct";
            nominal         = 1.0;
            leakStartDmg    = 0.50;
            leakSeconds     = 120;
            //The gun and the pylons share the utility system, so hits on either vent it.
            drainedBy[]     = {"gunTurret", "pylons"};
        };

        //Discharges to start the APU and is refilled by the pumps it just started. Doubles
        //as emergency flight-control pressure, gated on the crew button.
        class Accumulator {
            //No damageRole - no selection in the p3d, so it cannot be shot out.
            variableName    = "accHydPsi";
            output          = "UTIL_HYD";
            //Off the accessory drive, not UTIL_HYD - a store recharging from the node it
            //feeds would top itself up forever.
            rechargedBy     = "ACCESSORY_DRIVE";
            gate            = "bmkhs_emerHydOn";
            startedBy       = "bmkhs_apuBtnOn";
            nominal         = 3000;       //psi at full charge
            startAbove      = 2600;       //psi needed to turn the APU over at all
            stopBelow       = 1650;       //psi, the floor it stops discharging at
            emerDischarge   = 90;         //sec of emergency pressure
        };
    };

    class Consumers {
        //Either circuit alone keeps the controls moving, so losing one side is a
        //degradation rather than a loss of control.
        class FlightControls {
            variableName = "fltCtrlsSupplied";
            suppliedBy[] = {"PRI_HYD", "UTIL_HYD"};
            minValue     = 1260;          //psi
        };
    };
