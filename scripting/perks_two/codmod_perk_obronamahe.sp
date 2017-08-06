#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>


#define SANDBAGS 1
int g_iSandbagOwners[2048] = {0};
#include <codmod301>


public Plugin myinfo = {
    name = "Call of Duty Mod - Perk - Obrona Mahesvary",
    author = "th7nder",
    description = "201 Rewrite Perk",
    version = "2.0",
    url = "http://th7.eu"
};

char szClassName[] = {"Obrona Mahesvary"};
char szDesc[] = {"Dostajesz M249 i zadajesz +8 wiecej obrażeń, posiadasz 2 worki, +30 wytrzymałości"};
int g_iPerkId;


bool g_bHasItem[MAXPLAYERS +1] = {false};

int g_iSandbags[MAXPLAYERS+1] = {0};
float g_fLastUse[MAXPLAYERS+1] = {0.0};


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
    CodMod_SetStat(iClient, ARMOR_PERK, CodMod_GetStat(iClient, ARMOR_PERK) + 30);
}

public void CodMod_OnPerkDisabled(int iClient, int iPerkId){
    if(iPerkId != g_iPerkId)
        return;

    g_bHasItem[iClient] = false;
    CodMod_SetStat(iClient, ARMOR_PERK, CodMod_GetStat(iClient, ARMOR_PERK) - 30);
}

public void CodMod_OnPlayerDamaged(int iAttacker, int iVictim, float &fDamage, WeaponID iWeaponID, int iDamageType){
    if(g_bHasItem[iAttacker]){
        fDamage += 8.0;
    }
}

const WeaponID g_iGiveWeapon = WEAPON_M249;
char g_szGiveWeapon[] = "weapon_m249";
const int g_iWeaponSlot = 0;
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
        g_iSandbags[iClient] = 0;
    }
}

public void CodMod_OnPerkSkillUsed(int iClient){
    if(!g_bHasItem[iClient] || !IsPlayerAlive(iClient))
        return;

    if(GetGameTime() - g_fLastUse[iClient] < 2.0){
        PrintToChat(iClient, "%s Worki można używać co 2 sekundy!", PREFIX_SKILL);
        return;
    }
    int iMaxSandbags = 2;
    if(g_iSandbags[iClient] + 1 <= iMaxSandbags){
        g_fLastUse[iClient] = GetGameTime();
        g_iSandbags[iClient]++;
        PrintToChat(iClient, "%s Postawiłeś worek! Zostały Ci %d worki", PREFIX_SKILL, iMaxSandbags - g_iSandbags[iClient]);
        Player_PlaceSandbag(iClient);
    } else {
        PrintToChat(iClient, "%s Wykorzystałeś już %d worków tej rundzie!", PREFIX_SKILL, iMaxSandbags)
    }
}

public void CodMod_OnWeaponCanUsePerk(int iClient, WeaponID iWeaponID, int &iCanUse, bool bBuy){
    if(g_bHasItem[iClient] && g_iGiveWeapon == iWeaponID && !bBuy){
        iCanUse = 2;
    }
}