#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <codmod301>


public Plugin myinfo = {
    name = "Call of Duty Mod - Perk - Dragi Witboya",
    author = "th7nder",
    description = "201 Rewrite Perk",
    version = "2.0",
    url = "http://th7.eu"
};

float g_DrugAngles[20] = {0.0, 5.0, 10.0, 15.0, 20.0, 25.0, 20.0, 15.0, 10.0, 5.0, 0.0, -5.0, -10.0, -15.0, -20.0, -25.0, -20.0, -15.0, -10.0, -5.0};
Handle g_DrugTimers[MAXPLAYERS+1] = {INVALID_HANDLE};

char szClassName[] = {"Dragi Witboya"};
char szDesc[] = {"Na początku rundy dostajesz M4A4 \n +5dmg z M4A4, 1/5 szansy na ućpanie gracza na 5sec"};
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

const WeaponID g_iGiveWeapon = WEAPON_M4A4;
char g_szGiveWeapon[] = "weapon_m4a1";
const int g_iWeaponSlot = 0;
public void CodMod_OnPlayerSpawn(int iClient){
    if(g_bHasItem[iClient]){
        int iEntity = GetPlayerWeaponSlot(iClient, g_iWeaponSlot);
        if(iEntity != -1){
            WeaponID iWeaponID = CodMod_GetWeaponID(iEntity);
            if(iWeaponID != g_iGiveWeapon){
                RemovePlayerItem(iClient, iEntity);
                iEntity = GivePlayerItem(iClient, g_szGiveWeapon);
                EquipPlayerWeapon(iClient, iEntity);
            }
        } else if(iEntity == -1){
            iEntity = GivePlayerItem(iClient, g_szGiveWeapon);
            EquipPlayerWeapon(iClient, iEntity);
        }

    }
}

public void CodMod_OnWeaponCanUsePerk(int iClient, WeaponID iWeaponID, int &iCanUse, bool bBuy){
    if(g_bHasItem[iClient] && g_iGiveWeapon == iWeaponID && !bBuy){
        iCanUse = 2;
    }
}

public void CodMod_OnPlayerDamagedPerk(int iAttacker, int iVictim, float &fDamage, WeaponID iWeaponID, int iDamageType){
    if(g_bHasItem[iAttacker]){
        if(iWeaponID == g_iGiveWeapon){
            fDamage += 5.0;
            if(GetRandomInt(1, 100) >= 80 && g_DrugTimers[iVictim] == null){
                PrintToChatAll("%s %N został naćpany przez Dragi Witboya!", PREFIX_SKILL, iVictim);
                CreateDrug(iVictim);
                CreateTimer(15.0, Timer_KillDrug, GetClientSerial(iVictim));
            }
        }
    }
}



public Action Timer_KillDrug(Handle hTimer, int iClient){
    iClient = GetClientFromSerial(iClient);
    if(IsValidPlayer(iClient) && IsPlayerAlive(iClient)){
        KillDrug(iClient);
    } else if(g_DrugTimers[iClient] != INVALID_HANDLE){
        KillDrugTimer(iClient);
    }
}

KillDrugTimer(client)
{
    if(g_DrugTimers[client] != null){
        KillTimer(g_DrugTimers[client]);
        g_DrugTimers[client] = null;
    }
}


CreateDrug(client)
{
    g_DrugTimers[client] = CreateTimer(1.0, Timer_Drug, client, TIMER_REPEAT);
}


KillDrug(client)
{
    KillDrugTimer(client);

    new Float:angs[3];
    GetClientEyeAngles(client, angs);

    angs[2] = 0.0;

    TeleportEntity(client, NULL_VECTOR, angs, NULL_VECTOR);

    new clients[2];
    clients[0] = client;

    new duration = 1536;
    new holdtime = 1536;
    new flags = (0x0001 | 0x0010);
    new color[4] = { 0, 0, 0, 0 };

    Handle message = StartMessageEx(GetUserMessageId("Fade"), clients, 1);
    if (GetUserMessageType() == UM_Protobuf)
    {
        Protobuf pb = UserMessageToProtobuf(message);
        pb.SetInt("duration", duration);
        pb.SetInt("hold_time", holdtime);
        pb.SetInt("flags", flags);
        pb.SetColor("clr", color);
    }
    else
    {
        BfWrite bf = UserMessageToBfWrite(message);
        bf.WriteShort(duration);
        bf.WriteShort(holdtime);
        bf.WriteShort(flags);
        bf.WriteByte(color[0]);
        bf.WriteByte(color[1]);
        bf.WriteByte(color[2]);
        bf.WriteByte(color[3]);
    }

    EndMessage();
}


public Action Timer_Drug(Handle:timer, any:client)
{
    if (!IsClientInGame(client))
    {
        KillDrugTimer(client);

        return Plugin_Handled;
    }

    if (!IsPlayerAlive(client))
    {
        KillDrug(client);

        return Plugin_Handled;
    }

    new Float:angs[3];
    GetClientEyeAngles(client, angs);

    angs[2] = g_DrugAngles[GetRandomInt(0,100) % 20];

    TeleportEntity(client, NULL_VECTOR, angs, NULL_VECTOR);

    new clients[2];
    clients[0] = client;

    new duration = 255;
    new holdtime = 255;
    new flags = 0x0002;
    new color[4] = { 0, 0, 0, 128 };
    color[0] = GetRandomInt(0,255);
    color[1] = GetRandomInt(0,255);
    color[2] = GetRandomInt(0,255);

    Handle message = StartMessageEx(GetUserMessageId("Fade"), clients, 1);
    if (GetUserMessageType() == UM_Protobuf)
    {
        Protobuf pb = UserMessageToProtobuf(message);
        pb.SetInt("duration", duration);
        pb.SetInt("hold_time", holdtime);
        pb.SetInt("flags", flags);
        pb.SetColor("clr", color);
    }
    else
    {
        BfWriteShort(message, duration);
        BfWriteShort(message, holdtime);
        BfWriteShort(message, flags);
        BfWriteByte(message, color[0]);
        BfWriteByte(message, color[1]);
        BfWriteByte(message, color[2]);
        BfWriteByte(message, color[3]);
    }

    EndMessage();

    return Plugin_Handled;
}
