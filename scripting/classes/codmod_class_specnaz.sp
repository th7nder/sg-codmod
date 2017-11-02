#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <th7manager>
#include <emitsoundany>

#define _IN_CODMOD_CLASS 1
#define DOUBLE_JUMP 1
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


char g_szClassName[128] = {"Specnaz"};
char g_szDesc[256] = {"120HP, AK47, P250 \n HEGrenade + Smoke \n Podwójny skok \n 1/3 na 3x dmg z HE"};
const int g_iHealth = 0;
const int g_iStartingHealth = 120;
const int g_iArmor = 0;
const int g_iDexterity = 15;
const int g_iIntelligence = 0;
int g_iClassId = 0;
bool g_bHasClass[MAXPLAYERS+1]    = {false};
public void OnPluginStart(){
    g_iWeapons[0] = WEAPON_P250;
    g_iWeapons[1] = WEAPON_AK47;
    g_iWeapons[2] = WEAPON_HEGRENADE;
    g_iWeapons[3] = WEAPON_SMOKEGRENADE;
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
        if(iWeaponID == WEAPON_HEGRENADE)
        {
            if(GetRandomInt(1, 100) >= 66)
            {
                fDamage *= 3.0;
                PrintToChat(iAttacker, "%s Potrójny damage z HE: %f!", PREFIX_SKILL, fDamage);
            }
        }
    }
}

public Action OnPlayerRunCmd(int iClient, int &iButtons, int &iImpulse, float fVel[3], float fAngles[3], int &iWeapon) {
    if(g_bHasClass[iClient]){
        DoubleJump(iClient);
    }

    return Plugin_Continue;
}
