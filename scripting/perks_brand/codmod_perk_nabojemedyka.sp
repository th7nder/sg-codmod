#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <codmod301>








public Plugin:myinfo = {
	name = "Call of Duty Mod - Perk - Naboje Medyka",
	author = "th7nder",
	description = "CODMOD's Perk",
	version = "1.0",
	url = "http://th7.eu"
};

new const String:szClassName[NAME_LENGTH] = {"Naboje Medyka"};
new const String:szDesc[DESC_LENGTH] = {"Gdy strzelasz do swoich leczysz ich o 3HP. +3dmg do wszystkich broni."};
int g_iPerkId;

bool g_bHasItem[MAXPLAYERS +1] = {false};


public void OnPluginStart()
{
	g_iPerkId = CodMod_RegisterPerk(szClassName, szDesc);
}


public void OnPluginEnd()
{
	CodMod_UnregisterPerk(g_iPerkId);
}

public void OnClientPutInServer(int iClient)
{
	g_bHasItem[iClient] = false;
    SDKHook(iClient, SDKHook_OnTakeDamage, SDK_OnTakeDamage);
}

public void OnClientDisconnect(int iClient)
{
    SDKUnhook(iClient, SDKHook_OnTakeDamage, SDK_OnTakeDamage);
}

public void CodMod_OnPerkEnabled(iClient, iPerkId)
{
	if(iPerkId != g_iPerkId)
		return;

	g_bHasItem[iClient] = true;

}


public void CodMod_OnPerkDisabled(int iClient, int iPerkId)
{
    if(iPerkId != g_iPerkId)
        return;


    g_bHasItem[iClient] = false;
}



public void CodMod_OnPlayerDamaged(int iAttacker, int iVictim, float &fDamage, WeaponID iWeaponID, int iDamageType){
    if(g_bHasItem[iAttacker]){
        fDamage += 3.0;
    }
}


public Action SDK_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &iWeapon, const float fDamageForce[3], const float fDamagePosition[3])
{
    if(attacker != 0 && attacker < MAXPLAYERS && GetClientTeam(attacker) == GetClientTeam(victim) && g_bHasItem[attacker])
    {
        CodMod_Heal(attacker, victim, 3);
    }

    return Plugin_Continue;
}
