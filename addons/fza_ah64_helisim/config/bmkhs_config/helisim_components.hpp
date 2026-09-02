/////////////////////////////////////////////////////////////////////////////////////////////
// Components ///////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////
//What this airframe actually has, and what it is wired to. Core reads these and runs one
//kind per component - it has no idea what an AH-64 is.
//
//Member count comes from damageRole: the hitpoints claiming that role ARE the members, so
//a third generator hitpoint gives a third generator with no change to Core or to this file
//beyond the hitpoint itself. A role nothing claims means the component does not exist here.
//
//Circuits are just names. These are ours to choose; Core matches them as strings.
//  ACCESSORY_DRIVE  turned by the APU, or by the transmission (engines, or the rotor in
//                   an autorotation) - which is why hydraulics survive an engine failure
//  PRI_HYD/UTIL_HYD the two flight-control hydraulic circuits
//  AC/DC            the electrical buses

    class Producers {
        //The accessory section, and the two things that can turn it. Highest feeder wins the
        //node, so whichever is spinning faster is what drives the accessories.
        //
        //The APU drives the accessory section directly and NOT the transmission, which is why
        //APU ground ops give hydraulics and generators with the rotor stopped.
        class ApuDrive {
            damageRole   = "apu";
            variableName = "apuDrive";
            output       = "ACCESSORY_DRIVE";
            drivenBy     = "";            //self-driven once running
            gate         = "bmkhs_apuOn";
            nominal      = 1.0;           //spins accessories at full working speed
            rampSeconds  = 0;             //bmkhs_apuOn already follows the APU's own spool
        };
        //The transmission, turned by the engines or - in an autorotation - by the rotor.
        //Nr is the same shaft either way, so accessories keep turning with the engines dead.
        class XmsnDrive {
            damageRole   = "transmission";
            variableName = "xmsnDrive";
            output       = "ACCESSORY_DRIVE";
            drivenBy     = "ROTOR";
            minDrive     = 0;             //any rotation at all; the pumps set their own floor
            passthrough  = 1;             //accessories turn at Nr, whatever Nr happens to be
            rampSeconds  = 0;
        };

        //Hydraulic pumps hang off the accessory section, NOT the engines - an APU with the
        //engines shut down still makes pressure, and so does an autorotating rotor. They
        //need fluid to move, so a holed reservoir stops them however healthy they are.
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

        //Generators need considerably more shaft speed than the pumps do, which is what
        //makes an autorotation cost you the electrics but not the flight controls.
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
        //The accumulator's primary job is starting the APU: it discharges to spin it up,
        //and the APU driving the pumps is what refills it. That is the ACCUM caution
        //appearing and then clearing on a normal start.
        //
        //Its secondary job is emergency flight-control pressure, gated on the crew pressing
        //the button, which is why it feeds the utility circuit rather than sitting idle.
        class Accumulator {
            //No damageRole - the accumulator has no selection of its own in the p3d, so it
            //is not separately damageable. It still exists; it just cannot be shot out.
            variableName = "accHydPsi";
            output       = "UTIL_HYD";
            //Refills off the accessory drive, not off UTIL_HYD - a store recharging from the
            //node it feeds would top itself up forever. A turning accessory section means the
            //pumps are circulating fluid, which is what actually recharges it.
            rechargedBy  = "ACCESSORY_DRIVE";
            gate         = "bmkhs_emerHydOn";
            startedBy    = "bmkhs_apuBtnOn";
            startDraw       = 0.35;       //fraction of full charge one APU start costs
            spentBelow      = 1650;       //psi, the floor it stops discharging at
            drainSeconds    = 90;         //full to empty, discharging
            rechargeSeconds = 20;         //empty to full, once the pumps are turning
            nominal         = 3000;
        };
    };

    class Consumers {
        //Fed by primary AND utility: either one alone keeps the controls moving, so losing
        //the primary side is a degradation rather than a loss of control.
        class FlightControls {
            variableName = "fltCtrlsSupplied";
            suppliedBy[] = {"PRI_HYD", "UTIL_HYD"};
            minValue     = 1260;          //psi
        };
    };
