#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>




#define ON_FIRE 1
bool g_bOnFire[MAXPLAYERS+1] = {false};

#include <codmod301>
public Plugin myinfo = {
    name = "Call of Duty Mod - Perk - Left4Deft",
    author = "th7nder",
    description = "201 Rewrite Perk",
    version = "2.0",
    url = "http://th7.eu"
};

char szClassName[] = {"Left4Deft"};
char szDesc[] = {"M4A1-S(+10dmg) na początku rundy \n \
                Refill ammo za zabójstwo \n\ 
                1/12 na podpalenie, 3s co 1sec 10dmg"};
int g_iPerkId;


bool g_bHasItem[MAXPLAYERS +1] = {false};

int g_iBeamColor[] = {255, 265, 0, 255};


int g_iBeamSprite = -1;
int g_iHaloSprite = -1;


public void OnPluginStart(){
    g_iPerkId = CodMod_RegisterPerk(szClassName, szDesc);
}

public void OnMapStart()
{
    g_iBeamSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
    g_iHaloSprite = PrecacheModel("materials/sprites/halo.vmt");
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

const WeaponID g_iGiveWeapon = WEAPON_M4A1;
char g_szGiveWeapon[] = "weapon_m4a1_silencer";
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

        if(g_bHasItem[iAttacker] && !g_bOnFire[iVictim] && GetRandomInt(1, 100) >= 93){
            g_bOnFire[iVictim] = true;
            PrintToChat(iAttacker, "%s Podpaliłeś gracza!", PREFIX_SKILL);
            PrintToChat(iVictim, "%s Zostałeś podpalony!", PREFIX_SKILL);
            CodMod_Burn(iAttacker, iVictim, 3.0, 1.0, 10.0);

            float fPosition[3], fTargetPosition[3];
            GetClientEyePosition(iAttacker, fPosition);
            GetClientEyePosition(iVictim, fTargetPosition);
            fPosition[2] -= 10.0;
            fTargetPosition[2] -= 10.0;
            TE_SetupBeamPoints(fPosition, fTargetPosition, g_iBeamSprite, g_iHaloSprite, 0, 66, 1.0, 1.0, 20.0, 1, 0.0, g_iBeamColor, 5);
            TE_SendToAll();
        }
    }
}


public Action Timer_Refill(Handle hTimer, int iSerial)
{
    int iClient = GetClientFromSerial(iSerial);
    if(iClient > 0)
    {
        Player_RefillClip(iClient, -1, 1);
    }
}


public void CodMod_OnPlayerDie(int iAttacker, int iVictim, bool bHeadshot){
    if(g_bHasItem[iAttacker]){
        CreateTimer(0.00, Timer_Refill, GetClientSerial(iAttacker));
    }
}
