#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <th7manager>

#include "include/emitsoundany.inc"

#define _IN_CODMOD_CLASS 1
#include <codmod301>
public Plugin myinfo = {
    name = "CodMod 301 - Class - Ghost",
    author = "th7nder",
    description = "Ghost Class from CodMod 301",
    version = "2.0",
    url = "http://serwery-go.pl"
};

WeaponID g_iWeapons[WEAPON_LIMIT] = {WEAPON_NONE};
WeaponID g_iPistols[] = {
    WEAPON_GLOCK,
    WEAPON_DEAGLE,
    WEAPON_HKP2000,
    WEAPON_FIVESEVEN,
    WEAPON_ELITE,
    WEAPON_P250,
    WEAPON_USP,
    WEAPON_TEC9,
    WEAPON_CZ,
    WEAPON_REVOLVER
};

int g_iRadarUsed[MAXPLAYERS+1] = {0};
char g_szClassName[128] = {"Ghost [Premium]"};
char g_szDesc[256] = {"140HP, losowy pistolet, Smoke, Flashbang \n Widzi wrogów na radarze(1 na 6sec), ciche kroki, gdy kuca niewidoczny \n 1/5 na 3x dmg, +1000$ co rundę \n 1/3 na instakill z kosy na PPM"};
const int g_iHealth = 0;
const int g_iStartingHealth = 140;
const int g_iArmor = 0;
const int g_iDexterity = 0;
const int g_iIntelligence = 0;
int g_iClassId = 0;
bool g_bHasClass[MAXPLAYERS+1]    = {false};

float g_fLastUse[MAXPLAYERS+1] = {0.0};
public void OnPluginStart(){
    g_iWeapons[0] = WEAPON_SMOKEGRENADE;
    g_iWeapons[1] = WEAPON_FLASHBANG;
    g_iClassId = CodMod_RegisterClass(g_szClassName, g_szDesc, g_iHealth, g_iArmor, g_iDexterity, g_iIntelligence, g_iWeapons, ADMFLAG_KICK, g_iStartingHealth);
}

public void OnPluginEnd(){
    CodMod_UnregisterClass(g_iClassId);
}


public int CodMod_OnChangeClass(int iClient, int iPrevious, int iNext){
    if(iPrevious == g_iClassId){
        TH7_DisableSilentFootsteps(iClient);
    }
    if(iNext != g_iClassId) {
        g_bHasClass[iClient] = false;
    } else {
        g_bHasClass[iClient] = true;
        TH7_EnableSilentFootsteps(iClient);
        g_fLastUse[iClient] = 0.0;
        g_iRadarUsed[iClient] = 0;
    }

}

public CodMod_OnPlayerDamaged(int iAttacker, int iVictim, float &fDamage, WeaponID iWeaponID, int iDamageType){
    if(g_bHasClass[iAttacker]){
        if(iWeaponID != WEAPON_HEGRENADE && iWeaponID != WEAPON_MOLOTOV && iWeaponID != WEAPON_INCGRENADE && GetRandomInt(1, 100) >= 80){
            fDamage += 15.0;
        }

        if(GetRandomInt(1, 100) > 66 && iWeaponID == WEAPON_KNIFE && GetClientButtons(iAttacker) & IN_ATTACK2){
            fDamage *= 300.0;
        }
    }
}

public void CodMod_OnWeaponCanUse(int iClient, WeaponID iWeaponID, int &iCanUse, bool bBuy){
    if(g_bHasClass[iClient] && CodMod_WeaponIsPistol(iWeaponID) && !bBuy){
        iCanUse = 2;
    }
}

public void CodMod_OnPlayerSpawn(int iClient){
    if(g_bHasClass[iClient]){
        g_iRadarUsed[iClient] = 0;
        SetEntProp(iClient, Prop_Send, "m_iAccount", GetEntProp(iClient, Prop_Send, "m_iAccount") + 1000);
        int iEntity = GetPlayerWeaponSlot(iClient, 1);
        if(iEntity != -1){
            RemovePlayerItem(iClient, iEntity);
            RemoveEdict(iEntity);
        }

        char szWeapon[64];
        int iRandom = GetRandomInt(0, sizeof(g_iPistols) - 1);
        Format(STRING(szWeapon), "weapon_%s", weaponNames[g_iPistols[iRandom]]);
        GivePlayerItem(iClient, szWeapon);
    }
}


