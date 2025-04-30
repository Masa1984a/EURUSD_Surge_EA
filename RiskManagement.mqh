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
    
    // ブローカーの最小ストップロス距離を取得
    int minStopLevel = (int)MarketInfo(symbol, MODE_STOPLEVEL);
    // 安全マージンを追加（10ポイント追加）
    int safeStopDistance = minStopLevel + 10;
    
    // 現在のストップロス距離をチェック
    double currentStopDistance = MathAbs(entryPrice - stopLoss) / Point;
    
    // 最小ストップロス距離より近い場合は調整
    if(currentStopDistance < safeStopDistance)
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
            // 部分決済するロットサイズを計算
            double closeVolume = OrderLots() * (PartialClosePercent / 100.0);
            closeVolume = NormalizeDouble(closeVolume, 2);
            
            // 最小ロットサイズを確認
            double minLot = MarketInfo(symbol, MODE_MINLOT);
            if(closeVolume >= minLot)
            {
                // 部分決済を実行
                bool result = false;
                if(g_PartialCloseDirection > 0) // ロング
                {
                    result = OrderClose(ticket, closeVolume, Bid, 3, Green);
                }
                else // ショート
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