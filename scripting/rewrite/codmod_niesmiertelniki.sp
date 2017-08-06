#include <sourcemod>
#include <cstrike>
#include <entity>
#include <sdktools>
#include <sdkhooks>
#include <codmod301>
#include <smlib>
#include <emitsoundany>

#define ARRAY_LENGTH 255
#define ITEM_LIMIT 10

new Handle:hDatabase;
new bullets[MAXPLAYERS + 1] = {0};
new items[ITEM_LIMIT] = {0};
new bool:doubleExp[MAXPLAYERS + 1] = {false};
new String:doubleExpAuths[MAXPLAYERS + 1][64];
new Handle:g_timeLeftTimer = INVALID_HANDLE;



bool g_bSuperHE[MAXPLAYERS+1] = {false};
bool g_bLoaded[MAXPLAYERS+1] = {false};
public Plugin:myinfo = {
	name = "Call of Duty Mod - Nieśmiertelniki",
	author = "th7nder",
	description = "CODMOD's Nieśmiertelniki",
	version = "1.0",
	url = "http://th7.eu"
};


public int Native_SetDogtagCount(Handle hPlugin, int iNumParams){
	int iClient = GetNativeCell(1);
	int iAmount = GetNativeCell(2);

	bullets[iClient] = iAmount;
	return 0;
}


public int Native_GetDogtagCount(Handle hPlugin, int iNumParams){
	int iClient = GetNativeCell(1);

	return bullets[iClient];
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max){
    CreateNative("CodMod_GiveEverlasting", Native_GiveEverlasting);
    CreateNative("CodMod_SetDogtagCount", Native_SetDogtagCount);
    CreateNative("CodMod_GetDogtagCount", Native_GetDogtagCount);
    return APLRes_Success;
}



public int Native_GiveEverlasting(Handle hPlugin, int iNumParams){
	int iClient = GetNativeCell(1);
	int iAmount = GetNativeCell(2);

	bullets[iClient] += iAmount;
	PrintToChat(iClient, "%s Otrzymałeś %d nieśmiertelników", PREFIX_INFO, iAmount);
	return 0;
}

new boughtItems[MAXPLAYERS +1][6];

public OnPluginStart(){
	SQL_Initialize();
	RegConsoleCmd("n", Shop);
	RegConsoleCmd("niesmiertelniki", Shop);
	RegConsoleCmd("nsm", Shop);
	RegServerCmd("codmod_addgoldenbullets", Server_AddGoldenBullets);
	items[0] = 10;
	items[1] = 100;
	items[2] = 20;
	items[3] = 100;
	items[4] = 50;
	items[5] = 15;

	for(new i = 0; i <= MaxClients; i++){
		Format(doubleExpAuths[i], 64, "NULL");
		boughtItems[i][0] = false;
		boughtItems[i][1] = false;
		boughtItems[i][2] = false;
		boughtItems[i][3] = false;
		boughtItems[i][4] = false;
		boughtItems[i][5] = false;
	}

	HookEvent("bomb_planted", Event_Map);
	HookEvent("bomb_defused", Event_Map);
	HookEvent("hostage_rescued", Event_Map);
	HookEvent("round_mvp", Event_OnRoundMVP);
	HookEvent("player_death", Event_OnPlayerDie);
}
public Event_Map(Handle:event, const String:name[], bool:broadcast){
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	bullets[client] += 5;
	PrintToChat(client, "%sOtrzymałeś 5 nieśmiertelników za wykonywanie celów mapy!", PREFIX_INFO);
}

public Event_OnRoundMVP(Handle:event, const String:name[], bool:broadcast){
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	bullets[client] += 1;
	PrintToChat(client, "%sOtrzymałeś 1 nieśmiertelnik za bycie MVP!", PREFIX_INFO);

}

public OnMapStart(){
	g_timeLeftTimer = CreateTimer(5.0, TimeLeftChanged, _, TIMER_REPEAT);
}

public OnMapEnd(){
	for(new i = 0; i <= MaxClients; i++){
		Format(doubleExpAuths[i], 64, "NULL");
	}
	if(g_timeLeftTimer != INVALID_HANDLE)
		KillTimer(g_timeLeftTimer);
}


public Action:TimeLeftChanged(Handle:timer){
	new time;
	if (GetMapTimeLeft(time) && time <= 10){
		GiveTop3();
		g_timeLeftTimer = INVALID_HANDLE;
		return Plugin_Stop;
	}
	return Plugin_Continue;

}

