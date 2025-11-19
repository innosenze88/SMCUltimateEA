//+------------------------------------------------------------------+
//|                                                VisualManager.mqh |
//|                                          SMC Ultimate EA v1.0    |
//|                                   Visual Indicators Module       |
//+------------------------------------------------------------------+
#property copyright "SMC Ultimate EA"
#property version   "1.00"
#property strict

#include "SMCStructures.mqh"

//+------------------------------------------------------------------+
//| Class for Visual Management                                      |
//+------------------------------------------------------------------+
class CVisualManager
{
private:
   string   m_prefix;       // Prefix for object names
   bool     m_showSwings;   // Show swing points
   bool     m_showBOS;      // Show BOS signals
   bool     m_showCHoCH;    // Show CHoCH signals

   color    m_swingHighColor;
   color    m_swingLowColor;
   color    m_bosColorBull;
   color    m_bosColorBear;
   color    m_chochColorBull;
   color    m_chochColorBear;

public:
   // Constructor
   CVisualManager(string prefix = "SMC_")
   {
      m_prefix = prefix;
      m_showSwings = true;
      m_showBOS = true;
      m_showCHoCH = true;

      // Default colors
      m_swingHighColor = clrRed;
      m_swingLowColor = clrBlue;
      m_bosColorBull = clrLime;
      m_bosColorBear = clrOrange;
      m_chochColorBull = clrGreen;
      m_chochColorBear = clrCrimson;
   }

   //+------------------------------------------------------------------+
   //| Draw swing high on chart                                         |
   //+------------------------------------------------------------------+
   void DrawSwingHigh(SwingPoint &swing, long chartId = 0)
   {
      if(!m_showSwings) return;

      string name = m_prefix + "SwingH_" + TimeToString(swing.time);

      // Draw horizontal line
      ObjectCreate(chartId, name, OBJ_TREND, 0, swing.time, swing.price,
                   swing.time + PeriodSeconds(PERIOD_CURRENT) * 20, swing.price);
      ObjectSetInteger(chartId, name, OBJPROP_COLOR, m_swingHighColor);
      ObjectSetInteger(chartId, name, OBJPROP_STYLE, STYLE_SOLID);
      ObjectSetInteger(chartId, name, OBJPROP_WIDTH, 1);
      ObjectSetInteger(chartId, name, OBJPROP_RAY_RIGHT, true);
      ObjectSetInteger(chartId, name, OBJPROP_BACK, true);

      // Draw label
      string labelName = name + "_Label";
      ObjectCreate(chartId, labelName, OBJ_TEXT, 0, swing.time, swing.price);
      ObjectSetString(chartId, labelName, OBJPROP_TEXT, "SH");
      ObjectSetInteger(chartId, labelName, OBJPROP_COLOR, m_swingHighColor);
      ObjectSetInteger(chartId, labelName, OBJPROP_FONTSIZE, 8);
   }

   //+------------------------------------------------------------------+
   //| Draw swing low on chart                                          |
   //+------------------------------------------------------------------+
   void DrawSwingLow(SwingPoint &swing, long chartId = 0)
   {
      if(!m_showSwings) return;

      string name = m_prefix + "SwingL_" + TimeToString(swing.time);

      // Draw horizontal line
      ObjectCreate(chartId, name, OBJ_TREND, 0, swing.time, swing.price,
                   swing.time + PeriodSeconds(PERIOD_CURRENT) * 20, swing.price);
      ObjectSetInteger(chartId, name, OBJPROP_COLOR, m_swingLowColor);
      ObjectSetInteger(chartId, name, OBJPROP_STYLE, STYLE_SOLID);
      ObjectSetInteger(chartId, name, OBJPROP_WIDTH, 1);
      ObjectSetInteger(chartId, name, OBJPROP_RAY_RIGHT, true);
      ObjectSetInteger(chartId, name, OBJPROP_BACK, true);

      // Draw label
      string labelName = name + "_Label";
      ObjectCreate(chartId, labelName, OBJ_TEXT, 0, swing.time, swing.price);
      ObjectSetString(chartId, labelName, OBJPROP_TEXT, "SL");
      ObjectSetInteger(chartId, labelName, OBJPROP_COLOR, m_swingLowColor);
      ObjectSetInteger(chartId, labelName, OBJPROP_FONTSIZE, 8);
   }

