#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <codmod301>


public Plugin:myinfo = {
	name = "Call of Duty Mod - Perk - Nóż Zwiadowcy",
	author = "th7nder",
	description = "CODMOD's Perk",
	version = "1.0",
	url = "http://th7.eu"
};

new const String:szClassName[NAME_LENGTH] = {"Nóż zwiadowcy"};
new const String:szDesc[DESC_LENGTH] = {"Gdy zmienisz broń na nóż jesteś bardzo szybki."};
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
	SDKHook(iClient, SDKHook_WeaponSwitchPost, Hook_WeaponSwitchPost);

}

public CodMod_OnPerkDisabled(iClient, iPerkId){
	if(iPerkId != g_iPerkId)
		return;

	if(g_bHasItem[iClient]){
		SDKUnhook(iClient, SDKHook_WeaponSwitchPost, Hook_WeaponSwitchPost);
		CodMod_SetStat(iClient, DEX_PERK, 0);
	}
	g_bHasItem[iClient] = false;
}

public Hook_WeaponSwitchPost(iClient, iWeapon){
	if(g_bHasItem[iClient]){
		if(CodMod_GetWeaponID(iWeapon) == WEAPON_KNIFE){
			CodMod_SetStat(iClient, DEX_PERK, 60);
		} else {
			CodMod_SetStat(iClient, DEX_PERK, 0);
		}
	}
}
