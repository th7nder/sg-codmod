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


public int factorial(int n)
{
        if(n < 2) return 1;

        return n * factorial(n - 1);
}

stock int FetchScores(int iScores[MAXPLAYERS+1][ScoreData])
{
        int n = 0;
        for(int i = 1; i <= MaxClients; i++)
        {
                if(IsClientInGame(i) && !IsFakeClient(i))
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

public void QuickSort(int[][] iArray, int n)
{
        if(n <= 1) return;
        int iPivot[ScoreData];
        int[][] iLeft = new int[n - 1][ScoreData];
        int[][] iRight = new int[n - 1][ScoreData];

        iPivot[ScoreData_ClientIndex] = iArray[0][ScoreData_ClientIndex];
        iPivot[ScoreData_ClientScore] = iArray[0][ScoreData_ClientScore];

        int iLeftN = 0;
        int iRightN = 0;
        for(int i = 1; i < n; i++)
        {
                if(iArray[i][ScoreData_ClientScore] > iPivot[ScoreData_ClientScore])
                {
                        iLeft[iLeftN][ScoreData_ClientIndex] = iArray[i][ScoreData_ClientIndex];
                        iLeft[iLeftN][ScoreData_ClientScore] = iArray[i][ScoreData_ClientScore];
                        iLeftN++;
                }
                else
                {
                        iRight[iRightN][ScoreData_ClientIndex] = iArray[i][ScoreData_ClientIndex];
                        iRight[iRightN][ScoreData_ClientScore] = iArray[i][ScoreData_ClientScore];
                        iRightN++;
                }
        }

        QuickSort(iLeft, iLeftN);
        QuickSort(iRight, iRightN);

        int i = 0;
        for(int j = 0; j < iLeftN; j++)
        {
                iArray[i][ScoreData_ClientIndex] = iLeft[j][ScoreData_ClientIndex];
                iArray[i][ScoreData_ClientScore] = iLeft[j][ScoreData_ClientScore];
                i++;
        }

        iArray[i][ScoreData_ClientIndex] = iPivot[ScoreData_ClientIndex];
        iArray[i][ScoreData_ClientScore] = iPivot[ScoreData_ClientScore];
        i++;

        for(int j = 0; j < iRightN; j++)
        {
                iArray[i][ScoreData_ClientIndex] = iRight[j][ScoreData_ClientIndex];
                iArray[i][ScoreData_ClientScore] = iRight[j][ScoreData_ClientScore];
                i++;
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

        if(bDebug)
        {
                QuickSort(iScores, n);
                for(int i = 0; i < n; i++)
                {
                        PrintToServer("%d# %d | %d ", i, iScores[i][ScoreData_ClientIndex], iScores[i][ScoreData_ClientScore]);
                }

        }
        else
        {
                QuickSort(iScores, n);
                //Sort(iScores, n);    
        }
        

        char szClientName[32];
        
        for(int i = 0; i < 3; i++)
        {
                char szRewardMessage[128] = "%s\x08 TOP%d %s%s \x08Otrzymał %d expa i %d nieśmiertelników! Gratulujemy!";
                GetClientName(iScores[i][ScoreData_ClientIndex], szClientName, sizeof(szClientName));
                Format(szRewardMessage, sizeof(szRewardMessage), szRewardMessage, CHAT_PREFIX, i + 1, g_iRewards[i][RewardData_Color], szClientName, g_iRewards[i][RewardData_Exp], g_iRewards[i][RewardData_Dogtags]);
                if(bDebug)
                {       
                        PrintToServer(szRewardMessage);
                }
                else
                {
                        PrintToChatAll(szRewardMessage);   
                }
                
        }

        int iRandom = GetRandomInt(3, n - 1);
        char szRandomMessage[128] = "%s\x08 Losowy gracz %s%s \x08otrzymał %d expa i %d nieśmiertelników! Gratulujemy!";
        GetClientName(iScores[iRandom][ScoreData_ClientIndex], szClientName, sizeof(szClientName));
        Format(szRandomMessage, sizeof(szRandomMessage), szRandomMessage, CHAT_PREFIX, g_iRewards[3][RewardData_Color], szClientName, g_iRewards[3][RewardData_Exp], g_iRewards[3][RewardData_Dogtags]);
        if(bDebug)
        {
                PrintToServer(szRandomMessage);
        }
        else
        {
                PrintToChatAll(szRandomMessage);
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