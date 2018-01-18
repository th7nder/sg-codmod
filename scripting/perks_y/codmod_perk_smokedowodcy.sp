#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <codmod301>


public Plugin:myinfo = {
	name = "Call of Duty Mod - Perk - Smoke Dowódcy",
	author = "th7nder",
	description = "CODMOD's Perk",
	version = "1.0",
	url = "http://th7.eu"
};

new const String:szClassName[NAME_LENGTH] = {"Smoke Dowódcy"};
new const String:szDesc[DESC_LENGTH] = {"Na początku rundy dostajesz smoke'a, gdy trafisz nim w kogoś - zabijasz.\n Kolejny smoke 20 sec po rzuceniu."};
new g_iPerkId;



const float g_fNextGrenadeTime = 20.0;
new bool:g_bHasItem[MAXPLAYERS +1] = {false};



public OnPluginStart(){
	g_iPerkId = CodMod_RegisterPerk(szClassName, szDesc);
}

public OnPluginEnd(){
	CodMod_UnregisterPerk(g_iPerkId);
}


public OnClientPutInServer(iClient){
	g_bHasItem[iClient] = false;
}

public CodMod_OnPerkEnabled(iClient, iPerkId){
	if(iPerkId != g_iPerkId)
		return;

	g_bHasItem[iClient] = true;
	if(!CodMod_GetPlayerNades(iClient, TH7_SMOKE)){
		GivePlayerItem(iClient, "weapon_smokegrenade");
	}

}

public CodMod_OnPerkDisabled(iClient, iPerkId){
	if(iPerkId != g_iPerkId)
		return;

	g_bHasItem[iClient] = false;
}



public CodMod_OnPlayerSpawn(iClient){
	if(g_bHasItem[iClient]){
		if(!CodMod_GetPlayerNades(iClient, TH7_SMOKE)){
			GivePlayerItem(iClient, "weapon_smokegrenade");
		}
	}

}

public OnEntityCreated(iEntity, const String:szClassname[]){
	if(StrEqual(szClassname, "smokegrenade_projectile")){
		SDKHook(iEntity, SDKHook_Spawn, OnSpawn);
		SDKHook(iEntity, SDKHook_StartTouch, OnSmokeTouch);
	}
}

public Action OnSpawn(int iGrenade)
{
	int iOwner = GetEntPropEnt(iGrenade, Prop_Data, "m_hOwnerEntity");
	if(IsValidPlayer(iOwner) && g_bHasItem[iOwner]){
		Handle hPack = CreateDataPack();
		WritePackCell(hPack, GetClientSerial(iOwner));
		WritePackCell(hPack, CodMod_GetRoundIndex());
		CreateTimer(g_fNextGrenadeTime, Timer_GiveGrenade, hPack);
	}
}

public Action Timer_GiveGrenade(Handle hTimer, Handle hPack)
{
	ResetPack(hPack);
	int iSerial = ReadPackCell(hPack);
	int iRoundIndex = ReadPackCell(hPack);
	delete hPack;

	
	if(CodMod_GetRoundIndex() != iRoundIndex)
	{
		return Plugin_Stop;
	}

	int iClient = GetClientFromSerial(iSerial);
	if(!IsValidPlayer(iClient) || CodMod_GetPlayerNades(iClient, TH7_SMOKE))
	{
		return Plugin_Stop;
	}

	GivePlayerItem(iClient, "weapon_smokegrenade");


	return Plugin_Stop;
}

public OnSmokeTouch(iGrenade, iClient){
	if(IsValidPlayer(iClient) && IsPlayerAlive(iClient)){
		new iOwner = GetEntPropEnt(iGrenade, Prop_Data, "m_hOwnerEntity");
		if(IsValidPlayer(iOwner) && g_bHasItem[iOwner] && GetClientTeam(iOwner) != GetClientTeam(iClient)){
			CodMod_DealDamage(iOwner, iClient, 1000.0, TH7_DMG_SMOKE);
			CreateTimer(0.1, Timer_AcceptKill, iGrenade);
		}
	}
}

