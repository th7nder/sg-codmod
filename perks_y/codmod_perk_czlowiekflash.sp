#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <codmod301>


public Plugin:myinfo = {
	name = "Call of Duty Mod - Perk - Człowiek Flash",
	author = "th7nder",
	description = "CODMOD's Perk",
	version = "1.5",
	url = "http://th7.eu"
};

new const String:szClassName[NAME_LENGTH] = {"Człowiek Flash"};
new const String:szDesc[DESC_LENGTH] = {"Po wciśnięciu codmod_perk, oślepia przeciwników w danym promieniu(co 15 sec)"};
new g_iPerkId;

new bool:g_bHasItem[MAXPLAYERS +1] = {false};
float g_fLastUsed[MAXPLAYERS+1] = {0.0};

int g_beamSprite = -1, g_haloSprite = -1;


public OnPluginStart(){
	g_iPerkId = CodMod_RegisterPerk(szClassName, szDesc);
}

public OnPluginEnd(){
	CodMod_UnregisterPerk(g_iPerkId);
}

public void OnMapStart(){
	g_beamSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
	g_haloSprite = PrecacheModel("materials/sprites/halo.vmt")
}

public void OnClientPutInServer(iClient){
	g_bHasItem[iClient] = false;
	g_fLastUsed[iClient] = 0.0;
}

public void CodMod_OnPerkEnabled(iClient, iPerkId){
	if(iPerkId != g_iPerkId)
		return;

	g_bHasItem[iClient] = true;
	g_fLastUsed[iClient] = 0.0;
}

public void CodMod_OnPerkDisabled(iClient, iPerkId){
	if(iPerkId != g_iPerkId)
		return;

	g_bHasItem[iClient] = false;
	g_fLastUsed[iClient] = 0.0;
}

public void CodMod_OnPlayerSpawn(iClient){
	if(g_bHasItem[iClient]){
		g_fLastUsed[iClient] = 0.0;
	}
}

stock void BeamRing(color[4], Float:vec[3]){

	vec[2] += 10.0;
	TE_SetupBeamRingPoint(vec, 20.0, 650.0, g_beamSprite, g_haloSprite, 0, 10, 0.6, 10.0, 0.5, color, 10, 0);
	TE_SendToAll();
}

public void Player_Blind(int iClient, int iMsecs, int iRed, int iGreen, int iBlue, int iAlpha){
	int iColor[4];
	iColor[0] = iRed;
	iColor[1] = iGreen;
	iColor[2] = iBlue;
	iColor[3] = iAlpha;
	Handle hFadeClient = StartMessageOne("Fade", iClient)
	PbSetInt(hFadeClient, "duration", 100);
	PbSetInt(hFadeClient, "hold_time", iMsecs);
	PbSetInt(hFadeClient, "flags", (0x0010|0x0002));
	PbSetColor(hFadeClient, "clr", iColor);
	EndMessage();
}

public void CodMod_OnPerkSkillUsed(int iClient){
	if(!IsValidPlayer(iClient) || !IsPlayerAlive(iClient) || !g_bHasItem[iClient])
		return;

	if(g_fLastUsed[iClient] != 0.0 && GetGameTime() - g_fLastUsed[iClient] <= 15.0){
		float fNextUse = 15.0;
		fNextUse -= (GetGameTime() - g_fLastUsed[iClient]);
		PrintToChat(iClient, "%s Następne użycie za: %.1f", PREFIX_INFO, fNextUse);
		return;
	}


	g_fLastUsed[iClient] = GetGameTime();
	float fOrigin[3];
	GetClientAbsOrigin(iClient, fOrigin);
	BeamRing({0, 200, 0, 255}, fOrigin);
	int iTeam = GetClientTeam(iClient);

	float fTargetOrigin[3];
	for(int i = 1; i <= MaxClients; i++){
		if(IsClientInGame(i) && IsPlayerAlive(i) && iTeam != GetClientTeam(i)){
			GetClientAbsOrigin(i, fTargetOrigin);
			if(GetVectorDistance(fTargetOrigin, fOrigin) <= 650.0){
				Player_Blind(i, 2500, 255, 255, 255, 255);
			}

		}
	}

	return;
}
