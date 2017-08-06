#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <codmod301>

#include <th7manager>
public Plugin myinfo = {
    name = "Call of Duty Mod - Perk - Niezbędnik GROMu",
    author = "th7nder",
    description = "201 Rewrite Perk",
    version = "2.0",
    url = "http://th7.eu"
};

char szClassName[] = {"Niezbędnik GROMu"};
char szDesc[] = {"Gdy otrzymasz pierwszy damage znikasz na 3 sekundy."};
int g_iPerkId;


bool g_bHasItem[MAXPLAYERS +1] = {false};

bool g_bInvisible[MAXPLAYERS+1] = {false};
bool g_bWasInvisible[MAXPLAYERS+1] = {false};


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

    g_bInvisible[iClient] = false;
    g_bWasInvisible[iClient] = false;
}

public void CodMod_OnPerkDisabled(int iClient, int iPerkId){
    if(iPerkId != g_iPerkId)
        return;

    g_bHasItem[iClient] = false;


    if(iPerkId == g_iPerkId && g_bInvisible[iClient]){
        TH7_SetVisible(iClient);
    }

    g_bInvisible[iClient] = false;
    g_bWasInvisible[iClient] = false;
}


public void CodMod_OnPlayerSpawn(int iClient){
    if(g_bInvisible[iClient] && IsPlayerAlive(iClient)){
        TH7_SetVisible(iClient);
        g_bInvisible[iClient] = false;
    }
    g_bWasInvisible[iClient] = false;
}


public Action Timer_SetVisible(Handle hTimer, int iClient){
    iClient = GetClientFromSerial(iClient);
    if(!IsValidPlayer(iClient)){
        return Plugin_Stop;
    }

    if(g_bInvisible[iClient] && IsPlayerAlive(iClient)){
        TH7_SetVisible(iClient);
        g_bInvisible[iClient] = false;
    }

    return Plugin_Stop;
}

public CodMod_OnPlayerDamaged(int iAttacker, int iVictim, float &fDamage, WeaponID iWeaponID, int iDamageType){
    if(g_bHasItem[iVictim] && !g_bWasInvisible[iVictim]){
        g_bInvisible[iVictim] = true;
        g_bWasInvisible[iVictim] = true;
        TH7_SetInvisible(iVictim);
        CreateTimer(3.0, Timer_SetVisible, GetClientSerial(iVictim));
    }

    if(g_bHasItem[iVictim] && g_bInvisible[iVictim] && (iWeaponID == WEAPON_MOLOTOV || iWeaponID == WEAPON_HEGRENADE || (iDamageType & DMG_BURN))){
        fDamage = 0.0;
    }

}
