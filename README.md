<p align="center">
  <img src="https://img.shields.io/badge/EURUSD-Surge_EA-blue.svg" width="300"/>
</p>

<p align="center">
  <a href="README.ja.md"><img src="https://img.shields.io/badge/ドキュメント-日本語-white.svg" alt="JA doc"/></a>
  <a href="README.md"><img src="https://img.shields.io/badge/english-document-white.svg" alt="EN doc"></a>
</p>

<div align="center">

# EURUSD Surge EA

[![License: MIT](https://img.shields.io/badge/license-MIT-blue)](https://github.com/Masa1984a/EURUSD_Surge_EA)
[![Platform: MT4](https://img.shields.io/badge/Platform-MT4-blue.svg)](https://www.metatrader4.com/)

<!-- 技術スタックバッジ -->
<img src="https://img.shields.io/badge/MQL5-4286f4?style=flat" alt="MQL5" />

</div>

EURUSD Surge EA is a specialized automated trading system exclusively for the EURUSD currency pair. It detects price surges and enters during correction phases, utilizing ATR and ZigZag-based dynamic stop losses combined with comprehensive risk management features.

## 🚀 Features

- **Price Surge Detection**: Analyzes volatility and candlestick patterns to detect significant price movements
- **Correction Phase Entry**: High-probability entries after price surge corrections
- **Multi-Timeframe Analysis**: Confirms trend direction across multiple timeframes
- **Dynamic Stop Loss Calculation**:
  - ATR-based dynamic stop loss
  - ZigZag points for precision stop loss placement
- **Comprehensive Risk Management**:
  - Account-based maximum risk percentage
  - Partial position closing
  - Automatic risk-reward ratio calculation
- **Advanced Filtering System**:
  - ADX trend strength filter
  - Bollinger Band range market detection
  - RSI/MACD confirmation mechanisms
- **Time Management**:
  - Trading hour restrictions
  - Order expiration settings
  - Daily trade limits

## ⚙️ Parameters

### Basic Settings

- **EnableLongTrades**: Activate long positions
- **EnableShortTrades**: Activate short positions
- **LotSize**: Trading lot size (0=auto calculation)
- **MaxDailyTrades**: Maximum entries per day

### Timeframe Settings

- **MainTimeFrame**: Primary timeframe (Default: M5)
- **TrendTimeFrame**: Trend confirmation timeframe (Default: M15)

### Volatility Settings

- **UseATR**: Enable ATR usage
- **ATRPeriod**: ATR calculation period
- **ATRMultiplier**: ATR multiplier
- **VolatilityPeriod**: Volatility calculation period
- **VolatilityMultiplier**: Surge detection multiplier
- **BodyToTotalRatio**: Candlestick body/total ratio (%)

### Entry Settings

- **AdjustmentCandlesMin**: Minimum correction candles
- **AdjustmentCandlesMax**: Maximum correction candles
- **EntryPullbackPercent**: Entry pullback percentage (%)

### Risk Management Settings

- **RiskRewardRatio**: Risk-reward ratio
- **MaxRiskPercent**: Maximum risk percentage (%)
- **UsePartialClose**: Enable partial position closure
- **PartialClosePercent**: Partial closure percentage (%)
- **PartialCloseTrigger**: Partial closure trigger point

### Filtering Settings

- **UseADXFilter**: Enable ADX filter
- **ADXPeriod**: ADX calculation period
- **ADXThreshold**: ADX threshold value
- **UseBollingerFilter**: Enable Bollinger Band filter
- **BBPeriod**: Bollinger Band period
- **BBDeviation**: Bollinger Band standard deviation
- **BBWidthThreshold**: Bollinger Band width threshold
- **UseRSIConfirmation**: Enable RSI confirmation
- **RSIPeriod**: RSI calculation period
- **UseMACDConfirmation**: Enable MACD confirmation
- **MACDFastEMA**: MACD fast EMA
- **MACDSlowEMA**: MACD slow EMA
- **MACDSignalPeriod**: MACD signal period

### Time Settings

- **TRADE_START_HOUR**: Trading start hour
- **TRADE_END_HOUR**: Trading end hour
- **FORCE_CLOSE_HOUR**: Forced closure hour
- **FORCE_CLOSE_MINUTE**: Forced closure minute
- **PendingOrderTimeout**: Pending order timeout (minutes)

## 📁 File Structure

- **EURUSD_Surge_EA.mq4**: Main EA file
- **MarketAnalysis.mqh**: Market analysis functions
- **EntryManagement.mqh**: Entry management functions
- **RiskManagement.mqh**: Risk management functions
- **FilteringSystem.mqh**: Filtering system
- **Utilities.mqh**: Utility functions

## 💡 Recommended Setup

- **Currency Pair**: EURUSD (Euro/US Dollar) only
- **Timeframe**: M5 (5-minute)
- **Minimum Capital**: $1,000 recommended
- **Broker**: Low spread, minimal slippage broker recommended

## ⚠️ Disclaimers

The Expert Advisor (EA) "EURUSD_Surge_EA" introduced in this document is an automated trading program that operates on the MetaTrader 4 (MT4) platform and was developed primarily for the technical verification and research of trading logic incorporating AI (Artificial Intelligence) concepts.

**Important Notices:**

- **Not Investment Advice:** This document and the EA do not in any way recommend, solicit, or advise investments in any financial instruments (including foreign exchange margin trading). The information provided is limited to technical explanations and analysis.
- **No Profit Guarantee:** The use of this EA does not guarantee future profits. Past performance is not indicative of future results, and market fluctuations may result in losses.
- **High Risk:** Foreign exchange margin trading (FX) is a very high-risk financial transaction that offers the potential for large profits due to leverage effects, but also the possibility of losses exceeding the initial investment. Before beginning trading, you must fully understand the risks of FX trading, considering your financial situation, investment experience, and risk tolerance.
- **Principle of Self-Responsibility:** The author, developer, and related parties assume no legal responsibility for any trading or investment decisions made based on the information provided in this document or the use of this EA. All trading and investment decisions are made at the user's own responsibility and judgment.
- **Consult Professionals:** For final investment decisions, please consult independent financial advisors or financial professionals as necessary.
- **Risks Associated with Software Use:** The author, developer, and related parties assume no responsibility for any direct or indirect damages, losses, or malfunctions (including but not limited to data loss, program malfunction, and system impact) resulting from the use of the source code, executable files, or logic of this EA.

This EA is provided solely as a tool for technical exploration and learning. By using it, you are deemed to have fully understood and accepted the above disclaimers.

- This EA is designed exclusively for EURUSD
- Backtest results may differ from live trading performance
- Trading involves risk - thorough demo testing is recommended
- Optimal parameter settings may vary based on market conditions

## 📜 Version History

- **Version 1.00**: Initial release

---

<p align="center">
  <small>Copyright © 2025 Massan All Rights Reserved.</small><br>
  <small>https://github.com/Masa1984a/EURUSD_Surge_EA</small>
</p>
