#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <codmod301>


public Plugin:myinfo = {
	name = "Call of Duty Mod - Perk - Przesłuchanie po zabiciu",
	author = "th7nder",
	description = "CODMOD's Perk",
	version = "1.5",
	url = "http://th7.eu"
};

new const String:szClassName[NAME_LENGTH] = {"Przesłuchanie"};
new const String:szDesc[DESC_LENGTH] = {"Po zabiciu przeciwnika widzisz wrogów na radarze."};
new g_iPerkId;

new bool:g_bHasItem[MAXPLAYERS +1] = {false};

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

}

public void CodMod_OnPerkDisabled(iClient, iPerkId){
	if(iPerkId != g_iPerkId)
		return;

	g_bHasItem[iClient] = false;

}

public void CodMod_OnPlayerDie(int iAttacker, int iVictim, bool bHeadshot){
    if(g_bHasItem[iAttacker]){
        ShowEnemiesToClient(iAttacker);
        Handle hPack = CreateDataPack();
        WritePackCell(hPack, GetClientSerial(iAttacker));
        WritePackFloat(hPack, 3.0);
        CreateTimer(0.1, Timer_ShowEnemies, hPack);
    }
}


public Action Timer_ShowEnemies(Handle hTimer, Handle hPack){
    ResetPack(hPack);
    int iClient = GetClientFromSerial(ReadPackCell(hPack));
    float fRemaining = ReadPackFloat(hPack);

    CloseHandle(hPack);
    if(!IsValidPlayer(iClient)){
        return Plugin_Stop;
    }

    fRemaining -= 0.1;
    if(fRemaining < 0){
        return Plugin_Stop;
    }


    ShowEnemiesToClient(iClient);

    hPack = CreateDataPack();
    WritePackCell(hPack, GetClientSerial(iClient));
    WritePackFloat(hPack, fRemaining);
    CreateTimer(0.1, Timer_ShowEnemies, hPack);

    return Plugin_Stop;
}


public void ShowEnemiesToClient(int iClient){
    Handle hMessage = StartMessageOne("ProcessSpottedEntityUpdate", iClient, USERMSG_RELIABLE);
    Handle hEntityUpdates;

    float fPos[3],  fAngles[3];
    for(int i = 1; i <= MaxClients; i++){
        if(IsClientInGame(i) && IsPlayerAlive(i)){
            hEntityUpdates = PbAddMessage(hMessage, "entity_updates");
            SetEntProp(i, Prop_Send, "m_bSpotted", 1);
            GetClientAbsOrigin(i, fPos);
            GetClientEyeAngles(i, fAngles);
            PbSetInt(hEntityUpdates, "entity_idx", i);
            PbSetInt(hEntityUpdates, "class_id", GetClientTeam(i));
            PbSetInt(hEntityUpdates, "origin_x", RoundFloat(fPos[0]));
            PbSetInt(hEntityUpdates, "origin_y", RoundFloat(fPos[1]));
            PbSetInt(hEntityUpdates, "origin_z", RoundFloat(fPos[2]));
            PbSetInt(hEntityUpdates, "angle_y", RoundFloat(fAngles[1]));
        }
    }
    EndMessage();
}
