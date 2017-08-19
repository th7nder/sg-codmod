#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>

#define ON_FIRE 1
bool g_bOnFire[MAXPLAYERS+1] = {false};
#include <codmod301>
#include <dhooks>


public Plugin:myinfo = {
	name = "Call of Duty Mod - Perk - Granat Sprawiedliwości",
	author = "th7nder",
	description = "CODMOD's Perk",
	version = "1.0",
	url = "http://th7.eu"
};

new const String:szClassName[NAME_LENGTH] = {"Granat sprawiedliwości"};
new const String:szDesc[DESC_LENGTH] = {"Otrzymujesz HE [+125DMG], który po wybuchu tworzy 2 dodatkowe HE\nMają 1/4 szansy na zamrożenie lub podpalenie [10hp/s] na 5s"};
int g_iPerkId;

bool g_bHasItem[MAXPLAYERS +1] = {false};
Handle g_hDetonate = null;

int g_iFreezingNade[MAXPLAYERS+1];
int g_iBurningNade[MAXPLAYERS+1];

int g_iBeamSprite = -1;
int g_iHaloSprite = -1;

public void OnPluginStart(){
	g_hDetonate = DHookCreate(235, HookType_Entity, ReturnType_Void, ThisPointer_CBaseEntity, DHook_OnGrenadeDetonate);
	g_iPerkId = CodMod_RegisterPerk(szClassName, szDesc);
}

public void OnMapStart()
{
    g_iBeamSprite = PrecacheModel("materials/sprites/bluelaser1.vmt");
    g_iHaloSprite = PrecacheModel("materials/sprites/halo01.vmt");
}


public void OnPluginEnd(){
	CodMod_UnregisterPerk(g_iPerkId);
}

public void OnClientPutInServer(iClient){
	g_bHasItem[iClient] = false;
}

public void CodMod_OnPerkEnabled(iClient, iPerkId){
	if(iPerkId != g_iPerkId)
		return;

	g_bHasItem[iClient] = true;
	g_iFreezingNade[iClient] = -1;
	g_iBurningNade[iClient] = -1;

}


public void CodMod_OnPerkDisabled(int iClient, int iPerkId){
    if(iPerkId != g_iPerkId)
        return;

    g_bHasItem[iClient] = false;
}


public void CodMod_OnPlayerSpawn(int iClient){
    g_iFreezingNade[iClient] = -1;
	g_iBurningNade[iClient] = -1;
    if(g_bHasItem[iClient]){
        if(CodMod_GetPlayerNades(iClient, TH7_HE) < 1){
            GivePlayerItem(iClient, "weapon_hegrenade");
        }
    }
    g_bOnFire[iClient] = false;
}

public void CodMod_OnPlayerDamagedPerk(int iAttacker, int iVictim, float &fDamage, WeaponID iWeaponID, int iDamageType){
    if(g_bHasItem[iAttacker]){
        if((iWeaponID == WEAPON_HEGRENADE)){
            fDamage += 125.0;
        }
    }
}



public void OnEntityCreated(int iEntity, const char[] szClassname)
{
    if(StrEqual(szClassname, "hegrenade_projectile"))
    {
        SDKHook(iEntity, SDKHook_SpawnPost, OnHegrenadeSpawned);
    }
}

public Action OnHegrenadeSpawned(int iEntity)
{
    int iOwner = GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity");
    if(iOwner != -1 && g_bHasItem[iOwner])
    {
        DHookEntity(g_hDetonate, false, iEntity);
    }
}



public MRESReturn DHook_OnGrenadeDetonate(int iEntity)
{
    int iOwner = GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity");
    float fOrigin[3];
	GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", fOrigin);
    if(iOwner != -1 && IsValidPlayer(iOwner) && g_bHasItem[iOwner] && g_iFreezingNade[iOwner] != iEntity && g_iBurningNade[iOwner] != iEntity)
    {
		fOrigin[2] += 10.0;
		g_iFreezingNade[iOwner] = SpawnGrenade(iOwner, fOrigin);
		fOrigin[2] += 10.0;
		g_iBurningNade[iOwner] = SpawnGrenade(iOwner, fOrigin);
    }


    if(iOwner != -1 && g_bHasItem[iOwner] && (g_iFreezingNade[iOwner] == iEntity || g_iBurningNade[iOwner] == iEntity))
    { 
 		bool bFreezing = false;
 		if(g_iFreezingNade[iOwner] == iEntity)
 		{
 			bFreezing = true;
 			TE_SetupBeamRingPoint(fOrigin, 10.0, 350.0, g_iBeamSprite, g_iHaloSprite, 0, 10, 0.3, 8.0, 0.0,  {0,0,255,255}, 10, 0);
   			TE_SendToAll();
 		}
 		else
 		{
 			TE_SetupBeamRingPoint(fOrigin, 10.0, 350.0, g_iBeamSprite, g_iHaloSprite, 0, 10, 0.3, 8.0, 0.0,  {255,0,0,255}, 10, 0);
   			TE_SendToAll();
 		}


   		float fTargetPos[3];
   		int iOwnerTeam = GetClientTeam(iOwner);
   		for(int i = 1; i <= MaxClients; i++)
   		{
   			if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) != iOwnerTeam && GetRandomInt(1, 100) >= 75)
   			{
   				GetClientEyePosition(i, fTargetPos);
   				if(GetVectorDistance(fOrigin, fTargetPos) >= 350.0) continue;

   				if(bFreezing)
   				{
   					CodMod_Freeze(i, 2.0);
   				}
   				else
   				{
   					if(!g_bOnFire[i]){
				        g_bOnFire[i] = true;
				        PrintToChat(iOwner, "%s Podpaliłeś gracza!", PREFIX_SKILL);
				        PrintToChat(i, "%s Zostałeś podpalony!", PREFIX_SKILL);
				        CodMod_Burn(iOwner, i, 5.0, 1.0, 10.0);
			    	}
   				}

   			}
   		}
    }

	
    return MRES_Ignored;
}


stock int SpawnGrenade(int iOwner, float fOrigin[3])
{
	int iEntity = CreateEntityByName("hegrenade_projectile");
	SetEntPropEnt(iEntity, Prop_Data, "m_hThrower", iOwner);
	SetEntProp(iEntity, Prop_Data, "m_iTeamNum", GetClientTeam(iOwner));
	SetEntPropFloat(iEntity, Prop_Data, "m_flDamage", 99.0);
	SetEntPropFloat(iEntity, Prop_Data, "m_DmgRadius", 350.0);  
	SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", iOwner);
	DispatchSpawn(iEntity);  
	AcceptEntityInput(iEntity, "InitializeSpawnFromWorld");  
	TeleportEntity(iEntity, fOrigin, NULL_VECTOR, NULL_VECTOR);

	DHookEntity(g_hDetonate, false, iEntity);
	return iEntity;
}

