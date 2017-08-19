#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <dhooks>

#include <th7manager>

//#include <codmod301>

#define FUNCTION_OFFSET 466
#define GetPlayerMaxSpeed_OFFSET 498

#define CSAddon_NONE            0
#define CSAddon_Flashbang1      (1<<0)
#define CSAddon_Flashbang2      (1<<1)
#define CSAddon_HEGrenade       (1<<2)
#define CSAddon_SmokeGrenade    (1<<3)
#define CSAddon_C4              (1<<4)
#define CSAddon_DefuseKit       (1<<5)
#define CSAddon_PrimaryWeapon   (1<<6)
#define CSAddon_SecondaryWeapon (1<<7)
#define CSAddon_Holster         (1<<8)

public Plugin:myinfo = {
    name = "TH7 Manager",
    author = "th7nder",
    description = "No-Recoil, Silent footsteps and shiitt",
    version = "2.0",
    url = "http://serwery-go.pl"
};


bool g_bEnableNoRecoil[MAXPLAYERS+1] = {false}
bool g_bEnableItemNoRecoil[MAXPLAYERS+1] = {false}
bool g_bSilentFootsteps[MAXPLAYERS+1] = {false};
bool g_bItemFootsteps[MAXPLAYERS+1] = {false};
bool g_bHalfVisible[MAXPLAYERS+1] = {false};
Handle g_hGetInaccuracy = INVALID_HANDLE;



enum RenderColor {
    R = 0,
    G,
    B,
    A
}

bool g_bRenderColor[MAXPLAYERS+1] = {false};
bool g_bItemRenderColor[MAXPLAYERS+1] = {false};
bool g_bWeaponInvisible[MAXPLAYERS+1] = {false};
int g_iRenderColor[MAXPLAYERS+1][RenderColor];

bool g_bInvisible[MAXPLAYERS+1];
bool g_bRadarVisibility[MAXPLAYERS+1] = {false};

bool g_bWeaponNoSlow[MAXPLAYERS+1] = {false};
Handle g_hGetPlayerMaxSpeed = INVALID_HANDLE;


float g_fMaxSpeed[MAXPLAYERS+1] = {0.0};
bool g_bMovementNoRecoil[MAXPLAYERS+1] = {false};

bool g_bHooked[2048 +1 ] = {false};
bool g_bInvisibleHooked[2048 +1] = {false};
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max){
    CreateNative("TH7_EnableNoRecoil", Native_EnableNoRecoil);
    CreateNative("TH7_DisableNoRecoil", Native_DisableNoRecoil);
    CreateNative("TH7_SetMovementNoRecoil", Native_SetMovementNoRecoil)
    CreateNative("TH7_EnableSilentFootsteps", Native_EnableSilentFootsteps);
    CreateNative("TH7_DisableSilentFootsteps", Native_DisableSilentFootsteps);
    CreateNative("TH7_SetRenderColor", Native_SetRenderColor);
    CreateNative("TH7_SetInvisible", Native_SetInvisible);
    CreateNative("TH7_SetVisible", Native_SetVisible);
    CreateNative("TH7_DisableRenderColor", Native_DisableRenderColor);
    CreateNative("TH7_EnableRenderColor", Native_EnableRenderColor);
    CreateNative("TH7_SetRadarVisibility", Native_SetRadarVisibility);
    CreateNative("TH7_SetHalfInvisible", Native_SetHalfInvisible);
    CreateNative("TH7_GetHalfInvisible", Native_GetHalfInvisible);
    CreateNative("TH7_SetWeaponNoSlow", Native_SetWeaponNoSlow);
    CreateNative("TH7_GetAlpha", Native_GetAlpha);
    CreateNative("TH7_SetPlayerMaxSpeed", Native_SetPlayerMaxSpeed);
    CreateNative("TH7_GetPlayerMaxSpeed", Native_GetPlayerMaxSpeed);
    CreateNative("TH7_IsRenderColorEnabled", Native_IsRenderColorEnabled);
    return APLRes_Success;
}

public int Native_GetPlayerMaxSpeed(Handle hPlugin, int iNumParams){
    return view_as<int>(g_fMaxSpeed[GetNativeCell(1)]);
}

public Native_GetAlpha(Handle hPlugin, int iNumParams){
    int iClient = GetNativeCell(1);
    if(IsValidPlayer(iClient)){
        return g_iRenderColor[iClient][A]
    }

    return 0;
}


