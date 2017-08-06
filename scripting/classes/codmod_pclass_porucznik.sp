#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <th7manager>

#include <emitsoundany>

#define _IN_CODMOD_CLASS 1
#include <codmod301>
public Plugin myinfo = {
    name = "CodMod 301 - Class - Porucznik",
    author = "th7nder",
    description = "Porucznik Class from CodMod 301",
    version = "2.0",
    url = "http://serwery-go.pl"
};

WeaponID g_iWeapons[WEAPON_LIMIT] = {WEAPON_NONE};


char g_szClassName[128] = {"Porucznik [Premium]"};
char g_szDesc[256] = {"110HP, AK47/M4A4, P250 \n Gdy ma AK47 1/8 na potrząśnięcie ekranem gdy M4A4 leczenie(50%% na +1/5 dmg) \n +15HP + magazynek per kill "};
const int g_iHealth = 0;
const int g_iStartingHealth = 110;
const int g_iArmor = 0;
const int g_iDexterity = 0;
const int g_iIntelligence = 0;
int g_iClassId = 0;
bool g_bHasClass[MAXPLAYERS+1]    = {false};
public void OnPluginStart(){
    g_iWeapons[0] = WEAPON_P250;
    g_iClassId = CodMod_RegisterClass(g_szClassName, g_szDesc, g_iHealth, g_iArmor, g_iDexterity, g_iIntelligence, g_iWeapons, ADMFLAG_CUSTOM2, g_iStartingHealth);
}

public void OnPluginEnd(){
    CodMod_UnregisterClass(g_iClassId);
}


public int CodMod_OnChangeClass(int iClient, int iPrevious, int iNext){
    if(iNext != g_iClassId) {
        g_bHasClass[iClient] = false;
    } else {
        g_bHasClass[iClient] = true;
    }

}

public void SetWeaponToKnife(client){
    int weapon = GetPlayerWeaponSlot(client, 2);
    SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
}

public CodMod_OnPlayerDamaged(int iAttacker, int iVictim, float &fDamage, WeaponID iWeaponID, int iDamageType){
    if(g_bHasClass[iAttacker]){
        //if(GetRandomInt(1, 100) >= 95)
        //{
         //   SetWeaponToKnife(iVictim);
        //}
        if(iWeaponID == WEAPON_AK47 && GetRandomInt(1, 8) == 1){
            Shake(iVictim, 20.0);
        }

        if(iWeaponID == WEAPON_M4A4 && GetRandomInt(1, 100) >= 50){
            CodMod_Heal(iAttacker, iAttacker, RoundFloat(fDamage * 0.2));
        }
    }
}


public void CodMod_OnPlayerDie(int iAttacker, int iVictim, bool bHeadshot){
    if(g_bHasClass[iAttacker]){
        Player_RefillClip(iAttacker, -1, 1);
        CodMod_Heal(iAttacker, iAttacker, 15);


    }
}

const WeaponID g_iFirstWeaponID = WEAPON_AK47;
const WeaponID g_iSecondWeaponID = WEAPON_M4A4;
int g_iWeaponAmmos[2] = {-1};

public void CodMod_OnPlayerSpawn(int iClient){
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

stock void Shake(int iClient, float fAmp=1.0) {
  new Handle:hMessage = StartMessageOne("Shake", iClient, 1);
  PbSetInt(hMessage, "command", 0);
  PbSetFloat(hMessage, "local_amplitude", fAmp);
  PbSetFloat(hMessage, "frequency", 100.0);
  PbSetFloat(hMessage, "duration", 1.5);
  EndMessage();
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
    }
}

public void CodMod_OnWeaponCanUse(int iClient, WeaponID iWeaponID, int &iCanUse, bool bBuy){
    if(g_bHasClass[iClient] && (iWeaponID == g_iFirstWeaponID || iWeaponID == g_iSecondWeaponID)){
        iCanUse = 2;
    }
}
