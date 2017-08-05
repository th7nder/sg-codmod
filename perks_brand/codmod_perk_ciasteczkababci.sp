#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <codmod301>


public Plugin:myinfo = {
	name = "Call of Duty Mod - Perk - Ciasteczka Babci",
	author = "th7nder",
	description = "CODMOD's Perk",
	version = "1.0",
	url = "http://th7.eu"
};

new const String:szClassName[NAME_LENGTH] = {"Ciasteczka Babci"};
new const String:szDesc[DESC_LENGTH] = {"Za zabójstwo +20HP, odnowienie magazynku \n Odporny na umiejętności(TARCZA SWAT)"};
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


public void CodMod_OnTH7Dmg(int iVictim, int iAttacker, float &fDamage, int iTH7Dmg){
    if(g_bHasItem[iVictim]){
        fDamage = 0.0;
    }
}



public void CodMod_OnPlayerDie(int iAttacker, int iVictim, bool bHeadshot){
    if(g_bHasItem[iAttacker]){
        Player_RefillClip(iAttacker, -1, 1);
        CodMod_Heal(iAttacker, iAttacker, 20);
    }
}

