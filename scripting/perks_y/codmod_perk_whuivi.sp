#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <codmod301>

public Plugin:myinfo = {
	name = "Call of Duty Mod - Perk - WHuivi",
	author = "th7nder",
	description = "CODMOD's Perk",
	version = "1.0",
	url = "http://th7.eu"
};

new const String:szClassName[NAME_LENGTH] = {"WHuivi"};
new const String:szDesc[DESC_LENGTH] = {"Na każdym spawnie dostajesz Granat Taktyczny."};
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

	g_bHasItem[iClient] = true;

}

public CodMod_OnPerkDisabled(iClient, iPerkId){
	if(iPerkId != g_iPerkId)
		return;

	g_bHasItem[iClient] = false;

}

public CodMod_OnPlayerSpawn(iClient){
	if(g_bHasItem[iClient]){
        if(!CodMod_GetPlayerNades(iClient, TH7_TACTICAL))
		      GivePlayerItem(iClient, "weapon_tagrenade");
	}
}
