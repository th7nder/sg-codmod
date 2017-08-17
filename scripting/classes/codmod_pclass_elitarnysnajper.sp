#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <th7manager>

#include <emitsoundany>

#define _IN_CODMOD_CLASS 1
#include <codmod301>
public Plugin myinfo = {
    name = "CodMod 301 - Class - Elitarny Snajper",
    author = "th7nder",
    description = "Elitarny Snajper Class from CodMod 301",
    version = "2.0",
    url = "http://serwery-go.pl"
};

WeaponID g_iWeapons[WEAPON_LIMIT] = {WEAPON_NONE};


#define ADDITIONAL_AWP_STR 3.0 - STRENGTH_MULTIPLIER
#define ADDITIONAL_P250_STR (0.3 - STRENGTH_MULTIPLIER)
#define ADDITIONAL_SSG_STR (0.8 - STRENGTH_MULTIPLIER)


char g_szClassName[128] = {"Elitarny Snajper [Premium]"};
char g_szDesc[256] = {"120HP, AWP(3dmg/1str), P250(0.3dmg/1str) \n 1/2 na +175dmg; 60%% widoczności \n Na codmod_special dostaje 2x na rundę Skupienie(no-rec) na 10sec"};
const int g_iHealth = 0;
const int g_iStartingHealth = 120;
const int g_iArmor = 0;
const int g_iDexterity = 0;
const int g_iIntelligence = 0;
int g_iClassId = 0;
bool g_bHasClass[MAXPLAYERS+1]    = {false};


int g_iNoRecoils[MAXPLAYERS+1] = {0};
bool g_bNoRecoil[MAXPLAYERS+1] = {false};

public void OnPluginStart(){
    g_iWeapons[0] = WEAPON_P250;
    g_iWeapons[1] = WEAPON_AWP;
    g_iClassId = CodMod_RegisterClass(g_szClassName, g_szDesc, g_iHealth, g_iArmor, g_iDexterity, g_iIntelligence, g_iWeapons, ADMFLAG_BAN, g_iStartingHealth);
}

public void OnPluginEnd(){
    CodMod_UnregisterClass(g_iClassId);
}

public int CodMod_OnChangeClass(int iClient, int iPrevious, int iNext){
    if(iPrevious == g_iClassId){
        TH7_DisableRenderColor(iClient);
    }
    if(iNext != g_iClassId) {
        g_bHasClass[iClient] = false;
    } else {
        g_bHasClass[iClient] = true;
        TH7_SetRenderColor(iClient, 255, 255, 255, 150);
        g_iNoRecoils[iClient] = 0;
        g_bNoRecoil[iClient] = false;
    }

}

public CodMod_OnPlayerDamaged(int iAttacker, int iVictim, float &fDamage, WeaponID iWeaponID, int iDamageType){
    if(g_bHasClass[iAttacker]){
        if(iWeaponID == WEAPON_P250){
            fDamage += ((ADDITIONAL_P250_STR) * float(CodMod_GetWholeStat(iAttacker, STRENGTH)));
        }

        if(iWeaponID == WEAPON_AWP){
            fDamage += ((ADDITIONAL_AWP_STR) * float(CodMod_GetWholeStat(iAttacker, STRENGTH)));
        }

        /*if(iWeaponID == WEAPON_SSG08){
            fDamage += (0.8 * float(CodMod_GetWholeStat(iAttacker, STRENGTH)));
            if(GetRandomInt(1, 100) >= 66){
                fDamage *= 300.0;
            }
        }*/

        if(iWeaponID == WEAPON_AWP){
            if(GetRandomInt(1, 100) >= 50){
                fDamage += 175.0;
            }
        }
    }
}


const WeaponID g_iFirstWeaponID = WEAPON_AWP;
const WeaponID g_iSecondWeaponID = WEAPON_SSG08;
int g_iWeaponAmmos[2] = {-1};

