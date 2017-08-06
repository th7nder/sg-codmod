#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <codmod301>

#include <th7manager>

public Plugin:myinfo = {
	name = "Call of Duty Mod - Perk - Siatka Kamuflująca",
	author = "th7nder",
	description = "CODMOD's Perk",
	version = "1.0",
	url = "http://th7.eu"
};

new const String:szClassName[NAME_LENGTH] = {"Siatka Kamuflująca"};
new const String:szDesc[DESC_LENGTH] = {"Twoja widoczność spada do 30 procent."};
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
	TH7_SetRenderColor(iClient, 255, 255, 255, 76);

}

public CodMod_OnPerkDisabled(iClient, iPerkId){
	if(iPerkId != g_iPerkId)
		return;

	g_bHasItem[iClient] = false;
	TH7_DisableRenderColor(iClient);
}
