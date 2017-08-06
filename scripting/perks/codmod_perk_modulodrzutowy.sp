#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <codmod301>


public Plugin myinfo = {
    name = "Call of Duty Mod - Perk - Moduł Odrzutowy",
    author = "th7nder",
    description = "201 Rewrite Perk",
    version = "2.0",
    url = "http://th7.eu"
};

char szClassName[] = {"Moduł Odrzutowy"};
char szDesc[] = {"Wyrzuca Cie z siłą 666(+int) w kierunku celownika \n CTRL + SPACJA, 4 sec cooldown"};
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

float g_fLastJump[MAXPLAYERS+1] = {0.0};

public void CodMod_OnPerkEnabled(int iClient, int iPerkId){
    if(iPerkId != g_iPerkId)
        return;

    g_bHasItem[iClient] = true;
    g_fLastJump[iClient] = 0.0;
}

public void CodMod_OnPerkDisabled(int iClient, int iPerkId){
    if(iPerkId != g_iPerkId)
        return;

    g_bHasItem[iClient] = false;
}

public Action OnPlayerRunCmd(int iClient, int &iButtons, int &iImpulse, float fVel[3], float fAngles[3], int &iWeapon) {
    if(g_bHasItem[iClient] && iButtons & IN_DUCK && iButtons & IN_JUMP){
        if(GetGameTime() > g_fLastJump[iClient]) {
            g_fLastJump[iClient] = GetGameTime() + 4.0;
            Launch(iClient);
        }
    }

    return Plugin_Continue;
}
