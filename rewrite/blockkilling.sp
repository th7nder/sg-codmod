#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <dhooks>

public Plugin myinfo = {
	name = "Block",
	author = "th7nder",
	description = "Block kill",
	version = "0.005",
	url = "http://serwery-go.pl"
};

public void OnPluginStart(){
	RegConsoleCmd("kill", Command_Block);
}

public Action Command_Block(int iClient, int iArgs){
	if(GameRules_GetProp("m_bWarmupPeriod") == 1){
		return Plugin_Handled
	}

	return Plugin_Continue;
}
