# SMC Ultimate EA v1.0 - Documentation

## 🎯 Overview

SMC Ultimate EA v1.0 is the first version of a Smart Money Concepts Expert Advisor for MetaTrader 5. This EA implements the core SMC principles focusing on **Break of Structure (BOS)** and **Change of Character (CHoCH)** detection with dual timeframe analysis.

## ✨ Features

### Core Components

1. **SMC Market Structure Detection**
   - Automatic swing high/low identification
   - BOS (Break of Structure) detection for trend continuation
   - CHoCH (Change of Character) detection for trend reversal
   - Multi-timeframe structure analysis

2. **Dual Timeframe Analysis**
   - **H4 (Higher Timeframe)**: Determines overall trend direction
   - **M15 (Lower Timeframe)**: Executes precise entries
   - Only trades when LTF signals align with HTF trend

3. **Risk Management**
   - Fixed percentage risk per trade (default: 1%)
   - Automatic lot size calculation based on stop loss
   - Risk:Reward ratio (default: 1:2)
   - Stop loss placed beyond structure with buffer

4. **Visual Indicators**
   - Swing points marked on chart (SH/SL)
   - BOS signals with arrows and labels
   - CHoCH signals with arrows and labels
   - Real-time dashboard showing trends and statistics

## 📋 Installation

### Method 1: Manual Installation

1. **Copy files to MetaTrader 5 directory:**
   ```
   [MT5 Data Folder]/MQL5/Experts/SMCUltimateEA_V1.mq5
   [MT5 Data Folder]/MQL5/Include/SMCStructures.mqh
   [MT5 Data Folder]/MQL5/Include/RiskManager.mqh
   [MT5 Data Folder]/MQL5/Include/VisualManager.mqh
   ```

2. **Compile the EA:**
   - Open MetaEditor (F4 in MT5)
   - Open `SMCUltimateEA_V1.mq5`
   - Click Compile (F7)
   - Check for any errors

3. **Attach to chart:**
   - Open MT5
   - Open desired chart (e.g., EURUSD)
   - Drag EA from Navigator to chart
   - Configure settings
   - Click OK

### Method 2: Direct Compilation

If you have MetaTrader 5 installed, you can compile directly:

```bash
# From the repository root
cd Experts
# Use MetaEditor command line compiler
metaeditor64 /compile:SMCUltimateEA_V1.mq5
```

## ⚙️ Configuration

### Timeframe Settings

| Parameter | Default | Description |
|-----------|---------|-------------|
| **Higher Timeframe** | H4 | Determines overall trend |
| **Lower Timeframe** | M15 | Entry execution timeframe |

**Recommended combinations:**
- Conservative: H4 + M15 (default)
- Aggressive: H1 + M5
- Scalping: M15 + M1

### SMC Settings

| Parameter | Default | Description |
|-----------|---------|-------------|
| **Swing Strength** | 5 | Bars on each side for swing detection |
| **Trade BOS** | true | Enable BOS trading signals |
| **Trade CHoCH** | true | Enable CHoCH trading signals |

**Swing Strength Guide:**
- Lower (3-4): More sensitive, more signals
- Medium (5-7): Balanced approach
- Higher (8-10): Stronger swings, fewer signals

### Risk Management

| Parameter | Default | Description |
|-----------|---------|-------------|
| **Risk Per Trade** | 1.0% | Percentage of account balance to risk |
| **R:R Ratio** | 2.0 | Risk to Reward ratio (1:2) |
| **SL Buffer** | 10 points | Extra distance beyond structure |

**Risk Guidelines:**
- Conservative: 0.5% - 1%
- Moderate: 1% - 2%
- Aggressive: 2% - 3%
- **Never exceed 5% per trade**

### Visual Settings

| Parameter | Default | Description |
|-----------|---------|-------------|
| **Show Swings** | true | Display swing high/low points |
| **Show BOS** | true | Display BOS signals |
| **Show CHoCH** | true | Display CHoCH signals |
| **Show Dashboard** | true | Display info panel |

### Trading Settings

| Parameter | Default | Description |
|-----------|---------|-------------|
| **Magic Number** | 123456 | Unique identifier for EA trades |
| **Trade Comment** | SMC_v1 | Comment added to trades |

## 🎮 How It Works

### 1. Market Structure Analysis

The EA continuously scans the market for:
- **Swing Highs**: Price peaks with lower highs on both sides
- **Swing Lows**: Price valleys with higher lows on both sides

### 2. Trend Detection

**Higher Timeframe (H4):**
- Identifies overall market direction
- Bullish: Price making higher highs
- Bearish: Price making lower lows

**Lower Timeframe (M15):**
- Looks for precise entry points
- Only trades in direction of H4 trend

### 3. Signal Generation

**BOS (Break of Structure) - Continuation:**
- Bullish BOS: Price breaks above previous high
- Bearish BOS: Price breaks below previous low
- Signals trend continuation
- Entry: Immediate on break

**CHoCH (Change of Character) - Reversal:**
- Bullish CHoCH: Downtrend breaks into uptrend
- Bearish CHoCH: Uptrend breaks into downtrend
- Signals trend reversal
- Entry: Immediate on confirmation

### 4. Trade Execution

When signal detected:
1. ✅ Check alignment with HTF trend
2. ✅ Calculate stop loss (beyond structure + buffer)
3. ✅ Calculate take profit (R:R ratio applied)
4. ✅ Calculate lot size (based on % risk)
5. ✅ Validate trade parameters
6. ✅ Execute market order

### 5. Trade Management

