#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <codmod301>


public Plugin myinfo = {
    name = "Call of Duty Mod - Perk - Fart Strzelca",
    author = "th7nder",
    description = "201 Rewrite Perk",
    version = "2.0",
    url = "http://th7.eu"
};

char szClassName[] = {"Fart Strzelca"};
char szDesc[] = {"1/5 na natychmiastowe zabicie z Glocka/P2000/USP"};
int g_iPerkId;


bool g_bHasItem[MAXPLAYERS +1] = {false};


public void OnPluginStart(){
    g_iPerkId = CodMod_RegisterPerk(szClassName, szDesc);
}

public void OnPluginEnd(){
    CodMod_UnregisterPerk(g_iPerkId);
}

public void OnClientPutInServer(int iClient){
    g_bHasItem[iClient] = false;
}

public void CodMod_OnPerkEnabled(int iClient, int iPerkId){
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
        if((iWeaponID == WEAPON_USP || iWeaponID == WEAPON_GLOCK || iWeaponID == WEAPON_HKP2000) && GetRandomInt(1, 100) >= 80){
            fDamage *= 300.0;
        }
    }
}


const WeaponID g_iGiveWeapon = WEAPON_GLOCK;
char g_szGiveWeapon[] = "weapon_glock";
const WeaponID g_iGiveSecondWeapon = WEAPON_USP;
char g_szGiveSecondWeapon[] = "weapon_usp_silencer";

const int g_iWeaponSlot = 1;

public void CodMod_OnPlayerSpawn(int iClient){
    if(g_bHasItem[iClient]){
            int iEntity = GetPlayerWeaponSlot(iClient, g_iWeaponSlot);
            bool bGive = true;
            if(iEntity != -1){
                bGive = false;
                WeaponID iWeaponID = CodMod_GetWeaponID(iEntity);
                if(iWeaponID != g_iGiveWeapon && iWeaponID != g_iGiveSecondWeapon){
                    RemovePlayerItem(iClient, iEntity);
                    bGive = true;
                }


            }

            if(bGive){ 
                if(GetClientTeam(iClient) == CS_TEAM_T){
                    iEntity = GivePlayerItem(iClient, g_szGiveWeapon);
                } else {
                    iEntity = GivePlayerItem(iClient, g_szGiveSecondWeapon);
                }

                EquipPlayerWeapon(iClient, iEntity);
            }




    }
}

public void CodMod_OnWeaponCanUsePerk(int iClient, WeaponID iWeaponID, int &iCanUse, bool bBuy){
    if(g_bHasItem[iClient] && (g_iGiveWeapon == iWeaponID || g_iGiveSecondWeapon == iWeaponID) && !bBuy){
        iCanUse = 2;
    }
}
