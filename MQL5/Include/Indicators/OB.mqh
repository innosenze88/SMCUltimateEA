//+------------------------------------------------------------------+
//| SMC Ultimate EA - Order Block (OB) Indicator                     |
//+------------------------------------------------------------------+

#ifndef _OB_MQH_
#define _OB_MQH_

#include "..\Utilities\Utils.mqh"

//+------------------------------------------------------------------+
//| Order Block Structure                                             |
//+------------------------------------------------------------------+
struct OrderBlock
{
    double topLevel;
    double bottomLevel;
    int barStart;
    int barEnd;
    DIRECTION direction;
    double blockSize;
    int strength;  // 1-3: weak, medium, strong
};

//+------------------------------------------------------------------+
//| Order Block (OB) Class                                            |
//+------------------------------------------------------------------+
class OBDetector
{
private:
    int m_lookback;
    double m_minSize;
    OrderBlock m_currentOB;

public:
    OBDetector(int lookback = OB_LOOKBACK, double minSize = OB_MIN_SIZE)
        : m_lookback(lookback), m_minSize(minSize)
    {
        m_currentOB.topLevel = 0;
        m_currentOB.bottomLevel = 0;
        m_currentOB.barStart = 0;
        m_currentOB.barEnd = 0;
        m_currentOB.direction = DIR_NEUTRAL;
        m_currentOB.blockSize = 0;
        m_currentOB.strength = 0;
    }

    //+------------------------------------------------------------------+
    //| Detect Bullish Order Block                                        |
    //| Order block forms at bottom of impulsive down move (strong demand)|
    //+------------------------------------------------------------------+
    bool DetectBullishOB(const double& high[], const double& low[],
                         const double& close[], int bar = 1)
    {
        if (bar < m_lookback + 1)
            return false;

        // Bullish OB: Find a strong impulsive down move followed by reversal
        // The OB is the body of the candle that reversed the trend

        // Look for lowest low in the range
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

        // Check if there's a reversal after the low
        if (bar > lowBar && close[bar - 1] > close[lowBar])
        {
            double blockSize = (high[lowBar] - low[lowBar]) / PriceUtils::GetPoint();

            if (blockSize >= m_minSize)
            {
                m_currentOB.topLevel = high[lowBar];
                m_currentOB.bottomLevel = low[lowBar];
                m_currentOB.barStart = lowBar;
                m_currentOB.barEnd = bar;
                m_currentOB.direction = DIR_BUY;
                m_currentOB.blockSize = blockSize;
                m_currentOB.strength = CalculateOBStrength(high, low, close, lowBar, bar);
                return true;
            }
        }

        return false;
    }

    //+------------------------------------------------------------------+
    //| Detect Bearish Order Block                                        |
    //| Order block forms at top of impulsive up move (strong supply)     |
    //+------------------------------------------------------------------+
    bool DetectBearishOB(const double& high[], const double& low[],
                        const double& close[], int bar = 1)
    {
        if (bar < m_lookback + 1)
            return false;

        // Bearish OB: Find a strong impulsive up move followed by reversal
        // The OB is the body of the candle that reversed the trend

        // Look for highest high in the range
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

        // Check if there's a reversal after the high
        if (bar > highBar && close[bar - 1] < close[highBar])
        {
            double blockSize = (high[highBar] - low[highBar]) / PriceUtils::GetPoint();

            if (blockSize >= m_minSize)
            {
                m_currentOB.topLevel = high[highBar];
                m_currentOB.bottomLevel = low[highBar];
                m_currentOB.barStart = highBar;
                m_currentOB.barEnd = bar;
                m_currentOB.direction = DIR_SELL;
                m_currentOB.blockSize = blockSize;
                m_currentOB.strength = CalculateOBStrength(high, low, close, highBar, bar);
                return true;
            }
        }

        return false;
    }

