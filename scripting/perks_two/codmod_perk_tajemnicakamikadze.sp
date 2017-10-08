#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>



public Plugin myinfo = {
    name = "Call of Duty Mod - Perk - Tajemnica Kamikadze",
    author = "th7nder",
    description = "201 Rewrite Perk",
    version = "2.0",
    url = "http://th7.eu"
};

char szClassName[] = {"Tajemnica Kamikadze"};
char szDesc[] = {"Po użyciu codmod_perk stajesz się nieśmiertelny, \n dostajesz 60 szybkości i po 3 sekundach wybuchasz \n zadając 300dmg w promieniu 200u"};
int g_iPerkId;


bool g_bHasItem[MAXPLAYERS +1] = {false};

#include <codmod301>
bool g_bUsed[MAXPLAYERS+1] = {false};
bool g_bUsing[MAXPLAYERS+1] = {false};


public void OnPluginStart(){
    g_iPerkId = CodMod_RegisterPerk(szClassName, szDesc);
    HookEvent("player_hurt", OnPlayerHurt, EventHookMode_Pre);
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

    if(g_bUsing[iClient]){
        g_bUsing[iClient] = false;
        CodMod_SetStat(iClient, DEX_PERK, CodMod_GetStat(iClient, DEX_PERK) - 60);
    }

    g_bUsed[iClient] = false;
    g_bUsing[iClient] = false;
}

public void CodMod_OnPerkDisabled(int iClient, int iPerkId){
    if(iPerkId != g_iPerkId)
        return;

    g_bHasItem[iClient] = false;
}

public void CodMod_OnPlayerSpawn(int iClient){
    if(g_bHasItem[iClient]){


        if(g_bUsing[iClient]){
            g_bUsing[iClient] = false;
            CodMod_SetStat(iClient, DEX_PERK, CodMod_GetStat(iClient, DEX_PERK) - 60);
        }

        g_bUsed[iClient] = false;
        g_bUsing[iClient] = false;
    }
}

public void CodMod_OnPerkSkillUsed(int iClient){
    if(!g_bHasItem[iClient] || !IsPlayerAlive(iClient))
        return;

    if(g_bUsed[iClient]){
        PrintToChat(iClient, "%s Użyłeś już przedmiotu w tej rundzie!", PREFIX_SKILL);
        return;
    }

    SetEntPropFloat(iClient, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
    SetEntProp(iClient, Prop_Send, "m_iProgressBarDuration", 3);

    PrintToChat(iClient, "%s Masz 3 sekundy na dobiegnięcie do przeciwnika!", PREFIX_SKILL);
    g_bUsed[iClient] = true;
    g_bUsing[iClient] = true;
    CodMod_SetStat(iClient, DEX_PERK, CodMod_GetStat(iClient, DEX_PERK) + 60);

    CreateTimer(3.0, Timer_DisableFeatures, GetClientSerial(iClient));
}

public Action Timer_DisableFeatures(Handle hTimer, int iClient){
    iClient = GetClientFromSerial(iClient);
    if(!IsValidPlayer(iClient)){
        return Plugin_Stop;
    }

    if(g_bUsing[iClient]){
        g_bUsing[iClient] = false;
        CodMod_SetStat(iClient, DEX_PERK, CodMod_GetStat(iClient, DEX_PERK) - 60);
        SetEntProp(iClient, Prop_Send, "m_iProgressBarDuration", 0);
        if(IsPlayerAlive(iClient)){
            CodMod_PerformEntityExplosion(iClient, iClient, 300.0, 200, 0.0, TH7_DMG_EXPLODE);
            ForcePlayerSuicide(iClient);
            CS_SetClientContributionScore(iClient, CS_GetClientContributionScore(iClient) + 2);
        }
    }

    return Plugin_Stop;
}


public void CodMod_OnTH7DmgPost(int iVictim, int iAttacker, float &fDamage, int iTH7Dmg){
    if(g_bUsing[iVictim]){
        fDamage = 0.0;
    }
}

public void CodMod_OnPlayerDamagedPerk(int iAttacker, int iVictim, float &fDamage, WeaponID iWeaponID, int iDamageType){
    if(g_bUsing[iVictim]){
        fDamage *= 0.0;
    }

}

public Action OnPlayerHurt(Event hEvent, const char[] sName, bool bDontBroadcast)
{
    int iVictimId = hEvent.GetInt("userid");
    int iVictim = GetClientOfUserId(iVictimId);

    if(g_bHasItem[iVictim])
        SetEntPropFloat(iVictim, Prop_Send, "m_flVelocityModifier", 1.0);

    return Plugin_Continue;
}
