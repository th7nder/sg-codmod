#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <codmod301>


public Plugin:myinfo = {
	name = "Call of Duty Mod - Perk - Defibrylator",
	author = "th7nder",
	description = "CODMOD's Perk",
	version = "1.0",
	url = "http://th7.eu"
};

new const String:szClassName[NAME_LENGTH] = {"Defibrylator"};
new const String:szDesc[DESC_LENGTH] = {"Masz 1/5 szansy na zreanimowanie losowego członka drużyny po zabiciu wroga."};
int g_iPerkId;

bool g_bHasItem[MAXPLAYERS +1] = {false};

public void OnPluginStart(){
	g_iPerkId = CodMod_RegisterPerk(szClassName, szDesc);
}


public void OnPluginEnd(){
	CodMod_UnregisterPerk(g_iPerkId);
}

public void OnClientPutInServer(iClient){
	g_bHasItem[iClient] = false;
}

public void CodMod_OnPerkEnabled(iClient, iPerkId){
	if(iPerkId != g_iPerkId)
		return;

	g_bHasItem[iClient] = true;

}


public void CodMod_OnPerkDisabled(int iClient, int iPerkId){
    if(iPerkId != g_iPerkId)
        return;

    g_bHasItem[iClient] = false;
}

int GetRandomTarget(int iExclude, int iTeam){
    int iCount = 0;
    int iTargets[MAXPLAYERS+1] = {-1};
    for(int i = 1; i <= MaxClients; i++){
        if(i != iExclude && IsClientInGame(i) && !IsPlayerAlive(i) && GetClientTeam(i) == iTeam){
            iTargets[iCount++] = i;
        }
    }

    return iTargets[GetRandomInt(0, iCount - 1)];
}



public void CodMod_OnPlayerDie(int iAttacker, int iVictim, bool bHeadshot){
    if(g_bHasItem[iAttacker]){
        if(GetRandomInt(1, 100) >= 80)
        {
        	int iTarget = GetRandomTarget(iAttacker, GetClientTeam(iAttacker));
        	if(iTarget != -1)
        	{
        		PrintToChatAll("%s %N zdefibrylował %N!", PREFIX_INFO, iAttacker, iTarget);
        		CS_RespawnPlayer(iTarget);
        	}
        }
    }
}

