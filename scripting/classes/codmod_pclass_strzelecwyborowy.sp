#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <th7manager>

#include <emitsoundany>

#define _IN_CODMOD_CLASS 1
#include <codmod301>
public Plugin myinfo = {
    name = "CodMod 301 - Class - Strzelec Wyborowy",
    author = "th7nder",
    description = "Strzelec Wyborowy Class from CodMod 301",
    version = "2.0",
    url = "http://serwery-go.pl"
};

WeaponID g_iWeapons[WEAPON_LIMIT] = {WEAPON_NONE};


const WeaponID g_iFirstWeaponID = WEAPON_M4A1;
const WeaponID g_iSecondWeaponID = WEAPON_AK47;
int g_iWeaponAmmos[2] = {-1};
bool g_bFrozen[MAXPLAYERS+1] = {false};

int g_iBeamColor[] = {0,255,255,255}; 

char g_szClassName[128] = {"Strzelec Wyborowy [Premium]"};
char g_szDesc[256] = {"120HP, AK47/M4A1-S, USP \n 1/6 na zredukowanie 90%% damage'u, 1/10 na zamrożenie na 1.5s \n +6dmg z każdej broni"};
const int g_iHealth = 0;
const int g_iStartingHealth = 120;
const int g_iArmor = 0;
const int g_iDexterity = 0;
const int g_iIntelligence = 0;
int g_iClassId = 0;
bool g_bHasClass[MAXPLAYERS+1]    = {false};

int g_iBeamSprite = -1;
int g_iHaloSprite = -1;
int g_iGlowSprite = -1;
public void OnPluginStart(){
    g_iWeapons[0] = WEAPON_USP;
    g_iClassId = CodMod_RegisterClass(g_szClassName, g_szDesc, g_iHealth, g_iArmor, g_iDexterity, g_iIntelligence, g_iWeapons, ADMFLAG_CUSTOM5, g_iStartingHealth);
}

public void OnPluginEnd(){
    CodMod_UnregisterClass(g_iClassId);
}


public void OnMapStart()
{
    g_iBeamSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
    g_iHaloSprite = PrecacheModel("materials/sprites/halo.vmt");
    g_iGlowSprite = PrecacheModel("sprites/glow07.vmt");
}


public int CodMod_OnChangeClass(int iClient, int iPrevious, int iNext){
    if(iNext != g_iClassId) {
        g_bHasClass[iClient] = false;
    } else {
        g_bHasClass[iClient] = true;

        CreateTimer(0.5, Timer_GiveWeapon, GetClientSerial(iClient));
    }

}

public Action Timer_GiveWeapon(Handle hTimer, int iSerial)
{
    int iClient = GetClientFromSerial(iSerial);

    if(iClient > 0 && IsClientInGame(iClient))
    {
        if(IsPlayerAlive(iClient))
        {
            g_iWeaponAmmos[0] = -1;
            g_iWeaponAmmos[1] = -1;
            int iCurrentEntity = GetPlayerWeaponSlot(iClient, 0);
            if(iCurrentEntity == -1){
                char szWeapon[64];
                Format(STRING(szWeapon), "weapon_%s", weaponNames[g_iFirstWeaponID]);
                GivePlayerItem(iClient, szWeapon);
            }  
        }
    }
}

public CodMod_OnPlayerDamaged(int iAttacker, int iVictim, float &fDamage, WeaponID iWeaponID, int iDamageType){
    if(g_bHasClass[iAttacker]){
        fDamage += 6.0;
        if(GetRandomInt(1, 10) == 1 && !g_bFrozen[iVictim] && iWeaponID != WEAPON_MOLOTOV){
            SetEntityMoveType(iVictim, MOVETYPE_NONE);
            PrintToChat(iVictim, "%s Zostałeś zamrożony!", PREFIX_SKILL);
            g_bFrozen[iVictim] = true;
            CreateTimer(1.5, Timer_Unfreeze, GetClientSerial(iVictim));

            float fPosition[3], fTargetPosition[3];
            GetClientEyePosition(iAttacker, fPosition);
            GetClientEyePosition(iVictim, fTargetPosition);
            fPosition[2] -= 10.0;
            fTargetPosition[2] -= 10.0;
            TE_SetupBeamPoints(fPosition, fTargetPosition, g_iBeamSprite, g_iHaloSprite, 0, 66, 1.0, 1.0, 20.0, 1, 0.0, g_iBeamColor, 5);
            TE_SendToAll();
        }
    }

    if(g_bHasClass[iVictim] && GetRandomInt(1, 6) == 1){
        fDamage *= 0.1;
        PrintToChat(iVictim, "%s Damage został zredukowany!", PREFIX_SKILL);
        float fPosition[3];
        GetClientEyePosition(iVictim, fPosition);
        fPosition[2] -= 32.0;
        CreateGlowSprite(g_iGlowSprite, fPosition, 0.5);
    }
}

