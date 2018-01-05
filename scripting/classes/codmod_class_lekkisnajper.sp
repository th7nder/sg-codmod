#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <th7manager>

#include <emitsoundany>

#define _IN_CODMOD_CLASS 1
#include <codmod301>
public Plugin myinfo = {
    name = "CodMod 301 - Class - Lekki Snajper",
    author = "th7nder",
    description = "Lekki Snajper Class from CodMod 301",
    version = "2.0",
    url = "http://serwery-go.pl"
};

WeaponID g_iWeapons[WEAPON_LIMIT] = {WEAPON_NONE};

#define ADDITIONAL_MULTIPLIER 0.9 - STRENGTH_MULTIPLIER


char g_szClassName[128] = {"Lekki Snajper"};
char g_szDesc[256] = {"140HP, Scout, FiveSeven \n 1/3 na potrójny damage ze scouta, \n Zmniejszona grawitacja \n 1 siły - 0.9dmg, 50%% widoczności"};
const int g_iHealth = 0;
const int g_iStartingHealth = 140;
const int g_iArmor = 0;
const int g_iDexterity = 20;
const int g_iIntelligence = 0;
int g_iClassId = 0;
bool g_bHasClass[MAXPLAYERS+1]    = {false};
public void OnPluginStart(){
    g_iWeapons[0] = WEAPON_SSG08;
    g_iWeapons[1] = WEAPON_FIVESEVEN;
    g_iClassId = CodMod_RegisterClass(g_szClassName, g_szDesc, g_iHealth, g_iArmor, g_iDexterity, g_iIntelligence, g_iWeapons, 0, g_iStartingHealth);
    CodMod_RegisterClassGravity(g_szClassName, 80);
}

public void OnPluginEnd(){
    CodMod_UnregisterClass(g_iClassId);
}


public int CodMod_OnChangeClass(int iClient, int iPrevious, int iNext){
    if(iPrevious == g_iClassId){
        TH7_DisableRenderColor(iClient);
    }
    if(iNext != g_iClassId) {
        g_bHasClass[iClient] = false;
    } else {
        g_bHasClass[iClient] = true;
        TH7_SetRenderColor(iClient, 255, 255, 255, 190);
    }


}

public CodMod_OnPlayerDamaged(int iAttacker, int iVictim, float &fDamage, WeaponID iWeaponID, int iDamageType){
    if(g_bHasClass[iAttacker]){

        if(iWeaponID == WEAPON_SSG08){
            fDamage += CodMod_GetWholeStat(iAttacker, STRENGTH) * ADDITIONAL_MULTIPLIER;
            if(GetRandomInt(1, 100) >= 67){
                fDamage *= 3.0;
            }
        }
    }
}
