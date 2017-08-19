#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <codmod301>


public Plugin:myinfo = {
	name = "Call of Duty Mod - Perk - Łut Szczęscia",
	author = "th7nder",
	description = "CODMOD's Perk",
	version = "1.0",
	url = "http://th7.eu"
};

new const String:szClassName[NAME_LENGTH] = {"Łut Szczęścia"};
new const String:szDesc[DESC_LENGTH] = {"Co rundę dostajesz losową broń i masz 1/20 na zabicie z niej."};
new g_iPerkId;

new bool:g_bHasItem[MAXPLAYERS +1] = {false};

WeaponID g_iCurrentWeapon[MAXPLAYERS+1] = {WEAPON_NONE};
public OnPluginStart()
{
	g_iPerkId = CodMod_RegisterPerk(szClassName, szDesc);
}


public OnPluginEnd()
{
	CodMod_UnregisterPerk(g_iPerkId);
}

public OnClientPutInServer(iClient)
{
	g_bHasItem[iClient] = false;
}

public CodMod_OnPerkEnabled(iClient, iPerkId)
{
	if(iPerkId != g_iPerkId)
		return;

	PrintToChat(iClient, "%s Perk zostanie aktywowany w następnej rundzie", PREFIX_INFO);
	g_iCurrentWeapon[iClient] = WEAPON_NONE;
	g_bHasItem[iClient] = true;

}


public void CodMod_OnPerkDisabled(int iClient, int iPerkId)
{
    if(iPerkId != g_iPerkId)
        return;

    g_bHasItem[iClient] = false;
}

public bool HasZeus(int iClient)
{
	int iSize = GetEntPropArraySize(iClient, Prop_Send, "m_hMyWeapons");
	char szClassname[64];
	int iEnt = -1;
	for(int i = 0; i < iSize; i++){
		if((iEnt = GetEntPropEnt(iClient, Prop_Send, "m_hMyWeapons", i)) != -1 && IsValidEntity(iEnt)){
			GetEdictClassname(iEnt, szClassname, 64);
			if(StrEqual(szClassname, "weapon_taser")){
				return true;
			}
		}
	}

	return false;
}

public void GiveRandomWeapon(int iClient)
{
	WeaponID iRandomWeapon = WEAPON_NONE;
	
	do
	{
		iRandomWeapon = view_as<WeaponID>(GetRandomInt(view_as<int>(WEAPON_GLOCK), view_as<int>(WEAPON_HEALTHSHOT)));
	} while (IsWeaponGrenade(iRandomWeapon) || iRandomWeapon == WEAPON_SG552 || iRandomWeapon == WEAPON_KNIFE || iRandomWeapon == WEAPON_C4 || iRandomWeapon == WEAPON_KNIFE_GG || iRandomWeapon == WEAPON_DEFUSER || iRandomWeapon == WEAPON_STANDARDPISTOLS);
	g_iCurrentWeapon[iClient] = iRandomWeapon;
	int iSlot = 0;
	char szClassname[64];
	Format(szClassname, sizeof(szClassname), "weapon_%s", weaponNames[iRandomWeapon]);
	if(WeaponIsPistol(iRandomWeapon))
	{
		iSlot = 1;
		int iEntity = -1;
		if((iEntity = GetPlayerWeaponSlot(iClient, iSlot)) != -1)
		{
			if(IsValidEntity(iEntity))
			{
				CS_DropWeapon(iClient, iEntity, true, false);
			}

		}

		GivePlayerItem(iClient, szClassname)
	} 
	else if(iRandomWeapon == WEAPON_TASER)
	{
		if(!HasZeus(iClient))
		{
			GivePlayerItem(iClient, szClassname);
		}
	} 
	else if(IsWeaponGrenade(iRandomWeapon))
	{
		bool bGive = false;
		switch(iRandomWeapon)
		{
			case WEAPON_HEGRENADE:
			{
				if(!CodMod_GetPlayerNades(iClient, TH7_HE))
				{
					bGive = true;
				}
			}

			case WEAPON_SMOKEGRENADE:
			{
				if(!CodMod_GetPlayerNades(iClient, TH7_SMOKE))
				{
					bGive = true;
				}
			}

			case WEAPON_FLASHBANG:
			{
				if(CodMod_GetPlayerNades(iClient, TH7_FLASHBANG) < 2)
				{
					bGive = true;
				}
			}

			case WEAPON_MOLOTOV,WEAPON_INCGRENADE:
			{
				if(!CodMod_GetPlayerNades(iClient, TH7_MOLOTOV))
				{
					bGive = true;
				}
			}

			case WEAPON_DECOY:
			{
				if(!CodMod_GetPlayerNades(iClient, TH7_DECOY))
				{
					bGive = true;
				}
			}

			case WEAPON_TAGRENADE:
			{
				if(!CodMod_GetPlayerNades(iClient, TH7_TACTICAL))
				{
					bGive = true;
				}
			}
		}
		if(bGive)
		{
			GivePlayerItem(iClient, szClassname);
		}	
	} else {
		int iEntity = -1;
		if((iEntity = GetPlayerWeaponSlot(iClient, iSlot)) != -1)
		{
			if(IsValidEntity(iEntity))
			{
				CS_DropWeapon(iClient, iEntity, true, false);
			}
		}

		GivePlayerItem(iClient, szClassname)
	}

}



public void CodMod_OnPlayerSpawn(int iClient)
{
	if(g_bHasItem[iClient])
	{
		GiveRandomWeapon(iClient);
		PrintToChat(iClient, "%s Twój łut szczęścia przyniól Ci %s!", PREFIX_INFO, weaponNames[g_iCurrentWeapon[iClient]]);
	}
}

public void CodMod_OnPlayerDamagedPerk(int iAttacker, int iVictim, float &fDamage, WeaponID iWeaponID, int iDamageType){
    if(g_bHasItem[iAttacker])
	{
    	if(iWeaponID == g_iCurrentWeapon[iAttacker] && GetRandomInt(1, 100) >= 95)
	    {
	        fDamage *= 30.0;
	    }
    }
}


public void CodMod_OnWeaponCanUsePerk(int iClient, WeaponID iWeaponID, int &iCanUse, bool bBuy){
    if(g_bHasItem[iClient] && g_iCurrentWeapon[iClient] == iWeaponID){
        iCanUse = 2;
    }
}
