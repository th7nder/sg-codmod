#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>

#include <emitsoundany>

#define _IN_CODMOD_CLASS 1
#define MEDKITS 1
#define MAX_MEDKITS 2 + (CodMod_GetWholeStat(iClient, INT) / 50)
#define HEAL_MEDKIT_FORMULA 10 + (CodMod_GetWholeStat(iClient, INT) / 5)
int g_iHaloSprite, g_iBeamSprite;
#include <codmod301>

Handle g_hSkillTimers[MAXPLAYERS+1] = {INVALID_HANDLE};

public Plugin myinfo = {
    name = "CodMod 301 - Class - Medyk",
    author = "th7nder",
    description = "Medyk Class from CodMod 301",
    version = "2.0",
    url = "http://serwery-go.pl"
};

WeaponID g_iWeapons[WEAPON_LIMIT] = {WEAPON_NONE};


int g_iRessurected[MAXPLAYERS+1] = {0};


char g_szClassName[128] = {"Medyk"};
char g_szDesc[128] = {"120HP, MP9, Glock(+5dmg) \n2x(+1/50INT) Apteczka(10HP + 0,2/1INT), 5sec co 1sec\nWskrzeszenie(max. 5)\n 2x Healthshot"};
const int g_iHealth = 0;
const int g_iStartingHealth = 120;
const int g_iArmor = 0;
const int g_iDexterity = 0;
const int g_iIntelligence = 0;
int g_iClassId = 0;
bool g_bHasClass[MAXPLAYERS+1]    = {false};

int g_iMedkits[MAXPLAYERS+1] = {0};


public void OnPluginStart(){
    g_iWeapons[0] = WEAPON_MP9;
    g_iWeapons[1] = WEAPON_GLOCK;
    g_iWeapons[2] = WEAPON_HEALTHSHOT;
    g_iWeapons[3] = WEAPON_HEALTHSHOT;
    g_iClassId = CodMod_RegisterClass(g_szClassName, g_szDesc, g_iHealth, g_iArmor, g_iDexterity, g_iIntelligence, g_iWeapons, 0, g_iStartingHealth);
}

public void OnPluginEnd(){
    CodMod_UnregisterClass(g_iClassId);
}

public void KillSkillTimer(int iClient){
    if(g_hSkillTimers[iClient] != INVALID_HANDLE){
        KillTimer(g_hSkillTimers[iClient]);
        g_hSkillTimers[iClient] = INVALID_HANDLE;
    }


    if(IsClientInGame(iClient) && IsPlayerAlive(iClient)){
        SetEntProp(iClient, Prop_Send, "m_iProgressBarDuration", 0);
    }
}

public void OnClientDisconnect(int iClient){
    KillSkillTimer(iClient);
    SDKUnhook(iClient, SDKHook_WeaponSwitch, SDK_OnWeaponSwitch);
}

public void OnClientPutInServer(int iClient){
    KillSkillTimer(iClient);
    SDKHook(iClient, SDKHook_WeaponSwitch, SDK_OnWeaponSwitch);
}


public void OnMapStart(){
    g_iBeamSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
    g_iHaloSprite = PrecacheModel("materials/sprites/halo.vmt");
}

public int CodMod_OnChangeClass(int iClient, int iPrevious, int iNext){
    if(iNext != g_iClassId) {
        g_bHasClass[iClient] = false;
    } else {
        g_bHasClass[iClient] = true;
    }

    g_iMedkits[iClient] = 0;
    g_iRessurected[iClient] = 0;
    KillSkillTimer(iClient);
}

public void CodMod_OnPlayerSpawn(int iClient){
    if(g_bHasClass[iClient]){
        g_iMedkits[iClient] = 0;
        g_iRessurected[iClient] = 0;
    }
}


public void CodMod_OnClassSkillUsed(int iClient){
    if(!g_bHasClass[iClient] || !IsPlayerAlive(iClient))
        return;

    int iMaxMedkits = MAX_MEDKITS;
    if(g_iMedkits[iClient] + 1 <= iMaxMedkits){
        g_iMedkits[iClient]++;
        PrintToChat(iClient, "%s Postawiłeś apteczkę! Zostały Ci %d apteczki", PREFIX_SKILL, iMaxMedkits - g_iMedkits[iClient]);
        Place_MedKit(iClient, 5.0, 1.0);
    } else {
        PrintToChat(iClient, "%s Wykorzystałeś już %d apteczki w tej rundzie!", PREFIX_SKILL, iMaxMedkits)
    }
}

