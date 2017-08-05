#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <codmod301>


public Plugin:myinfo = {
	name = "Call of Duty Mod - Perk - Stabilne Statystyki",
	author = "th7nder",
	description = "CODMOD's Perk",
	version = "1.0",
	url = "http://th7.eu"
};

new const String:szClassName[NAME_LENGTH] = {"Stabilne Statystyki"};
new const String:szDesc[DESC_LENGTH] = {"+20 do każdej statystyki."};
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
	CodMod_SetStat(iClient, HP_PERK, CodMod_GetStat(iClient, HP_PERK) + 20);
	CodMod_SetStat(iClient, ARMOR_PERK, CodMod_GetStat(iClient, ARMOR_PERK) + 20);
	CodMod_SetStat(iClient, INT_PERK, CodMod_GetStat(iClient, INT_PERK) + 20);
	CodMod_SetStat(iClient, DEX_PERK, CodMod_GetStat(iClient, DEX_PERK) + 20);
	CodMod_SetStat(iClient, STRENGTH_PERK, CodMod_GetStat(iClient, STRENGTH_PERK) + 20);

}

public CodMod_OnPerkDisabled(iClient, iPerkId){
	if(iPerkId != g_iPerkId)
		return;

	g_bHasItem[iClient] = false;

	CodMod_SetStat(iClient, HP_PERK, CodMod_GetStat(iClient, HP_PERK) - 20);
	CodMod_SetStat(iClient, ARMOR_PERK, CodMod_GetStat(iClient, ARMOR_PERK) - 20);
	CodMod_SetStat(iClient, INT_PERK, CodMod_GetStat(iClient, INT_PERK) - 20);
	CodMod_SetStat(iClient, DEX_PERK, CodMod_GetStat(iClient, DEX_PERK) - 20);
	CodMod_SetStat(iClient, STRENGTH_PERK, CodMod_GetStat(iClient, STRENGTH_PERK) - 20);
}
