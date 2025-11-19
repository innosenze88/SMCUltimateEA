//+------------------------------------------------------------------+
//|                                                SMCStructures.mqh |
//|                                          SMC Ultimate EA v1.0    |
//|                                   Market Structure Detection     |
//+------------------------------------------------------------------+
#property copyright "SMC Ultimate EA"
#property version   "1.00"
#property strict

//+------------------------------------------------------------------+
//| Enumeration for trend direction                                  |
//+------------------------------------------------------------------+
enum ENUM_TREND_DIRECTION
{
   TREND_BULLISH,      // Uptrend (HH + HL)
   TREND_BEARISH,      // Downtrend (LH + LL)
   TREND_NEUTRAL       // No clear trend
};

//+------------------------------------------------------------------+
//| Structure for Swing Point                                        |
//+------------------------------------------------------------------+
struct SwingPoint
{
   datetime time;      // Time of swing
   double   price;     // Price of swing
   int      barIndex;  // Bar index
   bool     isHigh;    // True = swing high, False = swing low
   bool     isBroken;  // Has this level been broken?
};

//+------------------------------------------------------------------+
//| Structure for Market Structure Break                             |
//+------------------------------------------------------------------+
struct StructureBreak
{
   datetime       time;           // Time of break
   double         price;          // Price of break
   bool           isBOS;          // True = BOS, False = CHoCH
   bool           isBullish;      // True = bullish, False = bearish
   SwingPoint     brokenLevel;    // The level that was broken
   int            barIndex;       // Bar where break occurred
};

//+------------------------------------------------------------------+
//| Class for Market Structure Analysis                              |
//+------------------------------------------------------------------+
class CMarketStructure
{
private:
   string            m_symbol;              // Symbol
   ENUM_TIMEFRAMES   m_timeframe;           // Timeframe
   int               m_swingStrength;       // Bars for swing detection (left+right)

   SwingPoint        m_swingHighs[];        // Array of swing highs
   SwingPoint        m_swingLows[];         // Array of swing lows
   StructureBreak    m_structureBreaks[];   // Array of structure breaks

   ENUM_TREND_DIRECTION m_currentTrend;     // Current trend direction

public:
   // Constructor
   CMarketStructure(string symbol, ENUM_TIMEFRAMES timeframe, int swingStrength = 5)
   {
      m_symbol = symbol;
      m_timeframe = timeframe;
      m_swingStrength = swingStrength;
      m_currentTrend = TREND_NEUTRAL;

      ArrayResize(m_swingHighs, 0);
      ArrayResize(m_swingLows, 0);
      ArrayResize(m_structureBreaks, 0);
   }

   //+------------------------------------------------------------------+
   //| Detect swing high at given bar                                   |
   //+------------------------------------------------------------------+
   bool IsSwingHigh(int barIndex)
   {
      if(barIndex < m_swingStrength) return false;

      double centerHigh = iHigh(m_symbol, m_timeframe, barIndex);

      // Check left side
      for(int i = 1; i <= m_swingStrength; i++)
      {
         if(iHigh(m_symbol, m_timeframe, barIndex - i) >= centerHigh)
            return false;
      }

      // Check right side
      for(int i = 1; i <= m_swingStrength; i++)
      {
         if(iHigh(m_symbol, m_timeframe, barIndex + i) >= centerHigh)
            return false;
      }

      return true;
   }

   //+------------------------------------------------------------------+
   //| Detect swing low at given bar                                    |
   //+------------------------------------------------------------------+
   bool IsSwingLow(int barIndex)
   {
      if(barIndex < m_swingStrength) return false;

      double centerLow = iLow(m_symbol, m_timeframe, barIndex);

      // Check left side
      for(int i = 1; i <= m_swingStrength; i++)
      {
         if(iLow(m_symbol, m_timeframe, barIndex - i) <= centerLow)
            return false;
      }

      // Check right side
      for(int i = 1; i <= m_swingStrength; i++)
      {
         if(iLow(m_symbol, m_timeframe, barIndex + i) <= centerLow)
            return false;
      }

      return true;
   }

