//+------------------------------------------------------------------+
//| SMC Ultimate EA - Trading Engine Module                          |
//+------------------------------------------------------------------+

#ifndef _TRADING_ENGINE_MQH_
#define _TRADING_ENGINE_MQH_

#include "..\Utilities\Config.mqh"
#include "..\Utilities\Utils.mqh"
#include "..\Indicators\BoS.mqh"
#include "..\Indicators\ChoCH.mqh"
#include "..\Indicators\FVG.mqh"
#include "..\Indicators\OB.mqh"
#include "StateManager.mqh"
#include "RiskManager.mqh"

//+------------------------------------------------------------------+
//| Trading Signal Structure                                          |
//+------------------------------------------------------------------+
struct TradeSignal
{
    SIGNAL_TYPE signalType;
    DIRECTION direction;
    double entryPrice;
    double stopLoss;
    double takeProfit;
    double confidence;
    int bar;
    datetime time;
};

//+------------------------------------------------------------------+
//| Trading Engine Class                                              |
//+------------------------------------------------------------------+
class TradingEngine
{
private:
    BoSDetector* m_bosDetector;
    ChoCHDetector* m_chochDetector;
    FVGDetector* m_fvgDetector;
    OBDetector* m_obDetector;
    StateManager* m_stateManager;
    RiskManager* m_riskManager;

    TradeSignal m_lastSignal;
    TradeSignal m_currentSignal;
    int m_signalConfirmationBars;
    bool m_positionOpen;

public:
    TradingEngine()
        : m_signalConfirmationBars(0), m_positionOpen(false)
    {
        m_bosDetector = new BoSDetector();
        m_chochDetector = new ChoCHDetector();
        m_fvgDetector = new FVGDetector();
        m_obDetector = new OBDetector();
        m_stateManager = new StateManager();
        m_riskManager = new RiskManager();

        m_lastSignal.signalType = SIGNAL_NONE;
        m_lastSignal.confidence = 0;
        m_currentSignal.signalType = SIGNAL_NONE;
        m_currentSignal.confidence = 0;
    }

    //+------------------------------------------------------------------+
    //| Destructor                                                        |
    //+------------------------------------------------------------------+
    ~TradingEngine()
    {
        if (m_bosDetector != NULL) delete m_bosDetector;
        if (m_chochDetector != NULL) delete m_chochDetector;
        if (m_fvgDetector != NULL) delete m_fvgDetector;
        if (m_obDetector != NULL) delete m_obDetector;
        if (m_stateManager != NULL) delete m_stateManager;
        if (m_riskManager != NULL) delete m_riskManager;
    }

    //+------------------------------------------------------------------+
    //| Initialize Trading Engine                                         |
    //+------------------------------------------------------------------+
    void Initialize()
    {
        Logger::Info("Initializing Trading Engine...");

        m_stateManager.Initialize();
        m_riskManager.Initialize();

        m_signalConfirmationBars = 0;
        m_positionOpen = false;

        Logger::Info("Trading Engine initialized successfully");
    }

