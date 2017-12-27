#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <th7manager>

#include <emitsoundany>

#define _IN_CODMOD_CLASS 1
#include <codmod301>
public Plugin myinfo = {
    name = "CodMod 301 - Class - Komandor",
    author = "th7nder",
    description = "Major Class from CodMod 301",
    version = "2.0",
    url = "http://serwery-go.pl"
};

WeaponID g_iWeapons[WEAPON_LIMIT] = {WEAPON_NONE};
const int AMOUNT_HEAL = 15;
const int AMOUNT_HEAL_REPEAT = 10;
const float HEAL_INTERVAL = 1.0;
const int MAX_HEALING_TIMES = 1;

char g_szClassName[128] = {"Komandor [Premium]"};
char g_szDesc[256] = {"130HP, G3SG1, CZetka(+5dmg)\n\
                        codmod_skill (15hp/1s przez 10s)\n\
                        +500$ za zabójstwo\n\
                        1/15 na spowolnienie przeciwnika o 40% na 2 sec\n\
                        1/10 na odbicie pocisku w plecy"};
const int g_iHealth = 0;
const int g_iStartingHealth = 130;
const int g_iArmor = 0;
const int g_iDexterity = 0;
const int g_iIntelligence = 0;
int g_iClassId = 0;
bool g_bHasClass[MAXPLAYERS+1]    = {false};


bool g_bHealing[MAXPLAYERS+1] = {false};
bool g_bSlow[MAXPLAYERS+1] = {false};
int g_iUsed[MAXPLAYERS+1] = {0};

public void OnPluginStart()
{
    g_iWeapons[0] = WEAPON_G3SG1;
    g_iWeapons[1] = WEAPON_CZ;
    g_iClassId = CodMod_RegisterClass(g_szClassName, g_szDesc, g_iHealth, g_iArmor, g_iDexterity, g_iIntelligence, g_iWeapons, 0, g_iStartingHealth);
}

public void OnPluginEnd()
{
    CodMod_UnregisterClass(g_iClassId);
}


public int CodMod_OnChangeClass(int iClient, int iPrevious, int iNext)
{
    if(iNext != g_iClassId) {
        g_bHasClass[iClient] = false;
    } else {
        g_bHasClass[iClient] = true;
    }

}

public CodMod_OnPlayerSpawn(int iClient)
{
    g_bSlow[iClient] = false;
    g_bHealing[iClient] = false;
    g_iUsed[iClient] = 0;
}

public CodMod_OnPlayerDamaged(int iAttacker, int iVictim, float &fDamage, WeaponID iWeaponID, int iDamageType)
{
    if(g_bHasClass[iAttacker])
    {
        if(iWeaponID == WEAPON_CZ)
        {
            fDamage += 5.0;
        }

        if(!g_bSlow[iVictim] && GetRandomInt(1, 15) == 1)
        {
            PrintToChat(iVictim, "%s Zostałeś spowolniony!", PREFIX_SKILL);
            PrintToChat(iAttacker, "%s Spowolniłeś %N!", PREFIX_SKILL, iVictim);
            g_bSlow[iVictim] = true;
            Handle hPack = CreateDataPack();
            CodMod_ChangeStat(iVictim, DEX_PERK, -40);
            WritePackCell(hPack, GetClientSerial(iVictim));
            WritePackCell(hPack, CodMod_GetRoundIndex());
            CreateTimer(2.0, Timer_Unslow, hPack);
        }
    }


}

public void CodMod_OnPlayerDie(int iAttacker, int iVictim, bool bHeadshot)
{
    if(g_bHasClass[iAttacker])
    {
        Player_GiveMoney(iAttacker, 500);
    }
}

public Action Timer_Unslow(Handle hTimer, Handle hPack)
{
        ResetPack(hPack);
        int iSerial = ReadPackCell(hPack);
        int iRoundIndex = ReadPackCell(hPack);
        delete hPack;

        int iClient = GetClientFromSerial(iSerial);
        if(!IsValidPlayer(iClient)) return Plugin_Stop;


        CodMod_ChangeStat(iClient, DEX_PERK, 40);

        if(IsPlayerAlive(iClient))
        {
                if(CodMod_GetRoundIndex() == iRoundIndex)
                {
                        g_bSlow[iClient] = false;
                        PrintToChat(iClient, "%s Poruszasz się już normalnie", PREFIX_SKILL);
                }       

        }



        return Plugin_Stop;
}



public void CodMod_OnClassSkillUsed(int iClient){
    if(!g_bHasClass[iClient] || !IsPlayerAlive(iClient))
        return;

    if(g_iUsed[iClient] + 1 > MAX_HEALING_TIMES)
    {
        PrintToChat(iClient, "%s Nie możesz użyć leczenia więcej niż %d raz na runde!", MAX_HEALING_TIMES);
        return;
    }
    if(g_bHealing[iClient]){
        PrintToChat(iClient, "%s Jesteś w trakcie leczenia!", PREFIX_SKILL);
        return;
    }


    PrintToChat(iClient, "%s Rozpocząłeś leczenie!", PREFIX_SKILL);
    g_bHealing[iClient] = true;
    g_iUsed[iClient] += 1;
    Handle hPack = CreateDataPack();
    WritePackCell(hPack, GetClientSerial(iClient));
    WritePackCell(hPack, CodMod_GetRoundIndex());
    WritePackCell(hPack, AMOUNT_HEAL_REPEAT);

    CreateTimer(HEAL_INTERVAL, Timer_Healing, hPack);

    SetEntPropFloat(iClient, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
    SetEntProp(iClient, Prop_Send, "m_iProgressBarDuration", AMOUNT_HEAL_REPEAT);
}


public Action Timer_Healing(Handle hTimer, Handle hPack){
    ResetPack(hPack);
    int iSerial = ReadPackCell(hPack);
    int iRoundIndex = ReadPackCell(hPack);
    int iTimesExecuted = ReadPackCell(hPack);
    delete hPack;

    int iClient = GetClientFromSerial(iSerial)
    if(!IsValidPlayer(iClient) || iRoundIndex != CodMod_GetRoundIndex() || iTimesExecuted <= 0){

        if(GetEntProp(iClient, Prop_Send, "m_iProgressBarDuration") == AMOUNT_HEAL_REPEAT){
            SetEntPropFloat(iClient, Prop_Send, "m_flProgressBarStartTime", 0.0);
            SetEntProp(iClient, Prop_Send, "m_iProgressBarDuration", 0);
        }

        return Plugin_Stop;
    }



    CodMod_Heal(iClient, iClient, AMOUNT_HEAL);
    iTimesExecuted--;

    hPack = CreateDataPack();
    WritePackCell(hPack, GetClientSerial(iClient));
    WritePackCell(hPack, CodMod_GetRoundIndex());
    WritePackCell(hPack, iTimesExecuted);

    CreateTimer(HEAL_INTERVAL, Timer_Healing, hPack);

    return Plugin_Stop;
}
