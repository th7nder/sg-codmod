#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <codmod301>
#include <currentmapmodel>


public Plugin:myinfo = {
	name = "Call of Duty Mod - Perk - Podręcznik Szpiega",
	author = "th7nder",
	description = "CODMOD's Perk",
	version = "1.0",
	url = "http://th7.eu"
};

new const String:szClassName[NAME_LENGTH] = {"Podręcznik Szpiega"};
new const String:szDesc[DESC_LENGTH] = {"Zadajesz +30DMG w Plecy, oraz na starcie rundy masz 1/8 szans na resp u przeciwnika."};
new g_iPerkId;

new bool:g_bHasItem[MAXPLAYERS +1] = {false};

public OnPluginStart(){
	g_iPerkId = CodMod_RegisterPerk(szClassName, szDesc);
}


public OnPluginEnd(){
	CodMod_UnregisterPerk(g_iPerkId);
}

char g_szCTModel[128] = {"models/player/ctm_idf_variantD.mdl"};
char g_szTTModel[128] = {"models/player/tm_leet_variantD.mdl"};


public void OnMapStart(){
  PrecacheModel(g_szCTModel);
  PrecacheModel(g_szTTModel);
}

public OnClientPutInServer(iClient){
	g_bHasItem[iClient] = false;
}

public CodMod_OnPerkEnabled(iClient, iPerkId){
	if(iPerkId != g_iPerkId)
		return;

	g_bHasItem[iClient] = true;

}

void UpdateModel(int iClient)
{
  if(!IsPlayerAlive(iClient))
    return;

  if(GetClientTeam(iClient) == CS_TEAM_T){

    if(GetCurrentMapModel(CS_TEAM_CT, g_szCTModel, sizeof(g_szCTModel))){
      SetEntityModel(iClient, g_szCTModel);
      LogMessage("UpdateModel from tt to ct: %s", g_szCTModel);
    }


  } else {
    if(GetCurrentMapModel(CS_TEAM_T, g_szTTModel, sizeof(g_szTTModel)))
    {
      LogMessage("UpdateModel from ct to tt: %s", g_szTTModel);
      SetEntityModel(iClient, g_szTTModel);
    }

  }
}

public void CodMod_OnPlayerSpawn(int iClient)
{
	if(g_bHasItem[iClient])
	{
		if(GetRandomInt(1, 100) >= 87 && !RespawnAtEnemySpawn(iClient))
		{
			CreateRespawnTimer(iClient);
		}

		UpdateModel(iClient);
	}

}

stock CreateRespawnTimer(int iClient)
{
	PrintToChat(iClient, "%s Wylosowałeś teleport, nie ma wolnego miejsca, próbujemy za chwilę!", PREFIX_SKILL);
	Handle hPack = CreateDataPack();
	WritePackCell(hPack, GetClientSerial(iClient));
	WritePackCell(hPack, CodMod_GetRoundIndex());
	CreateTimer(0.5, Timer_Respawn, hPack);
}

public Action Timer_Respawn(Handle hTimer, Handle hPack)
{
	ResetPack(hPack);
	int iClient = GetClientFromSerial(ReadPackCell(hPack));
	int iRoundIndex = ReadPackCell(hPack);
	delete hPack;
	if(!IsValidPlayer(iClient) || CodMod_GetRoundIndex() != iRoundIndex) return Plugin_Stop;

	if(!RespawnAtEnemySpawn(iClient))
	{
		CreateRespawnTimer(iClient);
	}

	return Plugin_Stop;
}


stock bool RespawnAtEnemySpawn(int iClient)
{
		if(!IsPlayerAlive(iClient)) return true;

		int iSpawn = -1;
		if(GetClientTeam(iClient) == CS_TEAM_T)
		{
			iSpawn = FindFreeSpawn("info_player_counterterrorist");
		}
		else if(GetClientTeam(iClient) == CS_TEAM_CT)
		{
			iSpawn = FindFreeSpawn("info_player_terrorist");

		}
		if(iSpawn == -1) return false;
		float fOrigin[3], fAngle[3];
		GetEntPropVector(iSpawn, Prop_Data, "m_vecOrigin", fOrigin);
		GetEntPropVector(iSpawn, Prop_Data, "m_angRotation", fAngle);

		if(fOrigin[0] == 0.0 || fOrigin[1] == 0.0 || fOrigin[2] == 0.0) return false;

		//PrintToConsole(iClient, "%.1f %.1f %.1f", fOrigin[0], fOrigin[1], fOrigin[2]);
		TeleportEntity(iClient, fOrigin, fAngle, NULL_VECTOR);

		return true;
}

public void CodMod_OnPerkDisabled(int iClient, int iPerkId){
    if(iPerkId != g_iPerkId)
        return;

    g_bHasItem[iClient] = false;
}


public void CodMod_OnPlayerDamaged(int iAttacker, int iVictim, float &fDamage, WeaponID iWeaponID, int iDamageType){
    if(g_bHasItem[iAttacker])
	{
    	if(isInFOV(iAttacker, iVictim) && !isInFOV(iVictim, iAttacker))
	   	{
		   fDamage += 30.0;
	   	}
    }
}



public bool IsValidSpawn(float fVecPos[3]){
    static const float fVecMins[] = {-16.0, -16.0, 0.0};
    static const float fVecMaxs[] = {16.0, 16.0, 72.0};

    TR_TraceHullFilter(fVecPos, fVecPos, fVecMins, fVecMaxs, MASK_SOLID, TraceFilter_IgnoreEntity, 0);

	if(TR_PointOutsideWorld(fVecPos))
	{
		return false;
	}


    if(TR_DidHit()){
        int iEntity = TR_GetEntityIndex();
        if(iEntity == 0){
            return true;
        }

        if(IsValidPlayer(iEntity)){
            return false;
        }

    } 

    return true;
}


public int FindFreeSpawn(char szClassname[64]){
    float fVecPos[3];

    int iEnt = -1;
    int iValidSpawns[32] = {-1};
    int iSpawnCounter = 0;
    while ((iEnt = FindEntityByClassname(iEnt, szClassname)) != -1) {
        GetEntPropVector(iEnt, Prop_Data, "m_vecOrigin", fVecPos);
        if(IsValidSpawn(fVecPos) && fVecPos[0] != 0.0 && fVecPos[1] != 0.0 && fVecPos[2] != 0.0){
            iValidSpawns[iSpawnCounter++] = iEnt;
        } 
    }

    if(!iSpawnCounter) return -1;



    return iValidSpawns[GetRandomInt(0, iSpawnCounter)];
}