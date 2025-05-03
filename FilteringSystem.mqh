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
    
    return true;
}





// 強制決済時間かどうかをチェック
bool IsForceCloseTime()
{
    int currentHour = TimeHour(TimeCurrent());
    int currentMinute = TimeMinute(TimeCurrent());
    return (currentHour == FORCE_CLOSE_HOUR && currentMinute == FORCE_CLOSE_MINUTE);
}
