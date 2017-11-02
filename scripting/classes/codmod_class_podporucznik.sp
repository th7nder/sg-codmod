#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <th7manager>

#include <emitsoundany>

#define MAX_SWITCHES 1 + (CodMod_GetWholeStat(iClient, INT) / 25)
#define _IN_CODMOD_CLASS 1
#include <codmod301>
public Plugin myinfo = {
    name = "CodMod 301 - Class - Podporucznik",
    author = "th7nder",
    description = "Podporucznik Class from CodMod 301",
    version = "2.0",
    url = "http://serwery-go.pl"
};

WeaponID g_iWeapons[WEAPON_LIMIT] = {WEAPON_NONE};

#define ADDITIONAL_MULTIPLIER 0.50 - STRENGTH_MULTIPLIER


char g_szClassName[128] = {"Podporucznik"};
char g_szDesc[256] = {"120 HP, Galil, Berrety, Molotov \n codmod_special - podmiana miejscami(1x + 1/25int) \n +10HP, +10dmg Beretty, +5dmg Galil per kill"};
const int g_iHealth = 0;
const int g_iStartingHealth = 120;
const int g_iArmor = 0;
const int g_iDexterity = 0;
const int g_iIntelligence = 0;
int g_iClassId = 0;
bool g_bHasClass[MAXPLAYERS+1]    = {false};
int g_iSwitches[MAXPLAYERS+1] = {0};
int g_iKillCounter[MAXPLAYERS+1] = {0};

float g_fRoundStarted = 0.0;
float g_fLastUse[MAXPLAYERS+1] = 0.0;
public void OnPluginStart(){
    g_iWeapons[0] = WEAPON_GALILAR;
    g_iWeapons[1] = WEAPON_ELITE;
    g_iWeapons[2] = WEAPON_MOLOTOV;
    g_iClassId = CodMod_RegisterClass(g_szClassName, g_szDesc, g_iHealth, g_iArmor, g_iDexterity, g_iIntelligence, g_iWeapons, 0, g_iStartingHealth);

    HookEvent("round_start", Event_OnRoundStart);
}

public Action Event_OnRoundStart(Event hEvent, char[] szEventName, bool bBroadcast){
    g_fRoundStarted = GetGameTime();
}

public void OnPluginEnd(){
    CodMod_UnregisterClass(g_iClassId);
}

public void OnMapStart(){
    g_fRoundStarted = 0.0;
}


public int CodMod_OnChangeClass(int iClient, int iPrevious, int iNext){
    if(iNext != g_iClassId) {
        g_bHasClass[iClient] = false;
    } else {
        g_bHasClass[iClient] = true;
        g_fLastUse[iClient] = 0.0;
    }

    g_iSwitches[iClient] = 0;

}

public CodMod_OnPlayerDamaged(int iAttacker, int iVictim, float &fDamage, WeaponID iWeaponID, int iDamageType){
    if(g_bHasClass[iAttacker]){
        if(iWeaponID == WEAPON_GALILAR){
            fDamage += float(g_iKillCounter[iAttacker] * 5);
        } else if(iWeaponID == WEAPON_ELITE){
            fDamage += float(g_iKillCounter[iAttacker] * 10);
        }
    }
}

public void CodMod_OnPlayerSpawn(int iClient){
    g_iKillCounter[iClient] = 0;
    g_iSwitches[iClient] = 0;
}
public void CodMod_OnPlayerDie(int attacker, int victim, bool headshot){
    if(g_bHasClass[attacker]){
        CodMod_Heal(attacker, attacker, 10);
        g_iKillCounter[attacker]++;
    }
}


public void CodMod_OnClassSkillUsed(int iClient){
    if(!g_bHasClass[iClient] || !IsPlayerAlive(iClient))
        return;

    if(GetGameTime() - g_fRoundStarted < 10.0){
        PrintToChat(iClient, "%s Możesz używać zamiany 10 sec po starcie rundy!", PREFIX_SKILL);
        return;
    }


    int iMaxSwitches = MAX_SWITCHES;
    if(g_iSwitches[iClient] + 1 <= iMaxSwitches){
        if(GetGameTime() - g_fLastUse[iClient] < 5.0){
            PrintToChat(iClient, "%s Możesz używać zamiany co 5 sec!", PREFIX_SKILL);
            return;
        }


        int iTargetTeam = GetClientTeam(iClient) == CS_TEAM_T ? CS_TEAM_CT : CS_TEAM_T;
        int iTarget;
        float targetOrigin[3];
        float currentOrigin[3];
        int iCounter = 0;
        do {
            iTarget = GetRandomAliveTarget(iClient, iTargetTeam);
            if(CodMod_GetImmuneToSkills(iTarget))
            {
                iCounter++;
                if(iCounter > 6){
                    PrintToChat(iClient, "%s Nie znaleziono blisko odpowiedniego przeciwnika!", PREFIX_SKILL);
                    return;
                }
                continue;
            } 
            if(!IsValidPlayer(iTarget)) {
                continue;
            }   
            GetClientAbsOrigin(iTarget, targetOrigin);
            GetClientAbsOrigin(iClient, currentOrigin);
            iCounter++;
            if(iCounter > 6){
                PrintToChat(iClient, "%s Nie znaleziono blisko odpowiedniego przeciwnika!", PREFIX_SKILL);

                return;
            }

        } while(GetVectorDistance(currentOrigin, targetOrigin) >= 700.0);

        if(CodMod_GetImmuneToSkills(iTarget))
        {
            PrintToChat(iClient, "%s Nie znaleziono blisko odpowiedniego przeciwnika!", PREFIX_SKILL);
            return;
        }
        g_iSwitches[iClient]++;
        PrintToChat(iClient, "%s Zamieniłeś się miejscami! Zostało Ci %d zamian", PREFIX_SKILL, iMaxSwitches - g_iSwitches[iClient]);
        g_fLastUse[iClient] = GetGameTime();
        SwitchPlaces(iClient, iTarget);
    } else {
        PrintToChat(iClient, "%s Wykorzystałeś już %d zamian tej rundzie!", PREFIX_SKILL, iMaxSwitches)
    }
}

int GetRandomAliveTarget(int iExclude, int iTeam){
    int iCount = 0;
    int iTargets[MAXPLAYERS+1];
    for(int i = 1; i <= MaxClients; i++){
        if(i != iExclude && IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == iTeam){
            iTargets[iCount++] = i;
        }
    }

    return iTargets[GetRandomInt(0, iCount - 1)];
}

public void SwitchPlaces(int iClient, int iTarget){
    if(IsValidPlayer(iTarget) && GetClientTeam(iClient) != GetClientTeam(iTarget)){
        float targetOrigin[3];
        float currentOrigin[3];
        GetClientAbsOrigin(iTarget, targetOrigin);
        GetClientAbsOrigin(iClient, currentOrigin);
        /*if(GetVectorDistance(targetOrigin, currentOrigin) >= 1200.0 + (float(CodMod_GetWholeStat(iClient, INT) * 10))  ){
            PrintToChat(iClient, "%sPrzeciwnik jest za daleko!", PREFIX_SKILL);
            return;
        }*/

        TeleportEntity(iClient, targetOrigin, NULL_VECTOR, NULL_VECTOR);
        TeleportEntity(iTarget, currentOrigin, NULL_VECTOR, NULL_VECTOR);
        PrintToChat(iClient, "%sZostałeś zamieniony miejscami!", PREFIX);
        PrintToChat(iTarget, "%sZostałeś zamieniony miejscami!", PREFIX);
    }
}
