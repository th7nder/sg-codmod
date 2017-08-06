#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <dhooks>

#include <codmod301>


#define CHAT_PREFIX_SG "  \x06[\x0BSerwery\x01-\x07GO\x06]\x0A"
bool g_bBought[MAXPLAYERS+1] = {false};
stock bool Player_IsVIP(int iClient){
	if (CheckCommandAccess(iClient, "codmod_vip", ADMFLAG_CUSTOM1, false)) {
		return true;
	} else {
		return false;
	}
}


public void OnPluginStart(){
	RegConsoleCmd("respawn", Command_Respawn);
	HookEvent("player_spawn", Event_OnPlayerSpawn);
}

public void OnClientPutInServer(int iClient){
	g_bBought[iClient] = false;
//	if(Player_IsVIP(iClient)){
//		PrintToChatAll("%s VIP \x07 %N \x0Awszedł na serwer! Witamy!", CHAT_PREFIX_SG, iClient);
	//}
}

public Action Event_OnPlayerSpawn(Event hEvent, const char[] szEvName, bool bDontBroadcast) {
	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
	CreateTimer(1.0, Timer_TakeMoney, GetClientSerial(iClient));
	return Plugin_Continue;
}


public Action Timer_TakeMoney(Handle hTimer, int iClient){
	iClient = GetClientFromSerial(iClient);
	if(iClient > 0 && IsClientInGame(iClient) && IsPlayerAlive(iClient)){
		if(g_bBought[iClient]){
			SetEntProp(iClient, Prop_Send, "m_iAccount", GetEntProp(iClient, Prop_Send, "m_iAccount") - 32000);
			g_bBought[iClient] = false;
		}

	}
}


public Action Command_Respawn(int iClient, int iArgs){
	if(IsClientInGame(iClient)){
		if(!IsPlayerAlive(iClient)){
			if(Player_IsVIP(iClient)){
				int iMoney = GetEntProp(iClient, Prop_Send, "m_iAccount");
				if(iMoney >= 32000){
					g_bBought[iClient] = true;
					SetEntProp(iClient, Prop_Send, "m_iAccount", iMoney - 32000);
					CS_RespawnPlayer(iClient);
				} else {
					PrintToChat(iClient, "%s Szanowny VIPie, nie masz wystarczającej ilości dolarów.", CHAT_PREFIX_SG);
				}
			} else {
				PrintToChat(iClient, "%s Musisz być VIPem aby używać tej komendy!", CHAT_PREFIX_SG);
			}
		} else {
			PrintToChat(iClient, "%s Musisz być martwy aby tego użyć!", CHAT_PREFIX_SG);
		}
	}

	return Plugin_Handled;
}


char g_szGrenadeNames[][] = {
    "weapon_flashbang",
    "weapon_molotov",
    "weapon_smokegrenade",
    "weapon_hegrenade",
    "weapon_decoy",
    "weapon_incgrenade",
    "weapon_tagrenade"
};

public void CodMod_OnPlayerSpawn(int iClient){
	if(Player_IsVIP(iClient)){
			SetEntProp(iClient, Prop_Send, "m_iAccount", GetEntProp(iClient, Prop_Send, "m_iAccount") + 6000);

		int iRandom, iCounter = 0;
		do {
			iRandom = GetRandomInt(0, 5);
			iCounter++;

		} while(CodMod_GetPlayerNades(iClient, iRandom) && iCounter < 6);

		GivePlayerItem(iClient, g_szGrenadeNames[iRandom]);
		PrintToChat(iClient, "%s Otrzymałeś granat(%s), gdyż jesteś wybornym VIPem!", CHAT_PREFIX_SG, g_szGrenadeNames[iRandom]);
	}
}
