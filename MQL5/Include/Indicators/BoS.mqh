//+------------------------------------------------------------------+
//| SMC Ultimate EA - Break of Structure (BoS) Indicator             |
//+------------------------------------------------------------------+

#ifndef _BOS_MQH_
#define _BOS_MQH_

#include "..\Utilities\Utils.mqh"

//+------------------------------------------------------------------+
//| Break of Structure (BoS) Class                                   |
//+------------------------------------------------------------------+
class BoSDetector
{
private:
    int m_lookback;
    double m_minDeviation;

public:
    BoSDetector(int lookback = BoS_LOOKBACK, double minDeviation = 0.0005)
        : m_lookback(lookback), m_minDeviation(minDeviation) {}

    //+------------------------------------------------------------------+
    //| Detect Bullish Break of Structure                                |
    //| Returns: true if bullish BoS detected                            |
    //+------------------------------------------------------------------+
    bool DetectBullishBoS(const double& high[], const double& low[], int bar = 1)
    {
        if (bar < m_lookback + 2)
            return false;

        // Find the highest high in lookback period (before the break)
        double highestHigh = high[bar];
        int highBar = bar;

        for (int i = bar + 1; i <= bar + m_lookback; i++)
        {
            if (high[i] > highestHigh)
            {
                highestHigh = high[i];
                highBar = i;
            }
        }

        // Check if price broke above the highest high with confirmation
        if (low[bar - 1] > highestHigh)
            return true;

        // Check if current bar closed above with significant deviation
        if (high[bar] > highestHigh + PriceUtils::PipsToPrice(5))
            return true;

        return false;
    }

    //+------------------------------------------------------------------+
    //| Detect Bearish Break of Structure                                |
    //| Returns: true if bearish BoS detected                            |
    //+------------------------------------------------------------------+
    bool DetectBearishBoS(const double& high[], const double& low[], int bar = 1)
    {
        if (bar < m_lookback + 2)
            return false;

        // Find the lowest low in lookback period (before the break)
        double lowestLow = low[bar];
        int lowBar = bar;

        for (int i = bar + 1; i <= bar + m_lookback; i++)
        {
            if (low[i] < lowestLow)
            {
                lowestLow = low[i];
                lowBar = i;
            }
        }

        // Check if price broke below the lowest low with confirmation
        if (high[bar - 1] < lowestLow)
            return true;

        // Check if current bar closed below with significant deviation
        if (low[bar] < lowestLow - PriceUtils::PipsToPrice(5))
            return true;

        return false;
    }

    //+------------------------------------------------------------------+
    //| Detect BoS with detailed analysis                                |
    //+------------------------------------------------------------------+
    DIRECTION DetectBoS(const double& high[], const double& low[],
                       const double& close[], int bar = 1)
    {
        if (bar < m_lookback + 2)
            return DIR_NEUTRAL;

        // Check for recent swing high and low
        double swingHigh = GetSwingHigh(high, bar, m_lookback);
        double swingLow = GetSwingLow(low, bar, m_lookback);

        // Bullish BoS: Price closes above previous swing high
        if (close[bar - 1] > swingHigh && low[bar - 1] > swingHigh)
        {
            if (DetectBullishBoS(high, low, bar))
                return DIR_BUY;
        }

        // Bearish BoS: Price closes below previous swing low
        if (close[bar - 1] < swingLow && high[bar - 1] < swingLow)
        {
            if (DetectBearishBoS(high, low, bar))
                return DIR_SELL;
        }

        return DIR_NEUTRAL;
    }

    //+------------------------------------------------------------------+
    //| Get Swing High in range                                          |
    //+------------------------------------------------------------------+
    double GetSwingHigh(const double& high[], int bar, int range)
    {
        double swingHigh = high[bar];
        for (int i = bar + 1; i <= bar + range && i < ArraySize(high); i++)
        {
            if (high[i] > swingHigh)
                swingHigh = high[i];
        }
        return swingHigh;
    }

    //+------------------------------------------------------------------+
    //| Get Swing Low in range                                           |
    //+------------------------------------------------------------------+
    double GetSwingLow(const double& low[], int bar, int range)
    {
        double swingLow = low[bar];
        for (int i = bar + 1; i <= bar + range && i < ArraySize(low); i++)
        {
            if (low[i] < swingLow)
                swingLow = low[i];
        }
        return swingLow;
    }

    //+------------------------------------------------------------------+
    //| Get BoS level                                                     |
    //+------------------------------------------------------------------+
    double GetBoSLevel(const double& high[], const double& low[],
                      DIRECTION direction, int bar = 1)
    {
        if (direction == DIR_BUY)
            return GetSwingHigh(high, bar, m_lookback);
        else if (direction == DIR_SELL)
            return GetSwingLow(low, bar, m_lookback);

        return 0;
    }

    // Setter methods
    void SetLookback(int lookback) { m_lookback = lookback; }
    void SetMinDeviation(double deviation) { m_minDeviation = deviation; }

    // Getter methods
    int GetLookback() const { return m_lookback; }
    double GetMinDeviation() const { return m_minDeviation; }
};

#endif
