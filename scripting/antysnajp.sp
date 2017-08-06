#include <sourcemod>
#include <sdkhooks>
#include <timers>
#include <sdktools> 
#include <cstrike>
#include <codmod301>

bool first25Seconds = false;
bool inBuyZone[64] = false;
Handle g_hTimer = null;
bool mapSniperRestricted = false;

public void OnMapStart(){
	decl String:currentMap[64];
	GetCurrentMap(currentMap, sizeof(currentMap));
	mapSniperRestricted = StrEqual(currentMap, "de_dust_2002_v1");
	
	if (mapSniperRestricted) {
		HookEvent("round_start", roundStart, EventHookMode_Post);		
		HookEvent("enter_buyzone", Enter_BuyZone, EventHookMode_Post);
		HookEvent("exit_buyzone", Exit_BuyZone, EventHookMode_Post);
		HookEvent("round_end", roundEnd, EventHookMode_Post);
	}
}


public Action:Enter_BuyZone(Handle:event, const String:name[], bool:dontBroadcast){
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    inBuyZone[client] = true;
}

public Action:Exit_BuyZone(Handle:event, const String:name[], bool:dontBroadcast){
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    inBuyZone[client] = false;
}  

public Action roundStart(Handle:event, const String:name[], bool:dontBroadcast){
	if(mapSniperRestricted)
	{
		first25Seconds = true;
		g_hTimer = CreateTimer(25.0, allowSnipers);
	}
	return Plugin_Continue;
}

public Action roundEnd(Handle:event, const String:name[], bool:dontBroadcast){
	first25Seconds = false;
	if (g_hTimer != INVALID_HANDLE){
		CloseHandle(g_hTimer);
		g_hTimer = INVALID_HANDLE;
	}
}


public void CodMod_OnPlayerDamaged(int iAttacker, int iVictim, float &fDamage, WeaponID iWeaponID, int iDamageType){
    if(first25Seconds && inBuyZone[iVictim] && inBuyZone[iAttacker])
    {
    	if(iWeaponID == WEAPON_SSG08 || iWeaponID == WEAPON_AWP || iWeaponID == WEAPON_G3SG1 || iWeaponID == WEAPON_SCAR20)
    	{
    		fDamage = 0.0;
			PrintToChat(iAttacker, "Nie możesz strzelać ze snajperki na respa przed upływem 25 sek!");
    	}
    }
}

public Action allowSnipers(Handle timer){
	PrintToChatAll("25 sekund upłynęło, można już strzelać ze snajperek!");
	first25Seconds = false;
	g_hTimer = INVALID_HANDLE;
	return Plugin_Handled;
}

public void OnMapEnd(){
	UnhookEvent("round_start", roundStart, EventHookMode_Post);		
	UnhookEvent("enter_buyzone", Enter_BuyZone, EventHookMode_Post);
	UnhookEvent("exit_buyzone", Exit_BuyZone, EventHookMode_Post);
	UnhookEvent("round_end", roundEnd, EventHookMode_Post);
}