public void CodMod_OnPlayerSpawn(int iClient){
    if(g_bHasClass[iClient]){
       /* g_iWeaponAmmos[0] = -1;
        g_iWeaponAmmos[1] = -1;
        int iCurrentEntity = GetPlayerWeaponSlot(iClient, 0);
        if(iCurrentEntity == -1){
            char szWeapon[64];
            Format(STRING(szWeapon), "weapon_%s", weaponNames[g_iFirstWeaponID]);
            GivePlayerItem(iClient, szWeapon);
        }*/
        g_bNoRecoil[iClient] = false;
        g_iNoRecoils[iClient] = 0;
        TH7_DisableNoRecoil(iClient);

    }
}

public Action Timer_DisableNoRecoil(Handle hTimer, int iSerial)
{
    int iClient = GetClientFromSerial(iSerial);
    if(!IsValidPlayer(iClient) || !g_bNoRecoil[iClient])
    {
        return Plugin_Stop;
    }

    g_bNoRecoil[iClient] = false;
    TH7_DisableNoRecoil(iClient);
    PrintToChat(iClient, "%s Twoje Skupienie skończyło się!", PREFIX_SKILL);

    return Plugin_Stop;
}

public void CodMod_OnClassSkillUsed(int iClient){
    if(!g_bHasClass[iClient] || !IsPlayerAlive(iClient))
        return;

    if(g_iNoRecoils[iClient] + 1 > 2 )
    {
        PrintToChat(iClient, "%s Nie masz już Skupienia!", PREFIX_SKILL);
        return;
    }
    if(g_bNoRecoil[iClient])
    {
        PrintToChat(iClient, "%s Twoje Skupienie nadal trwa!", PREFIX_SKILL);
        return;
    }

    PrintToChat(iClient, "%s Skupiłeś się! Przez 10 sekund posiadasz no-recoila!", PREFIX_SKILL);
    g_bNoRecoil[iClient] = true;
    g_iNoRecoils[iClient]++;
    TH7_EnableNoRecoil(iClient);
    CreateTimer(10.0, Timer_DisableNoRecoil, GetClientSerial(iClient));
    /*int iCurrentEntity = GetPlayerWeaponSlot(iClient, 0);
    WeaponID iWeaponID = CodMod_GetWeaponID(iCurrentEntity);

    char szWeapon[64];
    if(iWeaponID == g_iFirstWeaponID){
        g_iWeaponAmmos[0] = GetEntProp(iCurrentEntity, Prop_Send, "m_iClip1");

        RemovePlayerItem(iClient, iCurrentEntity);
        RemoveEdict(iCurrentEntity);

        Format(STRING(szWeapon), "weapon_%s", weaponNames[g_iSecondWeaponID]);
        int iNextEntity = GivePlayerItem(iClient, szWeapon);
        if(g_iWeaponAmmos[1] != -1){
            SetEntProp(iNextEntity, Prop_Send, "m_iClip1", g_iWeaponAmmos[1]);
        }

        EquipPlayerWeapon(iClient, iNextEntity);
    } else if(iWeaponID == g_iSecondWeaponID){
        if(iWeaponID == g_iSecondWeaponID){
            g_iWeaponAmmos[1] = GetEntProp(iCurrentEntity, Prop_Send, "m_iClip1");
        } else {
            g_iWeaponAmmos[1] = -1;
        }

        if(iCurrentEntity != -1){
            RemovePlayerItem(iClient, iCurrentEntity);
            RemoveEdict(iCurrentEntity);
        }


        Format(STRING(szWeapon), "weapon_%s", weaponNames[g_iFirstWeaponID]);
        int iNextEntity = GivePlayerItem(iClient, szWeapon);
        if(g_iWeaponAmmos[0] != -1){
            SetEntProp(iNextEntity, Prop_Send, "m_iClip1", g_iWeaponAmmos[0]);
        }
        EquipPlayerWeapon(iClient, iNextEntity);
    }*/
}

/*public void CodMod_OnWeaponCanUse(int iClient, WeaponID iWeaponID, int &iCanUse, bool bBuy){
    if(g_bHasClass[iClient] && (iWeaponID == g_iFirstWeaponID || iWeaponID == g_iSecondWeaponID)){
        iCanUse = 2;
    }
}*/