stock GiveTop3(){
	/*if(GetClientCount() < 8){
		PrintToChatAll("%sAby TOP3 graczy dostało dodatkowe doświadczenie musi być co najmniej 8 graczy!", PREFIX);
		return;
	}


	new playerScores[MAXPLAYERS + 1] = {0};
	for(new i = 1; i <= MaxClients; i++) {
		if(!IsClientConnected(i) || !IsClientInGame(i)) continue;
		playerScores[i] = CS_GetClientContributionScore(i);
	}

	new top1 = 0;
	new score = -1;
	for(new i = 1; i <= MaxClients; i++){
		if(playerScores[i] >= score){
			top1 = i;
			score = playerScores[i];
		}
	}

	score = -1;
	new top2 = 0;
	for(new i = 1; i <= MaxClients; i++){
		if(playerScores[i] >= score && i != top1){
			top2 = i;
			score = playerScores[i];
		}
	}

	score = -1;
	new top3 = 0;
	for(new i = 1; i <= MaxClients; i++){
		if(playerScores[i] >= score && i != top1 && i != top2){
			top3 = i;
			score = playerScores[i];
		}
	}


	new amount = 3000;
	decl String:playerName[128];


	CodMod_GiveGoldenBullets(top1, 3);
	PrintToChat(top1, "%sOtrzymałeś 10 Nieśmietelników za bycie TOP1 na mapie!", PREFIX);

	GetClientName(top1, playerName, 128);
	PrintToChatAll("%sGracz %s otrzymał \x04 %d doświadczenia \x04 za bycie TOP1 na mapie!", PREFIX_INFO, playerName, amount);
	CodMod_GiveExp(top1, amount);


	CodMod_GiveGoldenBullets(top2, 2);

	PrintToChat(top2, "%sOtrzymałeś 7 Nieśmiertelników za bycie TOP2 na mapie!", PREFIX);

	amount = 2000;
	GetClientName(top2, playerName, 128);
	PrintToChatAll("%sGracz %s otrzymał \x04 %d doświadczenia \x04 za bycie TOP2 na mapie!", PREFIX_INFO, playerName, amount);
	CodMod_GiveExp(top2, amount);

	CodMod_GiveGoldenBullets(top3, 1);
	PrintToChat(top3, "%sOtrzymałeś 5 Nieśmiertelników za bycie TOP3 na mapie!", PREFIX);

	amount = 1000;
	GetClientName(top3, playerName, 128);
	PrintToChatAll("%sGracz %s otrzymał \x04 %d doświadczenia \x04 za bycie TOP3 na mapie!", PREFIX_INFO, playerName, amount);
	CodMod_GiveExp(top3, amount);*/
}




public OnClientDisconnect(client){
	if(g_bLoaded[client]){
		new String:auth[48];
		GetClientAuthId(client, AuthId_Steam2, auth, 48);

		new String:checkQuery[ARRAY_LENGTH];
		Format(checkQuery, ARRAY_LENGTH, "SELECT amount FROM `codmod_goldenbullets` WHERE `player_sid`='%s'", auth);


		new Handle:hData = CreateDataPack();
		WritePackCell(hData, bullets[client]);
		WritePackString(hData, auth);
		SQL_TQuery(hDatabase, SaveBulletsCallback, checkQuery, hData, DBPrio_High);
	}

	doubleExp[client] = false;
}

public SaveBulletsCallback(Handle:owner, Handle:hndl, const String:error[], any:data){
	new Handle:hData = data;
	ResetPack(hData);
	new amount = ReadPackCell(hData);
	new String:auth[32];
	ReadPackString(hData, auth, 32);

	CloseHandle(hData);
	if (hndl == INVALID_HANDLE)
	{
		new String:insertQuery[ARRAY_LENGTH];
		Format(insertQuery, ARRAY_LENGTH, "INSERT INTO `codmod_goldenbullets` (`player_sid`, `amount`) VALUES ('%s', 0)", auth);
		SQL_DirectQuery(insertQuery);
	} else {
		if(SQL_FetchRow(hndl)){
			new String:updateQuery[ARRAY_LENGTH];
			Format(updateQuery, ARRAY_LENGTH, "UPDATE `codmod_goldenbullets` SET `amount`=%d WHERE `player_sid`='%s'", amount, auth);
			SQL_DirectQuery(updateQuery);
		} else {
			new String:insertQuery[ARRAY_LENGTH];
			Format(insertQuery, ARRAY_LENGTH, "INSERT INTO `codmod_goldenbullets` (`player_sid`, `amount`) VALUES ('%s', 0)", auth);
			SQL_DirectQuery(insertQuery);
		}
	}
}


