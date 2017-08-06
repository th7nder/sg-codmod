#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <codmod301>


public Plugin myinfo = {
    name = "Call of Duty Mod - Perk - Bezlik Ammo",
    author = "th7nder",
    description = "201 Rewrite Perk",
    version = "2.0",
    url = "http://th7.eu"
};

char szClassName[] = {"Bezlik Ammo"};
char szDesc[] = {"Posiadasz nieskończoną ilość ammo."};
int g_iPerkId;


bool g_bHasItem[MAXPLAYERS +1] = {false};

int g_iOffsetClip = -1;
int g_iOffsetActiveWeapon = -1;

public void OnPluginStart(){
    g_iPerkId = CodMod_RegisterPerk(szClassName, szDesc);
    HookEvent("weapon_fire", Event_WeaponFire, EventHookMode_Post);

    g_iOffsetClip = FindSendPropOffs("CWeaponCSBase", "m_iClip1");
    g_iOffsetActiveWeapon = FindSendPropOffs("CBasePlayer", "m_hActiveWeapon");

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


public Action Event_WeaponFire(Event hEvent, const char[] szEventName, bool bBroadcast){
    int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
    if(g_bHasItem[iClient]){
        int iWeaponIdx = GetEntDataEnt2(iClient, g_iOffsetActiveWeapon);
        if(iWeaponIdx != -1){
            if(IsValidEdict(iWeaponIdx)){
                SetEntData(iWeaponIdx, g_iOffsetClip, GetEntData(iWeaponIdx, g_iOffsetClip) + 1, true);
            }
        }
    }
}
