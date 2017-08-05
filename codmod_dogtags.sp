#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>

#include <codmod301>

#define GetEventClient(%1) GetClientOfUserId(hEvent.GetInt(%1))
#define CHAT_PREFIX_SG "  \x06[\x0BSerwery\x01-\x07GO\x06] "

#pragma newdecls required
/* DROP TABLE IF EXISTS `codmod_dogtags`;
CREATE TABLE `codmod_dogtags` (
  `steamid` varchar(128) NOT NULL,
  `name` varchar(128) DEFAULT NULL,
  `dogtags` int(10) DEFAULT NULL,
  PRIMARY KEY (`steamid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8; */


public Plugin myinfo =  {
	name = "Nieśmiertelniki",
	author = "th7nder",
	description = "Nieśmiertelniki",
	version = "0.01",
	url = "http://serwery-go.pl"
};


int g_iPlayerDogtags[MAXPLAYERS + 1] =  { -1 };
bool g_bFullyLoaded[MAXPLAYERS + 1] =  { false };
bool g_bDoubleExp[MAXPLAYERS+1] = {false};
Handle g_hDatabase = INVALID_HANDLE;


bool g_bSuperHE[MAXPLAYERS+1] = {false};
bool g_bStartedLoading[MAXPLAYERS+1] = {false};

char g_szShopItems[][] =  {
	"Regeneracja perku [10 NŚM]",
	"Zwiększenie EXPa o 25% na mapę [100 NŚM]",
	"HE 1/2 na kill [20 NŚM]",
	"10 000 EXPa [100 NŚM]",
	"5 000 EXPa [50 NŚM]",
	"Losowy Perk [15 NŚM]"
}

int g_iShopPrices[] =  {
	10,
	100,
	20,
	100,
	50,
	15
}

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] szError, int iErr){
    CreateNative("CodMod_SetDogtagCount", Native_SetDogtagCount);
    CreateNative("CodMod_GetDogtagCount", Native_GetDogtagCount);
    return APLRes_Success;
}

public void OnPluginStart() {
	HookEvent("player_death", Event_OnPlayerDeath);

	HookEvent("bomb_planted", Event_Map);
	HookEvent("bomb_defused", Event_Map);
	HookEvent("hostage_rescued", Event_Map);
	HookEvent("round_mvp", Event_OnRoundMVP);

	RegConsoleCmd("nsm", Command_Dogtags);
	RegConsoleCmd("n", Command_Dogtags);
	RegConsoleCmd("dt", Command_Dogtags);
	RegConsoleCmd("dogtags", Command_Dogtags);


	SQL_TConnect(Callback_Connect, "codmod_dogtags");
}

public void OnPluginEnd() {
	delete g_hDatabase;
}

public int Native_SetDogtagCount(Handle hPlugin, int iNumParams){
	int iClient = GetNativeCell(1);
	int iAmount = GetNativeCell(2);

	g_iPlayerDogtags[iClient] = iAmount;
	return 0;
}


public int Native_GetDogtagCount(Handle hPlugin, int iNumParams){
	int iClient = GetNativeCell(1);
	return g_iPlayerDogtags[iClient];
}

public void Callback_Connect(Handle hOwner, Handle hResult, const char[] szError, any aData) {
	if (hResult == INVALID_HANDLE || strlen(szError) > 2) {
		LogError("TH7 NŚM: Connect Error %s", szError);
		return;
	}

	g_hDatabase = CloneHandle(hResult);
	SQL_SetCharset(g_hDatabase, "utf8");

	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !g_bStartedLoading[i] && !IsFakeClient(i) && !IsClientSourceTV(i))
		{
			OnClientPutInServer(i);
		}
	}
}



public void OnClientPutInServer(int iClient) {
	if(IsFakeClient(iClient) || IsClientSourceTV(iClient)) return;
	if(g_hDatabase == null)
	{
		g_bStartedLoading[iClient] = false;
		return;
	}

	g_bStartedLoading[iClient] = true;
	g_bFullyLoaded[iClient] = false;
	g_iPlayerDogtags[iClient] = -1;
	SQL_LoadDogtags(iClient);
	g_bSuperHE[iClient] = false;
	g_bDoubleExp[iClient] = false;
}

public void OnClientDisconnect(int iClient) {
	if(IsFakeClient(iClient) || IsClientSourceTV(iClient)) return;

	g_bStartedLoading[iClient] = false;
	if (g_bFullyLoaded[iClient]) {
		SQL_SaveDogtags(iClient, g_iPlayerDogtags[iClient]);
	}

}

public bool GiveDogtags(int iClient, int iAmount) {
	if( GetClientCount(true) < 5) {
		PrintToChat(iClient, "%sOtrzymywanie NSM jest dostępne od 4 graczy!", CHAT_PREFIX_SG)
		return false;
	}
	g_iPlayerDogtags[iClient] += iAmount;
	return true;
}


