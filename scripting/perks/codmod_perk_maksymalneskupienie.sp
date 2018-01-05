#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <codmod301>


public Plugin myinfo = {
    name = "Call of Duty Mod - Perk - Maksymalne Skupienie",
    author = "th7nder",
    description = "201 Rewrite Perk",
    version = "2.0",
    url = "http://th7.eu"
};

const int g_iAdditionalExp = 800;
const int g_iAdditionalHSExp = 1500;
char szClassName[] = {"Maksymalne Skupienie"};
char szDesc[] = {"Za każde zabójstwo dodatkowe +800 expa, za HS +1500 expa"};
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

public void CodMod_OnGiveExp(int iAttacker, int iVictim, int &iExp, bool bHeadshot){
    if(g_bHasItem[iAttacker])
    {
       iExp += g_iAdditionalExp;
       if(bHeadshot)
       {
            iExp += g_iAdditionalHSExp;
       }
    }
}
