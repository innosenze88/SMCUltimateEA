//+------------------------------------------------------------------+
//| SMC Ultimate EA - Fair Value Gap (FVG) Indicator                 |
//+------------------------------------------------------------------+

#ifndef _FVG_MQH_
#define _FVG_MQH_

#include "..\Utilities\Utils.mqh"

//+------------------------------------------------------------------+
//| Fair Value Gap (FVG) Structure                                    |
//+------------------------------------------------------------------+
struct FVGLevel
{
    double topLevel;
    double bottomLevel;
    int barStart;
    int barEnd;
    DIRECTION direction;
    double gapSize;
};

//+------------------------------------------------------------------+
//| Fair Value Gap (FVG) Class                                        |
//+------------------------------------------------------------------+
class FVGDetector
{
private:
    int m_minPips;
    FVGLevel m_currentFVG;
    int m_fvgCount;

public:
    FVGDetector(int minPips = FVG_MIN_PIPS)
        : m_minPips(minPips), m_fvgCount(0)
    {
        m_currentFVG.topLevel = 0;
        m_currentFVG.bottomLevel = 0;
        m_currentFVG.barStart = 0;
        m_currentFVG.barEnd = 0;
        m_currentFVG.direction = DIR_NEUTRAL;
        m_currentFVG.gapSize = 0;
    }

    //+------------------------------------------------------------------+
    //| Detect Bullish FVG - Gap above candle                             |
    //+------------------------------------------------------------------+
    bool DetectBullishFVG(const double& high[], const double& low[], int bar = 2)
    {
        if (bar < 2)
            return false;

        // Bullish FVG: Previous bar high < Current bar low < Next bar low
        // This creates a "gap" of unfilled price
        if (low[bar] > high[bar + 1] && high[bar + 1] < low[bar - 1])
        {
            double gapPips = (low[bar] - high[bar + 1]) / PriceUtils::GetPoint();

            // Check if gap size meets minimum requirement
            if (gapPips >= m_minPips)
            {
                m_currentFVG.topLevel = low[bar];
                m_currentFVG.bottomLevel = high[bar + 1];
                m_currentFVG.barStart = bar + 1;
                m_currentFVG.barEnd = bar;
                m_currentFVG.direction = DIR_BUY;
                m_currentFVG.gapSize = gapPips;
                return true;
            }
        }

        return false;
    }

    //+------------------------------------------------------------------+
    //| Detect Bearish FVG - Gap below candle                             |
    //+------------------------------------------------------------------+
    bool DetectBearishFVG(const double& high[], const double& low[], int bar = 2)
    {
        if (bar < 2)
            return false;

        // Bearish FVG: Previous bar low > Current bar high > Next bar high
        // This creates a "gap" of unfilled price
        if (high[bar] < low[bar + 1] && low[bar + 1] > high[bar - 1])
        {
            double gapPips = (low[bar + 1] - high[bar]) / PriceUtils::GetPoint();

            // Check if gap size meets minimum requirement
            if (gapPips >= m_minPips)
            {
                m_currentFVG.topLevel = low[bar + 1];
                m_currentFVG.bottomLevel = high[bar];
                m_currentFVG.barStart = bar + 1;
                m_currentFVG.barEnd = bar;
                m_currentFVG.direction = DIR_SELL;
                m_currentFVG.gapSize = gapPips;
                return true;
            }
        }

        return false;
    }

    //+------------------------------------------------------------------+
    //| Detect FVG with comprehensive analysis                            |
    //+------------------------------------------------------------------+
    DIRECTION DetectFVG(const double& high[], const double& low[],
                       const double& close[], int bar = 2)
    {
        if (bar < 2)
            return DIR_NEUTRAL;

        // Check for bullish FVG
        if (DetectBullishFVG(high, low, bar))
        {
            return DIR_BUY;
        }

        // Check for bearish FVG
        if (DetectBearishFVG(high, low, bar))
        {
            return DIR_SELL;
        }

        return DIR_NEUTRAL;
    }

    //+------------------------------------------------------------------+
    //| Check if FVG has been filled (mitigated)                          |
    //+------------------------------------------------------------------+
    bool IsFVGFilled(const double& high[], const double& low[])
    {
        if (m_currentFVG.topLevel == 0)
            return false;

        // Check if gap has been filled
        if (m_currentFVG.direction == DIR_BUY)
        {
            // Bullish FVG filled when price comes back down
            if (low[0] <= m_currentFVG.bottomLevel)
                return true;
        }
        else if (m_currentFVG.direction == DIR_SELL)
        {
            // Bearish FVG filled when price comes back up
            if (high[0] >= m_currentFVG.topLevel)
                return true;
        }

        return false;
    }

    //+------------------------------------------------------------------+
    //| Get FVG strength (gap size)                                       |
    //+------------------------------------------------------------------+
    double GetFVGStrength(DIRECTION direction)
    {
        if (m_currentFVG.direction != direction)
            return 0.0;

        // Normalize gap size to strength (0-1)
        // Assume gaps from 10 to 100 pips map to 0.3-1.0 strength
        double maxPips = 100;
        double strength = (m_currentFVG.gapSize - 10) / (maxPips - 10);

        return MathMin(MathMax(strength, 0.3), 1.0);
    }

    //+------------------------------------------------------------------+
    //| Get FVG entry level (where price should bounce from gap)          |
    //+------------------------------------------------------------------+
    double GetFVGEntryLevel(DIRECTION direction)
    {
        if (m_currentFVG.direction != direction)
            return 0;

        if (direction == DIR_BUY)
            return m_currentFVG.bottomLevel;
        else
            return m_currentFVG.topLevel;

        return 0;
    }

    //+------------------------------------------------------------------+
    //| Get FVG mitigation level                                          |
    //+------------------------------------------------------------------+
    double GetFVGMitigationLevel(DIRECTION direction)
    {
        if (m_currentFVG.direction != direction)
            return 0;

        if (direction == DIR_BUY)
            return m_currentFVG.topLevel;
        else
            return m_currentFVG.bottomLevel;

        return 0;
    }

    //+------------------------------------------------------------------+
    //| Find multiple FVGs in range                                       |
    //+------------------------------------------------------------------+
    int FindMultipleFVGs(const double& high[], const double& low[],
                        const double& close[], int barCount, DIRECTION& direction)
    {
        int fvgCount = 0;

        for (int i = 2; i < barCount; i++)
        {
            DIRECTION fvgDir = DetectFVG(high, low, close, i);
            if (fvgDir != DIR_NEUTRAL)
            {
                fvgCount++;
                direction = fvgDir;
            }
        }

        m_fvgCount = fvgCount;
        return fvgCount;
    }

    //+------------------------------------------------------------------+
    //| Get current FVG structure                                         |
    //+------------------------------------------------------------------+
    FVGLevel GetCurrentFVG() const
    {
        return m_currentFVG;
    }

    // Setter methods
    void SetMinPips(int minPips) { m_minPips = minPips; }

    // Getter methods
    int GetMinPips() const { return m_minPips; }
    int GetFVGCount() const { return m_fvgCount; }
};

#endif
