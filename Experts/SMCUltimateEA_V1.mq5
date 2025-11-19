//+------------------------------------------------------------------+
//|                                              SMCUltimateEA_V1.mq5|
//|                                          SMC Ultimate EA v1.0    |
//|                                   Smart Money Concepts EA        |
//+------------------------------------------------------------------+
#property copyright "SMC Ultimate EA"
#property link      "https://github.com/innosenze88/SMCUltimateEA"
#property version   "1.00"
#property description "Smart Money Concepts EA - BOS/CHoCH Detection"
#property description "Dual Timeframe: H4 (trend) + M15 (entry)"
#property strict

#include <Trade\Trade.mqh>
#include "../Include/SMCStructures.mqh"
#include "../Include/RiskManager.mqh"
#include "../Include/VisualManager.mqh"

//+------------------------------------------------------------------+
//| Input Parameters                                                 |
//+------------------------------------------------------------------+
input group "=== Timeframe Settings ==="
input ENUM_TIMEFRAMES InpHTF = PERIOD_H4;          // Higher Timeframe (Trend)
input ENUM_TIMEFRAMES InpLTF = PERIOD_M15;         // Lower Timeframe (Entry)

input group "=== SMC Settings ==="
input int             InpSwingStrength = 5;        // Swing Strength (bars)
input bool            InpTradeBOS = true;          // Trade BOS Signals
input bool            InpTradeCHoCH = true;        // Trade CHoCH Signals

input group "=== Risk Management ==="
input double          InpRiskPercent = 1.0;        // Risk Per Trade (%)
input double          InpRRRatio = 2.0;            // Risk:Reward Ratio
input int             InpSLBuffer = 10;            // Stop Loss Buffer (points)

input group "=== Visual Settings ==="
input bool            InpShowSwings = true;        // Show Swing Points
input bool            InpShowBOS = true;           // Show BOS Signals
input bool            InpShowCHoCH = true;         // Show CHoCH Signals
input bool            InpShowDashboard = true;     // Show Dashboard

input group "=== Trading Settings ==="
input int             InpMagicNumber = 123456;     // Magic Number
input string          InpTradeComment = "SMC_v1";  // Trade Comment

//+------------------------------------------------------------------+
//| Global Variables                                                 |
//+------------------------------------------------------------------+
CMarketStructure*     g_htfStructure;              // HTF structure analyzer
CMarketStructure*     g_ltfStructure;              // LTF structure analyzer
CRiskManager*         g_riskManager;               // Risk manager
CVisualManager*       g_visualManager;             // Visual manager
CTrade                g_trade;                     // Trade execution object

datetime              g_lastBarTime = 0;           // Last bar time for new bar detection
int                   g_totalTrades = 0;           // Total trades taken
int                   g_winningTrades = 0;         // Winning trades
bool                  g_positionOpen = false;      // Is position currently open?

//+------------------------------------------------------------------+
//| Expert initialization function                                    |
//+------------------------------------------------------------------+
int OnInit()
{
   // Initialize objects
   g_htfStructure = new CMarketStructure(_Symbol, InpHTF, InpSwingStrength);
   g_ltfStructure = new CMarketStructure(_Symbol, InpLTF, InpSwingStrength);
   g_riskManager = new CRiskManager(InpRiskPercent, _Symbol);
   g_visualManager = new CVisualManager("SMC_");

   // Configure trade object
   g_trade.SetExpertMagicNumber(InpMagicNumber);
   g_trade.SetDeviationInPoints(10);
   g_trade.SetTypeFilling(ORDER_FILLING_FOK);

   // Configure visual settings
   g_visualManager.SetShowSwings(InpShowSwings);
   g_visualManager.SetShowBOS(InpShowBOS);
   g_visualManager.SetShowCHoCH(InpShowCHoCH);

   Print("=== SMC Ultimate EA v1.0 Initialized ===");
   Print("HTF: ", EnumToString(InpHTF), " | LTF: ", EnumToString(InpLTF));
   Print("Risk: ", InpRiskPercent, "% | R:R: 1:", InpRRRatio);
   Print("Trading: BOS=", InpTradeBOS, " CHoCH=", InpTradeCHoCH);

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   // Clean up objects
   if(g_htfStructure != NULL) delete g_htfStructure;
   if(g_ltfStructure != NULL) delete g_ltfStructure;
   if(g_riskManager != NULL) delete g_riskManager;
   if(g_visualManager != NULL) delete g_visualManager;

   // Remove visual objects
   g_visualManager.RemoveAll();

   Print("SMC Ultimate EA deinitialized. Reason: ", reason);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // Check for new bar on LTF
   if(!IsNewBar()) return;

   // Update structures
   g_htfStructure.UpdateSwingPoints();
   g_ltfStructure.UpdateSwingPoints();
   g_htfStructure.UpdateTrend();
   g_ltfStructure.UpdateTrend();

   // Update visual elements
   UpdateVisuals();

   // Check if position is already open
   CheckOpenPosition();

   // If position open, skip new entries
   if(g_positionOpen) return;

   // Look for trading signals
   CheckTradingSignals();
}

//+------------------------------------------------------------------+
//| Check if new bar formed                                          |
//+------------------------------------------------------------------+
bool IsNewBar()
{
   datetime currentBarTime = iTime(_Symbol, InpLTF, 0);

   if(currentBarTime != g_lastBarTime)
   {
      g_lastBarTime = currentBarTime;
      return true;
   }

   return false;
}

