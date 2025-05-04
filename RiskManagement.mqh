//+------------------------------------------------------------------+
//|                                               RiskManagement.mqh |
//|                                                                   |
//|                                                                   |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025"
#property strict

//+------------------------------------------------------------------+
//| グローバル変数/パラメータの宣言                                    |
//+------------------------------------------------------------------+

// ストップロス設定
extern int StopLossPips = 50;         // ストップロス距離（ピップ）
extern double StopLossAdjustment = 1.0; // ストップロス調整係数

// ZigZagベースのストップロス設定
extern bool UseZigZagStopLoss = true;           // ZigZagベースSLを使用する
extern int ZigZagTimeFrame = PERIOD_M1;         // ZigZag計算に使用する時間足
extern int ZigZagDepth = 12;                    // ZigZagの ExtDepth パラメータ
extern int ZigZagDeviation = 5;                 // ZigZagの ExtDeviation パラメータ
extern int ZigZagBackstep = 3;                  // ZigZagの ExtBackstep パラメータ
extern double ZigZagBufferPercent = 15.0;       // ZigZagポイントとエントリー価格の距離に対するバッファ率（%）
extern int ZigZagMaxLookback = 100;             // ZigZagポイントを探す最大遡及バー数
extern bool ZigZagFallbackToDefaultSL = true;   // ZigZagポイントが見つからない場合にデフォルトSLロジックを使用する

//+------------------------------------------------------------------+
//| ポジションサイジング関連の関数                                     |
//+------------------------------------------------------------------+

// リスク率に基づいたポジションサイズを計算
double CalculatePositionSize(string symbol, double stopLossDistance)
{
    // リスク額を計算（口座残高の一定割合）
    double riskAmount = AccountEquity() * (MaxRiskPercent / 100.0);
    
    // 1ピップあたりの価値を取得
    double tickValue = MarketInfo(symbol, MODE_TICKVALUE);
    double tickSize = MarketInfo(symbol, MODE_TICKSIZE);
    double pipValue = tickValue * (Point / tickSize);
    
    // ストップロス距離をピップに変換
    double stopLossPips = stopLossDistance / Point;
    
    // ロットサイズを計算
    double lotSize = 0;
    if(stopLossPips > 0 && pipValue > 0)
    {
        lotSize = NormalizeDouble(riskAmount / (stopLossPips * pipValue), 2);
    }
    
    // 最大/最小ロットサイズの確認
    double minLot = MarketInfo(symbol, MODE_MINLOT);
    double maxLot = MarketInfo(symbol, MODE_MAXLOT);
    double lotStep = MarketInfo(symbol, MODE_LOTSTEP);
    
    // ロットサイズの調整
    lotSize = MathMax(minLot, MathMin(maxLot, lotSize));
    lotSize = NormalizeDouble(lotSize / lotStep, 0) * lotStep;
    
    // 手動設定のロットサイズがある場合はそれを使用
    if(LotSize > 0)
    {
        lotSize = LotSize;
    }
    
    return lotSize;
}

//+------------------------------------------------------------------+
//| ストップロス計算関連の関数                                         |
//+------------------------------------------------------------------+

