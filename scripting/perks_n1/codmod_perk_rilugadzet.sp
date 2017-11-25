#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <codmod301>


public Plugin myinfo = {
    name = "Call of Duty Mod - Perk - RiluGadzet",
    author = "th7nder",
    description = "201 Rewrite Perk",
    version = "2.0",
    url = "http://th7.eu"
};

int g_iSwitches[MAXPLAYERS+1] = {0};

char szClassName[] = {"RiluGadzet"};
char szDesc[] = {"AK47(+5dmg), Molotov(2x dmg) \n1/12 na spowolnienie gracza o 40% z AK \nZamiana z miejscami na codmod_perk"};
int g_iPerkId;


float g_fRoundStarted = 0.0;
bool g_bHasItem[MAXPLAYERS +1] = {false};
bool g_bSlow[MAXPLAYERS+1] = {false};
float g_fLastUse[MAXPLAYERS+1] = {0.0};

public void OnPluginStart(){
    g_iPerkId = CodMod_RegisterPerk(szClassName, szDesc);
    HookEvent("round_start", Event_OnRoundStart);
}

public Action Event_OnRoundStart(Event hEvent, char[] szEventName, bool bBroadcast){
    g_fRoundStarted = GetGameTime();
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

const WeaponID g_iGiveWeapon = WEAPON_AK47;
char g_szGiveWeapon[] = "weapon_ak47";
const int g_iWeaponSlot = 0;
public void CodMod_OnPlayerSpawn(int iClient){
    g_bSlow[iClient] = false;
    if(g_bHasItem[iClient]){
        g_iSwitches[iClient] = 0;
        g_fLastUse[iClient] = 0.0;
        if(CodMod_GetPlayerNades(iClient, TH7_MOLOTOV) < 1){
            GivePlayerItem(iClient, "weapon_molotov");
        }
       
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
        if(iWeaponID == WEAPON_AK47){
            fDamage += 5.0;
            if(!g_bSlow[iVictim] && GetRandomInt(1, 100) >= 83)
            {
                PrintToChat(iVictim, "%s Zostałeś spowolniony!", PREFIX_SKILL);
                PrintToChat(iAttacker, "%s Spowolniłeś %N!", PREFIX_SKILL, iVictim);
                g_bSlow[iVictim] = true;
                Handle hPack = CreateDataPack();
                CodMod_ChangeStat(iVictim, DEX_PERK, -40);
                WritePackCell(hPack, GetClientSerial(iVictim));
                WritePackCell(hPack, CodMod_GetRoundIndex());
                CreateTimer(2.0, Timer_Unslow, hPack);

            }
        }

        if(iWeaponID == WEAPON_MOLOTOV)
        {
            fDamage *= 2.0;
        }
    }
}

public Action Timer_Unslow(Handle hTimer, Handle hPack)
{
        ResetPack(hPack);
        int iSerial = ReadPackCell(hPack);
        int iRoundIndex = ReadPackCell(hPack);
        delete hPack;
        int iClient = GetClientFromSerial(iSerial);
        if(!IsValidPlayer(iClient)) return Plugin_Stop;

        if(IsPlayerAlive(iClient))
        {
                if(CodMod_GetRoundIndex() == iRoundIndex)
                {
                        g_bSlow[iClient] = false;
                        PrintToChat(iClient, "%s Poruszasz sie juz normalnie", PREFIX_SKILL);
                }       

                CodMod_ChangeStat(iClient, DEX_PERK, 40);
        }

        return Plugin_Stop;
}



public void CodMod_OnPerkSkillUsed(int iClient){
    if(!g_bHasItem[iClient] || !IsPlayerAlive(iClient))
        return;

    if(GetGameTime() - g_fRoundStarted < 10.0){
        PrintToChat(iClient, "%s Możesz używać zamiany 10 sec po starcie rundy!", PREFIX_SKILL);
        return;
    }


    int iMaxSwitches = 1;
    if(g_iSwitches[iClient] + 1 <= iMaxSwitches){
        if(GetGameTime() - g_fLastUse[iClient] < 5.0){
            PrintToChat(iClient, "%s Możesz używać zamiany co 5 sec!", PREFIX_SKILL);
            return;
        }


        int iTargetTeam = GetClientTeam(iClient) == CS_TEAM_T ? CS_TEAM_CT : CS_TEAM_T;
        int iTarget;
        float targetOrigin[3];
        float currentOrigin[3];
        int iCounter = 0;
        do {
            iTarget = GetRandomAliveTarget(iClient, iTargetTeam);
            if(CodMod_GetImmuneToSkills(iTarget))
            {
                iCounter++;
                if(iCounter > 6){
                    PrintToChat(iClient, "%s Nie znaleziono blisko odpowiedniego przeciwnika!", PREFIX_SKILL);
                    return;
                }
                continue;
            } 
            if(!IsValidPlayer(iTarget)) {
                continue;
            }   
            GetClientAbsOrigin(iTarget, targetOrigin);
            GetClientAbsOrigin(iClient, currentOrigin);
            iCounter++;
            if(iCounter > 6){
                PrintToChat(iClient, "%s Nie znaleziono blisko odpowiedniego przeciwnika!", PREFIX_SKILL);

                return;
            }

        } while(GetVectorDistance(currentOrigin, targetOrigin) >= 700.0);

        if(CodMod_GetImmuneToSkills(iTarget))
        {
            PrintToChat(iClient, "%s Nie znaleziono blisko odpowiedniego przeciwnika!", PREFIX_SKILL);
            return;
        }
        g_iSwitches[iClient]++;
        PrintToChat(iClient, "%s Zamieniłeś się miejscami! Zostało Ci %d zamian", PREFIX_SKILL, iMaxSwitches - g_iSwitches[iClient]);
        g_fLastUse[iClient] = GetGameTime();
        SwitchPlaces(iClient, iTarget);
    } else {
        PrintToChat(iClient, "%s Wykorzystałeś już %d zamian tej rundzie!", PREFIX_SKILL, iMaxSwitches)
    }
}

int GetRandomAliveTarget(int iExclude, int iTeam){
    int iCount = 0;
    int iTargets[MAXPLAYERS+1];
    for(int i = 1; i <= MaxClients; i++){
        if(i != iExclude && IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == iTeam){
            iTargets[iCount++] = i;
        }
    }

    return iTargets[GetRandomInt(0, iCount - 1)];
}

public void SwitchPlaces(int iClient, int iTarget){
    if(IsValidPlayer(iTarget) && GetClientTeam(iClient) != GetClientTeam(iTarget)){
        float targetOrigin[3];
        float currentOrigin[3];
        GetClientAbsOrigin(iTarget, targetOrigin);
        GetClientAbsOrigin(iClient, currentOrigin);
        /*if(GetVectorDistance(targetOrigin, currentOrigin) >= 1200.0 + (float(CodMod_GetWholeStat(iClient, INT) * 10))  ){
            PrintToChat(iClient, "%sPrzeciwnik jest za daleko!", PREFIX_SKILL);
            return;
        }*/

        TeleportEntity(iClient, targetOrigin, NULL_VECTOR, NULL_VECTOR);
        TeleportEntity(iTarget, currentOrigin, NULL_VECTOR, NULL_VECTOR);
        PrintToChat(iClient, "%sZostałeś zamieniony miejscami!", PREFIX);
        PrintToChat(iTarget, "%sZostałeś zamieniony miejscami!", PREFIX);
    }
}

