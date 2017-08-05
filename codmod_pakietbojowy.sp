#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <codmod301>
#include "include/emitsoundany.inc"
#define CHAT_PREFIX_SG "  \x06[\x0BSerwery\x01-\x07GO\x06]\x0A"

public Plugin:myinfo = {
    name = "Call of Duty Mod - Pakiet Bojowy",
    author = "th7nder",
    description = "CODMOD's Pakiet Bojowy",
    version = "2.0",
    url = "http://th7.eu"
};


int g_iDeadCounter[MAXPLAYERS + 1] = {false};
bool g_bActivatedBonuses[MAXPLAYERS + 1]  = {false};

public void OnClientPutInServer(iClient){
    g_iDeadCounter[iClient] = 0;
    g_bActivatedBonuses[iClient] = false;
}

public void CodMod_OnPlayerDie(int iAttacker, int iVictim, bool bHeadshot){
    g_iDeadCounter[iAttacker] = 0;
    g_iDeadCounter[iVictim]++;

    if(g_bActivatedBonuses[iVictim]){
        g_bActivatedBonuses[iVictim] = false;
        CodMod_SetStat(iVictim, DEX_PERK, CodMod_GetStat(iVictim, DEX_PERK) - 20);
        CodMod_SetStat(iVictim, HP_PERK, CodMod_GetStat(iVictim, HP_PERK) - 50);
        CodMod_SetStat(iVictim, ARMOR_PERK, CodMod_GetStat(iVictim, ARMOR_PERK) - 15);
        PrintToChat(iVictim, "%sTwój pakiet bojowy uległ zniszczeniu!", CHAT_PREFIX_SG);
    }
}



public void CodMod_OnPlayerSpawn(int iClient){
    if(g_bActivatedBonuses[iClient]){
        g_bActivatedBonuses[iClient] = false;
        PrintToChat(iClient, "%sTwój pakiet bojowy uległ zniszczeniu!", CHAT_PREFIX_SG);
        CodMod_SetStat(iClient, DEX_PERK, CodMod_GetStat(iClient, DEX_PERK) - 20);
        CodMod_SetStat(iClient, ARMOR_PERK, CodMod_GetStat(iClient, ARMOR_PERK) - 15);
        CodMod_SetStat(iClient, HP_PERK, CodMod_GetStat(iClient, HP_PERK) - 50);
    }

    if(g_iDeadCounter[iClient] >= 4){
        g_iDeadCounter[iClient] = 0;
        g_bActivatedBonuses[iClient] = true;
        PrintToChat(iClient, "%sOtrzymałeś pakiet bojowy! dodatkowe 100HP, 20 Kondycji oraz 15 Wytrzymałości na tą rundę!", CHAT_PREFIX_SG);
        CodMod_SetStat(iClient, DEX_PERK, CodMod_GetStat(iClient, DEX_PERK) + 20);
        CodMod_SetStat(iClient, ARMOR_PERK, CodMod_GetStat(iClient, ARMOR_PERK) + 15);
        CodMod_SetStat(iClient, HP_PERK, CodMod_GetStat(iClient, HP_PERK) + 50);

        CodMod_Heal(iClient, iClient, 999);
    }
}
