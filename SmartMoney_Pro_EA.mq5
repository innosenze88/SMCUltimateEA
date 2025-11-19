//+------------------------------------------------------------------+
//|                                      SmartMoney_Pro_EA.mq5        |
//|                     Smart Money Concepts Trading System           |
//|                              Version 2.0                          |
//|                                                                    |
//| Implements pure SMC methodology:                                  |
//| - Break of Structure (BOS)                                       |
//| - Change of Character (CHoCH)                                    |
//| - Fair Value Gaps (FVG)                                          |
//| - Order Blocks (OB)                                              |
//+------------------------------------------------------------------+

#property copyright "Smart Money Concepts"
#property link      "https://smartmoneyconcepts.com"
#property version   "2.0"
#property strict
#property description "Professional SMC Trading EA with 7 Entry Methods"

#include <Trade/Trade.mqh>
#include <Trade/SymbolInfo.mqh>
#include <Trade/PositionInfo.mqh>

// ===== ENUMS =====
enum ENTRY_METHOD {
    ENTRY_BOS_BREAK = 0,        // Break of Structure - Immediate Entry
    ENTRY_BOS_RETEST = 1,       // Break of Structure - Retest Entry (Recommended)
    ENTRY_CHOCH_BREAK = 2,      // Change of Character - Break
    ENTRY_CHOCH_RETEST = 3,     // Change of Character - Retest
    ENTRY_FVG_FILL = 4,         // Fair Value Gap Fill
    ENTRY_OB_TOUCH = 5,         // Order Block Touch
    ENTRY_COMBINED = 6          // Combined Confirmations (Best)
};

enum SL_METHOD {
    SL_SWING = 0,               // Based on swing structure
    SL_ORDERBLOCK = 1,          // Based on order block
    SL_FVG = 2,                 // Based on FVG
    SL_ATR = 3                  // Based on ATR
};

enum TRADE_BIAS {
    BIAS_BULLISH = 1,
    BIAS_BEARISH = -1,
    BIAS_NEUTRAL = 0
};

// ===== STRUCTURES =====
struct SwingPoint {
    int bar;
    double price;
    bool isHigh;
};

struct FVGZone {
    double top;
    double bottom;
    int barCreated;
    bool isBullish;
    double fillPercent;
};

struct OrderBlock {
    double high;
    double low;
    int barCreated;
    bool isBullish;
    int touchCount;
    double strength;
};

// ===== INPUT PARAMETERS =====

// -----Timeframe Settings-----
input ENUM_TIMEFRAMES HTF = PERIOD_H4;               // Higher timeframe
input ENUM_TIMEFRAMES LTF = PERIOD_M15;              // Lower timeframe
input ENUM_TIMEFRAMES OrderBlockTF = PERIOD_H1;     // Order block timeframe

// -----Entry Configuration-----
input ENTRY_METHOD EntryMethod = ENTRY_BOS_RETEST;  // Entry method
input SL_METHOD StopLossMethod = SL_SWING;          // Stop loss method
input double MinRiskReward = 2.0;                   // Minimum R:R ratio
input double RiskPercent = 1.0;                     // Risk per trade %

// -----Structure Detection-----
input bool RequireHTFConfirmation = true;           // Wait for HTF alignment
input bool TradeWithTrend = true;                   // Only trade with HTF trend
input bool UseFVG = true;                           // Use Fair Value Gaps
input bool UseOrderBlocks = true;                   // Use Order Blocks
input bool RequireStrongOB = true;                  // Only strong order blocks

// -----FVG Settings-----
input double MinFvgSize = 20;                       // Minimum FVG size (points)
input double FvgFillPercent = 50;                   // Entry at FVG fill %
input int MaxFvgAge = 50;                           // Max bars since FVG created

// -----Order Block Settings-----
input double MinOrderBlockSize = 30;                // Minimum OB candle size
input int OBTouchZone = 30;                         // Touch zone % of OB
input int MaxOBTouches = 2;                         // Max touches to trade

