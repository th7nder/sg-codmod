#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <codmod301>


public Plugin myinfo = {
    name = "Call of Duty Mod - Perk - Wytrenowany Weteran",
    author = "th7nder",
    description = "201 Rewrite Perk",
    version = "2.0",
    url = "http://th7.eu"
};

char szClassName[] = {"Wytrenowany Weteran"};
char szDesc[] = {"+50 do witalności, -50 do szybkości."};
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
    CodMod_SetStat(iClient, HP_PERK, CodMod_GetStat(iClient, HP_PERK) + 50);
    CodMod_SetStat(iClient, DEX_PERK, CodMod_GetStat(iClient, DEX_PERK) - 50);
}

public void CodMod_OnPerkDisabled(int iClient, int iPerkId){
    if(iPerkId != g_iPerkId)
        return;

    g_bHasItem[iClient] = false;
    CodMod_SetStat(iClient, HP_PERK, CodMod_GetStat(iClient, HP_PERK) - 50);
    CodMod_SetStat(iClient, DEX_PERK, CodMod_GetStat(iClient, DEX_PERK) + 50);
}
