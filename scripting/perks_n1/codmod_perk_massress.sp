#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <codmod301>



public Plugin:myinfo = {
        name = "Call of Duty Mod - Perk - Mass Ress",
        author = "th7nder",
        description = "CODMOD's Perk",
        version = "1.0",
        url = "http://th7.eu"
};

new const String:szClassName[NAME_LENGTH] = {"Mass Ress"};
new const String:szDesc[256] = {"Wskrzeszasz wszystkich martwych członków twojego teamu.\ndostajesz bazowe 800 expa + 100 za każdego kolejnego wskrzeszonego.\n Niszczy sie po użyciu."};
new g_iPerkId;

new bool:g_bHasItem[MAXPLAYERS +1] = {false};

public OnPluginStart(){
        g_iPerkId = CodMod_RegisterPerk(szClassName, szDesc);
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

        if(GetRandomInt(1, 100) <= 80)
        {
                CodMod_DestroyPerk(iClient);
                PrintToChat(iClient, "%s Otrzymałeś mass ress bez mocy wksrzeszania!", PREFIX_INFO);
        } else {
                g_bHasItem[iClient] = true;
        }



}

public CodMod_OnPerkDisabled(iClient, iPerkId){
        if(iPerkId != g_iPerkId)
                return;

        g_bHasItem[iClient] = false;
}



public void CodMod_OnPerkSkillUsed(int iClient){
        if(!IsValidPlayer(iClient) || !IsPlayerAlive(iClient) || !g_bHasItem[iClient])
                return;

        int iTeam = GetClientTeam(iClient);
        int iExp = 800;
        PrintToChatAll("%s %N użył Mass Ressa!", PREFIX_INFO, iClient);
        int iExpAdded = 0;
        int iRessurected = 0;
        for(int i = 1; i <= MaxClients; i++)
        {
                if(IsClientInGame(i) && !IsPlayerAlive(i) && GetClientTeam(i) == iTeam)
                {
                        CS_RespawnPlayer(i);
                        iRessurected++;
                        iExpAdded += iExp;
                        iExp += 100;
                }
        }

        CodMod_DestroyPerk(iClient);


        PrintToChat(iClient, "%s Otrzymałeś %d expa za wksrzeszenie %d graczy!", PREFIX_INFO, CodMod_GiveExp(iClient, iExpAdded), iRessurected);
}