// -----Trade Management-----
input bool UseBreakeven = true;                     // Move SL to breakeven
input double BreakevenTrigger = 1.0;                // Trigger for breakeven (R)
input bool UseTrailingStop = true;                  // Use trailing stop
input double TrailingTrigger = 1.5;                 // Start trailing at R
input double TrailPoints = 20;                      // Trail distance (points)
input bool UsePartialClose = true;                  // Close trades partially
input double PartialCloseTrigger = 2.0;             // Partial close at R
input double PartialClosePercent = 50;              // Close % of position

// -----Risk Management-----
input int MaxDailyTrades = 3;                       // Max trades per day
input double MaxDailyLossPercent = 2.0;             // Max loss per day %
input double MaxSpreadPoints = 10;                  // Max spread allowed

// -----Session Control-----
input bool OnlyTradeSession = false;                // Trade only in session
input int SessionStartHour = 8;                     // Session start hour
input int SessionEndHour = 16;                      // Session end hour

// -----Visualization-----
input bool ShowStructure = true;                    // Show HTF/LTF structure
input bool ShowFVG = true;                          // Show FVG zones
input bool ShowOrderBlocks = true;                  // Show order blocks
input bool ShowLabels = true;                       // Show signal labels
input bool ShowPanel = true;                        // Show info panel

// ===== GLOBAL VARIABLES =====
CTrade trade;
CPositionInfo position;
CSymbolInfo symbol;

struct DailyStats {
    int tradesCount;
    double dailyPnL;
    double dailyLoss;
} dailyStats;

FVGZone bullishFVGs[100];
FVGZone bearishFVGs[100];
OrderBlock bullishOBs[100];
OrderBlock bearishOBs[100];

int bullishFVGCount = 0;
int bearishFVGCount = 0;
int bullishOBCount = 0;
int bearishOBCount = 0;

SwingPoint lastSwingHigh, lastSwingLow;
bool htfBullish = true;
bool ltfBullish = true;
double accountBalance = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                    |
//+------------------------------------------------------------------+
int OnInit() {
    // Initialize trade object
    trade.SetExpertMagicNumber(123456789);
    trade.SetDeviationInPoints(50);

    // Log initialization
    Print("SmartMoney Pro EA v2.0 Initialized");
    Print("Entry Method: ", EntryMethod);
    Print("Risk: ", RiskPercent, "% per trade");
    Print("Min R:R: 1:", MinRiskReward);

    accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);

    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    // Clean up visual objects
    DeleteAllObjects();
    Print("EA Stopped");
}

//+------------------------------------------------------------------+
//| Expert tick function                                              |
//+------------------------------------------------------------------+
void OnTick() {
    // Safety checks
    if (!IsTradeAllowed() || !SymbolSelect(_Symbol, true)) return;
    if (iBlankValue(Close[0])) return;

    // Update daily stats
    UpdateDailyStats();

    // Get current structure
    DetectStructure();

    // Detect patterns
    if (UseFVG) DetectFVG();
    if (UseOrderBlocks) DetectOrderBlocks();

    // Check entry conditions
    CheckEntrySetup();

    // Manage open trades
    ManageTrades();

    // Draw visualizations
    if (ShowStructure) DrawStructure();
    if (ShowFVG) DrawFVG();
    if (ShowOrderBlocks) DrawOrderBlocks();
    if (ShowPanel) DrawInfoPanel();
}

//+------------------------------------------------------------------+
//| Detect Market Structure                                            |
//+------------------------------------------------------------------+
void DetectStructure() {
    // HTF Structure
    DetectSwings(HTF, lastSwingHigh, lastSwingLow);
    htfBullish = (lastSwingHigh.price > lastSwingLow.price);

    // LTF Structure
    SwingPoint ltfHigh, ltfLow;
    DetectSwings(LTF, ltfHigh, ltfLow);
    ltfBullish = (ltfHigh.price > ltfLow.price);
}

