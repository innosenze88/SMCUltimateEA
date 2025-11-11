# SMC Ultimate EA - Technical Design Document

## Architecture Overview

The SMC Ultimate EA is built with a modular architecture consisting of:

```
┌─────────────────────────────────────────────────────────┐
│                SMCUltimateEA.mq5 (Main)                │
├─────────────────────────────────────────────────────────┤
│                   TradingEngine                          │
├──────────────┬──────────────┬──────────────┬────────────┤
│ StateManager │ RiskManager  │ Indicators   │ Utilities  │
├──────────────┼──────────────┼──────────────┼────────────┤
│ • IDLE       │ • Position   │ • BoS        │ • Logger   │
│ • SCANNING   │   Sizing     │ • CHoCH      │ • PriceU   │
│ • CONFIRM    │ • TP/SL      │ • FVG        │ • TimeUtils│
│ • ENTRY      │ • Risk Limits│ • OB         │ • PositionU│
│ • MANAGE     │ • Trailing   │              │ • ArrayU   │
│ • EXIT       │               │              │            │
└──────────────┴──────────────┴──────────────┴────────────┘
```

## Core Components

### 1. Main EA File (`SMCUltimateEA.mq5`)

**Responsibilities:**
- Entry point for the expert advisor
- Manages MT5 event handlers (OnInit, OnTick, OnDeinit)
- Orchestrates state machine flow
- Displays UI/status information
- Handles order execution lifecycle

**Key Functions:**
```
OnInit()                    → Initialize all modules
OnTick()                    → Process on each tick
OnDeinit()                  → Cleanup
ProcessStateMachine()       → Route to state handlers
HandleXXXX()               → State-specific logic
IsNewBar()                 → Check for new bar
DisplayStatus()            → Update UI
```

### 2. State Manager (`StateManager.mqh`)

**Responsibilities:**
- Maintain current state
- Track state transitions
- Enforce state machine rules
- Monitor state duration
- Provide state validation logic

**State Transitions:**
```
IDLE → SCANNING_MARKET → STRUCTURE_ANALYSIS → CONFIRMATION_PENDING
   → ENTRY_SETUP → POSITION_MANAGEMENT → EXIT_ANALYSIS → IDLE
```

**Key Methods:**
```cpp
TransitionTo(STATE)         → Change state
GetCurrentState()           → Get active state
ShouldStartScanning()       → Check if ready for scan
ShouldAnalyzeStructure()    → Check if ready for analysis
IsSignalConfirmed()         → Check confirmation rules
GetStatusString()           → Return status display
```

### 3. Risk Manager (`RiskManager.mqh`)

**Responsibilities:**
- Calculate position size based on risk
- Manage stop loss and take profit levels
- Track daily loss and limits
- Prevent over-leveraging
- Implement trailing stops

**Key Methods:**
```cpp
CanTrade()                      → Check if trading allowed
CalculateLotSize()              → Compute position size
CalculateStopLossLevel()        → Calculate SL price
CalculateTakeProfitLevel()      → Calculate TP price
UpdateDailyLoss()               → Track daily P&L
HasReachedTakeProfit()          → Check TP condition
HasReachedStopLoss()            → Check SL condition
ShouldApplyTrailingStop()       → Check trailing stop
GetDailyLossPercent()           → Get loss percentage
```

**Risk Calculation Formula:**
```
LotSize = (AccountBalance × RiskPercent/100) / (StopLossPips × Point × 100,000)
```

### 4. Trading Engine (`TradingEngine.mqh`)

**Responsibilities:**
- Orchestrate all indicator analysis
- Generate trading signals
- Confirm signals over multiple bars
- Execute trades
- Manage signal lifecycle

**Key Methods:**
```cpp
Initialize()                    → Setup all indicators
AnalyzeMarket()                → Generate signals
ConfirmSignal()                → Validate signal
CalculateEntryLevels()         → Compute entry/SL/TP
ExecuteTrade()                 → Send order to broker
GetLastSignal()                → Last confirmed signal
GetCurrentSignal()             → Current analysis signal
```

**Signal Confidence Calculation:**
```
Single Indicator:      0.5 - 0.6 base confidence
Two Indicators:        0.7 confidence
Three Indicators:      0.8 confidence
Four Indicators (All): 0.9 confidence (CONFLUENCE)
```

## Indicator Modules

### 1. Break of Structure (BoS) - `BoS.mqh`

