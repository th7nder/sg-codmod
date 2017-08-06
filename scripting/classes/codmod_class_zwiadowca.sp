#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>

#include <emitsoundany>

#define SPAWNTELEPORT 1
#define _IN_CODMOD_CLASS 1
#define TELEPORTS 1
#define MAX_TELEPORTS 1
#include <codmod301>
public Plugin myinfo = {
    name = "CodMod 301 - Class - Zwiadowca",
    author = "th7nder",
    description = "Zwiadowca Class from CodMod 301",
    version = "2.0",
    url = "http://serwery-go.pl"
};

WeaponID g_iWeapons[WEAPON_LIMIT] = {WEAPON_NONE};



char g_szClassName[128] = {"Zwiadowca"};
char g_szDesc[128] = {"120HP, PP-Bizon, P250\n codmod_skill - teleport na spawn i odnawia 50% hp,\n +10 kondycji "};
const int g_iHealth = 0;
const int g_iStartingHealth = 120;
const int g_iArmor = 0;
const int g_iDexterity = 10;
const int g_iIntelligence = 0;
int g_iClassId = 0;
bool g_bHasClass[MAXPLAYERS+1]    = {false};

int g_iTeleports[MAXPLAYERS+1] = {0};
float g_fLastUse[MAXPLAYERS+1] = {0.0};
public void OnPluginStart(){
    g_iWeapons[0] = WEAPON_BIZON;
    g_iWeapons[1] = WEAPON_P250;
    g_iClassId = CodMod_RegisterClass(g_szClassName, g_szDesc, g_iHealth, g_iArmor, g_iDexterity, g_iIntelligence, g_iWeapons, 0, g_iStartingHealth);
    HookEvent("round_start", Event_OnRoundStart);
}

public Action Event_OnRoundStart(Event hEvent, const char[] szBroadcast, bool bBroadcast)
{
    for(int i = 0; i <= MaxClients; i++)
    {
        g_iTeleports[i] = 0;
    }
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

    g_iTeleports[iClient] = 0;
    g_fLastUse[iClient] = 0.0;
}

public void CodMod_OnPlayerSpawn(int iClient){
    if(g_bHasClass[iClient]){
        g_fLastUse[iClient] = 0.0;
    }
}

public void CodMod_OnClassSkillUsed(int iClient){
    if(!g_bHasClass[iClient] || !IsPlayerAlive(iClient))
        return;

    if(GetGameTime() - g_fLastUse[iClient] < 2.0){
        PrintToChat(iClient, "%s Teleport dozwolony co 2 sekundy!", PREFIX_SKILL);
        return;
    }

    int iMaxTeleports = MAX_TELEPORTS;
    if(g_iTeleports[iClient] + 1 <= iMaxTeleports){
        int iCurrentHealth = GetClientHealth(iClient);
        if(!RespawnAtSpawn(iClient)) {
            CS_RespawnPlayer(iClient);
            PrintToChat(iClient, "%s Zostałeś przeteleportowany na spawn i uleczony! ", PREFIX_SKILL);
        }
        int iMaxHealth = CodMod_GetPlayerInfo(iClient, HP_OVERRIDE) != 0 ? CodMod_GetPlayerInfo(iClient, HP_OVERRIDE) : CodMod_GetMaxHP(iClient);
        if(iCurrentHealth + RoundToFloor(0.5 * iMaxHealth) > iMaxHealth) {
            SetEntityHealth(iClient, iMaxHealth);
        } else {
            SetEntityHealth(iClient, iCurrentHealth + RoundToFloor(0.5 * iMaxHealth));
        }
        g_iTeleports[iClient]++;
        g_fLastUse[iClient] = GetGameTime();

    } else {
        PrintToChat(iClient, "%s Wykorzystałeś już %d teleportów w tej rundzie!", PREFIX_SKILL, iMaxTeleports)
    }
}

public CodMod_OnPlayerDamaged(int iAttacker, int iVictim, float &fDamage, WeaponID iWeaponID, int iDamageType){
    if(g_bHasClass[iAttacker]){
        fDamage += 5.0;
    }
}