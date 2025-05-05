//+------------------------------------------------------------------+
//|                                                 Utilities.mqh |
//|                                                                   |
//|                                                                   |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025"
#property strict

//+------------------------------------------------------------------+
//| 時間管理関連の関数                                                |
//+------------------------------------------------------------------+

// 新しい日かどうかをチェック
bool IsNewDay()
{
    static datetime lastDay = 0;
    datetime currentDay = StringToTime(TimeToString(TimeCurrent(), TIME_DATE));
    
    if(currentDay > lastDay)
    {
        lastDay = currentDay;
        return true;
    }
    
    return false;
}

// 取引時間内かどうかをチェック
bool IsTradeTime()
{
    int currentHour = TimeHour(TimeCurrent());
    return (currentHour >= TRADE_START_HOUR && currentHour < TRADE_END_HOUR);
}

// 新しいバーが完成したかどうかをチェック
bool IsNewBar(string symbol, int timeframe)
{
    static datetime lastBarTime = 0;
    datetime currentBarTime = iTime(symbol, timeframe, 0);
    
    if(currentBarTime > lastBarTime)
    {
        lastBarTime = currentBarTime;
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| ログ機能関連の関数                                                |
//+------------------------------------------------------------------+

// デバッグログを出力
void LogDebug(string message)
{
    if(DebugMode)
    {
        Print("[DEBUG] " + TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS) + ": " + message);
    }
}

// 情報ログを出力
void LogInfo(string message)
{
    Print("[INFO] " + TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS) + ": " + message);
}

// 警告ログを出力
void LogWarning(string message)
{
    Print("[WARNING] " + TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS) + ": " + message);
}

// エラーログを出力
void LogError(string message)
{
    Print("[ERROR] " + TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS) + ": " + message);
}

//+------------------------------------------------------------------+
//| エラーハンドリング関連の関数                                       |
//+------------------------------------------------------------------+

// エラーコードからエラーメッセージを取得
string GetLastErrorText(int errorCode)
{
    string errorText;
    
    switch(errorCode)
    {
        case 0:   errorText = "エラーなし"; break;
        case 1:   errorText = "一般エラー"; break;
        case 2:   errorText = "無効なトレードパラメータ"; break;
        case 3:   errorText = "サーバーがビジー状態"; break;
        case 4:   errorText = "古いバージョン"; break;
        case 5:   errorText = "クライアントターミナルとサーバーの接続なし"; break;
        case 6:   errorText = "アカウントが無効"; break;
        case 7:   errorText = "不十分な権限"; break;
        case 8:   errorText = "リクエスト頻度が高すぎる"; break;
        case 9:   errorText = "操作が頻繁すぎる"; break;
        case 64:  errorText = "アカウントが無効"; break;
        case 65:  errorText = "無効なアカウント番号"; break;
        case 128: errorText = "トレード待機時間の終了"; break;
        case 129: errorText = "無効な価格"; break;
        case 130: errorText = "無効なストップ"; break;
        case 131: errorText = "無効なロットサイズ"; break;
        case 132: errorText = "市場が閉じている"; break;
        case 133: errorText = "トレードが無効"; break;
        case 134: errorText = "資金不足"; break;
        case 135: errorText = "価格が変更された"; break;
        case 136: errorText = "価格がない"; break;
        case 137: errorText = "ブローカーがビジー状態"; break;
        case 138: errorText = "新価格"; break;
        case 139: errorText = "注文がロックされている"; break;
        case 140: errorText = "ロングポジションのみ可能"; break;
        case 141: errorText = "リクエストが多すぎる"; break;
        case 145: errorText = "過度の修正"; break;
        case 146: errorText = "トレードコンテキストがビジー状態"; break;
        case 147: errorText = "有効期限が無効"; break;
        case 148: errorText = "トレードが多すぎる"; break;
        default:  errorText = "未知のエラー (" + IntegerToString(errorCode) + ")";
    }
    
    return errorText;
}

// 注文エラーを処理
bool HandleOrderError(int errorCode)
{
    switch(errorCode)
    {
        // 再試行可能なエラー
        case 4:   // 古いバージョン
        case 8:   // リクエスト頻度が高すぎる
        case 9:   // 操作が頻繁すぎる
        case 128: // トレード待機時間の終了
        case 135: // 価格が変更された
        case 136: // 価格がない
        case 137: // ブローカーがビジー状態
        case 138: // 新価格
        case 146: // トレードコンテキストがビジー状態
            LogWarning("再試行可能なエラー: " + GetLastErrorText(errorCode));
            return true; // 再試行可能
            
        // 致命的なエラー
        default:
            LogError("致命的なエラー: " + GetLastErrorText(errorCode));
            return false; // 再試行不可
    }
}


//+------------------------------------------------------------------+
//| 注文管理関連の関数                                                |
//+------------------------------------------------------------------+

// 注文送信（再試行ロジック付き）
int SendOrderWithRetry(int type, double lots, double price, int slippage, double stopLoss, double takeProfit, 
                      string comment, int magic, datetime expiration, color arrow_color)
{
    int ticket = -1;
    int retries = 5;
    int wait_time = 500; // ミリ秒
    
    for(int i = 0; i < retries; i++)
    {
        ticket = OrderSend(Symbol(), type, lots, price, slippage, stopLoss, takeProfit, commsent, magic, expiration, arrow_color);
        
        if(ticket > 0)
        {
            return ticket;
        }
        
        int errorCode = GetLastError();
        
        if(!HandleOrderError(errorCode))
        {
            // 致命的なエラーの場合は再試行しない
            return -1;
        }
        
        // 再試行前に待機
        Sleep(wait_time);
        RefreshRates();
        
        // 待機時間を増やす
        wait_time *= 2;
    }
    
    return -1;
}


// 注文削除（再試行ロジック付き）
bool DeleteOrderWithRetry(int ticket)
{
    bool result = false;
    int retries = 5;
    int wait_time = 500; // ミリ秒
    
    for(int i = 0; i < retries; i++)
    {
        result = OrderDelete(ticket);
        
        if(result)
        {
            return true;
        }
        
        int errorCode = GetLastError();
        
        if(!HandleOrderError(errorCode))
        {
            // 致命的なエラーの場合は再試行しない
            return false;
        }
        
        // 再試行前に待機
        Sleep(wait_time);
        RefreshRates();
        
        // 待機時間を増やす
        wait_time *= 2;
    }
    
    return false;
}
