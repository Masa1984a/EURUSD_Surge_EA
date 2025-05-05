//+------------------------------------------------------------------+
//|                                              EURUSD_Surge_EA.mq4 |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2025 Massan All Rights Reserved."
#property link      "https://github.com/Masa1984a/EURUSD_Surge_EA"
#property version   "0.01"
#property description "EURUSD専用の急騰急落検出型EAで、価格サージを利用した高精度エントリーを実現。ATR・ZigZagベースの動的SL、リスク管理機能搭載。プライスアクションにより、相場状況に応じた取引を行う。時間帯制限機能で効率的な取引が可能。"
#property strict

// 外部ファイルのインクルード
#include "MarketAnalysis.mqh"
#include "EntryManagement.mqh"
#include "RiskManagement.mqh"
#include "FilteringSystem.mqh"
#include "Utilities.mqh"

// 基本設定
extern string Basic_Settings = "===== 基本設定 =====";
extern bool   EnableLongTrades = true;        // ロングトレードを有効にする
extern bool   EnableShortTrades = true;       // ショートトレードを有効にする
extern double LotSize = 0;                    // 取引ロットサイズ (0=自動計算)
extern int    MaxDailyTrades = 4;             // 1日の最大エントリー回数 (旧:2)
extern string TimeFrame_Settings = "===== 時間足設定 =====";
extern int    MainTimeFrame = PERIOD_M5;      // メイン時間足
extern int    TrendTimeFrame = PERIOD_M15;    // トレンド確認用時間足

// ボラティリティ設定
extern string Volatility_Settings = "===== ボラティリティ設定 =====";
extern bool   UseATR = true;                  // ATRを使用する
extern int    ATRPeriod = 14;                 // ATR計算期間
extern double ATRMultiplier = 1.2;            // ATR乗数
extern int    VolatilityPeriod = 50;          // ボラティリティ計算期間（ATR未使用時）
extern double VolatilityMultiplier = 2.0;     // 平均ボラティリティの何倍を急騰/急落とするか
extern double BodyToTotalRatio = 40.0;        // ローソク足の実体/全体比率（%）

// エントリー設定
extern string Entry_Settings = "===== エントリー設定 =====";
extern int    AdjustmentCandlesMin = 1;       // 調整足の最小数
extern int    AdjustmentCandlesMax = 7;       // 調整足の最大数 
extern double EntryPullbackPercent = 40.0;    // エントリー引き付け率（%） 

// リスク管理設定
extern string Risk_Settings = "===== リスク管理設定 =====";
extern double RiskRewardRatio = 2.0;          // リスクリワード比 
extern double MaxRiskPercent = 2.0;           // 総資産に対する最大リスク率（％）
extern bool   UsePartialClose = true;         // 部分決済を使用する
extern double PartialClosePercent = 60.0;     // 部分決済の割合（%） 
extern double PartialCloseTrigger = 1.0;      // 部分決済トリガー（リスクの何倍で部分決済するか）

// フィルタリング設定
extern string Filter_Settings = "===== フィルタリング設定 =====";
extern bool   UseADXFilter = true;            // ADXフィルタを使用する
extern int    ADXPeriod = 14;                 // ADX計算期間
extern double ADXThreshold = 20.0;            // ADXしきい値（これ以上でトレンド相場と判断） (旧:25.0)
extern bool   UseBollingerFilter = true;      // ボリンジャーバンドフィルタを使用する
extern int    BBPeriod = 20;                  // ボリンジャーバンド計算期間
extern double BBDeviation = 2.0;              // ボリンジャーバンド標準偏差
extern double BBWidthThreshold = 0.015;       // ボリンジャーバンド幅しきい値（これ以下でレンジ相場と判断） (旧:0.01)
extern bool   UseRSIConfirmation = true;      // RSI確認を使用する
extern int    RSIPeriod = 14;                 // RSI計算期間
extern bool   UseMACDConfirmation = true;     // MACD確認を使用する
extern int    MACDFastEMA = 12;               // MACD速いEMA
extern int    MACDSlowEMA = 26;               // MACD遅いEMA
extern int    MACDSignalPeriod = 9;           // MACDシグナル期間