- **Stop Loss**: Placed beyond broken structure level
- **Take Profit**: Based on R:R ratio (default 1:2)
- **No manual intervention**: EA manages entries only
- **User handles exits**: Can modify TP/SL manually

## 📊 Visual Guide

### Chart Elements

**Swing Points:**
- Red horizontal lines = Swing Highs (SH)
- Blue horizontal lines = Swing Lows (SL)

**BOS Signals:**
- Green arrow up ↑ = Bullish BOS
- Orange arrow down ↓ = Bearish BOS
- Label: "BOS ↑" or "BOS ↓"

**CHoCH Signals:**
- Dark green double arrow ⇈ = Bullish CHoCH
- Crimson double arrow ⇊ = Bearish CHoCH
- Label: "CHoCH ⇈" or "CHoCH ⇊"

**Dashboard (Top-left):**
```
┌─────────────────────────────┐
│ SMC Ultimate EA v1.0        │
│ H4 Trend: BULLISH           │
│ M15 Trend: BULLISH          │
│ Trades: 10 | Win: 65.0%     │
└─────────────────────────────┘
```

## 🔍 Example Trade Scenarios

### Scenario 1: Bullish BOS Entry

```
Setup:
- H4 Trend: BULLISH (higher highs forming)
- M15: Price pulls back after uptrend
- Previous swing high at 1.1000

Trigger:
- M15 price breaks above 1.1000 → BOS detected
- EA validates: H4 bullish ✅

Execution:
- Entry: 1.1005 (market price)
- SL: 1.0985 (below structure + 10pts buffer)
- TP: 1.1045 (1:2 R:R = 40pts profit)
- Lot: 0.02 (for 1% risk on 20pt SL)

Result:
- Trade opened immediately
- Risk: $20 | Potential Profit: $40
```

### Scenario 2: Bearish CHoCH Entry

```
Setup:
- H4 Trend: BULLISH
- M15: Making lower high (sign of reversal)
- Previous M15 high at 1.1050

Trigger:
- M15 price breaks below previous low → CHoCH
- Trend shifts: BULLISH → BEARISH

Execution:
- Entry: 1.1020 (market price)
- SL: 1.1035 (above structure + buffer)
- TP: 1.0990 (1:2 R:R)
- Lot: 0.02

Result:
- Reversal trade captured
- CHoCH signal shown on chart
```

## 📈 Backtest Recommendations

### Backtest Settings

**Period:**
- Minimum: 3 months
- Recommended: 6-12 months
- Optimal: 1-2 years

**Symbols:**
- Major Pairs: EURUSD, GBPUSD, USDJPY
- Crosses: EURJPY, GBPJPY
- Gold: XAUUSD (requires adjustment)

**Mode:**
- Every tick (most accurate)
- 1 minute OHLC (faster)

### Expected Results

**Win Rate:**
- BOS trades: 55-65%
- CHoCH trades: 45-55%
- Combined: 50-60%

**Profit Factor:**
- Target: 1.5 - 2.0
- With 1:2 R:R: Achievable at 50%+ win rate

## ⚠️ Important Notes

### What This EA Does

✅ Detects market structure (swing points)
✅ Identifies BOS and CHoCH signals
✅ Executes immediate entries on signals
✅ Calculates proper position sizing
✅ Places SL and TP automatically
✅ Shows visual indicators on chart

### What This EA Does NOT Do

❌ Does NOT trail stops automatically
❌ Does NOT close partial positions
❌ Does NOT detect FVG (Fair Value Gaps)
❌ Does NOT detect Order Blocks
❌ Does NOT move SL to breakeven
❌ Does NOT filter news events

### Limitations

1. **V1 is basic**: This is the foundation version
2. **No FVG/OB**: Advanced concepts come in v2+
3. **No trade management**: Exits are static TP/SL
4. **Market conditions**: Works best in trending markets
5. **Spread sensitive**: Use low-spread brokers

## 🛠️ Troubleshooting

### EA not taking trades

**Check:**
1. Is EA enabled? (Look for smiley face in corner)
2. Is AutoTrading enabled? (Click AutoTrading button)
3. Are there actual BOS/CHoCH signals?
4. Check H4 trend - trades only with trend
5. Is there already an open position?

### Compilation errors

**Common fixes:**
1. Ensure all .mqh files are in MQL5/Include/
2. Check file paths in #include statements
3. Verify MT5 is updated to latest version
4. Close and reopen MetaEditor

### Visual elements not showing

1. Right-click chart → Properties → Common
2. Ensure "Show objects descriptions" is checked
3. Restart EA (remove and re-attach)

## 📞 Support & Updates

**Repository:** https://github.com/innosenze88/SMCUltimateEA

**Documentation:**
- `docs/SMC_CONCEPTS.md` - SMC theory
- `docs/QUICK_START.md` - Quick start guide
- `docs/EA_V1_README.md` - This file

## 🚀 What's Next?

**Version 2.0 will include:**
- Fair Value Gap (FVG) detection
- Order Block (OB) identification
- Retest entry logic (instead of immediate)
- Advanced trade management
- Trailing stop functionality
- Break-even automation
- News filter integration

## 📜 License

This EA is for educational and personal use. Do not distribute without permission.

## ⚖️ Disclaimer

Trading involves risk. Past performance does not guarantee future results. Always test on demo account first. Never risk more than you can afford to lose. The creators are not responsible for any trading losses.

---

**Version:** 1.0
**Last Updated:** 2024
**Status:** Initial Release - Basic BOS/CHoCH Detection

Happy Trading! 🎯📈
