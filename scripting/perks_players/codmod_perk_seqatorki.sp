#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <codmod301>


public Plugin myinfo = {
    name = "Call of Duty Mod - Perk - Seqatorki",
    author = "th7nder",
    description = "201 Rewrite Perk",
    version = "2.0",
    url = "http://th7.eu"
};

char szClassName[] = {"Seqatorki"};
char szDesc[] = {"Dostajesz 40 kondycji, 20 witalności, Dual Elite + 10dmg do nich"};
int g_iPerkId;


bool g_bHasItem[MAXPLAYERS +1] = {false};

public void OnLibraryAdded(const char[] name)
{
    if (StrEqual(name, "codmod301"))
    {
        g_iPerkId = CodMod_RegisterPerk(szClassName, szDesc);
    }
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
    CodMod_ChangeStat(iClient, HP_PERK, 20);
    CodMod_ChangeStat(iClient, DEX_PERK, 40);
}

public void CodMod_OnPerkDisabled(int iClient, int iPerkId){
    if(iPerkId != g_iPerkId)
        return;

    g_bHasItem[iClient] = false;
    CodMod_ChangeStat(iClient, HP_PERK, -20);
    CodMod_ChangeStat(iClient, DEX_PERK, -40);
}

const WeaponID g_iGiveWeapon = WEAPON_ELITE;
char g_szGiveWeapon[] = "weapon_elite";
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


public void CodMod_OnPlayerDamagedPerk(int iAttacker, int iVictim, float &fDamage, WeaponID iWeaponID, int iDamageType){
    if(g_bHasItem[iAttacker]){
        if(iWeaponID == g_iGiveWeapon){
            fDamage += 10.0;
        }
    }
}