public Action SDK_OnWeaponSwitch(int iClient, int iWeapon){
	if(g_bHasClass[iClient] && IsPlayerAlive(iClient) && g_iRessurected[iClient] + 1 <= 5){
		if(CodMod_GetWeaponID(iWeapon) != WEAPON_KNIFE){
			SetEntProp(iClient, Prop_Send, "m_iProgressBarDuration", 0);
			KillSkillTimer(iClient);
		} else {
			StartSkillTimer(iClient);
		}
	}
	return Plugin_Continue;
}

public void StartSkillTimer(int iClient){
    float fPos[3];
    GetClientAbsOrigin(iClient, fPos);
    int iTarget = FindClosestRagdoll(fPos, GetClientTeam(iClient), iClient);
    if(IsValidPlayer(iTarget)){
        SetEntPropFloat(iClient, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
        SetEntProp(iClient, Prop_Send, "m_iProgressBarDuration", 3);

        Handle hPack = CreateDataPack();
        WritePackCell(hPack, GetClientSerial(iClient));
        WritePackCell(hPack, GetClientSerial(iTarget));
        g_hSkillTimers[iClient] = CreateTimer(3.0, Timer_Resurrect, hPack);
    }
}

public Action Timer_Resurrect(Handle hTimer, Handle hPack){
    ResetPack(hPack);
    int iClient = GetClientFromSerial(ReadPackCell(hPack));
    int iTarget = GetClientFromSerial(ReadPackCell(hPack));
    delete hPack;

    if(!IsValidPlayer(iClient) || !IsValidPlayer(iTarget) || IsPlayerAlive(iTarget) || !IsPlayerAlive(iClient)){
        g_hSkillTimers[iClient] = INVALID_HANDLE;
        KillSkillTimer(iClient);
        return Plugin_Stop;
    }

    int iRagdoll = GetEntPropEnt(iTarget, Prop_Send, "m_hRagdoll");
    if(iRagdoll == -1 || !IsValidEntity(iRagdoll)){
        g_hSkillTimers[iClient] = INVALID_HANDLE;
        KillSkillTimer(iClient);
        return Plugin_Stop;
    }

    float fPos[3];
    GetEntPropVector(iRagdoll, Prop_Data, "m_vecOrigin", fPos);
    CS_RespawnPlayer(iTarget);
    RemoveEdict(iRagdoll);
    fPos[2] += 3.0;
    if(IsValidPlayerPosEx(iTarget, fPos) != 0){
      TeleportEntity(iTarget, fPos, NULL_VECTOR, NULL_VECTOR);
    }

    PrintToChatAll("%s %N został wskrzeszony przez %N!", PREFIX_SKILL, iTarget, iClient);
    int iRandom = GetRandomInt(50, 150);
    PrintToChat(iClient, "%s Otrzymałeś %d expa za wskrzeszenie i 1 nieśmiertelnik!", PREFIX_SKILL, iRandom);
    CodMod_GiveExp(iClient, iRandom);
    CodMod_SetDogtagCount(iClient, CodMod_GetDogtagCount(iClient) + 1);

    g_iRessurected[iClient]++;
    g_hSkillTimers[iClient] = INVALID_HANDLE;
    KillSkillTimer(iClient);
    return Plugin_Stop;
}

public Action OnPlayerRunCmd(int iClient, int &iButtons, int &iImpulse, float fVel[3], float fAngles[3], int &iWeapon) {
    if(g_bHasClass[iClient] && (iButtons & IN_JUMP || iButtons & IN_FORWARD || iButtons & IN_BACK || iButtons & IN_MOVELEFT || iButtons & IN_MOVERIGHT)){
        KillSkillTimer(iClient);
    }

    return Plugin_Continue;
}


public void CodMod_OnWeaponCanUse(client, WeaponID iWeaponID, &canUse, bool bBuy)
{
    if(g_bHasClass[client])
    {
        if(iWeaponID == WEAPON_HEALTHSHOT)
        {
            canUse = 2;
        }
    }
    
}