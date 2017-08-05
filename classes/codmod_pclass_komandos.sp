#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <th7manager>

#include <emitsoundany>

#define _IN_CODMOD_CLASS 1
#include <codmod301>
public Plugin myinfo = {
    name = "CodMod 301 - Class - Komandos",
    author = "th7nder",
    description = "Komandos Class from CodMod 301",
    version = "2.0",
    url = "http://serwery-go.pl"
};

WeaponID g_iWeapons[WEAPON_LIMIT] = {WEAPON_NONE};




char g_szClassName[128] = {"Komandos [Premium]"};
char g_szDesc[256] = {"140HP, Deagle, 1/1 z Kosy prawego, \n codmod_special - +50kondycji/2s co 15 sec\n Gdy kuca na nożu ma 10%% widoczności \n +25 kondycji"};
const int g_iHealth = 0;
const int g_iStartingHealth = 140;
const int g_iArmor = 0;
const int g_iDexterity = 25;
const int g_iIntelligence = 0;
int g_iClassId = 0;
bool g_bHasClass[MAXPLAYERS+1]    = {false};
float g_fLastUsed[MAXPLAYERS+1] = {0.0};
bool g_bBoosted[MAXPLAYERS+1] = {false};
public void OnPluginStart(){
    g_iWeapons[0] = WEAPON_DEAGLE;
    g_iClassId = CodMod_RegisterClass(g_szClassName, g_szDesc, g_iHealth, g_iArmor, g_iDexterity, g_iIntelligence, g_iWeapons, ADMFLAG_CUSTOM4, g_iStartingHealth);
    HookEvent("player_hurt", OnPlayerHurt, EventHookMode_Pre);
}




public void OnPluginEnd(){
    CodMod_UnregisterClass(g_iClassId);
}


public int CodMod_OnChangeClass(int iClient, int iPrevious, int iNext){
    if(g_bBoosted[iClient]){
        CodMod_SetStat(iClient, DEX_PERK, CodMod_GetStat(iClient, DEX_PERK) - 50);
        g_bBoosted[iClient] = false;
    }

    if(iPrevious == g_iClassId)
    {
        TH7_DisableRenderColor(iClient);
    }

    if(iNext != g_iClassId) {
        g_bHasClass[iClient] = false;
    } else {
        g_bHasClass[iClient] = true;
    }

    g_fLastUsed[iClient] = 0.0;
    g_bBoosted[iClient] = false;
}

public CodMod_OnPlayerDamaged(int iAttacker, int iVictim, float &fDamage, WeaponID iWeaponID, int iDamageType){
    if(g_bHasClass[iAttacker]){
        if(iWeaponID == WEAPON_KNIFE){
            if(GetClientButtons(iAttacker) & IN_ATTACK2)
            {
                fDamage *= 300.0;
            }
           /* fDamage += 100.0;
            if(GetClientButtons(iAttacker) & IN_ATTACK2 && isInFOV(iAttacker, iVictim) && !isInFOV(iVictim, iAttacker))
            {
                fDamage *= 300.0;
            }*/
        }
    }
}



public Action OnPlayerHurt(Event hEvent, const char[] sName, bool bDontBroadcast)
{
    int iVictimId = hEvent.GetInt("userid");
    int iVictim = GetClientOfUserId(iVictimId);

    if(g_bHasClass[iVictim])
        SetEntPropFloat(iVictim, Prop_Send, "m_flVelocityModifier", 1.0);

    return Plugin_Continue;
}

public Action OnPlayerRunCmd(int iClient, int &iButtons, int &iImpulse, float fVel[3], float fAngles[3], int &iWeapon) {
    if(g_bHasClass[iClient]){
        /*if(iButtons & IN_WALK || iButtons & IN_FORWARD || iButtons & IN_MOVELEFT || iButtons & IN_MOVERIGHT || iButtons & IN_BACK){
            TH7_SetRenderColor(iClient, 255, 255, 255, );
        } else {
            TH7_DisableRenderColor(iClient);
        }*/
        char szWeapon[64];
        GetClientWeapon(iClient, STRING(szWeapon));
        if(iButtons & IN_DUCK && StrContains(szWeapon, "knife") != -1)
        {
            TH7_SetRenderColor(iClient, 255, 255, 255, 15);
        } else {
            TH7_DisableRenderColor(iClient);
        }
    }

    return Plugin_Continue;
}

