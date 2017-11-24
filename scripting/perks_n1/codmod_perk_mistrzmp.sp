#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <codmod301>


public Plugin myinfo = {
    name = "Call of Duty Mod - Perk - MistrzMP",
    author = "th7nder",
    description = "201 Rewrite Perk",
    version = "2.0",
    url = "http://th7.eu"
};


const WeaponID g_iFirstWeaponID = WEAPON_MP7;
const WeaponID g_iSecondWeaponID = WEAPON_MP9;
int g_iWeaponAmmos[2] = {-1};

char szClassName[] = {"MistrzMP"};
char szDesc[] = {"MP7(+5dmg)/MP9(+5dmg), codmod_perk - zmiana broni"};
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

public void CodMod_OnPlayerSpawn(int iClient){
    if(g_bHasItem[iClient]){
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

stock void Shake(int iClient, float fAmp=1.0) {
  new Handle:hMessage = StartMessageOne("Shake", iClient, 1);
  PbSetInt(hMessage, "command", 0);
  PbSetFloat(hMessage, "local_amplitude", fAmp);
  PbSetFloat(hMessage, "frequency", 100.0);
  PbSetFloat(hMessage, "duration", 1.5);
  EndMessage();
}

public void CodMod_OnPerkSkillUsed(int iClient){
    if(!g_bHasItem[iClient] || !IsPlayerAlive(iClient))
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

public void CodMod_OnWeaponCanUsePerk(int iClient, WeaponID iWeaponID, int &iCanUse, bool bBuy){
    if(g_bHasItem[iClient] && (iWeaponID == g_iFirstWeaponID || iWeaponID == g_iSecondWeaponID)){
        iCanUse = 2;
    }
}