public void CodMod_OnClassSkillUsed(int iClient){
    if(!g_bHasClass[iClient] || !IsPlayerAlive(iClient))
        return;

    if(g_iRadarUsed[iClient] + 1 > 3){
        PrintToChat(iClient, "%s Możesz użyć tej umiejętności 3 razy na runde!", PREFIX_SKILL);
        return;
    }


    if(GetGameTime() - g_fLastUse[iClient] < 5.0){
        PrintToChat(iClient, "%s Użycie raz na 5 sec!", PREFIX_SKILL);
        g_fLastUse[iClient] = GetGameTime();
    }

    g_iRadarUsed[iClient]++;

    ShowEnemiesToClient(iClient);
    Handle hPack = CreateDataPack();
    WritePackCell(hPack, GetClientSerial(iClient));
    WritePackCell(hPack, 5);
    CreateTimer(1.0, Timer_ShowEnemies, hPack);

}

public Action Timer_ShowEnemies(Handle hTimer, Handle hPack){
    ResetPack(hPack);
    int iClient = GetClientFromSerial(ReadPackCell(hPack));
    int iRemaining = ReadPackCell(hPack);

    CloseHandle(hPack);
    if(!IsValidPlayer(iClient)){
        return Plugin_Stop;
    }

    iRemaining--;
    if(iRemaining < 0){
        return Plugin_Stop;
    }


    ShowEnemiesToClient(iClient);

    hPack = CreateDataPack();
    WritePackCell(hPack, GetClientSerial(iClient));
    WritePackCell(hPack, iRemaining);
    CreateTimer(1.0, Timer_ShowEnemies, hPack);

    return Plugin_Stop;
}


public void ShowEnemiesToClient(int iClient){
    Handle hMessage = StartMessageOne("ProcessSpottedEntityUpdate", iClient, USERMSG_RELIABLE);
    Handle hEntityUpdates;

    float fPos[3];
    for(int i = 1; i <= MaxClients; i++){
        if(IsClientInGame(i) && IsPlayerAlive(i)){
            hEntityUpdates = PbAddMessage(hMessage, "entity_updates");
            GetClientAbsOrigin(i, fPos);
            PbSetInt(hEntityUpdates, "entity_idx", i);
            PbSetInt(hEntityUpdates, "class_id", GetClientTeam(i));
            PbSetInt(hEntityUpdates, "origin_x", RoundFloat(fPos[0]));
            PbSetInt(hEntityUpdates, "origin_y", RoundFloat(fPos[1]));
            PbSetInt(hEntityUpdates, "origin_z", RoundFloat(fPos[2]));
        }
    }
    EndMessage();
}


public Action OnPlayerRunCmd(int iClient, int &iButtons, int &iImpulse, float fVel[3], float fAngles[3], int &iWeapon) {
    if(g_bHasClass[iClient]){
        if(iButtons & IN_DUCK && fVel[0] == 0.0 && fVel[1] == 0.0 && fVel[2] == 0.0 && CodMod_GetClientWeaponID(iClient) == WEAPON_KNIFE){
            TH7_SetInvisible(iClient);
        } else {
            TH7_SetVisible(iClient);
        }
    }

    return Plugin_Continue;
}


char g_szBlockedPerks[][] = {
    "puchowe buty"
}

const int g_iBlockedPerksSize = sizeof(g_szBlockedPerks);
int g_iBlockedPerks[g_iBlockedPerksSize];

public void OnMapStart(){
    for(int i = 0; i < g_iBlockedPerksSize; i++){
        g_iBlockedPerks[i] = CodMod_GetPerkId(g_szBlockedPerks[i]);
    }
}

public void CodMod_OnPerkEnabled(int iClient, int iPerkId){
    if(g_bHasClass[iClient]){
        for(int i = 0; i < g_iBlockedPerksSize; i++){
            if(iPerkId == g_iBlockedPerks[i]){
                CodMod_GiveRandomPerk(iClient);
                break;
            }
        }
    }
}
