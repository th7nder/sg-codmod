#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <codmod301>
#include <emitsoundany>


public Plugin:myinfo = {
	name = "Call of Duty Mod - Sklep",
	author = "th7nder",
	description = "CODMOD's Shop",
	version = "1.0",
	url = "http://th7.eu"
};

bool g_bBoughtGravity[MAXPLAYERS+1] = {false};
bool g_bIncreasedExp[MAXPLAYERS+1] = {false};
bool g_bIncreasedSpeed[MAXPLAYERS+1] = {false};
bool g_bIncreasedDamage[MAXPLAYERS+1] = {false};

new itemsPrices[20];
new bought[MAXPLAYERS + 1] = {0};
//new moneyOffset;
new bool:roundEnd = false;

new bool:itemBought[MAXPLAYERS + 1][7];

char g_saGrenadeWeaponNames[][] = {
    "weapon_flashbang",
    "weapon_molotov",
    "weapon_smokegrenade",
    "weapon_hegrenade",
    "weapon_decoy",
    "weapon_incgrenade"
};

int g_iaGrenadeOffsets[sizeof(g_saGrenadeWeaponNames)];

public OnPluginStart(){
	RegConsoleCmd("sklep", Shop);
	RegConsoleCmd("s", Shop);
	itemsPrices[0] = 6000;
	itemsPrices[1] = 8000;
	itemsPrices[2] = 8000;
	itemsPrices[3] = 12000;
	itemsPrices[4] = 16000;
	itemsPrices[5] = 8000;
	itemsPrices[6] = 8000;
	HookEvent("player_spawn", Event_OnPlayerSpawn);
	HookEvent("round_end", Event_OnRoundEnd);
	HookEvent("round_start", Event_OnRoundStart);
	for(new i = 0; i <= MaxClients; i++){
		for(new j = 0; j < 7; j++)
			itemBought[i][j] = false;
	}
	//moneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");

}


public Event_OnRoundStart(Handle:event, const String:name[], bool:broadcast){
	roundEnd = false;
	for(int i = 1; i <= MaxClients; i++){
		g_bIncreasedExp[i] = false;
	}
}

public Event_OnRoundEnd(Handle:event, const String:name[], bool:broadcast){
	roundEnd = true;
}


stock GetMoney(client){
	//4return GetEntData(client, moneyOffset);
	return GetEntProp(client, Prop_Send, "m_iAccount");
}

stock SetMoney(client, amount){
	SetEntProp(client, Prop_Send, "m_iAccount", amount);
}



public Action:Shop(client, args) {
	if(roundEnd){
		return Plugin_Handled;
	}

	if(!IsPlayerAlive(client)){
		PrintToChat(client, "%sJak jesteś martwy, nie możesz korzystać ze sklepiku!", PREFIX_INFO);
		return Plugin_Handled;
	}

	if(GameRules_GetProp("m_bWarmupPeriod") == 1) {
		PrintToChat(client, "%sNie możesz korzystać ze sklepu podczas rozgrzewki!", PREFIX);
		return Plugin_Handled;
	}

	/*if(GetClientCount() < 5){
		PrintToChat(client, "%sMusi być co najmniej 5 graczy, aby korzystać ze sklepiku!", PREFIX);
		return Plugin_Handled;
	}*/

	new Handle:menu = CreateMenu(Shop_Handler, MENU_ACTIONS_ALL);
	SetMenuTitle(menu, "%s", "Sklep CodMod Serwery-GO.pl");

	AddMenuItem(menu, "0", "Morfina[+50HP] - 6000$");
	AddMenuItem(menu, "1", "Losowy Perk - 8000$");
	AddMenuItem(menu, "2", "Mała ilość expa[1-500] - 8000$");
	AddMenuItem(menu, "3", "Średnia ilość expa[500-1000] - 12000$");
	AddMenuItem(menu, "4", "Duża ilość expa[1000-1500] - 16000$");
	AddMenuItem(menu, "5", "Rosyjska Ruletka[1-8 lub śmierć] - 8000$");

	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 20);
	return Plugin_Handled;
}

