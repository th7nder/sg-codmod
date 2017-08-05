#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <th7manager>

#include <emitsoundany>

#define _IN_CODMOD_CLASS 1
#include <codmod301>
public Plugin myinfo = {
    name = "CodMod 301 - Class - Hawkeye",
    author = "th7nder",
    description = "Hawkeye Class from CodMod 301",
    version = "2.0",
    url = "http://serwery-go.pl"
};

WeaponID g_iWeapons[WEAPON_LIMIT] = {WEAPON_NONE};



char g_szClassName[128] = {"Hawkeye"};
char g_szDesc[256] = {"120HP, Famas, P250 \n Moduł Odrzutowy(CTRL + SPACE, 10s, jest podczas skoku niewidzialny) \n +5dmg do wszystkich broni, Granat Taktyczny"};
const int g_iHealth = 0;
const int g_iStartingHealth = 120;
const int g_iArmor = 0;
const int g_iDexterity = 0;
const int g_iIntelligence = 0;
int g_iClassId = 0;
bool g_bHasClass[MAXPLAYERS+1]    = {false};
float g_fLastJump[MAXPLAYERS+1] = {0.0};
public void OnPluginStart(){
    g_iWeapons[0] = WEAPON_FAMAS;
    g_iWeapons[1] = WEAPON_P250;
    g_iWeapons[2] = WEAPON_TAGRENADE;
    g_iClassId = CodMod_RegisterClass(g_szClassName, g_szDesc, g_iHealth, g_iArmor, g_iDexterity, g_iIntelligence, g_iWeapons, 0, g_iStartingHealth);
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

    g_fLastJump[iClient] = 0.0;
}

public Action OnPlayerRunCmd(int iClient, int &iButtons, int &iImpulse, float fVel[3], float fAngles[3], int &iWeapon) {
    if(g_bHasClass[iClient] && IsPlayerAlive(iClient))
    {
        static float g_fLastTry[MAXPLAYERS+1];
        if((iButtons & IN_JUMP) && (iButtons & IN_DUCK)  )
        {
            if(GetGameTime() - g_fLastJump[iClient] >= 10.0) {
                g_fLastJump[iClient] = GetGameTime();
                g_fLastTry[iClient] = g_fLastJump[iClient];
                Launch(iClient);
                TH7_SetInvisible(iClient);
                CreateTimer(0.75, Timer_SetVisible, GetClientSerial(iClient));
            } else if(GetGameTime() - g_fLastTry[iClient] >= 0.2){
                g_fLastTry[iClient] = GetGameTime();
                PrintToChat(iClient, "%s Do następnego uzycia zostało %.1f s!", PREFIX_SKILL, 10.0 - (GetGameTime() - g_fLastJump[iClient]));
            }
        }
    }



    return Plugin_Continue;
}

public Action Timer_SetVisible(Handle hTimer, int iSerial){
    int iClient = GetClientFromSerial(iSerial);
    if(IsValidPlayer(iClient)){
        TH7_SetVisible(iClient);
    }
}

/*public Action SDK_OnStartTouch(int iClient, int iEntity){
    if(g_bHasClass[iClient] && iEntity == 0){
        TH7_SetVisible(iClient);
        SDKUnhook(iClient, SDKHook_StartTouch, SDK_OnStartTouch);
    }

}*/

public CodMod_OnPlayerDamaged(int iAttacker, int iVictim, float &fDamage, WeaponID iWeaponID, int iDamageType){
    if(g_bHasClass[iAttacker]){
        fDamage += 5.0;
    }
}