//+------------------------------------------------------------------+
//| Detect Swing Points                                                |
//+------------------------------------------------------------------+
void DetectSwings(ENUM_TIMEFRAMES tf, SwingPoint &swingHigh, SwingPoint &swingLow) {
    int bars = 5;

    // Find last swing high
    for (int i = bars; i < 500; i++) {
        double price = iHigh(Symbol(), tf, i);
        bool isHigher = true;

        for (int j = 1; j <= bars; j++) {
            if (iHigh(Symbol(), tf, i + j) >= price || iHigh(Symbol(), tf, i - j) >= price) {
                isHigher = false;
                break;
            }
        }

        if (isHigher) {
            swingHigh.bar = i;
            swingHigh.price = price;
            swingHigh.isHigh = true;
            break;
        }
    }

    // Find last swing low
    for (int i = bars; i < 500; i++) {
        double price = iLow(Symbol(), tf, i);
        bool isLower = true;

        for (int j = 1; j <= bars; j++) {
            if (iLow(Symbol(), tf, i + j) <= price || iLow(Symbol(), tf, i - j) <= price) {
                isLower = false;
                break;
            }
        }

        if (isLower) {
            swingLow.bar = i;
            swingLow.price = price;
            swingLow.isHigh = false;
            break;
        }
    }
}

//+------------------------------------------------------------------+
//| Detect Fair Value Gaps                                             |
//+------------------------------------------------------------------+
void DetectFVG() {
    bullishFVGCount = 0;
    bearishFVGCount = 0;

    // Scan last 100 candles
    for (int i = 3; i < 100; i++) {
        // Bullish FVG: C1 High < C3 Low
        double c1High = iHigh(Symbol(), LTF, i);
        double c2High = iHigh(Symbol(), LTF, i - 1);
        double c3Low = iLow(Symbol(), LTF, i - 2);

        if (c1High < c3Low && (c3Low - c1High) > MinFvgSize * Point()) {
            FVGZone fvg;
            fvg.top = c3Low;
            fvg.bottom = c1High;
            fvg.barCreated = i;
            fvg.isBullish = true;
            fvg.fillPercent = 0;

            bullishFVGs[bullishFVGCount] = fvg;
            bullishFVGCount++;
        }

        // Bearish FVG: C1 Low > C3 High
        double c1Low = iLow(Symbol(), LTF, i);
        double c3High = iHigh(Symbol(), LTF, i - 2);

        if (c1Low > c3High && (c1Low - c3High) > MinFvgSize * Point()) {
            FVGZone fvg;
            fvg.top = c1Low;
            fvg.bottom = c3High;
            fvg.barCreated = i;
            fvg.isBullish = false;
            fvg.fillPercent = 0;

            bearishFVGs[bearishFVGCount] = fvg;
            bearishFVGCount++;
        }
    }
}

