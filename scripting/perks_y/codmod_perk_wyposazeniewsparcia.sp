#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>


#define ROCKETS 1
#define MAX_ROCKETS 2 //+ (CodMod_GetWholeStat(iClient, INT) / 50)
#define DAMAGE_ROCKET_FORMULA 50 + RoundFloat(float(CodMod_GetWholeStat(iClient, INT)) * 0.5)
#include <codmod301>

int g_iRockets[MAXPLAYERS+1] = {0};
float g_fLastUse[MAXPLAYERS+1] = {0.0};
public Plugin:myinfo = {
    name = "Call of Duty Mod - Perk - Wyposazenie Wsparcia",
    author = "th7nder",
    description = "CODMOD's Perk",
    version = "1.5",
    url = "http://th7.eu"
};

new const String:szClassName[NAME_LENGTH] = {"Wyposażenie Wsparcia"};
new const String:szDesc[DESC_LENGTH] = {"Posiadasz 2 rakiety zadające +50dmg + 0.5/1 INT(codmod_perk)."};
new g_iPerkId;

new bool:g_bHasItem[MAXPLAYERS +1] = {false};


public OnPluginStart(){
    g_iPerkId = CodMod_RegisterPerk(szClassName, szDesc);
}

public OnPluginEnd(){
    CodMod_UnregisterPerk(g_iPerkId);
}


public void OnClientPutInServer(iClient){
    g_bHasItem[iClient] = false;
}

public void CodMod_OnPerkEnabled(iClient, iPerkId){
    if(iPerkId != g_iPerkId)
        return;

    g_bHasItem[iClient] = true;
    g_iRockets[iClient] = 0;
    g_fLastUse[iClient] = 0.0;
}

public void CodMod_OnPerkDisabled(iClient, iPerkId){
    if(iPerkId != g_iPerkId)
        return;

    g_bHasItem[iClient] = false;

}

public void CodMod_OnPlayerSpawn(iClient){
    if(g_bHasItem[iClient]){
        g_iRockets[iClient] = 0;
        g_fLastUse[iClient] = 0.0;
    }
}


public void CodMod_OnPerkSkillUsed(int iClient){
    if(!IsValidPlayer(iClient) || !IsPlayerAlive(iClient) || !g_bHasItem[iClient])
        return;

    if(GetGameTime() - g_fLastUse[iClient] < 4.0){
        PrintToChat(iClient, "%s Rakiety można używać co 4 sekundy!", PREFIX_SKILL);
        return;
    }
    int iMaxRockets = MAX_ROCKETS;
    if(g_iRockets[iClient] + 1 <= iMaxRockets){
        g_fLastUse[iClient] = GetGameTime();
        g_iRockets[iClient]++;
        PrintToChat(iClient, "%s Wystrzeliłeś rakietę! Zostały Ci %d rakiety", PREFIX_SKILL, iMaxRockets - g_iRockets[iClient]);
        FireRocket(iClient);
    } else {
        PrintToChat(iClient, "%s Wykorzystałeś już %d rakiet tej rundzie!", PREFIX_SKILL, iMaxRockets)
    }

}
