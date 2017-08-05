#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <codmod301>

#include <th7manager>
#define KNIFE_MDL "models/weapons/w_knife_karam.mdl"

public Plugin:myinfo = {
	name = "Call of Duty Mod - Perk - Tomahawk",
	author = "th7nder",
	description = "CODMOD's Perk",
	version = "1.0",
	url = "http://th7.eu"
};

new const String:szClassName[NAME_LENGTH] = {"Tomahawk"};
new const String:szDesc[DESC_LENGTH] = {"Posiadasz 5 noży do rzucania(1 nóz 50dmg)."};
new g_iPerkId;


new bool:g_bHasItem[MAXPLAYERS +1] = {false};
int g_iKnives[MAXPLAYERS+1] = {0};

new const Float:g_fSpin[3] = {4877.4, 0.0, 0.0};

public OnPluginStart(){
	g_iPerkId = CodMod_RegisterPerk(szClassName, szDesc);

	HookEvent("weapon_fire", Event_WeaponFire);
}

public OnPluginEnd(){
	CodMod_UnregisterPerk(g_iPerkId);
}

public OnClientPutInServer(iClient){
	g_bHasItem[iClient] = false;
	g_iKnives[iClient] = 0;
}

public OnMapStart(){
	PrecacheModel(KNIFE_MDL);
}

public CodMod_OnPerkEnabled(iClient, iPerkId){
	if(iPerkId != g_iPerkId)
		return;

	g_bHasItem[iClient] = true;
	g_iKnives[iClient] = 5;

}

public CodMod_OnPerkDisabled(iClient, iPerkId){
	if(iPerkId != g_iPerkId)
		return;

	g_bHasItem[iClient] = false;
	g_iKnives[iClient] = 0;
}

public CodMod_OnPlayerSpawn(iClient){
	if(g_bHasItem[iClient]){
		g_iKnives[iClient] = 5;
	}
}




public Event_WeaponFire(Event hEvent, const char[] szName, bool bDontBroadcast) {
	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));

	if (g_bHasItem[iClient]){
		int iEntity = GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
		if(iEntity != -1 && CodMod_GetWeaponID(iEntity) == WEAPON_KNIFE){
			ThrowKnife(iClient);
		}

	}
}

stock ThrowKnife(client) {
	if(g_iKnives[client] < 1){
		PrintToChat(client, "%sNie masz wystarczającej ilości noży do rzucenia!", PREFIX_INFO);
		return;
	}
	g_iKnives[client]--;

	new entity = CreateEntityByName("decoy_projectile");
	if ((entity != -1) && DispatchSpawn(entity)) {
		SetEntityModel(entity, KNIFE_MDL);
		SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client);

		new Float:eyes_angle[3];
		GetClientEyeAngles(client, eyes_angle);

		new Float:fwd_vec[3];
		GetAngleVectors(eyes_angle, fwd_vec, NULL_VECTOR, NULL_VECTOR);

		new Float:velocity[3];
		velocity[0] = fwd_vec[0] * 1500.0;
		velocity[1] = fwd_vec[1] * 1500.0;
		velocity[2] = fwd_vec[2] * 1500.0;

		new Float:eyes[3];
		GetClientEyePosition(client, eyes);
		eyes[2] += 20;

		SetEntPropVector(entity, Prop_Data, "m_vecAngVelocity", g_fSpin);
		SetEntPropFloat(entity, Prop_Send, "m_flElasticity", 0.2);
		SetEntProp(entity, Prop_Send, "m_usSolidFlags", 152);
		SetEntProp(entity, Prop_Send, "m_CollisionGroup", 11);

		TeleportEntity(entity, eyes, NULL_VECTOR, velocity);
		SDKHook(entity, SDKHook_StartTouchPost, OnKnifeStartTouch);
	}
}

public OnKnifeStartTouch(entity, client){
	if(!IsValidEdict(entity))
		return;

	new owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	if(IsValidPlayer(owner) && IsValidPlayer(client)){
		if(owner == client && g_bHasItem[owner]){
			if(g_iKnives[owner] + 1 <= 3){
				g_iKnives[owner]++;
				PrintToChat(owner, "%sPodniosłeś nóż!", PREFIX_INFO);
				CreateTimer(0.1, Timer_AcceptKill, entity);
			}

		} else if(GetClientTeam(client) != GetClientTeam(owner)){
			float fVelocity[3];
			GetEntPropVector(entity, Prop_Data, "m_vecVelocity", fVelocity);
			if(fVelocity[0] != 0.0 && fVelocity[1] != 0.0 && fVelocity[2] != 0.0){
				CodMod_DealDamage(owner, client, 50.0, TH7_DMG_THROWINGKNIFE);
				CreateTimer(0.01, Timer_AcceptKill, entity);
			} else if(g_bHasItem[client]) {
				if(g_iKnives[client] + 1 <= 3){
					g_iKnives[client]++;
					PrintToChat(client, "%sPodniosłeś nóż!", PREFIX_INFO);
					CreateTimer(0.1, Timer_AcceptKill, entity);
				}

			}
		}

	}
}
