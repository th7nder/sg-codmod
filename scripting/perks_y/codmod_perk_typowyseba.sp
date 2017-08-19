#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <codmod301>


public Plugin:myinfo = {
	name = "Call of Duty Mod - Perk - Typowy Seba",
	author = "th7nder",
	description = "CODMOD's Perk",
	version = "1.0",
	url = "http://th7.eu"
};

new const String:szClassName[NAME_LENGTH] = {"Typowy Seba"};
new const String:szDesc[DESC_LENGTH] = {"Zeus 1/1 - 10ammo, +25 kondycji"};
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


public void RemoveZeus(iClient){
	int iSize = GetEntPropArraySize(iClient, Prop_Send, "m_hMyWeapons");
	char szClassname[64];
	int iEnt = -1;
	for(int i = 0; i < iSize; i++){
		if((iEnt = GetEntPropEnt(iClient, Prop_Send, "m_hMyWeapons", i)) != -1 && IsValidEntity(iEnt)){
			GetEdictClassname(iEnt, szClassname, 64);
			if(StrEqual(szClassname, "weapon_taser")){
				RemovePlayerItem(iClient, iEnt);
				RemoveEdict(iEnt);
			}
		}
	}
}


public CodMod_OnPlayerSpawn(iClient){
	if(g_bHasItem[iClient]){
		RemoveZeus(iClient);
		int iWeapon = GivePlayerItem(iClient, "weapon_taser");
		if(iWeapon != -1){
			SetEntProp(iWeapon, Prop_Send, "m_iClip1", 10);
		}
	}
}


public void CodMod_OnWeaponCanUsePerk(int iClient, WeaponID iWeaponID, int &iCanUse, bool bBuy){
    if(g_bHasItem[iClient] && iWeaponID == WEAPON_TASER && !bBuy){
        iCanUse = 2;
    }
}


public CodMod_OnPlayerDamagedPerk(int iAttacker, int iVictim, float &fDamage, WeaponID iWeaponID, int iDamageType){
	if(g_bHasItem[iAttacker] && iWeaponID == WEAPON_TASER){
		fDamage *= 200.0;
	}
}

public CodMod_OnPerkEnabled(iClient, iPerkId){
	if(iPerkId != g_iPerkId)
		return;

	g_bHasItem[iClient] = true;
	CodMod_SetStat(iClient, DEX_PERK, CodMod_GetStat(iClient, DEX_PERK) + 25);

}

public CodMod_OnPerkDisabled(iClient, iPerkId){
	if(iPerkId != g_iPerkId)
		return;

	g_bHasItem[iClient] = false;
	CodMod_SetStat(iClient, DEX_PERK, CodMod_GetStat(iClient, DEX_PERK) - 25);
}
