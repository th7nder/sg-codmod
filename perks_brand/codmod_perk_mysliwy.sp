#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <codmod301>





char g_szStatsNames[statsIdxs][32] = {
    {"hp"},
    {"armor"},
    {"dex"},
    {"int"},
    {"str"},
    {"grav"},
    {"Witalności"},
    {"Wytrzymałości"},
    {"Szybkości"},
    {"Inteligencji"},
    {"Siły"},
    {"Grawitacji"},
    {"starthp"}
}



public Plugin:myinfo = {
	name = "Call of Duty Mod - Perk - Mysliwy",
	author = "th7nder",
	description = "CODMOD's Perk",
	version = "1.0",
	url = "http://th7.eu"
};

new const String:szClassName[NAME_LENGTH] = {"Myśliwy"};
new const String:szDesc[DESC_LENGTH] = {"Po zabiciu wroga dostajesz +8 losowej statystyki - na jedną rundę."};
int g_iPerkId;

bool g_bHasItem[MAXPLAYERS +1] = {false};

int g_iGivenStatistics[MAXPLAYERS+1][statsIdxs];

public void OnPluginStart()
{
	g_iPerkId = CodMod_RegisterPerk(szClassName, szDesc);
    HookEvent("round_start", Event_OnRoundStart);
}


public void OnPluginEnd()
{
	CodMod_UnregisterPerk(g_iPerkId);
}

public void OnClientPutInServer(iClient)
{
	g_bHasItem[iClient] = false;
}

public void CodMod_OnPerkEnabled(iClient, iPerkId)
{
	if(iPerkId != g_iPerkId)
		return;

	g_bHasItem[iClient] = true;

    for(statsIdxs i = HP_PERK; i <= GRAVITY_PERK; i++)
    {
        g_iGivenStatistics[iClient][i] = 0;
    }

}


public void CodMod_OnPerkDisabled(int iClient, int iPerkId)
{
    if(iPerkId != g_iPerkId)
        return;

    TakeStats(iClient);

    g_bHasItem[iClient] = false;
}


public void CodMod_OnPlayerDie(int iAttacker, int iVictim, bool bHeadshot)
{
    if(g_bHasItem[iAttacker])
    {
        statsIdxs targetStat = view_as<statsIdxs>(GetRandomInt(view_as<int>(HP_PERK), view_as<int>(GRAVITY_PERK)));
        CodMod_SetStat(iAttacker, targetStat, CodMod_GetStat(iAttacker, targetStat) + 8);
        g_iGivenStatistics[iAttacker][targetStat] += 8;
        if(targetStat == HP_PERK)
        {
            SetEntityHealth(iAttacker, GetClientHealth(iAttacker) + (8 * HP_MULTIPLIER));
        }
        PrintToChat(iAttacker, "%s Dostałeś +8 do %s", PREFIX_INFO, g_szStatsNames[targetStat]);
    }
}


public Action Event_OnRoundStart(Event hEvent, const char[] szBroadcast, bool bBroadcast)
{
    for(int iClient = 1; iClient <= MaxClients; iClient++)
    {
        if(IsClientInGame(iClient))
        {
            TakeStats(iClient);
        }
    }
}


stock void TakeStats(int iClient)
{
    for(statsIdxs i = HP_PERK; i <= GRAVITY_PERK; i++)
    {
        if(g_bHasItem[iClient])
        {
            CodMod_SetStat(iClient, i, CodMod_GetStat(iClient, i) - g_iGivenStatistics[iClient][i]);
        }
        g_iGivenStatistics[iClient][i] = 0;
    }
}


