#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#define ON_FIRE 1
bool g_bOnFire[MAXPLAYERS+1] = {false};
#include <codmod301>


public Plugin myinfo = {
    name = "Call of Duty Mod - Perk - Płonące Naboje",
    author = "th7nder",
    description = "201 Rewrite Perk",
    version = "2.0",
    url = "http://th7.eu"
};

char szClassName[] = {"Płonące Naboje"};
char szDesc[] = {"Masz 1/4 szans na podpalenie wroga(5dmg(+1/3INT), przez 3 sec co 1 sec)"};
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
    g_bOnFire[iClient] = false;
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


public void CodMod_OnPlayerSpawn(int iClient){
    g_bOnFire[iClient] = false;
}

public void CodMod_OnPlayerDamagedPerk(int iAttacker, int iVictim, float &fDamage, WeaponID iWeaponID, int iDamageType){
    if(g_bHasItem[iAttacker] && !g_bOnFire[iVictim] && GetRandomInt(1, 100) >= 75){
        g_bOnFire[iVictim] = true;
        PrintToChat(iAttacker, "%s Podpaliłeś gracza!", PREFIX_SKILL);
        PrintToChat(iVictim, "%s Zostałeś podpalony!", PREFIX_SKILL);
        CodMod_Burn(iAttacker, iVictim, 3.0, 1.0, 5.0 + float(CodMod_GetWholeStat(iAttacker, INT) / 3));
    }
}