public Native_SetPlayerMaxSpeed(Handle hPlugin, int iNumParams){
    int iClient = GetNativeCell(1);
    float fMaxSpeed = view_as<float>(GetNativeCell(2));
    if(IsValidPlayer(iClient)){
        g_fMaxSpeed[iClient] = fMaxSpeed;
    }

    return 0;
}


public Native_EnableNoRecoil(Handle hPlugin, int iNumParams){
    int iClient = GetNativeCell(1);
    if(IsValidPlayer(iClient)){
        char szPluginName[64];
        GetPluginFilename(hPlugin, szPluginName, sizeof(szPluginName));
        if(StrContains(szPluginName, "item") != -1 || StrContains(szPluginName, "perk") != -1){
            g_bEnableItemNoRecoil[iClient] = true;
        } else {
            g_bEnableNoRecoil[iClient] = true;
        }

        SetClientNoRecoil(iClient);

        HookWeapon(iClient, -1);
    }
}

public Native_DisableNoRecoil(Handle hPlugin, int iNumParams){
    int iClient = GetNativeCell(1);
    if(IsValidPlayer(iClient)){
        char szPluginName[64];
        GetPluginFilename(hPlugin, szPluginName, sizeof(szPluginName));
        if(StrContains(szPluginName, "item") != -1 || StrContains(szPluginName, "perk") != -1){
            g_bEnableItemNoRecoil[iClient] = false;
        } else {
            g_bEnableNoRecoil[iClient] = false;
        }
        SetClientRecoil(iClient);
    }
}


public Native_EnableSilentFootsteps(Handle hPlugin, int iNumParams){
    int iClient = GetNativeCell(1);
    if(IsValidPlayer(iClient)){
        char szPluginName[64];
        GetPluginFilename(hPlugin, szPluginName, sizeof(szPluginName));
        if(StrContains(szPluginName, "item") != -1 || StrContains(szPluginName, "perk") != -1){
            g_bItemFootsteps[iClient] = true;
        } else {
            g_bSilentFootsteps[iClient] = true;
        }

    }
}

public Native_DisableSilentFootsteps(Handle hPlugin, int iNumParams){
    int iClient = GetNativeCell(1);
    if(IsValidPlayer(iClient)){
        char szPluginName[64];
        GetPluginFilename(hPlugin, szPluginName, sizeof(szPluginName));
        if(StrContains(szPluginName, "item") != -1 || StrContains(szPluginName, "perk") != -1){
            g_bItemFootsteps[iClient] = false;
        } else {
            g_bSilentFootsteps[iClient] = false;
        }
    }
}


public int Native_IsRenderColorEnabled(Handle hPlugin, int iNumParams){
    int iClient = GetNativeCell(1);
    
    return view_as<int>(g_bRenderColor[iClient]);
}

public Native_SetRenderColor(Handle hPlugin, int iNumParams){
    int iClient = GetNativeCell(1);
    if(IsValidPlayer(iClient)){
        char szPluginName[64];
        GetPluginFilename(hPlugin, szPluginName, sizeof(szPluginName));
        if(StrContains(szPluginName, "item") != -1 || StrContains(szPluginName, "perk") != -1){
            g_bItemRenderColor[iClient] = true;
        } else {
            g_bRenderColor[iClient] = true;
        }
        g_iRenderColor[iClient][R] = GetNativeCell(2);
        g_iRenderColor[iClient][G] = GetNativeCell(3);
        g_iRenderColor[iClient][B] = GetNativeCell(4);
        g_iRenderColor[iClient][A] = GetNativeCell(5);

        if(g_iRenderColor[iClient][A] < 2){
            g_iRenderColor[iClient][A] = 2;
        }

        //PrintToConsole(iClient, "Alpha: %d", g_iRenderColor[iClient][A]);
        UpdateAlpha(iClient);
    }
}

public Native_DisableRenderColor(Handle hPlugin, int iNumParams){
    int iClient = GetNativeCell(1);
    if(IsValidPlayer(iClient)){
        char szPluginName[64];
        GetPluginFilename(hPlugin, szPluginName, sizeof(szPluginName));
        if(StrContains(szPluginName, "item") != -1 || StrContains(szPluginName, "perk") != -1){
            g_bItemRenderColor[iClient] = false;
        } else {
            g_bRenderColor[iClient] = false;
        }
        UpdateAlpha(iClient);
    }
}