    //+------------------------------------------------------------------+
    //| Analyze market and generate signals                               |
    //+------------------------------------------------------------------+
    TradeSignal AnalyzeMarket(const double& high[], const double& low[],
                             const double& close[], int bar = 1)
    {
        TradeSignal signal;
        signal.signalType = SIGNAL_NONE;
        signal.direction = DIR_NEUTRAL;
        signal.confidence = 0;
        signal.bar = bar;
        signal.time = TimeCurrent();

        if (bar < 3)
            return signal;

        // Detect each SMC component
        DIRECTION bosDir = m_bosDetector.DetectBoS(high, low, close, bar);
        DIRECTION chochDir = m_chochDetector.DetectChoCH(high, low, close, bar);
        DIRECTION fvgDir = m_fvgDetector.DetectFVG(high, low, close, bar);
        DIRECTION obDir = m_obDetector.DetectOB(high, low, close, bar);

        // Count confluence signals
        int confluenceCount = 0;
        if (bosDir != DIR_NEUTRAL) confluenceCount++;
        if (chochDir != DIR_NEUTRAL) confluenceCount++;
        if (fvgDir != DIR_NEUTRAL) confluenceCount++;
        if (obDir != DIR_NEUTRAL) confluenceCount++;

        // Determine signal based on confluence
        if (confluenceCount >= 3)
        {
            // Multiple signals aligned = strong signal
            signal.signalType = SIGNAL_CONFLUENCE;
            signal.confidence = 0.9;

            // Determine direction (must be same for all signals)
            if (bosDir != DIR_NEUTRAL) signal.direction = bosDir;
            if (chochDir != DIR_NEUTRAL && chochDir == signal.direction) signal.confidence += 0.05;
            if (fvgDir != DIR_NEUTRAL && fvgDir == signal.direction) signal.confidence += 0.05;
            if (obDir != DIR_NEUTRAL && obDir == signal.direction) signal.confidence += 0.05;

            signal.confidence = MathMin(signal.confidence, 1.0);
        }
        else if (confluenceCount == 2)
        {
            // Two signals aligned
            signal.confidence = 0.7;

            if (bosDir != DIR_NEUTRAL) signal.direction = bosDir;
            if (chochDir != DIR_NEUTRAL && chochDir == signal.direction)
                signal.signalType = SIGNAL_CHOCH_REVERSAL;
            if (fvgDir != DIR_NEUTRAL && fvgDir == signal.direction)
                signal.signalType = SIGNAL_FVG_PULLBACK;
            if (obDir != DIR_NEUTRAL && obDir == signal.direction)
                signal.signalType = SIGNAL_OB_REACTION;

            if (signal.signalType == SIGNAL_NONE)
                signal.signalType = SIGNAL_BOS_BREAKOUT;
        }
        else if (bosDir != DIR_NEUTRAL)
        {
            // Primary signal: Break of Structure
            signal.signalType = SIGNAL_BOS_BREAKOUT;
            signal.direction = bosDir;
            signal.confidence = 0.6;

            // Add confidence from other confirmations
            if (chochDir == signal.direction) signal.confidence += 0.1;
            if (fvgDir == signal.direction) signal.confidence += 0.1;
            if (obDir == signal.direction) signal.confidence += 0.1;

            signal.confidence = MathMin(signal.confidence, 1.0);
        }
        else if (chochDir != DIR_NEUTRAL)
        {
            signal.signalType = SIGNAL_CHOCH_REVERSAL;
            signal.direction = chochDir;
            signal.confidence = 0.6;

            if (fvgDir == signal.direction) signal.confidence += 0.1;
            if (obDir == signal.direction) signal.confidence += 0.1;

            signal.confidence = MathMin(signal.confidence, 1.0);
        }
        else if (fvgDir != DIR_NEUTRAL)
        {
            signal.signalType = SIGNAL_FVG_PULLBACK;
            signal.direction = fvgDir;
            signal.confidence = 0.6;

            if (obDir == signal.direction) signal.confidence += 0.1;

            signal.confidence = MathMin(signal.confidence, 1.0);
        }
        else if (obDir != DIR_NEUTRAL)
        {
            signal.signalType = SIGNAL_OB_REACTION;
            signal.direction = obDir;
            signal.confidence = 0.5;
        }

        m_currentSignal = signal;
        return signal;
    }

    //+------------------------------------------------------------------+
    //| Check if signal is confirmed                                      |
    //+------------------------------------------------------------------+
    bool ConfirmSignal(const TradeSignal& signal)
    {
        if (signal.signalType == SIGNAL_NONE)
        {
            m_signalConfirmationBars = 0;
            return false;
        }

        if (signal.direction == DIR_NEUTRAL)
        {
            m_signalConfirmationBars = 0;
            return false;
        }

        if (signal.signalType != m_lastSignal.signalType ||
            signal.direction != m_lastSignal.direction)
        {
            m_signalConfirmationBars = 1;
        }
        else
        {
            m_signalConfirmationBars++;
        }

        m_lastSignal = signal;

        // Signal confirmed if confidence > threshold and enough bars
        if (signal.confidence >= CONFIRMATION_THRESHOLD &&
            m_signalConfirmationBars >= SIGNAL_BARS)
        {
            return true;
        }

        return false;
    }

