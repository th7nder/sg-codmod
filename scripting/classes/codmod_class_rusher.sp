#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <th7manager>

#include <emitsoundany>

#define _IN_CODMOD_CLASS 1
#include <codmod301>
public Plugin myinfo = {
    name = "CodMod 301 - Class - Rusher",
    author = "th7nder",
    description = "Rusher Class from CodMod 301",
    version = "2.0",
    url = "http://serwery-go.pl"
};

WeaponID g_iWeapons[WEAPON_LIMIT] = {WEAPON_NONE};



char g_szClassName[128] = {"Rusher"};
char g_szDesc[256] = {"125HP, Nova, P250 \n +50 kondycji \n 1/14 na 2x dmg z novy, +10 dmg z novy"};
const int g_iHealth = 0;
const int g_iStartingHealth = 125;
const int g_iArmor = 0;
const int g_iDexterity = 50;
const int g_iIntelligence = 0;
int g_iClassId = 0;
bool g_bHasClass[MAXPLAYERS+1]    = {false};
public void OnPluginStart(){
    g_iWeapons[0] = WEAPON_NOVA;
    g_iWeapons[1] = WEAPON_P250;
    g_iClassId = CodMod_RegisterClass(g_szClassName, g_szDesc, g_iHealth, g_iArmor, g_iDexterity, g_iIntelligence, g_iWeapons, 0, g_iStartingHealth);
}

public void OnPluginEnd(){
    CodMod_UnregisterClass(g_iClassId);
}


public int CodMod_OnChangeClass(int iClient, int iPrevious, int iNext){
    if(iNext != g_iClassId) {
        g_bHasClass[iClient] = false;
    } else {
        g_bHasClass[iClient] = true;
    }

}

public CodMod_OnPlayerDamaged(int iAttacker, int iVictim, float &fDamage, WeaponID iWeaponID, int iDamageType){
    if(g_bHasClass[iAttacker] && iWeaponID == WEAPON_NOVA && GetRandomInt(1, 14) == 1){
        fDamage *= 2.0;
    }
    fDamage += 10.0;
}
