//+------------------------------------------------------------------+
//| SMC Ultimate EA - Main Expert Advisor                            |
//| Smart Money Concepts Trading System                              |
//| Uses: BoS, CHoCH, FVG, OB signals with state machine             |
//+------------------------------------------------------------------+

#property copyright "SMC Ultimate EA"
#property link "https://github.com/innosenze88/SMCUltimateEA"
#property version "1.0"
#property strict

//+------------------------------------------------------------------+
//| Include all modules                                              |
//+------------------------------------------------------------------+
#include "..\Include\Utilities\Config.mqh"
#include "..\Include\Utilities\Utils.mqh"
#include "..\Include\Core\StateManager.mqh"
#include "..\Include\Core\RiskManager.mqh"
#include "..\Include\Core\TradingEngine.mqh"

//+------------------------------------------------------------------+
//| Global variables                                                 |
//+------------------------------------------------------------------+
TradingEngine* g_tradingEngine = NULL;
StateManager* g_stateManager = NULL;
RiskManager* g_riskManager = NULL;

int g_lastBar = -1;
datetime g_lastBarTime = 0;
int g_newDayCounter = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    Logger::Info("====================================");
    Logger::Info("SMC Ultimate EA - Version 1.0");
    Logger::Info("====================================");

    // Check chart symbol and timeframe
    if (Symbol() != SYMBOL)
    {
        Logger::Warning("Current symbol: " + Symbol() + " != Configured symbol: " + SYMBOL);
        Logger::Warning("Switching to configured symbol...");
    }

    if (Period() != TIMEFRAME)
    {
        Logger::Warning("Current timeframe mismatch!");
        Logger::Warning("Please switch to " + PeriodToString(TIMEFRAME));
    }

    // Initialize trading engine
    g_tradingEngine = new TradingEngine();
    if (g_tradingEngine == NULL)
    {
        Logger::Error("Failed to create Trading Engine");
        return INIT_FAILED;
    }

    g_tradingEngine.Initialize();

    // Get state and risk managers from trading engine
    g_stateManager = g_tradingEngine.GetStateManager();
    g_riskManager = g_tradingEngine.GetRiskManager();

    Logger::Info("EA initialized successfully on " + Symbol() + " " + PeriodToString(Period()));
    Logger::Info("Ready to trade...");

    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    Logger::Info("EA deinitialized. Reason: " + IntegerToString(reason));

    if (g_tradingEngine != NULL)
    {
        delete g_tradingEngine;
        g_tradingEngine = NULL;
    }

    Logger::Info("Cleanup completed");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // Check if new bar formed
    if (!IsNewBar())
        return;

    Logger::Debug("=== OnTick: New bar formed ===");

    // Check if new day - reset daily counters
    if (TimeUtils::IsNewDay(g_lastBarTime))
    {
        g_newDayCounter++;
        Logger::Info("New day detected. Daily counter: " + IntegerToString(g_newDayCounter));
    }

    g_lastBarTime = TimeCurrent();

    // Get price data
    double high[2];
    double low[2];
    double close[2];

    if (!CopyHigh(Symbol(), Period(), 0, 2, high) ||
        !CopyLow(Symbol(), Period(), 0, 2, low) ||
        !CopyClose(Symbol(), Period(), 0, 2, close))
    {
        Logger::Error("Failed to copy price data");
        return;
    }

    // Reverse arrays for easier indexing (0 = current, 1 = previous)
    ArraySetAsSeries(high, true);
    ArraySetAsSeries(low, true);
    ArraySetAsSeries(close, true);

    // Process state machine
    ProcessStateMachine(high, low, close);
}