    //+------------------------------------------------------------------+
    //| Calculate entry prices                                            |
    //+------------------------------------------------------------------+
    void CalculateEntryLevels(const TradeSignal& signal, double& entryPrice,
                             double& stopLoss, double& takeProfit)
    {
        double bidPrice = SymbolInfoDouble(Symbol(), SYMBOL_BID);
        double askPrice = SymbolInfoDouble(Symbol(), SYMBOL_ASK);

        if (signal.direction == DIR_BUY)
        {
            entryPrice = PriceUtils::NormalizePrice(askPrice);
            stopLoss = m_riskManager.CalculateStopLossLevel(entryPrice, DIR_BUY);
            takeProfit = m_riskManager.CalculateTakeProfitLevel(entryPrice, DIR_BUY);
        }
        else if (signal.direction == DIR_SELL)
        {
            entryPrice = PriceUtils::NormalizePrice(bidPrice);
            stopLoss = m_riskManager.CalculateStopLossLevel(entryPrice, DIR_SELL);
            takeProfit = m_riskManager.CalculateTakeProfitLevel(entryPrice, DIR_SELL);
        }
    }

    //+------------------------------------------------------------------+
    //| Execute trade based on signal                                     |
    //+------------------------------------------------------------------+
    bool ExecuteTrade(const TradeSignal& signal)
    {
        if (!m_riskManager.CanTrade())
        {
            Logger::Warning("Risk check failed. Cannot execute trade.");
            return false;
        }

        double entryPrice, stopLoss, takeProfit;
        CalculateEntryLevels(signal, entryPrice, stopLoss, takeProfit);

        double lotSize = m_riskManager.CalculateLotSize();

        MqlTradeRequest request;
        MqlTradeResult result;

        ZeroMemory(request);
        request.action = TRADE_ACTION_DEAL;
        request.symbol = Symbol();
        request.volume = lotSize;
        request.price = entryPrice;
        request.sl = stopLoss;
        request.tp = takeProfit;
        request.comment = "SMC EA - " + GetSignalName(signal.signalType);

        if (signal.direction == DIR_BUY)
        {
            request.type = ORDER_TYPE_BUY;
        }
        else if (signal.direction == DIR_SELL)
        {
            request.type = ORDER_TYPE_SELL;
        }

        if (!OrderSend(request, result))
        {
            Logger::Error("Failed to execute trade. Error: " +
                        IntegerToString(result.retcode));
            return false;
        }

        Logger::Info("Trade executed: " + GetSignalName(signal.signalType) +
                    " | Entry: " + DoubleToString(entryPrice, 5) +
                    " | SL: " + DoubleToString(stopLoss, 5) +
                    " | TP: " + DoubleToString(takeProfit, 5) +
                    " | Lots: " + DoubleToString(lotSize, 2));

        m_positionOpen = true;
        return true;
    }

    //+------------------------------------------------------------------+
    //| Get signal name                                                   |
    //+------------------------------------------------------------------+
    string GetSignalName(SIGNAL_TYPE signalType) const
    {
        switch (signalType)
        {
            case SIGNAL_NONE:           return "NONE";
            case SIGNAL_BOS_BREAKOUT:   return "BoS Breakout";
            case SIGNAL_CHOCH_REVERSAL: return "CHoCH Reversal";
            case SIGNAL_FVG_PULLBACK:   return "FVG Pullback";
            case SIGNAL_OB_REACTION:    return "OB Reaction";
            case SIGNAL_CONFLUENCE:     return "Confluence";
            default:                    return "UNKNOWN";
        }
    }

    //+------------------------------------------------------------------+
    //| Get State Manager                                                 |
    //+------------------------------------------------------------------+
    StateManager* GetStateManager() { return m_stateManager; }

    //+------------------------------------------------------------------+
    //| Get Risk Manager                                                  |
    //+------------------------------------------------------------------+
    RiskManager* GetRiskManager() { return m_riskManager; }

    //+------------------------------------------------------------------+
    //| Get last signal                                                   |
    //+------------------------------------------------------------------+
    TradeSignal GetLastSignal() const { return m_lastSignal; }

    //+------------------------------------------------------------------+
    //| Get current signal                                                |
    //+------------------------------------------------------------------+
    TradeSignal GetCurrentSignal() const { return m_currentSignal; }

    //+------------------------------------------------------------------+
    //| Get signal confirmation bars                                      |
    //+------------------------------------------------------------------+
    int GetSignalConfirmationBars() const { return m_signalConfirmationBars; }
};

#endif