public Action Event_OnPlayerDeath(Event hEvent, char[] szEvent, bool bBroadcast) {
	int iAttacker = GetEventClient("attacker");
	int iVictim = GetEventClient("userid");
	bool bHeadshot = hEvent.GetBool("headshot");

	if (!IsValidPlayer(iAttacker) || !g_bFullyLoaded[iAttacker] || !IsValidPlayer(iVictim) || iAttacker == iVictim)
		return Plugin_Continue;

	int iAttackerTeam = GetClientTeam(iAttacker);
	int iVictimTeam = GetClientTeam(iVictim);

	if( iAttackerTeam == iVictimTeam)
		return Plugin_Continue;

	if(GetPlayerCount() < 5)
	{
		return Plugin_Continue;
	}

	char szWeapon[64];
	hEvent.GetString("weapon", szWeapon, 64);
	WeaponID iWeaponID = CodMod_GetWeaponIDByName(szWeapon);

	int iDogtags = 1;
	if(iWeaponID == WEAPON_HEGRENADE || iWeaponID == WEAPON_INCGRENADE || iWeaponID == WEAPON_MOLOTOV)
	{
		iDogtags = 3;
		PrintToChat(iAttacker, "%sOtrzymałeś %d nieśmiertelników za zabójstwo granatem!", CHAT_PREFIX_SG, iDogtags);
	}
	else if(bHeadshot)
	{
		iDogtags = 2;
		PrintToChat(iAttacker, "%sOtrzymałeś %d nieśmiertelników za zabójstwo headshotem!", CHAT_PREFIX_SG, iDogtags);
	}
	else
	{
		PrintToChat(iAttacker, "%sOtrzymałeś %d nieśmiertelników za zabójstwo", CHAT_PREFIX_SG, iDogtags);
	}

	GiveDogtags(iAttacker, iDogtags);



	return Plugin_Continue;
}

public Action Event_Map(Event hEvent, const char[] szName, bool bBroadcast){
	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
	if(GiveDogtags(iClient, 5))
		PrintToChat(iClient, "%sOtrzymałeś 5 nieśmiertelników za wykonywanie celów mapy!", CHAT_PREFIX_SG);
}


public Action Event_OnRoundMVP(Event hEvent, const char[] szName, bool bBroadcast){
	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
	if(GiveDogtags(iClient, 2))
		PrintToChat(iClient, "%sOtrzymałeś 2 nieśmiertelniki za bycie MVP!", CHAT_PREFIX_SG);
}
public void SQL_SaveDogtags(int iClient, int iDogtags) {
	g_bFullyLoaded[iClient] = false;
	char szPlayerName[32], szEscapedName[128], szAuthID[64];
	if (!GetClientName(iClient, STRING(szPlayerName)) || !GetClientAuthId(iClient, AuthId_Steam2, STRING(szAuthID)) || !SQL_EscapeString(g_hDatabase, szPlayerName, STRING(szEscapedName)))
		return;
	ReplaceString(STRING(szAuthID), "STEAM_0", "STEAM_1");

	char szQuery[512];
	Format(STRING(szQuery), "INSERT INTO `codmod_dogtags` VALUES ('%s', '%s', %d) ON DUPLICATE KEY UPDATE `name`='%s', `dogtags`=%d", szAuthID, szEscapedName, iDogtags, szEscapedName, iDogtags);
	SQL_TVoid(g_hDatabase, szQuery);
}


public void SQL_LoadDogtags(int iClient) {
	char szAuthID[64];
	if (!GetClientAuthId(iClient, AuthId_Steam2, STRING(szAuthID)))
		return;

	ReplaceString(STRING(szAuthID), "STEAM_0", "STEAM_1");

	char szQuery[128];
	Format(STRING(szQuery), "SELECT `dogtags` FROM `codmod_dogtags` WHERE `steamid`='%s'", szAuthID);
	SQL_TQuery(g_hDatabase, Callback_Load, szQuery, GetClientSerial(iClient));
}

public void Callback_Load(Handle hOwner, Handle hResult, const char[] szError, int iClient) {
	if (hResult == INVALID_HANDLE || strlen(szError) > 2) {
		LogError("TH7 NŚM: FetchQuery ERROR, %s", szError);
	} else {
		iClient = GetClientFromSerial(iClient);
		if (!IsValidPlayer(iClient)) {
			return;
		}

		if (SQL_FetchRow(hResult)) {
			g_iPlayerDogtags[iClient] = SQL_FetchInt(hResult, 0);
		} else {
			g_iPlayerDogtags[iClient] = 0;
		}
		CloseHandle(hResult);
		g_bFullyLoaded[iClient] = true;
	}
}


public Action Command_Dogtags(int iClient, int iArgs) {
	if (IsClientInGame(iClient)) {
		Panel_Dogtags(iClient);
	}

	return Plugin_Handled;
}

