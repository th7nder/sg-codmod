#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>



public Plugin myinfo = {
    name = "Call of Duty Mod - Perk - Notatki Sapera",
    author = "th7nder",
    description = "201 Rewrite Perk",
    version = "2.0",
    url = "http://th7.eu"
};

char szClassName[] = {"Notatki Sapera"};
char szDesc[] = {"Posiada 3 miny(100dmg + 1,5/1 INT)\n codmod_perk"};
int g_iPerkId;


bool g_bHasItem[MAXPLAYERS +1] = {false};


#define MINES 1
#define MAX_MINES 3 //+ (CodMod_GetWholeStat(iClient, INT) / 50)
#define DAMAGE_MINE_FORMULA 100 + RoundFloat(float(CodMod_GetWholeStat(iClient, INT)) * 1.5)
#include <codmod301>

int g_iMines[MAXPLAYERS+1] = {0};
public void OnPluginStart(){
    g_iPerkId = CodMod_RegisterPerk(szClassName, szDesc);
}

public void OnPluginEnd(){
    CodMod_UnregisterPerk(g_iPerkId);
}

public void OnClientPutInServer(int iClient){
    g_bHasItem[iClient] = false;
}

public void CodMod_OnPerkEnabled(int iClient, int iPerkId){
    if(iPerkId != g_iPerkId)
        return;

    g_bHasItem[iClient] = true;
    g_iMines[iClient] = 0;
}

public void CodMod_OnPerkDisabled(int iClient, int iPerkId){
    if(iPerkId != g_iPerkId)
        return;

    g_bHasItem[iClient] = false;
}

public void CodMod_OnPlayerSpawn(int iClient){
    if(g_bHasItem[iClient]){
        g_iMines[iClient] = 0;
    }
}

public void CodMod_OnPerkSkillUsed(int iClient){
    if(!g_bHasItem[iClient] || !IsPlayerAlive(iClient))
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
