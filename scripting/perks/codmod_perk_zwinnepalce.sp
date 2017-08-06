#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <codmod301>


public Plugin myinfo = {
    name = "Call of Duty Mod - Perk - Zwinne Palce",
    author = "th7nder",
    description = "201 Rewrite Perk",
    version = "2.0",
    url = "http://th7.eu"
};

char szClassName[] = {"Zwinne Palce"};
char szDesc[] = {"Natychmiastowe przeładowanie broni."};
int g_iPerkId;


bool g_bHasItem[MAXPLAYERS +1] = {false};



int g_iOffsetNextAttack;
int g_iOffsetActiveWeapon;

int g_iOffsetTimeWeaponIdle;
int g_iOffsetNextPrimaryAttack;

public void OnPluginStart(){
    g_iPerkId = CodMod_RegisterPerk(szClassName, szDesc);
    HookEvent("weapon_reload", Event_WeaponReload);
    g_iOffsetNextAttack = FindSendPropOffs("CBasePlayer", "m_flNextAttack");
    g_iOffsetActiveWeapon = FindSendPropOffs("CBasePlayer", "m_hActiveWeapon");

    g_iOffsetTimeWeaponIdle = FindSendPropOffs("CBaseCombatWeapon", "m_flTimeWeaponIdle");
    g_iOffsetNextPrimaryAttack = FindSendPropOffs("CBaseCombatWeapon", "m_flNextPrimaryAttack");
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


public Action Event_WeaponReload(Event hEvent, const char[] szEventName, bool bBroadcast){
    int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
    if(g_bHasItem[iClient]){
        float fTargetTime = GetGameTime();
        SetEntDataFloat(iClient, g_iOffsetNextAttack, fTargetTime, true);
        int iEntity = GetEntDataEnt2(iClient, g_iOffsetActiveWeapon);
        SetEntDataFloat(iEntity, g_iOffsetTimeWeaponIdle, fTargetTime, true);
        SetEntDataFloat(iEntity, g_iOffsetNextPrimaryAttack, fTargetTime, true);

    }
}
