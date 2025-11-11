//+------------------------------------------------------------------+
//| SMC Ultimate EA - Risk Manager Module                            |
//+------------------------------------------------------------------+

#ifndef _RISK_MANAGER_MQH_
#define _RISK_MANAGER_MQH_

#include "..\Utilities\Config.mqh"
#include "..\Utilities\Utils.mqh"

//+------------------------------------------------------------------+
//| Risk Parameters Structure                                         |
//+------------------------------------------------------------------+
struct RiskParams
{
    double lotSize;
    double stopLossPips;
    double takeProfitPips;
    double riskRewardRatio;
    double maxLossPercent;
};

//+------------------------------------------------------------------+
//| Risk Manager Class                                                |
//+------------------------------------------------------------------+
class RiskManager
{
private:
    RiskParams m_riskParams;
    double m_initialBalance;
    double m_dailyMaxLoss;
    double m_dailyLossToday;
    int m_ordersToday;

public:
    RiskManager()
        : m_initialBalance(AccountInfoDouble(ACCOUNT_BALANCE)),
          m_dailyMaxLoss(0), m_dailyLossToday(0), m_ordersToday(0)
    {
        m_riskParams.lotSize = LOT_SIZE;
        m_riskParams.stopLossPips = STOP_LOSS_PIPS;
        m_riskParams.takeProfitPips = TAKE_PROFIT_PIPS;
        m_riskParams.riskRewardRatio = TAKE_PROFIT_PIPS / STOP_LOSS_PIPS;
        m_riskParams.maxLossPercent = RISK_PERCENT;
    }

    //+------------------------------------------------------------------+
    //| Initialize Risk Manager                                           |
    //+------------------------------------------------------------------+
    void Initialize()
    {
        m_initialBalance = AccountInfoDouble(ACCOUNT_BALANCE);
        m_dailyMaxLoss = m_initialBalance * (RISK_PERCENT / 100.0);
        m_dailyLossToday = 0;
        m_ordersToday = PositionUtils::GetTradesToday();

        Logger::Info("Risk Manager initialized. Max daily loss: " +
                    DoubleToString(m_dailyMaxLoss, 2));
    }

    //+------------------------------------------------------------------+
    //| Check if trading is allowed (risk check)                          |
    //+------------------------------------------------------------------+
    bool CanTrade()
    {
        // Check daily loss limit
        if (GetDailyLossPercent() >= RISK_PERCENT)
        {
            Logger::Warning("Daily loss limit reached: " +
                           DoubleToString(GetDailyLossPercent(), 2) + "%");
            return false;
        }

        // Check max orders per day
        if (m_ordersToday >= MAX_ORDERS_PER_DAY)
        {
            Logger::Warning("Max orders per day reached: " +
                           IntegerToString(m_ordersToday));
            return false;
        }

        // Check account equity
        double equity = AccountInfoDouble(ACCOUNT_EQUITY);
        double balance = AccountInfoDouble(ACCOUNT_BALANCE);

        if (equity < balance * 0.5)  // Equity below 50% of balance
        {
            Logger::Warning("Equity too low: " + DoubleToString(equity, 2));
            return false;
        }

        return true;
    }