   //+------------------------------------------------------------------+
   //| Draw BOS signal                                                  |
   //+------------------------------------------------------------------+
   void DrawBOS(StructureBreak &sb, long chartId = 0)
   {
      if(!m_showBOS) return;

      color signalColor = sb.isBullish ? m_bosColorBull : m_bosColorBear;
      string name = m_prefix + "BOS_" + TimeToString(sb.time);

      // Draw arrow
      ObjectCreate(chartId, name, OBJ_ARROW, 0, sb.time, sb.price);
      ObjectSetInteger(chartId, name, OBJPROP_ARROWCODE, sb.isBullish ? 241 : 242);
      ObjectSetInteger(chartId, name, OBJPROP_COLOR, signalColor);
      ObjectSetInteger(chartId, name, OBJPROP_WIDTH, 3);

      // Draw label
      string labelName = name + "_Label";
      double labelPrice = sb.isBullish ? sb.price + 20 * _Point : sb.price - 20 * _Point;
      ObjectCreate(chartId, labelName, OBJ_TEXT, 0, sb.time, labelPrice);
      ObjectSetString(chartId, labelName, OBJPROP_TEXT, "BOS " + (sb.isBullish ? "↑" : "↓"));
      ObjectSetInteger(chartId, labelName, OBJPROP_COLOR, signalColor);
      ObjectSetInteger(chartId, labelName, OBJPROP_FONTSIZE, 10);
      ObjectSetInteger(chartId, labelName, OBJPROP_ANCHOR, sb.isBullish ? ANCHOR_BOTTOM : ANCHOR_TOP);
   }

   //+------------------------------------------------------------------+
   //| Draw CHoCH signal                                                |
   //+------------------------------------------------------------------+
   void DrawCHoCH(StructureBreak &sb, long chartId = 0)
   {
      if(!m_showCHoCH) return;

      color signalColor = sb.isBullish ? m_chochColorBull : m_chochColorBear;
      string name = m_prefix + "CHoCH_" + TimeToString(sb.time);

      // Draw arrow
      ObjectCreate(chartId, name, OBJ_ARROW, 0, sb.time, sb.price);
      ObjectSetInteger(chartId, name, OBJPROP_ARROWCODE, sb.isBullish ? 233 : 234);
      ObjectSetInteger(chartId, name, OBJPROP_COLOR, signalColor);
      ObjectSetInteger(chartId, name, OBJPROP_WIDTH, 4);

      // Draw label
      string labelName = name + "_Label";
      double labelPrice = sb.isBullish ? sb.price + 30 * _Point : sb.price - 30 * _Point;
      ObjectCreate(chartId, labelName, OBJ_TEXT, 0, sb.time, labelPrice);
      ObjectSetString(chartId, labelName, OBJPROP_TEXT, "CHoCH " + (sb.isBullish ? "⇈" : "⇊"));
      ObjectSetInteger(chartId, labelName, OBJPROP_COLOR, signalColor);
      ObjectSetInteger(chartId, labelName, OBJPROP_FONTSIZE, 11);
      ObjectSetInteger(chartId, labelName, OBJPROP_ANCHOR, sb.isBullish ? ANCHOR_BOTTOM : ANCHOR_TOP);
   }

