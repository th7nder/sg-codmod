#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <th7manager>

#include <emitsoundany>

#define _IN_CODMOD_CLASS 1
#define MINES 1
#define BURNING_MINES 1
#define MAX_MINES 1 + (CodMod_GetWholeStat(iClient, INT) / 25)
#define DAMAGE_MINE_FORMULA 50
#define ON_FIRE 1
bool g_bOnFire[MAXPLAYERS+1] = {false};

int g_iMines[MAXPLAYERS+1] = {0};
#include <codmod301>
public Plugin myinfo = {
    name = "CodMod 301 - Class - Piroman",
    author = "th7nder",
    description = "Major Class from CodMod 301",
    version = "2.0",
    url = "http://serwery-go.pl"
};

WeaponID g_iWeapons[WEAPON_LIMIT] = {WEAPON_NONE};



char g_szClassName[128] = {"Piroman"};
char g_szDesc[256] = {"125HP, UMP45, Dual Elite, Molotov \n +5dmg do wszystkich broni \n 1/12 na podpalenie (10dmg+int/5 per sec, 3 sec)\n Posiada miny, ktore podpalają(50dmg, +15/sec)"};
const int g_iHealth = 0;
const int g_iStartingHealth = 125;
const int g_iArmor = 0;
const int g_iDexterity = 0;
const int g_iIntelligence = 0;
int g_iClassId = 0;
bool g_bHasClass[MAXPLAYERS+1]    = {false};

public void OnPluginStart(){
    g_iWeapons[0] = WEAPON_UMP45;
    g_iWeapons[1] = WEAPON_ELITE;
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
    }

    g_bOnFire[iClient] = false;
    g_iMines[iClient] = 0;
}

public CodMod_OnPlayerSpawn(int iClient){
    g_bOnFire[iClient] = false;
    g_iMines[iClient] = 0;
}

public CodMod_OnPlayerDamaged(int iAttacker, int iVictim, float &fDamage, WeaponID iWeaponID, int iDamageType){
    if(g_bHasClass[iAttacker]){
        fDamage += 5.0;
        if(!g_bOnFire[iVictim] && GetRandomInt(1, 12) == 6) {
            PrintToChat(iAttacker, "%s Podpaliłeś gracza!", PREFIX_SKILL);
            PrintToChat(iVictim, "%s Zostałeś podpalony!", PREFIX_SKILL);
            CodMod_Burn(iAttacker, iVictim, 3.0, 1.0, 10.0 + (float(CodMod_GetWholeStat(iAttacker, INT)) / 5)  );
        }
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