#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>

#include "include/emitsoundany.inc"

#define _IN_CODMOD_CLASS 1
#define DOUBLE_JUMP 1
#define DYNAMITES 1
#define MAX_DYNAMITES 1
#define DAMAGE_DYNAMITE_FORMULA 100 + (CodMod_GetWholeStat(iClient, INT) + (CodMod_GetWholeStat(iClient, INT) / 2))
#include <codmod301>
public Plugin myinfo = {
    name = "CodMod 301 - Class - Demolitions",
    author = "th7nder",
    description = "Demolitions Class from CodMod 301",
    version = "2.0",
    url = "http://serwery-go.pl"
};

WeaponID g_iWeapons[WEAPON_LIMIT] = {WEAPON_NONE};



char g_szClassName[128] = {"Demolitions"};
char g_szDesc[128] = {"110HP, SG553, P250\n codmod_skill - Dynamit(100 dmg + 1,5/1 INT) \n Wszystkie granaty, 1/4 z HE \n Podwójny skok"};
const int g_iHealth = 0;
const int g_iStartingHealth = 110;
const int g_iArmor = 0;
const int g_iDexterity = 0;
const int g_iIntelligence = 0;
int g_iClassId = 0;
bool g_bHasClass[MAXPLAYERS+1]    = {false};
int g_iDynamites[MAXPLAYERS+1] = {0};

public void OnPluginStart(){
    g_iWeapons[0] = WEAPON_SG556;
    g_iWeapons[1] = WEAPON_P250;
    g_iWeapons[2] = WEAPON_FLASHBANG;
    g_iWeapons[3] = WEAPON_SMOKEGRENADE;
    g_iWeapons[4] = WEAPON_HEGRENADE;
    g_iWeapons[5] = WEAPON_MOLOTOV;
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
        g_iDynamites[iClient] = 0;
    }
}

public CodMod_OnPlayerDamaged(int iAttacker, int iVictim, float &fDamage, WeaponID iWeaponID, int iDamageType){
    if(g_bHasClass[iAttacker]){
        if(iWeaponID == WEAPON_HEGRENADE && GetRandomInt(1, 100) >= 75){
            fDamage *= 300.0;
        }
    }
}

public Action OnPlayerRunCmd(int iClient, int &iButtons, int &iImpulse, float fVel[3], float fAngles[3], int &iWeapon) {
    if(g_bHasClass[iClient]){
        DoubleJump(iClient);
    }

    return Plugin_Continue;
}

public void CodMod_OnClassSkillUsed(int iClient){
    if(!g_bHasClass[iClient])
        return;

    int iMaxDynamites = MAX_DYNAMITES;
    if(IsPlayerAlive(iClient) && g_iDynamites[iClient] == 0){
        PrintToChat(iClient, "%s Postawiłeś dynamit! Użyj go znowu aby zdetonować!", PREFIX_SKILL);
        g_iDynamites[iClient] = PlaceDynamite(iClient);
    } else if(g_iDynamites[iClient]){
        int iDamage = DAMAGE_DYNAMITE_FORMULA
        CodMod_PerformEntityExplosion(g_iDynamites[iClient], iClient, float(iDamage), 175, 0.0, TH7_DMG_DYNAMITE);
        PrintToChat(iClient, "%s Dynamit został wysadzony!", PREFIX_SKILL);
        g_iDynamites[iClient] = -1;
    } else if(IsPlayerAlive(iClient) && g_iDynamites[iClient] == -1){
        PrintToChat(iClient, "%s Wykorzystałeś już dynamit w tej rundzie", PREFIX_SKILL, iMaxDynamites)
    }
}
