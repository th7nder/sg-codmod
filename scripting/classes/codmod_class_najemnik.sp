#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <th7manager>

#include <emitsoundany>

#define _IN_CODMOD_CLASS 1
#include <codmod301>
public Plugin myinfo = {
    name = "CodMod 301 - Class - Najemnik",
    author = "th7nder",
    description = "Najemnik Class from CodMod 301",
    version = "2.0",
    url = "http://serwery-go.pl"
};

WeaponID g_iWeapons[WEAPON_LIMIT] = {WEAPON_NONE};



char g_szClassName[128] = {"Najemnik"};
char g_szDesc[256] = {"120HP\n Dostęp do każdej broni(oprócz XM i Autokampy)\n 1/10 na 3x dmg\n+5000$ na starcie"};
const int g_iHealth = 0;
const int g_iStartingHealth = 120;
const int g_iArmor = 0;
const int g_iDexterity = 0;
const int g_iIntelligence = 0;
int g_iClassId = 0;
bool g_bHasClass[MAXPLAYERS+1]    = {false};

public void OnPluginStart(){
    g_iWeapons[0] = WEAPON_STANDARDPISTOLS;
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

public void CodMod_OnPlayerSpawn(int iClient){
    if(g_bHasClass[iClient]){
        SetEntProp(iClient, Prop_Send, "m_iAccount", GetEntProp(iClient, Prop_Send, "m_iAccount") + 5000);
    }
}

public CodMod_OnPlayerDamaged(int iAttacker, int iVictim, float &fDamage, WeaponID iWeaponID, int iDamageType){
    if(g_bHasClass[iAttacker]){
        if(GetRandomInt(1, 100) >= 94){
            fDamage *= 3.0;
        }
    }
}

public void CodMod_OnWeaponCanUse(int iClient, WeaponID iWeaponID, int &iCanUse, bool bBuy){
    if(g_bHasClass[iClient] && iWeaponID != WEAPON_G3SG1 && iWeaponID != WEAPON_XM1014){
        iCanUse = 2;
    }
}
