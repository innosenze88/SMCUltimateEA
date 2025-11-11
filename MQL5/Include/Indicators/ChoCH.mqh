//+------------------------------------------------------------------+
//| SMC Ultimate EA - Change of Character (CHoCH) Indicator          |
//+------------------------------------------------------------------+

#ifndef _CHOCH_MQH_
#define _CHOCH_MQH_

#include "..\Utilities\Utils.mqh"

//+------------------------------------------------------------------+
//| Change of Character (CHoCH) Class                                |
//+------------------------------------------------------------------+
class ChoCHDetector
{
private:
    int m_minBars;
    double m_volatilityThreshold;

public:
    ChoCHDetector(int minBars = ChoCH_MIN_BARS, double volatilityThreshold = 0.0003)
        : m_minBars(minBars), m_volatilityThreshold(volatilityThreshold) {}

    //+------------------------------------------------------------------+
    //| Detect Character Change - Shift from impulsive to corrective     |
    //+------------------------------------------------------------------+
    DIRECTION DetectChoCH(const double& high[], const double& low[],
                         const double& close[], int bar = 1)
    {
        if (bar < m_minBars + 2)
            return DIR_NEUTRAL;

        // Analyze bar structure for character change
        // Impulsive move: Large body, small wick (continuation)
        // Corrective move: Small body, large wicks (reversal)

        // Check current bar characteristics
        bool isCurrentBarImpulsive = IsImpulsiveBar(high, low, close, bar);
        bool isPreviousBarImpulsive = IsImpulsiveBar(high, low, close, bar + 1);

        // Character change detected when switching from impulsive to corrective
        if (isPreviousBarImpulsive && !isCurrentBarImpulsive)
        {
            // Determine direction based on previous impulsive move
            if (close[bar + 1] > open[bar + 1])
                return DIR_SELL;  // Was bullish, now corrective
            else
                return DIR_BUY;   // Was bearish, now corrective
        }

        return DIR_NEUTRAL;
    }

    //+------------------------------------------------------------------+
    //| Detect Bullish CHoCH - Shift to bullish character                |
    //+------------------------------------------------------------------+
    bool DetectBullishChoCH(const double& high[], const double& low[],
                           const double& close[], int bar = 1)
    {
        if (bar < m_minBars + 1)
            return false;

        // Look for recent lower low followed by reversal
        double recentLow = GetLowestLow(low, bar, m_minBars);

        // Current bar should close above recent resistance
        if (close[bar - 1] > high[bar])
        {
            // Check if there's a reversal pattern
            if (HasBullishReversal(high, low, close, bar))
                return true;
        }

        return false;
    }

    //+------------------------------------------------------------------+
    //| Detect Bearish CHoCH - Shift to bearish character                |
    //+------------------------------------------------------------------+
    bool DetectBearishChoCH(const double& high[], const double& low[],
                           const double& close[], int bar = 1)
    {
        if (bar < m_minBars + 1)
            return false;

        // Look for recent higher high followed by reversal
        double recentHigh = GetHighestHigh(high, bar, m_minBars);

        // Current bar should close below recent support
        if (close[bar - 1] < low[bar])
        {
            // Check if there's a reversal pattern
            if (HasBearishReversal(high, low, close, bar))
                return true;
        }

        return false;
    }

    //+------------------------------------------------------------------+
    //| Check if bar is impulsive (large body, small wick)                |
    //+------------------------------------------------------------------+
    bool IsImpulsiveBar(const double& high[], const double& low[],
                       const double& close[], int bar)
    {
        double open_val = open[bar];
        double body = MathAbs(close[bar] - open_val);
        double topWick = high[bar] - MathMax(close[bar], open_val);
        double bottomWick = MathMin(close[bar], open_val) - low[bar];
        double totalRange = high[bar] - low[bar];

        if (totalRange == 0) return false;

        // Impulsive: body > 60% of range, wicks < 20% of range
        if ((body / totalRange) > 0.6)
        {
            if ((topWick / totalRange) < 0.2 && (bottomWick / totalRange) < 0.2)
                return true;
        }

        return false;
    }

    //+------------------------------------------------------------------+
    //| Check for bullish reversal pattern                                |
    //+------------------------------------------------------------------+
    bool HasBullishReversal(const double& high[], const double& low[],
                           const double& close[], int bar)
    {
        if (bar < m_minBars)
            return false;

        // Look for lower lows followed by higher lows (reversal)
        double low1 = low[bar];
        double low2 = low[bar + 1];
        double low3 = low[bar + 2];

        if (low1 > low2 && low2 < low3)
            return true;

        return false;
    }

    //+------------------------------------------------------------------+
    //| Check for bearish reversal pattern                                |
    //+------------------------------------------------------------------+
    bool HasBearishReversal(const double& high[], const double& low[],
                           const double& close[], int bar)
    {
        if (bar < m_minBars)
            return false;

        // Look for higher highs followed by lower highs (reversal)
        double high1 = high[bar];
        double high2 = high[bar + 1];
        double high3 = high[bar + 2];

        if (high1 < high2 && high2 > high3)
            return true;

        return false;
    }

    //+------------------------------------------------------------------+
    //| Get strongest CHoCH signal with confidence                        |
    //+------------------------------------------------------------------+
    double GetChoCHStrength(const double& high[], const double& low[],
                           const double& close[], DIRECTION direction, int bar = 1)
    {
        double strength = 0.0;

        if (direction == DIR_BUY)
        {
            if (DetectBullishChoCH(high, low, close, bar))
                strength = 0.8;
            if (HasBullishReversal(high, low, close, bar))
                strength += 0.1;
        }
        else if (direction == DIR_SELL)
        {
            if (DetectBearishChoCH(high, low, close, bar))
                strength = 0.8;
            if (HasBearishReversal(high, low, close, bar))
                strength += 0.1;
        }

        return MathMin(strength, 1.0);
    }

    //+------------------------------------------------------------------+
    //| Helper: Get lowest low in range                                   |
    //+------------------------------------------------------------------+
    double GetLowestLow(const double& low[], int bar, int range)
    {
        double lowest = low[bar];
        for (int i = bar + 1; i <= bar + range && i < ArraySize(low); i++)
        {
            if (low[i] < lowest)
                lowest = low[i];
        }
        return lowest;
    }

    //+------------------------------------------------------------------+
    //| Helper: Get highest high in range                                 |
    //+------------------------------------------------------------------+
    double GetHighestHigh(const double& high[], int bar, int range)
    {
        double highest = high[bar];
        for (int i = bar + 1; i <= bar + range && i < ArraySize(high); i++)
        {
            if (high[i] > highest)
                highest = high[i];
        }
        return highest;
    }

    // Setter methods
    void SetMinBars(int minBars) { m_minBars = minBars; }
    void SetVolatilityThreshold(double threshold) { m_volatilityThreshold = threshold; }

    // Getter methods
    int GetMinBars() const { return m_minBars; }
    double GetVolatilityThreshold() const { return m_volatilityThreshold; }
};

#endif
