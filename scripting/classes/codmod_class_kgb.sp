#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <th7manager>

#include <emitsoundany>

#define _IN_CODMOD_CLASS 1
#include <codmod301>
public Plugin myinfo = {
    name = "CodMod 301 - Class - KGB",
    author = "th7nder",
    description = "KGB Class from CodMod 301",
    version = "2.0",
    url = "http://serwery-go.pl"
};

WeaponID g_iWeapons[WEAPON_LIMIT] = {WEAPON_NONE};

#define ADDITIONAL_MULTIPLIER 0.50 - STRENGTH_MULTIPLIER


char g_szClassName[128] = {"KGB"};
char g_szDesc[256] = {"130HP, AK47, Glock \n 5HP za trafienie w ciało(10hp za HS) \n +5dmg do wszystkich broni"};
const int g_iHealth = 0;
const int g_iStartingHealth = 130;
const int g_iArmor = 0;
const int g_iDexterity = 0;
const int g_iIntelligence = 0;
int g_iClassId = 0;
bool g_bHasClass[MAXPLAYERS+1]    = {false};
public void OnPluginStart(){
    g_iWeapons[0] = WEAPON_GLOCK;
    g_iWeapons[1] = WEAPON_AK47;
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
        fDamage += 5.0;
        if(iWeaponID == WEAPON_AK47) {
            if(fDamage == CS_DMG_HEADSHOT) {
                CodMod_Heal(iAttacker, iAttacker, 10);
            } else {
                CodMod_Heal(iAttacker, iAttacker, 5);
            }
        }
    }
}