   //+------------------------------------------------------------------+
   //| Update swing points                                              |
   //+------------------------------------------------------------------+
   void UpdateSwingPoints()
   {
      // Scan for new swing points (start from swing strength to avoid incomplete swings)
      for(int i = m_swingStrength; i < 100; i++)
      {
         // Check for swing high
         if(IsSwingHigh(i))
         {
            SwingPoint sh;
            sh.time = iTime(m_symbol, m_timeframe, i);
            sh.price = iHigh(m_symbol, m_timeframe, i);
            sh.barIndex = i;
            sh.isHigh = true;
            sh.isBroken = false;

            // Add if not already exists
            if(!SwingExists(sh))
               AddSwingPoint(sh);
         }

         // Check for swing low
         if(IsSwingLow(i))
         {
            SwingPoint sl;
            sl.time = iTime(m_symbol, m_timeframe, i);
            sl.price = iLow(m_symbol, m_timeframe, i);
            sl.barIndex = i;
            sl.isHigh = false;
            sl.isBroken = false;

            // Add if not already exists
            if(!SwingExists(sl))
               AddSwingPoint(sl);
         }
      }
   }

   //+------------------------------------------------------------------+
   //| Check if swing point already exists                              |
   //+------------------------------------------------------------------+
   bool SwingExists(SwingPoint &point)
   {
      if(point.isHigh)
      {
         for(int i = 0; i < ArraySize(m_swingHighs); i++)
         {
            if(m_swingHighs[i].time == point.time)
               return true;
         }
      }
      else
      {
         for(int i = 0; i < ArraySize(m_swingLows); i++)
         {
            if(m_swingLows[i].time == point.time)
               return true;
         }
      }
      return false;
   }

   //+------------------------------------------------------------------+
   //| Add swing point to array                                         |
   //+------------------------------------------------------------------+
   void AddSwingPoint(SwingPoint &point)
   {
      if(point.isHigh)
      {
         int size = ArraySize(m_swingHighs);
         ArrayResize(m_swingHighs, size + 1);
         m_swingHighs[size] = point;
      }
      else
      {
         int size = ArraySize(m_swingLows);
         ArrayResize(m_swingLows, size + 1);
         m_swingLows[size] = point;
      }
   }

   //+------------------------------------------------------------------+
   //| Get last swing high                                              |
   //+------------------------------------------------------------------+
   SwingPoint GetLastSwingHigh()
   {
      SwingPoint empty;
      int size = ArraySize(m_swingHighs);
      if(size == 0) return empty;

      // Find the most recent (lowest bar index)
      int minIndex = 0;
      for(int i = 1; i < size; i++)
      {
         if(m_swingHighs[i].barIndex < m_swingHighs[minIndex].barIndex)
            minIndex = i;
      }

      return m_swingHighs[minIndex];
   }

   //+------------------------------------------------------------------+
   //| Get last swing low                                               |
   //+------------------------------------------------------------------+
   SwingPoint GetLastSwingLow()
   {
      SwingPoint empty;
      int size = ArraySize(m_swingLows);
      if(size == 0) return empty;

      // Find the most recent (lowest bar index)
      int minIndex = 0;
      for(int i = 1; i < size; i++)
      {
         if(m_swingLows[i].barIndex < m_swingLows[minIndex].barIndex)
            minIndex = i;
      }

      return m_swingLows[minIndex];
   }

   //+------------------------------------------------------------------+
   //| Detect BOS (Break of Structure)                                  |
   //+------------------------------------------------------------------+
   StructureBreak* DetectBOS()
   {
      double currentHigh = iHigh(m_symbol, m_timeframe, 0);
      double currentLow = iLow(m_symbol, m_timeframe, 0);

      // Check for Bullish BOS (price breaks above previous high)
      SwingPoint lastHigh = GetLastSwingHigh();
      if(lastHigh.price > 0 && !lastHigh.isBroken)
      {
         if(currentHigh > lastHigh.price && m_currentTrend == TREND_BULLISH)
         {
            StructureBreak *sb = new StructureBreak();
            sb.time = iTime(m_symbol, m_timeframe, 0);
            sb.price = currentHigh;
            sb.isBOS = true;
            sb.isBullish = true;
            sb.brokenLevel = lastHigh;
            sb.barIndex = 0;

            // Mark swing as broken
            for(int i = 0; i < ArraySize(m_swingHighs); i++)
            {
               if(m_swingHighs[i].time == lastHigh.time)
                  m_swingHighs[i].isBroken = true;
            }

            return sb;
         }
      }

      // Check for Bearish BOS (price breaks below previous low)
      SwingPoint lastLow = GetLastSwingLow();
      if(lastLow.price > 0 && !lastLow.isBroken)
      {
         if(currentLow < lastLow.price && m_currentTrend == TREND_BEARISH)
         {
            StructureBreak *sb = new StructureBreak();
            sb.time = iTime(m_symbol, m_timeframe, 0);
            sb.price = currentLow;
            sb.isBOS = true;
            sb.isBullish = false;
            sb.brokenLevel = lastLow;
            sb.barIndex = 0;

            // Mark swing as broken
            for(int i = 0; i < ArraySize(m_swingLows); i++)
            {
               if(m_swingLows[i].time == lastLow.time)
                  m_swingLows[i].isBroken = true;
            }

            return sb;
         }
      }

      return NULL;
   }

