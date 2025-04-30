//+------------------------------------------------------------------+
//|                                              FilteringSystem.mqh |
//|                                                                   |
//|                                                                   |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025"
#property strict

//+------------------------------------------------------------------+
//| 市場状況フィルタ関連の関数                                         |
//+------------------------------------------------------------------+

// 現在の市場状況で取引すべきかどうかをチェック
bool ShouldTradeInCurrentMarket(string symbol, int timeframe)
{
    // トレンド相場かレンジ相場かを判断
    bool isRangeMarket = IsRangeMarket(symbol, timeframe);
    bool isStrongTrend = IsStrongTrend(symbol, timeframe);
    
    // レンジ相場では取引を控える
    if(isRangeMarket && !isStrongTrend)
    {
        LogInfo("レンジ相場を検出: 取引を見送ります");
        return false;
    }
    
    // ボラティリティが過剰に高い場合も取引を控える
    if(IsMarketTooVolatile(symbol, timeframe))
    {
        LogInfo("過剰なボラティリティを検出: 取引を見送ります");
        return false;
    }
    
    // 経済指標発表時間帯は取引を控える
    if(IsNewsTime())
    {
        LogInfo("経済指標発表時間帯: 取引を見送ります");
        return false;
    }
    
    return true;
}

// 市場のボラティリティが過剰に高いかどうかをチェック
bool IsMarketTooVolatile(string symbol, int timeframe)
{
    double currentVolatility = GetCurrentVolatility(symbol, timeframe);
    double avgVolatility = GetAveragePastVolatility(symbol, timeframe, VolatilityPeriod);
    
    // 平均の5倍以上のボラティリティは過剰と判断
    return (currentVolatility > avgVolatility * 5.0);
}

//+------------------------------------------------------------------+
//| 経済指標フィルタ関連の関数                                         |
//+------------------------------------------------------------------+

// 経済指標発表時間かどうかをチェック
bool IsNewsTime()
{
    // 実際の実装では外部データソースから経済指標カレンダーを取得する必要があります
    // ここでは簡易的な実装として、特定の時間帯を経済指標発表時間とみなします
    
    datetime currentTime = TimeCurrent();
    int currentHour = TimeHour(currentTime);
    int currentMinute = TimeMinute(currentTime);
    int currentDayOfWeek = TimeDayOfWeek(currentTime);
    
    // 米国の主要経済指標発表時間（例: 雇用統計発表日の8:30 ET）
    bool isNFPTime = (currentDayOfWeek == 5 && // 金曜日
                      currentHour == 8 && currentMinute >= 25 && currentMinute <= 35);
    
    // 米国FOMC発表時間（例: 14:00 ET）
    bool isFOMCTime = (currentHour == 14 && currentMinute >= 55 && currentMinute <= 5);
    
    // ECB政策金利発表時間（例: 7:45 ET）
    bool isECBTime = (currentHour == 7 && currentMinute >= 40 && currentMinute <= 50);
    
    return (isNFPTime || isFOMCTime || isECBTime);
}

// 重要な経済指標発表が予定されているかどうかをチェック
bool IsHighImpactNewsExpected()
{
    // 実際の実装では外部データソースから経済指標カレンダーを取得する必要があります
    // ここでは簡易的な実装として、特定の曜日を重要指標発表日とみなします
    
    int currentDayOfWeek = TimeDayOfWeek(TimeCurrent());
    
    // 金曜日（雇用統計など）と水曜日（FOMC）を重要指標発表日とみなす
    return (currentDayOfWeek == 5 || currentDayOfWeek == 3);
}




// 強制決済時間かどうかをチェック
bool IsForceCloseTime()
{
    int currentHour = TimeHour(TimeCurrent());
    int currentMinute = TimeMinute(TimeCurrent());
    return (currentHour == FORCE_CLOSE_HOUR && currentMinute == FORCE_CLOSE_MINUTE);
}
