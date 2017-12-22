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
    name = "CodMod 301 - Class - Szpieg",
    author = "th7nder",
    description = "Szpieg Class from CodMod 301",
    version = "2.0",
    url = "http://serwery-go.pl"
};

WeaponID g_iWeapons[WEAPON_LIMIT] = {WEAPON_NONE};

char g_szClassName[128] = {"Szpieg"};
char g_szDesc[256] = {"120HP, USP-S, 2x Flashbang \n 1/5 na 2x dmg, 0.45dmg/1str USP Cichy Chód \n +5 dmg do wszystkich broni \n Niewidoczny na radarze"};
const int g_iHealth = 0;
const int g_iStartingHealth = 120;
const int g_iArmor = 0;
const int g_iDexterity = 30;
const int g_iIntelligence = 0;
int g_iClassId = 0;
bool g_bHasClass[MAXPLAYERS+1]    = {false};
public void OnPluginStart(){
    g_iWeapons[0] = WEAPON_USP;
    g_iWeapons[1] = WEAPON_FLASHBANG;
    g_iWeapons[2] = WEAPON_FLASHBANG;
    g_iClassId = CodMod_RegisterClass(g_szClassName, g_szDesc, g_iHealth, g_iArmor, g_iDexterity, g_iIntelligence, g_iWeapons, 0, g_iStartingHealth);
}

public void OnPluginEnd(){
    CodMod_UnregisterClass(g_iClassId);
}

char g_szCTModel[128] = {"models/player/ctm_idf_variantD.mdl"};
char g_szTTModel[128] = {"models/player/tm_leet_variantD.mdl"};


public void OnMapStart(){
  PrecacheModel(g_szCTModel);
  PrecacheModel(g_szTTModel);
}

public int CodMod_OnChangeClass(int iClient, int iPrevious, int iNext){
    if(iPrevious == g_iClassId){
        TH7_DisableSilentFootsteps(iClient);
        TH7_SetRadarVisibility(iClient, true);
    }

    if(iNext != g_iClassId) {
        g_bHasClass[iClient] = false;
    } else {
        g_bHasClass[iClient] = true;
        TH7_EnableSilentFootsteps(iClient);
        TH7_SetRadarVisibility(iClient, false);
        UpdateModel(iClient);
    }

}

void UpdateModel(int iClient)
{
  if(!IsPlayerAlive(iClient))
    return;

  if(GetClientTeam(iClient) == CS_TEAM_T){

    if(GetCurrentMapModel(CS_TEAM_CT, g_szCTModel, sizeof(g_szCTModel))){
      SetEntityModel(iClient, g_szCTModel);
      LogMessage("UpdateModel from tt to ct: %s", g_szCTModel);
    }


  } else {
    if(GetCurrentMapModel(CS_TEAM_T, g_szTTModel, sizeof(g_szTTModel)))
    {
      LogMessage("UpdateModel from ct to tt: %s", g_szTTModel);
      SetEntityModel(iClient, g_szTTModel);
    }

  }
}

public CodMod_OnPlayerDamaged(int iAttacker, int iVictim, float &fDamage, WeaponID iWeaponID, int iDamageType){
    if(g_bHasClass[iAttacker]){
        fDamage += 5.0;
        if(iWeaponID == WEAPON_USP)
        {
          fDamage += (float(CodMod_GetWholeStat(iAttacker, STRENGTH)) * 0.15);
        }

        if(iWeaponID == WEAPON_USP && GetRandomInt(1, 100) >= 80){
            fDamage *= 2.0;
        }

    }
}

public void CodMod_OnPlayerSpawn(int iClient){
  if(g_bHasClass[iClient]){
    TH7_EnableSilentFootsteps(iClient);
    UpdateModel(iClient);
  }
}
