#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <codmod301>


public Plugin myinfo = {
	name = "Call of Duty Mod - Perk - Lucky Luke",
	author = "th7nder",
	description = "CODMOD's Perk",
	version = "1.0",
	url = "http://th7.eu"
};

char szClassName[] = {"Lucky Luke"};
char szDesc[] = {"Posiadasz R8 Revolver i 1/4 na zabójstwo z niego."};
int g_iPerkId;


bool g_bHasItem[MAXPLAYERS +1] = {false};


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



const WeaponID g_iGiveWeapon = WEAPON_REVOLVER;
char g_szGiveWeapon[] = "weapon_revolver";
const int g_iWeaponSlot = 1;
public void CodMod_OnPlayerSpawn(int iClient){
    if(g_bHasItem[iClient]){
        int iEntity = GetPlayerWeaponSlot(iClient, g_iWeaponSlot);
        if(iEntity != -1){
            WeaponID iWeaponID = CodMod_GetWeaponID(iEntity);
            if(iWeaponID != g_iGiveWeapon){
                RemovePlayerItem(iClient, iEntity);
                iEntity = GivePlayerItem(iClient, g_szGiveWeapon);
                EquipPlayerWeapon(iClient, iEntity);
            }
        } else if(iEntity == -1){
            iEntity = GivePlayerItem(iClient, g_szGiveWeapon);
            EquipPlayerWeapon(iClient, iEntity);
        }

    }
}

public void CodMod_OnWeaponCanUsePerk(int iClient, WeaponID iWeaponID, int &iCanUse, bool bBuy){
    if(g_bHasItem[iClient] && g_iGiveWeapon == iWeaponID && !bBuy){
        iCanUse = 2;
    }
}

public void CodMod_OnPlayerDamaged(int iAttacker, int iVictim, float &fDamage, WeaponID iWeaponID, int iDamageType){
    if(g_bHasItem[iAttacker]){
        if(GetRandomInt(1, 100) >= 75 && iWeaponID == g_iGiveWeapon){
            fDamage *= 300.0;
        }
    }
}