// 動的なストップロスを計算
double CalculateDynamicStopLoss(string symbol, int timeframe, int direction, double entryPrice, double surgeStartPrice)
{
    double stopLoss = 0;
    
    // ZigZagベースのストップロス計算が有効で、それを使用するかどうか
    if(UseZigZagStopLoss)
    {
        // ZigZagに基づいたストップロス計算
        stopLoss = GetZigZagBasedStopLoss(symbol, direction, entryPrice);
        
        // ZigZagポイントが見つからないか、計算結果が不正な場合
        if(stopLoss == 0 && ZigZagFallbackToDefaultSL)
        {
            LogInfo("ZigZagベースのSLがフォールバックします。代替SL計算を使用します。");
            
            // 代替計算にフォールバック
            if(UseATR)
            {
                // ATRに基づくストップロス
                stopLoss = GetATRBasedStopLoss(symbol, timeframe, direction, entryPrice);
            }
            else
            {
                // 急騰・急落の起点に基づくストップロス
                double pipPoint = Point;
                if(Digits == 5 || Digits == 3)
                {
                    pipPoint = Point * 10;
                }
                
                if(direction > 0) // ロング
                {
                    stopLoss = NormalizeDouble(surgeStartPrice - (StopLossPips * StopLossAdjustment * pipPoint), Digits);
                }
                else // ショート
                {
                    stopLoss = NormalizeDouble(surgeStartPrice + (StopLossPips * StopLossAdjustment * pipPoint), Digits);
                }
            }
        }
        else if(stopLoss == 0 && !ZigZagFallbackToDefaultSL)
        {
            // ZigZagに基づくSLが見つからず、フォールバックしない設定の場合
            LogWarning("ZigZagベースのSLが計算できず、フォールバックが無効です。注文は見送られます。");
            return 0; // 0を返すことで呼び出し元で処理を判断できる
        }
    }
    else if(UseATR)
    {
        // ATRに基づくストップロス
        stopLoss = GetATRBasedStopLoss(symbol, timeframe, direction, entryPrice);
    }
    else
    {
        // 急騰・急落の起点に基づくストップロス
        double pipPoint = Point;
        if(Digits == 5 || Digits == 3)
        {
            pipPoint = Point * 10;
        }
        
        if(direction > 0) // ロング
        {
            stopLoss = NormalizeDouble(surgeStartPrice - (StopLossPips * StopLossAdjustment * pipPoint), Digits);
        }
        else // ショート
        {
            stopLoss = NormalizeDouble(surgeStartPrice + (StopLossPips * StopLossAdjustment * pipPoint), Digits);
        }
    }
    
    // ブローカーの最小ストップロス距離を取得
    int minStopLevel = (int)MarketInfo(symbol, MODE_STOPLEVEL);
    // 安全マージンを追加（10ポイント追加）
    int safeStopDistance = minStopLevel + 10;
    
    // 現在のストップロス距離をチェック
    double currentStopDistance = MathAbs(entryPrice - stopLoss) / Point;
    
    // 最小ストップロス距離より近い場合は調整
    if(stopLoss != 0 && currentStopDistance < safeStopDistance)
    {
        LogWarning("警告: ストップロス距離が不足しています: " + DoubleToString(currentStopDistance, 0) + 
                  " < " + IntegerToString(safeStopDistance));
        
        if(direction > 0) // ロング
        {
            stopLoss = NormalizeDouble(entryPrice - (safeStopDistance * Point), Digits);
        }
        else // ショート
        {
            stopLoss = NormalizeDouble(entryPrice + (safeStopDistance * Point), Digits);
        }
        
        LogInfo("最小距離を確保するためストップロスを調整しました: " + DoubleToString(stopLoss, Digits));
    }
    
    return stopLoss;
}

// ATRに基づくストップロスを計算
double GetATRBasedStopLoss(string symbol, int timeframe, int direction, double entryPrice)
{
    double atr = iATR(symbol, timeframe, ATRPeriod, 1);
    double stopDistance = atr * ATRMultiplier;
    
    if(direction > 0) // ロング
    {
        return NormalizeDouble(entryPrice - stopDistance, Digits);
    }
    else // ショート
    {
        return NormalizeDouble(entryPrice + stopDistance, Digits);
    }
}

