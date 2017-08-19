#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <th7manager>
#define PLUGIN_VERSION "1.0.1"


#include <codmod301>

bool g_bGrenadeBlockade = false;
Handle g_hTimer = INVALID_HANDLE;
int g_iCounter = 0;
public Plugin myinfo =
{
	name = "Grenade Blockade",
	author = "th7nder",
	description = "Grenade Blockade",
	version = PLUGIN_VERSION,
	url = "http://serwery-go.pl"
}

public void OnClientPutInServer(int iClient) {
	SDKHook(iClient, SDKHook_PreThink, Prethink);
}

public OnClientDisconnect(int iClient) {
	SDKUnhook(iClient, SDKHook_PreThink, Prethink);
}

public OnPluginStart() {
	HookEvent("round_freeze_end", RoundStart);
}

public OnMapStart() {
	g_hTimer = INVALID_HANDLE;
}

public Action Prethink(int iClient) {
		int iButtons = GetClientButtons(iClient);
		int iWeapon = GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");

		int iPlayerClassID = CodMod_GetPlayerInfo(iClient, CLASS)
		int iClassID = CodMod_GetClassId("Juan Deag");
		if(iPlayerClassID == iClassID) {
			return;
		}

		if(IsValidPlayer(iClient) && IsPlayerAlive(iClient)){
			if(g_bGrenadeBlockade){
				char szWeapon[64];
				GetClientWeapon(iClient, szWeapon, sizeof(szWeapon));
				if(/*StrEqual(szWeapon, "weapon_flashbang") || */StrEqual(szWeapon, "weapon_hegrenade")) {
					if(iButtons & IN_ATTACK || iButtons & IN_ATTACK2){
						if(iWeapon != -1 && IsValidEdict(iWeapon)){
							SetEntProp(iClient, Prop_Data, "m_nButtons", iButtons & ~IN_ATTACK);
							SetEntPropFloat(iWeapon, Prop_Send, "m_flNextSecondaryAttack", GetGameTime() + 999.0);
							PrintHintText(iClient, "  Granaty będą dostępne za: \n  <font color='#00CC00'>%d</font> sekund!", 15 - g_iCounter);
						}
					}
				}
			} else if(iWeapon != -1 && IsValidEdict(iWeapon)){
				char szWeapon[64];
				GetClientWeapon(iClient, szWeapon, sizeof(szWeapon));
				if(/*StrEqual(szWeapon, "weapon_flashbang") ||*/ StrEqual(szWeapon, "weapon_hegrenade")){
					float fNextAttack = GetEntPropFloat(iWeapon, Prop_Send, "m_flNextSecondaryAttack");
					if(fNextAttack - GetGameTime() >= 100.0){
						SetEntPropFloat(iWeapon, Prop_Send, "m_flNextSecondaryAttack", GetGameTime());
					}
				}
			}
        }
}

public Action RoundStart(Handle hEvent, const char[] szName, bool bDontBroadcast) {
	if(g_hTimer != INVALID_HANDLE){
		KillTimer(g_hTimer);
		g_hTimer = INVALID_HANDLE;
	}
	g_bGrenadeBlockade = true;
	g_iCounter = 0;
	g_hTimer = CreateTimer(1.0, Grenade_Blockade, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public Action Grenade_Blockade(Handle hTimer){
	if(g_iCounter + 1 <= 15){
		g_iCounter++;
		return Plugin_Continue;
	}

	g_iCounter = 0;
	g_bGrenadeBlockade = false;
	g_hTimer = INVALID_HANDLE;


	return Plugin_Stop;
}

/*public bool IsValidPlayer(iClient){
	if(iClient > 0 && iClient <= MaxClients && IsValidEdict(iClient) && IsClientInGame(iClient) && !IsFakeClient(iClient)){
		return true;
	}

	return false;
}*/	