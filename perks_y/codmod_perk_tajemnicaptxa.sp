#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>


#define DOUBLE_JUMP 1
#include <codmod301>
public Plugin:myinfo = {
	name = "Call of Duty Mod - Perk - Tajemnica Ptxa",
	author = "th7nder",
	description = "CODMOD's Perk",
	version = "1.0",
	url = "http://th7.eu"
};

new const String:szClassName[NAME_LENGTH] = {"Tajemnica Ptxa"};
new const String:szDesc[DESC_LENGTH] = {"Podwójny skok oraz odnawianie ammo po zabiciu."};
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

public void CodMod_OnPlayerDie(int iAttacker, int iVictim, bool bHeadshot){
    if(g_bHasItem[iAttacker]){
        Player_RefillClip(iAttacker, -1, 1);
    }
}


public Action OnPlayerRunCmd(int iClient, int &iButtons, int &iImpulse, float fVel[3], float fAngles[3], int &iWeapon) {
    if(g_bHasItem[iClient]){
        DoubleJump(iClient);
    }

    return Plugin_Continue;
}
