#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <th7manager>

#include <emitsoundany>

#define _IN_CODMOD_CLASS 1
#define ROCKETS 1
#define MAX_ROCKETS 3 //+ (CodMod_GetWholeStat(iClient, INT) / 50)
#define DAMAGE_ROCKET_FORMULA 50 + RoundFloat(float(CodMod_GetWholeStat(iClient, INT)) * 1.25)
#include <codmod301>
public Plugin myinfo = {
    name = "CodMod 301 - Class - Bandit",
    author = "th7nder",
    description = "Bandit Class from CodMod 301",
    version = "2.0",
    url = "http://serwery-go.pl"
};


char g_szClassName[128] = {"Bandit [Premium]"};
char g_szDesc[256] = {"120HP, M4A1-S, P250, +5dmg \n Po zabiciu magazynek, +15HP \n +1 skok, znika na nożu w bezruchu \n 3 rakiety(50 + 1.25 * int dmg)"};
const int g_iHealth = 0;
const int g_iStartingHealth = 120;
const int g_iArmor = 0;
const int g_iDexterity = 0;
const int g_iIntelligence = 0;
int g_iClassId = 0;
bool g_bHasClass[MAXPLAYERS+1]    = {false};
WeaponID g_iWeapons[WEAPON_LIMIT] = {WEAPON_NONE};

int g_iRockets[MAXPLAYERS+1] = {0};
float g_fLastUse[MAXPLAYERS+1] = {0.0};
public void OnPluginStart(){
    g_iWeapons[0] = WEAPON_M4A1;
    g_iWeapons[1] = WEAPON_P250;
    g_iClassId = CodMod_RegisterClass(g_szClassName, g_szDesc, g_iHealth, g_iArmor, g_iDexterity, g_iIntelligence, g_iWeapons, ADMFLAG_KICK, g_iStartingHealth);
}

public void OnPluginEnd(){
    CodMod_UnregisterClass(g_iClassId);
}

public void OnClientPutInServer(int iClient){
    SDKHook(iClient, SDKHook_WeaponSwitch, SDK_OnWeaponSwitch);
}

public void OnClientDisconnect(int iClient){
    SDKUnhook(iClient, SDKHook_WeaponSwitch, SDK_OnWeaponSwitch);
}


public int CodMod_OnChangeClass(int iClient, int iPrevious, int iNext){
    if(iPrevious == g_iClassId)
    {
        CodMod_SetPlayerInfo(iClient, DOUBLE_JUMP, 0);
    }
    if(iNext != g_iClassId) {
        g_bHasClass[iClient] = false;
        TH7_SetVisible(iClient);
    } else {
        g_bHasClass[iClient] = true;
        CodMod_SetPlayerInfo(iClient, DOUBLE_JUMP, 1);
    }

}

public CodMod_OnPlayerDamaged(int iAttacker, int iVictim, float &fDamage, WeaponID iWeaponID, int iDamageType){
    if(g_bHasClass[iAttacker]){
       // CodMod_Heal(iAttacker, iAttacker, GetRandomInt(1, 5));
       fDamage+=5.0;
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
        CodMod_Heal(iAttacker, iAttacker, 15);
        CreateTimer(0.00, Timer_Refill, GetClientSerial(iAttacker));
    }
}


public Action OnPlayerRunCmd(int iClient, int &iButtons, int &iImpulse, float fVel[3], float fAngles[3], int &iWeapon) {
    if(g_bHasClass[iClient]){
        if(fVel[0] != 0.0 || fVel[1] != 0.0 || iButtons & IN_JUMP || iButtons & IN_DUCK){
            TH7_SetVisible(iClient);
        }

    }

    return Plugin_Continue;
}

public Action SDK_OnWeaponSwitch(int iClient, int iWeapon){
    if(g_bHasClass[iClient]){
        if(iWeapon != -1 && IsValidEdict(iWeapon)){
            WeaponID iWeaponID = CodMod_GetWeaponID(iWeapon);
            if(iWeaponID == WEAPON_KNIFE){
                TH7_SetInvisible(iClient);
            } else {
                TH7_SetVisible(iClient);
            }
        }
    }

    return Plugin_Continue;
}

public void CodMod_OnPlayerSpawn(int iClient){
    if(g_bHasClass[iClient]){
        g_iRockets[iClient] = 0;
        g_fLastUse[iClient] = 0.0;
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
