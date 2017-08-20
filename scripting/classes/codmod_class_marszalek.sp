#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <th7manager>

#include <emitsoundany>

#define _IN_CODMOD_CLASS 1
#include <codmod301>
public Plugin myinfo = {
    name = "CodMod 301 - Class - Marszałek",
    author = "th7nder",
    description = "KGB Class from CodMod 301",
    version = "2.0",
    url = "http://serwery-go.pl"
};

WeaponID g_iWeapons[WEAPON_LIMIT] = {WEAPON_NONE};



char g_szClassName[128] = {"Marszałek"};
char g_szDesc[256] = {"120HP, UMP-45, FiveSeven, Molotov \n 1/10 na odnowienie 5 naboi przy trafieniu\n Na codmod_skill przez 3 sec \n  leczysz się o 20%% zadawanego dmg"};
const int g_iHealth = 0;
const int g_iStartingHealth = 130;
const int g_iArmor = 0;
const int g_iDexterity = 0;
const int g_iIntelligence = 0;
int g_iClassId = 0;
bool g_bHasClass[MAXPLAYERS+1]    = {false};

bool g_bHealing[MAXPLAYERS+1] = {false};
float g_fLastUsed[MAXPLAYERS+1] = {0};
public void OnPluginStart(){
    g_iWeapons[0] = WEAPON_FIVESEVEN;
    g_iWeapons[1] = WEAPON_UMP45;
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


    g_fLastUsed[iClient] = 0.0;
    g_bHealing[iClient] = false;
}

public void CodMod_OnPlayerSpawn(int iClient)
{
    g_bHealing[iClient] = false;
    g_fLastUsed[iClient] = 0.0;
}

public CodMod_OnPlayerDamaged(int iAttacker, int iVictim, float &fDamage, WeaponID iWeaponID, int iDamageType){
    if(g_bHasClass[iAttacker])
    {
        if(GetRandomInt(1, 100) >= 90)
        {
            GiveAmmo(iAttacker, 5);
        }

        if(g_bHealing[iAttacker])
        {
            if(CodMod_Heal(iAttacker, iAttacker, RoundFloat(fDamage * 0.2)))
            {
                PrintToChat(iAttacker, "%s Uleczyłeś się o %d!", PREFIX_SKILL, RoundFloat(fDamage * 0.2));
            }
        }
    }
}


int GiveAmmo(int iClient, int iAmmo)
{
    int iWeapon = GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
    if(iWeapon != -1 && IsValidEntity(iWeapon))
    {
        WeaponID iWeaponID = CodMod_GetWeaponID(iWeapon);
        if(g_iWeaponClip[iWeaponID][0] > 0)
        {
            int iClip1 = GetEntProp(iWeapon, Prop_Send, "m_iClip1");
            if(iClip1 + iAmmo > g_iWeaponClip[iWeaponID][0])
            {
                iClip1 = g_iWeaponClip[iWeaponID][0];
            }
            else
            {
                iClip1 += iAmmo;
            }
            SetEntProp(iWeapon, Prop_Send, "m_iClip1", iClip1);
        }
    }
}


public void CodMod_OnClassSkillUsed(int iClient){
    if(!g_bHasClass[iClient] || !IsPlayerAlive(iClient))
        return;

    if(g_bHealing[iClient]){
        PrintToChat(iClient, "%s Aktywowałeś już umiejętność!", PREFIX_SKILL);
        return;
    }

    if(GetGameTime() - g_fLastUsed[iClient] < 20.0){
        PrintToChat(iClient, "%s Do użycia pozostało: %.1f!", PREFIX_SKILL, 20 - (GetGameTime() - g_fLastUsed[iClient]));
        return;
    }

    PrintToChat(iClient, "%s Umiejętność aktywowana! Przez 3 sec masz szanse na leczenie się!", PREFIX_SKILL);
    g_bHealing[iClient] = true;
    g_fLastUsed[iClient] = GetGameTime();

    CreateTimer(3.0, Timer_DisableHealing, GetClientSerial(iClient));
    if(GetEntProp(iClient, Prop_Send, "m_iProgressBarDuration") > 3){
        if(GetGameTime() - GetEntPropFloat(iClient, Prop_Send, "m_flProgressBarStartTime") < 3){
            return;
        }
    }
    SetEntPropFloat(iClient, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
    SetEntProp(iClient, Prop_Send, "m_iProgressBarDuration", 3);
}


public Action Timer_DisableHealing(Handle hTimer, int iSerial)
{
    int iClient = GetClientFromSerial(iSerial);
    if(!IsValidPlayer(iClient)){
        return Plugin_Stop;
    }

    if(GetEntProp(iClient, Prop_Send, "m_iProgressBarDuration") == 3){
        SetEntPropFloat(iClient, Prop_Send, "m_flProgressBarStartTime", 0.0);
        SetEntProp(iClient, Prop_Send, "m_iProgressBarDuration", 0);
    }

    if(g_bHealing[iClient])
    {
        PrintToChat(iClient, "%s Umiejętność została dezaktywowana!", PREFIX_SKILL);
        g_bHealing[iClient] = false;
    }

    return Plugin_Stop;
}


