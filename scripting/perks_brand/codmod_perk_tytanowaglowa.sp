#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <codmod301>
#define DMG_HEADSHOT        (1 << 30)

public Plugin:myinfo = {
	name = "Call of Duty Mod - Perk - Tytanowa Głowa",
	author = "th7nder",
	description = "CODMOD's Perk",
	version = "1.0",
	url = "http://th7.eu"
};

new const String:szClassName[NAME_LENGTH] = {"Tytanowa Głowa"};
new const String:szDesc[DESC_LENGTH] = {"Masz 1/8s na odbicie headshota!"};
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



public CodMod_OnPlayerDamaged(iAttacker, iVictim, float &fDamage, WeaponID iWeaponID, int iDamageType){
	if(g_bHasItem[iVictim] && GetRandomInt(1, 100) > 87 && (iDamageType & DMG_HEADSHOT)){
		CodMod_DealDamage(iVictim, iAttacker, fDamage, TH7_DMG_REFLECT);
		fDamage = 0.0;
	}
}