**Detection Logic:**
```
Bullish BoS:
  - Find highest high in lookback range
  - Check if price breaks above with new low
  - Validate with deviation threshold

Bearish BoS:
  - Find lowest low in lookback range
  - Check if price breaks below with new high
  - Validate with deviation threshold
```

**Key Methods:**
```cpp
DetectBullishBoS()              → Detect bull break
DetectBearishBoS()              → Detect bear break
DetectBoS()                     → Combined detection
GetSwingHigh()                  → Find swing high
GetSwingLow()                   → Find swing low
GetBoSLevel()                   → Return level
```

**Parameters:**
- `BoS_LOOKBACK`: 50 bars (configurable)
- `BoS_DEVIATION`: 0.05% (configurable)

### 2. Change of Character (CHoCH) - `ChoCH.mqh`

**Detection Logic:**
```
Impulsive Bar:
  - Body > 60% of total range
  - Wicks < 20% of total range
  - Indicates continuation

Corrective Bar:
  - Body < 60% of total range
  - Wicks > 20% of total range
  - Indicates reversal

CHoCH:
  - Shift from Impulsive → Corrective = Signal
```

**Reversal Patterns:**
```
Bullish Reversal (Lower → Higher):
  low[1] > low[2] AND low[2] < low[3]

Bearish Reversal (Higher → Lower):
  high[1] < high[2] AND high[2] > high[3]
```

**Key Methods:**
```cpp
DetectChoCH()                   → Main detection
IsImpulsiveBar()                → Check bar type
HasBullishReversal()            → Bull pattern
HasBearishReversal()            → Bear pattern
GetChoCHStrength()              → Confidence level
```

**Parameters:**
- `ChoCH_MIN_BARS`: 3 bars
- `VOLATILITY_THRESHOLD`: 0.03% (0.0003)

### 3. Fair Value Gap (FVG) - `FVG.mqh`

**Detection Logic:**
```
Bullish FVG:
  gap_top = low[bar]
  gap_bot = high[bar+1]
  Condition: gap_top > gap_bot
  Gap Size: (gap_top - gap_bot) / Point ≥ FVG_MIN_PIPS

Bearish FVG:
  gap_top = low[bar+1]
  gap_bot = high[bar]
  Condition: gap_top > gap_bot
  Gap Size: (gap_top - gap_bot) / Point ≥ FVG_MIN_PIPS
```

**FVGLevel Structure:**
```cpp
struct FVGLevel
{
    double topLevel;      // Upper boundary
    double bottomLevel;   // Lower boundary
    int barStart;         // Where gap started
    int barEnd;          // Where gap formed
    DIRECTION direction;  // UP or DOWN
    double gapSize;      // In pips
};
```

**Key Methods:**
```cpp
DetectBullishFVG()              → Bull gap detection
DetectBearishFVG()              → Bear gap detection
IsFVGFilled()                   → Check if filled
GetFVGStrength()                → Confidence (0-1)
GetFVGEntryLevel()              → Entry price
GetFVGMitigationLevel()         → Where gap fills
```

**Parameters:**
- `FVG_MIN_PIPS`: 10 pips minimum
- Max pips for strength calculation: 100 pips

### 4. Order Block (OB) - `OB.mqh`

**Detection Logic:**
```
Bullish OB (Demand):
  1. Find lowest low in range
  2. Check if price reversed after low
  3. OB = body of candle where low formed
  4. Size must exceed OB_MIN_SIZE

Bearish OB (Supply):
  1. Find highest high in range
  2. Check if price reversed after high
  3. OB = body of candle where high formed
  4. Size must exceed OB_MIN_SIZE
```

**OrderBlock Structure:**
```cpp
struct OrderBlock
{
    double topLevel;      // OB upper boundary
    double bottomLevel;   // OB lower boundary
    int barStart;         // Formation bar
    int barEnd;          // Current bar
    DIRECTION direction;  // BUY or SELL
    double blockSize;     // Size in pips
    int strength;         // 1 (weak) to 3 (strong)
};
```

**Strength Calculation:**
```
Body Ratio: body / block_size
  > 0.7 = Strong (3)
  > 0.5 = Medium (2)
  < 0.5 = Weak (1)

Bonus: +1 if price tested level 3+ times
```

**Key Methods:**
```cpp
DetectBullishOB()               → Demand level
DetectBearishOB()               → Supply level
CalculateOBStrength()           → Strength rating
IsPriceAtOB()                   → Check if at level
GetOBStrengthConfidence()       → Confidence 0-1
FindMultipleOBs()               → Multiple OBs
```

