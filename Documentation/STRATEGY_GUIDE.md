# SMC Ultimate EA - Strategy Guide

## Overview

The SMC Ultimate EA (Expert Advisor) is a sophisticated algorithmic trading system based on **Smart Money Concepts (SMC)** trading principles. It integrates four powerful technical analysis components to identify high-probability trading opportunities.

## Core Trading Components

### 1. Break of Structure (BoS)
**What it is:** A break of structure occurs when price breaks beyond a previous swing high or swing low, indicating a potential change in market direction.

**How it works:**
- **Bullish BoS**: Price closes above and breaks through a previous swing high
- **Bearish BoS**: Price closes below and breaks through a previous swing low
- Signals impulsive moves with strong directionality

**Entry Signal:** When BoS is confirmed with higher timeframe confluence

### 2. Change of Character (CHoCH)
**What it is:** A shift from impulsive market structure to corrective structure, indicating potential trend reversal.

**How it works:**
- Monitors bar structure for patterns:
  - **Impulsive bars**: Large body, small wicks (continuation)
  - **Corrective bars**: Small body, large wicks (reversal)
- Detects reversal patterns (lower lows turning to higher lows, etc.)
- Identifies shift in market participant behavior

**Entry Signal:** When market switches from impulsive to corrective character

### 3. Fair Value Gap (FVG)
**What it is:** An unfilled area of price between candles that may act as support/resistance.

**How it works:**
- **Bullish FVG**: Gap above a candle (previous high < current low < next low)
- **Bearish FVG**: Gap below a candle (previous low > current high > next high)
- Price often returns to fill these gaps
- Minimum gap size: 10 pips (configurable)

**Entry Signal:** When price approaches FVG levels, often with BoS or CHoCH confirmation

### 4. Order Block (OB)
**What it is:** A price level where strong buying or selling pressure occurred before reversal.

**How it works:**
- **Bullish OB**: Forms at bottom of impulsive down move (strong demand)
- **Bearish OB**: Forms at top of impulsive up move (strong supply)
- Price often bounces from these levels
- Strength rating: 1 (weak) to 3 (strong)

**Entry Signal:** When price comes back to test OB level, especially with other signal confluence

## State Machine Flow

The EA follows a structured state machine approach:

```
IDLE
  → SCANNING_MARKET (looking for setup)
    → STRUCTURE_ANALYSIS (analyzing SMC components)
      → CONFIRMATION_PENDING (waiting for signal confirmation)
        → ENTRY_SETUP (preparing to enter)
          → POSITION_MANAGEMENT (managing open position)
            → EXIT_ANALYSIS (evaluating exit conditions)
              → IDLE (position closed, restart cycle)
```

### State Descriptions

- **IDLE**: Waiting for market conditions to trade
- **SCANNING_MARKET**: Monitoring price action for setup opportunities
- **STRUCTURE_ANALYSIS**: Analyzing all SMC components (BoS, CHoCH, FVG, OB)
- **CONFIRMATION_PENDING**: Waiting for signal confirmation over multiple bars
- **ENTRY_SETUP**: Preparing to execute trade based on confirmed signal
- **POSITION_MANAGEMENT**: Managing open position with stop loss/take profit
- **EXIT_ANALYSIS**: Checking exit conditions
- **RISK_CHECK**: Risk management triggered (daily loss limit, etc.)

## Signal Types

### 1. BoS Breakout (Confidence: 60%)
Primary signal based on Break of Structure

### 2. CHoCH Reversal (Confidence: 60%)
Primary signal based on Change of Character

### 3. FVG Pullback (Confidence: 60%)
Signal when price approaches Fair Value Gap

### 4. OB Reaction (Confidence: 50%)
Signal when price tests Order Block level

### 5. Confluence (Confidence: 90%)
**STRONGEST** - Multiple signals aligned (3+ components agree)

## Risk Management

### Position Sizing
- Based on account risk percentage (default: 2%)
- Calculated using stop loss distance
- Formula: Risk Amount / (Stop Loss in Pips × 100,000)

### Stop Loss / Take Profit
- **Stop Loss**: 50 pips (default, configurable)
- **Take Profit**: 150 pips (default, configurable)
- **Risk/Reward Ratio**: 1:3 (minimum 1:1.5)

### Daily Limits
- **Max Orders Per Day**: 5 trades
- **Max Daily Loss**: Based on risk percentage
- Automatic trading halt when limits reached

### Trailing Stop
- Applied after profit reaches 50% of TP target
- Protects profits during favorable moves

## Trading Rules

### Entry Rules
1. Signal must form at confluence of 2+ SMC components (preferred)
2. Signal confidence must exceed 70% threshold
3. Confirmation must sustain for minimum 2 bars
4. Risk management rules must be satisfied
5. Trading hours: 00:00 - 23:00 (configurable)

### Exit Rules
1. **Automatic**: Stop Loss or Take Profit hit
2. **Trailing Stop**: Activated after 50% profit target
3. **Manual**: Trader can close position manually
4. **Time-based**: Optional maximum holding period

### Risk Rules
1. No trading after daily loss limit reached
2. No trading after max orders per day reached
3. No trading during low-equity conditions (<50% balance)
4. Minimum spread threshold must be met

## Configuration

See `Config.mqh` for all configuration parameters:

- Symbol and timeframe
- Lot size and risk parameters
- Stop loss / take profit levels
- Daily trading limits
- Trading hours
- Indicator sensitivity

## Performance Metrics to Monitor

1. **Win Rate**: Target >60% with proper risk management
2. **Risk/Reward Ratio**: Minimum 1:1.5, target 1:3
3. **Drawdown**: Monitor daily and monthly drawdown
4. **Sharpe Ratio**: Target >1.0
5. **Profit Factor**: Target >1.5 (profit / loss)

## Best Practices

1. **Use on Higher Timeframes**: H1 and above preferred for reliability
2. **Confluence is Key**: Wait for multiple signals before entering
3. **Respect Risk Management**: Never override stop loss/take profit
4. **Monitor Volatility**: Adjust parameters for high volatility periods
5. **Keep Historical Data**: Maintain at least 3 months of data
6. **Backtest First**: Always backtest parameters before live trading
7. **Start Small**: Begin with minimum lot size
8. **Review Regularly**: Analyze trades weekly for optimization

## Troubleshooting

### Too Many False Signals
- Increase `CONFIRMATION_THRESHOLD` (higher = more strict)
- Increase `SIGNAL_BARS` (require longer confirmation)
- Increase minimum FVG size and OB size

### Too Few Signals
- Decrease sensitivity parameters
- Expand trading hours
- Lower confirmation requirements

### High Drawdown
- Reduce lot size
- Reduce max daily risk percentage
- Increase stop loss size
- Increase required confluence signals

---

For technical questions, refer to `TECHNICAL_DESIGN.md`

For installation help, refer to `INSTALLATION.md`
