#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <codmod301>


public Plugin:myinfo = {
    name = "Call of Duty Mod - Perk - Ręce TayreNa",
    author = "th7nder",
    description = "CODMOD's Perk",
    version = "1.0",
    url = "http://th7.eu"
};

new const String:szClassName[NAME_LENGTH] = {"Ręce TayreNa"};
new const String:szDesc[DESC_LENGTH] = {"Masz 1/4 na to, ze po zabiciu będziesz mógł ukraść perk przeciwnika."};
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

    g_bHasItem[iClient] = true;

}


public void CodMod_OnPerkDisabled(int iClient, int iPerkId){
    if(iPerkId != g_iPerkId)
        return;

    g_bHasItem[iClient] = false;
}

public void CodMod_OnPlayerDie(int iAttacker, int iVictim, bool bHeadshot){
    if(g_bHasItem[iAttacker]){
        int iPerk = 0;
        if(GetRandomInt(1, 100) >= 75 && (iPerk = CodMod_GetPerk(iVictim)) != 0)
        {
            Menu hMenu = new Menu(MenuHandler_WannaSteal);
            char szPerkName[64];
            CodMod_GetPerkName(iPerk, szPerkName);
            hMenu.SetTitle("Chcesz ukraść %s?", szPerkName);
            

            char szInfo[128];
            Format(szInfo, 128, "%d|%d", GetClientSerial(iVictim), iPerk);

            hMenu.AddItem(szInfo, "Tak");
            hMenu.AddItem("X", "Nie");

            hMenu.ExitButton = true;
            hMenu.Display(iAttacker, MENU_TIME_FOREVER);
        }
    }
}

public int MenuHandler_WannaSteal(Menu hMenu, MenuAction iAction, int iClient, int iItemPos)
{
    if(iAction == MenuAction_Select)
    {
        if(iItemPos == 1)
        {
            return 0;
        }

        char szInfo[128];
        hMenu.GetItem(iItemPos, szInfo, 128);

        char szData[2][64];
        ExplodeString(szInfo, "|", szData, 2, 64);

        int iSerial = StringToInt(szData[0]);
        int iPerk = StringToInt(szData[1]);
        int iVictim = GetClientFromSerial(iSerial);
        if(iVictim == 0 || !IsValidPlayer(iVictim))
        {
            PrintToChat(iClient, "%s Gracz wyszedł z serwera!", PREFIX_INFO);
            return 0;
        }

        if(CodMod_GetPerk(iVictim) != iPerk)
        {
            PrintToChat(iClient, "%s Perk Twojego przeciwnika się zmienił", PREFIX_INFO);
            return 0;
        }
        CodMod_DestroyPerk(iVictim);
        CodMod_SetPerk(iClient, iPerk, 100);

    }
    else if (iAction == MenuAction_End)
    {
        delete hMenu;
    }
    return 0;
}
