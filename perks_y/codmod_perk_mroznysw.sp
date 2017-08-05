#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <codmod301>
#include <th7manager>


public Plugin:myinfo = {
	name = "Call of Duty Mod - Perk - Mroźny sW",
	author = "th7nder",
	description = "CODMOD's Perk",
	version = "1.0",
	url = "http://th7.eu"
};

new const String:szClassName[NAME_LENGTH] = {"Mroźny sW"};
new const String:szDesc[DESC_LENGTH] = {"1/5 na zamrożenie wroga po zadaniu obrażeń."};
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


public CodMod_OnPlayerDamaged(iAttacker, iVictim, float &fDamage, WeaponID iWeaponID, iDamageType){
	if(g_bHasItem[iAttacker] && GetClientTeam(iAttacker) != GetClientTeam(iVictim)){
		if(GetRandomInt(1, 100) >= 75){
			CodMod_Freeze(iVictim, 1.5);
		}
	}
}