**Parameters:**
- `OB_LOOKBACK`: 20 bars
- `OB_MIN_SIZE`: 100 pips

## Utility Modules

### 1. Configuration (`Config.mqh`)

Centralized configuration with enums and constants:
- Trading parameters
- SMC component settings
- Risk management limits
- Time restrictions
- State machine definitions
- Signal types

### 2. Utilities (`Utils.mqh`)

**Logger Class:**
```cpp
Logger::Info()      → Information messages
Logger::Warning()   → Warning messages
Logger::Error()     → Error messages
Logger::Debug()     → Debug messages (debug build)
```

**PriceUtils Class:**
```cpp
PipsToPrice()       → Convert pips to price
GetSpreadPips()     → Current spread
NormalizePrice()    → Round to digits
GetPoint()          → Symbol point
```

**TimeUtils Class:**
```cpp
IsTradingTime()     → Check trading hours
IsDailyLimitReached() → Check trade limits
IsNewDay()          → Check if new day
Hour(), Day()       → Get time info
```

**PositionUtils Class:**
```cpp
CalculateLotSize()  → Position sizing
GetOpenPositions()  → Count open trades
GetTradesToday()    → Count daily trades
```

**ArrayUtils Class:**
```cpp
GetHighest()        → Find max value
GetLowest()         → Find min value
GetAverage()        → Calculate average
```

## Signal Flow

```
OnTick()
  ↓
IsNewBar? YES
  ↓
CopyPrice() → high[], low[], close[]
  ↓
ProcessStateMachine()
  ├─ IDLE → ShouldStartScanning?
  ├─ SCANNING → ShouldAnalyzeStructure?
  ├─ STRUCTURE → AnalyzeMarket()
  │   ├─ BoSDetector.DetectBoS()
  │   ├─ ChoCHDetector.DetectChoCH()
  │   ├─ FVGDetector.DetectFVG()
  │   ├─ OBDetector.DetectOB()
  │   └─ Calculate Confluence → Signal
  │
  ├─ CONFIRM → ConfirmSignal() → 2+ bars?
  ├─ ENTRY → ExecuteTrade()
  │   ├─ OrderSend() → MT5 Broker
  │   └─ Position Open
  │
  ├─ MANAGE → Monitor Position
  ├─ EXIT → Check TP/SL/Trailing
  └─ Return to IDLE
  ↓
DisplayStatus()
```

## Data Types & Structures

```cpp
// Main signal structure
struct TradeSignal
{
    SIGNAL_TYPE signalType;     // Type of signal
    DIRECTION direction;        // BUY or SELL
    double entryPrice;          // Entry level
    double stopLoss;            // SL level
    double takeProfit;          // TP level
    double confidence;          // Confidence 0-1
    int bar;                    // Bar number
    datetime time;              // Timestamp
};

// Enums for state machine
enum STATE { IDLE, SCANNING_MARKET, STRUCTURE_ANALYSIS, ... };
enum DIRECTION { DIR_NEUTRAL, DIR_BUY, DIR_SELL };
enum SIGNAL_TYPE { SIGNAL_NONE, SIGNAL_BOS_BREAKOUT, ... };
```

## Error Handling

**Critical Errors:**
- Initialization failures → INIT_FAILED
- Price data copy failure → Log and skip bar
- Order send failure → Log error, return to IDLE
- Account equity too low → Trigger RISK_CHECK

**Recovery:**
- Auto-transition to IDLE on errors
- Attempt recovery on next bar
- Log all errors for review

## Performance Considerations

**Optimization Techniques:**
1. Array indexing optimized for performance
2. Minimal loops with early termination
3. Efficient confluence detection
4. Single pass analysis per bar

**Memory Usage:**
- Indicators store only last level detected
- No historical signal storage
- Minimal dynamic memory allocation

**Processing:**
- Runs only on new bars (efficient)
- ~10-50ms per bar (typical)
- No lagging issues on backtesting

## Testing & Validation

**Backtest Validation:**
- Load minimum 3-6 months historical data
- Test across multiple symbols
- Verify signal generation
- Check order execution
- Validate P&L calculation

**Forward Testing:**
- Run on demo account 1-2 weeks
- Monitor signal quality
- Verify trade execution
- Check money management
- Validate risk limits

---

**Version:** 1.0
**Last Updated:** 2025-11-11
**Author:** SMC Ultimate EA Development Team