//+------------------------------------------------------------------+
//| Check if position is open                                        |
//+------------------------------------------------------------------+
void CheckOpenPosition()
{
   g_positionOpen = false;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(PositionGetSymbol(i) == _Symbol &&
         PositionGetInteger(POSITION_MAGIC) == InpMagicNumber)
      {
         g_positionOpen = true;
         break;
      }
   }
}

//+------------------------------------------------------------------+
//| Check for trading signals                                        |
//+------------------------------------------------------------------+
void CheckTradingSignals()
{
   // Get HTF trend direction
   ENUM_TREND_DIRECTION htfTrend = g_htfStructure.GetTrend();

   // Detect BOS on LTF
   if(InpTradeBOS)
   {
      StructureBreak *bos = g_ltfStructure.DetectBOS();
      if(bos != NULL)
      {
         // Check if BOS aligns with HTF trend
         if((bos.isBullish && htfTrend == TREND_BULLISH) ||
            (!bos.isBullish && htfTrend == TREND_BEARISH))
         {
            Print("BOS Detected! Direction: ", bos.isBullish ? "Bullish" : "Bearish");
            ExecuteTrade(bos.isBullish, bos.price, bos.brokenLevel.price, "BOS");
         }

         delete bos;
      }
   }

   // Detect CHoCH on LTF
   if(InpTradeCHoCH)
   {
      StructureBreak *choch = g_ltfStructure.DetectCHoCH();
      if(choch != NULL)
      {
         Print("CHoCH Detected! Direction: ", choch.isBullish ? "Bullish" : "Bearish");
         ExecuteTrade(choch.isBullish, choch.price, choch.brokenLevel.price, "CHoCH");

         delete choch;
      }
   }
}

//+------------------------------------------------------------------+
//| Execute trade                                                    |
//+------------------------------------------------------------------+
void ExecuteTrade(bool isBuy, double entryPrice, double structureLevel, string signalType)
{
   // Update account balance
   g_riskManager.UpdateAccountBalance();

   // Calculate stop loss
   double sl = g_riskManager.CalculateStopLoss(isBuy, structureLevel, InpSLBuffer);

   // Calculate take profit
   double tp = g_riskManager.CalculateTakeProfit(isBuy, entryPrice, sl, InpRRRatio);

   // Normalize prices
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   sl = NormalizeDouble(sl, digits);
   tp = NormalizeDouble(tp, digits);

   // Validate trade parameters
   if(!g_riskManager.ValidateTradeParams(entryPrice, sl, tp))
   {
      Print("Trade parameters validation failed");
      return;
   }

   // Calculate lot size
   double lotSize = g_riskManager.CalculateLotSize(entryPrice, sl);

   if(lotSize <= 0)
   {
      Print("Invalid lot size: ", lotSize);
      return;
   }

   // Prepare trade comment
   string comment = InpTradeComment + "_" + signalType;

   // Execute trade
   bool result = false;

   if(isBuy)
   {
      result = g_trade.Buy(lotSize, _Symbol, 0, sl, tp, comment);
      Print("BUY Order: ", isBuy ? "Success" : "Failed");
   }
   else
   {
      result = g_trade.Sell(lotSize, _Symbol, 0, sl, tp, comment);
      Print("SELL Order: ", result ? "Success" : "Failed");
   }

   if(result)
   {
      Print("=== TRADE EXECUTED ===");
      Print("Type: ", isBuy ? "BUY" : "SELL");
      Print("Signal: ", signalType);
      Print("Entry: ", entryPrice);
      Print("SL: ", sl, " (", MathAbs(entryPrice - sl) / point, " points)");
      Print("TP: ", tp, " (", MathAbs(tp - entryPrice) / point, " points)");
      Print("Lot: ", lotSize);
      Print("Risk: ", g_riskManager.GetRiskAmount(), " ", AccountInfoString(ACCOUNT_CURRENCY));
      Print("=====================");

      g_totalTrades++;
   }
   else
   {
      Print("Trade failed: ", g_trade.ResultRetcodeDescription());
   }
}

//+------------------------------------------------------------------+
//| Update visual elements                                           |
//+------------------------------------------------------------------+
void UpdateVisuals()
{
   // Draw swing points
   if(InpShowSwings)
   {
      SwingPoint highs[];
      SwingPoint lows[];

      g_ltfStructure.GetSwingHighs(highs);
      g_ltfStructure.GetSwingLows(lows);

      for(int i = 0; i < ArraySize(highs); i++)
         g_visualManager.DrawSwingHigh(highs[i]);

      for(int i = 0; i < ArraySize(lows); i++)
         g_visualManager.DrawSwingLow(lows[i]);
   }

   // Draw dashboard
   if(InpShowDashboard)
   {
      string htfTrendStr = GetTrendString(g_htfStructure.GetTrend());
      string ltfTrendStr = GetTrendString(g_ltfStructure.GetTrend());
      double winRate = (g_totalTrades > 0) ? (g_winningTrades * 100.0 / g_totalTrades) : 0;

      g_visualManager.DrawDashboard(htfTrendStr, ltfTrendStr, g_totalTrades, winRate);
   }
}

//+------------------------------------------------------------------+
//| Get trend as string                                              |
//+------------------------------------------------------------------+
string GetTrendString(ENUM_TREND_DIRECTION trend)
{
   switch(trend)
   {
      case TREND_BULLISH:  return "BULLISH";
      case TREND_BEARISH:  return "BEARISH";
      case TREND_NEUTRAL:  return "NEUTRAL";
      default:             return "UNKNOWN";
   }
}

//+------------------------------------------------------------------+
//| OnTrade event handler                                            |
//+------------------------------------------------------------------+
void OnTrade()
{
   // Update win rate when positions close
   // This is a simplified version - proper tracking would be more complex
}
