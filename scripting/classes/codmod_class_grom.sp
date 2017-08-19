#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <th7manager>

#include <emitsoundany>

#define _IN_CODMOD_CLASS 1
#include <codmod301>
public Plugin myinfo = {
    name = "CodMod 301 - Class - GROM",
    author = "th7nder",
    description = "GROM Class from CodMod 301",
    version = "2.0",
    url = "http://serwery-go.pl"
};

WeaponID g_iWeapons[WEAPON_LIMIT] = {WEAPON_NONE};



char g_szClassName[128] = {"GROM"};
char g_szDesc[256] = {"130HP, M4A1-S(+5dmg), FiveSeven \n Gdy otrzyma DMG znika na 1.5s(+odporność na granaty)"};
const int g_iHealth = 0;
const int g_iStartingHealth = 130;
const int g_iArmor = 0;
const int g_iDexterity = 0;
const int g_iIntelligence = 0;
int g_iClassId = 0;
bool g_bHasClass[MAXPLAYERS+1]    = {false};


bool g_bInvisible[MAXPLAYERS+1] = {false};
bool g_bWasInvisible[MAXPLAYERS+1] = {false};

int g_iCamouflageMask = -1;
public void OnPluginStart(){
    g_iWeapons[0] = WEAPON_M4A1;
    g_iWeapons[1] = WEAPON_FIVESEVEN;
    g_iClassId = CodMod_RegisterClass(g_szClassName, g_szDesc, g_iHealth, g_iArmor, g_iDexterity, g_iIntelligence, g_iWeapons, 0, g_iStartingHealth);
    HookEvent("player_blind", Event_OnFlashPlayer, EventHookMode_Pre);
}

public void OnPluginEnd(){
    CodMod_UnregisterClass(g_iClassId);
}

public void OnMapStart(){
    g_iCamouflageMask = -1;
    g_iCamouflageMask = CodMod_GetPerkId("Siatka Kamuflująca");
}


public int CodMod_OnChangeClass(int iClient, int iPrevious, int iNext){
    if(iPrevious == g_iClassId && g_bInvisible[iClient]){
        TH7_DisableRenderColor(iClient);
    }

    if(iNext != g_iClassId) {
        g_bHasClass[iClient] = false;
    } else {
        g_bHasClass[iClient] = true;
    }

    g_bInvisible[iClient] = false;
    g_bWasInvisible[iClient] = false;
}

public void CodMod_OnPlayerSpawn(int iClient){
    if(g_bHasClass[iClient]){
        g_bInvisible[iClient] = false;
        g_bWasInvisible[iClient] = false;

        if(CodMod_GetPlayerInfo(iClient, PERK) == g_iCamouflageMask){
          TH7_SetRenderColor(iClient, 255, 255, 255, 76);
        } else {
          TH7_DisableRenderColor(iClient);
        }
    }
}


public Action Timer_SetVisible(Handle hTimer, int iClient){
    iClient = GetClientFromSerial(iClient);
    if(!IsValidPlayer(iClient)){
        return Plugin_Stop;
    }

    if(g_bInvisible[iClient] && IsPlayerAlive(iClient)){
        if(CodMod_GetPlayerInfo(iClient, PERK) == g_iCamouflageMask){
          TH7_SetRenderColor(iClient, 255, 255, 255, 76);
        } else {
          TH7_DisableRenderColor(iClient);
        }

        g_bInvisible[iClient] = false;
    }

    return Plugin_Stop;
}

public CodMod_OnPlayerDamaged(int iAttacker, int iVictim, float &fDamage, WeaponID iWeaponID, int iDamageType){
    if(g_bHasClass[iAttacker] && iWeaponID == WEAPON_M4A1){
        fDamage += 5.0;
    }

    if(g_bHasClass[iVictim] && !g_bWasInvisible[iVictim]){
        g_bInvisible[iVictim] = true;
        g_bWasInvisible[iVictim] = true;
        TH7_SetRenderColor(iVictim, 255, 255, 255, 10);
        CreateTimer(1.5, Timer_SetVisible, GetClientSerial(iVictim));
    }

    if(g_bHasClass[iVictim] && g_bInvisible[iVictim] && (iWeaponID == WEAPON_MOLOTOV || iWeaponID == WEAPON_HEGRENADE || (iDamageType & DMG_BURN))){
        fDamage = 0.0;
    }

}

public Action Event_OnFlashPlayer(Event hEvent, const char[] szEvent, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
	if(g_bInvisible[iClient])
		SetEntPropFloat(iClient, Prop_Send, "m_flFlashMaxAlpha", 0.5);

	return Plugin_Handled;
}