   //+------------------------------------------------------------------+
   //| Draw dashboard info                                              |
   //+------------------------------------------------------------------+
   void DrawDashboard(string trendHTF, string trendLTF, int totalTrades,
                      double winRate, long chartId = 0)
   {
      string name = m_prefix + "Dashboard";

      // Create dashboard background
      int x = 10;
      int y = 20;
      int width = 200;
      int height = 100;

      ObjectCreate(chartId, name + "_BG", OBJ_RECTANGLE_LABEL, 0, 0, 0);
      ObjectSetInteger(chartId, name + "_BG", OBJPROP_XDISTANCE, x);
      ObjectSetInteger(chartId, name + "_BG", OBJPROP_YDISTANCE, y);
      ObjectSetInteger(chartId, name + "_BG", OBJPROP_XSIZE, width);
      ObjectSetInteger(chartId, name + "_BG", OBJPROP_YSIZE, height);
      ObjectSetInteger(chartId, name + "_BG", OBJPROP_BGCOLOR, clrBlack);
      ObjectSetInteger(chartId, name + "_BG", OBJPROP_BORDER_TYPE, BORDER_FLAT);
      ObjectSetInteger(chartId, name + "_BG", OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(chartId, name + "_BG", OBJPROP_BACK, false);

      // Title
      ObjectCreate(chartId, name + "_Title", OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(chartId, name + "_Title", OBJPROP_XDISTANCE, x + 10);
      ObjectSetInteger(chartId, name + "_Title", OBJPROP_YDISTANCE, y + 5);
      ObjectSetString(chartId, name + "_Title", OBJPROP_TEXT, "SMC Ultimate EA v1.0");
      ObjectSetInteger(chartId, name + "_Title", OBJPROP_COLOR, clrGold);
      ObjectSetInteger(chartId, name + "_Title", OBJPROP_FONTSIZE, 9);

      // HTF Trend
      ObjectCreate(chartId, name + "_HTF", OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(chartId, name + "_HTF", OBJPROP_XDISTANCE, x + 10);
      ObjectSetInteger(chartId, name + "_HTF", OBJPROP_YDISTANCE, y + 25);
      ObjectSetString(chartId, name + "_HTF", OBJPROP_TEXT, "H4 Trend: " + trendHTF);
      ObjectSetInteger(chartId, name + "_HTF", OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(chartId, name + "_HTF", OBJPROP_FONTSIZE, 8);

      // LTF Trend
      ObjectCreate(chartId, name + "_LTF", OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(chartId, name + "_LTF", OBJPROP_XDISTANCE, x + 10);
      ObjectSetInteger(chartId, name + "_LTF", OBJPROP_YDISTANCE, y + 45);
      ObjectSetString(chartId, name + "_LTF", OBJPROP_TEXT, "M15 Trend: " + trendLTF);
      ObjectSetInteger(chartId, name + "_LTF", OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(chartId, name + "_LTF", OBJPROP_FONTSIZE, 8);

      // Stats
      ObjectCreate(chartId, name + "_Stats", OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(chartId, name + "_Stats", OBJPROP_XDISTANCE, x + 10);
      ObjectSetInteger(chartId, name + "_Stats", OBJPROP_YDISTANCE, y + 65);
      ObjectSetString(chartId, name + "_Stats", OBJPROP_TEXT,
                     StringFormat("Trades: %d | Win: %.1f%%", totalTrades, winRate));
      ObjectSetInteger(chartId, name + "_Stats", OBJPROP_COLOR, clrLightBlue);
      ObjectSetInteger(chartId, name + "_Stats", OBJPROP_FONTSIZE, 8);
   }

   //+------------------------------------------------------------------+
   //| Remove all visual objects                                        |
   //+------------------------------------------------------------------+
   void RemoveAll(long chartId = 0)
   {
      ObjectsDeleteAll(chartId, m_prefix);
   }

   //+------------------------------------------------------------------+
   //| Set visibility options                                           |
   //+------------------------------------------------------------------+
   void SetShowSwings(bool show) { m_showSwings = show; }
   void SetShowBOS(bool show) { m_showBOS = show; }
   void SetShowCHoCH(bool show) { m_showCHoCH = show; }
};