public Native_EnableRenderColor(Handle hPlugin, int iNumParams){
    int iClient = GetNativeCell(1);
    if(IsValidPlayer(iClient)){
        char szPluginName[64];
        GetPluginFilename(hPlugin, szPluginName, sizeof(szPluginName));
        if(StrContains(szPluginName, "item") != -1 || StrContains(szPluginName, "perk") != -1){
            g_bItemRenderColor[iClient] = true;
        } else {
            g_bRenderColor[iClient] = true;
        }
        UpdateAlpha(iClient);
    }
}

public Native_SetVisible(Handle hPlugin, int iNumParams){
    /*char szName[128];
    GetPluginFilename(hPlugin, szName, 128);
    LogMessage("set visible %s", szName);*/
    int iClient = GetNativeCell(1);
    if(IsValidPlayer(iClient)){
        g_bInvisible[iClient] = false;
        UpdateAlpha(iClient);

        HookWeapon(iClient, -1);
    }
}

public Native_SetInvisible(Handle hPlugin, int iNumParams){
   /* char szName[128];
    GetPluginFilename(hPlugin, szName, 128);
    LogMessage("set invvisible %s", szName);*/
    int iClient = GetNativeCell(1);
    bool bFull = view_as<bool>(GetNativeCell(2));
    if(IsValidPlayer(iClient)){
        g_bInvisible[iClient] = true;
        g_bWeaponInvisible[iClient] = bFull;
        UpdateAlpha(iClient);

        HookWeapon(iClient, -1);
    }
}

public Native_SetHalfInvisible(Handle hPlugin, int iNumParams){
    int iClient = GetNativeCell(1);
    if(IsValidPlayer(iClient)){
        g_bHalfVisible[iClient] = view_as<bool>(GetNativeCell(2));
        UpdateAlpha(iClient);
    }
}

public Native_GetHalfInvisible(Handle hPlugin, int iNumParams){
    int iClient = GetNativeCell(1);
    if(IsValidPlayer(iClient)){
        return g_bHalfVisible[iClient];
    }

    return false;
}


public Native_SetRadarVisibility(Handle hPlugin, int iNumParams){
    int iClient = GetNativeCell(1);
    if(IsValidPlayer(iClient)){
        g_bRadarVisibility[iClient] = view_as<bool>(GetNativeCell(2));
    }
}

public Native_SetWeaponNoSlow(Handle hPlugin, int iNumParams){
    int iClient = GetNativeCell(1);
    if(IsValidPlayer(iClient)){
        g_bWeaponNoSlow[iClient] = view_as<bool>(GetNativeCell(2));
    }
}

public Native_SetMovementNoRecoil(Handle hPlugin, int iNumParams){
    int iClient = GetNativeCell(1);
    if(IsValidPlayer(iClient)){
        g_bMovementNoRecoil[iClient] = view_as<bool>(GetNativeCell(2));
    }
}

Handle g_hCvarFootsteps = INVALID_HANDLE;


public OnPluginStart(){
    g_hGetInaccuracy = DHookCreate(FUNCTION_OFFSET, HookType_Entity, ReturnType_Float, ThisPointer_CBaseEntity, DHook_GetInaccuracy);
    g_hGetPlayerMaxSpeed = DHookCreate(GetPlayerMaxSpeed_OFFSET, HookType_Entity, ReturnType_Float, ThisPointer_CBaseEntity, DHook_GetPlayerMaxSpeed);

    RegAdminCmd("nrc", Command_ToggleNRC, ADMFLAG_ROOT);
    RegAdminCmd("sfoot", Command_ToggleSilentFootsteps, ADMFLAG_ROOT);
    RegAdminCmd("inv", Command_ToggleInv, ADMFLAG_ROOT);

    HookEvent("player_death", Event_PlayerDeath);
    HookEvent("player_spawn", Event_PlayerSpawn);


    AddNormalSoundHook(OnNormalSoundPlayed);

    g_hCvarFootsteps = FindConVar("sv_footsteps");

    for(int iClient = 1; iClient <= MaxClients; iClient++){
        if(IsClientInGame(iClient)){
            OnClientPutInServer(iClient);
        }
    }
}

public OnMapStart(){
    SetConVarInt(FindConVar("sv_disable_immunity_alpha"), 1);
}

