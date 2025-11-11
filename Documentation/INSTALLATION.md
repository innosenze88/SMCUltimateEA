# SMC Ultimate EA - Installation Guide

## Prerequisites

- MetaTrader 5 (MT5)
- MQL5 compiler (included with MT5)
- Basic knowledge of MT5 platform
- Stable internet connection

## Installation Steps

### Step 1: Locate EA Files

All EA files are located in the `MQL5` directory:

```
SMCUltimateEA/
├── MQL5/
│   ├── Experts/
│   │   └── SMCUltimateEA.mq5          ← Main EA file
│   └── Include/
│       ├── Core/                       ← Core modules
│       ├── Indicators/                 ← Indicator modules
│       └── Utilities/                  ← Utility modules
```

### Step 2: Copy EA Files

1. Open MT5 Data Folder:
   - Click: **File → Open Data Folder**
   - Or navigate to: `C:\Users\[YourUsername]\AppData\Roaming\MetaQuotes\Terminal\[TerminalID]\MQL5\`

2. Copy the following directories:
   ```
   MQL5/
   ├── Experts/SMCUltimateEA.mq5
   └── Include/
       ├── Core/
       ├── Indicators/
       └── Utilities/
   ```

3. Paste into your MT5 `MQL5` folder

### Step 3: Compile EA

1. In MT5, open **MetaEditor** (F5 or Tools → MetaQuotes Language Editor)
2. Navigate to: `Experts → SMCUltimateEA.mq5`
3. Click **Compile** button (or Ctrl+F7)
4. Check for errors in the compilation log

### Step 4: Configure EA

Before attaching to chart, configure parameters in `MQL5/Include/Utilities/Config.mqh`:

```c++
// Trading Configuration
const string SYMBOL = "EURUSD";              // Your trading pair
const ENUM_TIMEFRAMES TIMEFRAME = PERIOD_H1; // Your timeframe
const double LOT_SIZE = 0.1;                 // Position size
const double RISK_PERCENT = 2.0;             // Risk per trade (%)

// SMC Configuration
const int BoS_LOOKBACK = 50;                 // BoS detection lookback
const int ChoCH_MIN_BARS = 3;                // CHoCH bar minimum
const int FVG_MIN_PIPS = 10;                 // FVG minimum size
const int OB_LOOKBACK = 20;                  // OB detection lookback

// Risk Management
const int STOP_LOSS_PIPS = 50;               // SL size
const int TAKE_PROFIT_PIPS = 150;            // TP size
const int MAX_ORDERS_PER_DAY = 5;            // Daily trade limit
```

### Step 5: Attach EA to Chart

1. Open chart for your configured symbol and timeframe
2. Go to **Insert → Expert Advisors → SMCUltimateEA**
   - Or drag `SMCUltimateEA.ex5` from Navigator to chart

3. In the Expert Advisor setup dialog:
   - **Check "Allow automated trading"** checkbox
   - **Check "Allow live (real-time) trading"** if on live account
   - Verify all parameters match your intended settings
   - Click OK

### Step 6: Verify Installation

1. Check Journal/Logs (Ctrl+L):
   - Look for: "EA initialized successfully"
   - Should see state: "Ready to trade..."

2. Check Expert tab:
   - Should show: "Expert Advisor running"
   - Log should display status updates

3. Chart display:
   - Status information appears in top-left corner
   - Shows current state, signals, and positions

## Configuration Options

### Basic Configuration

| Parameter | Default | Description |
|-----------|---------|-------------|
| SYMBOL | EURUSD | Trading instrument |
| TIMEFRAME | H1 | Chart timeframe |
| LOT_SIZE | 0.1 | Default position size |
| RISK_PERCENT | 2.0 | Risk per trade (%) |

### SMC Indicators

| Parameter | Default | Description |
|-----------|---------|-------------|
| BoS_LOOKBACK | 50 | Bars for structure analysis |
| ChoCH_MIN_BARS | 3 | Minimum bars for character change |
| FVG_MIN_PIPS | 10 | Minimum fair value gap size |
| OB_LOOKBACK | 20 | Bars for order block detection |

### Risk Management

| Parameter | Default | Description |
|-----------|---------|-------------|
| STOP_LOSS_PIPS | 50 | Stop loss distance |
| TAKE_PROFIT_PIPS | 150 | Take profit distance |
| MAX_ORDERS_PER_DAY | 5 | Maximum daily trades |
| CONFIRMATION_THRESHOLD | 0.7 | Signal confidence level |
| SIGNAL_BARS | 2 | Bars for confirmation |

### Trading Hours

| Parameter | Default | Description |
|-----------|---------|-------------|
| TRADING_START_HOUR | 0 | Start trading hour |
| TRADING_END_HOUR | 23 | Stop trading hour |
| DAILY_LIMIT_HOUR | 21 | Close last trades |

## Troubleshooting

### EA Won't Compile

**Issue**: Compilation errors in output
- **Solution**: Check that all `.mqh` files are in correct folders
- Verify Include paths match folder structure
- Check for missing dependencies

### "Expert Advisor not enabled" message

**Issue**: EA doesn't execute trades
- **Solution**:
  1. Tools → Options → Expert Advisors
  2. Check "Allow automated trading" box
  3. Restart MT5

### EA stops working

**Issue**: EA stops after some time
- **Solution**:
  1. Check Journal for errors
  2. Verify account still has sufficient balance
  3. Restart EA by removing and re-attaching
  4. Check internet connection stability

### Compilation shows warnings

**Issue**: Compilation completes but with warnings
- **Solution**: Generally safe to ignore minor warnings
- Focus on fixing errors (red marks)
- Test on demo account first

## First Steps After Installation

1. **Backtest First** (Optional but recommended):
   - In MT5: View → Strategy Tester
   - Load SMCUltimateEA
   - Set testing period (last 3-6 months)
   - Run backtest on demo account first

2. **Paper Trading**:
   - Start on demo account for 1-2 weeks
   - Monitor performance and signal quality
   - Adjust parameters if needed

3. **Live Trading**:
   - Start with minimum lot size
   - Monitor daily for first week
   - Scale up only after confirmed profitability

## File Structure After Installation

Your MT5 MQL5 folder should look like:

```
MQL5/
├── Experts/
│   └── SMCUltimateEA.mq5
├── Include/
│   ├── Core/
│   │   ├── StateManager.mqh
│   │   ├── RiskManager.mqh
│   │   └── TradingEngine.mqh
│   ├── Indicators/
│   │   ├── BoS.mqh
│   │   ├── ChoCH.mqh
│   │   ├── FVG.mqh
│   │   └── OB.mqh
│   └── Utilities/
│       ├── Config.mqh
│       └── Utils.mqh
```

## Support & Questions

For issues or questions:

1. Check `STRATEGY_GUIDE.md` for strategy explanation
2. Review `TECHNICAL_DESIGN.md` for code details
3. Check Journal tab for error messages
4. Verify all files are installed in correct locations

## Version History

- **v1.0** (Current): Initial release with BoS, CHoCH, FVG, OB indicators

---

Happy Trading! 🎯
