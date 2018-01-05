//Tajemnica Deft'a - Galil (+10 DMG), pod codmod_perk leczy się o 50HP+5HP przez 5s co sekunde raz na runde i double jump
#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <codmod301>


const int AMOUNT_HEAL = 5;
const int AMOUNT_HEAL_REPEAT = 5;
const float HEAL_INTERVAL = 1.0;
const int MAX_HEALING_TIMES = 1;

public Plugin myinfo = {
    name = "Call of Duty Mod - Perk - Tajemnica Defta",
    author = "th7nder",
    description = "201 Rewrite Perk",
    version = "2.0",
    url = "http://th7.eu"
};

char szClassName[] = {"Tajemnica Defta"};
char szDesc[] = {"Dostajesz Galila(+10dmg)\nPodwójny skok\ncodmod_perk leczy o 50HP oraz 5hp/1s przez 5 s\ncodmod_perk raz na rundę"};
int g_iPerkId;


bool g_bHasItem[MAXPLAYERS +1] = {false};

bool g_bHealing[MAXPLAYERS+1] = {false};
int g_iUsed[MAXPLAYERS+1] = {0};


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
        CodMod_SetPlayerInfo(iClient, DOUBLE_JUMP_PERK, 1);

        g_bHealing[iClient] = false;
        g_iUsed[iClient] = 0;
}

public void CodMod_OnPerkDisabled(int iClient, int iPerkId){
        if(iPerkId != g_iPerkId)
                return;

        CodMod_SetPlayerInfo(iClient, DOUBLE_JUMP_PERK, 0);
}

const WeaponID g_iGiveWeapon = WEAPON_GALILAR;
char g_szGiveWeapon[] = "weapon_galilar";
const int g_iWeaponSlot = 0;
public void CodMod_OnPlayerSpawn(int iClient){
    if(g_bHasItem[iClient]){
        g_bHealing[iClient] = false;
        g_iUsed[iClient] = 0;
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




public void CodMod_OnPerkSkillUsed(int iClient){
    if(!g_bHasItem[iClient] || !IsPlayerAlive(iClient))
        return;

    if(g_iUsed[iClient] + 1 > MAX_HEALING_TIMES)
    {
        PrintToChat(iClient, "%s Nie możesz użyć leczenia więcej niż %d raz na runde!", PREFIX_SKILL, MAX_HEALING_TIMES);
        return;
    }
    if(g_bHealing[iClient]){
        PrintToChat(iClient, "%s Jesteś w trakcie leczenia!", PREFIX_SKILL);
        return;
    }


    CodMod_Heal(iClient, iClient, 50);
    PrintToChat(iClient, "%s Rozpocząłeś leczenie!", PREFIX_SKILL);
    g_bHealing[iClient] = true;
    g_iUsed[iClient] += 1;
    Handle hPack = CreateDataPack();
    WritePackCell(hPack, GetClientSerial(iClient));
    WritePackCell(hPack, CodMod_GetRoundIndex());
    WritePackCell(hPack, AMOUNT_HEAL_REPEAT);

    CreateTimer(HEAL_INTERVAL, Timer_Healing, hPack);

    SetEntPropFloat(iClient, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
    SetEntProp(iClient, Prop_Send, "m_iProgressBarDuration", AMOUNT_HEAL_REPEAT);
}


public Action Timer_Healing(Handle hTimer, Handle hPack){
    ResetPack(hPack);
    int iSerial = ReadPackCell(hPack);
    int iRoundIndex = ReadPackCell(hPack);
    int iTimesExecuted = ReadPackCell(hPack);
    delete hPack;

    int iClient = GetClientFromSerial(iSerial)
    if(!IsValidPlayer(iClient) || !g_bHasItem[iClient] || iRoundIndex != CodMod_GetRoundIndex() || iTimesExecuted <= 0){

        if(GetEntProp(iClient, Prop_Send, "m_iProgressBarDuration") == AMOUNT_HEAL_REPEAT){
            SetEntPropFloat(iClient, Prop_Send, "m_flProgressBarStartTime", 0.0);
            SetEntProp(iClient, Prop_Send, "m_iProgressBarDuration", 0);
        }

        return Plugin_Stop;
    }



    CodMod_Heal(iClient, iClient, AMOUNT_HEAL);
    iTimesExecuted--;

    hPack = CreateDataPack();
    WritePackCell(hPack, GetClientSerial(iClient));
    WritePackCell(hPack, CodMod_GetRoundIndex());
    WritePackCell(hPack, iTimesExecuted);

    CreateTimer(HEAL_INTERVAL, Timer_Healing, hPack);

    return Plugin_Stop;
}