public OnClientPutInServer(iClient){
    if(IsFakeClient(iClient)){
        return;
    }
    g_bEnableNoRecoil[iClient] = false;
    g_bEnableItemNoRecoil[iClient] = false;
    g_bSilentFootsteps[iClient] = false;
    g_bItemFootsteps[iClient] = false;
    g_bRenderColor[iClient] = false;
    g_bHalfVisible[iClient] = false;
    g_iRenderColor[iClient][R] = 255;
    g_iRenderColor[iClient][G] = 255;
    g_iRenderColor[iClient][B] = 255;
    g_iRenderColor[iClient][A] = 255;
    g_bInvisible[iClient] = false;
    g_bRadarVisibility[iClient] = true;
    g_bItemRenderColor[iClient] = false;
    g_bWeaponNoSlow[iClient] = false;
    g_bMovementNoRecoil[iClient] = false;
    g_fMaxSpeed[iClient] = 0.0;
    g_bWeaponInvisible[iClient] = false;

    DHookEntity(g_hGetPlayerMaxSpeed, true, iClient);

    SDKHook(iClient, SDKHook_PostThinkPost, OnPostThinkPost);
    SDKHook(iClient, SDKHook_PostThink, OnPostThink);
    SDKHook(iClient, SDKHook_WeaponEquip, SDK_OnWeaponEquip);
    SendConVarValue(iClient, g_hCvarFootsteps, "0");
}

public OnClientDisconnect(int iClient){
    SDKUnhook(iClient, SDKHook_PostThinkPost, OnPostThinkPost);
    SDKUnhook(iClient, SDKHook_PostThink, OnPostThink);
    SDKUnhook(iClient, SDKHook_WeaponEquip, SDK_OnWeaponEquip);
}


public Action Command_ToggleSilentFootsteps(iClient, iArgs){
    g_bSilentFootsteps[iClient] = !g_bSilentFootsteps[iClient];

    return Plugin_Handled;
}

public Action Command_ToggleInv(iClient, iArgs){
    g_bInvisible[iClient] = !g_bInvisible[iClient];

    return Plugin_Handled;
}

public Action Command_ToggleNRC(iClient, iArgs){
    g_bEnableNoRecoil[iClient] = !g_bEnableNoRecoil[iClient];
    if(g_bEnableNoRecoil[iClient]){
        HookWeapon(iClient, -1);
        SetClientNoRecoil(iClient);
    } else {
        SetClientRecoil(iClient);
    }

    return Plugin_Handled;
}

public void Event_PlayerDeath(Event hEvent, const char[] sName, bool dontBroadcast) {
    int iClient = GetClientOfUserId((hEvent.GetInt("userid")));
    if(g_bEnableNoRecoil[iClient] || g_bEnableItemNoRecoil[iClient]){
        SetClientRecoil(iClient);
    }
}

public void Event_PlayerSpawn(Event hEvent, const char[] sName, bool dontBroadcast) {
    int iClient = GetClientOfUserId((hEvent.GetInt("userid")));
    if(g_bEnableNoRecoil[iClient] || g_bEnableItemNoRecoil[iClient]){
         SetClientNoRecoil(iClient);
    }

    UpdateAlpha(iClient);
}

public OnPostThinkPost(iClient){
    if(!IsPlayerAlive(iClient)){
        return;
    }
    if(g_bEnableNoRecoil[iClient] || g_bMovementNoRecoil[iClient] || g_bEnableItemNoRecoil[iClient]){
        int iEntity = GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
        if(iEntity != -1 && IsValidEdict(iEntity)){
            SetEntPropFloat(iEntity, Prop_Send, "m_fAccuracyPenalty", 0.0);
        }


        SetEntProp(iClient, Prop_Send, "m_iShotsFired", 0);
        float fVec[3] = {0.0, 0.0, 0.0};
        SetEntPropVector(iClient, Prop_Send, "m_viewPunchAngle", fVec);
        SetEntPropVector(iClient, Prop_Send, "m_aimPunchAngle", fVec);
        SetEntPropVector(iClient, Prop_Send, "m_aimPunchAngleVel", fVec);
    }


    if((g_bInvisible[iClient] && g_bWeaponInvisible[iClient]) || g_bRenderColor[iClient] || g_bItemRenderColor[iClient]){
        SetEntProp(iClient, Prop_Send, "m_iAddonBits", CSAddon_NONE);
    }
}


public OnPostThink(iClient){
    if(!IsPlayerAlive(iClient)){
        return;
    }

    if(!g_bRadarVisibility[iClient]){
        SetEntPropEnt(iClient, Prop_Send, "m_bSpotted", 0);
    }
}

