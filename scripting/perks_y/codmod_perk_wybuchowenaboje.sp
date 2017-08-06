#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <codmod301>


public Plugin:myinfo = {
	name = "Call of Duty Mod - Perk - Pas Amunicji",
	author = "th7nder",
	description = "CODMOD's Perk",
	version = "1.0",
	url = "http://th7.eu"
};

new const String:szClassName[NAME_LENGTH] = {"Wybuchowe Naboje"};
new const String:szDesc[DESC_LENGTH] = {"+5 dmg, po zabiciu zwłoki ofiary mają 1/4 szansy na wybuch."};
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



public CodMod_OnPlayerDamaged(int iAttacker, int iVictim, float &fDamage, WeaponID iWeaponID, int iDamageType){
	if(g_bHasItem[iAttacker]){
		fDamage += 5.0;
	}
}

public CodMod_OnPlayerDie(attacker, victim, bool headshot){
	if(g_bHasItem[attacker]){
		if(GetRandomInt(1, 4) == 1){
			CodMod_PerformEntityExplosion(victim, attacker, 50.0 + float(CodMod_GetWholeStat(attacker, INT) / 100), 250, 0.0, TH7_DMG_EXPLODE);
		}
	}
}
