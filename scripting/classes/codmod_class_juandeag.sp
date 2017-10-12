#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <th7manager>
#include <dhooks>
#include <emitsoundany>

#define _IN_CODMOD_CLASS 1
#include <codmod301>
public Plugin myinfo = {
    name = "CodMod 301 - Class - Juan Deag",
    author = "th7nder",
    description = "Juan Deag Class from CodMod 301",
    version = "2.0",
    url = "http://serwery-go.pl"
};

WeaponID g_iWeapons[WEAPON_LIMIT] = {WEAPON_NONE};

#define ADDITIONAL_MULTIPLIER (0.50 - STRENGTH_MULTIPLIER)

bool g_bUsed[MAXPLAYERS+1] = {false};
bool g_bUsing[MAXPLAYERS+1] = {false};

char g_szClassName[128] = {"Juan Deag"};
char g_szDesc[256] = {"110HP, Desert Eagle \n 1/1 w głowę \n Odnawianie magazynka po zabójstwie, 1 siły - 0.5dmg \n \
                        Gdy rzuci Flash zamraża graczy w promieniu 300u na 2 sec(noflash) \ 
                        \n Na codmod_skill blokuje 85%% dmg przez 2 sec, raz na rundę"};
const int g_iHealth = 0;
const int g_iStartingHealth = 110;
const int g_iArmor = 0;
const int g_iDexterity = 0;
const int g_iIntelligence = 0;
int g_iBeamSprite;
int g_iClassId = 0;
bool g_bHasClass[MAXPLAYERS+1]    = {false};
public void OnPluginStart()
{
    g_iWeapons[0] = WEAPON_DEAGLE;
    g_iWeapons[1] = WEAPON_FLASHBANG;
    g_iClassId = CodMod_RegisterClass(g_szClassName, g_szDesc, g_iHealth, g_iArmor, g_iDexterity, g_iIntelligence, g_iWeapons, 0, g_iStartingHealth);
}

public void OnMapStart()
{
    g_iBeamSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
    HookEvent("flashbang_detonate", Event_OnFlashDetoate);
    HookEvent("player_blind", Event_OnFlashPlayer, EventHookMode_Pre);
}

public void OnPluginEnd()
{
    CodMod_UnregisterClass(g_iClassId);
}

public Action:Event_OnFlashPlayer(Event hEvent, const char[] szEvent, bool bDontBroadcast)
{
    int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
    if(g_bHasClass[iClient])
        SetEntPropFloat(iClient, Prop_Send, "m_flFlashMaxAlpha", 0.5);

    return Plugin_Handled;
}

public int CodMod_OnChangeClass(int iClient, int iPrevious, int iNext){
    if(iNext != g_iClassId) {
        g_bHasClass[iClient] = false;
    } else {
        g_bHasClass[iClient] = true;
    }

}

public void CodMod_OnPlayerSpawn(int iClient)
{
    g_bUsed[iClient] = false;
    g_bUsing[iClient] = false;
}

public CodMod_OnPlayerDamaged(int iAttacker, int iVictim, float &fDamage, WeaponID iWeaponID, int iDamageType){
    if(g_bHasClass[iAttacker]){
        fDamage += CodMod_GetWholeStat(iAttacker, STRENGTH) * ADDITIONAL_MULTIPLIER;
        if(iWeaponID == WEAPON_DEAGLE && (iDamageType & DMG_HEADSHOT)){
            fDamage *= 300.0;
        }
    }

    if(g_bHasClass[iVictim] && g_bUsing[iVictim])
    {
        fDamage *= 0.15;
    }
}

public Action Timer_Refill(Handle hTimer, int iSerial)
{
    int iClient = GetClientFromSerial(iSerial);
    if(iClient > 0)
    {
        Player_RefillClip(iClient, -1, 1);
    }
}


public void CodMod_OnPlayerDie(int iAttacker, int victim, bool headshot){
    if(g_bHasClass[iAttacker]){
        CreateTimer(0.00, Timer_Refill, GetClientSerial(iAttacker));
    }
}

public void CodMod_OnClassSkillUsed(int iClient){
    if(!g_bHasClass[iClient] || !IsPlayerAlive(iClient))
        return;
    
    if(g_bUsed[iClient])
    {
        PrintToChat(iClient, "%s Użyłeś już tego skilla w tej rundzie!", PREFIX_SKILL);
        return;
    }
    g_bUsed[iClient] = true;
    g_bUsing[iClient] = true;

    PrintToChat(iClient, "%s Blokujesz 85%% dmg przez 2sec!", PREFIX_SKILL);
    Handle hData = CreateDataPack();
    WritePackCell(hData, GetClientSerial(iClient));
    WritePackCell(hData, CodMod_GetRoundIndex());
    CreateTimer(2.0, Timer_DisableSkill, hData);
}

public Action Timer_DisableSkill(Handle hTimer, Handle hData)
{
    ResetPack(hData);
    int iClient = GetClientFromSerial(ReadPackCell(hData));
    int iRoundIndex = ReadPackCell(hData);
    if(iRoundIndex != CodMod_GetRoundIndex() || !IsValidPlayer(iClient)) return Plugin_Stop;

    g_bUsing[iClient] = false;
    PrintToChat(iClient, "%s Redukcja się skończyła!", PREFIX_SKILL);

    return Plugin_Stop;
}


public void OnEntityCreated(int iEntity, const char[] szClassname)
{
    if(StrEqual(szClassname, "flashbang_projectile"))
    {
        SDKHook(iEntity, SDKHook_SpawnPost, OnFlashgrenadeSpawned);
    }
}

public Action OnFlashgrenadeSpawned(int iEntity)
{
    int iOwner = GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity");
    if(iOwner != -1 && g_bHasClass[iOwner])
    {
        char szName[32];
        GetEntPropString(iEntity, Prop_Data, "m_iName", szName, sizeof(szName));
        if(StrEqual(szName, "cm_justicenade"))
        {
            return Plugin_Continue;
        }
        BeamFollowFunction(iEntity, {75,75,255,255});
    }
    return Plugin_Continue;
}



void BeamFollowFunction(int iEntity, int iColor[4])
{
	TE_SetupBeamFollow(iEntity, g_iBeamSprite, 0, 1.0, 4.0, 2.0, 4, iColor);
	TE_SendToAll();
}

public Event_OnFlashDetoate(Event hEvent, const char[] szBroadcast, bool bBroadcast)
{
    int iEntity = hEvent.GetInt("entityid");
    int iOwner = GetClientOfUserId(hEvent.GetInt("userid"));
    if(g_bHasClass[iOwner]) {
        CodMod_RadiusFreeze(iEntity, 300, 2.0);

        CreateTimer(0.1, Timer_RemoveEntity, EntIndexToEntRef(iEntity));
    }
}


public Action Timer_RemoveEntity(Handle hTimer, int iRef)
{
    int iEntity = EntRefToEntIndex(iRef);
    if(iEntity != INVALID_ENT_REFERENCE)
    {
        AcceptEntityInput(iEntity, "kill");
    }
}


