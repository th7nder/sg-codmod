#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <codmod301>


public Plugin myinfo = {
    name = "Call of Duty Mod - Perk - Tajemnica Skoczka",
    author = "th7nder",
    description = "201 Rewrite Perk",
    version = "2.0",
    url = "http://th7.eu"
};

char szClassName[] = {"Tajemnica Skoczka"};
char szDesc[] = {"Za każde zabójstwo dostajesz +20HP oraz +10 do pierwszego magazynku."};
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
    if(g_bHasItem[iAttacker]){
        CodMod_Heal(iAttacker, iAttacker, 20);

        int iEntity = GetEntPropEnt(iAttacker, Prop_Send, "m_hActiveWeapon");
        WeaponID iWeaponID = CodMod_GetWeaponID(iEntity);
        if(iWeaponID != WEAPON_NONE){
            SetEntProp(iEntity, Prop_Send, "m_iClip1", GetEntProp(iEntity, Prop_Send, "m_iClip1") + 10);
        }
    }
}