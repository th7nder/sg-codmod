#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <dhooks>
//#include <th7manager>

#include <emitsoundany>

bool g_bHooked[2048 + 1] = {false};
#define _IN_CODMOD_CLASS 1
#include <codmod301>
public Plugin myinfo = {
    name = "CodMod 301 - Class - Striker",
    author = "th7nder",
    description = "Striker Class from CodMod 301",
    version = "2.0",
    url = "http://serwery-go.pl"
};

WeaponID g_iWeapons[WEAPON_LIMIT] = {WEAPON_NONE};
int g_iHeals[MAXPLAYERS+1] = {0};


char g_szClassName[128] = {"Striker [Premium]"};
char g_szDesc[256] = {"120HP, MP7, P250 \n No-Recoil na MAC10, 10HP za killa oraz ammo \n +5dmg ze wszystkiego, codmod_special - heal o 70HP"};
const int g_iHealth = 0;
const int g_iStartingHealth = 120;
const int g_iArmor = 0;
const int g_iDexterity = 0;
const int g_iIntelligence = 0;
int g_iClassId = 0;
bool g_bHasClass[MAXPLAYERS+1]    = {false};
Handle g_hGetInaccuracy = INVALID_HANDLE;
#define FUNCTION_OFFSET 466
public void OnPluginStart(){
    g_hGetInaccuracy = DHookCreate(FUNCTION_OFFSET, HookType_Entity, ReturnType_Float, ThisPointer_CBaseEntity, DHook_GetInaccuracy);

    g_iWeapons[0] = WEAPON_MP7;
    g_iWeapons[1] = WEAPON_P250;
    for(int i = 1; i<= MaxClients; i++)
    {
        if(IsClientInGame(i))
        {
            OnClientPutInServer(i);
        }
    }
    g_iClassId = CodMod_RegisterClass(g_szClassName, g_szDesc, g_iHealth, g_iArmor, g_iDexterity, g_iIntelligence, g_iWeapons, ADMFLAG_CUSTOM3, g_iStartingHealth);
}

public void OnPluginEnd(){
    CodMod_UnregisterClass(g_iClassId);
}

public OnEntityCreated(int iEntity, const String:szClassname[]){
    if(iEntity > 0 && iEntity < 2048){
        g_bHooked[iEntity] = false;
    }
}

public int CodMod_OnChangeClass(int iClient, int iPrevious, int iNext){
    if(iNext != g_iClassId) {
        g_bHasClass[iClient] = false;
    } else {
        g_bHasClass[iClient] = true;
    }
}



public CodMod_OnPlayerDamaged(int iAttacker, int iVictim, float &fDamage, WeaponID iWeaponID, int iDamageType){
    if(g_bHasClass[iAttacker]){
        fDamage += 5.0;
    }
}

public Action Timer_Refill(Handle hTimer, int iSerial)
{
    int iClient = GetClientFromSerial(iSerial);
    if(iClient > 0)
    {
        Player_RefillClip(iClient, -1, 0);
    }
}


public void CodMod_OnPlayerDie(int iAttacker, int iVictim, bool bHeadshot){
    if(g_bHasClass[iAttacker]){
        CodMod_Heal(iAttacker, iAttacker, 10);
        CreateTimer(0.00, Timer_Refill, GetClientSerial(iAttacker));
    }
}

public CodMod_OnPlayerSpawn(int iClient){
    g_iHeals[iClient] = 0;
    int iEntity = GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
    if(g_bHasClass[iClient] && iEntity != -1 && CodMod_GetWeaponID(iEntity) == WEAPON_MAC10)
    {
        SetClientNoRecoil(iClient);
    }
}


public void CodMod_OnClassSkillUsed(int iClient){
    if(!g_bHasClass[iClient] || !IsPlayerAlive(iClient))
        return;

    int iMaxHeals = 1;
    if(g_iHeals[iClient] + 1 <= iMaxHeals){
        g_iHeals[iClient]++;
        PrintToChat(iClient, "%s Uleczyłeś się! Zostało Ci %d uleczeń", PREFIX_SKILL, iMaxHeals - g_iHeals[iClient]);
        CodMod_Heal(iClient, iClient, 70);
    } else {
        PrintToChat(iClient, "%s Wykorzystałeś już wszystkie uleczenia w tej rundzie!", PREFIX_SKILL);
    }
}