    //+------------------------------------------------------------------+
    //| Calculate lot size based on risk parameters                       |
    //+------------------------------------------------------------------+
    double CalculateLotSize(double stopLossPips = 0)
    {
        if (stopLossPips == 0)
            stopLossPips = STOP_LOSS_PIPS;

        double riskAmount = AccountInfoDouble(ACCOUNT_BALANCE) * (RISK_PERCENT / 100.0);
        double priceIncrease = PriceUtils::PipsToPrice(stopLossPips);

        if (priceIncrease <= 0)
            return LOT_SIZE;

        double lotSize = riskAmount / (priceIncrease * 100000);

        // Validate lot size
        double minLot = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);
        double maxLot = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX);
        double step = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_STEP);

        if (lotSize < minLot)
            lotSize = minLot;
        if (lotSize > maxLot)
            lotSize = maxLot;

        lotSize = MathRound(lotSize / step) * step;

        return NormalizeDouble(lotSize, 2);
    }

    //+------------------------------------------------------------------+
    //| Calculate Take Profit level                                       |
    //+------------------------------------------------------------------+
    double CalculateTakeProfitLevel(double entryPrice, DIRECTION direction)
    {
        double tpPrice = PriceUtils::PipsToPrice(TAKE_PROFIT_PIPS);

        if (direction == DIR_BUY)
            return PriceUtils::NormalizePrice(entryPrice + tpPrice);
        else if (direction == DIR_SELL)
            return PriceUtils::NormalizePrice(entryPrice - tpPrice);

        return 0;
    }

    //+------------------------------------------------------------------+
    //| Calculate Stop Loss level                                         |
    //+------------------------------------------------------------------+
    double CalculateStopLossLevel(double entryPrice, DIRECTION direction)
    {
        double slPrice = PriceUtils::PipsToPrice(STOP_LOSS_PIPS);

        if (direction == DIR_BUY)
            return PriceUtils::NormalizePrice(entryPrice - slPrice);
        else if (direction == DIR_SELL)
            return PriceUtils::NormalizePrice(entryPrice + slPrice);

        return 0;
    }

    //+------------------------------------------------------------------+
    //| Check if position has reached TP                                  |
    //+------------------------------------------------------------------+
    bool HasReachedTakeProfit(double currentPrice, double tpLevel, DIRECTION direction)
    {
        if (direction == DIR_BUY)
            return currentPrice >= tpLevel;
        else
            return currentPrice <= tpLevel;

        return false;
    }

    //+------------------------------------------------------------------+
    //| Check if position has reached SL                                  |
    //+------------------------------------------------------------------+
    bool HasReachedStopLoss(double currentPrice, double slLevel, DIRECTION direction)
    {
        if (direction == DIR_BUY)
            return currentPrice <= slLevel;
        else
            return currentPrice >= slLevel;

        return false;
    }

    //+------------------------------------------------------------------+
    //| Update daily loss                                                 |
    //+------------------------------------------------------------------+
    void UpdateDailyLoss()
    {
        double currentBalance = AccountInfoDouble(ACCOUNT_BALANCE);
        m_dailyLossToday = m_initialBalance - currentBalance;

        if (m_dailyLossToday < 0)
            m_dailyLossToday = 0;
    }

    //+------------------------------------------------------------------+
    //| Get daily loss percentage                                         |
    //+------------------------------------------------------------------+
    double GetDailyLossPercent()
    {
        UpdateDailyLoss();
        if (m_initialBalance == 0)
            return 0;

        return (m_dailyLossToday / m_initialBalance) * 100.0;
    }

    //+------------------------------------------------------------------+
    //| Get remaining daily loss allowance                                |
    //+------------------------------------------------------------------+
    double GetRemainingDailyLoss()
    {
        return m_dailyMaxLoss - m_dailyLossToday;
    }

    //+------------------------------------------------------------------+
    //| Check if trailing stop should be applied                          |
    //+------------------------------------------------------------------+
    bool ShouldApplyTrailingStop(double currentPrice, double entryPrice,
                                double profitPips, DIRECTION direction)
    {
        // Apply trailing stop if profit > 50% of TP
        double trailingTrigger = PriceUtils::PipsToPrice(TAKE_PROFIT_PIPS * 0.5);

        if (direction == DIR_BUY)
            return (currentPrice - entryPrice) > trailingTrigger;
        else
            return (entryPrice - currentPrice) > trailingTrigger;

        return false;
    }

    //+------------------------------------------------------------------+
    //| Calculate trailing stop level                                      |
    //+------------------------------------------------------------------+
    double CalculateTrailingStopLevel(double currentPrice, DIRECTION direction)
    {
        double trailingDistance = PriceUtils::PipsToPrice(STOP_LOSS_PIPS * 0.5);

        if (direction == DIR_BUY)
            return PriceUtils::NormalizePrice(currentPrice - trailingDistance);
        else
            return PriceUtils::NormalizePrice(currentPrice + trailingDistance);

        return 0;
    }

    //+------------------------------------------------------------------+
    //| Get Risk Manager status                                           |
    //+------------------------------------------------------------------+
    string GetStatusString()
    {
        string status = "Daily Loss: " + DoubleToString(GetDailyLossPercent(), 2) + "% | " +
                       "Trades Today: " + IntegerToString(m_ordersToday) + "/" +
                       IntegerToString(MAX_ORDERS_PER_DAY) + " | " +
                       "Lot Size: " + DoubleToString(LOT_SIZE, 2);

        return status;
    }

    // Setter methods
    void SetLotSize(double lotSize) { m_riskParams.lotSize = lotSize; }
    void SetStopLossPips(double pips) { m_riskParams.stopLossPips = pips; }
    void SetTakeProfitPips(double pips) { m_riskParams.takeProfitPips = pips; }

    // Getter methods
    RiskParams GetRiskParams() const { return m_riskParams; }
    double GetDailyMaxLoss() const { return m_dailyMaxLoss; }
    int GetOrdersToday() const { return m_ordersToday; }
};

#endif
