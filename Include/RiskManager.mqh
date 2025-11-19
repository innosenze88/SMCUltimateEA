//+------------------------------------------------------------------+
//|                                                  RiskManager.mqh |
//|                                          SMC Ultimate EA v1.0    |
//|                                   Risk Management Module         |
//+------------------------------------------------------------------+
#property copyright "SMC Ultimate EA"
#property version   "1.00"
#property strict

//+------------------------------------------------------------------+
//| Class for Risk Management                                        |
//+------------------------------------------------------------------+
class CRiskManager
{
private:
   double   m_riskPercent;        // Risk percentage per trade
   double   m_accountBalance;     // Current account balance
   string   m_symbol;             // Trading symbol

public:
   // Constructor
   CRiskManager(double riskPercent = 1.0, string symbol = NULL)
   {
      m_riskPercent = riskPercent;
      m_symbol = (symbol == NULL) ? _Symbol : symbol;
      UpdateAccountBalance();
   }

   //+------------------------------------------------------------------+
   //| Update account balance                                           |
   //+------------------------------------------------------------------+
   void UpdateAccountBalance()
   {
      m_accountBalance = AccountBalance();
   }

   //+------------------------------------------------------------------+
   //| Calculate lot size based on risk percentage                      |
   //+------------------------------------------------------------------+
   double CalculateLotSize(double entryPrice, double stopLoss)
   {
      if(entryPrice <= 0 || stopLoss <= 0)
         return 0;

      // Calculate risk amount in account currency
      double riskAmount = m_accountBalance * (m_riskPercent / 100.0);

      // Calculate stop loss distance in points
      double slDistance = MathAbs(entryPrice - stopLoss);

      if(slDistance <= 0)
         return 0;

      // Get symbol properties
      double tickValue = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_VALUE);
      double tickSize = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_SIZE);
      double minLot = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MIN);
      double maxLot = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MAX);
      double lotStep = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_STEP);

      // Calculate lot size
      double lotSize = (riskAmount / slDistance) / (tickValue / tickSize);

      // Normalize lot size
      lotSize = MathFloor(lotSize / lotStep) * lotStep;

      // Apply limits
      if(lotSize < minLot)
         lotSize = minLot;
      if(lotSize > maxLot)
         lotSize = maxLot;

      return NormalizeLot(lotSize);
   }

   //+------------------------------------------------------------------+
   //| Normalize lot size                                               |
   //+------------------------------------------------------------------+
   double NormalizeLot(double lot)
   {
      double lotStep = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_STEP);
      double minLot = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MIN);
      double maxLot = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MAX);

      lot = MathRound(lot / lotStep) * lotStep;

      if(lot < minLot)
         lot = minLot;
      if(lot > maxLot)
         lot = maxLot;

      return lot;
   }

   //+------------------------------------------------------------------+
   //| Calculate stop loss based on structure                           |
   //+------------------------------------------------------------------+
   double CalculateStopLoss(bool isBuy, double structureLevel, double bufferPoints = 10)
   {
      double point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
      double buffer = bufferPoints * point;

      if(isBuy)
         return structureLevel - buffer;  // SL below structure for buy
      else
         return structureLevel + buffer;  // SL above structure for sell
   }

   //+------------------------------------------------------------------+
   //| Calculate take profit based on R:R ratio                         |
   //+------------------------------------------------------------------+
   double CalculateTakeProfit(bool isBuy, double entryPrice, double stopLoss, double rrRatio = 2.0)
   {
      double slDistance = MathAbs(entryPrice - stopLoss);
      double tpDistance = slDistance * rrRatio;

      if(isBuy)
         return entryPrice + tpDistance;
      else
         return entryPrice - tpDistance;
   }

   //+------------------------------------------------------------------+
   //| Validate trade parameters                                        |
   //+------------------------------------------------------------------+
   bool ValidateTradeParams(double price, double sl, double tp)
   {
      double point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
      int stopsLevel = (int)SymbolInfoInteger(m_symbol, SYMBOL_TRADE_STOPS_LEVEL);

      double minDistance = stopsLevel * point;

      // Check SL distance
      if(MathAbs(price - sl) < minDistance)
      {
         Print("SL too close to entry price");
         return false;
      }

      // Check TP distance
      if(MathAbs(price - tp) < minDistance)
      {
         Print("TP too close to entry price");
         return false;
      }

      return true;
   }

   //+------------------------------------------------------------------+
   //| Get current risk amount in currency                              |
   //+------------------------------------------------------------------+
   double GetRiskAmount()
   {
      return m_accountBalance * (m_riskPercent / 100.0);
   }

   //+------------------------------------------------------------------+
   //| Set risk percentage                                              |
   //+------------------------------------------------------------------+
   void SetRiskPercent(double riskPercent)
   {
      if(riskPercent > 0 && riskPercent <= 100)
         m_riskPercent = riskPercent;
   }

   //+------------------------------------------------------------------+
   //| Get risk percentage                                              |
   //+------------------------------------------------------------------+
   double GetRiskPercent() { return m_riskPercent; }
};
