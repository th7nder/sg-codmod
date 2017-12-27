#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <th7manager>

#include <emitsoundany>

#define _IN_CODMOD_CLASS 1
#include <codmod301>
public Plugin myinfo = {
    name = "CodMod 301 - Class - Sierżant",
    author = "th7nder",
    description = "GROM Class from CodMod 301",
    version = "2.0",
    url = "http://serwery-go.pl"
};

WeaponID g_iWeapons[WEAPON_LIMIT] = {WEAPON_NONE};



char g_szClassName[128] = {"Sierżant"};
char g_szDesc[256] = {"130HP, AUG, FiveSeven \n Pod codmod_skill niewidzialność na 2s(2x na runde, 20sec cooldown)\n, Odporność na granaty, 1/8 szansy na 50%% EXP więcej"};
const int g_iHealth = 0;
const int g_iStartingHealth = 130;
const int g_iArmor = 0;
const int g_iDexterity = 0;
const int g_iIntelligence = 0;
int g_iClassId = 0;
bool g_bHasClass[MAXPLAYERS+1]    = {false};


bool g_bInvisible[MAXPLAYERS+1] = {false};
bool g_bWasInvisible[MAXPLAYERS+1] = {false};

float g_fLastUse[MAXPLAYERS+1] = {0.0}

int g_iCamouflageMask = -1;
int g_iUses[MAXPLAYERS] = 0;

public void OnPluginStart(){
    g_iWeapons[0] = WEAPON_AUG;
    g_iWeapons[1] = WEAPON_USP;
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
    g_iUses[iClient] = 0;
    g_fLastUse[iClient] = 0.0;
}

public void CodMod_OnPlayerSpawn(int iClient){
    if(g_bHasClass[iClient]){
        g_bInvisible[iClient] = false;
        g_bWasInvisible[iClient] = false;
        g_iUses[iClient] = 0;
        TH7_SetVisible(iClient);
        if(CodMod_GetPlayerInfo(iClient, PERK) == g_iCamouflageMask){
          TH7_SetRenderColor(iClient, 255, 255, 255, 76);
        }
    }
}


public Action Timer_SetVisible(Handle hTimer, int iClient){
    iClient = GetClientFromSerial(iClient);
    if(!IsValidPlayer(iClient)){
        return Plugin_Stop;
    }

    SetEntPropFloat(iClient, Prop_Send, "m_flProgressBarStartTime", 0.0);
    SetEntProp(iClient, Prop_Send, "m_iProgressBarDuration", 0);
    if(g_bInvisible[iClient] && IsPlayerAlive(iClient)){
        if(CodMod_GetPlayerInfo(iClient, PERK) == g_iCamouflageMask){
          TH7_SetRenderColor(iClient, 255, 255, 255, 76);
        }
        TH7_SetVisible(iClient);

        PrintToChat(iClient, "%s Znów jesteś widzialny!", PREFIX_SKILL)
        g_bInvisible[iClient] = false;
    }

    return Plugin_Stop;
}

public CodMod_OnPlayerDamaged(int iAttacker, int iVictim, float &fDamage, WeaponID iWeaponID, int iDamageType){
    if(g_bHasClass[iVictim] && g_bInvisible[iVictim] && (iWeaponID == WEAPON_MOLOTOV || iWeaponID == WEAPON_HEGRENADE || (iDamageType & DMG_BURN))){
        fDamage = 0.0;
    }

}

public void CodMod_OnClassSkillUsed(int iClient){
    if(!g_bHasClass[iClient] || !IsPlayerAlive(iClient) )
        return;


    if(g_iUses[iClient] >= 2) {
        PrintToChat(iClient, "%s Użyłeś już swojej umiejętności 2 razy w tej rundzie!", PREFIX_SKILL)
        return;
    } 

    if(GetGameTime() - g_fLastUse[iClient] <= 20.0)
    {
        PrintToChat(iClient, "%s Możesz użyć umiejętności za %.1fs!", PREFIX_SKILL, 20.0 - (GetGameTime() - g_fLastUse[iClient]));
        return;
    }

    g_fLastUse[iClient] = GetGameTime();
    g_bInvisible[iClient] = true;
    g_bWasInvisible[iClient] = true;
    //TH7_SetRenderColor(iClient, 255, 255, 255, 10);
    TH7_SetInvisible(iClient);
    CreateTimer(2.0, Timer_SetVisible, GetClientSerial(iClient));
    PrintToChat(iClient, "%s Użyłeś swojej umiejętności!", PREFIX_SKILL)

    SetEntPropFloat(iClient, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
    SetEntProp(iClient, Prop_Send, "m_iProgressBarDuration", 2);

    g_iUses[iClient]++;
}

public void CodMod_OnGiveExp(int iAttacker, int iVictim, int &iExp, bool bHeadshot){
    if(g_bHasClass[iAttacker] && GetRandomInt(1,8) == 1)
    {
       iExp = RoundToFloor(iExp*1.5);
    }
}

public Action Event_OnFlashPlayer(Event hEvent, const char[] szEvent, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
	if(g_bInvisible[iClient])
		SetEntPropFloat(iClient, Prop_Send, "m_flFlashMaxAlpha", 0.5);

	return Plugin_Handled;
}
