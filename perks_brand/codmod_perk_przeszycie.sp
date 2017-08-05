#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <codmod301>


public Plugin:myinfo = {
	name = "Call of Duty Mod - Perk - Przeszycie",
	author = "th7nder",
	description = "CODMOD's Perk",
	version = "1.0",
	url = "http://th7.eu"
};

new const String:szClassName[NAME_LENGTH] = {"Przeszycie"};
new const String:szDesc[DESC_LENGTH] = {"Omijasz całą wytrzymałość wroga."};
int g_iPerkId;

bool g_bHasItem[MAXPLAYERS +1] = {false};

public void OnPluginStart(){
	g_iPerkId = CodMod_RegisterPerk(szClassName, szDesc);
}


public void OnPluginEnd(){
	CodMod_UnregisterPerk(g_iPerkId);
}

public void OnClientPutInServer(iClient){
	g_bHasItem[iClient] = false;
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
