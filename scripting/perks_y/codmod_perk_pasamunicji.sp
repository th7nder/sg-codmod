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

new const String:szClassName[NAME_LENGTH] = {"Pas Amunicji"};
new const String:szDesc[DESC_LENGTH] = {"+8 dmg z każdej broni i +20ammo do pierwszego magazynka."};
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
		int iEntity = -1;
		for(int i = 0; i <= 1; i++){
			iEntity = GetPlayerWeaponSlot(iClient, i);
			if(iEntity != -1 && IsValidEdict(iEntity)){
				SetEntProp(iEntity, Prop_Send, "m_iClip1", GetEntProp(iEntity, Prop_Send, "m_iClip1") + 20);
			}
		}
	}
}

public CodMod_OnPlayerDamagedPerk(int iAttacker, int iVictim, float &fDamage, WeaponID iWeaponID, int iDamageType){
	if(g_bHasItem[iAttacker]){
		fDamage += 8.0;
	}
}