public Action DeleteEntity(Handle hTimer, any iEntity)
{
    if(IsValidEdict(iEntity))
        AcceptEntityInput(iEntity, "kill");
}

void CreateGlowSprite(int iSprite, const float faCoord[3], const float fDuration)
{
    TE_SetupGlowSprite(faCoord, iSprite, fDuration, 2.2, 180);
    TE_SendToAll();
}


public Action Timer_Unfreeze(Handle hTimer, int iClient){
    iClient = GetClientFromSerial(iClient);
    if(!IsValidPlayer(iClient)){
        return Plugin_Stop;
    }

    if(g_bFrozen[iClient] && IsPlayerAlive(iClient)){
        g_bFrozen[iClient] = false;
        SetEntityMoveType(iClient, MOVETYPE_WALK);
        PrintToChat(iClient, "%s Zostałeś odmrożony!", PREFIX_SKILL);
    }

    return Plugin_Stop;
}




public void OnClientPutInServer(int iClient){
    g_bFrozen[iClient] = false;
}

public void CodMod_OnPlayerSpawn(int iClient){
    if(g_bFrozen[iClient]){
        SetEntityMoveType(iClient, MOVETYPE_WALK);
        g_bFrozen[iClient] = false;
    }



    if(g_bHasClass[iClient]){
        g_iWeaponAmmos[0] = -1;
        g_iWeaponAmmos[1] = -1;
        int iCurrentEntity = GetPlayerWeaponSlot(iClient, 0);
        if(iCurrentEntity == -1){
            char szWeapon[64];
            Format(STRING(szWeapon), "weapon_%s", weaponNames[g_iFirstWeaponID]);
            GivePlayerItem(iClient, szWeapon);
        }
    }
}

public void CodMod_OnClassSkillUsed(int iClient){
    if(!g_bHasClass[iClient] || !IsPlayerAlive(iClient))
        return;

    int iCurrentEntity = GetPlayerWeaponSlot(iClient, 0);
    WeaponID iWeaponID = CodMod_GetWeaponID(iCurrentEntity);

    char szWeapon[64];
    if(iWeaponID == g_iFirstWeaponID){
        g_iWeaponAmmos[0] = GetEntProp(iCurrentEntity, Prop_Send, "m_iClip1");

        RemovePlayerItem(iClient, iCurrentEntity);
        RemoveEdict(iCurrentEntity);

        Format(STRING(szWeapon), "weapon_%s", weaponNames[g_iSecondWeaponID]);
        int iNextEntity = GivePlayerItem(iClient, szWeapon);
        if(g_iWeaponAmmos[1] != -1){
            SetEntProp(iNextEntity, Prop_Send, "m_iClip1", g_iWeaponAmmos[1]);
        }

        EquipPlayerWeapon(iClient, iNextEntity);
        SetWeaponActive(iClient, iNextEntity);
    } else if(iWeaponID == g_iSecondWeaponID){
        if(iWeaponID == g_iSecondWeaponID){
            g_iWeaponAmmos[1] = GetEntProp(iCurrentEntity, Prop_Send, "m_iClip1");
        } else {
            g_iWeaponAmmos[1] = -1;
        }


        if(iCurrentEntity != -1){
            RemovePlayerItem(iClient, iCurrentEntity);
            RemoveEdict(iCurrentEntity);
        }

        Format(STRING(szWeapon), "weapon_%s", weaponNames[g_iFirstWeaponID]);
        int iNextEntity = GivePlayerItem(iClient, szWeapon);
        if(g_iWeaponAmmos[0] != -1){
            SetEntProp(iNextEntity, Prop_Send, "m_iClip1", g_iWeaponAmmos[0]);
        }
        EquipPlayerWeapon(iClient, iNextEntity);
        SetWeaponActive(iClient, iNextEntity);
    }
}

public void CodMod_OnWeaponCanUse(int iClient, WeaponID iWeaponID, int &iCanUse, bool bBuy){
    if(g_bHasClass[iClient] && (iWeaponID == g_iFirstWeaponID || iWeaponID == g_iSecondWeaponID)){
        iCanUse = 2;
    }
}
