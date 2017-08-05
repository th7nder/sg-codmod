#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>

#include <codmod301>

public Plugin:myinfo = {
	name = "Call of Duty Mod - Perk - Elektromagnes Militarny",
	author = "th7nder",
	description = "CODMOD's Perk",
	version = "1.0",
	url = "http://th7.eu"
};

int g_iCounter[2048] = {0};
new const String:szClassName[NAME_LENGTH] = {"Elektromagnes Militarny"};
new const String:szDesc[DESC_LENGTH] = {"Co rundę możesz położyć magnes, który wywali broń dla przeciwników w zasięgu 350u\n 2sec"};
new g_iPerkId;

int g_iHaloSprite = -1;
int g_iBeamSprite = -1;
bool g_bUsed[MAXPLAYERS+1] = {false};
new bool:g_bHasItem[MAXPLAYERS +1] = {false};

public OnPluginStart(){
	g_iPerkId = CodMod_RegisterPerk(szClassName, szDesc);
}


public OnPluginEnd(){
	CodMod_UnregisterPerk(g_iPerkId);
}


public void OnMapStart()
{
    g_iHaloSprite = PrecacheModel("materials/sprites/halo.vmt");
    g_iBeamSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
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


public void CodMod_OnPerkSkillUsed(int iClient){
	if(!IsValidPlayer(iClient) || !IsPlayerAlive(iClient) || !g_bHasItem[iClient])
		return;

	if(g_bUsed[iClient]){
        PrintToChat(iClient, "%s Użyłeś już elektromagnesu w tej rundzie!", PREFIX_SKILL);
		return;
	}

    if((g_bUsed[iClient] = PlaceMagnet(iClient)))
    {
        PrintToChat(iClient, "%s Magnes został postawiony!", PREFIX_SKILL);
    }
}

public void CodMod_OnPlayerSpawn(int iClient)
{
    g_bUsed[iClient] = false;
}

public bool IsValidMagnetPos(int iMine, float fVecPos[3]){
   /* static const float fVecMins[] = {-8.0, -24.0, 0.0};
    static const float fVecMaxs[] = {24.0, 24.0, 114.0};

    TR_TraceHullFilter(fVecPos, fVecPos, fVecMins, fVecMaxs, MASK_SOLID, TraceFilter_IgnorePlayer,iMine);

    return (!TR_DidHit(null));*/
    return true;
}

public bool PlaceMagnet(int iClient){
    float fOrigin[3];
    if(!(GetEntityFlags(iClient) & FL_ONGROUND) ){
        GetClientGroundPosition(iClient, fOrigin);
    } else {
        GetClientAbsOrigin(iClient, fOrigin);
    }


    fOrigin[2] += 2.5;

    if(!IsValidMagnetPos(iClient, fOrigin)){
        return false;
    }

    int iEntity = CreateEntityByName("prop_physics_override");
    DispatchKeyValue(iEntity, "targetname", "cm_mine");
    DispatchKeyValue(iEntity, "model", MINE_MODEL);
    DispatchKeyValue(iEntity, "Solid", "6");
    DispatchSpawn(iEntity);
    SetEntityModel(iEntity, MINE_MODEL);
    SetEntProp(iEntity, Prop_Send, "m_usSolidFlags",  152)
    SetEntProp(iEntity, Prop_Send, "m_CollisionGroup", 11)

    SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", iClient);
    SetEntPropFloat(iEntity, Prop_Send, "m_flModelScale", 1.0);

    SetEntityMoveType(iEntity, MOVETYPE_FLYGRAVITY);
    SetEntityRenderMode(iEntity, RENDER_TRANSCOLOR);
    SetEntityRenderColor(iEntity, 0, 0, 175, 50);
    TeleportEntity(iEntity, fOrigin, NULL_VECTOR, view_as<float>({0.0, 0.0, -600.0}));

    g_iCounter[iEntity] = 0;
    CreateTimer(0.1, Timer_Pulse, EntIndexToEntRef(iEntity), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
    return true;
}

public Action Timer_Pulse(Handle hTimer, int iRef)
{
    int iEntity = EntRefToEntIndex(iRef);
    if(!IsValidEntity(iEntity)) {
        return Plugin_Continue;
    }
    if(iEntity == INVALID_ENT_REFERENCE)
    {
        g_iCounter[iEntity] = 0;
        return Plugin_Stop;
    }
    int iOwner = GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity");
    float fOrigin[3];
    GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", fOrigin);

    if(g_iCounter[iEntity] % 5 == 0)
    {
        TE_SetupBeamRingPoint(fOrigin, 10.0, 350.0, g_iBeamSprite, g_iHaloSprite, 0, 10, 0.3, 8.0, 0.0,  {125, 0, 0,255}, 10, 0);
        TE_SendToAll();
    }

    if(g_iCounter[iEntity] >= 20)
    {
        g_iCounter[iEntity] = 0;
        AcceptEntityInput(iEntity, "kill");
        return Plugin_Stop;
    }

    RadiusDrop(iOwner, fOrigin, 350.0);

    g_iCounter[iEntity]++;
    return Plugin_Continue;
}


public void RadiusDrop(int iOwner, float fOrigin[3], float fRadius)
{
    int iOwnerTeam = GetClientTeam(iOwner);
    float fTargetOrigin[3];
    int iWeapon = -1;
    for(int i = 1; i <= MaxClients; i++)
    {
        if(i != iOwner && IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) != iOwnerTeam)
        {
            GetClientEyePosition(i, fTargetOrigin);
            if(GetVectorDistance(fOrigin, fTargetOrigin) <= fRadius)
            {
                iWeapon = GetEntPropEnt(i, Prop_Send, "m_hActiveWeapon");
                if(CodMod_GetWeaponID(iWeapon) != WEAPON_KNIFE)
                {
                    CS_DropWeapon(i, iWeapon, true);
                }
            }
        }
    }
}