public CodMod_OnPlayerSpawn(client){
	boughtItems[client][0] = false;
	boughtItems[client][1] = false;
	boughtItems[client][2] = false;
	boughtItems[client][3] = false;
	boughtItems[client][4] = false;
	boughtItems[client][5] = false;
	g_bSuperHE[client] = false;
	if(doubleExp[client]){
		PrintToChat(client, "%sZdobywane przez Ciebie doświadczenie jest zwiększone o 50 procent!", PREFIX_INFO);
	}
}

public OnClientPutInServer(client){
	g_bLoaded[client] = false;
	bullets[client] = 0;

	if(IsFakeClient(client)){
		return;
	}

	for(new i = 0; i <= MaxClients; i++){
		boughtItems[i][0] = false;
		boughtItems[i][1] = false;
		boughtItems[i][2] = false;
		boughtItems[i][3] = false;
		boughtItems[i][4] = false;
		boughtItems[i][5] = false;
	}

	decl String:auth[64];
	GetClientAuthId(client, AuthId_Steam2, auth, 64);
	if(StrEqual(auth, doubleExpAuths[client])){
		doubleExp[client] = true;
	} else {
		doubleExp[client] = false;
	}


	new String:checkQuery[ARRAY_LENGTH];
	Format(checkQuery, ARRAY_LENGTH, "SELECT amount FROM `codmod_goldenbullets` WHERE `player_sid`='%s'", auth);
	SQL_TQuery(hDatabase, AssignBulletsCallback, checkQuery, GetClientSerial(client), DBPrio_Normal);
}


public AssignBulletsCallback(Handle:owner, Handle:hndl, const String:error[], any:client){
	client = GetClientFromSerial(client)
	if(!IsValidPlayer(client))
		return;
	new String:auth[64];
	GetClientAuthId(client, AuthId_Steam2, auth, 64);
	new String:insertQuery[ARRAY_LENGTH];
	Format(insertQuery, ARRAY_LENGTH, "INSERT INTO `codmod_goldenbullets` (`player_sid`, `amount`) VALUES ('%s', 0)", auth);
	if (hndl == INVALID_HANDLE) {
		SQL_DirectQuery(insertQuery);
	} else {
		if(SQL_FetchRow(hndl)){
			bullets[client] = SQL_FetchInt(hndl, 0);
		} else {
			SQL_DirectQuery(insertQuery);
		}

		g_bLoaded[client] = true;
	}
}
public CodMod_OnGiveExpMultiply(client, &Float:multiply){
	if(doubleExp[client]){
		multiply += 0.25;
	}
}

