#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>



public Plugin myinfo = {
    name = "Call of Duty Mod - Perk - Narzędzia Demolitions",
    author = "th7nder",
    description = "201 Rewrite Perk",
    version = "2.0",
    url = "http://th7.eu"
};

char szClassName[] = {"Narzędzia Demolitions"};
char szDesc[] = {"Otrzymujesz dynamit, który wybucha w promieniu 200u\n Zadaje 100(+1,5/1INT) obrażeń\n codmod_perk"};
int g_iPerkId;


bool g_bHasItem[MAXPLAYERS +1] = {false};


#define DYNAMITES 1
#define MAX_DYNAMITES 1
#define DAMAGE_DYNAMITE_FORMULA 100 + RoundFloat(float(CodMod_GetWholeStat(iClient, INT)) * 1.5)
#include <codmod301>

int g_iDynamites[MAXPLAYERS+1] = {0};
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
    g_iDynamites[iClient] = 0;
}

public void CodMod_OnPerkDisabled(int iClient, int iPerkId){
    if(iPerkId != g_iPerkId)
        return;

    g_bHasItem[iClient] = false;
}


public void CodMod_OnPlayerSpawn(int iClient){
    if(g_bHasItem[iClient]){
        g_iDynamites[iClient] = 0;
    }
}

public void CodMod_OnPerkSkillUsed(int iClient){
    if(!g_bHasItem[iClient])
        return;

    int iMaxDynamites = MAX_DYNAMITES;
    if(IsPlayerAlive(iClient) && g_iDynamites[iClient] == 0){
        PrintToChat(iClient, "%s Postawiłeś dynamit! Użyj go znowu aby zdetonować!", PREFIX_SKILL, iMaxDynamites - g_iDynamites[iClient]);
        g_iDynamites[iClient] = PlaceDynamite(iClient);
    } else if(g_iDynamites[iClient]){
        int iDamage = DAMAGE_DYNAMITE_FORMULA
        CodMod_PerformEntityExplosion(g_iDynamites[iClient], iClient, float(iDamage), 175, 0.0, TH7_DMG_DYNAMITE);
        PrintToChat(iClient, "%s Dynamit został wysadzony!", PREFIX_SKILL);
        g_iDynamites[iClient] = -1;
    } else if(IsPlayerAlive(iClient) && g_iDynamites[iClient] == -1){
        PrintToChat(iClient, "%s Wykorzystałeś już dynamit w tej rundzie", PREFIX_SKILL, iMaxDynamites)
    }
}
