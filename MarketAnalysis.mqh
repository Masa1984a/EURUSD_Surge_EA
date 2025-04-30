//+------------------------------------------------------------------+
//|                                                MarketAnalysis.mqh |
//|                                                                   |
//|                                                                   |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025"
#property strict

//+------------------------------------------------------------------+
//| ボラティリティ分析関連の関数                                       |
//+------------------------------------------------------------------+

// 現在のボラティリティを取得（ATRまたは高値-安値の差）
double GetCurrentVolatility(string symbol, int timeframe)
{
    if(UseATR)
    {
        // ATRを使用する場合
        return iATR(symbol, timeframe, ATRPeriod, 1);
    }
    else
    {
        // 単純な高値-安値の差を使用する場合
        return (iHigh(symbol, timeframe, 1) - iLow(symbol, timeframe, 1));
    }
}

// 過去の平均ボラティリティを計算
double GetAveragePastVolatility(string symbol, int timeframe, int period)
{
    double avgVolatility = 0;
    
    if(UseATR)
    {
        // ATRを使用する場合は、現在のATR値を返す（既に平均化されている）
        return iATR(symbol, timeframe, period, 1);
    }
    else
    {
        // 単純な高値-安値の差の平均を計算
        for(int i = 2; i <= period+1; i++)
        {
            avgVolatility += (iHigh(symbol, timeframe, i) - iLow(symbol, timeframe, i));
        }
        return avgVolatility / period;
    }
}

// 市場状況に基づく動的なボラティリティ乗数を取得
double GetDynamicVolatilityMultiplier(string symbol, int timeframe)
{
    // 短期と長期のボラティリティ比率を計算
    double shortTermVolatility = GetAveragePastVolatility(symbol, timeframe, ATRPeriod);
    double longTermVolatility = GetAveragePastVolatility(symbol, timeframe, VolatilityPeriod);
    
    double ratio = 1.0;
    if(longTermVolatility > 0)
    {
        ratio = shortTermVolatility / longTermVolatility;
    }
    
    // 時間帯に基づく調整
    int currentHour = TimeHour(TimeCurrent());
    double timeAdjustment = 1.0;
    
    // ロンドン・NY市場オーバーラップ時間帯（高ボラティリティ）
    if(currentHour >= 13 && currentHour < 16)
    {
        timeAdjustment = 1.2;
    }
    // アジア市場時間帯（低ボラティリティ）
    else if(currentHour >= 0 && currentHour < 7)
    {
        timeAdjustment = 0.8;
    }
    
    // 比率に基づいて乗数を調整
    if(ratio > 1.5)
    {
        return VolatilityMultiplier * 0.7 * timeAdjustment; // 短期ボラティリティが高い場合は乗数を下げる
    }
    else if(ratio < 0.7)
    {
        return VolatilityMultiplier * 1.3 * timeAdjustment; // 短期ボラティリティが低い場合は乗数を上げる
    }
    
    return VolatilityMultiplier * timeAdjustment; // デフォルト値に時間帯調整を適用
}

// 高ボラティリティのローソク足かどうかをチェック
bool IsHighVolatilityCandle(string symbol, int timeframe)
{
    // 最新の完成したローソク足を取得
    double currentOpen = iOpen(symbol, timeframe, 1);
    double currentClose = iClose(symbol, timeframe, 1);
    double currentHigh = iHigh(symbol, timeframe, 1);
    double currentLow = iLow(symbol, timeframe, 1);
    
    // ローソク足の実体と全体の大きさを計算
    double bodySize = MathAbs(currentClose - currentOpen);
    double totalSize = currentHigh - currentLow;
    
    // 実体/全体比率の計算
    double bodyRatio = 0;
    if(totalSize > 0)
    {
        bodyRatio = (bodySize / totalSize) * 100.0;
    }
    
    // 現在のボラティリティと平均ボラティリティを取得
    double currentVolatility = totalSize;
    double avgVolatility = GetAveragePastVolatility(symbol, timeframe, VolatilityPeriod);
    
    // 動的な乗数を取得
    double multiplier = GetDynamicVolatilityMultiplier(symbol, timeframe);
    
    // ボラティリティ比率の計算
    double volatilityRatio = 0;
    if(avgVolatility > 0)
    {
        volatilityRatio = currentVolatility / avgVolatility;
    }
    
    // 高ボラティリティかつ実体比率が十分かをチェック
    return (volatilityRatio >= multiplier && bodyRatio >= BodyToTotalRatio);
}

