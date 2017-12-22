#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <th7manager>

#include <emitsoundany>

#define _IN_CODMOD_CLASS 1
#define ON_FIRE 1
bool g_bOnFire[MAXPLAYERS+1] = {false};
#include <codmod301>
public Plugin myinfo = {
    name = "CodMod 301 - Class - Major",
    author = "th7nder",
    description = "Major Class from CodMod 301",
    version = "2.0",
    url = "http://serwery-go.pl"
};

WeaponID g_iWeapons[WEAPON_LIMIT] = {WEAPON_NONE};



char g_szClassName[128] = {"Major [Premium]"};
char g_szDesc[256] = {"120HP, SG556, P250 \n 1/10 na wybuch wokół gracza 20dmg +0.5int \n 1/15 na odbicie pocisku \n Za zabójstwo 20HP "};
const int g_iHealth = 0;
const int g_iStartingHealth = 120;
const int g_iArmor = 0;
const int g_iDexterity = 0;
const int g_iIntelligence = 0;
int g_iClassId = 0;
bool g_bHasClass[MAXPLAYERS+1]    = {false};

public void OnPluginStart(){
    g_iWeapons[0] = WEAPON_SG556;
    g_iWeapons[1] = WEAPON_P250;
    g_iClassId = CodMod_RegisterClass(g_szClassName, g_szDesc, g_iHealth, g_iArmor, g_iDexterity, g_iIntelligence, g_iWeapons, ADMFLAG_SLAY, g_iStartingHealth);
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

    g_bOnFire[iClient] = false;
}

public CodMod_OnPlayerSpawn(int iClient){
    g_bOnFire[iClient] = false;
}

public CodMod_OnPlayerDamaged(int iAttacker, int iVictim, float &fDamage, WeaponID iWeaponID, int iDamageType){
    if(g_bHasClass[iAttacker]){
        if(GetRandomInt(1, 100) >= 90){
            CodMod_PerformEntityExplosion(iVictim, iAttacker, 20.0 + float(CodMod_GetWholeStat(iAttacker, INT)) * 0.5, 300, 0.0, TH7_DMG_EXPLODE, false);

        }
    }

    if(g_bHasClass[iVictim]){
        if(GetRandomInt(1, 15) == 1) {
            CodMod_DealDamage(iVictim, iAttacker, fDamage, TH7_DMG_REFLECT);
            fDamage = 0.0;
            PrintToChat(iVictim, "%s Pocisk został odbity!", PREFIX_SKILL);
        }
    }
}

public void CodMod_OnPlayerDie(int iAttacker, int iVictim, bool bHeadshot){
    if(g_bHasClass[iAttacker]){
        CodMod_Heal(iAttacker, iAttacker, 20);
    }
}