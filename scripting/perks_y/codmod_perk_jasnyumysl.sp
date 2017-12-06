#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <codmod301>
#include <th7manager>


public Plugin:myinfo = {
	name = "Call of Duty Mod - Perk - Jasny Umysł",
	author = "th7nder",
	description = "CODMOD's Perk",
	version = "1.0",
	url = "http://th7.eu"
};

new const String:szClassName[NAME_LENGTH] = {"Jasny Umysł"};
new const String:szDesc[DESC_LENGTH] = {"+40 do inteligencji, widzi niewidzialnych na codmod_perk"};
new g_iPerkId;


new bool:g_bHasItem[MAXPLAYERS +1] = {false};
float g_fLastUsed[MAXPLAYERS+1] = {0.0};

bool g_bTagged[MAXPLAYERS+1][MAXPLAYERS+1];

public OnPluginStart()
{
	g_iPerkId = CodMod_RegisterPerk(szClassName, szDesc);
}



public OnPluginEnd(){
	CodMod_UnregisterPerk(g_iPerkId);
}

public OnClientPutInServer(iClient){
	g_bHasItem[iClient] = false;

	for(int i = 1; i <= MaxClients; i++)
	{
		g_bTagged[i][iClient] = false;
		g_bTagged[iClient][i] = false;
	}
}

public CodMod_OnPerkEnabled(iClient, iPerkId){
	if(iPerkId != g_iPerkId)
		return;

	g_bHasItem[iClient] = true;
	g_fLastUsed[iClient] = 0.0;
	CodMod_SetStat(iClient, INT_PERK, CodMod_GetStat(iClient, INT_PERK) + 40);

}

public CodMod_OnPerkDisabled(iClient, iPerkId){
	if(iPerkId != g_iPerkId)
		return;

	g_bHasItem[iClient] = false;

	CodMod_SetStat(iClient, INT_PERK, CodMod_GetStat(iClient, INT_PERK) - 40);
}


public void CodMod_OnPlayerSpawn(int iClient)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		g_bTagged[i][iClient] = false;
		g_bTagged[iClient][i] = false;
	}
	g_fLastUsed[iClient] = 0.0;
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
	int iTeam = GetClientTeam(iClient);
	float fTargetOrigin[3];
	for(int i = 1; i <= MaxClients; i++){
		if(IsClientInGame(i) && IsPlayerAlive(i) && iTeam != GetClientTeam(i)){
			GetClientAbsOrigin(i, fTargetOrigin);
			if((TH7_GetInvisible(i) || TH7_IsRenderColorEnabled(i)) && GetVectorDistance(fTargetOrigin, fOrigin) <= 600.0){
				SetEntPropFloat(i, Prop_Send, "m_flDetectedByEnemySensorTime", GetGameTime() + 2.0);
				g_bTagged[iClient][i] = true;
			}

		}
	}

	CreateTimer(2.0, Timer_UnTag, iClient);

	return;
}

public Action Timer_UnTag(Handle hTimer, int iClient)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i))
		{
			g_bTagged[iClient][i] = false;
			SetEntPropFloat(i, Prop_Send, "m_flDetectedByEnemySensorTime", 0.0);
		}
	}
}