public void Panel_Dogtags(int iClient) {
	Panel hPanel = new Panel();
	SetPanelTitleEx(hPanel, "Sklep z Nieśmiertelnikami - Serwery-GO.pl [%d NŚM]", g_iPlayerDogtags[iClient]);
	int iSize = sizeof(g_iShopPrices);
	for (int i = 0; i < iSize; i++) {
		hPanel.DrawItem(g_szShopItems[i]);
	}
	hPanel.DrawItem("Wyjście");

	hPanel.Send(iClient, Handler_MainBuy, 20);
}

public int Handler_MainBuy(Menu hMenu, MenuAction iAction, int iClient, int iItem) {
	if (iAction == MenuAction_Select) {
		if(iItem != 7)
			BuyItem(iClient, iItem);
	} else if (iAction == MenuAction_End) {
		delete hMenu;
	}
}

public void BuyItem(int iClient, int iItem) {
	if (!IsPlayerAlive(iClient)) {
		PrintToChat(iClient, "%sMusisz być żywy aby korzystać ze sklepu!", CHAT_PREFIX_SG);
		return;
	}

	if (!g_bFullyLoaded[iClient]) {
		PrintToChat(iClient, "%sTwoje dane nie zostały jeszcze w pełni załadowane!", CHAT_PREFIX_SG);
		return;
	}

	if (g_iPlayerDogtags[iClient] < g_iShopPrices[iItem - 1]) {
		PrintToChat(iClient, "%sNie masz wystarczającej ilości nieśmiertelników!", CHAT_PREFIX_SG);
		return;
	}


	switch (iItem) {

		case 1:
		{
			CodMod_SetPlayerInfo(iClient, PERK_ARMOR, 100);
			PrintToChat(iClient, "%sZregenerowałeś perk do 100%% wytrzymałości!", CHAT_PREFIX_SG);
		}

		case 2:
		{
			if(g_bDoubleExp[iClient])
			{
				PrintToChat(iClient, "%sMasz już zwiększonego expa!", CHAT_PREFIX_SG);
				return;
			}
			g_bDoubleExp[iClient] = true;
			PrintToChat(iClient, "%sOtrzymałeś zwiększenie expa o 25%%!", CHAT_PREFIX_SG);
		}

		case 3:
		{

			if(CodMod_GetPlayerNades(iClient, TH7_HE)){
            	PrintToChat(iClient, "%sMasz już HE!", CHAT_PREFIX_SG);
            	return;
        	}

			GivePlayerItem(iClient, "weapon_hegrenade");
			PrintToChat(iClient, "%sOtrzymałeś HE, z którego masz 1/2!", PREFIX);
			g_bSuperHE[iClient] = true;
		}

		case 4:
		{

			CodMod_GiveExp(iClient, 10000);
			PrintToChat(iClient, "%sOtrzymałeś 10000 doświadczenia!", CHAT_PREFIX_SG);
		}
		case 5:
		{


			CodMod_GiveExp(iClient, 5000);
			PrintToChat(iClient, "%sOtrzymałeś 5000 doświadczenia!", CHAT_PREFIX_SG);
		}

		case 6:
		{
			CodMod_GiveRandomPerk(iClient);
			PrintToChat(iClient, "%sOtrzymałeś losowy perk!", CHAT_PREFIX_SG);
		}
	}

	g_iPlayerDogtags[iClient] -= g_iShopPrices[iItem - 1];

}


public void CodMod_OnPlayerDamaged(int iAttacker, int iVictim, float &fDamage, WeaponID iWeaponID, int iDamageType){
    if(g_bSuperHE[iAttacker]){
        if((iWeaponID == WEAPON_HEGRENADE)){
            fDamage *= 300.0;
        }
        g_bSuperHE[iAttacker] = false;
    }
}


public void CodMod_OnGiveExpMultiply(int iClient, float &fMultiply){
	if(g_bDoubleExp[iClient]){
		fMultiply += 0.25;
	}
}

stock int GetPlayerCount()
{
    int sum = 0;
    for(int i = 1; i <= MaxClients; i++)
    {
        if(IsClientInGame(i) && (GetClientTeam(i) == CS_TEAM_T || GetClientTeam(i) == CS_TEAM_CT))
        {
            sum++;
        }
    }

    return sum;
}


public void SQL_TVoid(Handle db, char[] query)
{
	Handle data = CreateDataPack();
	WritePackString(data, query);
	ResetPack(data);
	SQL_TQuery(db, SQLCallback_Void_PrintQuery, query, data);
}

public void SQLCallback_Void_PrintQuery(Handle owner, Handle hndl, const char[] error, any data)
{
	if(hndl == INVALID_HANDLE || strlen(error) > 2)
	{
		char query[2048];
		ReadPackString(data, STRING(query));
		LogError("SQL error happened.\nQuery: %s\nError: %s", query, error);
	}
	CloseHandle(data);
}

stock void SetPanelTitleEx(Handle menu, char[] display, any ...)
{
	char m_display[256];
	VFormat(m_display, sizeof(m_display), display, 3);
	SetPanelTitle(menu, m_display);
}
