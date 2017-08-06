#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>

#include <emitsoundany>

#define _IN_CODMOD_CLASS 1
#define SANDBAGS 1
#define MAX_SANDBAGS 3 + (CodMod_GetWholeStat(iClient, INT) / 50)
int g_iSandbagOwners[2048] = {0};
#include <codmod301>
public Plugin myinfo = {
    name = "CodMod 301 - Class - Obrońca",
    author = "th7nder",
    description = "Obrońca Class from CodMod 301",
    version = "2.0",
    url = "http://serwery-go.pl"
};

WeaponID g_iWeapons[WEAPON_LIMIT] = {WEAPON_NONE};



char g_szClassName[128] = {"Obrońca"};
char g_szDesc[128] = {"140HP, M249, Glock/HKP2000, Molotov \n codmod_skill - 3 worki \n Odporny na Miny"};
const int g_iHealth = 0;
const int g_iStartingHealth = 140;
const int g_iArmor = 0;
const int g_iDexterity = 0;
const int g_iIntelligence = 0;
int g_iClassId = 0;
bool g_bHasClass[MAXPLAYERS+1]    = {false};

int g_iSandbags[MAXPLAYERS+1] = {0};
float g_fLastUse[MAXPLAYERS+1] = {0.0};
public void OnPluginStart(){
    g_iWeapons[0] = WEAPON_M249;
    g_iWeapons[1] = WEAPON_STANDARDPISTOLS;
    g_iWeapons[2] = WEAPON_MOLOTOV;
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

    g_iSandbags[iClient] = 0;
}

public void CodMod_OnPlayerSpawn(int iClient){
    if(g_bHasClass[iClient]){
        g_iSandbags[iClient] = 0;
    }
}

public void CodMod_OnTH7Dmg(int iVictim, int iAttacker, float &fDamage, int iTH7Dmg){
    if(g_bHasClass[iVictim]){
        if(iTH7Dmg == TH7_DMG_MINE/* || iTH7Dmg == TH7_DMG_ROCKET || iTH7Dmg == TH7_DMG_DYNAMITE*/){
            fDamage = 0.0;
        }
    }
}
public void CodMod_OnClassSkillUsed(int iClient){
    if(!g_bHasClass[iClient] || !IsPlayerAlive(iClient))
        return;

    if(GetGameTime() - g_fLastUse[iClient] < 2.0){
        PrintToChat(iClient, "%s Worki można używać co 2 sekundy!", PREFIX_SKILL);
        return;
    }
    int iMaxSandbags = MAX_SANDBAGS;
    if(g_iSandbags[iClient] + 1 <= iMaxSandbags){
        g_fLastUse[iClient] = GetGameTime();
        g_iSandbags[iClient]++;
        PrintToChat(iClient, "%s Postawiłeś worek! Zostały Ci %d worki", PREFIX_SKILL, iMaxSandbags - g_iSandbags[iClient]);
        Player_PlaceSandbag(iClient);
    } else {
        PrintToChat(iClient, "%s Wykorzystałeś już %d worków tej rundzie!", PREFIX_SKILL, iMaxSandbags)
    }
}