// ZigZagに基づくストップロスを計算
double GetZigZagBasedStopLoss(string symbol, int direction, double entryPrice)
{
    datetime zzTime = 0;
    double zzPrice = 0;
    double stopLoss = 0;
    
    // ZigZagポイントを探す
    bool foundZigZag = FindRecentZigZagPoint(symbol, ZigZagTimeFrame, direction, zzPrice, zzTime);
    
    if(foundZigZag && zzPrice > 0)
    {
        // エントリー価格とZigZagポイントの距離を計算
        double distance = MathAbs(entryPrice - zzPrice);
        
        // バッファ値を計算（距離の指定パーセンテージ）
        double bufferValue = distance * (ZigZagBufferPercent / 100.0);
        
        // SL価格を決定
        if(direction > 0) // ロング（買い）
        {
            stopLoss = NormalizeDouble(zzPrice - bufferValue, Digits);
            
            // 念のため：SLがエントリー価格より大きくないことを確認（不正なSL）
            if(stopLoss >= entryPrice)
            {
                LogWarning("警告: ZigZagベースのSLがエントリー価格を上回っています（ロング）。SL: " + 
                          DoubleToString(stopLoss, Digits) + ", エントリー: " + DoubleToString(entryPrice, Digits));
                return 0; // 不正なSLなので0を返してフォールバック処理をトリガー
            }
        }
        else // ショート（売り）
        {
            stopLoss = NormalizeDouble(zzPrice + bufferValue, Digits);
            
            // 念のため：SLがエントリー価格より小さくないことを確認（不正なSL）
            if(stopLoss <= entryPrice)
            {
                LogWarning("警告: ZigZagベースのSLがエントリー価格を下回っています（ショート）。SL: " + 
                          DoubleToString(stopLoss, Digits) + ", エントリー: " + DoubleToString(entryPrice, Digits));
                return 0; // 不正なSLなので0を返してフォールバック処理をトリガー
            }
        }
        
        LogInfo("ZigZagベースのSL計算: ZigZagポイント=" + DoubleToString(zzPrice, Digits) + 
               ", 距離=" + DoubleToString(distance, Digits) + 
               ", バッファ値=" + DoubleToString(bufferValue, Digits) + 
               ", SL=" + DoubleToString(stopLoss, Digits));
        
        return stopLoss;
    }
    
    // ZigZagポイントが見つからない場合
    LogWarning("ZigZagポイントが見つかりませんでした。代替SLにフォールバックします。");
    return 0; // 見つからない場合は0を返してフォールバック処理をトリガー
}

// 直近のZigZagポイント（高値/安値）を探す
bool FindRecentZigZagPoint(string symbol, int timeframe, int direction, double &zzPoint, datetime &zzTime)
{
    // ZigZagバッファの配列
    double zigzagBuffer[];
    datetime timeBuffer[];
    
    // 配列サイズを設定
    ArrayResize(zigzagBuffer, ZigZagMaxLookback);
    ArrayResize(timeBuffer, ZigZagMaxLookback);
    ArrayInitialize(zigzagBuffer, 0.0);
    
    // ZigZagの計算
    int handle = iCustom(symbol, timeframe, "ZigZag", ZigZagDepth, ZigZagDeviation, ZigZagBackstep);
    
    if(handle == INVALID_HANDLE)
    {
        LogError("ZigZagインジケーターのハンドルを取得できませんでした。エラー: " + IntegerToString(GetLastError()));
        return false;
    }
    
    // 時間配列を作成
    for(int i = 0; i < ZigZagMaxLookback; i++)
    {
        timeBuffer[i] = iTime(symbol, timeframe, i);
        
        // ZigZagの値を取得（バッファ0がZigZag値）
        double value = iCustom(symbol, timeframe, "ZigZag", ZigZagDepth, ZigZagDeviation, ZigZagBackstep, 0, i);
        zigzagBuffer[i] = value;
    }
    
    // 方向に合わせて適切なZigZagポイントを探す
    if(direction > 0) // ロング（買い）の場合は直近の安値（Trough）を探す
    {
        for(int i = 1; i < ZigZagMaxLookback - 1; i++)
        {
            // ZigZagの値が0でなく、両隣の値より小さい場合は安値と判断
            if(zigzagBuffer[i] != 0 && 
               (zigzagBuffer[i-1] == 0 || zigzagBuffer[i] < zigzagBuffer[i-1]) && 
               (zigzagBuffer[i+1] == 0 || zigzagBuffer[i] < zigzagBuffer[i+1]))
            {
                zzPoint = zigzagBuffer[i];
                zzTime = timeBuffer[i];
                
                LogInfo("ロング用ZigZag安値検出: 価格=" + DoubleToString(zzPoint, Digits) + 
                       ", 時間=" + TimeToString(zzTime, TIME_DATE|TIME_MINUTES));
                
                return true;
            }
        }
    }
    else // ショート（売り）の場合は直近の高値（Peak）を探す
    {
        for(int i = 1; i < ZigZagMaxLookback - 1; i++)
        {
            // ZigZagの値が0でなく、両隣の値より大きい場合は高値と判断
            if(zigzagBuffer[i] != 0 && 
               (zigzagBuffer[i-1] == 0 || zigzagBuffer[i] > zigzagBuffer[i-1]) && 
               (zigzagBuffer[i+1] == 0 || zigzagBuffer[i] > zigzagBuffer[i+1]))
            {
                zzPoint = zigzagBuffer[i];
                zzTime = timeBuffer[i];
                
                LogInfo("ショート用ZigZag高値検出: 価格=" + DoubleToString(zzPoint, Digits) + 
                       ", 時間=" + TimeToString(zzTime, TIME_DATE|TIME_MINUTES));
                
                return true;
            }
        }
    }
    
    // 見つからなかった場合
    LogWarning("適切なZigZagポイントが" + IntegerToString(ZigZagMaxLookback) + "バー以内に見つかりませんでした。");
    return false;
}