//public Action OnPlayerRunCmd(iClient, &iButtons, &iImpulse, float fVel[3], float fAngles[3], int &iWeapon){
//    UpdateAlpha(iClient);
//    return Plugin_Continue;
//}

/*public OnEntityCreated(iEntity, const String:szClassname[]){
    WeaponID iWeapon = CodMod_GetWeaponID(iEntity);
    if(iWeapon != WEAPON_NONE && iWeapon != WEAPON_KNIFE && iWeapon != WEAPON_HEGRENADE && iWeapon != WEAPON_DEFUSER && iWeapon != WEAPON_INCGRENADE && iWeapon != WEAPON_MOLOTOV && iWeapon != WEAPON_FLASHBANG && iWeapon != WEAPON_SMOKEGRENADE && iWeapon != WEAPON_DECOY && iWeapon != WEAPON_C4){
        if(g_hGetInaccuracy != INVALID_HANDLE){
            DHookEntity(g_hGetInaccuracy, true, iEntity);
        } else {
            LogError("[TH7 Manager] didn't manage to hook function, check offsets.")

        }


        SDKHook(iEntity, SDKHook_SetTransmit, OnSetTransmit);
    }
}*/
public OnEntityCreated(int iEntity, const String:szClassname[]){
    if(iEntity > 0 && iEntity < 2048){
        g_bHooked[iEntity] = false;
        g_bInvisibleHooked[iEntity] = false;
    }
}

void HookWeapon(int iClient, int iWeapon){
    if(IsValidPlayer(iClient)){
        if(iWeapon == -1 && IsPlayerAlive(iClient)){
            int iEntity = -1;
            for(int i = 0; i <= 1; i++){
                iEntity = GetPlayerWeaponSlot(iClient, i);
                if(iEntity != -1 && iEntity < 2048 && iEntity > 0){
                    HookWeapon(iClient, iEntity);
                }
            }
        } else if(iWeapon > 0 && iWeapon < 2048 && IsValidEntity(iWeapon)){
           
            if((g_bEnableNoRecoil[iClient] || g_bEnableItemNoRecoil[iClient])&& !g_bHooked[iWeapon]){

                g_bHooked[iWeapon] = true;
                DHookEntity(g_hGetInaccuracy, true, iWeapon);
            }


            /*if(g_bInvisible[iClient] && !g_bInvisibleHooked[iWeapon]){
                g_bInvisibleHooked[iWeapon] = true;
                SDKHook(iWeapon, SDKHook_SetTransmit, OnSetTransmit);
            }

            if(!g_bInvisible[iClient] && g_bInvisibleHooked[iWeapon]){
                g_bInvisibleHooked[iWeapon] = false;
                SDKUnhook(iWeapon, SDKHook_SetTransmit, OnSetTransmit);
            }*/
        }
    }
}


public Action SDK_OnWeaponEquip(int iClient, int iWeapon){
    if(!IsPlayerAlive(iClient))
    {
        return Plugin_Continue;
    }
    HookWeapon(iClient, iWeapon);

    return Plugin_Continue;
}

public Action OnSetTransmit(int iEntity, int iClient){
    if(!IsPlayerAlive(iClient)) return Plugin_Continue;
    int iOwner = GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity");
    if(!IsValidPlayer(iOwner))
        return Plugin_Continue;

    if(iOwner == iClient)
        return Plugin_Continue;

    if((g_bInvisible[iClient] && g_bWeaponInvisible[iClient]))
        return Plugin_Handled;

    return Plugin_Continue;
}

public Action OnNormalSoundPlayed(int iClients[64], int &iNumClients, char szSample[PLATFORM_MAX_PATH], int &iEntity, int &iChannel, float &fVolume, int &iLevel, int &iPitch, int &iFlags) {
    if (iEntity && iEntity <= MaxClients && (StrContains(szSample, "physics") != -1 || StrContains(szSample, "footsteps") != -1)) {
        if (g_bSilentFootsteps[iEntity] || g_bItemFootsteps[iEntity]) {
            return Plugin_Handled;
        } else {
            for (int i = 1; i <= MaxClients; i++) {
                if (IsClientInGame(i)) {
                    iClients[iNumClients++] = i;
                    //EmitSoundToClient(i, szSample, iEntity, iChannel);
                }
            }

            return Plugin_Changed;
        }
    }

    return Plugin_Continue;
}

