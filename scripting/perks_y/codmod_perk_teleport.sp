#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <codmod301>


public Plugin:myinfo = {
	name = "Call of Duty Mod - Perk - Teleport",
	author = "th7nder",
	description = "CODMOD's Perk",
	version = "1.0",
	url = "http://th7.eu"
};

new const String:szClassName[NAME_LENGTH] = {"Teleport"};
new const String:szDesc[DESC_LENGTH] = {"Teleportujesz się do zapisanego miejsca(codmod_perk)"};
new g_iPerkId;


new bool:g_bHasItem[MAXPLAYERS +1] = {false};

int g_iUsed[MAXPLAYERS+1] = {0};
float g_fStartOrigin[MAXPLAYERS][3];
public OnPluginStart(){
	g_iPerkId = CodMod_RegisterPerk(szClassName, szDesc);
}

public OnPluginEnd(){
	CodMod_UnregisterPerk(g_iPerkId);
}

public OnClientPutInServer(iClient){
	g_bHasItem[iClient] = false;
	g_iUsed[iClient] = 0;
}

public CodMod_OnPerkEnabled(iClient, iPerkId){
	if(iPerkId != g_iPerkId)
		return;

	g_bHasItem[iClient] = true;
	g_iUsed[iClient] = 0;

}

public CodMod_OnPerkDisabled(iClient, iPerkId){
	if(iPerkId != g_iPerkId)
		return;

	g_bHasItem[iClient] = false;
	g_iUsed[iClient] = 0;
}

public CodMod_OnPlayerSpawn(iClient){
	if(g_bHasItem[iClient]){
		g_iUsed[iClient] = 0;
	}
}



public void CodMod_OnPerkSkillUsed(int iClient){
	if(!IsValidPlayer(iClient) || !IsPlayerAlive(iClient) || !g_bHasItem[iClient])
		return;

	if(g_iUsed[iClient] == 0){
		g_iUsed[iClient] = 1;
		GetClientAbsOrigin(iClient, g_fStartOrigin[iClient]);
		PrintHintText(iClient, "\n<font size='30' color='#00CC00'>Pozycja zapisana!</font>");
		return
	} else if(g_iUsed[iClient] == 1){
		g_iUsed[iClient] = 2;
		PrintHintText(iClient, "\n<font size='30' color='#00CC00'>Teleportacja!</font>");
		TeleportEntity(iClient, g_fStartOrigin[iClient], NULL_VECTOR, NULL_VECTOR);
		return;
	} else {
		return;
	}
}
