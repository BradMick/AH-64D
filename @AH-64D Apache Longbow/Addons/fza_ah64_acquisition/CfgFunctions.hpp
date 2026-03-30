#ifdef __A3_DEBUG__
#define R recompile = 1
#else
#define R recompile = 0
#endif
class CfgFunctions
{
    class fza_ah64_acquisition {
        tag="fza_acquisition";
        class functions {
            file = "\fza_ah64_acquisition\functions";
            class update{R;};
        };
    };
};