#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <th7manager>

#include <emitsoundany>

#define _IN_CODMOD_CLASS 1
#include <codmod301>
public Plugin myinfo = {
    name = "CodMod 301 - Class - El Pistolero",
    author = "th7nder",
    description = "El Pistolero Class from CodMod 301",
    version = "2.0",
    url = "http://serwery-go.pl"
};

WeaponID g_iWeapons[WEAPON_LIMIT] = {WEAPON_NONE};



char g_szClassName[128] = {"El Pistolero"};
char g_szDesc[256] = {"120HP, Może kupić każdy pistolet \n Moduł Odrzutowy(CTRL + SPACE, co 5 sec) \n +5dmg do pistoli, 15%% redukcji obrażeń"};
const int g_iHealth = 0;
const int g_iStartingHealth = 120;
const int g_iArmor = 0;
const int g_iDexterity = 0;
const int g_iIntelligence = 0;
int g_iClassId = 0;
bool g_bHasClass[MAXPLAYERS+1]    = {false};
float g_fLastJump[MAXPLAYERS+1] = {0.0};
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

    g_fLastJump[iClient] = 0.0;
}

public Action OnPlayerRunCmd(int iClient, int &iButtons, int &iImpulse, float fVel[3], float fAngles[3], int &iWeapon) {
    if(g_bHasClass[iClient] && IsPlayerAlive(iClient))
    {
        static float g_fLastTry[MAXPLAYERS+1];
        if((iButtons & IN_JUMP) && (iButtons & IN_DUCK)  )
        {
            if(GetGameTime() - g_fLastJump[iClient] >= 5.0) {
                g_fLastJump[iClient] = GetGameTime();
                g_fLastTry[iClient] = g_fLastJump[iClient];
                Launch(iClient);
            } else if(GetGameTime() - g_fLastTry[iClient] >= 0.2){
                g_fLastTry[iClient] = GetGameTime();
                PrintToChat(iClient, "%s Do następnego uzycia zostało %.1f s!", PREFIX_SKILL, 5.0 - (GetGameTime() - g_fLastJump[iClient]));
            }
        }
    }

    

    return Plugin_Continue;
}


public CodMod_OnPlayerDamaged(int iAttacker, int iVictim, float &fDamage, WeaponID iWeaponID, int iDamageType){
    if(g_bHasClass[iAttacker]){
        fDamage += 5.0;
    }

    if(g_bHasClass[iVictim]){
        fDamage *= 0.85;
    }
}

public void CodMod_OnWeaponCanUse(int iClient, WeaponID iWeaponID, int &iCanUse, bool bBuy){
    if(g_bHasClass[iClient] && CodMod_WeaponIsPistol(iWeaponID)){
        iCanUse = 2;
    }
}
