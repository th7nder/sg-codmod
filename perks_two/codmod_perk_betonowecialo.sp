#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <codmod301>


public Plugin myinfo = {
    name = "Call of Duty Mod - Perk - Betonowe Ciało",
    author = "th7nder",
    description = "201 Rewrite Perk",
    version = "2.0",
    url = "http://th7.eu"
};

char szClassName[] = {"Betonowe Ciało"};
char szDesc[] = {"Można Cie zabić tylko headshotem(raz na 3 sec)"};
int g_iPerkId;


bool g_bHasItem[MAXPLAYERS +1] = {false};
float g_fLastReflected[MAXPLAYERS+1] = {0.0};


public void OnPluginStart(){
    g_iPerkId = CodMod_RegisterPerk(szClassName, szDesc);
}

public void OnPluginEnd(){
    CodMod_UnregisterPerk(g_iPerkId);
}

public void OnClientPutInServer(int iClient){
    g_bHasItem[iClient] = false;
    g_fLastReflected[iClient] = 0.0;
}

public void CodMod_OnPerkEnabled(int iClient, int iPerkId){
    if(iPerkId != g_iPerkId)
        return;

    g_bHasItem[iClient] = true;
    g_fLastReflected[iClient] = 0.0;
}

public void CodMod_OnPerkDisabled(int iClient, int iPerkId){
    if(iPerkId != g_iPerkId)
        return;

    g_bHasItem[iClient] = false;
}

public void CodMod_OnPlayerSpawn(int iClient){
    g_fLastReflected[iClient] = 0.0;
}

public void CodMod_OnPlayerDamaged(int iAttacker, int iVictim, float &fDamage, WeaponID iWeaponID, int iDamageType){
    if(g_bHasItem[iVictim] && !(iDamageType & CS_DMG_HEADSHOT)){
        if(g_fLastReflected[iVictim] == 0.0){
            g_fLastReflected[iVictim] = GetGameTime();
            fDamage = 0.0;
            PrintToChat(iVictim, "%s Damage został zredukowany!", PREFIX_SKILL);
        } else if(GetGameTime() - g_fLastReflected[iVictim] > 0.0 && GetGameTime() - g_fLastReflected[iVictim] < 3.0){
            fDamage = 0.0;
            PrintToChat(iVictim, "%s Damage został redukowany!", PREFIX_SKILL);
        }
    }
}