public void OnClientPutInServer(int iClient)
{
    SDKHook(iClient, SDKHook_WeaponSwitch, SDK_OnWeaponEquip);
    SDKHook(iClient, SDKHook_PostThinkPost, OnPostThinkPost);
}

public void OnClientDisconnet(int iClient)
{
    SDKUnhook(iClient, SDKHook_WeaponSwitch, SDK_OnWeaponEquip);
}



void HookWeapon(int iClient, int iWeapon){
    if(iWeapon > 0 && iWeapon < 2048 && IsValidEntity(iWeapon)){ 
        if(g_bHasClass[iClient] && !g_bHooked[iWeapon]){
            g_bHooked[iWeapon] = true;
            DHookEntity(g_hGetInaccuracy, true, iWeapon);
        }
    }
}


public Action SDK_OnWeaponEquip(int iClient, int iWeapon){
    if(g_bHasClass[iClient] && CodMod_GetWeaponID(iWeapon) == WEAPON_MAC10)
    {
        SetClientNoRecoil(iClient);
        HookWeapon(iClient, iWeapon);
    }
    else if(g_bHasClass[iClient])
    {
        SetClientRecoil(iClient);
    }
    return Plugin_Continue;
}

public MRESReturn DHook_GetInaccuracy(int pThis, Handle hReturn){
    int iOwner = GetEntPropEnt(pThis, Prop_Send, "m_hOwnerEntity");
    if(hReturn != INVALID_HANDLE && iOwner != -1){
        if(g_bHasClass[iOwner]){
            DHookSetReturn(hReturn, 0.0);
            return MRES_Override;
        }
    }
    return MRES_Ignored;
}


public OnPostThinkPost(iClient){
    if(g_bHasClass[iClient] && IsPlayerAlive(iClient)){
        int iEntity = GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
        if(CodMod_GetWeaponID(iEntity) != WEAPON_MAC10) return;
        if(iEntity != -1 && IsValidEdict(iEntity)){
            SetEntPropFloat(iEntity, Prop_Send, "m_fAccuracyPenalty", 0.0);
        }


        SetEntProp(iClient, Prop_Send, "m_iShotsFired", 0);
        float fVec[3] = {0.0, 0.0, 0.0};
        SetEntPropVector(iClient, Prop_Send, "m_viewPunchAngle", fVec);
        SetEntPropVector(iClient, Prop_Send, "m_aimPunchAngle", fVec);
        SetEntPropVector(iClient, Prop_Send, "m_aimPunchAngleVel", fVec);
    }
}

stock SetClientNoRecoil(iClient)
{
        SendConVarValue(iClient, FindConVar("weapon_accuracy_nospread"), "1");
        SendConVarValue(iClient, FindConVar("weapon_recoil_cooldown"), "0");
        SendConVarValue(iClient, FindConVar("weapon_recoil_cooldown"), "9");
        SendConVarValue(iClient, FindConVar("weapon_recoil_decay1_exp"), "99999");
        SendConVarValue(iClient, FindConVar("weapon_recoil_decay2_exp"), "99999");
        SendConVarValue(iClient, FindConVar("weapon_recoil_decay2_lin"), "99999");
        SendConVarValue(iClient, FindConVar("weapon_recoil_scale"), "0");
        SendConVarValue(iClient, FindConVar("weapon_recoil_suppression_shots"), "500");
}

stock SetClientRecoil(iClient)
{
        SendConVarValue(iClient, FindConVar("weapon_accuracy_nospread"), "0");
        SendConVarValue(iClient, FindConVar("weapon_recoil_cooldown"), "0.55");
        SendConVarValue(iClient, FindConVar("weapon_recoil_decay1_exp"), "3.5");
        SendConVarValue(iClient, FindConVar("weapon_recoil_decay2_exp"), "8");
        SendConVarValue(iClient, FindConVar("weapon_recoil_decay2_lin"), "18");
        SendConVarValue(iClient, FindConVar("weapon_recoil_scale"), "2.0");
        SendConVarValue(iClient, FindConVar("weapon_recoil_suppression_shots"), "4");
}