    //+------------------------------------------------------------------+
    //| Detect Order Block with comprehensive analysis                    |
    //+------------------------------------------------------------------+
    DIRECTION DetectOB(const double& high[], const double& low[],
                      const double& close[], int bar = 1)
    {
        if (bar < m_lookback + 1)
            return DIR_NEUTRAL;

        // Check for bullish OB
        if (DetectBullishOB(high, low, close, bar))
        {
            return DIR_BUY;
        }

        // Check for bearish OB
        if (DetectBearishOB(high, low, close, bar))
        {
            return DIR_SELL;
        }

        return DIR_NEUTRAL;
    }

    //+------------------------------------------------------------------+
    //| Calculate Order Block Strength (1-3)                              |
    //+------------------------------------------------------------------+
    int CalculateOBStrength(const double& high[], const double& low[],
                           const double& close[], int obBar, int currentBar)
    {
        double blockSize = (high[obBar] - low[obBar]) / PriceUtils::GetPoint();
        double body = MathAbs(close[obBar] - open[obBar]) / PriceUtils::GetPoint();

        // Count how many times price tested this level
        int testCount = 0;
        for (int i = obBar - 1; i >= obBar - 5 && i >= 0; i--)
        {
            if (m_currentOB.direction == DIR_BUY)
            {
                if (low[i] <= m_currentOB.bottomLevel)
                    testCount++;
            }
            else if (m_currentOB.direction == DIR_SELL)
            {
                if (high[i] >= m_currentOB.topLevel)
                    testCount++;
            }
        }

        // Strength based on body ratio and tests
        double bodyRatio = body / blockSize;
        int strength = 1;  // Default weak

        if (bodyRatio > 0.7)
            strength = 3;  // Strong
        else if (bodyRatio > 0.5)
            strength = 2;  // Medium
        else
            strength = 1;  // Weak

        // Add bonus for multiple tests
        if (testCount > 2)
            strength = MathMin(strength + 1, 3);

        return strength;
    }

    //+------------------------------------------------------------------+
    //| Check if price is at Order Block level                            |
    //+------------------------------------------------------------------+
    bool IsPriceAtOB(double currentPrice, double tolerance = 10)
    {
        if (m_currentOB.topLevel == 0)
            return false;

        double tolPrice = PriceUtils::PipsToPrice(tolerance);

        if (m_currentOB.direction == DIR_BUY)
        {
            if (currentPrice >= (m_currentOB.bottomLevel - tolPrice) &&
                currentPrice <= (m_currentOB.topLevel + tolPrice))
                return true;
        }
        else if (m_currentOB.direction == DIR_SELL)
        {
            if (currentPrice >= (m_currentOB.bottomLevel - tolPrice) &&
                currentPrice <= (m_currentOB.topLevel + tolPrice))
                return true;
        }

        return false;
    }

    //+------------------------------------------------------------------+
    //| Get Order Block strength as confidence (0-1)                      |
    //+------------------------------------------------------------------+
    double GetOBStrengthConfidence()
    {
        // Convert 1-3 strength to 0.3-1.0 confidence
        switch (m_currentOB.strength)
        {
            case 1:
                return 0.5;
            case 2:
                return 0.75;
            case 3:
                return 1.0;
            default:
                return 0.3;
        }
    }

    //+------------------------------------------------------------------+
    //| Find multiple OBs in range                                        |
    //+------------------------------------------------------------------+
    int FindMultipleOBs(const double& high[], const double& low[],
                       const double& close[], int barCount)
    {
        int obCount = 0;

        for (int i = 1; i < barCount; i++)
        {
            DIRECTION obDir = DetectOB(high, low, close, i);
            if (obDir != DIR_NEUTRAL)
                obCount++;
        }

        return obCount;
    }

    //+------------------------------------------------------------------+
    //| Get current Order Block                                           |
    //+------------------------------------------------------------------+
    OrderBlock GetCurrentOB() const
    {
        return m_currentOB;
    }

    // Setter methods
    void SetLookback(int lookback) { m_lookback = lookback; }
    void SetMinSize(double minSize) { m_minSize = minSize; }

    // Getter methods
    int GetLookback() const { return m_lookback; }
    double GetMinSize() const { return m_minSize; }
};

#endif
