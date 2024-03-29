#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>


#include <codmod301>
public Plugin myinfo = {
    name = "Call of Duty Mod - Perk - Notatki Ninjy",
    author = "th7nder",
    description = "201 Rewrite Perk",
    version = "2.0",
    url = "http://th7.eu"
};

char szClassName[] = {"Notatki Ninjy"};
char szDesc[] = {"Posiadasz podwójny skok."};
int g_iPerkId;


bool g_bHasItem[MAXPLAYERS +1] = {false};


public OnPluginStart(){

    if(LibraryExists(COD_LIBRARY_NAME))
    {
        g_iPerkId = CodMod_RegisterPerk(szClassName, szDesc);
    }
}

public void OnLibraryAdded(const char[] szName)
{
    if(StrEqual(szName, COD_LIBRARY_NAME))
    {
        g_iPerkId = CodMod_RegisterPerk(szClassName, szDesc);
    }
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
    CodMod_SetPlayerInfo(iClient, DOUBLE_JUMP_PERK, 1);
}

public void CodMod_OnPerkDisabled(int iClient, int iPerkId){
    if(iPerkId != g_iPerkId)
        return;

    g_bHasItem[iClient] = false;
    CodMod_SetPlayerInfo(iClient, DOUBLE_JUMP_PERK, 0);
}



