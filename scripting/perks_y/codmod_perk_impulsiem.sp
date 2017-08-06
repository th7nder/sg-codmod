#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <codmod301>

#include <th7manager>
public Plugin:myinfo = {
	name = "Call of Duty Mod - Perk - Impuls IEM",
	author = "th7nder",
	description = "CODMOD's Perk",
	version = "1.0",

};

new const String:szClassName[NAME_LENGTH] = {"Impuls IEM"};
new const String:szDesc[DESC_LENGTH] = {"Nie widać Cie na radarze oraz posiadasz decoya, który zamraża."};
new g_iPerkId;


new bool:g_bHasItem[MAXPLAYERS +1] = {false};

Handle g_hFrozenTimers[MAXPLAYERS+1] = {INVALID_HANDLE};
int iBeamSprite = -1;


public OnPluginStart(){
	g_iPerkId = CodMod_RegisterPerk(szClassName, szDesc);
	HookEvent("decoy_firing", EventDecoyFire, EventHookMode_Post);
}

public OnMapStart(){
	iBeamSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
}

public CodMod_OnPlayerSpawn(iClient){
	if(g_bHasItem[iClient]){
		if(!CodMod_GetPlayerNades(iClient, TH7_DECOY)){
			GivePlayerItem(iClient, "weapon_decoy");
		}
	}
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
	TH7_SetRadarVisibility(iClient, false);

}

public CodMod_OnPerkDisabled(iClient, iPerkId){
	if(iPerkId != g_iPerkId)
		return;

	g_bHasItem[iClient] = false;
	TH7_SetRadarVisibility(iClient, true);
}





stock bool Player_IsVIP(int iClient){
	if (CheckCommandAccess(iClient, "codmod_vip", ADMFLAG_RESERVATION, false)) {
		return true;
	} else {
		return false;
	}
}


public Action EventDecoyFire(Handle gEventHook, const char[] gEventName, bool iDontBroadcast)
{

	float iOrigin[3];
	float pVictimOrigin[3];
	float iDirection[3] = {0.0, 0.0, 0.0};


	int sEntity = GetEventInt(gEventHook, "entityid");

	int iOwner = GetEntPropEnt(sEntity, Prop_Send, "m_hOwnerEntity");
	if(!IsValidPlayer(iOwner))
		return;

	if(Player_IsVIP(iOwner) || g_bHasItem[iOwner]){
		iOrigin[0] = GetEventFloat(gEventHook, "x");
		iOrigin[1] = GetEventFloat(gEventHook, "y");
		iOrigin[2] = GetEventFloat(gEventHook, "z");

		int iGrenadeRadiusFreezing = 300;
		for (int iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
		{

			if (IsValidPlayer(iPlayer) && iPlayer != iOwner && GetClientTeam(iPlayer) != GetClientTeam(iOwner) )
			{

				GetClientAbsOrigin(iPlayer, pVictimOrigin);
				pVictimOrigin[2] += 2.0;

				if (GetVectorDistance(iOrigin, pVictimOrigin) <= iGrenadeRadiusFreezing)
				{
					Handle trTrace = TR_TraceRayFilterEx(iOrigin, pVictimOrigin, MASK_SOLID, RayType_EndPoint, IsPlayerTarget, iPlayer);

					if ((TR_DidHit(trTrace) && TR_GetEntityIndex(trTrace) == iPlayer) || (GetVectorDistance(iOrigin, pVictimOrigin) <= 100.0))
					{

						CodMod_Freeze(iPlayer, 1.5);
						Freeze(iPlayer);

						CloseHandle(trTrace);
					}
					else
					{

						CloseHandle(trTrace);
						GetClientEyePosition(iPlayer, pVictimOrigin);
						pVictimOrigin[2] -= 2.0;
						trTrace = TR_TraceRayFilterEx(iOrigin, pVictimOrigin, MASK_SOLID, RayType_EndPoint, IsPlayerTarget, iPlayer);

						if ((TR_DidHit(trTrace) && TR_GetEntityIndex(trTrace) == iPlayer) || (GetVectorDistance(iOrigin, pVictimOrigin) <= 100.0))
						{
							CodMod_Freeze(iPlayer, 1.5);
							Freeze(iPlayer);
						}

						CloseHandle(trTrace);
					}
				}
			}
		}


		TE_SetupSparks(iOrigin, iDirection, 5000, 1000);
		TE_SendToAll();

		CreateTimer(0.1, Timer_AcceptKill, sEntity);
	}
}


public bool IsPlayerTarget(int sEntity, int iContentsMask, any iVictim)
{
	return (iVictim == sEntity);
}

public void OnEntityCreated(int sEntity, const char[] szClassname)
{
	if (!IsValidEntity(sEntity))
		return;

	if(StrContains(szClassName, "weapon_") == -1)
		return;

	int iOwner = GetEntPropEnt(sEntity, Prop_Send, "m_hOwnerEntity");
	if(!IsValidPlayer(iOwner))
		return;

	if(Player_IsVIP(iOwner) || g_bHasItem[iOwner]){
		if (strcmp(szClassname, "decoy_projectile") == 0)
			BeamFollowFunction(sEntity, {75,75,255,255});
	}
}


void BeamFollowFunction(int sEntity, int iColor[4])
{
	TE_SetupBeamFollow(sEntity, iBeamSprite, 0, 1.0, 4.0, 2.0, 4, iColor);
	TE_SendToAll();
}

void Freeze(int iPlayer)
{

	if (g_hFrozenTimers[iPlayer] != INVALID_HANDLE)
	{
		KillTimer(g_hFrozenTimers[iPlayer]);
		g_hFrozenTimers[iPlayer] = INVALID_HANDLE;
	}

	if(TH7_GetAlpha(iPlayer) == 255)
		TH7_SetRenderColor(iPlayer, 120, 120, 255, 255);


	float iVector[3];
	GetClientEyePosition(iPlayer, iVector);

	iVector[2] -= 50.0;
	EmitAmbientSound("physics/glass/glass_impact_bullet4.wav", iVector, iPlayer, SNDLEVEL_RAIDSIREN);
	g_hFrozenTimers[iPlayer] = CreateTimer(1.5, EventRemoveFreezing, iPlayer);
}

public Action EventRemoveFreezing(Handle sTimer, int iPlayer){
	g_hFrozenTimers[iPlayer] = INVALID_HANDLE;

	if(!IsValidPlayer(iPlayer)){
		return;
	}

	SetEntityMoveType(iPlayer, MOVETYPE_WALK);

	TH7_DisableRenderColor(iPlayer);
}
