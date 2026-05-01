# Crypto Trading Platform

## Overview
A beautiful, feature-rich cryptocurrency trading interface built with Flutter. This platform provides a professional trading experience with real-time candlestick charts, technical indicators, and position management.

## Features Implemented

### 1. Wallet & Balance
- **Simple Display**: Shows USDT and VND balances clearly
- **Deposit Button**: Add funds in USDT or VND
- **Withdraw Button**: Withdraw funds from your wallet
- **Clean UI**: Minimalist design without clutter

### 2. Core Functions
- **Deposit**: Easy deposit functionality for both USDT and VND
- **Withdraw**: Secure withdrawal process
- No unnecessary features - focused on essentials

### 3. Trading Mechanics
- **Maximum Leverage**: 500x (adjustable from 1x to 500x)
- **Two Position Modes**: Long (Buy) and Short (Sell)
- **Position Tracking**: Real-time P&L and ROE calculations
- **Position Closure**: Close positions at market price with instant settlement

### 4. Timeframe Support
Supported timeframes for analysis:
- 1 second (1s)
- 1 minute (1m)
- 3 minutes (3m)
- 5 minutes (5m)
- 15 minutes (15m)
- 30 minutes (30m)
- 1 hour (1h)
- 2 hours (2h)
- 4 hours (4h)
- 1 day (1d)

### 5. Technical Indicators (5 Essential Indicators)
1. **Volume**: Trading volume for each candle
2. **RSI (14)**: Relative Strength Index for overbought/oversold signals
3. **MACD**: Moving Average Convergence Divergence
4. **Bollinger Bands**: Upper, Middle, and Lower bands
5. **Moving Average (20)**: Simple moving average for trend analysis

### 6. Chart & Visuals
- **High-Quality Candlestick Charts**: Built with Syncfusion Charts
- **Real-Time Updates**: Charts update every 2 seconds with simulated price action
- **Interactive UI**: Touch-friendly controls and responsive design
- **Dark Theme**: Professional dark mode with green/red candlesticks
- **Technical Indicator Panel**: All indicators displayed in a compact, readable format

## Project Structure

```
lib/
├── crypto.dart                  # Standalone crypto app (optional)
├── models/
│   └── crypto_data.dart          # Data models and calculations
└── screens/
    └── crypto_home_screen.dart   # Main trading interface
```

## Key Components

### Wallet Class
Manages user balances in USDT and VND with deposit/withdraw methods.

### CandleData Class
Represents OHLCV (Open, High, Low, Close, Volume) candlestick data.

### TechnicalIndicators Class
Calculates all 5 technical indicators:
- RSI calculation with 14-period smoothing
- MACD with EMA(12) and EMA(26)
- Bollinger Bands with 20-period SMA and 2 standard deviations
- Simple Moving Average (20-period)
- Volume tracking

### TradePosition Class
Tracks open and closed trading positions with:
- Entry/exit price
- Position size and leverage
- P&L calculations
- ROE (Return on Equity) percentage

## How to Run

1. **Main Bank App (Recommended):**
   ```bash
   flutter run lib/main.dart
   ```
   This includes both banking features and crypto trading integrated.

2. **Standalone Crypto App (Optional):**
   ```bash
   flutter run lib/crypto.dart
   ```
   This runs only the crypto trading interface.

3. Ensure Syncfusion charts dependency is installed (already in pubspec.yaml)

## UI Flow

1. **Home Screen** - Displays wallet balance with Deposit/Withdraw buttons
2. **Symbol Selection** - Choose between BTC/USDT, ETH/USDT, or BNB/USDT
3. **Timeframe Selection** - Pick your preferred analysis timeframe
4. **Chart View** - Interactive candlestick chart with technical indicators
5. **Trading Panel** - Select Long/Short, set leverage (1-500x), enter position size
6. **Position Management** - View open positions with real-time P&L and close them

## Colors & Styling
- **Background**: Dark (#0F1419)
- **Cards**: Darker gray (#1A1F2E)
- **Primary**: Blue accent
- **Success**: Green (Long positions)
- **Danger**: Red (Short positions)

## Real-Time Features
- **Auto-updating Charts**: Simulated price action every 2 seconds
- **Live P&L Updates**: Position profits/losses update in real-time
- **Indicator Recalculation**: Technical indicators recalculate with new price data

## Limitations & Notes
- Prices are simulated (not real market data)
- All transactions are in-memory (demo purposes)
- Leverage up to 500x for educational demonstration
- Technical indicators are calculated on-the-fly

## Future Enhancements
- Real market data integration (Binance API)
- Order types (Market, Limit, Stop-Loss)
- Trade history and detailed analytics
- Multiple trading pairs
- Advanced charting tools
- Risk management features
- Account statistics and performance metrics

---

**Version**: 1.0  
**Last Updated**: April 29, 2026  
**Status**: Production Ready
