#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <codmod301>


public Plugin:myinfo = {
	name = "Call of Duty Mod - Perk - Tajemnica Medyka",
	author = "th7nder",
	description = "CODMOD's Perk",
	version = "1.0",
	url = "http://th7.eu"
};

new const String:szClassName[NAME_LENGTH] = {"Tajemnica Medyka"};
new const String:szDesc[DESC_LENGTH] = {"Zmieniając broń na nóż, możesz wskrzesić 3 osoby na rundę."};
new g_iPerkId;


int g_iRessurected[MAXPLAYERS+1] = {0};
Handle g_hSkillTimers[MAXPLAYERS+1] = {INVALID_HANDLE};

new bool:g_bHasItem[MAXPLAYERS +1] = {false};
public OnPluginStart(){
	g_iPerkId = CodMod_RegisterPerk(szClassName, szDesc);
}

public OnPluginEnd(){
	CodMod_UnregisterPerk(g_iPerkId);
}



public CodMod_OnPerkEnabled(iClient, iPerkId){
	if(iPerkId != g_iPerkId)
		return;

	g_bHasItem[iClient] = true;
    g_iRessurected[iClient] = 0;
    KillSkillTimer(iClient);
}

public void CodMod_OnPlayerSpawn(int iClient){
    if(g_bHasItem[iClient]){
        g_iRessurected[iClient] = 0;
    }
}


public CodMod_OnPerkDisabled(iClient, iPerkId){
	if(iPerkId != g_iPerkId)
		return;

	g_bHasItem[iClient] = false;
    KillSkillTimer(iClient);

}

public void KillSkillTimer(int iClient){
    if(g_hSkillTimers[iClient] != INVALID_HANDLE){
        KillTimer(g_hSkillTimers[iClient]);
        g_hSkillTimers[iClient] = INVALID_HANDLE;
    }


    if(IsClientInGame(iClient) && IsPlayerAlive(iClient)){
        SetEntProp(iClient, Prop_Send, "m_iProgressBarDuration", 0);
    }
}

public void OnClientDisconnect(int iClient){
    KillSkillTimer(iClient);
    SDKUnhook(iClient, SDKHook_WeaponSwitch, SDK_OnWeaponSwitch);
}

public void OnClientPutInServer(int iClient){
    g_bHasItem[iClient] = false;
    KillSkillTimer(iClient);
    SDKHook(iClient, SDKHook_WeaponSwitch, SDK_OnWeaponSwitch);
}

public Action SDK_OnWeaponSwitch(int iClient, int iWeapon){
	if(g_bHasItem[iClient] && IsPlayerAlive(iClient) && g_iRessurected[iClient] + 1 <= 3){
		if(CodMod_GetWeaponID(iWeapon) != WEAPON_KNIFE){
			SetEntProp(iClient, Prop_Send, "m_iProgressBarDuration", 0);
			KillSkillTimer(iClient);
		} else {
			StartSkillTimer(iClient);
		}
	}
	return Plugin_Continue;
}

public void StartSkillTimer(int iClient){
    float fPos[3];
    GetClientAbsOrigin(iClient, fPos);
    int iTarget = FindClosestRagdoll(fPos, GetClientTeam(iClient), iClient);
    if(IsValidPlayer(iTarget)){
        SetEntPropFloat(iClient, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
        SetEntProp(iClient, Prop_Send, "m_iProgressBarDuration", 3);

        Handle hPack = CreateDataPack();
        WritePackCell(hPack, GetClientSerial(iClient));
        WritePackCell(hPack, GetClientSerial(iTarget));
        g_hSkillTimers[iClient] = CreateTimer(3.0, Timer_Resurrect, hPack);
    }
}

public Action Timer_Resurrect(Handle hTimer, Handle hPack){
    ResetPack(hPack);
    int iClient = GetClientFromSerial(ReadPackCell(hPack));
    int iTarget = GetClientFromSerial(ReadPackCell(hPack));
    delete hPack;

    if(!IsValidPlayer(iClient) || !IsValidPlayer(iTarget) || IsPlayerAlive(iTarget) || !IsPlayerAlive(iClient)){
        g_hSkillTimers[iClient] = INVALID_HANDLE;
        KillSkillTimer(iClient);
        return Plugin_Stop;
    }

    int iRagdoll = GetEntPropEnt(iTarget, Prop_Send, "m_hRagdoll");
    if(iRagdoll == -1 || !IsValidEntity(iRagdoll)){
        g_hSkillTimers[iClient] = INVALID_HANDLE;
        KillSkillTimer(iClient);
        return Plugin_Stop;
    }

    float fPos[3];
    GetEntPropVector(iRagdoll, Prop_Data, "m_vecOrigin", fPos);
    CS_RespawnPlayer(iTarget);
    RemoveEdict(iRagdoll);
    fPos[2] += 3.0;
    if(IsValidPlayerPosEx(iTarget, fPos) != 0){
      TeleportEntity(iTarget, fPos, NULL_VECTOR, NULL_VECTOR);
    }

    PrintToChatAll("%s %N został wskrzeszony przez %N!", PREFIX_SKILL, iTarget, iClient);
    int iRandom = GetRandomInt(50, 150);
    PrintToChat(iClient, "%s Otrzymałeś %d expa za wskrzeszenie i 1 nieśmiertelnik!", PREFIX_SKILL, iRandom);
    
    CodMod_GiveExp(iClient, iRandom);
    CodMod_SetDogtagCount(iClient, CodMod_GetDogtagCount(iClient) + 1);
    g_iRessurected[iClient]++;
    g_hSkillTimers[iClient] = INVALID_HANDLE;
    KillSkillTimer(iClient);
    return Plugin_Stop;
}

public Action OnPlayerRunCmd(int iClient, int &iButtons, int &iImpulse, float fVel[3], float fAngles[3], int &iWeapon) {
    if(g_bHasItem[iClient] && (iButtons & IN_JUMP || iButtons & IN_FORWARD || iButtons & IN_BACK || iButtons & IN_MOVELEFT || iButtons & IN_MOVERIGHT)){
        KillSkillTimer(iClient);
    }

    return Plugin_Continue;
}
