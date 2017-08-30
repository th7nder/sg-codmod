#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <codmod301>


public Plugin:myinfo = {
	name = "Call of Duty Mod - Perk - Podmuch Lodu",
	author = "th7nder",
	description = "CODMOD's Perk",
	version = "1.0",
	url = "http://th7.eu"
};

#define MAXUSES 2

new const String:szClassName[NAME_LENGTH] = {"Podmuch lodu"};
new const String:szDesc[DESC_LENGTH] = {"Zamrażasz przeciwników w odległości 600u od siebie na 2 sekundy"};
new g_iPerkId;

new bool:g_bHasItem[MAXPLAYERS +1] = {false};

float g_fLastUse[MAXPLAYERS+1] = {0.0};
int g_iUses[MAXPLAYERS+1] = {0};

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


public void CodMod_OnPlayerSpawn(int iClient)
{
        g_iUses[iClient] = 0;
}

public void CodMod_OnPerkSkillUsed(int iClient){
	if(!IsValidPlayer(iClient) || !IsPlayerAlive(iClient) || !g_bHasItem[iClient])
		return;

	if(GetGameTime() - g_fLastUse[iClient] < 5.0){
                PrintToChat(iClient, "%s Zamrożenia można używać co 5 sekundy!", PREFIX_SKILL);
                return;
        }

	if(g_iUses[iClient] + 1 <= MAXUSES){
                g_fLastUse[iClient] = GetGameTime();
                g_iUses[iClient]++;
                PrintToChat(iClient, "%s Uzyłeś zamrożenia!", PREFIX_SKILL);
                CodMod_RadiusFreeze(iClient, 600, 2.0);
	} else {
                PrintToChat(iClient, "%s Wykorzystałeś już %d zamrożeń w tej rundzie!", PREFIX_SKILL, MAXUSES)
        }
}
	
