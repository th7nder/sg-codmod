#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <codmod301>


public Plugin myinfo = {
    name = "Call of Duty Mod - Perk - Zwrot do Nadawcy",
    author = "th7nder",
    description = "201 Rewrite Perk",
    version = "2.0",
    url = "http://th7.eu"
};

char szClassName[] = {"Zwrot do Nadawcy"};
char szDesc[] = {"Odbijasz cały damage z min do właściciela."};
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

public void CodMod_OnTH7Dmg(int iVictim, int iAttacker, float &fDamage, int iTH7Dmg){
    if(g_bHasItem[iVictim] && (iTH7Dmg == TH7_DMG_LASERMINE || iTH7Dmg == TH7_DMG_MINE)){
        PrintToChat(iVictim, "%s Damage odbity!", PREFIX_SKILL);
        CodMod_DealDamage(iVictim, iAttacker, fDamage, TH7_DMG_REFLECT);
        fDamage = 0.0;
    }
}