//+------------------------------------------------------------------+
//| 利確レベル計算関連の関数                                          |
//+------------------------------------------------------------------+

// リスクリワード比に基づく利確レベルを計算
double CalculateTakeProfit(double entryPrice, double stopLoss, int direction)
{
    double riskDistance = MathAbs(entryPrice - stopLoss);
    double rewardDistance = riskDistance * RiskRewardRatio;
    
    if(direction > 0) // ロング
    {
        return NormalizeDouble(entryPrice + rewardDistance, Digits);
    }
    else // ショート
    {
        return NormalizeDouble(entryPrice - rewardDistance, Digits);
    }
}


//+------------------------------------------------------------------+
//| 部分決済関連の関数                                                |
//+------------------------------------------------------------------+

// 部分決済の設定
void SetupPartialClose(string symbol, int ticket, double entryPrice, double stopLoss, int direction)
{
    if(!UsePartialClose)
    {
        return;
    }
    
    // チケット番号を保存
    if(direction > 0) // ロング
    {
        g_TicketLong = ticket;
    }
    else // ショート
    {
        g_TicketShort = ticket;
    }
    
    // 部分決済トリガー価格を計算
    double riskDistance = MathAbs(entryPrice - stopLoss);
    double triggerDistance = riskDistance * PartialCloseTrigger;
    
    if(direction > 0) // ロング
    {
        g_PartialCloseTriggerPrice = NormalizeDouble(entryPrice + triggerDistance, Digits);
    }
    else // ショート
    {
        g_PartialCloseTriggerPrice = NormalizeDouble(entryPrice - triggerDistance, Digits);
    }
    
    g_PartialCloseDirection = direction;
    g_PartialCloseSet = true;
    
    LogInfo("部分決済設定: トリガー価格=" + DoubleToString(g_PartialCloseTriggerPrice, Digits) + 
           ", 方向=" + IntegerToString(direction));
}

