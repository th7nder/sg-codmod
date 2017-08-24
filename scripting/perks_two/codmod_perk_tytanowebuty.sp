#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <codmod301>


public Plugin myinfo = {
    name = "Call of Duty Mod - Perk - Tytanowe Buty",
    author = "th7nder",
    description = "201 Rewrite Perk",
    version = "2.0",
    url = "http://th7.eu"
};

char szClassName[] = {"Tytanowe Buty"};
char szDesc[] = {"Nie otrzymujesz obrażeń z upadku, oraz dostajesz +30 wytrzymałości."};
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
    SDKHook(iClient, SDKHook_OnTakeDamage, OnTakeDamage);
}

public void CodMod_OnPerkEnabled(int iClient, int iPerkId){
    if(iPerkId != g_iPerkId)
        return;

    g_bHasItem[iClient] = true;

    CodMod_SetStat(iClient, ARMOR_PERK, CodMod_GetStat(iClient, ARMOR_PERK) + 30);
}

public void CodMod_OnPerkDisabled(int iClient, int iPerkId){
    if(iPerkId != g_iPerkId)
        return;

    g_bHasItem[iClient] = false;
    CodMod_SetStat(iClient, ARMOR_PERK, CodMod_GetStat(iClient, ARMOR_PERK) - 30);
}

public void CodMod_OnPlayerDamagedPerk(int iAttacker, int iVictim, float &fDamage, WeaponID iWeaponID, int iDamageType){
    if(g_bHasItem[iVictim] && (iDamageType & DMG_FALL)){
        fDamage *= 0.0;
    }
}

public Action:OnTakeDamage(client, &attacker, &inflictor, &Float:damage, &damagetype)
{
    if(!g_bHasItem[client]) return Plugin_Continue;
    if (damagetype & DMG_FALL)
    {
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

