#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <codmod301>


public Plugin myinfo = {
	name = "Call of Duty Mod - Perk - Apteczka",
	author = "th7nder",
	description = "CODMOD's Perk",
	version = "2.0",
	url = "http://th7.eu"
};

char szClassName[NAME_LENGTH] = {"Apteczka"};
char szDesc[DESC_LENGTH] = {"Co 5 sekund możesz użyć apteczki na codmod_perk(70HP + int)"};
int g_iPerkId;

bool g_bHasItem[MAXPLAYERS +1] = {false};


int g_iUsed[MAXPLAYERS + 1] = {-1};
float g_fLastUsed[MAXPLAYERS + 1] = {0.0};

public void OnPluginStart(){
	g_iPerkId = CodMod_RegisterPerk(szClassName, szDesc);
}

public OnPluginEnd(){
	CodMod_UnregisterPerk(g_iPerkId);
}

public void OnClientPutInServer(iClient){
	g_bHasItem[iClient] = false;
	g_iUsed[iClient] = 0;
	g_fLastUsed[iClient] = 0.0;
}

public void CodMod_OnPerkEnabled(iClient, iPerkId){
	if(iPerkId != g_iPerkId)
		return;

	g_bHasItem[iClient] = true;
	g_iUsed[iClient] = 0;
	g_fLastUsed[iClient] = 0.0;
}

public void CodMod_OnPerkDisabled(iClient, iPerkId){
	if(iPerkId != g_iPerkId)
		return;

	g_bHasItem[iClient] = false;
	g_iUsed[iClient] = 0;
}

public void CodMod_OnPlayerSpawn(iClient){
	if(g_bHasItem[iClient]){
		g_iUsed[iClient] = 0;
		g_fLastUsed[iClient] = 0.0;
	}
}


public void CodMod_OnPerkSkillUsed(int iClient){
	if(!IsPlayerAlive(iClient) || !g_bHasItem[iClient])
		return;

	if(g_iUsed[iClient] + 1 > 2){
		PrintToChat(iClient, "%s Apteczki możesz użyć 2 razy na rundę!", PREFIX);
		return;
	}

	if(GetGameTime() - g_fLastUsed[iClient] < 5.0){
		PrintToChat(iClient, "%s Apteczki możesz użyć co 5 sekund!", PREFIX);
		return;
	}

	g_iUsed[iClient]++;
	g_fLastUsed[iClient] = GetGameTime();
	int iAmount = 70 + CodMod_GetWholeStat(iClient, INT);
	CodMod_Heal(iClient, iClient, iAmount);
	PrintToChat(iClient, "%s Pomyślnie uleczono o: %d HP!", PREFIX, iAmount);
}
