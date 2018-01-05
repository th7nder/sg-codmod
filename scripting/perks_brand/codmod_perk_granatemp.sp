#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <dhooks>


#include <codmod301>

public Plugin:myinfo = {
	name = "Call of Duty Mod - Perk - Granat EMP",
	author = "th7nder",
	description = "CODMOD's Perk",
	version = "1.0",
	url = "http://th7.eu"
};

new const String:szClassName[NAME_LENGTH] = {"Granat EMP"};
new const String:szDesc[300] = {"Dostajesz flasha, który po oślepieniu przeciwnika blokuje jego skille \nna 5 sekund, niszczy wszystkie miny, apteczki, etc(750u)\nKolejny flash 20 sec po rzuceniu"};
new g_iPerkId;

int g_iHaloSprite, g_iBeamSprite;
new bool:g_bHasItem[MAXPLAYERS +1] = {false};

public OnPluginStart(){
	g_iPerkId = CodMod_RegisterPerk(szClassName, szDesc);
    HookEvent("flashbang_detonate", Event_OnFlashDetoate)
}


stock bool HasPermission(int iClient)
{
    return (g_bHasItem[iClient] || CodMod_GetCustomPerkPermission(iClient, g_iPerkId));
}

public void OnMapStart()
{
    g_iHaloSprite = PrecacheModel("materials/sprites/halo.vmt");
    g_iBeamSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
}

public OnPluginEnd(){
	CodMod_UnregisterPerk(g_iPerkId);
}

public OnClientPutInServer(iClient){
	g_bHasItem[iClient] = false;
}

public CodMod_OnPerkEnabled(iClient, iPerkId){
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
    if(HasPermission(iClient)){
        if(CodMod_GetPlayerNades(iClient, TH7_FLASHBANG) < 2){
            GivePlayerItem(iClient, "weapon_flashbang");
        }
    }
}


public void OnEntityCreated(int iEntity, const char[] szClassname)
{
    if(StrEqual(szClassname, "flashbang_projectile"))
    {
        SDKHook(iEntity, SDKHook_SpawnPost, OnFlashSpawned);
        SDKHook(iEntity, SDKHook_Spawn, OnSpawn);
    }
}

const float g_fNextGrenadeTime = 20.0;

public Action OnSpawn(int iGrenade)
{
    int iOwner = GetEntPropEnt(iGrenade, Prop_Data, "m_hOwnerEntity");
    if(IsValidPlayer(iOwner) && g_bHasItem[iOwner]){
        Handle hPack = CreateDataPack();
        WritePackCell(hPack, GetClientSerial(iOwner));
        WritePackCell(hPack, CodMod_GetRoundIndex());
        CreateTimer(g_fNextGrenadeTime, Timer_GiveGrenade, hPack);
    }
}

public Action Timer_GiveGrenade(Handle hTimer, Handle hPack)
{
    ResetPack(hPack);
    int iSerial = ReadPackCell(hPack);
    int iRoundIndex = ReadPackCell(hPack);
    delete hPack;

    
    if(CodMod_GetRoundIndex() != iRoundIndex)
    {
        return Plugin_Stop;
    }

    int iClient = GetClientFromSerial(iSerial);
    if(!IsValidPlayer(iClient) || CodMod_GetPlayerNades(iClient, TH7_FLASHBANG))
    {
        return Plugin_Stop;
    }

    GivePlayerItem(iClient, "weapon_flashbang");


    return Plugin_Stop;
}

public Action OnFlashSpawned(int iEntity)
{
    int iOwner = GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity");
    if(iOwner != -1 && HasPermission(iOwner))
    {
        BeamFollowFunction(iEntity, {255,255,255,255});
    }
}



void BeamFollowFunction(int iEntity, int iColor[4])
{
    TE_SetupBeamFollow(iEntity, g_iBeamSprite, 0, 1.0, 4.0, 2.0, 4, iColor);
    TE_SendToAll();
}

public Event_OnFlashDetoate(Event hEvent, const char[] szBroadcast, bool bBroadcast)
{
    int iEntity = hEvent.GetInt("entityid");
    int iOwner = GetClientOfUserId(hEvent.GetInt("userid"));
	if(!HasPermission(iOwner)) {
		return;
	}

    float fOrigin[3];
    GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", fOrigin);
    TE_SetupBeamRingPoint(fOrigin, 10.0, 750.0, g_iBeamSprite, g_iHaloSprite, 0, 10, 0.3, 8.0, 0.0,  {255,255,255,255}, 10, 0);
    TE_SendToAll();

    DeleteAllThings(iOwner, fOrigin);


    int iOwnerTeam = GetClientTeam(iOwner);
    float fTargetOrigin[3];
    for(int i = 1; i <= MaxClients; i++)
    {
        if(IsClientInGame(i) && IsPlayerAlive(i) && i != iOwner && GetClientTeam(i) != iOwnerTeam)
        {
            GetClientEyePosition(i, fTargetOrigin);
            if(GetVectorDistance(fOrigin, fTargetOrigin) > 300.0) continue;
            CodMod_BlockSkill(i, 5.0);
            PrintToChat(i, "%s Twoje skille zostały zablokowane na 5 sec przez impuls EMP!", PREFIX_INFO);
        }
    }
}

public void DeleteAllThings(int iOwner, float fOrigin[3])
{
    int iEntityOwner = -2;
    char szName[32];
    float fEntOrigin[3];
    for(int iEntity = 64; iEntity < 2048; iEntity++)
    {
        if(!IsValidEntity(iEntity)) continue;

        GetEntPropString(iEntity, Prop_Data, "m_iName", szName, 32);
        if(StrContains(szName, "cm_") != -1)
        {
            GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", fEntOrigin);
            if(GetVectorDistance(fOrigin, fEntOrigin) >= 750.0) return;

            iEntityOwner = GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity");
            if(iEntityOwner != iOwner)
            {
                AcceptEntityInput(iEntity, "Kill");
            }
        }
    }
}
