#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>

#include <emitsoundany>

#define _IN_CODMOD_CLASS 1
#include <codmod301>
public Plugin myinfo = {
    name = "CodMod 301 - Class - Kapral",
    author = "th7nder",
    description = "Kapral Class from CodMod 301",
    version = "2.0",
    url = "http://serwery-go.pl"
};

WeaponID g_iWeapons[WEAPON_LIMIT] = {WEAPON_NONE};
#define ADDITIONAL_MULTIPLIER 2.0 - STRENGTH_MULTIPLIER
char g_szClassName[128] = {"Kapral"};
char g_szDesc[128] = {"115HP,Galil(+5dmg),USP-S(+10dmg)\n \
1/15 na ogłuszenie na 0.5s \n \ 
100% redukcja 1 otrzymanego DMG w rundzie"};

#define STUN_DURATION 0.5

const int g_iHealth = 0;
const int g_iStartingHealth = 115;
const int g_iArmor = 0;
const int g_iDexterity = 0;
const int g_iIntelligence = 0;
int g_iClassId = 0;
bool g_bHasClass[MAXPLAYERS+1]    = {false};

int g_iDamageCount[MAXPLAYERS+1] = {0};

float g_fStunned[MAXPLAYERS+1] = {0.0};
public void OnPluginStart(){
    g_iWeapons[0] = WEAPON_GALILAR;
    g_iWeapons[1] = WEAPON_USP;
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
        g_iDamageCount[iClient] = 0;
    }

}

public void CodMod_OnClientPutInServer(int iClient)
{
    SDKHook(iClient, SDKHook_WeaponSwitch, SDK_OnWeaponEvent);
    SDKHook(iClient, SDKHook_WeaponEquip, SDK_OnWeaponEvent);
}


public Action SDK_OnWeaponEvent(int iClient, int iWeapon)
{
    float fTime = GetGameTime();
    if(fTime - g_fStunned[iClient] <= STUN_DURATION)
    {
        if(GetPlayerWeaponSlot(iClient, 2) != iWeapon)
        {
            SetEntPropFloat(iWeapon, Prop_Send, "m_flNextPrimaryAttack", fTime + (STUN_DURATION - (fTime - g_fStunned[iClient])));
        }
    }

    return Plugin_Continue;
}

public void CodMod_OnPlayerSpawn(int iClient)
{
    g_iDamageCount[iClient] = 0;
    g_fStunned[iClient] = 0.0;
}

public CodMod_OnPlayerDamagedPerk(int iAttacker, int iVictim, float &fDamage, WeaponID iWeaponID, int iDamageType){
    if(g_bHasClass[iAttacker])
    {
        if(iWeaponID == WEAPON_USP)
        {
            fDamage += 10.0;
        }
        else if(iWeaponID == WEAPON_GALILAR)
        {
            fDamage += 5.0;
        }
        if(GetRandomInt(1, 100) >= 93 && !CodMod_GetImmuneToSkills(iVictim))
        {
            if(GetGameTime() - g_fStunned[iVictim] >= STUN_DURATION)
            {
                g_fStunned[iVictim] = GetGameTime();
                for(int i = 0; i < 2; i++)
                {
                    int iEntity = GetPlayerWeaponSlot(iVictim, i);
                    if(iEntity != -1 && IsValidEntity(iVictim))
                    {
                        SetEntPropFloat(iEntity, Prop_Send, "m_flNextPrimaryAttack", g_fStunned[iVictim] + STUN_DURATION);
                    }
                }

                PrintToChat(iVictim, "%s Zostałeś ogłuszony przez kaprala na %.2fs!", PREFIX_SKILL, STUN_DURATION);
                PrintToChat(iAttacker, "%s Gracz został przez Ciebie ogłuszony!", PREFIX_SKILL); 
            }
        }

    }

    if(g_bHasClass[iVictim])
    {
        if(g_iDamageCount[iVictim] == 0)
        {
            PrintToChat(iVictim, "%s Damage został zredukowany o 100%%!", PREFIX_SKILL);
            g_iDamageCount[iVictim]++;
            fDamage = 0.0;
        }
    }
}