   //+------------------------------------------------------------------+
   //| Detect CHoCH (Change of Character)                               |
   //+------------------------------------------------------------------+
   StructureBreak* DetectCHoCH()
   {
      double currentHigh = iHigh(m_symbol, m_timeframe, 0);
      double currentLow = iLow(m_symbol, m_timeframe, 0);

      // Check for Bullish CHoCH (was bearish, now breaking high = reversal to bullish)
      SwingPoint lastHigh = GetLastSwingHigh();
      if(lastHigh.price > 0 && !lastHigh.isBroken && m_currentTrend == TREND_BEARISH)
      {
         if(currentHigh > lastHigh.price)
         {
            StructureBreak *sb = new StructureBreak();
            sb.time = iTime(m_symbol, m_timeframe, 0);
            sb.price = currentHigh;
            sb.isBOS = false;  // This is CHoCH
            sb.isBullish = true;
            sb.brokenLevel = lastHigh;
            sb.barIndex = 0;

            // Change trend
            m_currentTrend = TREND_BULLISH;

            return sb;
         }
      }

      // Check for Bearish CHoCH (was bullish, now breaking low = reversal to bearish)
      SwingPoint lastLow = GetLastSwingLow();
      if(lastLow.price > 0 && !lastLow.isBroken && m_currentTrend == TREND_BULLISH)
      {
         if(currentLow < lastLow.price)
         {
            StructureBreak *sb = new StructureBreak();
            sb.time = iTime(m_symbol, m_timeframe, 0);
            sb.price = currentLow;
            sb.isBOS = false;  // This is CHoCH
            sb.isBullish = false;
            sb.brokenLevel = lastLow;
            sb.barIndex = 0;

            // Change trend
            m_currentTrend = TREND_BEARISH;

            return sb;
         }
      }

      return NULL;
   }

   //+------------------------------------------------------------------+
   //| Update trend direction                                           |
   //+------------------------------------------------------------------+
   void UpdateTrend()
   {
      SwingPoint lastHigh = GetLastSwingHigh();
      SwingPoint lastLow = GetLastSwingLow();

      if(lastHigh.price == 0 || lastLow.price == 0)
      {
         m_currentTrend = TREND_NEUTRAL;
         return;
      }

      // Simple trend detection: compare recent highs and lows
      // More sophisticated version would compare multiple swings
      double currentPrice = iClose(m_symbol, m_timeframe, 0);

      if(currentPrice > lastHigh.price)
         m_currentTrend = TREND_BULLISH;
      else if(currentPrice < lastLow.price)
         m_currentTrend = TREND_BEARISH;
   }

   //+------------------------------------------------------------------+
   //| Get current trend                                                |
   //+------------------------------------------------------------------+
   ENUM_TREND_DIRECTION GetTrend() { return m_currentTrend; }

   //+------------------------------------------------------------------+
   //| Set trend (for manual override or initialization)                |
   //+------------------------------------------------------------------+
   void SetTrend(ENUM_TREND_DIRECTION trend) { m_currentTrend = trend; }

   //+------------------------------------------------------------------+
   //| Get swing highs array                                            |
   //+------------------------------------------------------------------+
   void GetSwingHighs(SwingPoint &output[])
   {
      ArrayResize(output, ArraySize(m_swingHighs));
      for(int i = 0; i < ArraySize(m_swingHighs); i++)
         output[i] = m_swingHighs[i];
   }

   //+------------------------------------------------------------------+
   //| Get swing lows array                                             |
   //+------------------------------------------------------------------+
   void GetSwingLows(SwingPoint &output[])
   {
      ArrayResize(output, ArraySize(m_swingLows));
      for(int i = 0; i < ArraySize(m_swingLows); i++)
         output[i] = m_swingLows[i];
   }
};
