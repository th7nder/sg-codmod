#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <codmod301>


public Plugin:myinfo = {
	name = "Call of Duty Mod - Perk - Trykot Formixa",
	author = "th7nder",
	description = "CODMOD's Perk",
	version = "1.0",
	url = "http://th7.eu"
};

new const String:szClassName[NAME_LENGTH] = {"Trykot Formixa"};
new const String:szDesc[DESC_LENGTH] = {"Za zabójstwo +20HP, odnowienie magazynku \n Odporny na AWP\n1/2 na 50%% redukcji obrażen ze SSG08"};
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

public Action Timer_Refill(Handle hTimer, int iSerial)
{
    int iClient = GetClientFromSerial(iSerial);
    if(iClient > 0)
    {
        Player_RefillClip(iClient, -1, 1);
    }
}


public void CodMod_OnPlayerDamagedPerk(int iAttacker, int iVictim, float &fDamage, WeaponID iWeaponID, int iDamageType){
    if(g_bHasItem[iVictim]){
        if(iWeaponID == WEAPON_AWP) {
            fDamage = 0.0;
        } else if (iWeaponID == WEAPON_SSG08) {
            if(GetRandomInt(0,1) == 0) {
                fDamage *= 0.5;
            }
        }
    }
}




public void CodMod_OnPlayerDie(int iAttacker, int iVictim, bool bHeadshot){
    if(g_bHasItem[iAttacker]){
        CreateTimer(0.00, Timer_Refill, GetClientSerial(iAttacker));
        CodMod_Heal(iAttacker, iAttacker, 20);
    }
}

