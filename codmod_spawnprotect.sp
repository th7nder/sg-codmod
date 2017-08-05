#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <codmod301>


public Plugin:myinfo = {
	name = "Call of Duty Mod - SpawnProtect",
	author = "th7nder",
	description = "CODMOD's Perk",
	version = "1.0",
	url = "http://skyhorn.tech"
};


float g_fRoundStartedTime = 0.0;
int g_iRoundIndex = 0;
bool g_bProtection[MAXPLAYERS+1] = {false};

public OnPluginStart(){
	HookEvent("round_start", Event_OnRoundStart);
}


public void OnMapStart(){
	g_fRoundStartedTime = 0.0;
	g_iRoundIndex = 0;
}

public Action Event_OnRoundStart(Event hEvent, const char[] szBroadcast, bool bBroadcast){
	g_fRoundStartedTime = GetGameTime();
	g_iRoundIndex++;

	for(int i = 1; i <= MaxClients; i++){
		g_bProtection[i] = false;
	}
}

public void CodMod_OnPlayerSpawn(int iClient){
	if(GetGameTime() - g_fRoundStartedTime > 20.0){
		g_bProtection[iClient] = true;
		Handle hPack = CreateDataPack();
		WritePackCell(hPack, GetClientFromSerial(iClient));
		WritePackCell(hPack, g_iRoundIndex);
		CreateTimer(5.0, Timer_DisableProtection, hPack);
	}
}

public Action Timer_DisableProtection(Handle hTimer, Handle hPack){
	ResetPack(hPack);
	int iClient = GetClientFromSerial(ReadPackCell(hPack));
	int iRoundIndex = ReadPackCell(hPack);
	delete hPack;

	if(iRoundIndex != g_iRoundIndex){
		return Plugin_Stop;
	}

	if(!IsValidPlayer(iClient) || !IsPlayerAlive(iClient)){
		return Plugin_Stop;
	}

	g_bProtection[iClient] = false;

	return Plugin_Stop;
}


public CodMod_OnPlayerDamaged(int iAttacker, int iVictim, float &fDamage, WeaponID iWeaponID, int iDamageType){
	if(g_bProtection[iAttacker]){
		g_bProtection[iAttacker] = false;
	}

	if(g_bProtection[iVictim]){
		fDamage = 0.0;
	}
}

public void CodMod_OnTH7Dmg(int iVictim, int iAttacker, float &fDamage, int iTH7Dmg){
	if(g_bProtection[iVictim]){
		fDamage = 0.0;
	}
}