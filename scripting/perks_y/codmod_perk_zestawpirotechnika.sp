#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <codmod301>


public Plugin:myinfo = {
	name = "Call of Duty Mod - Perk - Zestaw pirotechnika",
	author = "th7nder",
	description = "CODMOD's Perk",
	version = "1.0",
	url = "http://th7.eu"
};

new const String:szClassName[NAME_LENGTH] = {"Zestaw Pirotechnika"};
new const String:szDesc[DESC_LENGTH] = {"Plantujesz pakę 1sec/defusujesz ją 1sec."};
new g_iPerkId;

new bool:g_bHasItem[MAXPLAYERS +1] = {false};

public OnPluginStart(){
	g_iPerkId = CodMod_RegisterPerk(szClassName, szDesc);

	HookEventEx("bomb_begindefuse", begin);
	HookEventEx("bomb_beginplant", begin);
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

public CodMod_OnPerkDisabled(iClient, iPerkId){
	if(iPerkId != g_iPerkId)
		return;

	g_bHasItem[iClient] = false;
}

public begin(Handle:event, const String:name[], bool:dontBroadcast)
{
    new userid = GetEventInt(event, "userid");
    if(StrContains(name, "defuse", false) != -1)
    {
        CreateTimer(0.0, timer_delay_defuse, userid);
        return;
    }

    CreateTimer(0.0, timer_delay_plant, userid);
}

public Action:timer_delay_defuse(Handle:timer, any:userid)
{

    new client = GetClientOfUserId(userid);

    if(client != 0 && IsPlayerAlive(client) && g_bHasItem[client])
    {
        new c4 = FindEntityByClassname(MaxClients+1, "planted_c4");
        if(c4 != -1)
        {
            SetEntPropFloat(c4, Prop_Send, "m_flDefuseCountDown", GetGameTime() + 1.0);
        }
    }
}
public Action:timer_delay_plant(Handle:timer, any:userid)
{

    new client = GetClientOfUserId(userid);

    if(client != 0 && IsPlayerAlive(client) && g_bHasItem[client])
    {
        new c4 = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
        new String:classname[30];
        GetEntityClassname(c4, classname, sizeof(classname));
        if(StrEqual(classname, "weapon_c4", false))
        {
            SetEntPropFloat(c4, Prop_Send, "m_fArmedTime", GetGameTime() + 1.0);
        }
    }
}
