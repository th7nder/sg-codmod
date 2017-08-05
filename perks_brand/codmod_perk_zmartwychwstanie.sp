#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <codmod301>


public Plugin:myinfo = {
	name = "Call of Duty Mod - Perk - Zmartwychwstanie",
	author = "th7nder",
	description = "CODMOD's Perk",
	version = "1.0",
	url = "http://th7.eu"
};

new const String:szClassName[NAME_LENGTH] = {"Zmartwychwstanie"};
new const String:szDesc[DESC_LENGTH] = {"Jeżeli zginąłeś i użyjesz codmod_perk po 5sec ożyjesz na nowo w tym samym miejscu co umarłeś."};
int g_iPerkId;

bool g_bHasItem[MAXPLAYERS +1] = {false};

float g_fDied[MAXPLAYERS+1][3];
bool g_bUsed[MAXPLAYERS+1] = {false};

public void OnPluginStart(){
	g_iPerkId = CodMod_RegisterPerk(szClassName, szDesc);
    HookEvent("round_start", Event_OnRoundStart);
}


public void OnPluginEnd(){
	CodMod_UnregisterPerk(g_iPerkId);
}

public void OnClientPutInServer(iClient){
	g_bHasItem[iClient] = false;
    g_bUsed[iClient] = false;
}

public void CodMod_OnPerkEnabled(iClient, iPerkId){
	if(iPerkId != g_iPerkId)
		return;

	g_bHasItem[iClient] = true;

}


public void CodMod_OnPerkDisabled(int iClient, int iPerkId){
    if(iPerkId != g_iPerkId)
        return;

    g_bHasItem[iClient] = false;
}



public void CodMod_OnPlayerDie(int iAttacker, int iVictim, bool bHeadshot){
    if(g_bHasItem[iVictim]){
        GetClientAbsOrigin(iVictim, g_fDied[iVictim]);
    }
}

public Action Event_OnRoundStart(Event hEvent, const char[] szBroadcast, bool bBroadcast)
{
    for(int i = 1; i <= MaxClients; i++)
    {
        if(IsClientInGame(i))
        {
            g_bUsed[i] = false;
        }
    }
}

public void CodMod_OnPerkSkillUsed(int iClient){
    if(!IsValidPlayer(iClient) || IsPlayerAlive(iClient) || !g_bHasItem[iClient])
        return;

    if(g_bUsed[iClient]){
        PrintToChat(iClient, "%sJuż zmartwychwstałeś w tej rundzie!", PREFIX_SKILL);
        return;
    }

    g_bUsed[iClient] = true;
    CreateTimer(5.0, Timer_Respawn, GetClientSerial(iClient));
    PrintToChat(iClient, "%sZa 5 sekund się pojawisz w tym miejscu gdzie zginąłeś!", PREFIX_SKILL);

}


public Action Timer_Respawn(Handle hTimer, int iSerial)
{
    int iClient = GetClientFromSerial(iSerial);
    if(IsValidPlayer(iClient) && g_bHasItem[iClient] && !IsPlayerAlive(iClient))
    {
        CS_RespawnPlayer(iClient);
        if(IsValidPlayerPos(iClient, g_fDied[iClient]))
        {
             TeleportEntity(iClient, g_fDied[iClient], NULL_VECTOR, NULL_VECTOR);
        }
    }
}
