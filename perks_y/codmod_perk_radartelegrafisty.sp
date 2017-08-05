#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <codmod301>


public Plugin:myinfo = {
	name = "Call of Duty Mod - Perk - Radar Telegrafisty",
	author = "th7nder",
	description = "CODMOD's Perk",
	version = "1.5",
	url = "http://th7.eu"
};

new const String:szClassName[NAME_LENGTH] = {"Radar Telegrafisty"};
new const String:szDesc[DESC_LENGTH] = {"Po wciśnięciu codmod_perk, przez 3 sekundy widzisz wrogów na radarze, 2x na rundę"};
new g_iPerkId;

new bool:g_bHasItem[MAXPLAYERS +1] = {false};
int g_iRadarUsed[MAXPLAYERS+1] = {0};
float g_fLastUse[MAXPLAYERS+1] = {0.0};

public OnPluginStart(){
	g_iPerkId = CodMod_RegisterPerk(szClassName, szDesc);
}

public OnPluginEnd(){
	CodMod_UnregisterPerk(g_iPerkId);
}


public void OnClientPutInServer(iClient){
	g_bHasItem[iClient] = false;
}

public void CodMod_OnPerkEnabled(iClient, iPerkId){
	if(iPerkId != g_iPerkId)
		return;

	g_bHasItem[iClient] = true;
    g_iRadarUsed[iClient] = 0;
    g_fLastUse[iClient] = 0.0;
}

public void CodMod_OnPerkDisabled(iClient, iPerkId){
	if(iPerkId != g_iPerkId)
		return;

	g_bHasItem[iClient] = false;

}

public void CodMod_OnPlayerSpawn(iClient){
	if(g_bHasItem[iClient]){
        g_fLastUse[iClient] = 0.0;
        g_iRadarUsed[iClient] = 0;
	}
}


public void CodMod_OnPerkSkillUsed(int iClient){
	if(!IsValidPlayer(iClient) || !IsPlayerAlive(iClient) || !g_bHasItem[iClient])
		return;

    if(g_iRadarUsed[iClient] + 1 > 3){
        PrintToChat(iClient, "%s Możesz użyć tej umiejętności 2 razy na runde!", PREFIX_SKILL);
        return;
    }


    if(GetGameTime() - g_fLastUse[iClient] < 5.0){
        PrintToChat(iClient, "%s Użycie raz na 5 sec!", PREFIX_SKILL);
        g_fLastUse[iClient] = GetGameTime();
    }

    g_iRadarUsed[iClient]++;

    ShowEnemiesToClient(iClient);
    Handle hPack = CreateDataPack();
    WritePackCell(hPack, GetClientSerial(iClient));
    WritePackCell(hPack, 3);
    CreateTimer(1.0, Timer_ShowEnemies, hPack);

}

public Action Timer_ShowEnemies(Handle hTimer, Handle hPack){
    ResetPack(hPack);
    int iClient = GetClientFromSerial(ReadPackCell(hPack));
    int iRemaining = ReadPackCell(hPack);

    CloseHandle(hPack);
    if(!IsValidPlayer(iClient)){
        return Plugin_Stop;
    }

    iRemaining--;
    if(iRemaining < 0){
        return Plugin_Stop;
    }


    ShowEnemiesToClient(iClient);

    hPack = CreateDataPack();
    WritePackCell(hPack, GetClientSerial(iClient));
    WritePackCell(hPack, iRemaining);
    CreateTimer(1.0, Timer_ShowEnemies, hPack);

    return Plugin_Stop;
}


public void ShowEnemiesToClient(int iClient){
    Handle hMessage = StartMessageOne("ProcessSpottedEntityUpdate", iClient, USERMSG_RELIABLE);
    Handle hEntityUpdates;

    float fPos[3];
    int iTeam = GetClientTeam(iClient)
    for(int i = 1; i <= MaxClients; i++){
        if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) != iTeam){
            hEntityUpdates = PbAddMessage(hMessage, "entity_updates");
            GetClientAbsOrigin(i, fPos);
            PbSetInt(hEntityUpdates, "entity_idx", i);
            PbSetInt(hEntityUpdates, "class_id", GetClientTeam(i));
            PbSetInt(hEntityUpdates, "origin_x", RoundFloat(fPos[0]));
            PbSetInt(hEntityUpdates, "origin_y", RoundFloat(fPos[1]));
            PbSetInt(hEntityUpdates, "origin_z", RoundFloat(fPos[2]));
        }
    }
    EndMessage();
}