//+------------------------------------------------------------------+
//| Detect Order Blocks                                                |
//+------------------------------------------------------------------+
void DetectOrderBlocks() {
    bullishOBCount = 0;
    bearishOBCount = 0;

    // Scan last 100 candles on OrderBlockTF
    for (int i = 1; i < 100; i++) {
        double currentClose = iClose(Symbol(), OrderBlockTF, i);
        double currentOpen = iOpen(Symbol(), OrderBlockTF, i);
        double currentLow = iLow(Symbol(), OrderBlockTF, i);
        double currentHigh = iHigh(Symbol(), OrderBlockTF, i);
        double canleSize = MathAbs(currentClose - currentOpen);

        // Bullish OB: Down candle followed by strong move up
        if (currentClose < currentOpen && canleSize > MinOrderBlockSize * Point()) {
            // Check if followed by up move
            double nextHigh = iHigh(Symbol(), OrderBlockTF, i - 1);
            if (nextHigh > currentHigh) {
                OrderBlock ob;
                ob.high = currentHigh;
                ob.low = currentLow;
                ob.barCreated = i;
                ob.isBullish = true;
                ob.touchCount = 0;
                ob.strength = nextHigh - currentHigh;

                bullishOBs[bullishOBCount] = ob;
                bullishOBCount++;
            }
        }

        // Bearish OB: Up candle followed by strong move down
        if (currentClose > currentOpen && canleSize > MinOrderBlockSize * Point()) {
            // Check if followed by down move
            double nextLow = iLow(Symbol(), OrderBlockTF, i - 1);
            if (nextLow < currentLow) {
                OrderBlock ob;
                ob.high = currentHigh;
                ob.low = currentLow;
                ob.barCreated = i;
                ob.isBullish = false;
                ob.touchCount = 0;
                ob.strength = currentLow - nextLow;

                bearishOBs[bearishOBCount] = ob;
                bearishOBCount++;
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Check Entry Conditions                                             |
//+------------------------------------------------------------------+
void CheckEntrySetup() {
    // Check if we can open new trades
    if (dailyStats.tradesCount >= MaxDailyTrades) return;
    if (dailyStats.dailyLoss >= accountBalance * MaxDailyLossPercent / 100) return;
    if (!CheckSessionFilter()) return;
    if (CheckSpread()) return;

    // Get current price levels
    double currentBid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double currentAsk = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

    bool shouldTrade = false;
    int direction = 0; // 1 = Buy, -1 = Sell
    double entryPrice = 0;
    double stopLoss = 0;
    double takeProfit = 0;
    string reason = "";

    // Check based on entry method
    switch (EntryMethod) {
        case ENTRY_BOS_BREAK:
            if (CheckBOSBreak(direction, entryPrice, stopLoss, takeProfit)) {
                shouldTrade = true;
                reason = "BOS Break";
            }
            break;

        case ENTRY_BOS_RETEST:
            if (CheckBOSRetest(direction, entryPrice, stopLoss, takeProfit)) {
                shouldTrade = true;
                reason = "BOS Retest";
            }
            break;

        case ENTRY_CHOCH_BREAK:
            if (CheckCHoCHBreak(direction, entryPrice, stopLoss, takeProfit)) {
                shouldTrade = true;
                reason = "CHoCH Break";
            }
            break;

        case ENTRY_CHOCH_RETEST:
            if (CheckCHoCHRetest(direction, entryPrice, stopLoss, takeProfit)) {
                shouldTrade = true;
                reason = "CHoCH Retest";
            }
            break;

        case ENTRY_FVG_FILL:
            if (CheckFVGFill(direction, entryPrice, stopLoss, takeProfit)) {
                shouldTrade = true;
                reason = "FVG Fill";
            }
            break;

        case ENTRY_OB_TOUCH:
            if (CheckOBTouch(direction, entryPrice, stopLoss, takeProfit)) {
                shouldTrade = true;
                reason = "OB Touch";
            }
            break;

        case ENTRY_COMBINED:
            if (CheckCombined(direction, entryPrice, stopLoss, takeProfit)) {
                shouldTrade = true;
                reason = "Combined Setup";
            }
            break;
    }

    // Execute trade if valid
    if (shouldTrade) {
        // Validate R:R
        double riskPoints = MathAbs(entryPrice - stopLoss) / Point();
        double profitPoints = MathAbs(takeProfit - entryPrice) / Point();
        double ratio = profitPoints / riskPoints;

        if (ratio >= MinRiskReward) {
            OpenTrade(direction, entryPrice, stopLoss, takeProfit, reason);
        }
    }
}

//+------------------------------------------------------------------+
//| Check BOS Break Entry                                              |
//+------------------------------------------------------------------+
bool CheckBOSBreak(int &direction, double &entry, double &sl, double &tp) {
    if (TradeWithTrend && !htfBullish && !ltfBullish) return false;
    if (RequireHTFConfirmation && !htfBullish && !ltfBullish) return false;

    double current = Close[0];

    // Bullish BOS
    if (current > lastSwingHigh.price && htfBullish) {
        direction = 1;
        entry = current;
        sl = lastSwingLow.price - 20 * Point();
        tp = lastSwingHigh.price + (lastSwingHigh.price - lastSwingLow.price) * 1.5;
        return true;
    }

    // Bearish BOS
    if (current < lastSwingLow.price && !htfBullish) {
        direction = -1;
        entry = current;
        sl = lastSwingHigh.price + 20 * Point();
        tp = lastSwingLow.price - (lastSwingHigh.price - lastSwingLow.price) * 1.5;
        return true;
    }

    return false;
}

//+------------------------------------------------------------------+
//| Check BOS Retest Entry                                             |
//+------------------------------------------------------------------+
bool CheckBOSRetest(int &direction, double &entry, double &sl, double &tp) {
    if (TradeWithTrend && !htfBullish) return false;
    if (RequireHTFConfirmation && !htfBullish) return false;

    double current = Close[0];
    double tolerance = 10 * Point();

    // Bullish BOS Retest
    if (htfBullish && current > lastSwingHigh.price) {
        if (Close[1] < lastSwingHigh.price + tolerance && Close[0] > lastSwingHigh.price) {
            direction = 1;
            entry = current;
            sl = lastSwingLow.price - 10 * Point();
            tp = lastSwingHigh.price + (lastSwingHigh.price - lastSwingLow.price);
            return true;
        }
    }

    // Bearish BOS Retest
    if (!htfBullish && current < lastSwingLow.price) {
        if (Close[1] > lastSwingLow.price - tolerance && Close[0] < lastSwingLow.price) {
            direction = -1;
            entry = current;
            sl = lastSwingHigh.price + 10 * Point();
            tp = lastSwingLow.price - (lastSwingHigh.price - lastSwingLow.price);
            return true;
        }
    }

    return false;
}

//+------------------------------------------------------------------+
//| Check CHoCH Break Entry                                             |
//+------------------------------------------------------------------+
bool CheckCHoCHBreak(int &direction, double &entry, double &sl, double &tp) {
    // Placeholder for CHoCH break logic
    return false;
}

//+------------------------------------------------------------------+
//| Check CHoCH Retest Entry                                            |
//+------------------------------------------------------------------+
bool CheckCHoCHRetest(int &direction, double &entry, double &sl, double &tp) {
    // Placeholder for CHoCH retest logic
    return false;
}

//+------------------------------------------------------------------+
//| Check FVG Fill Entry                                               |
//+------------------------------------------------------------------+
bool CheckFVGFill(int &direction, double &entry, double &sl, double &tp) {
    if (!UseFVG) return false;

    double current = Close[0];

    // Check bullish FVGs
    if (htfBullish) {
        for (int i = 0; i < bullishFVGCount; i++) {
            double fillLevel = bullishFVGs[i].bottom +
                             (bullishFVGs[i].top - bullishFVGs[i].bottom) * FvgFillPercent / 100;

            if (current >= bullishFVGs[i].bottom && current <= bullishFVGs[i].top) {
                direction = 1;
                entry = current;
                sl = bullishFVGs[i].bottom - 10 * Point();
                tp = bullishFVGs[i].top + (bullishFVGs[i].top - bullishFVGs[i].bottom);
                return true;
            }
        }
    }

    // Check bearish FVGs
    if (!htfBullish) {
        for (int i = 0; i < bearishFVGCount; i++) {
            if (current >= bearishFVGs[i].bottom && current <= bearishFVGs[i].top) {
                direction = -1;
                entry = current;
                sl = bearishFVGs[i].top + 10 * Point();
                tp = bearishFVGs[i].bottom - (bearishFVGs[i].top - bearishFVGs[i].bottom);
                return true;
            }
        }
    }

    return false;
}

//+------------------------------------------------------------------+
//| Check OB Touch Entry                                               |
//+------------------------------------------------------------------+
bool CheckOBTouch(int &direction, double &entry, double &sl, double &tp) {
    if (!UseOrderBlocks) return false;

    double current = Close[0];

    // Check bullish OBs
    if (htfBullish && RequireStrongOB) {
        for (int i = 0; i < bullishOBCount; i++) {
            if (bullishOBs[i].touchCount <= MaxOBTouches) {
                double obZonePercent = OBTouchZone / 100.0;
                double obZone = (bullishOBs[i].high - bullishOBs[i].low) * obZonePercent;

                if (current >= bullishOBs[i].low && current <= bullishOBs[i].high + obZone) {
                    direction = 1;
                    entry = current;
                    sl = bullishOBs[i].low - 10 * Point();
                    tp = bullishOBs[i].high + (bullishOBs[i].high - bullishOBs[i].low) * 2;
                    bullishOBs[i].touchCount++;
                    return true;
                }
            }
        }
    }

    // Check bearish OBs
    if (!htfBullish && RequireStrongOB) {
        for (int i = 0; i < bearishOBCount; i++) {
            if (bearishOBs[i].touchCount <= MaxOBTouches) {
                double obZonePercent = OBTouchZone / 100.0;
                double obZone = (bearishOBs[i].high - bearishOBs[i].low) * obZonePercent;

                if (current <= bearishOBs[i].high && current >= bearishOBs[i].low - obZone) {
                    direction = -1;
                    entry = current;
                    sl = bearishOBs[i].high + 10 * Point();
                    tp = bearishOBs[i].low - (bearishOBs[i].high - bearishOBs[i].low) * 2;
                    bearishOBs[i].touchCount++;
                    return true;
                }
            }
        }
    }

    return false;
}

//+------------------------------------------------------------------+
//| Check Combined Entry (Best Quality)                                |
//+------------------------------------------------------------------+
bool CheckCombined(int &direction, double &entry, double &sl, double &tp) {
    // Requires multiple confirmations
    bool hasStructure = false;
    bool hasPattern = false;

    // Check structure
    if (RequireHTFConfirmation && htfBullish) {
        hasStructure = true;
    }

    // Check patterns
    if (UseFVG && bullishFVGCount > 0) hasPattern = true;
    if (UseOrderBlocks && bullishOBCount > 0) hasPattern = true;

    if (hasStructure && hasPattern) {
        // Execute conservative buy
        direction = 1;
        entry = Close[0];
        sl = lastSwingLow.price - 20 * Point();
        tp = lastSwingHigh.price + (lastSwingHigh.price - lastSwingLow.price) * 2;
        return true;
    }

    return false;
}

//+------------------------------------------------------------------+
//| Open Trade                                                         |
//+------------------------------------------------------------------+
void OpenTrade(int direction, double entry, double sl, double tp, string reason) {
    // Calculate lot size based on risk
    double riskAmount = accountBalance * RiskPercent / 100;
    double stopLossPoints = MathAbs(entry - sl) / Point();
    double lotSize = NormalizeDouble(riskAmount / (stopLossPoints * SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE)), 2);

    // Limit lot size
    if (lotSize < 0.01) lotSize = 0.01;
    if (lotSize > 1.0) lotSize = 1.0;

    if (direction == 1) {
        // Buy order
        if (trade.Buy(lotSize, _Symbol, entry, sl, tp, reason)) {
            Print("BUY Order Opened: ", reason);
            dailyStats.tradesCount++;
        }
    } else if (direction == -1) {
        // Sell order
        if (trade.Sell(lotSize, _Symbol, entry, sl, tp, reason)) {
            Print("SELL Order Opened: ", reason);
            dailyStats.tradesCount++;
        }
    }
}

//+------------------------------------------------------------------+
//| Manage Open Trades                                                 |
//+------------------------------------------------------------------+
void ManageTrades() {
    for (int i = PositionsTotal() - 1; i >= 0; i--) {
        if (!position.SelectByIndex(i)) continue;
        if (position.Symbol() != _Symbol) continue;

        double currentPrice = Close[0];
        double entryPrice = position.PriceOpen();
        double stopLoss = position.StopLoss();
        double takeProfit = position.TakeProfit();

        if (position.PositionType() == POSITION_TYPE_BUY) {
            // BUY trade management
            double pnlPoints = (currentPrice - entryPrice) / Point();
            double riskPoints = (entryPrice - stopLoss) / Point();
            double profitPoints = (takeProfit - entryPrice) / Point();
            double currentR = pnlPoints / riskPoints;

            // Breakeven protection
            if (UseBreakeven && currentR >= BreakevenTrigger) {
                if (stopLoss < entryPrice) {
                    trade.ModifyPosition(_Symbol, entryPrice, takeProfit);
                }
            }

            // Trailing stop
            if (UseTrailingStop && currentR >= TrailingTrigger) {
                double newSL = currentPrice - (TrailPoints * Point());
                if (newSL > stopLoss) {
                    trade.ModifyPosition(_Symbol, newSL, takeProfit);
                }
            }

            // Partial close
            if (UsePartialClose && currentR >= PartialCloseTrigger) {
                double closeQuantity = position.Volume() * (PartialClosePercent / 100);
                if (closeQuantity > 0) {
                    trade.Close(_Symbol, 100);
                }
            }
        } else if (position.PositionType() == POSITION_TYPE_SELL) {
            // SELL trade management
            double pnlPoints = (entryPrice - currentPrice) / Point();
            double riskPoints = (stopLoss - entryPrice) / Point();
            double profitPoints = (entryPrice - takeProfit) / Point();
            double currentR = pnlPoints / riskPoints;

            // Breakeven protection
            if (UseBreakeven && currentR >= BreakevenTrigger) {
                if (stopLoss > entryPrice) {
                    trade.ModifyPosition(_Symbol, entryPrice, takeProfit);
                }
            }

            // Trailing stop
            if (UseTrailingStop && currentR >= TrailingTrigger) {
                double newSL = currentPrice + (TrailPoints * Point());
                if (newSL < stopLoss) {
                    trade.ModifyPosition(_Symbol, newSL, takeProfit);
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Update Daily Statistics                                            |
//+------------------------------------------------------------------+
void UpdateDailyStats() {
    static datetime lastDay = 0;
    datetime currentDay = TimeCurrent();

    if (TimeDay(currentDay) != TimeDay(lastDay)) {
        dailyStats.tradesCount = 0;
        dailyStats.dailyPnL = 0;
        dailyStats.dailyLoss = 0;
        lastDay = currentDay;
    }

    // Update P&L
    dailyStats.dailyPnL = AccountInfoDouble(ACCOUNT_PROFIT);
    if (dailyStats.dailyPnL < 0) {
        dailyStats.dailyLoss = MathAbs(dailyStats.dailyPnL);
    }
}

//+------------------------------------------------------------------+
//| Check Session Filter                                               |
//+------------------------------------------------------------------+
bool CheckSessionFilter() {
    if (!OnlyTradeSession) return true;

    int hour = TimeHour(TimeCurrent());
    if (hour >= SessionStartHour && hour < SessionEndHour) {
        return true;
    }

    return false;
}

//+------------------------------------------------------------------+
//| Check Spread                                                       |
//+------------------------------------------------------------------+
bool CheckSpread() {
    double spread = (SymbolInfoDouble(_Symbol, SYMBOL_ASK) -
                    SymbolInfoDouble(_Symbol, SYMBOL_BID)) / Point();

    if (spread > MaxSpreadPoints) {
        return true; // Too wide, skip trade
    }

    return false;
}

//+------------------------------------------------------------------+
//| Draw Structure Lines                                               |
//+------------------------------------------------------------------+
void DrawStructure() {
    // Draw HTF swing high
    if (lastSwingHigh.price > 0) {
        DrawLine("HTF_HH", lastSwingHigh.price, clrBlue, STYLE_SOLID, 2);
    }

    // Draw HTF swing low
    if (lastSwingLow.price > 0) {
        DrawLine("HTF_LL", lastSwingLow.price, clrRed, STYLE_SOLID, 2);
    }
}

//+------------------------------------------------------------------+
//| Draw FVG Zones                                                     |
//+------------------------------------------------------------------+
void DrawFVG() {
    // Draw bullish FVGs
    for (int i = 0; i < bullishFVGCount; i++) {
        DrawRectangle("BULLISH_FVG_" + IntegerToString(i),
                     bullishFVGs[i].top,
                     bullishFVGs[i].bottom,
                     C'0,255,0', 20);
    }

    // Draw bearish FVGs
    for (int i = 0; i < bearishFVGCount; i++) {
        DrawRectangle("BEARISH_FVG_" + IntegerToString(i),
                     bearishFVGs[i].top,
                     bearishFVGs[i].bottom,
                     C'255,0,0', 20);
    }
}

//+------------------------------------------------------------------+
//| Draw Order Blocks                                                  |
//+------------------------------------------------------------------+
void DrawOrderBlocks() {
    // Draw bullish OBs
    for (int i = 0; i < bullishOBCount; i++) {
        DrawRectangle("BULLISH_OB_" + IntegerToString(i),
                     bullishOBs[i].high,
                     bullishOBs[i].low,
                     C'0,200,0', 50);
    }

    // Draw bearish OBs
    for (int i = 0; i < bearishOBCount; i++) {
        DrawRectangle("BEARISH_OB_" + IntegerToString(i),
                     bearishOBs[i].high,
                     bearishOBs[i].low,
                     C'200,0,0', 50);
    }
}

//+------------------------------------------------------------------+
//| Draw Info Panel                                                    |
//+------------------------------------------------------------------+
void DrawInfoPanel() {
    string panelText = "SMART MONEY PRO EA v2.0\n";
    panelText += "HTF: " + (htfBullish ? "BULLISH" : "BEARISH") + "\n";
    panelText += "LTF: " + (ltfBullish ? "BULLISH" : "BEARISH") + "\n";
    panelText += "Daily Trades: " + IntegerToString(dailyStats.tradesCount) + "/" + IntegerToString(MaxDailyTrades) + "\n";
    panelText += "Daily P&L: " + DoubleToString(dailyStats.dailyPnL, 2) + "\n";
    panelText += "BullishFVGs: " + IntegerToString(bullishFVGCount) + " | BearishFVGs: " + IntegerToString(bearishFVGCount) + "\n";
    panelText += "BullishOBs: " + IntegerToString(bullishOBCount) + " | BearishOBs: " + IntegerToString(bearishOBCount);

    CreateLabel("INFO_PANEL", 10, 10, panelText, clrWhite);
}

//+------------------------------------------------------------------+
//| Helper: Draw Line                                                  |
//+------------------------------------------------------------------+
void DrawLine(string name, double price, color clr, int style, int width) {
    ObjectDelete(0, name);
    ObjectCreate(0, name, OBJ_HLINE, 0, 0, price);
    ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
    ObjectSetInteger(0, name, OBJPROP_STYLE, style);
    ObjectSetInteger(0, name, OBJPROP_WIDTH, width);
}

//+------------------------------------------------------------------+
//| Helper: Draw Rectangle                                             |
//+------------------------------------------------------------------+
void DrawRectangle(string name, double top, double bottom, color clr, int alpha) {
    ObjectDelete(0, name);
    // Note: Rectangle drawing would require more complex implementation
    // Simplified here for demonstration
}

//+------------------------------------------------------------------+
//| Helper: Create Label                                               |
//+------------------------------------------------------------------+
void CreateLabel(string name, int x, int y, string text, color clr) {
    ObjectDelete(0, name);
    ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
    ObjectSetString(0, name, OBJPROP_TEXT, text);
    ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
    ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
    ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
    ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 9);
}

//+------------------------------------------------------------------+
//| Helper: Delete All Objects                                         |
//+------------------------------------------------------------------+
void DeleteAllObjects() {
    ObjectsDeleteAll(0);
}

//+------------------------------------------------------------------+
//| Helper: Check if value is blank                                    |
//+------------------------------------------------------------------+
bool iBlankValue(double value) {
    return (value == 0);
}

//+------------------------------------------------------------------+
//| OnStart Function (for testing)                                     |
//+------------------------------------------------------------------+
void OnStart() {
    Print("SmartMoney Pro EA v2.0 - Ready to trade");
}
