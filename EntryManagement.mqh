//+------------------------------------------------------------------+
//|                                              EntryManagement.mqh |
//|                                                                   |
//|                                                                   |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025"
#property strict

//+------------------------------------------------------------------+
//| 急騰・急落検出関連の関数                                          |
//+------------------------------------------------------------------+

// 急騰・急落を検出する関数
bool DetectPriceSurge(string symbol, int timeframe, int &direction, double &startPrice, double &endPrice, datetime &startTime)
{
    // 最新の完成したローソク足を取得
    double currentOpen = iOpen(symbol, timeframe, 1);
    double currentClose = iClose(symbol, timeframe, 1);
    double currentHigh = iHigh(symbol, timeframe, 1);
    double currentLow = iLow(symbol, timeframe, 1);
    
    // 高ボラティリティのローソク足かどうかをチェック
    if(!IsHighVolatilityCandle(symbol, timeframe))
    {
        return false;
    }
    
    // ローソク足パターンが有効かどうかをチェック
    if(!IsValidCandlePattern(symbol, timeframe))
    {
        return false;
    }
    
    // 陽線（上昇）の場合
    if(currentClose > currentOpen && EnableLongTrades)
    {
        // 前足からの最小値を探して起点とする
        double previousLow = currentLow;
        for(int i = 2; i <= 5; i++)
        {
            if(iLow(symbol, timeframe, i) < previousLow)
            {
                previousLow = iLow(symbol, timeframe, i);
            }
        }
        
        direction = 1; // 上昇
        startTime = iTime(symbol, timeframe, 5);
        startPrice = previousLow;
        endPrice = currentHigh;
        
        LogInfo("相対的急騰検知: ボラティリティ比 " + 
                DoubleToString(GetCurrentVolatility(symbol, timeframe) / 
                GetAveragePastVolatility(symbol, timeframe, VolatilityPeriod), 2) + 
                "倍, 実体比率: " + DoubleToString(GetBodyToTotalRatio(symbol, timeframe, 1), 2) + "%");
        
        return true;
    }
    // 陰線（下降）の場合
    else if(currentClose < currentOpen && EnableShortTrades)
    {
        // 前足からの最大値を探して起点とする
        double previousHigh = currentHigh;
        for(int i = 2; i <= 5; i++)
        {
            if(iHigh(symbol, timeframe, i) > previousHigh)
            {
                previousHigh = iHigh(symbol, timeframe, i);
            }
        }
        
        direction = -1; // 下降
        startTime = iTime(symbol, timeframe, 5);
        startPrice = previousHigh;
        endPrice = currentLow;
        
        LogInfo("相対的急落検知: ボラティリティ比 " + 
                DoubleToString(GetCurrentVolatility(symbol, timeframe) / 
                GetAveragePastVolatility(symbol, timeframe, VolatilityPeriod), 2) + 
                "倍, 実体比率: " + DoubleToString(GetBodyToTotalRatio(symbol, timeframe, 1), 2) + "%");
        
        return true;
    }
    
    return false;
}

// ローソク足の実体/全体比率を計算
double GetBodyToTotalRatio(string symbol, int timeframe, int shift)
{
    double open = iOpen(symbol, timeframe, shift);
    double close = iClose(symbol, timeframe, shift);
    double high = iHigh(symbol, timeframe, shift);
    double low = iLow(symbol, timeframe, shift);
    
    double bodySize = MathAbs(close - open);
    double totalSize = high - low;
    
    if(totalSize > 0)
    {
        return (bodySize / totalSize) * 100.0;
    }
    
    return 0;
}