// 部分決済条件をチェックして実行
void CheckAndExecutePartialClose(string symbol)
{
    if(!UsePartialClose || !g_PartialCloseSet)
    {
        return;
    }
    
    // 現在の価格を取得
    double currentPrice = (g_PartialCloseDirection > 0) ? Bid : Ask;
    
    // 部分決済条件をチェック
    bool triggerCondition = false;
    
    if(g_PartialCloseDirection > 0) // ロング
    {
        triggerCondition = (currentPrice >= g_PartialCloseTriggerPrice);
    }
    else // ショート
    {
        triggerCondition = (currentPrice <= g_PartialCloseTriggerPrice);
    }
    
    // 条件を満たしたら部分決済を実行
    if(triggerCondition)
    {
        int ticket = (g_PartialCloseDirection > 0) ? g_TicketLong : g_TicketShort;
        
        if(OrderSelect(ticket, SELECT_BY_TICKET))
        {
            // 約定済みポジションかどうかチェック (買いまたは売りポジションのみ処理)
            if(OrderType() == OP_BUY || OrderType() == OP_SELL)
            {
                // 部分決済するロットサイズを計算
                double closeVolume = OrderLots() * (PartialClosePercent / 100.0);
                closeVolume = NormalizeDouble(closeVolume, 2);
                
                // 最小ロットサイズを確認
                double minLot = MarketInfo(symbol, MODE_MINLOT);
                if(closeVolume >= minLot)
                {
                    // 部分決済を実行
                    bool result = false;
                    if(OrderType() == OP_BUY) // ロング
                    {
                        result = OrderClose(ticket, closeVolume, Bid, 3, Green);
                    }
                    else if(OrderType() == OP_SELL) // ショート
                    {
                        result = OrderClose(ticket, closeVolume, Ask, 3, Red);
                    }
                    
                    if(result)
                    {
                        LogInfo("部分決済実行: チケット=" + IntegerToString(ticket) + 
                               ", ロット=" + DoubleToString(closeVolume, 2));
                        
                        g_PartialCloseSet = false; // 部分決済フラグをリセット
                    }
                    else
                    {
                        LogError("部分決済エラー: " + IntegerToString(GetLastError()));
                    }
                }
            }
            else
            {
                // 約定済みポジションではない場合
                LogInfo("注文 #" + IntegerToString(ticket) + " は約定済みポジションではないため部分決済をスキップします");
                g_PartialCloseSet = false; // 部分決済フラグをリセット
            }
        }
    }
}

//+------------------------------------------------------------------+
//| トレーリングストップ関連の関数                                     |
//+------------------------------------------------------------------+

// トレーリングストップを管理
void ManageTrailingStop(string symbol)
{
    if(!UseTrailingStop)
    {
        return;
    }
    
    for(int i = 0; i < OrdersTotal(); i++)
    {
        if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            if(OrderSymbol() == symbol)
            {
                // 利益が一定レベル（リスクの設定倍率）に達したらトレーリングストップを有効化
                double pips = 0;
                if(OrderType() == OP_BUY)
                {
                    pips = (Bid - OrderOpenPrice()) / Point;
                }
                else if(OrderType() == OP_SELL)
                {
                    pips = (OrderOpenPrice() - Ask) / Point;
                }
                
                double riskPips = MathAbs(OrderOpenPrice() - OrderStopLoss()) / Point;
                
                if(pips > riskPips * TrailingTrigger)
                {
                    // トレーリングストップを設定
                    double newStop = 0;
                    if(OrderType() == OP_BUY)
                    {
                        newStop = NormalizeDouble(Bid - (riskPips * TrailingDistance * Point), Digits);
                    }
                    else if(OrderType() == OP_SELL)
                    {
                        newStop = NormalizeDouble(Ask + (riskPips * TrailingDistance * Point), Digits);
                    }
                    
                    // 現在のストップロスより有利な場合のみ更新
                    if((OrderType() == OP_BUY && newStop > OrderStopLoss()) ||
                       (OrderType() == OP_SELL && newStop < OrderStopLoss()))
                    {
                        bool result = OrderModify(OrderTicket(), OrderOpenPrice(), newStop, OrderTakeProfit(), 0);
                        if(result)
                        {
                            LogInfo("トレーリングストップ更新: チケット=" + IntegerToString(OrderTicket()) + 
                                   ", 新ストップ=" + DoubleToString(newStop, Digits));
                        }
                        else
                        {
                            LogError("トレーリングストップ更新エラー: " + IntegerToString(GetLastError()));
                        }
                    }
                }
            }
        }
    }
}