#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <codmod301>

public Plugin myinfo = {
    name = "Call of Duty Mod - Perk - No-Flash",
    author = "th7nder",
    description = "201 Rewrite Perk",
    version = "2.0",
    url = "http://th7.eu"
};

char szClassName[] = {"No-Flash"};
char szDesc[] = {"Posiadasz No-Flasha."};
int g_iPerkId;


bool g_bHasItem[MAXPLAYERS +1] = {false};


public void OnPluginStart(){
    g_iPerkId = CodMod_RegisterPerk(szClassName, szDesc);
    HookEvent("player_blind", Event_OnFlashPlayer, EventHookMode_Pre);
}

public void OnPluginEnd(){
    CodMod_UnregisterPerk(g_iPerkId);
}

public void OnClientPutInServer(int iClient){
    g_bHasItem[iClient] = false;
}

public void CodMod_OnPerkEnabled(int iClient, int iPerkId){
    if(iPerkId != g_iPerkId)
        return;

    g_bHasItem[iClient] = true;
}

public void CodMod_OnPerkDisabled(int iClient, int iPerkId){
    if(iPerkId != g_iPerkId)
        return;

    g_bHasItem[iClient] = false;
}


public Action Event_OnFlashPlayer(Event hEvent, const char[] szEvent, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
	if(g_bHasItem[iClient])
		SetEntPropFloat(iClient, Prop_Send, "m_flFlashMaxAlpha", 0.5);

	return Plugin_Handled;
}