// ローソク足パターンが有効かどうかをチェック
bool IsValidCandlePattern(string symbol, int timeframe)
{
    // 最新の完成したローソク足を取得
    double currentOpen = iOpen(symbol, timeframe, 1);
    double currentClose = iClose(symbol, timeframe, 1);
    double currentHigh = iHigh(symbol, timeframe, 1);
    double currentLow = iLow(symbol, timeframe, 1);
    
    // ローソク足の実体と全体の大きさを計算
    double bodySize = MathAbs(currentClose - currentOpen);
    double totalSize = currentHigh - currentLow;
    
    // 実体が全体の60%以上を占めるかどうかをチェック
    if(totalSize > 0 && (bodySize / totalSize) >= 0.6)
    {
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| 調整局面分析関連の関数                                            |
//+------------------------------------------------------------------+

// フィボナッチリトレースメントレベルを計算
double CalculateFibonacciLevel(double surgeStartPrice, double surgeEndPrice, double currentPrice, int direction)
{
    double surgeRange = MathAbs(surgeEndPrice - surgeStartPrice);
    double retracementLevel = 0;
    
    if(surgeRange == 0)
    {
        return 0;
    }
    
    if(direction > 0) // 上昇後の調整
    {
        retracementLevel = (surgeEndPrice - currentPrice) / surgeRange;
    }
    else // 下降後の調整
    {
        retracementLevel = (currentPrice - surgeEndPrice) / surgeRange;
    }
    
    return retracementLevel;
}

// 調整が有効かどうかをチェック
bool IsValidRetracement(double surgeStartPrice, double surgeEndPrice, double currentPrice, int direction)
{
    if(!UseFibonacciRetracement)
    {
        return true; // フィボナッチリトレースメントを使用しない場合は常にtrue
    }
    
    double retracementLevel = CalculateFibonacciLevel(surgeStartPrice, surgeEndPrice, currentPrice, direction);
    
    // 指定されたフィボナッチレベルの範囲内かどうかをチェック
    return (retracementLevel >= FiboMinLevel && retracementLevel <= FiboMaxLevel);
}

// 調整が完了したかどうかをチェック
bool IsAdjustmentComplete(string symbol, int timeframe, int adjustmentCount, int direction)
{
    // 調整足数が最小数に達していないかどうかをチェック
    if(adjustmentCount < AdjustmentCandlesMin)
    {
        return false;
    }
    
    // 調整足数が最大数を超えたかどうかをチェック
    if(adjustmentCount > AdjustmentCandlesMax)
    {
        return false;
    }
    
    // 最新の完成したローソク足を取得
    double currentOpen = iOpen(symbol, timeframe, 1);
    double currentClose = iClose(symbol, timeframe, 1);
    
    // 上昇トレンドの場合は陽線、下降トレンドの場合は陰線を確認
    if((direction > 0 && currentClose > currentOpen) || 
       (direction < 0 && currentClose < currentOpen))
    {
        // 実体比率をチェック
        double bodyRatio = GetBodyToTotalRatio(symbol, timeframe, 1);
        
        // 実体が十分に大きい場合のみ調整完了と判断
        if(bodyRatio >= 50.0)
        {
            return true;
        }
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| エントリーポイント検出関連の関数                                   |
//+------------------------------------------------------------------+

// 再エントリーポイントを検出する関数
bool DetectReentryPoint(string symbol, int timeframe, int direction, double surgeStartPrice, double surgeEndPrice, 
                        double &entryPrice, double &stopLoss, double &takeProfit)
{
    // 現在の価格を取得
    double currentPrice = (direction > 0) ? Ask : Bid;
    
    // 調整が有効かどうかをチェック
    if(!IsValidRetracement(surgeStartPrice, surgeEndPrice, currentPrice, direction))
    {
        return false;
    }
    
    // 複数指標による確認
    if(!ConfirmEntrySignal(symbol, timeframe, direction))
    {
        return false;
    }
    
    // 引き付けた指値注文の価格を計算
    double surgeRange = MathAbs(surgeEndPrice - surgeStartPrice);
    double pullbackAmount = surgeRange * (EntryPullbackPercent / 100.0);
    
    // 価格精度を調整（Digitsに合わせる）
    if(direction > 0) // ロング
    {
        entryPrice = NormalizeDouble(surgeEndPrice - pullbackAmount, Digits);
    }
    else // ショート
    {
        entryPrice = NormalizeDouble(surgeEndPrice + pullbackAmount, Digits);
    }
    
    // ストップロス位置を計算
    stopLoss = CalculateDynamicStopLoss(symbol, timeframe, direction, entryPrice, surgeStartPrice);
    
    // 利確位置を計算
    takeProfit = CalculateTakeProfit(entryPrice, stopLoss, direction);
    
    return true;
}

// エントリーシグナルを複数指標で確認
bool ConfirmEntrySignal(string symbol, int timeframe, int direction)
{
    bool confirmed = true;
    
    // RSIによる確認
    if(UseRSIConfirmation)
    {
        confirmed = confirmed && CheckRSIAlignment(symbol, timeframe, direction);
    }
    
    // MACDによる確認
    if(UseMACDConfirmation)
    {
        confirmed = confirmed && CheckMACDAlignment(symbol, timeframe, direction);
    }
    
    // トレンド方向の整合性確認
    confirmed = confirmed && IsTrendAligned(symbol, direction);
    
    return confirmed;
}

// RSIの方向性を確認
bool CheckRSIAlignment(string symbol, int timeframe, int direction)
{
    double rsi = iRSI(symbol, timeframe, RSIPeriod, PRICE_CLOSE, 1);
    
    if(direction > 0) // 上昇トレンド
    {
        return (rsi > 50);
    }
    else // 下降トレンド
    {
        return (rsi < 50);
    }
}

// MACDの方向性を確認
bool CheckMACDAlignment(string symbol, int timeframe, int direction)
{
    double macd = iMACD(symbol, timeframe, MACDFastEMA, MACDSlowEMA, MACDSignalPeriod, PRICE_CLOSE, MODE_MAIN, 1);
    double macdSignal = iMACD(symbol, timeframe, MACDFastEMA, MACDSlowEMA, MACDSignalPeriod, PRICE_CLOSE, MODE_SIGNAL, 1);
    
    if(direction > 0) // 上昇トレンド
    {
        return (macd > macdSignal);
    }
    else // 下降トレンド
    {
        return (macd < macdSignal);
    }
}
