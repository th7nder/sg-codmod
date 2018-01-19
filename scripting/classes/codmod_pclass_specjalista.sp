#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <th7manager>
#include <lasermines>

#include <emitsoundany>

#define _IN_CODMOD_CLASS 1
#include <codmod301>
public Plugin myinfo = {
    name = "CodMod 301 - Class - Specjalista",
    author = "th7nder",
    description = "Specjalista Class from CodMod 301",
    version = "2.0",
    url = "http://serwery-go.pl"
};

WeaponID g_iWeapons[WEAPON_LIMIT] = {WEAPON_NONE};

#define MAX_LASERS 3
#define LASER_DMG 150.0+float(CodMod_GetWholeStat(iAttacker, INT))*1.0


char g_szClassName[128] = {"Specjalista [Premium]"};
char g_szDesc[256] = {"M4A1-S, USP\n 2(+1 za każde 50 int) lasery(150dmg + 1.5*int) \n 5HP(+1HP/3int)/6sec, Odnawianie ammo per kill, +5dmg \n Może kupić każdy granat"};
const int g_iHealth = 0;
const int g_iStartingHealth = 120;
const int g_iArmor = 0;
const int g_iDexterity = 0;
const int g_iIntelligence = 0;
int g_iClassId = 0;
bool g_bHasClass[MAXPLAYERS+1]    = {false};
int g_iMines[MAXPLAYERS+1] = {0};

Handle g_hHealingTimer = INVALID_HANDLE;
public void OnPluginStart(){
    g_iWeapons[0] = WEAPON_M4A1;
    g_iWeapons[1] = WEAPON_USP;
    g_iClassId = CodMod_RegisterClass(g_szClassName, g_szDesc, g_iHealth, g_iArmor, g_iDexterity, g_iIntelligence, g_iWeapons, ADMFLAG_CUSTOM6, g_iStartingHealth);
}

public CodMod_OnPlayerDamaged(int iAttacker, int iVictim, float &fDamage, WeaponID iWeaponID, int iDamageType){
    if(g_bHasClass[iAttacker]){
        fDamage += 5.0;
    }

}

public void OnPluginEnd(){
    CodMod_UnregisterClass(g_iClassId);
}

public void OnMapStart(){
    if(g_hHealingTimer != INVALID_HANDLE){
        KillTimer(g_hHealingTimer);
        g_hHealingTimer = INVALID_HANDLE;
    }

    g_hHealingTimer = CreateTimer(6.0, Timer_HealAll, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public void OnMapEnd(){
    if(g_hHealingTimer != INVALID_HANDLE){
        KillTimer(g_hHealingTimer);
        g_hHealingTimer = INVALID_HANDLE;
    }
}

public Action Timer_HealAll(Handle hTimer){
    for(int i = 1; i <= MaxClients; i++){
        if(g_bHasClass[i] && IsValidPlayer(i) && IsPlayerAlive(i)){
            CodMod_Heal(i, i, 5 + (CodMod_GetWholeStat(i, INT) / 3));
        }
    }
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

    int iMaxMines = MAX_LASERS;
    if(g_iMines[iClient] + 1 <= iMaxMines){

        int iColor[3];
        if(GetClientTeam(iClient) == CS_TEAM_T){
            iColor = {255, 127, 0};
        } else {
            iColor = {0, 127, 255};
        }
        if(PlantClientLasermine(iClient, 1.0, 1000, 300, 0, iColor))
        {
            g_iMines[iClient]++;
            PrintToChat(iClient, "%s Postawiłeś minę! Zostały Ci %d miny", PREFIX_SKILL, iMaxMines - g_iMines[iClient]);
        }
        else
        {
            PrintToChat(iClient, "%s Nie udało się postawić laserminy w tym miejscu.", PREFIX_SKILL);
        }
    } else {
        PrintToChat(iClient, "%s Wykorzystałeś już %d min w tej rundzie!", PREFIX_SKILL, iMaxMines)
    }
}

public Action:OnPreHitByLasermine(iVictim, &iAttacker, &iBeam, &iLasermine, int &iDamage) {
    if(g_bHasClass[iAttacker]) {
        iDamage = RoundToFloor(LASER_DMG);
        return Plugin_Changed
    }
    return Plugin_Continue;
}

public void CodMod_OnWeaponCanUse(int iClient, WeaponID iWeaponID, int &iCanUse, bool bBuy){
    if(g_bHasClass[iClient] && IsWeaponGrenade(iWeaponID)){
        iCanUse = 2;
    }
}

public Action Timer_Refill(Handle hTimer, int iSerial)
{
    int iClient = GetClientFromSerial(iSerial);
    if(iClient > 0)
    {
        Player_RefillClip(iClient, -1, 1);
    }
}



public void CodMod_OnPlayerDie(int iAttacker, int iVictim, bool bHeadshot){
    if(g_bHasClass[iAttacker]){
        CreateTimer(0.00, Timer_Refill, GetClientSerial(iAttacker));
    }
}