/*stock int GetCurrentOwner(int iWeapon){
    for(int iClient = 1; iClient <= MaxClients; iClient++){
        if(IsClientInGame(iClient) && IsPlayerAlive(iClient)){
            int iEntity = GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
            if(iEntity == iWeapon){
                return iClient;
            }
        }
    }

    return -1;
}*/

public MRESReturn DHook_GetInaccuracy(int pThis, Handle hReturn){
//    int iOwner = GetCurrentOwner(pThis);
    int iOwner = GetEntPropEnt(pThis, Prop_Send, "m_hOwnerEntity");
    if(hReturn != INVALID_HANDLE && iOwner != -1){
        if(g_bMovementNoRecoil[iOwner] && !IsClientInMove(iOwner)){
            DHookSetReturn(hReturn, 0.0);
            return MRES_Override;
        } else if(g_bEnableNoRecoil[iOwner] || g_bEnableItemNoRecoil[iOwner]){
            DHookSetReturn(hReturn, 0.0);
            return MRES_Override;
        }
    }
    return MRES_Ignored;
}
public MRESReturn:DHook_GetPlayerMaxSpeed(int pThis, Handle hReturn){
    if(hReturn != INVALID_HANDLE && IsValidPlayer(pThis)){
        if(g_fMaxSpeed[pThis]){
            DHookSetReturn(hReturn, g_fMaxSpeed[pThis]);
            return MRES_Override;
        }



        if(g_bWeaponNoSlow[pThis]){
            DHookSetReturn(hReturn, 250.0);
            return MRES_Override;
        }
    }

    return MRES_Ignored;
}



stock SetClientNoRecoil(iClient){
        SendConVarValue(iClient, FindConVar("weapon_accuracy_nospread"), "1");
        SendConVarValue(iClient, FindConVar("weapon_recoil_cooldown"), "0");
        SendConVarValue(iClient, FindConVar("weapon_recoil_cooldown"), "9");
        SendConVarValue(iClient, FindConVar("weapon_recoil_decay1_exp"), "99999");
        SendConVarValue(iClient, FindConVar("weapon_recoil_decay2_exp"), "99999");
        SendConVarValue(iClient, FindConVar("weapon_recoil_decay2_lin"), "99999");
        SendConVarValue(iClient, FindConVar("weapon_recoil_scale"), "0");
        SendConVarValue(iClient, FindConVar("weapon_recoil_suppression_shots"), "500");
}

stock SetClientRecoil(iClient){
        SendConVarValue(iClient, FindConVar("weapon_accuracy_nospread"), "0");
        SendConVarValue(iClient, FindConVar("weapon_recoil_cooldown"), "0.55");
        SendConVarValue(iClient, FindConVar("weapon_recoil_decay1_exp"), "3.5");
        SendConVarValue(iClient, FindConVar("weapon_recoil_decay2_exp"), "8");
        SendConVarValue(iClient, FindConVar("weapon_recoil_decay2_lin"), "18");
        SendConVarValue(iClient, FindConVar("weapon_recoil_scale"), "2.0");
        SendConVarValue(iClient, FindConVar("weapon_recoil_suppression_shots"), "4");
}



stock UpdateAlpha(iClient){
    if(!IsPlayerAlive(iClient)){
        return;
    }

    if(g_bInvisible[iClient] || g_bHalfVisible[iClient]){
        SetEntityRenderMode(iClient, RENDER_NONE);
    } else if(g_bRenderColor[iClient] || g_bItemRenderColor[iClient]){
        SetEntityRenderMode(iClient, RENDER_TRANSCOLOR);
        SetEntityRenderColor(iClient, g_iRenderColor[iClient][R], g_iRenderColor[iClient][G], g_iRenderColor[iClient][B], g_iRenderColor[iClient][A]);
    } else {
        SetEntityRenderMode(iClient, RENDER_TRANSCOLOR);
        SetEntityRenderColor(iClient, 255, 255, 255, 255);
    }

}

stock bool IsClientInMove(int iClient){
    if(IsValidPlayer(iClient)){
        int iButtons = GetClientButtons(iClient);
        if(iButtons & IN_FORWARD || iButtons & IN_BACK || iButtons & IN_LEFT || iButtons & IN_RIGHT || iButtons & IN_JUMP || iButtons & IN_MOVERIGHT || iButtons & IN_MOVELEFT){
            return true;
        }
    }

    return false;
}

public bool IsValidPlayer(iClient){
    if(iClient > 0 && iClient <= MaxClients && IsClientInGame(iClient) /*&& !IsFakeClient(iClient)*/){
        return true;
    }

    return false;
}