public Shop_Handler(Handle:menu, MenuAction:action, client, item){
	switch(action) {
		case MenuAction_Select:
		{
			BuyItem(client, item);
		}

		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}

public CodMod_OnPlayerDie(attacker, victim, bool headshot){
	bought[attacker] = 0;
}

public Event_OnPlayerSpawn(Handle:event, const String:name[], bool:broadcast){
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(g_bBoughtGravity[client]){
		int iCurrent = CodMod_GetStat(client, GRAVITY_PERK);
		if(iCurrent < 50){
			CodMod_SetStat(client, GRAVITY_PERK, iCurrent + 50);
		} else {
			CodMod_SetStat(client, GRAVITY_PERK, iCurrent - 50);
		}
		g_bBoughtGravity[client] = false;
	}

	if(g_bIncreasedSpeed[client]){
		CodMod_SetStat(client, DEX_PERK, CodMod_GetStat(client, DEX_PERK) - 60);
		g_bIncreasedSpeed[client] = false;
	}

	if(g_bIncreasedDamage[client]){
		g_bIncreasedDamage[client] = false;
	}

	CreateTimer(1.0, FixMoney, any:client);
}

public Action:FixMoney(Handle:timer, any:client){

	for(new i = 0; i < 7; i++){
		itemBought[client][i] = false;
	}
}

public OnClientPutInServer(client){
	for(new i = 0; i < 7; i++){
		itemBought[client][i] = false;
	}

	g_bBoughtGravity[client] = false;
	g_bIncreasedExp[client] = false;
	g_bIncreasedSpeed[client] = false;
	g_bIncreasedDamage[client] = false;
}


public CodMod_OnGiveExp(attacker, victim, &exp){
	if(g_bIncreasedExp[attacker]){
		exp += (exp / 5);
	}
}

public OnMapEnd(){
	for(new i = 1; i <= MaxClients; i++){
		bought[i] = 0;
	}
}

public void OnMapStart(){
	if (!g_iaGrenadeOffsets[0]) {
		int end = sizeof(g_saGrenadeWeaponNames);
		for (int i=0; i<end; i++) {
			int entindex = CreateEntityByName(g_saGrenadeWeaponNames[i]);
			//DispatchSpawn(entindex);
			g_iaGrenadeOffsets[i] = GetEntProp(entindex, Prop_Send, "m_iPrimaryAmmoType");
			AcceptEntityInput(entindex, "Kill");
		}
	}
}

public BuyItem(client, item){
	if(GetMoney(client) < itemsPrices[item]){
		PrintToChat(client, "%sNie masz wystarczająco pieniędzy aby kupić ten przedmiot!", PREFIX_INFO);
		return;
	}

	if(itemBought[client][item]){
		PrintToChat(client, "%sKupiłeś ten przedmiot w tej rundzie!", PREFIX);
		return;
	}
	SetMoney(client, GetMoney(client) - itemsPrices[item]);
	bought[client] += itemsPrices[item];
	itemBought[client][item] = true;
	switch(item){
		case 0:
		{
			CodMod_Heal(client, client, 50);
		}

		case 1:
		{
			CodMod_GiveRandomPerk(client);
		}

		case 2:
		{
			new String:time[5];
			FormatTime(time, 5, "%H", GetTime());
			new hour = StringToInt(time);
			new random = GetRandomInt(1, 500);
			if(hour >= 23 && hour < 6){
				random += (random / 2);
			}
			CodMod_AddExp(client, random);
			PrintToChat(client, "%sDostałeś \x04 %d expa \x03! ", PREFIX_INFO, random);
		}

		case 3:
		{
			new String:time[5];
			FormatTime(time, 5, "%H", GetTime());
			new hour = StringToInt(time);
			new random = GetRandomInt(500, 1000);
			if(hour >= 23 && hour < 6){
				random += (random / 2);
			}
			CodMod_AddExp(client, random);
			PrintToChat(client, "%sDostałeś \x04 %d expa \x03! ", PREFIX_INFO, random);
		}

		case 4:
		{
			new String:time[5];
			FormatTime(time, 5, "%H", GetTime());
			new hour = StringToInt(time);
			new random = GetRandomInt(1000, 1500);
			if(hour >= 23 && hour < 6){
				random += (random / 2);
			}
			CodMod_AddExp(client, random);
			PrintToChat(client, "%sDostałeś \x04 %d expa \x03! ", PREFIX_INFO, random);
		}

		case 5:
		{
			Lotto(client);

		}


	}

}

stock Lotto(int iClient){
	new iRandom = GetRandomInt(1, 100);
	PrintToChat(iClient, "%sMaszyna losująca ruszyła!", PREFIX_INFO);
	if(iRandom > 55){
		ForcePlayerSuicide(iClient);
		PrintToChat(iClient, "%s Wylosowałeś śmierć.", PREFIX_INFO);
	} else {
		iRandom = GetRandomInt(1, 8);
		switch(iRandom){
			case 1:
			{
				g_bBoughtGravity[iClient] = true;
				PrintToChat(iClient, "%s Wylosowałeś +50 do grawitacji!", PREFIX_INFO);
				CodMod_SetStat(iClient, GRAVITY_PERK, CodMod_GetStat(iClient, GRAVITY_PERK) + 50);
			}

			case 2:
			{
				g_bBoughtGravity[iClient] = true;
				PrintToChat(iClient, "%s Wylosowałeś -50 do grawitacji!", PREFIX_INFO);
				CodMod_SetStat(iClient, GRAVITY_PERK, CodMod_GetStat(iClient, GRAVITY_PERK) - 50);
			}

			case 3:
			{
				int iExp = GetRandomInt(100, 1000);
				CodMod_AddExp(iClient, iExp);
				PrintToChat(iClient, "%s Wylosowałeś +%d expa!", PREFIX_INFO, iExp);
			}

			case 4:
			{
				PrintToChat(iClient, "%s Wylosowałeś losowy perk!", PREFIX_INFO);
				CodMod_GiveRandomPerk(iClient);
			}

			case 5:
			{
				PrintToChat(iClient, "%s Wylosowałeś zwiększenie expa o 20%% na jedną rundę!", PREFIX_INFO);
				g_bIncreasedExp[iClient] = true;
			}

			case 6:
			{
				g_bIncreasedSpeed[iClient] = true;
				PrintToChat(iClient, "%s Wylosowałeś +60 dodatkowej kondycji na rundę!", PREFIX_INFO);
				CodMod_SetStat(iClient, DEX_PERK, CodMod_GetStat(iClient, DEX_PERK) + 60);
			}

			case 7:
			{
				g_bIncreasedDamage[iClient] = true;
				PrintToChat(iClient, "%s Wylosowałeś +10 dmg zadawanych więcej obrażeń!", PREFIX_INFO);
			}

			case 8:
			{
				PrintToChat(iClient, "%s Wylosowałeś losowy granat!", PREFIX_INFO);
				int iGrenade = GetRandomInt(1, sizeof(g_iaGrenadeOffsets));
				int iCounter = 0;
				while(GetEntProp(iClient, Prop_Send, "m_iAmmo", _, g_iaGrenadeOffsets[iGrenade]) && iCounter < 10){
					iGrenade = GetRandomInt(1, sizeof(g_iaGrenadeOffsets));
					iCounter++;
				}
				GivePlayerItem(iClient, g_saGrenadeWeaponNames[iGrenade]);
			}
		}
	}
}

public CodMod_OnPlayerDamaged(attacker, victim, &Float:damage, WeaponID:weaponID, forwardClassId, damageType){
	if(g_bIncreasedDamage[attacker]){
		damage += 10.0;
	}
}
