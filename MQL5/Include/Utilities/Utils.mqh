//+------------------------------------------------------------------+
//| SMC Ultimate EA - Utility Functions Module                      |
//+------------------------------------------------------------------+

#ifndef _UTILS_MQH_
#define _UTILS_MQH_

#include "Config.mqh"

//+------------------------------------------------------------------+
//| Logger Class - For debugging and monitoring                      |
//+------------------------------------------------------------------+
class Logger
{
public:
    static void Info(const string msg)
    {
        Print("[INFO] ", msg, " - Time: ", TimeToString(TimeCurrent()));
    }

    static void Warning(const string msg)
    {
        Print("[WARNING] ", msg, " - Time: ", TimeToString(TimeCurrent()));
    }

    static void Error(const string msg)
    {
        Print("[ERROR] ", msg, " - Time: ", TimeToString(TimeCurrent()));
    }

    static void Debug(const string msg)
    {
        #ifdef _DEBUG
        Print("[DEBUG] ", msg);
        #endif
    }
};

//+------------------------------------------------------------------+
//| Price Utility Functions                                          |
//+------------------------------------------------------------------+
class PriceUtils
{
public:
    // Convert pips to price points
    static double PipsToPrice(double pips)
    {
        double point = SymbolInfoDouble(Symbol(), SYMBOL_POINT);
        int digits = (int)SymbolInfoInteger(Symbol(), SYMBOL_DIGITS);

        if (digits == 3 || digits == 5)
            return pips * point * 10;
        else
            return pips * point;
    }

    // Get current spread in pips
    static double GetSpreadPips()
    {
        double point = SymbolInfoDouble(Symbol(), SYMBOL_POINT);
        long spread = SymbolInfoInteger(Symbol(), SYMBOL_SPREAD);

        int digits = (int)SymbolInfoInteger(Symbol(), SYMBOL_DIGITS);
        if (digits == 3 || digits == 5)
            return spread / 10.0;
        else
            return spread / 1.0;
    }

    // Normalize price
    static double NormalizePrice(double price)
    {
        return NormalizeDouble(price, (int)SymbolInfoInteger(Symbol(), SYMBOL_DIGITS));
    }

    // Get point size
    static double GetPoint()
    {
        return SymbolInfoDouble(Symbol(), SYMBOL_POINT);
    }
};

//+------------------------------------------------------------------+
//| Time Utility Functions                                           |
//+------------------------------------------------------------------+
class TimeUtils
{
public:
    // Check if trading is allowed based on time
    static bool IsTradingTime()
    {
        int hour = Hour();
        if (hour >= TRADING_START_HOUR && hour < TRADING_END_HOUR)
            return true;
        return false;
    }

    // Check if daily limit reached
    static bool IsDailyLimitReached(int ordersToday)
    {
        if (ordersToday >= MAX_ORDERS_PER_DAY)
            return true;
        return false;
    }

    // Get current hour
    static int Hour()
    {
        return (int)TimeHour(TimeCurrent());
    }

    // Get current day
    static int Day()
    {
        return (int)TimeDay(TimeCurrent());
    }

    // Check if new day
    static bool IsNewDay(datetime lastTradeTime)
    {
        return TimeDay(TimeCurrent()) != TimeDay(lastTradeTime);
    }
};

//+------------------------------------------------------------------+
//| Position Utility Functions                                       |
//+------------------------------------------------------------------+
class PositionUtils
{
public:
    // Calculate lot size based on risk
    static double CalculateLotSize(double accountRisk, double stopLossPips)
    {
        double account_balance = AccountInfoDouble(ACCOUNT_BALANCE);
        double riskAmount = account_balance * (accountRisk / 100.0);
        double priceIncrease = PriceUtils::PipsToPrice(stopLossPips);

        if (priceIncrease <= 0) return 0.1;

        double lotSize = riskAmount / (priceIncrease * 100000);

        // Check minimum and maximum lot sizes
        double minLot = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);
        double maxLot = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX);
        double step = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_STEP);

        if (lotSize < minLot) lotSize = minLot;
        if (lotSize > maxLot) lotSize = maxLot;

        // Round to nearest step
        lotSize = MathRound(lotSize / step) * step;

        return NormalizeDouble(lotSize, 2);
    }

    // Get total open positions
    static int GetOpenPositions()
    {
        int count = 0;
        for (int i = 0; i < PositionsTotal(); i++)
        {
            if (PositionSelectByTicket(PositionGetTicket(i)))
            {
                if (PositionGetString(POSITION_SYMBOL) == Symbol())
                    count++;
            }
        }
        return count;
    }

    // Get total today's trades
    static int GetTradesToday()
    {
        int count = 0;
        for (int i = OrdersTotal() - 1; i >= 0; i--)
        {
            if (OrderSelect(OrderGetTicket(i)))
            {
                if (OrderGetString(ORDER_SYMBOL) == Symbol())
                {
                    if (TimeDay(OrderGetInteger(ORDER_TIME_SETUP)) == TimeDay(TimeCurrent()))
                        count++;
                }
            }
        }
        return count;
    }
};

//+------------------------------------------------------------------+
//| Array Utility Functions                                          |
//+------------------------------------------------------------------+
class ArrayUtils
{
public:
    // Get highest value in array
    static double GetHighest(const double& array[], int start, int count)
    {
        double highest = array[start];
        for (int i = start + 1; i < start + count && i < ArraySize(array); i++)
        {
            if (array[i] > highest)
                highest = array[i];
        }
        return highest;
    }

    // Get lowest value in array
    static double GetLowest(const double& array[], int start, int count)
    {
        double lowest = array[start];
        for (int i = start + 1; i < start + count && i < ArraySize(array); i++)
        {
            if (array[i] < lowest)
                lowest = array[i];
        }
        return lowest;
    }

    // Calculate average
    static double GetAverage(const double& array[], int start, int count)
    {
        double sum = 0;
        for (int i = start; i < start + count && i < ArraySize(array); i++)
        {
            sum += array[i];
        }
        return sum / count;
    }
};

#endif
