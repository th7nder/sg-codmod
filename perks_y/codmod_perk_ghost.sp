#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <codmod301>


public Plugin:myinfo = {
	name = "Call of Duty Mod - Perk - Ghost",
	author = "th7nder",
	description = "CODMOD's Perk",
	version = "1.0",
	url = "http://th7.eu"
};

new const String:szClassName[NAME_LENGTH] = {"Ghost"};
new const String:szDesc[DESC_LENGTH] = {"Przechodzisz przez ściany przez 2 sec po naciśnięciu codmod_perk."};
new g_iPerkId;

new bool:g_bHasItem[MAXPLAYERS +1] = {false};

bool g_bUnlockFreeze = false;

bool g_bUsed[MAXPLAYERS + 1] = {false};
bool g_bUsing[MAXPLAYERS+1] = {false};

float g_fStartOrigin[MAXPLAYERS+1][3];

bool g_bSpawnLock[MAXPLAYERS+1] = {false};

public OnPluginStart(){
	g_iPerkId = CodMod_RegisterPerk(szClassName, szDesc);
	HookEvent("round_start", Event_OnRoundStart);
}

public Action Event_OnRoundStart(Event hEvent, char[] szName, bool bDontBroadcast){
	g_bUnlockFreeze = false;
	CreateTimer(float(GetConVarInt(FindConVar("mp_freezetime"))), Timer_UnlockFreeze);

	return Plugin_Continue;
}

public Action Timer_UnlockFreeze(Handle hTimer){
	g_bUnlockFreeze = true;
}

public OnPluginEnd(){
	CodMod_UnregisterPerk(g_iPerkId);
}

public OnClientPutInServer(iClient){
	g_bHasItem[iClient] = false;
	g_bUsed[iClient] = false;
	g_bUsing[iClient] = false;
	g_bSpawnLock[iClient] = false;
}

public CodMod_OnPerkEnabled(iClient, iPerkId){
	if(iPerkId != g_iPerkId)
		return;

	g_bHasItem[iClient] = true;

	g_bUsed[iClient] = false;
	g_bUsing[iClient] = false;

}

public CodMod_OnPerkDisabled(iClient, iPerkId){
	if(iPerkId != g_iPerkId)
		return;

	g_bHasItem[iClient] = false;

	if(g_bUsing[iClient]){
		SetEntityMoveType(iClient, MOVETYPE_WALK);

		float fOrigin[3];
		GetClientAbsOrigin(iClient, fOrigin);
		if(!IsValidPlayerPos(iClient, fOrigin)){
			TeleportEntity(iClient, g_fStartOrigin[iClient], NULL_VECTOR, NULL_VECTOR);
		}
	}

	g_bUsed[iClient] = false;
	g_bUsing[iClient] = false;
}

public CodMod_OnPlayerSpawn(iClient){
	if(g_bHasItem[iClient]){
		g_bSpawnLock[iClient] = true;
		g_bUsed[iClient] = false;
		SetEntityMoveType(iClient, MOVETYPE_WALK);
		CreateTimer(5.0, Timer_RemoveSpawnLock, iClient);
	}
}



public void CodMod_OnPerkSkillUsed(int iClient){
	if(!IsValidPlayer(iClient) || !IsPlayerAlive(iClient) || !g_bHasItem[iClient] || !g_bUnlockFreeze)
		return;

	if(g_bUsed[iClient] || g_bSpawnLock[iClient]){
		return;
	}


	g_bUsing[iClient] = true;
	g_bUsed[iClient] = true;
	GetClientAbsOrigin(iClient, g_fStartOrigin[iClient]);

	SetEntityMoveType(iClient, MOVETYPE_NOCLIP);
	SetEntPropFloat(iClient, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
    SetEntProp(iClient, Prop_Send, "m_iProgressBarDuration", 2);
	CreateTimer(2.0, Timer_ResetMoveType, GetClientSerial(iClient));

	return;
}


public Action Timer_ResetMoveType(Handle hTimer, int iClient){
	iClient = GetClientFromSerial(iClient);
	if(IsValidPlayer(iClient)){
		SetEntPropFloat(iClient, Prop_Send, "m_flProgressBarStartTime", 0.0);
   		SetEntProp(iClient, Prop_Send, "m_iProgressBarDuration", 0);
	}
	if(IsValidPlayer(iClient) && IsPlayerAlive(iClient) && g_bHasItem[iClient] && g_bUsing[iClient]){
		SetEntityMoveType(iClient, MOVETYPE_WALK);

		float fOrigin[3];
		GetClientAbsOrigin(iClient, fOrigin);
		if(!IsValidPlayerPos(iClient, fOrigin)){
			TeleportEntity(iClient, g_fStartOrigin[iClient], NULL_VECTOR, NULL_VECTOR);
		}
	}

	g_bUsing[iClient] = false;

	return Plugin_Stop;
}
public Action Timer_RemoveSpawnLock(Handle hTimer, iClient){
	if(IsValidPlayer(iClient) && IsPlayerAlive(iClient) && g_bHasItem[iClient]){
		g_bSpawnLock[iClient] = false;
	}
}