//+------------------------------------------------------------------+
//| Process State Machine                                             |
//+------------------------------------------------------------------+
void ProcessStateMachine(const double& high[], const double& low[],
                        const double& close[])
{
    STATE currentState = g_stateManager.GetCurrentState();

    // Always check for risk conditions first
    if (g_riskManager.CanTrade() == false)
    {
        if (currentState != RISK_CHECK)
        {
            g_stateManager.TransitionTo(RISK_CHECK);
            Logger::Warning("Risk check triggered. Stopping trades.");
        }
        return;
    }

    // Reset to IDLE if in RISK_CHECK and conditions are ok
    if (currentState == RISK_CHECK && g_riskManager.CanTrade())
    {
        g_stateManager.TransitionTo(IDLE);
    }

    // State machine transitions
    switch (currentState)
    {
        case IDLE:
            HandleIDLE(high, low, close);
            break;

        case SCANNING_MARKET:
            HandleSCANNING_MARKET(high, low, close);
            break;

        case STRUCTURE_ANALYSIS:
            HandleSTRUCTURE_ANALYSIS(high, low, close);
            break;

        case CONFIRMATION_PENDING:
            HandleCONFIRMATION_PENDING(high, low, close);
            break;

        case ENTRY_SETUP:
            HandleENTRY_SETUP(high, low, close);
            break;

        case POSITION_MANAGEMENT:
            HandlePOSITION_MANAGEMENT(high, low, close);
            break;

        case EXIT_ANALYSIS:
            HandleEXIT_ANALYSIS(high, low, close);
            break;

        case RISK_CHECK:
            HandleRISK_CHECK();
            break;

        default:
            g_stateManager.TransitionTo(IDLE);
            break;
    }

    // Display status
    DisplayStatus(high, low, close);
}

//+------------------------------------------------------------------+
//| IDLE State Handler                                                |
//+------------------------------------------------------------------+
void HandleIDLE(const double& high[], const double& low[], const double& close[])
{
    // Check if conditions are met to start scanning
    if (g_stateManager.ShouldStartScanning())
    {
        g_stateManager.TransitionTo(SCANNING_MARKET);
        Logger::Info("Transitioning to SCANNING_MARKET");
    }
}

//+------------------------------------------------------------------+
//| SCANNING_MARKET State Handler                                     |
//+------------------------------------------------------------------+
void HandleSCANNING_MARKET(const double& high[], const double& low[],
                          const double& close[])
{
    if (g_stateManager.ShouldAnalyzeStructure())
    {
        g_stateManager.TransitionTo(STRUCTURE_ANALYSIS);
        Logger::Info("Transitioning to STRUCTURE_ANALYSIS");
    }
}

//+------------------------------------------------------------------+
//| STRUCTURE_ANALYSIS State Handler                                  |
//+------------------------------------------------------------------+
void HandleSTRUCTURE_ANALYSIS(const double& high[], const double& low[],
                             const double& close[])
{
    // Analyze market structure using all SMC components
    TradeSignal signal = g_tradingEngine.AnalyzeMarket(high, low, close, 1);

    if (g_stateManager.ShouldWaitForConfirmation(signal.signalType))
    {
        g_stateManager.TransitionTo(CONFIRMATION_PENDING);
        Logger::Info("Signal detected: " + g_tradingEngine.GetSignalName(signal.signalType) +
                    " | Confidence: " + DoubleToString(signal.confidence, 2) +
                    " | Direction: " + (signal.direction == DIR_BUY ? "BUY" : "SELL"));
    }
}

//+------------------------------------------------------------------+
//| CONFIRMATION_PENDING State Handler                                |
//+------------------------------------------------------------------+
void HandleCONFIRMATION_PENDING(const double& high[], const double& low[],
                               const double& close[])
{
    TradeSignal signal = g_tradingEngine.AnalyzeMarket(high, low, close, 1);

    if (g_tradingEngine.ConfirmSignal(signal))
    {
        g_stateManager.TransitionTo(ENTRY_SETUP);
        Logger::Info("Signal CONFIRMED after " +
                    IntegerToString(g_tradingEngine.GetSignalConfirmationBars()) + " bars");
    }
}

