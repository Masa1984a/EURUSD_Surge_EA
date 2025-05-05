<p align="center">
  <img src="https://img.shields.io/badge/EURUSD-Surge_EA-blue.svg" width="300"/>
</p>

<p align="center">
  <a href="README.ja.md"><img src="https://img.shields.io/badge/ドキュメント-日本語-white.svg" alt="JA doc"/></a>
  <a href="README.md"><img src="https://img.shields.io/badge/english-document-white.svg" alt="EN doc"></a>
</p>

<div align="center">

# EURUSD Surge EA (日本語版)

[![License: MIT](https://img.shields.io/badge/license-MIT-blue)](https://github.com/Masa1984a/EURUSD_Surge_EA)
[![Platform: MT4](https://img.shields.io/badge/Platform-MT4-blue.svg)](https://www.metatrader4.com/)

<!-- 技術スタックバッジ -->
<img src="https://img.shields.io/badge/MQL5-4286f4?style=flat" alt="MQL5" />

</div>

EURUSD Surge EA は、EURUSD（ユーロ/米ドル）通貨ペア専用の高精度自動売買システム（EA）です。急騰急落検出型 EA で、価格サージを利用した高精度エントリーを実現。ATR・ZigZag ベースの動的 SL、リスク管理機能搭載。プライスアクションにより、相場状況に応じた取引を行う。時間帯制限機能で効率的な取引が可能。

## 🚀 機能

- **価格サージ検出**: ボラティリティやローソク足パターンに基づいて急騰・急落を検出
- **調整局面エントリー**: サージ後の調整局面で高確率エントリーを実行
- **マルチタイムフレーム分析**: 複数時間足を分析してトレンド方向を確認
- **動的ストップロス計算**:
  - ATR ベースの動的ストップロス
  - ZigZag ポイントを利用した高精度なストップロス設定
- **包括的リスク管理機能**:
  - 資金に対する最大リスク率設定
  - 部分決済機能
  - リスクリワード比の自動計算
- **高度フィルタリングシステム**:
  - ADX によるトレンド強度フィルター
  - ボリンジャーバンドによるレンジ相場検出
  - RSI/MACD による確認機能
- **時間管理機能**:
  - 取引時間制限
  - 注文の有効時間設定
  - 日次取引制限

## ⚙️ パラメーター設定

### 基本設定

- **EnableLongTrades**: ロング（買い）ポジションの有効化
- **EnableShortTrades**: ショート（売り）ポジションの有効化
- **LotSize**: 取引ロットサイズ（0=自動計算）
- **MaxDailyTrades**: 1 日の最大エントリー回数

### 時間足設定

- **MainTimeFrame**: メイン時間足（デフォルト: M5）
- **TrendTimeFrame**: トレンド確認用時間足（デフォルト: M15）

### ボラティリティ設定

- **UseATR**: ATR 使用の有無
- **ATRPeriod**: ATR 計算期間
- **ATRMultiplier**: ATR 乗数
- **VolatilityPeriod**: ボラティリティ計算期間
- **VolatilityMultiplier**: 平均ボラティリティに対する急騰・急落判定の倍率
- **BodyToTotalRatio**: ローソク足の実体/全体比率（%）

### エントリー設定

- **AdjustmentCandlesMin**: 調整足の最小数
- **AdjustmentCandlesMax**: 調整足の最大数
- **EntryPullbackPercent**: エントリー引き付け率（%）

### リスク管理設定

- **RiskRewardRatio**: リスクリワード比
- **MaxRiskPercent**: 総資産に対する最大リスク率（%）
- **UsePartialClose**: 部分決済の有効化
- **PartialClosePercent**: 部分決済の割合（%）
- **PartialCloseTrigger**: 部分決済トリガー

### フィルタリング設定

- **UseADXFilter**: ADX フィルターの使用
- **ADXPeriod**: ADX 計算期間
- **ADXThreshold**: ADX しきい値
- **UseBollingerFilter**: ボリンジャーバンドフィルターの使用
- **BBPeriod**: ボリンジャーバンド計算期間
- **BBDeviation**: ボリンジャーバンド標準偏差
- **BBWidthThreshold**: ボリンジャーバンド幅しきい値
- **UseRSIConfirmation**: RSI 確認の使用
- **RSIPeriod**: RSI 計算期間
- **UseMACDConfirmation**: MACD 確認の使用
- **MACDFastEMA**: MACD 速い EMA
- **MACDSlowEMA**: MACD 遅い EMA
- **MACDSignalPeriod**: MACD シグナル期間

### 時間設定

- **TRADE_START_HOUR**: 取引開始時間（時）
- **TRADE_END_HOUR**: 取引終了時間（時）
- **FORCE_CLOSE_HOUR**: 強制決済時間（時）
- **FORCE_CLOSE_MINUTE**: 強制決済時間（分）
- **PendingOrderTimeout**: 指値注文の有効時間（分）

## 📁 ファイル構成

- **EURUSD_Surge_EA.mq4**: メインの EA ファイル
- **MarketAnalysis.mqh**: 市場分析機能
- **EntryManagement.mqh**: エントリー管理機能
- **RiskManagement.mqh**: リスク管理機能
- **FilteringSystem.mqh**: フィルタリングシステム
- **Utilities.mqh**: ユーティリティ関数

## 💡 推奨設定

- **取引通貨ペア**: EURUSD（ユーロ/米ドル）専用
- **時間足**: M5（5 分足）
- **最小資金**: 1000 ドル推奨
- **ブローカー**: スプレッドが低く、スリッページの少ない業者を推奨

## ⚠️ 免責事項

本記事で紹介する Expert Advisor（EA）「EURUSD_Surge_EA」は、MetaTrader 4（MT4）プラットフォーム上で動作する自動売買プログラムであり、AI（人工知能）の概念を取り入れた取引ロジックの技術的な検証および研究を主目的として開発されました。

**重要なご注意：**

- **投資助言ではありません：** 本記事および本 EA は、特定の金融商品（外国為替証拠金取引を含む）への投資を推奨、勧誘、または助言するものでは一切ありません。記載されている情報は、あくまで技術的な解説と分析に留まります。
- **利益を保証するものではありません：** 本 EA の使用によって将来的に利益が得られることを保証するものではありません。過去のパフォーマンスは将来の結果を示すものではなく、市場の変動により損失が発生する可能性があります。
- **高いリスクについて：** 外国為替証拠金取引（FX）は、レバレッジ効果により大きな利益を得る可能性がある一方で、投資元本を上回る損失を被る可能性もある、非常にリスクの高い金融取引です。取引を開始する前に、ご自身の財務状況、投資経験、リスク許容度を十分に考慮し、FX 取引のリスクを完全に理解する必要があります。
- **自己責任の原則：** 本記事で提供される情報、および本 EA の利用に基づいて行われたいかなる取引や投資判断の結果についても、著者、開発者、および関係者は一切の法的責任を負いません。すべての取引および投資判断は、利用者ご自身の責任と判断において行ってください。
- **専門家への相談：** 投資に関する最終的な決定は、必要に応じて独立したファイナンシャルアドバイザーや金融の専門家にご相談の上、慎重に行ってください。
- **ソフトウェア利用に伴うリスク：** 本 EA のソースコード、実行ファイル、またはそのロジックを利用したことによって生じたいかなる直接的・間接的な損害、損失、不具合（データの損失、プログラムの誤動作、システムへの影響などを含むがこれらに限定されない）についても、著者、開発者、および関係者は一切の責任を負いません。

本 EA は、あくまで技術的な探求と学習のためのツールとして提供されるものです。その利用にあたっては、上記免責事項を十分にご理解、ご承諾いただいたものとみなします。

## ⚠️ 注意事項

- 本 EA は EURUSD 専用に設計されています
- バックテストと実運用では結果が異なる場合があります
- 取引にはリスクが伴いますので、デモ口座での十分な検証をお勧めします
- パラメーター設定は市場環境によって最適値が変化する場合があります

## 📜 バージョン履歴

- **バージョン 1.00**: 初回リリース

---

<p align="center">
  <small>Copyright © 2025 Massan All Rights Reserved.</small><br>
  <small>https://github.com/Masa1984a/EURUSD_Surge_EA</small>
</p>
