#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <codmod301>


public Plugin myinfo = {
    name = "Call of Duty Mod - Perk - Stalker",
    author = "th7nder",
    description = "201 Rewrite Perk",
    version = "2.0",
    url = "http://th7.eu"
};

char szClassName[] = {"Stalker"};
char szDesc[] = {"Używając (codmod_perk), teleportujesz się za losowego gracza\n 1x na rundę, 12 sec po rozpoczęciu"};
int g_iPerkId;


bool g_bHasItem[MAXPLAYERS +1] = {false};
bool g_bUsed[MAXPLAYERS+1] = {false};


int g_iRoundIndex = 0;
bool g_bAllowed = false;
float g_fTried[MAXPLAYERS] = 0.0;

public void OnPluginStart(){
    g_iPerkId = CodMod_RegisterPerk(szClassName, szDesc);
    HookEvent("round_start", Event_OnRoundStart);
}

public Action Event_OnRoundStart(Event hEvent, const char[] szEvent, bool bBroadcast)
{
    g_bAllowed = false;
    g_iRoundIndex++;
    CreateTimer(12.0, Timer_Allow, g_iRoundIndex);
}

public Action Timer_Allow(Handle hTimer, int iRoundIndex)
{
    if(iRoundIndex != g_iRoundIndex)
    {
        return Plugin_Stop;
    }

    g_bAllowed = true;

    return Plugin_Stop;
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

public void CodMod_OnPlayerSpawn(int iClient)
{
    g_bUsed[iClient] = false;
}


public void CodMod_OnPerkSkillUsed(int iClient){
    if(!IsValidPlayer(iClient) || !IsPlayerAlive(iClient) || !g_bHasItem[iClient])
        return;

    if(g_bUsed[iClient])
    {
        PrintToChat(iClient, "%s Użyłeś już stalkera w tej rundzie!", PREFIX_SKILL);
        return;
    }

    if(!g_bAllowed)
    {
        PrintToChat(iClient, "%s Stalkera możesz użyć 12 sec po rozpoczęciu rundy!", PREFIX_SKILL);
        return;
    }
    if(GetEngineTime() - g_fTried[iClient] < 10.0) {
        PrintToChat(iClient, "%s Ostatnia próba się nie udała, spróbuj po 10 sekundach!", PREFIX_SKILL)
        return;
    }
    int iTries = 0;
    int iTeam = GetClientTeam(iClient);
    int iTarget = -1;
    do
    {
        iTarget = GetRandomTarget(iClient, iTeam);
        iTries++;
    } while(!TeleportBehind(iClient, iTarget) && iTries < 10);

    g_bUsed[iClient] = true;
    if(iTries >= 10)
    {
        PrintToChat(iClient, "%s W tej rundzie nie można znaleźć właściwego targetu, spróbuj za 10 sekund :(", PREFIX_SKILL);
        g_bUsed[iClient] = false;
        g_fTried[iClient] = GetEngineTime();
    }
}


public bool TeleportBehind(int iClient, int iTarget)
{
    float fEyes[3], fOrigin[3], fVelocity[3];
    GetClientEyeAngles(iTarget, fEyes);
    GetAngleVectors(fEyes, fVelocity, NULL_VECTOR, NULL_VECTOR);
    GetClientAbsOrigin(iTarget, fOrigin);
    float fLen = GetVectorLength(fVelocity);

    fOrigin[0] -= fVelocity[0] * 40.0 / fLen;
    fOrigin[1] -= fVelocity[1] * 40.0 / fLen;

    fVelocity[2] = 0.0;
    fVelocity[1] = ArcCosine(fVelocity[0] / fLen) * (1 - 2 * view_as<int>(fVelocity[1] < 0));
    fVelocity[0] = -ArcTangent(fVelocity[2] / fLen);

    if(IsValidPlayerPos(iClient, fOrigin))
    {
        TeleportEntity(iClient, fOrigin, fVelocity, NULL_VECTOR);
        return true;
    }
    
    return false;
}



int GetRandomTarget(int iExclude, int iTeam){
    int iCount = 0;
    int iTargets[MAXPLAYERS+1];
    for(int i = 1; i <= MaxClients; i++){
        if(i != iExclude && IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) != iTeam){
            iTargets[iCount++] = i;
        }
    }

    return iTargets[GetRandomInt(0, iCount - 1)];
}

   /*new Float:vec[3], Float:origin[3]
    velocity_by_aim(target, 1, vec)
    new Float:len = floatsqroot(vec[0]*vec[0]+vec[1]*vec[1])
    
    pev(target, pev_origin, origin)
    origin[0] -= vec[0]*40.0/len
    origin[1] -= vec[1]*40.0/len
    set_pev(id, pev_origin, origin)

    vec[2] = 0.0
    vec[1] = floatacos(vec[0]/len, 1)*(1-2*_:(vec[1]<0))
    vec[0] =-floatatan(vec[2]/len, 1)
    
    set_pev(id, pev_angles, vec)
    set_pev(id, pev_fixangle, 1)*/