//+------------------------------------------------------------------+
//| トレンド分析関連の関数                                            |
//+------------------------------------------------------------------+

// 複数時間足でのトレンド方向の整合性をチェック
bool IsTrendAligned(string symbol, int direction)
{
    // 上位足でのトレンド方向を確認
    double ma50_higher = iMA(symbol, TrendTimeFrame, 50, 0, MODE_SMA, PRICE_CLOSE, 1);
    double ma100_higher = iMA(symbol, TrendTimeFrame, 100, 0, MODE_SMA, PRICE_CLOSE, 1);
    
    // 下位足でのトレンド方向を確認
    double ma20_lower = iMA(symbol, MainTimeFrame, 20, 0, MODE_SMA, PRICE_CLOSE, 1);
    double ma50_lower = iMA(symbol, MainTimeFrame, 50, 0, MODE_SMA, PRICE_CLOSE, 1);
    
    if(direction > 0) // 上昇トレンド
    {
        // 上位足と下位足の両方で上昇トレンドが確認できるか
        return (ma50_higher > ma100_higher && ma20_lower > ma50_lower);
    }
    else if(direction < 0) // 下降トレンド
    {
        // 上位足と下位足の両方で下降トレンドが確認できるか
        return (ma50_higher < ma100_higher && ma20_lower < ma50_lower);
    }
    
    return false;
}

// 現在のトレンド方向を取得（1=上昇、-1=下降、0=不明確）
int GetTrendDirection(string symbol, int timeframe)
{
    // 移動平均を使用してトレンド方向を判断
    double ma20 = iMA(symbol, timeframe, 20, 0, MODE_SMA, PRICE_CLOSE, 1);
    double ma50 = iMA(symbol, timeframe, 50, 0, MODE_SMA, PRICE_CLOSE, 1);
    
    if(ma20 > ma50)
    {
        return 1; // 上昇トレンド
    }
    else if(ma20 < ma50)
    {
        return -1; // 下降トレンド
    }
    
    return 0; // 明確なトレンドなし
}

// ADX値を取得
double GetADXValue(string symbol, int timeframe)
{
    return iADX(symbol, timeframe, ADXPeriod, PRICE_CLOSE, MODE_MAIN, 1);
}

// 強いトレンドかどうかをチェック
bool IsStrongTrend(string symbol, int timeframe)
{
    if(!UseADXFilter)
    {
        return true; // フィルタを使用しない場合は常にtrue
    }
    
    double adx = GetADXValue(symbol, timeframe);
    return (adx > ADXThreshold);
}

// レンジ相場かどうかをチェック
bool IsRangeMarket(string symbol, int timeframe)
{
    if(!UseBollingerFilter)
    {
        return false; // フィルタを使用しない場合は常にfalse
    }
    
    double upperBand = iBands(symbol, timeframe, BBPeriod, BBDeviation, 0, PRICE_CLOSE, MODE_UPPER, 1);
    double lowerBand = iBands(symbol, timeframe, BBPeriod, BBDeviation, 0, PRICE_CLOSE, MODE_LOWER, 1);
    double middleBand = iBands(symbol, timeframe, BBPeriod, BBDeviation, 0, PRICE_CLOSE, MODE_MAIN, 1);
    
    if(middleBand == 0)
    {
        return false;
    }
    
    double bandWidth = (upperBand - lowerBand) / middleBand;
    
    return (bandWidth < BBWidthThreshold);
}
