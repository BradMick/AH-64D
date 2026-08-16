/* ----------------------------------------------------------------------------
    AH-64D Flight Model Tuner - non-blocking DATA OVERLAY (RscTitles / cutRsc).

    Display-only layer: renders on screen, player keeps FULL flight control.
    Updated each frame by fza_sfmplus_fnc_tunerOverlay.

    The forces TABLE is a STATIC grid of cells (cutRsc layers cannot create
    controls at runtime, so every cell is defined here). IDC scheme for the grid:
        cell idc = 54400 + row*10 + col
      row: 0 = header, 1..9 = generators, 10 = NET
      col: 0 = label (left-aligned), 1..6 = Fx Fy Fz Mrol Mpit Myaw (right-aligned)
    fn_tunerOverlay sets each cell's text + colour by idc every frame.
---------------------------------------------------------------------------- */

class RscText;

//--- Grid geometry macros (tweak here / in the GUI editor) -------------------
// YS = the row's FULL y expression, passed PRE-QUOTED (e.g. "safeZoneY + 0.335").
// No stringizing (#) anywhere - YS is already a complete string literal, so it
// drops straight into y=. x uses fixed literal column offset strings.
#define ROW_H   0.0345
#define LAB_W   0.20

#define NCELL1(R,YS) class Cell_##R##_1 : fza_sfmplus_TunerCell { idc = 54400+R*10+1; x = "safeZoneX + 0.216"; y = YS; w = 0.106; h = ROW_H; };
#define NCELL2(R,YS) class Cell_##R##_2 : fza_sfmplus_TunerCell { idc = 54400+R*10+2; x = "safeZoneX + 0.328"; y = YS; w = 0.106; h = ROW_H; };
#define NCELL3(R,YS) class Cell_##R##_3 : fza_sfmplus_TunerCell { idc = 54400+R*10+3; x = "safeZoneX + 0.440"; y = YS; w = 0.106; h = ROW_H; };
#define NCELL4(R,YS) class Cell_##R##_4 : fza_sfmplus_TunerCell { idc = 54400+R*10+4; x = "safeZoneX + 0.552"; y = YS; w = 0.106; h = ROW_H; };
#define NCELL5(R,YS) class Cell_##R##_5 : fza_sfmplus_TunerCell { idc = 54400+R*10+5; x = "safeZoneX + 0.664"; y = YS; w = 0.106; h = ROW_H; };
#define NCELL6(R,YS) class Cell_##R##_6 : fza_sfmplus_TunerCell { idc = 54400+R*10+6; x = "safeZoneX + 0.776"; y = YS; w = 0.106; h = ROW_H; };
#define LCELL(R,YS)  class Cell_##R##_0 : fza_sfmplus_TunerCellL { idc = 54400+R*10;   x = "safeZoneX + 0.016"; y = YS; w = LAB_W; h = ROW_H; };

// Full row: label + 6 number cells. YS = the pre-quoted y string for the row.
#define TBLROW(R,YS) LCELL(R,YS) NCELL1(R,YS) NCELL2(R,YS) NCELL3(R,YS) NCELL4(R,YS) NCELL5(R,YS) NCELL6(R,YS)

// SCALARS-by-band table: same 7-column geometry, IDC base 54500 (54500+R*10+C).
// Row 0 = header, rows 1..9 = the 9 airspeed bands. Col 0 = band label, cols 1..7
// = mainThr / tailThr / tailTrim / torque / stabLift / fuseSide / fin.
#define SCELL1(R,YS) class SCell_##R##_1 : fza_sfmplus_TunerCell { idc = 54600+R*10+1; x = "safeZoneX + 0.216"; y = YS; w = 0.106; h = ROW_H; };
#define SCELL2(R,YS) class SCell_##R##_2 : fza_sfmplus_TunerCell { idc = 54600+R*10+2; x = "safeZoneX + 0.328"; y = YS; w = 0.106; h = ROW_H; };
#define SCELL3(R,YS) class SCell_##R##_3 : fza_sfmplus_TunerCell { idc = 54600+R*10+3; x = "safeZoneX + 0.440"; y = YS; w = 0.106; h = ROW_H; };
#define SCELL4(R,YS) class SCell_##R##_4 : fza_sfmplus_TunerCell { idc = 54600+R*10+4; x = "safeZoneX + 0.552"; y = YS; w = 0.106; h = ROW_H; };
#define SCELL5(R,YS) class SCell_##R##_5 : fza_sfmplus_TunerCell { idc = 54600+R*10+5; x = "safeZoneX + 0.664"; y = YS; w = 0.106; h = ROW_H; };
#define SCELL6(R,YS) class SCell_##R##_6 : fza_sfmplus_TunerCell { idc = 54600+R*10+6; x = "safeZoneX + 0.776"; y = YS; w = 0.106; h = ROW_H; };
#define SCELL7(R,YS) class SCell_##R##_7 : fza_sfmplus_TunerCell { idc = 54600+R*10+7; x = "safeZoneX + 0.888"; y = YS; w = 0.106; h = ROW_H; };
#define SLCELL(R,YS) class SCell_##R##_0 : fza_sfmplus_TunerCellL { idc = 54600+R*10;   x = "safeZoneX + 0.016"; y = YS; w = LAB_W; h = ROW_H; };
#define SCLROW(R,YS) SLCELL(R,YS) SCELL1(R,YS) SCELL2(R,YS) SCELL3(R,YS) SCELL4(R,YS) SCELL5(R,YS) SCELL6(R,YS) SCELL7(R,YS)

