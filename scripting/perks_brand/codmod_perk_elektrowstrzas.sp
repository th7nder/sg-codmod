#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>

#include <codmod301>

public Plugin:myinfo = {
	name = "Call of Duty Mod - Perk - Elektrowstrząs",
	author = "th7nder",
	description = "CODMOD's Perk",
	version = "1.0",
	url = "http://th7.eu"
};

new const String:szClassName[NAME_LENGTH] = {"Elektrowstrząs"};
new const String:szDesc[DESC_LENGTH] = {"Masz 1/12 na potrząśnięcie ekranem przeciwnika."};
new g_iPerkId;


new bool:g_bHasItem[MAXPLAYERS +1] = {false};

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


public void CodMod_OnPerkDisabled(int iClient, int iPerkId){
    if(iPerkId != g_iPerkId)
        return;

    g_bHasItem[iClient] = false;
}




public void CodMod_OnPlayerDamagedPerk(int iAttacker, int iVictim, float &fDamage, WeaponID iWeaponID, int iDamageType){
    if(g_bHasItem[iAttacker]){
        if(GetRandomInt(1, 1000) >= 930)
        {
            Shake(iVictim, 20.0);
        }
    }
}


stock void Shake(int iClient, float fAmp=1.0) {
  new Handle:hMessage = StartMessageOne("Shake", iClient, 1);
  PbSetInt(hMessage, "command", 0);
  PbSetFloat(hMessage, "local_amplitude", fAmp);
  PbSetFloat(hMessage, "frequency", 100.0);
  PbSetFloat(hMessage, "duration", 1.5);
  EndMessage();
}