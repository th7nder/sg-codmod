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
new const String:szDesc[DESC_LENGTH] = {"Na początku rundy dostajesz smoke'a, gdy trafisz nim w kogoś - zabijasz."};
new g_iPerkId;


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
		SDKHook(iEntity, SDKHook_StartTouch, OnSmokeTouch);
	}
}

public OnSmokeTouch(iGrenade, iClient){
	if(IsValidPlayer(iClient) && IsPlayerAlive(iClient)){
		new iOwner = GetEntPropEnt(iGrenade, Prop_Data, "m_hOwnerEntity");
		if(IsValidPlayer(iOwner) && g_bHasItem[iOwner]){
			CodMod_DealDamage(iOwner, iClient, 1000.0, TH7_DMG_SMOKE);
			CreateTimer(0.1, Timer_AcceptKill, iGrenade);
		}
	}
}
