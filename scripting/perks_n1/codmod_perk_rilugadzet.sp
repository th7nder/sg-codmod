#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <codmod301>


public Plugin myinfo = {
    name = "Call of Duty Mod - Perk - RiluGadzet",
    author = "th7nder",
    description = "201 Rewrite Perk",
    version = "2.0",
    url = "http://th7.eu"
};

char szClassName[] = {"RiluGadzet"};
char szDesc[] = {"AK47(+5dmg), Molotov(2x dmg) \n1/12 na spowolnienie gracza o 40% z AK \nZamiana z miejscami na codmod_perk"};
int g_iPerkId;


bool g_bHasItem[MAXPLAYERS +1] = {false};
bool g_bSlow[MAXPLAYERS+1] = {false};

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

const WeaponID g_iGiveWeapon = WEAPON_AK47;
char g_szGiveWeapon[] = "weapon_ak47";
const int g_iWeaponSlot = 0;
public void CodMod_OnPlayerSpawn(int iClient){
    if(g_bHasItem[iClient]){
        g_bSlow[iClient] = false;
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
        if(iWeaponID == WEAPON_AK47){
            fDamage += 5.0;
            if(!g_bSlow[iVictim] && GetRandomInt(1, 100) >= 83)
            {
                PrintToChat(iVictim, "%s Zostałeś spowolniony!", PREFIX_SKILL);
                PrintToChat(iAttacker, "%s Spowolniłeś %N!", PREFIX_SKILL, iVictim);
                g_bSlow[iVictim] = true;
                Handle hPack = CreateDataPack();
                CodMod_ChangeStat(iVictim, DEX_PERK, -40);
                WritePackCell(hPack, GetClientSerial(iVictim));
                WritePackCell(hPack, CodMod_GetRoundIndex());
                CreateTimer(2.0, Timer_Unslow, hPack);

            }
        }
    }
}

public Action Timer_Unslow(Handle hTimer, Handle hPack)
{
        ResetPack(hPack);
        int iSerial = ReadPackCell(hPack);
        int iRoundIndex = ReadPackCell(hPack);
        delete hPack;
        int iClient = GetClientFromSerial(iSerial);
        if(!IsValidPlayer(iClient)) return Plugin_Stop;

        if(IsPlayerAlive(iClient))
        {
                if(CodMod_GetRoundIndex() == iRoundIndex)
                {
                        g_bSlow[iClient] = false;
                        PrintToChat(iClient, "%s Poruszasz sie juz normalnie", PREFIX_SKILL);
                }       

                CodMod_ChangeStat(iClient, DEX_PERK, 40);
        }

        return Plugin_Stop;
}
