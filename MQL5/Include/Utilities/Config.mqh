//+------------------------------------------------------------------+
//| SMC Ultimate EA - Configuration Module                          |
//+------------------------------------------------------------------+

#ifndef _CONFIG_MQH_
#define _CONFIG_MQH_

//=== Trading Configuration ===
const string SYMBOL = "EURUSD";
const ENUM_TIMEFRAMES TIMEFRAME = PERIOD_H1;
const double LOT_SIZE = 0.1;
const double RISK_PERCENT = 2.0;
const int MAX_ORDERS_PER_DAY = 5;

//=== SMC Configuration ===
const int BoS_LOOKBACK = 50;           // Bars to look back for Break of Structure
const int ChoCH_MIN_BARS = 3;          // Minimum bars for Change of Character
const int FVG_MIN_PIPS = 10;           // Minimum pips for Fair Value Gap
const int OB_LOOKBACK = 20;            // Bars to look back for Order Block
const double OB_MIN_SIZE = 100;        // Minimum order block size in pips

//=== Risk Management Configuration ===
const int STOP_LOSS_PIPS = 50;
const int TAKE_PROFIT_PIPS = 150;
const double TRAILING_STOP_PERCENT = 0.5;

//=== Time Configuration ===
const int DAILY_LIMIT_HOUR = 21;       // Stop trading after this hour
const int TRADING_START_HOUR = 0;      // Start trading from this hour
const int TRADING_END_HOUR = 23;       // Stop trading at this hour

//=== Indicator Sensitivity ===
const double CONFIRMATION_THRESHOLD = 0.7;  // Confidence level for signal confirmation
const int SIGNAL_BARS = 2;                   // Number of bars to confirm signal

//=== State Machine Configuration ===
enum STATE
{
    IDLE,
    SCANNING_MARKET,
    STRUCTURE_ANALYSIS,
    CONFIRMATION_PENDING,
    ENTRY_SETUP,
    POSITION_MANAGEMENT,
    EXIT_ANALYSIS,
    RISK_CHECK
};

//=== Trading Direction ===
enum DIRECTION
{
    DIR_NEUTRAL = 0,
    DIR_BUY = 1,
    DIR_SELL = -1
};

//=== Signal Types ===
enum SIGNAL_TYPE
{
    SIGNAL_NONE = 0,
    SIGNAL_BOS_BREAKOUT = 1,
    SIGNAL_CHOCH_REVERSAL = 2,
    SIGNAL_FVG_PULLBACK = 3,
    SIGNAL_OB_REACTION = 4,
    SIGNAL_CONFLUENCE = 5  // Multiple signals aligned
};

#endif
