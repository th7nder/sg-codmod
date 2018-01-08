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
    name = "CodMod 301 - Class - Lekki Snajper",
    author = "th7nder",
    description = "Lekki Snajper Class from CodMod 301",
    version = "2.0",
    url = "http://serwery-go.pl"
};

WeaponID g_iWeapons[WEAPON_LIMIT] = {WEAPON_NONE};

#define ADDITIONAL_MULTIPLIER 0.9 - STRENGTH_MULTIPLIER


char g_szClassName[128] = {"Lekki Snajper"};
char g_szDesc[256] = {"140HP, Scout, USP(18 naboi) \n 1/3 na potrójny damage ze scouta, \n Zmniejszona grawitacja \n 1 siły - 0.9dmg, 50%% widoczności"};
const int g_iHealth = 0;
const int g_iStartingHealth = 140;
const int g_iArmor = 0;
const int g_iDexterity = 20;
const int g_iIntelligence = 0;
int g_iClassId = 0;
bool g_bHasClass[MAXPLAYERS+1]    = {false};

int g_iGetMaxClip1Offset = 353;
Handle g_hGetMaxClip1 = null;

public void OnPluginStart(){
    g_iWeapons[0] = WEAPON_SSG08;
    g_iWeapons[1] = WEAPON_USP;
    g_iClassId = CodMod_RegisterClass(g_szClassName, g_szDesc, g_iHealth, g_iArmor, g_iDexterity, g_iIntelligence, g_iWeapons, 0, g_iStartingHealth);
    CodMod_RegisterClassGravity(g_szClassName, 80);

    g_hGetMaxClip1 = DHookCreate(g_iGetMaxClip1Offset, HookType_Entity, ReturnType_Int, ThisPointer_CBaseEntity, DHook_OnGetMaxClip1);

    for(int i = 1; i <= MaxClients; i++)
    {
        if(IsClientInGame(i))
        {
            OnClientPutInServer(i);
        }
    }
}

public void OnPluginEnd(){
    CodMod_UnregisterClass(g_iClassId);
}

public void OnClientPutInServer(int client)
{
    SDKHook(client, SDKHook_WeaponDropPost, Hook_OnWeaponDropPost);
}


public int CodMod_OnChangeClass(int iClient, int iPrevious, int iNext){
    if(iPrevious == g_iClassId){
        TH7_DisableRenderColor(iClient);
    }
    if(iNext != g_iClassId) {
        g_bHasClass[iClient] = false;
    } else {
        g_bHasClass[iClient] = true;
        TH7_SetRenderColor(iClient, 255, 255, 255, 190);
    }


}

public void CodMod_OnPlayerDamaged(int iAttacker, int iVictim, float &fDamage, WeaponID iWeaponID, int iDamageType){
    if(g_bHasClass[iAttacker]){

        if(iWeaponID == WEAPON_SSG08){
            fDamage += CodMod_GetWholeStat(iAttacker, STRENGTH) * ADDITIONAL_MULTIPLIER;
            if(GetRandomInt(1, 100) >= 67){
                fDamage *= 3.0;
            }
        }
    }
}


public void OnEntityCreated(int iEntity, const char[] szClassname)
{
    if(iEntity >= 2048)
        return;


    if(StrContains(szClassname, "weapon_") != -1 && szClassname[6] == '_')
    {
        SDKHook(iEntity, SDKHook_SpawnPost, SDK_OnSpawn);
    }

}

public Action SDK_OnSpawn(int iEntity)
{
    char szWeapon[64];
    GetRealWeaponName(iEntity, szWeapon, sizeof(szWeapon));
    if(StrEqual(szWeapon, "weapon_usp_silencer"))
    {
        DHookEntity(g_hGetMaxClip1, true, iEntity);
    }
}


public MRESReturn DHook_OnGetMaxClip1(int iWeapon, Handle hReturn)
{
    int iClient = GetEntPropEnt(iWeapon, Prop_Send, "m_hOwnerEntity");
    if(iClient <= 0 || !g_bHasClass[iClient])
    {
        return MRES_Ignored;
    }

    DHookSetReturn(hReturn, 18);
        

    return MRES_Supercede;
}


public void Hook_OnWeaponDropPost(int iClient, int iWeapon)
{
    if(!g_bHasClass[iClient])
        return;

    char szWeapon[64];
    GetRealWeaponName(iWeapon, szWeapon, sizeof(szWeapon));
    if(StrEqual(szWeapon, "weapon_usp_silencer"))
    {
        int iClip1 = GetEntProp(iWeapon, Prop_Data, "m_iClip1");
        if(iClip1 > 12)
        {
            iClip1 = 12;
            SetEntProp(iWeapon, Prop_Data, "m_iClip1", iClip1)
        }
    }
    
    return;
}