public void CodMod_OnClassSkillUsed(int iClient){
    if(!g_bHasClass[iClient] || !IsPlayerAlive(iClient))
        return;

    if(g_bBoosted[iClient]){
        PrintToChat(iClient, "%s Jesteś już przyspieszony!", PREFIX_SKILL);
        return;
    }

    if(GetGameTime() - g_fLastUsed[iClient] < 15.0){
        PrintToChat(iClient, "%s Tej umiejętności możesz używać co 15sec!", PREFIX_SKILL);
        return;
    }

    PrintToChat(iClient, "%s Zostałeś przyspieszony!", PREFIX_SKILL);
    g_bBoosted[iClient] = true;
    g_fLastUsed[iClient] = GetGameTime();
    CodMod_SetStat(iClient, DEX_PERK, CodMod_GetStat(iClient, DEX_PERK) + 50);
    CreateTimer(2.0, Timer_DisableBoost, GetClientSerial(iClient));
    if(GetEntProp(iClient, Prop_Send, "m_iProgressBarDuration") > 2){
        if(GetGameTime() - GetEntPropFloat(iClient, Prop_Send, "m_flProgressBarStartTime") < 2){
            return;
        }
    }
    SetEntPropFloat(iClient, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
    SetEntProp(iClient, Prop_Send, "m_iProgressBarDuration", 2);
}

public Action Timer_DisableBoost(Handle hTimer, int iClient){
    iClient = GetClientFromSerial(iClient);
    if(!IsValidPlayer(iClient)){
        return Plugin_Stop;
    }

    if(GetEntProp(iClient, Prop_Send, "m_iProgressBarDuration") == 2){
        SetEntPropFloat(iClient, Prop_Send, "m_flProgressBarStartTime", 0.0);
        SetEntProp(iClient, Prop_Send, "m_iProgressBarDuration", 0);
    }



    if(g_bBoosted[iClient]){
        CodMod_SetStat(iClient, DEX_PERK, CodMod_GetStat(iClient, DEX_PERK) - 50);
        g_bBoosted[iClient] = false;
    }

    return Plugin_Stop;
}

public void CodMod_OnPlayerSpawn(iClient){
    if(g_bBoosted[iClient]){
        CodMod_SetStat(iClient, DEX_PERK, CodMod_GetStat(iClient, DEX_PERK) - 50);
        g_bBoosted[iClient] = false;
    }
}


char g_szBlockedPerks[][] = {
    "zestaw rushera",
    "zestaw paranoika",
    "brożu.exe",
    "karabin kaprala",
    "awp snajper",
    "magiczny ck",
    "ssg08 snajper",
    "karabin szturmowy",
    "zmora panthli0nna",
    "ak bojownika",
    "viva la france",
    "buty luigego",
    "tajemnica komandosa",
    "turbo milka",
    "sekret mrozza",
    "obrona mahesvary"
}

const int g_iBlockedPerksSize = sizeof(g_szBlockedPerks);
int g_iBlockedPerks[g_iBlockedPerksSize];

public void OnMapStart(){
    for(int i = 0; i < g_iBlockedPerksSize; i++){
        g_iBlockedPerks[i] = CodMod_GetPerkId(g_szBlockedPerks[i]);
    }
}


/*public void CodMod_OnPerkDisabled(int iClient, int iPerkId){
    if(g_bHasClass[iClient]){
        CreateTimer(0.3, Timer_RemoveWeapon, iClient);

        for(int i = 0; i < g_iBlockedPerksSize; i++){
            if(iPerkId == g_iBlockedPerks[i]){
                CodMod_GiveRandomPerk(iClient);
                break;
            }
        }
    }
}*/

public Action Timer_RemoveWeapon(Handle hTimer, int iClient){
    if(IsClientInGame(iClient) && IsPlayerAlive(iClient)){
        int iEntity = GetPlayerWeaponSlot(iClient, 0);
        if(iEntity != -1){
            RemovePlayerItem(iClient, iEntity);
            RemoveEdict(iEntity);
        }
    }
}
