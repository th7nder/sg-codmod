#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <th7manager>

#include <emitsoundany>

#define _IN_CODMOD_CLASS 1
#include <codmod301>
public Plugin myinfo = {
    name = "CodMod 301 - Class - Dowódca",
    author = "th7nder",
    description = "Dowódca Class from CodMod 301",
    version = "2.0",
    url = "http://serwery-go.pl"
};

WeaponID g_iWeapons[WEAPON_LIMIT] = {WEAPON_NONE};



char g_szClassName[128] = {"Dowódca"};
char g_szDesc[256] = {"130HP, M4A4, FiveSeven, Smoke\n 1/1 ze smoke'a, +30dmg w głowę\n NoFlash\nDostaje smoke co 15 sekund"};
const int g_iHealth = 0;
const int g_iStartingHealth = 130;
const int g_iArmor = 0;
const int g_iDexterity = 0;
const int g_iIntelligence = 0;
int g_iClassId = 0;
bool g_bHasClass[MAXPLAYERS+1]    = {false};
public void OnPluginStart(){
    g_iWeapons[0] = WEAPON_M4A4;
    g_iWeapons[1] = WEAPON_FIVESEVEN;
    g_iWeapons[2] = WEAPON_SMOKEGRENADE;
    g_iClassId = CodMod_RegisterClass(g_szClassName, g_szDesc, g_iHealth, g_iArmor, g_iDexterity, g_iIntelligence, g_iWeapons, 0, g_iStartingHealth);
    HookEvent("player_blind", Event_OnFlashPlayer, EventHookMode_Pre);
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

}


public CodMod_OnPlayerDamaged(int iAttacker, int iVictim, float &fDamage, WeaponID iWeaponID, int iDamageType){
    if(g_bHasClass[iAttacker] && (iDamageType & DMG_HEADSHOT)){
        fDamage += 30.0;
    }

}

public Action CodMod_OnPlayerBlind(int iClient, int &mSecs) {
    if(g_bHasClass[iClient]) {
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

public Action:Event_OnFlashPlayer(Event hEvent, const char[] szEvent, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
	if(g_bHasClass[iClient])
		SetEntPropFloat(iClient, Prop_Send, "m_flFlashMaxAlpha", 0.5);

	return Plugin_Handled;
}

public OnEntityCreated(int iEnt, const char[] szClassname){
	if(StrEqual(szClassname, "smokegrenade_projectile")){
        SDKHook(iEnt, SDKHook_SpawnPost, SpawnPost_Smoke)
        SDKHook(iEnt, SDKHook_StartTouch, OnSmokeTouch);
	}
}


public Action OnSmokeTouch(int iGrenade, int iClient){
	if(IsValidPlayer(iClient) && IsPlayerAlive(iClient)){
		int iOwner = GetEntPropEnt(iGrenade, Prop_Data, "m_hOwnerEntity");
		if(IsValidPlayer(iOwner) && g_bHasClass[iOwner] && GetClientTeam(iOwner) != GetClientTeam(iClient)){
			CodMod_DealDamage(iOwner, iClient, 1000.0, TH7_DMG_SMOKE);
			RemoveEdict(iGrenade);
		}
	}
}

public Action SpawnPost_Smoke(int iGrenade) {
    int iOwner = GetEntPropEnt(iGrenade, Prop_Data, "m_hOwnerEntity");
    if(IsValidPlayer(iOwner) && g_bHasClass[iOwner]) {
        CreateTimer(15.0, Timer_GiveSmoke, GetClientSerial(iOwner), TIMER_FLAG_NO_MAPCHANGE);
    }
}

public Action Timer_GiveSmoke(Handle hTimer, int iSerial) {
    int iClient = GetClientFromSerial(iSerial);
    if(IsValidPlayer(iClient) && g_bHasClass[iClient]) {
        GivePlayerItem(iClient, "weapon_smokegrenade");
    }
}