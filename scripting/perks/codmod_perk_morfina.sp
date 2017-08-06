#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <codmod301>


public Plugin myinfo = {
    name = "Call of Duty Mod - Perk - Morfina",
    author = "th7nder",
    description = "201 Rewrite Perk",
    version = "2.0",
    url = "http://th7.eu"
};

char szClassName[] = {"Morfina"};
char szDesc[] = {"Masz 1/3 szans na odrodzenie po śmierci."};
int g_iPerkId;


bool g_bHasItem[MAXPLAYERS +1] = {false};


public void OnPluginStart(){
    g_iPerkId = CodMod_RegisterPerk(szClassName, szDesc);
}

public void OnPluginEnd(){
    CodMod_UnregisterPerk(g_iPerkId);
}
public void OnClientPutInServer(int iClient){
    g_bHasItem[iClient] = false;
}

public void CodMod_OnPerkEnabled(int iClient, int iPerkId){
    if(iPerkId != g_iPerkId)
        return;

    g_bHasItem[iClient] = true;
}

public void CodMod_OnPerkDisabled(int iClient, int iPerkId){
    if(iPerkId != g_iPerkId)
        return;

    g_bHasItem[iClient] = false;
}

public void CodMod_OnPlayerDie(int iAttacker, int iVictim, bool bHeadshot){
    if(g_bHasItem[iVictim] && GetRandomInt(1, 100) >= 67){
        CreateTimer(0.3, Timer_Respawn, GetClientSerial(iVictim));
    }
}


public Action Timer_Respawn(Handle hTimer, int iClient){
    iClient = GetClientFromSerial(iClient);
    if(IsValidPlayer(iClient) && !IsPlayerAlive(iClient)){
        CS_RespawnPlayer(iClient);
    }
}
