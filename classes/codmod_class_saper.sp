#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>

#include <emitsoundany>

#define _IN_CODMOD_CLASS 1
#define MINES 1
#define MAX_MINES 3 //+ (CodMod_GetWholeStat(iClient, INT) / 50)
#define DAMAGE_MINE_FORMULA 100 + RoundFloat(float(CodMod_GetWholeStat(iClient, INT)) * 1.5)
#include <codmod301>
public Plugin myinfo = {
    name = "CodMod 301 - Class - Saper",
    author = "th7nder",
    description = "Saper Class from CodMod 301",
    version = "2.0",
    url = "http://serwery-go.pl"
};

WeaponID g_iWeapons[WEAPON_LIMIT] = {WEAPON_NONE};



char g_szClassName[128] = {"Saper"};
char g_szDesc[128] = {"120HP, P90, P250 \nPosiada 3 miny(100dmg + 1,5/1 INT)"};
const int g_iHealth = 0;
const int g_iStartingHealth = 120;
const int g_iArmor = 0;
const int g_iDexterity = 0;
const int g_iIntelligence = 0;
int g_iClassId = 0;
bool g_bHasClass[MAXPLAYERS+1]    = {false};

int g_iMines[MAXPLAYERS+1] = {0};
public void OnPluginStart(){
    g_iWeapons[0] = WEAPON_P90;
    g_iWeapons[1] = WEAPON_P250;
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

    g_iMines[iClient] = 0;
}

public void CodMod_OnPlayerSpawn(int iClient){
    if(g_bHasClass[iClient]){
        g_iMines[iClient] = 0;
    }
}

public void CodMod_OnClassSkillUsed(int iClient){
    if(!g_bHasClass[iClient] || !IsPlayerAlive(iClient))
        return;

    int iMaxMines = MAX_MINES;
    if(g_iMines[iClient] + 1 <= iMaxMines){

        if(PlaceMine(iClient)){
          g_iMines[iClient]++;
          PrintToChat(iClient, "%s Postawiłeś minę! Zostały Ci %d miny", PREFIX_SKILL, iMaxMines - g_iMines[iClient]);
        } else {
          PrintToChat(iClient, "%s Zła pozycja do miny!", PREFIX_SKILL);
        }


    } else {
        PrintToChat(iClient, "%s Wykorzystałeś już %d min w tej rundzie!", PREFIX_SKILL, iMaxMines)
    }
}