// 取引時間設定
extern string Time_Settings = "===== 取引時間設定 =====";
extern int    TRADE_START_HOUR = 8;           // 取引開始時間（時）
extern int    TRADE_END_HOUR = 22;            // 取引終了時間（時）
extern int    FORCE_CLOSE_HOUR = 23;          // 強制決済時間（時）
extern int    FORCE_CLOSE_MINUTE = 30;        // 強制決済時間（分）
extern int    PendingOrderTimeout = 120;      // 指値注文の有効時間（分） (旧:60)

// グローバル変数
string g_Symbol = "EURUSD";                   // 対象通貨ペア
int g_TodayTrades = 0;                        // 今日の取引回数
datetime g_LastTradeTime = 0;                 // 最後の取引時間
int g_TicketLong = 0;                         // ロングポジションのチケット番号
int g_TicketShort = 0;                        // ショートポジションのチケット番号
bool g_PendingLongDetected = false;           // ロングエントリーポイント検出フラグ
bool g_PendingShortDetected = false;          // ショートエントリーポイント検出フラグ
datetime g_SurgeStartTime = 0;                // 急騰/急落の開始時間
double g_SurgeStartPrice = 0;                 // 急騰/急落の開始価格
double g_SurgeEndPrice = 0;                   // 急騰/急落の終了価格
int g_SurgeDirection = 0;                     // 急騰/急落の方向（1=上昇、-1=下降）
int g_AdjustmentCount = 0;                    // 調整足のカウント
bool g_SurgeDetected = false;                 // 急騰/急落検出フラグ
datetime g_LongOrderTime = 0;                 // ロング指値注文の発注時間
datetime g_ShortOrderTime = 0;                // ショート指値注文の発注時間
bool g_PartialCloseSet = false;               // 部分決済設定フラグ
double g_PartialCloseTriggerPrice = 0;        // 部分決済トリガー価格
int g_PartialCloseDirection = 0;              // 部分決済方向

