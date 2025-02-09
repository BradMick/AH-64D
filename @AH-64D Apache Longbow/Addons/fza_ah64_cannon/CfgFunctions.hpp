#ifdef __A3_DEBUG__
#define R recompile = 1
#else
#define R recompile = 0
#endif
class CfgFunctions
{
    class fza_ah64_cannon
    {
        tag = "fza_cannon";
        class ballistics {
            file = "\fza_ah64_cannon\functions\ballistics";
            class ballisticSolver {R;};
            class getFinalVelocity {R;};
            class getTargetElevation {R;};
            class getTurretElevationAngle {R;};
        };
        class functions {
            file = "\fza_ah64_cannon\functions";
            class fired {R;};
            class init {R;};
            class update {R;};
        };
    };
};