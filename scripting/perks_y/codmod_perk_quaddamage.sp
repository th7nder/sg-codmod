#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <codmod301>


public Plugin:myinfo = {
	name = "Call of Duty Mod - Perk - Quad Damage",
	author = "th7nder",
	description = "CODMOD's Perk",
	version = "1.0",
	url = "http://th7.eu"
};

new const String:szClassName[NAME_LENGTH] = {"Quad Damage"};
new const String:szDesc[DESC_LENGTH] = {"Po użyciu(codmod_perk) przez 5 sec zadajesz 4x więcej obrażeń."};
new g_iPerkId;

new bool:g_bHasItem[MAXPLAYERS +1] = {false};

bool g_bUsed[MAXPLAYERS + 1] = {false};
bool g_bUsing[MAXPLAYERS+1] = {false};

public OnPluginStart(){
	g_iPerkId = CodMod_RegisterPerk(szClassName, szDesc);
}


public OnPluginEnd(){
	CodMod_UnregisterPerk(g_iPerkId);
}

public OnClientPutInServer(iClient){
	g_bHasItem[iClient] = false;
	g_bUsed[iClient] = false;
	g_bUsing[iClient] = false;
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

	g_bUsed[iClient] = false;
	g_bUsing[iClient] = false;
}

public CodMod_OnPlayerSpawn(iClient){
	if(g_bHasItem[iClient]){
		g_bUsed[iClient] = false;
	}
}



public void CodMod_OnPerkSkillUsed(int iClient){
	if(!IsValidPlayer(iClient) || !IsPlayerAlive(iClient) || !g_bHasItem[iClient])
		return;

	if(g_bUsed[iClient]){
		PrintToChat(iClient, "%s Użyłeś już quad damage'u!", PREFIX_INFO);
		return;
	}


	g_bUsing[iClient] = true;
	g_bUsed[iClient] = true;

 	SetEntPropFloat(iClient, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
    SetEntProp(iClient, Prop_Send, "m_iProgressBarDuration", 5);
	CreateTimer(5.0, Timer_Reset, GetClientSerial(iClient));
}


public Action Timer_Reset(Handle hTimer, iClient){
	iClient = GetClientFromSerial(iClient);
	if(IsValidPlayer(iClient)){
		SetEntPropFloat(iClient, Prop_Send, "m_flProgressBarStartTime", 0.0);
   		SetEntProp(iClient, Prop_Send, "m_iProgressBarDuration", 0);
	}
	g_bUsing[iClient] = false;

	return Plugin_Stop;
}


public CodMod_OnPlayerDamagedPerk(int iAttacker, int iVictim, float &fDamage, WeaponID iWeaponID, int iDamageType){
	if(g_bHasItem[iAttacker] && g_bUsing[iAttacker]){
		fDamage *= 4.0;
	}
}
