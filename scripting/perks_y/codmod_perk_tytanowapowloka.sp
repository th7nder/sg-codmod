#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <codmod301>


public Plugin:myinfo = {
	name = "Call of Duty Mod - Perk - Tytanowa Powłoka",
	author = "th7nder",
	description = "CODMOD's Perk",
	version = "1.0",
	url = "http://th7.eu"
};

new const String:szClassName[NAME_LENGTH] = {"Tytanowa Powłoka"};
new const String:szDesc[DESC_LENGTH] = {"Jesteś odporny na nóż."};
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


public void CodMod_OnTH7Dmg(int iVictim, int iAttacker, float &fDamage, int iTH7Dmg){
    if(g_bHasItem[iVictim] && iTH7Dmg == TH7_DMG_THROWINGKNIFE)
    {
       fDamage = 0.0;
    }

}




public CodMod_OnPlayerDamagedPerk(iAttacker, iVictim, float &fDamage, WeaponID iWeaponID, iDamageType){
	if(g_bHasItem[iVictim] && iWeaponID == WEAPON_KNIFE){
		fDamage *= 0.0;
	}
}
