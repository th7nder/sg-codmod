#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <codmod301>

public Plugin myinfo = {
    name = "Call of Duty Mod - Perk - Buty Luigiego",
    author = "th7nder",
    description = "201 Rewrite Perk",
    version = "2.0",
    url = "http://th7.eu"
};

char szClassName[] = {"Buty Luigiego"};
char szDesc[] = {"Posiadasz AutoBHOPa."};
int g_iPerkId;


bool g_bHasItem[MAXPLAYERS +1] = {false};


public void OnPluginStart(){
    g_iPerkId = CodMod_RegisterPerk(szClassName, szDesc);
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

#define WATER_LEVEL_FEET_IN_WATER   1
stock Client_GetWaterLevel(client){
    return GetEntProp(client, Prop_Send, "m_nWaterLevel");
}

public Action OnPlayerRunCmd(int iClient, int &iButtons, int &iImpulse, float fVel[3], float fAngles[3], int &iWeapon) {
	if(g_bHasItem[iClient]){
		int iIndex = GetEntProp(iClient, Prop_Data, "m_nWaterLevel");
		int iWater = EntIndexToEntRef(iIndex);
		if (iWater != INVALID_ENT_REFERENCE)
		{
			if (IsPlayerAlive(iClient))
			{
				if (iButtons & IN_JUMP)
				{
					if (!(Client_GetWaterLevel(iClient) > WATER_LEVEL_FEET_IN_WATER))
					{
						if (!(GetEntityMoveType(iClient) & MOVETYPE_LADDER))
						{
							SetEntPropFloat(iClient, Prop_Send, "m_flStamina", 0.0);
              float vVel[3];
              GetEntPropVector(iClient, Prop_Data, "m_vecVelocity", vVel)
							if (!(GetEntityFlags(iClient) & FL_ONGROUND) && vVel[2] < -30.0)
							{
								iButtons &= ~IN_JUMP;
							}
						}
					}
				}
			}
		}
	}
	return Plugin_Continue;
}
