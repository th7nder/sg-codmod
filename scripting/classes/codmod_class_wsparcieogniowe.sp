#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>

#include <emitsoundany>

#define _IN_CODMOD_CLASS 1
#define ROCKETS 1
#define MAX_ROCKETS 3 //+ (CodMod_GetWholeStat(iClient, INT) / 50)
#define DAMAGE_ROCKET_FORMULA 65 + RoundFloat(float(CodMod_GetWholeStat(iClient, INT)))
#include <codmod301>
public Plugin myinfo = {
    name = "CodMod 301 - Class - Wsparcie Ogniowe",
    author = "th7nder",
    description = "Wsparcie Ogniowe Class from CodMod 301",
    version = "2.0",
    url = "http://serwery-go.pl"
};

WeaponID g_iWeapons[WEAPON_LIMIT] = {WEAPON_NONE};



char g_szClassName[128] = {"Wsparcie Ogniowe"};
char g_szDesc[200] = {"120HP, UMP-45(+5dmg), CZ75\n \
                            3 rakiety(65dmg+INT)\n1/4 na podpalenie z rakiety(7dmg *3s)\n \
                            1/8 na odbicie 50% dmg w plecy\n \ 
                            Po śmierci wybucha 60dmg(+INT)"};
const int g_iHealth = 0;
const int g_iStartingHealth = 120;
const int g_iArmor = 0;
const int g_iDexterity = 0;
const int g_iIntelligence = 0;
int g_iClassId = 0;
bool g_bHasClass[MAXPLAYERS+1]    = {false};

int g_iRockets[MAXPLAYERS+1] = {0};
float g_fLastUse[MAXPLAYERS+1] = {0.0};
public void OnPluginStart(){
    g_iWeapons[0] = WEAPON_UMP45;
    g_iWeapons[1] = WEAPON_CZ;
    g_iWeapons[2] = WEAPON_FLASHBANG;
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
        g_fLastUse[iClient] = 0.0;
    }

    g_iRockets[iClient] = 0;
}

public void CodMod_OnPlayerSpawn(int iClient){
    if(g_bHasClass[iClient]){
        g_iRockets[iClient] = 0;
    }
}

public void CodMod_OnClassSkillUsed(int iClient){
    if(!g_bHasClass[iClient] || !IsPlayerAlive(iClient))
        return;

    if(GetGameTime() - g_fLastUse[iClient] < 4.0){
        PrintToChat(iClient, "%s Rakiety można używać co 4 sekundy!", PREFIX_SKILL);
        return;
    }
    int iMaxRockets = MAX_ROCKETS;
    if(g_iRockets[iClient] + 1 <= iMaxRockets){
        g_fLastUse[iClient] = GetGameTime();
        g_iRockets[iClient]++;
        PrintToChat(iClient, "%s Wystrzeliłeś rakietę! Zostały Ci %d rakiety", PREFIX_SKILL, iMaxRockets - g_iRockets[iClient]);
        FireRocket(iClient);
    } else {
        PrintToChat(iClient, "%s Wykorzystałeś już %d rakiet tej rundzie!", PREFIX_SKILL, iMaxRockets)
    }
}

public void CodMod_OnPlayerDie(int iAttacker, int iVictim, bool bHeadshot){
    if(g_bHasClass[iVictim]){
        CodMod_PerformEntityExplosion(iVictim, iVictim, 60.0 + (CodMod_GetWholeStat(iVictim, INT)), 320, 0.0, TH7_DMG_EXPLODE);
    }
}