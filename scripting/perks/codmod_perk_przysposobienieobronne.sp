#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <codmod301>


public Plugin myinfo = {
    name = "Call of Duty Mod - Perk - Przysposobienie Obronne",
    author = "th7nder",
    description = "201 Rewrite Perk",
    version = "2.0",
    url = "http://th7.eu"
};


const int g_iAdditionalArmor = 25;
const int g_iAdditionalHealth = 25;
char szClassName[] = {"Przysposobienie Obronne"};
char szDesc[] = {"+25 do wytrzymałości, +25 witalności"};
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
    CodMod_SetStat(iClient, ARMOR_PERK, CodMod_GetStat(iClient, ARMOR_PERK) + g_iAdditionalArmor);
    CodMod_SetStat(iClient, HP_PERK, CodMod_GetStat(iClient, HP_PERK) + g_iAdditionalHealth);
}

public void CodMod_OnPerkDisabled(int iClient, int iPerkId){
    if(iPerkId != g_iPerkId)
        return;

    g_bHasItem[iClient] = false;
    CodMod_SetStat(iClient, ARMOR_PERK, CodMod_GetStat(iClient, ARMOR_PERK) - g_iAdditionalArmor);
    CodMod_SetStat(iClient, HP_PERK, CodMod_GetStat(iClient, HP_PERK) - g_iAdditionalHealth);
}
