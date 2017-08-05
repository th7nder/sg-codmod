#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <codmod301>


public Plugin:myinfo = {
	name = "Call of Duty Mod - Perk - Fala Śmierci",
	author = "th7nder",
	description = "CODMOD's Perk",
	version = "1.0",
	url = "http://th7.eu"
};

new const String:szClassName[NAME_LENGTH] = {"Fala Śmierci"};
new const String:szDesc[DESC_LENGTH] = {"Po użyciu zabijasz wszystkich przeciwników."};
new g_iPerkId;

new bool:g_bHasItem[MAXPLAYERS +1] = {false};

public OnPluginStart(){
	g_iPerkId = CodMod_RegisterPerk(szClassName, szDesc);
}


public OnPluginEnd(){
	CodMod_UnregisterPerk(g_iPerkId);
}

public OnClientPutInServer(iClient){
	g_bHasItem[iClient] = false;
}


public CodMod_OnPerkEnabled(iClient, iPerkId){
	if(iPerkId != g_iPerkId)
		return;

	if(GetRandomInt(1, 100) <= 80)
	{
		CodMod_DestroyPerk(iClient);
		PrintToChat(iClient, "%s Otrzymałeś felerną fale śmierci!", PREFIX_INFO);
	} else {
		g_bHasItem[iClient] = true;
	}



}

public CodMod_OnPerkDisabled(iClient, iPerkId){
	if(iPerkId != g_iPerkId)
		return;

	g_bHasItem[iClient] = false;
}



public void CodMod_OnPerkSkillUsed(int iClient){
	if(!IsValidPlayer(iClient) || !IsPlayerAlive(iClient) || !g_bHasItem[iClient])
		return;

	int iTeam = GetClientTeam(iClient);
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) != iTeam)
		{
			CodMod_DealDamage(iClient, i, 5000.0, TH7_DMG_DEATHBLAST);
		}
	}
	CodMod_DestroyPerk(iClient);
}