//+------------------------------------------------------------------+
//| ENTRY_SETUP State Handler                                         |
//+------------------------------------------------------------------+
void HandleENTRY_SETUP(const double& high[], const double& low[],
                      const double& close[])
{
    TradeSignal signal = g_tradingEngine.GetCurrentSignal();

    if (signal.signalType != SIGNAL_NONE)
    {
        // Execute trade
        if (g_tradingEngine.ExecuteTrade(signal))
        {
            g_stateManager.TransitionTo(POSITION_MANAGEMENT);
            Logger::Info("Trade executed successfully");
        }
        else
        {
            g_stateManager.TransitionTo(IDLE);
            Logger::Warning("Trade execution failed, returning to IDLE");
        }
    }
}

//+------------------------------------------------------------------+
//| POSITION_MANAGEMENT State Handler                                 |
//+------------------------------------------------------------------+
void HandlePOSITION_MANAGEMENT(const double& high[], const double& low[],
                              const double& close[])
{
    if (g_stateManager.ShouldAnalyzeExit())
    {
        g_stateManager.TransitionTo(EXIT_ANALYSIS);
    }
}

//+------------------------------------------------------------------+
//| EXIT_ANALYSIS State Handler                                       |
//+------------------------------------------------------------------+
void HandleEXIT_ANALYSIS(const double& high[], const double& low[],
                        const double& close[])
{
    // Check if position is still open
    if (g_stateManager.ShouldReturnToIdle())
    {
        g_stateManager.TransitionTo(IDLE);
        Logger::Info("Position closed. Returning to IDLE");
    }
    else
    {
        // Position still open, go back to position management
        g_stateManager.TransitionTo(POSITION_MANAGEMENT);
    }
}

//+------------------------------------------------------------------+
//| RISK_CHECK State Handler                                          |
//+------------------------------------------------------------------+
void HandleRISK_CHECK()
{
    Logger::Warning("Risk check in progress. Waiting for conditions to improve...");

    // Can transition back when risk is ok
    if (g_riskManager.CanTrade())
    {
        g_stateManager.TransitionTo(IDLE);
    }
}

//+------------------------------------------------------------------+
//| Check if new bar formed                                           |
//+------------------------------------------------------------------+
bool IsNewBar()
{
    static int lastBar = -1;

    int currentBar = Bars(Symbol(), Period());
    if (currentBar == lastBar)
        return false;

    lastBar = currentBar;
    return true;
}

//+------------------------------------------------------------------+
//| Display status information                                        |
//+------------------------------------------------------------------+
void DisplayStatus(const double& high[], const double& low[], const double& close[])
{
    string status = "\n";
    status += "========== SMC ULTIMATE EA STATUS ==========\n";
    status += "Symbol: " + Symbol() + " | Timeframe: " + PeriodToString(Period()) + "\n";
    status += g_stateManager.GetStatusString() + "\n";
    status += g_riskManager.GetStatusString() + "\n";

    TradeSignal signal = g_tradingEngine.GetCurrentSignal();
    status += "Signal: " + g_tradingEngine.GetSignalName(signal.signalType);
    status += " | Confidence: " + DoubleToString(signal.confidence, 2) + "\n";

    status += "Confirmation Bars: " + IntegerToString(g_tradingEngine.GetSignalConfirmationBars()) + "\n";
    status += "Open Positions: " + IntegerToString(PositionUtils::GetOpenPositions()) + "\n";
    status += "===========================================\n";

    Comment(status);
}

//+------------------------------------------------------------------+
//| Convert period to string                                          |
//+------------------------------------------------------------------+
string PeriodToString(ENUM_TIMEFRAMES period)
{
    switch (period)
    {
        case PERIOD_M1:  return "M1";
        case PERIOD_M5:  return "M5";
        case PERIOD_M15: return "M15";
        case PERIOD_M30: return "M30";
        case PERIOD_H1:  return "H1";
        case PERIOD_H4:  return "H4";
        case PERIOD_D1:  return "D1";
        case PERIOD_W1:  return "W1";
        case PERIOD_MN1: return "MN1";
        default:         return "UNKNOWN";
    }
}

//+------------------------------------------------------------------+
//| End of SMCUltimateEA.mq5                                          |
//+------------------------------------------------------------------+
