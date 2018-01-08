#include <sourcemod>
#include <cstrike>



stock void FireItemEvent(int iClient, const char[] szWeapon)
{
        Handle hEvent = CreateEvent("item_purchase"); 
        if (hEvent != INVALID_HANDLE) 
        { 
                SetEventInt(hEvent, "userid", GetClientUserId(iClient))
                SetEventInt(hEvent, "team", GetClientTeam(iClient)); // victim 
                SetEventString(hEvent, "weapon", szWeapon); // weapon name 
                FireEvent(hEvent, true); 
        }  
}


public Action Command_Buytest(int iClient, int iArgs)
{
        CS_RespawnPlayer(iClient);
}

public Action Command_TakeMoney(int iClient, int iArgs)
{
        SetEntProp(iClient, Prop_Send, "m_iAccount", 16000);
}


public Action Command_Fire(int iClient, int iArgs)
{
        FireItemEvent(iClient, "weapon_galilar");
}
public void OnPluginStart()
{
        RegConsoleCmd("buytest", Command_Buytest);
        RegConsoleCmd("takemoney", Command_TakeMoney);
        RegConsoleCmd("firevent", Command_Fire);
        HookEvent("item_purchase", Event_OnItemPurchased);
}

public Action Event_OnItemPurchased(Event hEvent, const char[] szBroadcast, bool bBroadcast)
{
        int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
        char szItem[32];
        hEvent.GetString("weapon", szItem, sizeof(szItem));
        PrintToChatAll("boight item: %s", szItem);

        return Plugin_Continue;
}