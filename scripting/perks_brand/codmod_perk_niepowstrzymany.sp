#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <codmod301>


public Plugin:myinfo = {
	name = "Call of Duty Mod - Perk - Niepowstrzymany",
	author = "th7nder",
	description = "CODMOD's Perk",
	version = "1.0",
	url = "http://th7.eu"
};

new const String:szClassName[NAME_LENGTH] = {"Niepowstrzymany"};
new const String:szDesc[DESC_LENGTH] = {"Otrzymujesz 60 kondycji, 50hp oraz +15dmg)"};
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
	CodMod_SetStat(iClient, HP_PERK, CodMod_GetStat(iClient, HP_PERK) + 25);
	CodMod_SetStat(iClient, DEX_PERK, CodMod_GetStat(iClient, DEX_PERK) + 60);

}

public CodMod_OnPerkDisabled(iClient, iPerkId){
	if(iPerkId != g_iPerkId)
		return;

	g_bHasItem[iClient] = false;

	CodMod_SetStat(iClient, HP_PERK, CodMod_GetStat(iClient, HP_PERK) - 25);
	CodMod_SetStat(iClient, DEX_PERK, CodMod_GetStat(iClient, DEX_PERK) - 60);
}

public void CodMod_OnPlayerDamaged(int iAttacker, int iVictim, float &fDamage, WeaponID iWeaponID, int iDamageType){
    if(g_bHasItem[iAttacker]){
        fDamage += 15.0;
    }
}

