#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <codmod301>


public Plugin myinfo = {
    name = "Call of Duty Mod - Perk - Tajemnica Generała",
    author = "th7nder",
    description = "201 Rewrite Perk",
    version = "2.0",
    url = "http://th7.eu"
};

char szClassName[] = {"Tajemnica Generała 2"};
char szDesc[] = {"Dostajesz HE, który zadaje 100dmg +1/1INT, 2x większy zasięg oraz zamraża na 5sec."};
int g_iPerkId;


bool g_bHasItem[MAXPLAYERS +1] = {false};
int g_iRoundCounter = 0;

public void OnPluginStart(){
    g_iPerkId = CodMod_RegisterPerk(szClassName, szDesc);
    HookEvent("round_start", Event_OnRoundStart);
}

public void OnMapStart(){
    g_iRoundCounter = 0;
}

public Action Event_OnRoundStart(Event hEvent, const char[] szEvent, bool bBroadcast){
    g_iRoundCounter++;
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


public void CodMod_OnPlayerSpawn(int iClient){
    if(g_bHasItem[iClient]){
        if(!CodMod_GetPlayerNades(iClient, TH7_HE)){
            GivePlayerItem(iClient, "weapon_hegrenade");
        }
    }
}

public void CodMod_OnPlayerDamagedPerk(int iAttacker, int iVictim, float &fDamage, WeaponID iWeaponID, int iDamageType){
    if(g_bHasItem[iAttacker]){
        if(iWeaponID == WEAPON_HEGRENADE){
            fDamage = 100.0 + float(CodMod_GetWholeStat(iAttacker, INT));

            if(GetEntityMoveType(iVictim) != MOVETYPE_NONE){
                SetEntityMoveType(iVictim, MOVETYPE_NONE);
                Handle hPack = CreateDataPack();
                WritePackCell(hPack, GetClientSerial(iVictim));
                WritePackCell(hPack, g_iRoundCounter);
                CreateTimer(5.0, Timer_Unfreeze, hPack);
                PrintToChat(iVictim, "%s Zostałeś zamrożony przez %N na 5 sec!", PREFIX_SKILL, iAttacker);
                PrintToChat(iAttacker, "%s Zamroziłeś %N na 5 sec!", PREFIX_SKILL, iVictim);
            }
        }
    }
}

public Action Timer_Unfreeze(Handle hTimer, Handle hPack){
    ResetPack(hPack);
    int iVictim = GetClientFromSerial(ReadPackCell(hPack));
    int iRoundCounter = ReadPackCell(hPack);
    delete hPack;
    if(iRoundCounter != g_iRoundCounter){
        return Plugin_Stop;
    }

    if(!IsValidPlayer(iVictim) || !IsPlayerAlive(iVictim)){
        return Plugin_Stop;
    }

    SetEntityMoveType(iVictim, MOVETYPE_WALK);
    return Plugin_Stop;
}

public void OnEntityCreated(int iEntity, const char[] szClassname){
	if(StrEqual(szClassname, "hegrenade_projectile")){
		SDKHook(iEntity, SDKHook_SpawnPost, SDK_OnHESpawn);
	}
}

public Action SDK_OnHESpawn(int iEntity){
    int iOwner = GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity");
    if(IsValidPlayer(iOwner) && g_bHasItem[iOwner]){
        SetEntPropFloat(iEntity, Prop_Send, "m_DmgRadius", GetEntPropFloat(iEntity, Prop_Send, "m_DmgRadius") * 2.0);
    }
    return Plugin_Continue;
}
