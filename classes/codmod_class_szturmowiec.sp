#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <th7manager>
#include <currentmapmodel>

#include <emitsoundany>

#define _IN_CODMOD_CLASS 1
#include <codmod301>
public Plugin myinfo = {
    name = "CodMod 301 - Class - Szturmowiec",
    author = "th7nder",
    description = "Szturmowiec Class from CodMod 301",
    version = "2.0",
    url = "http://serwery-go.pl"
};

WeaponID g_iWeapons[WEAPON_LIMIT] = {WEAPON_NONE};

char g_szClassName[128] = {"Szturmowiec"};
char g_szDesc[256] = {"120HP, M4A1-S Dual Beretta, Może kupować granaty \n 1/15 na oślepienie, \n +5 dmg do wszystkich broni \n Ciche chodzenie"};
const int g_iHealth = 0;
const int g_iStartingHealth = 120;
const int g_iArmor = 0;
const int g_iDexterity = 0;
const int g_iIntelligence = 0;
int g_iClassId = 0;
bool g_bHasClass[MAXPLAYERS+1]    = {false};
public void OnPluginStart(){
    g_iWeapons[0] = WEAPON_M4A1;
    g_iWeapons[1] = WEAPON_ELITE;
    g_iClassId = CodMod_RegisterClass(g_szClassName, g_szDesc, g_iHealth, g_iArmor, g_iDexterity, g_iIntelligence, g_iWeapons, 0, g_iStartingHealth);
}

public void OnPluginEnd(){
    CodMod_UnregisterClass(g_iClassId);
}

public int CodMod_OnChangeClass(int iClient, int iPrevious, int iNext){
    if(iPrevious == g_iClassId){
        TH7_DisableSilentFootsteps(iClient);
    }

    if(iNext != g_iClassId) {
        g_bHasClass[iClient] = false;
    } else {
        g_bHasClass[iClient] = true;
        TH7_EnableSilentFootsteps(iClient);
    }

}

int g_iColors[] = {0, 204, 204, 230};

public CodMod_OnPlayerDamaged(int iAttacker, int iVictim, float &fDamage, WeaponID iWeaponID, int iDamageType){
    if(g_bHasClass[iAttacker]){
        if(GetRandomInt(1, 15) == 1 && iWeaponID != WEAPON_MOLOTOV && iWeaponID != WEAPON_INCGRENADE){
          CodMod_FadeClient(iVictim, 50, g_iColors, 1000);
        }
        fDamage+=5.0;
    }
}

public void CodMod_OnPlayerSpawn(int iClient){
  if(g_bHasClass[iClient]){
    TH7_EnableSilentFootsteps(iClient);
  }
}

public void CodMod_OnWeaponCanUse(int iClient, WeaponID iWeaponID, int &iCanUse, bool bBuy){
    if(g_bHasClass[iClient] && (iWeaponID == WEAPON_FLASHBANG || iWeaponID == WEAPON_HEGRENADE || iWeaponID == WEAPON_MOLOTOV || iWeaponID == WEAPON_DECOY || iWeaponID == WEAPON_INCGRENADE || iWeaponID == WEAPON_SMOKEGRENADE)){
        iCanUse = 2;
    }
}
