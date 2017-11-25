#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <cstrike>
#include <codmod301>
#define CHAT_PREFIX "  \x02[MapTop]"

const int g_iPlayersRequired = 8;
enum ScoreData
{
        ScoreData_ClientIndex = 0,
        ScoreData_ClientScore
}

enum RewardData
{
        RewardData_Exp = 0,
        RewardData_Dogtags,
        String:RewardData_Color[4]
}

int g_iRewards[4][RewardData] = {{5000, 20, "\x10"}, {3000, 15, "\x09"}, {1500, 10, "\x05"}, {1500, 10, "\x06"}};

public void OnPluginStart()
{
        HookEvent("cs_win_panel_match", Hook_MapEnd);
        RegConsoleCmd("test_maptop", Command_Maptop);
}

public Action Command_Maptop(int iClient, int iArgs)
{
        if(iClient == 0)
        {
                GiveAwards(true);
        }
}


stock int FetchScores(int iScores[MAXPLAYERS+1][ScoreData])
{
        int n = 0;
        for(int i = 1; i <= MaxClients; i++)
        {
                if(IsClientInGame(i))
                {
                        iScores[n][ScoreData_ClientIndex] = i;
                        iScores[n][ScoreData_ClientScore] = CS_GetClientContributionScore(i);
                        n++;
                }
        }

        return n;
}

stock void Sort(int iArray[MAXPLAYERS+1][ScoreData], int n)
{
        int temp[ScoreData];
        for(int i = 0; i <= n - 1; i++)
        {
                for(int j = 0; j <= n - 1; j++)
                {
                        if(iArray[j][ScoreData_ClientScore] < iArray[j + 1][ScoreData_ClientScore])
                        {
                                temp = iArray[j];
                                iArray[j] = iArray[j + 1];
                                iArray[j + 1] = temp;
                        }
                }
        }
}



stock bool GiveAwards(bool bDebug = false)
{
        int iScores[MAXPLAYERS+1][ScoreData];
        int n = FetchScores(iScores);
        if(n <= g_iPlayersRequired)
        {
                char szMessage[128] = {"Nagrody za TOP4 najlepszych graczy nie zostaną rozdane. Jest %d/%d graczy"};
                Format(szMessage, sizeof(szMessage), szMessage, n, g_iPlayersRequired);
                if(bDebug)
                {
                        PrintToServer("[MapTop] %s", szMessage);
                }
                else
                {
                        PrintToChatAll("%s\x10%s", CHAT_PREFIX, szMessage);
                }
                return false;
        }

        Sort(iScores, n);

        char szClientName[32];
        
        for(int i = 0; i < 3; i++)
        {
                char szRewardMessage[128] = "\x08 TOP%d %s%s \x08Otrzymał %d expa i %d nieśmiertelników! Gratulujemy!";
                GetClientName(iScores[i][ScoreData_ClientIndex], szClientName, sizeof(szClientName));
                Format(szRewardMessage, sizeof(szRewardMessage), szRewardMessage, i + 1, g_iRewards[i][RewardData_Color], szClientName, g_iRewards[i][RewardData_Exp], g_iRewards[i][RewardData_Dogtags]);
                if(bDebug)
                {       
                        PrintToServer("[MapTop] %s", szRewardMessage);
                }
                else
                {
                        PrintToChatAll("%s %s", CHAT_PREFIX, szRewardMessage);   
                }
                
        }

        int iRandom = GetRandomInt(3, n - 1);
        char szRandomMessage[128] = "\x08 Losowy gracz %s%s \x08otrzymał %d expa i %d nieśmiertelników! Gratulujemy!";
        GetClientName(iScores[iRandom][ScoreData_ClientIndex], szClientName, sizeof(szClientName));
        Format(szRandomMessage, sizeof(szRandomMessage), szRandomMessage, g_iRewards[3][RewardData_Color], szClientName, g_iRewards[3][RewardData_Exp], g_iRewards[3][RewardData_Dogtags]);
        if(bDebug)
        {
                PrintToServer("[MapTop] %s", szRandomMessage);
        }
        else
        {
                PrintToChatAll("%s %s", CHAT_PREFIX, szRandomMessage);
        }

        if(!bDebug)
        {
                iScores[3] = iScores[iRandom];
                for(int i = 0; i < 4; i++)
                {
                        int iClient = iScores[i][ScoreData_ClientIndex];
                        CodMod_GiveExp(iClient, g_iRewards[i][RewardData_Exp]);
                        CodMod_SetDogtagCount(iClient, CodMod_GetDogtagCount(iClient) + g_iRewards[i][RewardData_Dogtags]);
                }     
        }


        return true;   
}


public Action Hook_MapEnd(Event hEvent, const char[] szEvent, bool bBroadcast)
{

        GiveAwards(false);
        return Plugin_Changed;
}