class RscTitles
{
    class fza_sfmplus_tunerOverlay
    {
        idd          = 54300;
        movingEnable = 1;       // non-blocking: player retains flight inputs
        duration     = 1e11;
        fadein       = 0;
        fadeout      = 0;
        name         = "fza_sfmplus_tunerOverlay";
        onLoad       = "uiNamespace setVariable ['fza_sfmplus_tunerOverlay', _this select 0];";
        onUnload     = "uiNamespace setVariable ['fza_sfmplus_tunerOverlay', displayNull];";

        class controls
        {
            //Background panel.
            class BG : RscText
            {
                idc = 54301;
                colorBackground[] = {0, 0, 0, 0.70};
                colorText[]       = {0, 0, 0, 0};
                text = "";
                x = "safeZoneX + 0.010";
                y = "safeZoneY + 0.030";
                w = 1.035;
                h = 1.14;
            };
            class Title : RscText
            {
                idc = 54302;
                colorBackground[] = {0.10, 0.10, 0.10, 0.90};
                colorText[]       = {1, 0.85, 0.4, 1};
                text = "FM TUNER - LIVE";
                font = "PuristaMedium";
                sizeEx = 0.039;
                style = 2;
                x = "safeZoneX + 0.010";
                y = "safeZoneY + 0.030";
                w = 1.035;
                h = 0.042;
            };
            //--- Summary lines (plain text) --------------------------------------
            class L1 : Title
            {
                idc = 54311;
                colorBackground[] = {0,0,0,0};
                colorText[]       = {0.7,0.9,1,1};
                font = "EtelkaMonospacePro";
                style = 0;
                sizeEx = 0.030;
                text = "";
                x = "safeZoneX + 0.016";
                w = 1.02;
                y = "safeZoneY + 0.088";
                h = 0.033;
            };
            class L2  : L1 { idc = 54312; y = "safeZoneY + 0.1225"; };
            class L3  : L1 { idc = 54313; y = "safeZoneY + 0.1570"; };
            class L4  : L1 { idc = 54314; y = "safeZoneY + 0.1915"; };
            class L5  : L1 { idc = 54315; y = "safeZoneY + 0.2260"; sizeEx = 0.022; }; // MASTER + PID auto-tune status; smaller font so the combined line fits
            //SCALARS - single line, smaller font so all 5 scalars fit the width.
            class L6  : L1 { idc = 54316; y = "safeZoneY + 0.2605"; sizeEx = 0.022; };

            //--- Forces TABLE cell templates -------------------------------------
            class fza_sfmplus_TunerCell : RscText
            {
                idc = -1;
                colorBackground[] = {0,0,0,0};
                colorText[]       = {0.7,0.9,1,1};
                font = "EtelkaMonospacePro";
                sizeEx = 0.030;
                style = 1;   // ST_RIGHT - number columns
                text = "";
                x = 0; y = 0; w = 0.11; h = 0.033;
            };
            class fza_sfmplus_TunerCellL : fza_sfmplus_TunerCell
            {
                style = 0;   // ST_LEFT - label column
            };

            //--- The 12-row x 7-col static grid (header + 10 gens + NET) ----------
            TBLROW(0,"safeZoneY + 0.3350")   // header
            TBLROW(1,"safeZoneY + 0.3695")   // Main Rotor
            TBLROW(2,"safeZoneY + 0.4040")   // Tail Rotor
            TBLROW(3,"safeZoneY + 0.4385")   // Right Wing
            TBLROW(4,"safeZoneY + 0.4730")   // Left Wing
            TBLROW(5,"safeZoneY + 0.5075")   // Vertical Fin
            TBLROW(6,"safeZoneY + 0.5420")   // Stabilator
            TBLROW(7,"safeZoneY + 0.5765")   // Fuselage Front
            TBLROW(8,"safeZoneY + 0.6110")   // Fuselage Side
            TBLROW(9,"safeZoneY + 0.6455")   // Fuselage Top
            TBLROW(10,"safeZoneY + 0.6800")  // Yaw Damper
            TBLROW(11,"safeZoneY + 0.7145")  // NET

            //Net-moment + crab summary line, directly below the forces table's NET
            //row so the scalars-by-band header/rows sit clearly beneath it.
            class L18 : L1 { idc = 54328; y = "safeZoneY + 0.7495"; };

            //--- SCALARS-by-band table (header + 9 airspeed bands) ----------------
            //Header row sits clearly BELOW the Net Nm line, with a gap.
            SCLROW(0,"safeZoneY + 0.8145")   // header: band mainThr tailThr tailTrim torque stabLift fuseSide fin
            SCLROW(1,"safeZoneY + 0.8490")   // band 0
            SCLROW(2,"safeZoneY + 0.8835")   // band 1
            SCLROW(3,"safeZoneY + 0.9180")   // band 2
            SCLROW(4,"safeZoneY + 0.9525")   // band 3
            SCLROW(5,"safeZoneY + 0.9870")   // band 4
            SCLROW(6,"safeZoneY + 1.0215")   // band 5
            SCLROW(7,"safeZoneY + 1.0560")   // band 6
            SCLROW(8,"safeZoneY + 1.0905")   // band 7
            SCLROW(9,"safeZoneY + 1.1250")   // band 8
        };
    };
};
