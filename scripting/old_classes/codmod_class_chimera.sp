#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <th7manager>

#include <emitsoundany>

#define _IN_CODMOD_CLASS 1
#define ON_FIRE 1
#define ON_POISON 1
bool g_bOnFire[MAXPLAYERS+1] = {false};
#include <codmod301>
public Plugin myinfo = {
    name = "CodMod 301 - Class - Chimera",
    author = "th7nder",
    description = "Chimera Class from CodMod 301",
    version = "2.0",
    url = "http://serwery-go.pl"
};

WeaponID g_iWeapons[WEAPON_LIMIT] = {WEAPON_NONE};


int g_iBeamSprite = -1;
int g_iHaloSprite = -1;
char g_szClassName[128] = {"Chimera"};
char g_szDesc[256] = {"110HP, M4A4, Glock, Wszystkie granaty \n leczy sie jednorazowo 65hp (codmod_skill) \n 1/10 na zadanie 10 dmg przez 4 sekundy wokół przeciwnika(300 unitów)"};
const int g_iHealth = 0;
const int g_iStartingHealth = 110;
const int g_iArmor = 0;
const int g_iDexterity = 0;
const int g_iIntelligence = 0;
int g_iClassId = 0;
bool g_bHasClass[MAXPLAYERS+1]    = {false};

float g_fLastUse[MAXPLAYERS+1] = {0.0};

int g_iUsed[MAXPLAYERS+1] = {0};
public void OnPluginStart(){
    g_iWeapons[0] = WEAPON_M4A4;
    g_iWeapons[1] = WEAPON_GLOCK;
    g_iWeapons[2] = WEAPON_HEGRENADE;
    g_iWeapons[3] = WEAPON_MOLOTOV;
    g_iWeapons[4] = WEAPON_FLASHBANG;
    g_iWeapons[5] = WEAPON_SMOKEGRENADE;
    g_iClassId = CodMod_RegisterClass(g_szClassName, g_szDesc, g_iHealth, g_iArmor, g_iDexterity, g_iIntelligence, g_iWeapons, 0, g_iStartingHealth);
}

public void OnPluginEnd(){
    CodMod_UnregisterClass(g_iClassId);
}

public void OnMapStart(){
    g_iBeamSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
    g_iHaloSprite = PrecacheModel("materials/sprites/halo.vmt");
}


public int CodMod_OnChangeClass(int iClient, int iPrevious, int iNext){
    if(iNext != g_iClassId) {
        g_bHasClass[iClient] = false;
    } else {
        g_bHasClass[iClient] = true;
    }

    g_bOnFire[iClient] = false;
    g_fLastUse[iClient] = 0.0;
    g_iUsed[iClient] = 0;
}

public CodMod_OnPlayerSpawn(int iClient){
    g_bOnFire[iClient] = false;
    g_fLastUse[iClient] = 0.0;
    g_iUsed[iClient] = 0;
}

stock void PoisonPlayer(int iAttacker, int iVictim){
    PrintToChat(iVictim, "%s Zostałeś otruty!", PREFIX_SKILL);
    CodMod_Burn(iAttacker, iVictim, 4.0, 1.0, 10.0);
  //TE_SetupBeamFollow(iVictim, g_iBeamSprite,	0, 4.0, 5.0, 5.0, 1, {0, 100, 0, 255});
    //TE_SendToAll();
}

stock BeamRing(int color[4], float vec[3]){
    vec[2] += 10.0;
    TE_SetupBeamRingPoint(vec, 20.0, 500.0, g_iBeamSprite, g_iHaloSprite, 0, 10, 0.6, 10.0, 0.5, color, 10, 0);
    TE_SendToAll();
}

public void CodMod_OnPlayerDie(int iAttacker, int iVictim, bool bHeadshot){
    if(g_bHasClass[iAttacker] && GetRandomInt(1, 100) >= 75){
        CodMod_PerformEntityExplosion(iVictim, iAttacker, 100.0 + (float(CodMod_GetWholeStat(iVictim, INT)) * 0.5), 200, 0.0, TH7_DMG_EXPLODE);
    }
}

public CodMod_OnPlayerDamaged(int iAttacker, int iVictim, float &fDamage, WeaponID iWeaponID, int iDamageType){
    if(g_bHasClass[iAttacker] && GetRandomInt(1, 10) == 1 && !g_bOnFire[iVictim])
    {
        g_bOnFire[iVictim] = true;
        float fPosition[3], fTargetPosition[3];
        int iTeam = GetClientTeam(iAttacker);
        GetClientAbsOrigin(iVictim, fPosition);
        BeamRing({0, 100, 0, 255}, fPosition);
        PoisonPlayer(iAttacker, iVictim);
        PrintToChat(iAttacker, "%s Otrułeś gracza %s!", PREFIX_SKILL, iVictim);
        for(int i = 1; i <= MaxClients; i++){
            if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) != iTeam && !g_bOnFire[i] && i != iVictim){
                GetClientAbsOrigin(i, fTargetPosition);
                if(GetVectorDistance(fPosition, fTargetPosition) <= 300.0){
                    g_bOnFire[i] = true;
                    PoisonPlayer(iAttacker, i);
                }
            }
        }
    }
}


public void CodMod_OnClassSkillUsed(int iClient){
    if(!g_bHasClass[iClient] || !IsPlayerAlive(iClient))
        return;

    if(g_iUsed[iClient] + 1 > 1){
        PrintToChat(iClient, "%s Już się uleczyłeś w tej rundzie!!", PREFIX_SKILL);
        return;
    }
    g_iUsed[iClient]++;
    CodMod_Heal(iClient, iClient, 65);
}
