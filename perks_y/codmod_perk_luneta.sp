#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <codmod301>


public Plugin:myinfo = {
	name = "Call of Duty Mod - Perk - Luneta",
	author = "th7nder",
	description = "CODMOD's Perk",
	version = "1.0",
	url = "http://th7.eu"
};

new const String:szClassName[NAME_LENGTH] = {"Luneta"};
new const String:szDesc[DESC_LENGTH] = {"Posiadasz zooma na każdej broni, na codmod_perk"};
new g_iPerkId;


new bool:g_bHasItem[MAXPLAYERS +1] = {false};
int g_iFOV[MAXPLAYERS+1] = {-1};
int g_iPreviousButtons[MAXPLAYERS+1] = {0};
public OnPluginStart(){
	g_iPerkId = CodMod_RegisterPerk(szClassName, szDesc);
}

public OnPluginEnd(){
	CodMod_UnregisterPerk(g_iPerkId);
}

public OnClientPutInServer(iClient){
	g_bHasItem[iClient] = false;
	g_iFOV[iClient] = -1;
	g_iPreviousButtons[iClient] = -1;
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

public void CodMod_OnPerkSkillUsed(int iClient){
	if(g_bHasItem[iClient]){
		int iFOV = GetEntProp(iClient, Prop_Send, "m_iFOV");
		PrintToChat(iClient, "%s Switching scope!", PREFIX_INFO);
		if(iFOV == 15){
			SetEntProp(iClient, Prop_Send, "m_iFOV", g_iFOV[iClient]);
		} else {
			g_iFOV[iClient] = iFOV;
			SetEntProp(iClient, Prop_Send, "m_iFOV", 15);
		}
	}

}