public Action:Shop(client, args) {
	if(!IsPlayerAlive(client)){
		PrintToChat(client, "%sJak jesteś martwy, nie możesz korzystać ze Sklepu Nieśmiertelników.", PREFIX_INFO);
		return Plugin_Handled;
	}

	if(GameRules_GetProp("m_bWarmupPeriod") == 1) {
		PrintToChat(client, "%sNie możesz korzystać ze sklepu Nieśmiertelników podczas rozgrzewki.", PREFIX);
		return Plugin_Handled;
	}

	/*if(GetClientCount() < 5){
		PrintToChat(client, "%sNie możesz korzystać ze Sklepu Złotych Nabojów gdy jest mniej niż 5 graczy!", PREFIX);
		return Plugin_Handled;
	}*/

	new Handle:menu = CreateMenu(Shop_Handler, MENU_ACTIONS_ALL);
	SetMenuTitle(menu, "%s %d NŚM", "Sklep Nieśmietelników - Posiadasz: ", bullets[client]);
	AddMenuItem(menu, "0", "Regeneracja Perku - 10 NŚM");
	AddMenuItem(menu, "1", "Zwiększenie otrzymywanego expa o 25% na jedną mapę - 100 NŚM");
	AddMenuItem(menu, "2", "HE 1/2 - 20 NŚM");
	AddMenuItem(menu, "3", "10K EXPa - 100 NŚM");
	AddMenuItem(menu, "4", "5K EXPa - 50 NŚM");
	AddMenuItem(menu, "5", "Losowy Perk - 15 NŚM");


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

public void OnEntityCreated(int iEntity, const char[] szClassname){
	if(StrEqual(szClassname, "hegrenade_projectile")){
		SDKHook(iEntity, SDKHook_SpawnPost, OnGrenadeSpawn);
	}
}

public void OnGrenadeSpawn(int iGrenade)
{
	CreateTimer(0.01, ChangeGrenadeDamage, iGrenade, TIMER_FLAG_NO_MAPCHANGE);
}

public Action ChangeGrenadeDamage(Handle hTimer, int iEntity)
{
	int iOwner = GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity");
	if(iOwner != -1 && IsValidPlayer(iOwner) && GetRandomInt(1, 100) >= 50 && g_bSuperHE[iOwner]){
		SetEntPropFloat(iEntity, Prop_Send, "m_flDamage", 3000.0);
		g_bSuperHE[iOwner] = false;
	}



}

public BuyItem(client, item){
	if(bullets[client] < 0){
		bullets[client] = 0;
	}
	if(bullets[client] < items[item]){
		PrintToChat(client, "%sNie masz wystarczająco Nieśmietelników aby kupić ten przedmiot! Zakupu możesz dokonać na: \x07 sklep.serwery-go.pl", PREFIX_INFO);
		return;
	}

	if(boughtItems[client][item]){
		PrintToChat(client, "%sKupiłeś przedmiot w tej rundzie!", PREFIX);
		return;
	}

	boughtItems[client][item] = true;
	decl String:auth[64];
	GetClientAuthId(client, AuthId_Steam2, auth, 64);
	switch(item){
		case 0:
		{
			CodMod_SetPlayerInfo(client, PERK_ARMOR, 100);
			PrintToChat(client, "%sWytrzymałość Twojego perku znów wynosi 100!", PREFIX);
		}
		case 1:
		{
			if(doubleExp[client]){
				PrintToChat(client, "%sMasz już aktywny zwiększony exp!", PREFIX_INFO);
				return;
			}

			doubleExp[client] = true;
			Format(doubleExpAuths[client], 64, auth);
			PrintToChat(client, "%sAktywowałeś zwiększenie zdobywania doświadczenia o 50 procent!", PREFIX);
		}

		case 2:
		{
			GivePlayerItem(client, "weapon_hegrenade");
			PrintToChat(client, "%sOtrzymałeś HE, z którego masz 1/2!", PREFIX);
			g_bSuperHE[client] = true;
		}

		case 3:
		{


			CodMod_GiveExp(client, 10000);
			PrintToChat(client, "%sOtrzymałeś 10000 doświadczenia!", PREFIX);
		}
		case 4:
		{


			CodMod_GiveExp(client, 5000);
			PrintToChat(client, "%sOtrzymałeś 5000 doświadczenia!", PREFIX);
		}

		case 5:
		{
			CodMod_GiveRandomPerk(client);
			PrintToChat(client, "%sOtrzymałeś losowy perk!", PREFIX);
		}

	}
	bullets[client] -= items[item];
	decl String:updateQuery[ARRAY_LENGTH];
	Format(updateQuery, ARRAY_LENGTH, "UPDATE `codmod_goldenbullets` SET `amount`=`amount`-%d WHERE `player_sid`='%s'", items[item], auth);
	SQL_DirectQuery(updateQuery);

}




public Action:Event_OnPlayerDie(Handle:event, const String:name[], bool:broadcast){
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new bool:headshot = GetEventBool(event, "headshot");

	if(attacker == 0 || victim == 0 || attacker == victim || IsFakeClient(attacker))
		return Plugin_Handled;
	decl String:sWeapon[64];
	GetEventString(event, "weapon", sWeapon, 64);

	WeaponID weaponID = CodMod_GetWeaponIDByName(sWeapon);
	if(weaponID == WEAPON_HEGRENADE || weaponID == WEAPON_MOLOTOV || weaponID == WEAPON_INCGRENADE){
		bullets[attacker] += 2;
		PrintToChat(attacker, "%sOtrzymałeś 2 nieśmiertelniki za zabójstwo granatem!", PREFIX_INFO);
	} else if(headshot) {
		bullets[attacker] += 2;
		PrintToChat(attacker, "%sOtrzymałeś 2 nieśmiertelniki za zabójstwo headshotem!", PREFIX_INFO);
	} else {
		bullets[attacker] += 1;
		PrintToChat(attacker, "%sOtrzymałeś 1 nieśmiertelnik za zabójstwo!", PREFIX_INFO);
	}


	return Plugin_Handled;
}



stock GetClientBulletsFromDB(client, const String:auth[]){
	decl String:getQuery[ARRAY_LENGTH];
	Format(getQuery, ARRAY_LENGTH, "SELECT amount FROM `codmod_goldenbullets` WHERE `player_sid`='%s'", auth);
	new Handle:result = SQL_HandleQuery(getQuery);
	if(SQL_FetchRow(result)){
		CloseHandle(result);
		return SQL_FetchInt(result, 0);
	}
	CloseHandle(result);
	return 0;
}



public Action:Server_AddGoldenBullets(args){
	if(args < 2){
		PrintToServer("AddGoldenBullets: to low arguments");
		return Plugin_Handled;
	}

	new String:auth[255];
	GetCmdArg(1, auth, 255);
	new String:amountString[255];
	GetCmdArg(2, amountString, 255);
	new amount = StringToInt(amountString);

	new String:sQuery[ARRAY_LENGTH];
	Format(sQuery, ARRAY_LENGTH, "INSERT INTO `codmod_goldenbullets` (`player_sid`, `amount`) VALUES ('%s', 0) ON DUPLICATE KEY UPDATE amount = %d", auth, amount);

	return Plugin_Handled;
}


public CodMod_GiveGoldenBullets(client, amount){
	new String:auth[48];
	GetClientAuthId(client, AuthId_Steam2, auth, 48);

	new String:checkQuery[ARRAY_LENGTH];
	Format(checkQuery, ARRAY_LENGTH, "SELECT amount FROM `codmod_goldenbullets` WHERE `player_sid`='%s'", auth);


	new Handle:hData = CreateDataPack();
	WritePackCell(hData, client);
	WritePackCell(hData, amount);
	SQL_TQuery(hDatabase, GoldenBulletsCallback, checkQuery, hData, DBPrio_Normal);
}

public GoldenBulletsCallback(Handle:owner, Handle:hndl, const String:error[], any:data){
	new Handle:hData = data;
	ResetPack(hData);
	new client = ReadPackCell(hData);
	new amount = ReadPackCell(hData);

	CloseHandle(hData);


	new String:auth[48];
	GetClientAuthId(client, AuthId_Steam2, auth, 48);
	if (hndl == INVALID_HANDLE)
	{
		new String:insertQuery[ARRAY_LENGTH];
		Format(insertQuery, ARRAY_LENGTH, "INSERT INTO `codmod_goldenbullets` (`player_sid`, `amount`) VALUES ('%s', 0)", auth);
		SQL_DirectQuery(insertQuery);
	} else {
		if(SQL_FetchRow(hndl)){
			new String:updateQuery[ARRAY_LENGTH];
			Format(updateQuery, ARRAY_LENGTH, "UPDATE `codmod_goldenbullets` SET `amount`=`amount`+%d WHERE `player_sid`='%s'", amount, auth);
			SQL_DirectQuery(updateQuery);
		} else {
			new String:insertQuery[ARRAY_LENGTH];
			Format(insertQuery, ARRAY_LENGTH, "INSERT INTO `codmod_goldenbullets` (`player_sid`, `amount`) VALUES ('%s', 0)", auth);
			SQL_DirectQuery(insertQuery);
		}
	}
}

/****************************************************** TOOLS ************************************/
stock SQL_Initialize(){
	decl String:error[ARRAY_LENGTH];
	hDatabase = SQL_DefConnect(error, ARRAY_LENGTH);
	if(hDatabase == INVALID_HANDLE){
		PrintToServer("Error in SQL_Initialize: %s", error);
	} else {
		SQL_DirectQuery("CREATE TABLE IF NOT EXISTS `codmod_goldenbullets` (`id` int(11) NOT NULL AUTO_INCREMENT, `player_sid` varchar(255) DEFAULT NULL, `amount` int(8) DEFAULT NULL, PRIMARY KEY (`id`)) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8");
	}
}




/****************************************************** TOOLS ************************************/
stock String:SQL_Escape(String:string[]){
	decl String:escaped[ARRAY_LENGTH];
	SQL_EscapeString(hDatabase, string, escaped, sizeof(escaped));
	return escaped;
}


public EmptyCallback(Handle:owner, Handle:hndl, const String:error[], any:client){
	if (hndl == INVALID_HANDLE){
		LogError("ZJEBAO SIE, %s", error);
		return;
	}
}

stock bool:SQL_DirectQuery(const String:query[]){
	SQL_TQuery(hDatabase, EmptyCallback, query, 0, DBPrio_High);
	return true;
}