// ブローカー対応用の変数
double g_pipPoint;                            // ブローカー対応用のポイント値

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    // 通貨ペアの確認
    if(Symbol() != g_Symbol)
    {
        LogError("このEAは" + g_Symbol + "専用です。現在の通貨ペア: " + Symbol());
        return INIT_FAILED;
    }
    
    // 時間足の確認
    if(Period() != MainTimeFrame)
    {
        LogError("このEAは" + IntegerToString(MainTimeFrame) + "分足専用です。現在の時間足: " + IntegerToString(Period()));
        return INIT_FAILED;
    }
    
    // 5桁/3桁ブローカー対応
    g_pipPoint = Point;
    if(Digits == 5 || Digits == 3)
    {
        g_pipPoint = Point * 10;
    }
    
    // 変数の初期化
    ResetDailyCounters();
    
    // ブローカー情報を出力
    LogInfo("EURUSD Surge EA Advanced Improved 初期化完了 - V2.20");
    LogInfo("ブローカー情報:");
    LogInfo("最小ストップロス距離: " + DoubleToString(MarketInfo(g_Symbol, MODE_STOPLEVEL), 0) + " ポイント");
    LogInfo("ティック値: " + DoubleToString(MarketInfo(g_Symbol, MODE_TICKVALUE), 5));
    LogInfo("ティックサイズ: " + DoubleToString(MarketInfo(g_Symbol, MODE_TICKSIZE), 5));
    LogInfo("Digits: " + IntegerToString(Digits));
    LogInfo("Point: " + DoubleToString(Point, Digits));
    LogInfo("計算用pipPoint: " + DoubleToString(g_pipPoint, Digits));
    LogInfo("Ask: " + DoubleToString(Ask, Digits) + ", Bid: " + DoubleToString(Bid, Digits));
    
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    // 終了時の処理
    LogInfo("EURUSD Surge EA Advanced Improved 終了: 理由コード=" + IntegerToString(reason));
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // 新しい日の開始時にカウンターをリセット
    if(IsNewDay())
    {
        ResetDailyCounters();
        LogInfo("新しい日を検出: カウンターをリセットしました");
    }
    
    // 強制決済時間なら全ポジションを決済
    if(IsForceCloseTime())
    {
        CloseAllPositions(g_Symbol);
        LogInfo("強制決済時間: すべてのポジションを決済しました");
        return;
    }
    
    // 指値注文の管理
    ManagePendingOrders(g_Symbol);
    
    // 部分決済の管理
    if(UsePartialClose)
    {
        CheckAndExecutePartialClose(g_Symbol);
    }
    
    // 取引時間外なら処理しない
    if(!IsTradeTime())
    {
        return;
    }
    
    // 新しいローソク足が完成した時のみ処理
    if(!IsNewBar(g_Symbol, MainTimeFrame))
    {
        return;
    }
    
    // 既に最大取引回数に達している場合は処理しない
    if(g_TodayTrades >= MaxDailyTrades)
    {
        return;
    }
    
    // 既にポジションがある場合は処理しない（重複エントリー防止）
    if(HasOpenPositions(g_Symbol) || HasPendingOrders(g_Symbol))
    {
        return;
    }
    
    // 市場状況をチェック
    if(!ShouldTradeInCurrentMarket(g_Symbol, MainTimeFrame))
    {
        return;
    }
    
    // 急騰・急落の検知
    if(!g_SurgeDetected)
    {
        if(DetectPriceSurge(g_Symbol, MainTimeFrame, g_SurgeDirection, g_SurgeStartPrice, g_SurgeEndPrice, g_SurgeStartTime))
        {
            g_SurgeDetected = true;
            g_AdjustmentCount = 0;
        }
    }
    // 急騰・急落後の調整と再エントリーポイントの検知
    else
    {
        // 調整足のカウントを増やす
        g_AdjustmentCount++;
        
        // 調整足が最大数を超えた場合はリセット
        if(g_AdjustmentCount > AdjustmentCandlesMax)
        {
            ResetSurgeDetection();
            LogInfo("調整足が最大数を超えました: 検出をリセットします");
            return;
        }
        
        // 調整が完了したかどうかをチェック
        if(IsAdjustmentComplete(g_Symbol, MainTimeFrame, g_AdjustmentCount, g_SurgeDirection))
        {
            double entryPrice = 0;
            double stopLoss = 0;
            double takeProfit = 0;
            
            // 再エントリーポイントを検出
            if(DetectReentryPoint(g_Symbol, MainTimeFrame, g_SurgeDirection, g_SurgeStartPrice, g_SurgeEndPrice, 
                                 entryPrice, stopLoss, takeProfit))
            {
                // ポジションサイズを計算
                double stopLossDistance = MathAbs(entryPrice - stopLoss);
                double lotSize = CalculatePositionSize(g_Symbol, stopLossDistance);
                
                int ticket = -1;
                
                // 指値注文を出す
                if(g_SurgeDirection > 0 && EnableLongTrades) // ロング
                {
                    // 買いトレード用のストップロス調整
                    double adjustedStopLoss = CalculateDynamicStopLoss(g_Symbol, MainTimeFrame, g_SurgeDirection, entryPrice, g_SurgeStartPrice);
                    
                    // SLが0の場合は取引を見送る（ZigZagポイントが見つからず、フォールバックも無効の場合）
                    if(adjustedStopLoss == 0)
                    {
                        LogWarning("ロング注文見送り: 有効なストップロス価格が計算できませんでした");
                        return;
                    }
                    
                    ticket = SendOrderWithRetry(OP_BUYLIMIT, lotSize, entryPrice, 3, adjustedStopLoss, takeProfit, 
                                              "EURUSD Surge EA Advanced Improved", 0, 0, Green);
                    
                    if(ticket > 0)
                    {
                        g_TicketLong = ticket;
                        g_LongOrderTime = TimeCurrent();
                        g_PendingLongDetected = true;
                        
                        // 部分決済の設定
                        if(UsePartialClose)
                        {
                            SetupPartialClose(g_Symbol, ticket, entryPrice, adjustedStopLoss, g_SurgeDirection);
                        }
                        
                        LogInfo("ロング指値注文設定: エントリー=" + DoubleToString(entryPrice, Digits) + 
                               " (引き付け率:" + DoubleToString(EntryPullbackPercent, 1) + "%), 損切=" + 
                               DoubleToString(adjustedStopLoss, Digits) + ", 利確=" + DoubleToString(takeProfit, Digits) + 
                               ", ロット=" + DoubleToString(lotSize, 2));
                    }
                    else
                    {
                        LogError("ロング指値注文エラー: " + GetLastErrorText(GetLastError()) + 
                                " 価格=" + DoubleToString(entryPrice, Digits) + 
                                " SL=" + DoubleToString(adjustedStopLoss, Digits) + 
                                " TP=" + DoubleToString(takeProfit, Digits));
                    }
                }
                else if(g_SurgeDirection < 0 && EnableShortTrades) // ショート
                {
                    // 売りトレード用のストップロス調整
                    double adjustedStopLoss = CalculateDynamicStopLoss(g_Symbol, MainTimeFrame, g_SurgeDirection, entryPrice, g_SurgeStartPrice);
                    
                    // SLが0の場合は取引を見送る（ZigZagポイントが見つからず、フォールバックも無効の場合）
                    if(adjustedStopLoss == 0)
                    {
                        LogWarning("ショート注文見送り: 有効なストップロス価格が計算できませんでした");
                        return;
                    }
                    
                    ticket = SendOrderWithRetry(OP_SELLLIMIT, lotSize, entryPrice, 3, adjustedStopLoss, takeProfit, 
                                              "EURUSD Surge EA Advanced Improved", 0, 0, Red);
                    
                    if(ticket > 0)
                    {
                        g_TicketShort = ticket;
                        g_ShortOrderTime = TimeCurrent();
                        g_PendingShortDetected = true;
                        
                        // 部分決済の設定
                        if(UsePartialClose)
                        {
                            SetupPartialClose(g_Symbol, ticket, entryPrice, adjustedStopLoss, g_SurgeDirection);
                        }
                        
                        LogInfo("ショート指値注文設定: エントリー=" + DoubleToString(entryPrice, Digits) + 
                               " (引き付け率:" + DoubleToString(EntryPullbackPercent, 1) + "%), 損切=" + 
                               DoubleToString(adjustedStopLoss, Digits) + ", 利確=" + DoubleToString(takeProfit, Digits) + 
                               ", ロット=" + DoubleToString(lotSize, 2));
                    }
                    else
                    {
                        LogError("ショート指値注文エラー: " + GetLastErrorText(GetLastError()) + 
                                " 価格=" + DoubleToString(entryPrice, Digits) + 
                                " SL=" + DoubleToString(adjustedStopLoss, Digits) + 
                                " TP=" + DoubleToString(takeProfit, Digits));
                    }
                }
                
                // 注文が成功したらリセット
                if(ticket > 0)
                {
                    g_SurgeDetected = false;
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| 全ポジションを決済する関数                                        |
//+------------------------------------------------------------------+
void CloseAllPositions(string symbol)
{
    bool success = true;
    
    for(int i = OrdersTotal() - 1; i >= 0; i--)
    {
        if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            if(OrderSymbol() == symbol)
            {
                // 買いポジションの決済
                if(OrderType() == OP_BUY)
                {
                    if(!OrderClose(OrderTicket(), OrderLots(), Bid, 3, White))
                    {
                        LogError("買いポジション決済エラー: " + GetLastErrorText(GetLastError()));
                        success = false;
                    }
                }
                // 売りポジションの決済
                else if(OrderType() == OP_SELL)
                {
                    if(!OrderClose(OrderTicket(), OrderLots(), Ask, 3, White))
                    {
                        LogError("売りポジション決済エラー: " + GetLastErrorText(GetLastError()));
                        success = false;
                    }
                }
                // 指値注文のキャンセル
                else if(OrderType() == OP_BUYLIMIT || OrderType() == OP_SELLLIMIT)
                {
                    if(!DeleteOrderWithRetry(OrderTicket()))
                    {
                        LogError("指値注文キャンセルエラー: " + GetLastErrorText(GetLastError()));
                        success = false;
                    }
                }
            }
        }
    }
    
    if(success)
    {
        LogInfo("すべてのポジションを正常に決済しました");
    }
}

//+------------------------------------------------------------------+
//| 指値注文を管理する関数                                            |
//+------------------------------------------------------------------+
void ManagePendingOrders(string symbol)
{
    // 指値注文が約定したかチェック
    if(g_PendingLongDetected || g_PendingShortDetected)
    {
        bool orderExecuted = false;
        
        for(int i = 0; i < OrdersTotal(); i++)
        {
            if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
            {
                // 注文が約定した場合
                if((OrderType() == OP_BUY && OrderTicket() == g_TicketLong) ||
                   (OrderType() == OP_SELL && OrderTicket() == g_TicketShort))
                {
                    // 取引回数をカウントアップ
                    g_TodayTrades++;
                    g_LastTradeTime = TimeCurrent();
                    orderExecuted = true;
                    
                    LogInfo("注文約定: チケット=" + IntegerToString(OrderTicket()) + 
                           ", タイプ=" + IntegerToString(OrderType()) + 
                           ", 価格=" + DoubleToString(OrderOpenPrice(), Digits));
                    break;
                }
            }
        }
        
        if(orderExecuted)
        {
            // 検出フラグをリセット
            ResetSurgeDetection();
            return;
        }
        
        // 指値注文が存在するかチェック
        bool longExists = false;
        bool shortExists = false;
        datetime currentTime = TimeCurrent();
        
        for(int i = 0; i < OrdersTotal(); i++)
        {
            if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
            {
                if(OrderType() == OP_BUYLIMIT && OrderTicket() == g_TicketLong)
                {
                    longExists = true;
                    
                    // 指値注文の有効時間をチェック
                    if(g_LongOrderTime > 0 && (currentTime - g_LongOrderTime) / 60 >= PendingOrderTimeout)
                    {
                        // 有効時間が経過したのでキャンセル
                        if(DeleteOrderWithRetry(g_TicketLong))
                        {
                            LogInfo("ロング指値注文タイムアウト: " + IntegerToString(PendingOrderTimeout) + 
                                   "分経過したためキャンセルしました");
                            g_PendingLongDetected = false;
                            g_LongOrderTime = 0;
                            g_TicketLong = 0;
                        }
                        else
                        {
                            LogError("ロング指値注文キャンセルエラー: " + GetLastErrorText(GetLastError()));
                        }
                    }
                }
                else if(OrderType() == OP_SELLLIMIT && OrderTicket() == g_TicketShort)
                {
                    shortExists = true;
                    
                    // 指値注文の有効時間をチェック
                    if(g_ShortOrderTime > 0 && (currentTime - g_ShortOrderTime) / 60 >= PendingOrderTimeout)
                    {
                        // 有効時間が経過したのでキャンセル
                        if(DeleteOrderWithRetry(g_TicketShort))
                        {
                            LogInfo("ショート指値注文タイムアウト: " + IntegerToString(PendingOrderTimeout) + 
                                   "分経過したためキャンセルしました");
                            g_PendingShortDetected = false;
                            g_ShortOrderTime = 0;
                            g_TicketShort = 0;
                        }
                        else
                        {
                            LogError("ショート指値注文キャンセルエラー: " + GetLastErrorText(GetLastError()));
                        }
                    }
                }
            }
        }
        
        // 指値注文が存在しない場合はフラグをリセット
        if(g_PendingLongDetected && !longExists)
        {
            g_PendingLongDetected = false;
            g_LongOrderTime = 0;
            LogInfo("ロング指値注文が存在しません: フラグをリセットします");
        }
        
        if(g_PendingShortDetected && !shortExists)
        {
            g_PendingShortDetected = false;
            g_ShortOrderTime = 0;
            LogInfo("ショート指値注文が存在しません: フラグをリセットします");
        }
    }
}

//+------------------------------------------------------------------+
//| 急騰・急落検知のリセット関数                                      |
//+------------------------------------------------------------------+
void ResetSurgeDetection()
{
    g_SurgeDetected = false;
    g_SurgeDirection = 0;
    g_SurgeStartTime = 0;
    g_SurgeStartPrice = 0;
    g_SurgeEndPrice = 0;
    g_AdjustmentCount = 0;
    g_PendingLongDetected = false;
    g_PendingShortDetected = false;
    g_LongOrderTime = 0;
    g_ShortOrderTime = 0;
}

//+------------------------------------------------------------------+
//| 日次カウンターのリセット関数                                      |
//+------------------------------------------------------------------+
void ResetDailyCounters()
{
    g_TodayTrades = 0;
    g_LastTradeTime = 0;
    ResetSurgeDetection();
}

//+------------------------------------------------------------------+
//| オープンポジションがあるかどうかをチェックする関数                |
//+------------------------------------------------------------------+
bool HasOpenPositions(string symbol)
{
    for(int i = 0; i < OrdersTotal(); i++)
    {
        if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            if(OrderSymbol() == symbol && (OrderType() == OP_BUY || OrderType() == OP_SELL))
            {
                return true;
            }
        }
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| 未決済の指値注文があるかどうかをチェックする関数                  |
//+------------------------------------------------------------------+
bool HasPendingOrders(string symbol)
{
    for(int i = 0; i < OrdersTotal(); i++)
    {
        if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            if(OrderSymbol() == symbol && (OrderType() == OP_BUYLIMIT || OrderType() == OP_SELLLIMIT))
            {
                return true;
            }
        }
    }
    
    return false;
}
