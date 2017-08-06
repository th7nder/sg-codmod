#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>

#define _ON_FIRE 1
bool g_bOnFire[MAXPLAYERS+1] = {0};
#include <codmod301>

public Plugin:myinfo = {
	name = "Call of Duty Mod - Perk - Ciepło Spajka",
	author = "th7nder",
	description = "CODMOD's Perk",
	version = "1.0",
	url = "http://th7.eu"
};

new const String:szClassName[NAME_LENGTH] = {"Ciepło Spajka"};
new const String:szDesc[DESC_LENGTH] = {"Dostajesz Molotova, ktory ma 2x damage oraz 1/4 na 3s podpalenie 10dmg/1s"};
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


public void CodMod_OnPerkDisabled(int iClient, int iPerkId){
    if(iPerkId != g_iPerkId)
        return;

    g_bHasItem[iClient] = false;
}

public void CodMod_OnPlayerSpawn(int iClient){
    g_bOnFire[iClient] = false;
    if(g_bHasItem[iClient]){
        if(CodMod_GetPlayerNades(iClient, TH7_MOLOTOV) < 1){
            GivePlayerItem(iClient, "weapon_molotov");
        }
    }
}


public void CodMod_OnPlayerDamaged(int iAttacker, int iVictim, float &fDamage, WeaponID iWeaponID, int iDamageType){
    if(g_bHasItem[iAttacker]){
        if((iWeaponID == WEAPON_MOLOTOV)){
            fDamage *= 2.0

            if(GetRandomInt(1, 1000) >= 750 && !g_bOnFire[iVictim])
            {
                CodMod_Burn(iAttacker, iVictim, 3.0, 1.0, 10.0);
            }
        }
    }
}


