#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>

#include <emitsoundany>

#define _IN_CODMOD_CLASS 1
#include <codmod301>
public Plugin myinfo = {
    name = "CodMod 301 - Class - Snajper",
    author = "th7nder",
    description = "Snajper Class from CodMod 301",
    version = "2.0",
    url = "http://serwery-go.pl"
};

WeaponID g_iWeapons[WEAPON_LIMIT] = {WEAPON_NONE};
#define ADDITIONAL_MULTIPLIER 2.0 - STRENGTH_MULTIPLIER
char g_szClassName[128] = {"Snajper"};
char g_szDesc[128] = {"120HP, AWP(110%% dmg), Deagle \n 1dmg/1siły"};
const int g_iHealth = 0;
const int g_iStartingHealth = 120;
const int g_iArmor = 0;
const int g_iDexterity = 0;
const int g_iIntelligence = 0;
int g_iClassId = 0;
bool g_bHasClass[MAXPLAYERS+1]    = {false};
public void OnPluginStart(){
    g_iWeapons[0] = WEAPON_AWP;
    g_iWeapons[1] = WEAPON_DEAGLE;
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
    if(g_bHasClass[iAttacker]){

        if(iWeaponID == WEAPON_AWP){
            fDamage *= 1.1;
            fDamage += (float(CodMod_GetWholeStat(iAttacker, STRENGTH)) * ADDITIONAL_MULTIPLIER);

        }
    }
}
