bool g_bNoblock[MAXPLAYERS+1] = {false};
int g_iRoundCounter = 0;
#define CHAT_PREFIX "  \x06[\x0BSerwery\x01-\x07GO\x06]"

public void OnPluginStart(){
    RegConsoleCmd("nb", Command_Noblock);
    RegConsoleCmd("noblock", Command_Noblock);
    g_iRoundCounter = 0;
    HookEvent("round_start", Event_RoundStart);
}

public Action Event_RoundStart(Event hEvent, const char[] szEventName, bool bBroadcast){
    g_iRoundCounter++;
}

public void OnMapStart(){
    g_iRoundCounter = 0;
}

public OnClientPutInServer(int iClient){
    g_bNoblock[iClient] = false;
}


public Action Command_Noblock(int iClient, int iArgs){
    if(IsClientInGame(iClient) && IsPlayerAlive(iClient) && !g_bNoblock[iClient]){
        g_bNoblock[iClient] = true;
        PrintToChat(iClient, "%s Noblock jest włączony na 2 sekundy!", CHAT_PREFIX);
        Handle hData = CreateDataPack();
        WritePackCell(hData, GetClientSerial(iClient));
        WritePackCell(hData, g_iRoundCounter);
        CreateTimer(2.0, Timer_Noblock, hData);
        SetEntProp(iClient, Prop_Data, "m_CollisionGroup", 2);
    }
    return Plugin_Handled;
}


public Action Timer_Noblock(Handle hTimer, Handle hData){
    ResetPack(hData);
    int iClient = GetClientFromSerial(ReadPackCell(hData));
    int iRoundIndex = ReadPackCell(hData);
    CloseHandle(hData);

    if(iRoundIndex != g_iRoundCounter || iClient < 1 || !IsClientInGame(iClient) || !IsPlayerAlive(iClient)){
        return Plugin_Stop;
    }

    g_bNoblock[iClient] = false;
    SetEntProp(iClient, Prop_Data, "m_CollisionGroup", 5);
    PrintToChat(iClient, "%s Noblock wyłączony!", CHAT_PREFIX);

    return Plugin_Stop;
}
