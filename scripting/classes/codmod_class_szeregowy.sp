#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <th7manager>

#include <emitsoundany>

#define _IN_CODMOD_CLASS 1
#include <codmod301>
public Plugin myinfo = {
    name = "CodMod 301 - Class - Szeregowy",
    author = "th7nder",
    description = "Szeregowy Class from CodMod 301",
    version = "2.0",
    url = "http://serwery-go.pl"
};

WeaponID g_iWeapons[WEAPON_LIMIT] = {WEAPON_NONE};
WeaponID g_iCurrentWeapon[MAXPLAYERS+1] = {WEAPON_NONE};



char g_szClassName[128] = {"Szeregowy"};
char g_szDesc[256] = {"120HP, Fiveseven, Co rundę losowa broń, +7 dmg\n 1/10 na obrócenie przeciwnika o 180 stopni, +20 DMG w plecy"};
const int g_iHealth = 0;
const int g_iStartingHealth = 120;
const int g_iArmor = 0;
const int g_iDexterity = 0;
const int g_iIntelligence = 0;
int g_iClassId = 0;
bool g_bHasClass[MAXPLAYERS+1]    = {false};
bool g_bRandomWeapon[MAXPLAYERS+1] = {true};

public void OnPluginStart(){
    g_iWeapons[0] = WEAPON_FIVESEVEN;
    g_iClassId = CodMod_RegisterClass(g_szClassName, g_szDesc, g_iHealth, g_iArmor, g_iDexterity, g_iIntelligence, g_iWeapons, 0, g_iStartingHealth);
}


public bool HasZeus(int iClient)
{
    int iSize = GetEntPropArraySize(iClient, Prop_Send, "m_hMyWeapons");
    char szClassname[64];
    int iEnt = -1;
    for(int i = 0; i < iSize; i++){
        if((iEnt = GetEntPropEnt(iClient, Prop_Send, "m_hMyWeapons", i)) != -1 && IsValidEntity(iEnt)){
            GetEdictClassname(iEnt, szClassname, 64);
            if(StrEqual(szClassname, "weapon_taser")){
                return true;
            }
        }
    }

    return false;
}

public void OnPluginEnd(){
    CodMod_UnregisterClass(g_iClassId);
}


public int CodMod_OnChangeClass(int iClient, int iPrevious, int iNext){
    if(iNext != g_iClassId) {
        g_bHasClass[iClient] = false;
    } else {
        g_bHasClass[iClient] = true;
        g_bRandomWeapon[iClient] = true;
    }
}


public void CodMod_OnPlayerSpawn(int iClient)
{
    if(g_bHasClass[iClient] && g_bRandomWeapon[iClient])
    {
        GiveRandomWeapon(iClient);
    }
}

public void CodMod_OnPlayerDamaged(int iAttacker, int iVictim, float &fDamage, WeaponID iWeaponID, int iDamageType){
    if(g_bHasClass[iAttacker])
    {
        if(CodMod_GetImmuneToSkills(iVictim) && GetRandomInt(1, 10) == 1)
        {
            float fAngles[3];
            GetClientEyeAngles(iVictim, fAngles);
            fAngles[1] += 180.0;
            TeleportEntity(iVictim, NULL_VECTOR, fAngles, NULL_VECTOR);
        }

        if(isInFOV(iAttacker, iVictim) && !isInFOV(iVictim, iAttacker))
        {
           fDamage += 20.0;
        }
        fDamage += 7.0;
    }
}

public void CodMod_OnWeaponCanUse(int iClient, WeaponID iWeaponID, int &iCanUse, bool bBuy){
    if(g_bHasClass[iClient] && g_iCurrentWeapon[iClient] == iWeaponID){
        iCanUse = 2;
    }
}


public void GiveRandomWeapon(int iClient)
{
    WeaponID iRandomWeapon = WEAPON_NONE;

    do
    {
        iRandomWeapon = view_as<WeaponID>(GetRandomInt(view_as<int>(WEAPON_GLOCK), view_as<int>(WEAPON_HEALTHSHOT)));
    } while (iRandomWeapon == WEAPON_SG552 || IsWeaponGrenade(iRandomWeapon) || iRandomWeapon == WEAPON_HEALTHSHOT || iRandomWeapon == WEAPON_P250 || iRandomWeapon == WEAPON_DEAGLE || iRandomWeapon == WEAPON_KNIFE || iRandomWeapon == WEAPON_C4 || iRandomWeapon == WEAPON_KNIFE_GG || iRandomWeapon == WEAPON_DEFUSER || iRandomWeapon == WEAPON_STANDARDPISTOLS || iRandomWeapon == WEAPON_HKP2000 || iRandomWeapon == WEAPON_USP || iRandomWeapon == WEAPON_REVOLVER || iRandomWeapon == WEAPON_GLOCK || iRandomWeapon == WEAPON_ELITE || iRandomWeapon == WEAPON_FIVESEVEN || iRandomWeapon == WEAPON_CZ || iRandomWeapon == WEAPON_TEC9);
    g_iCurrentWeapon[iClient] = iRandomWeapon;
    int iSlot = 0; 
    char szClassname[64];
    Format(szClassname, sizeof(szClassname), "weapon_%s", weaponNames[iRandomWeapon]);
    if(WeaponIsPistol(iRandomWeapon))
    {
        iSlot = 1;
        int iEntity = -1;
        if((iEntity = GetPlayerWeaponSlot(iClient, iSlot)) != -1)
        {
            if(IsValidEntity(iEntity))
            {
                RemovePlayerItem(iClient, iEntity);
                RemoveEdict(iEntity);
            }

        }

        GivePlayerItem(iClient, szClassname)
    }
    else if(iRandomWeapon == WEAPON_TASER)
    {
        if(!HasZeus(iClient))
        {
            GivePlayerItem(iClient, szClassname);
        }
    }
    else if(IsWeaponGrenade(iRandomWeapon))
    {
        bool bGive = false;
        switch(iRandomWeapon)
        {
            case WEAPON_HEGRENADE:
            {
                if(!CodMod_GetPlayerNades(iClient, TH7_HE))
                {
                    bGive = true;
                }
            }

            case WEAPON_SMOKEGRENADE:
            {
                if(!CodMod_GetPlayerNades(iClient, TH7_SMOKE))
                {
                    bGive = true;
                }
            }

            case WEAPON_FLASHBANG:
            {
                if(CodMod_GetPlayerNades(iClient, TH7_FLASHBANG) < 2)
                {
                    bGive = true;
                }
            }

            case WEAPON_MOLOTOV,WEAPON_INCGRENADE:
            {
                if(!CodMod_GetPlayerNades(iClient, TH7_MOLOTOV))
                {
                    bGive = true;
                }
            }

            case WEAPON_DECOY:
            {
                if(!CodMod_GetPlayerNades(iClient, TH7_DECOY))
                {
                    bGive = true;
                }
            }

            case WEAPON_TAGRENADE:
            {
                if(!CodMod_GetPlayerNades(iClient, TH7_TACTICAL))
                {
                    bGive = true;
                }
            }
        }
        if(bGive)
        {
            GivePlayerItem(iClient, szClassname);
        }
    } else {
        int iEntity = -1;
        if((iEntity = GetPlayerWeaponSlot(iClient, iSlot)) != -1)
        {
            if(IsValidEntity(iEntity))
            {
                RemovePlayerItem(iClient, iEntity);
                RemoveEdict(iEntity);
            }
        }

        GivePlayerItem(iClient, szClassname)
    }

}

char g_szAllowedPerksWeapons[][] = {
    "zestaw rushera",
    "zestaw paranoika",
    "brożu.exe",
    "karabin kaprala",
    "awp snajper",
    "magiczny ck",
    "ssg08 snajper",
    "karabin szturmowy",
    "zmora panthli0nna",
    "ak bojownika",
    "viva la france",
    "buty luigego",
    "tajemnica komandosa",
    "turbo milka",
    "sekret mrozza",
    "obrona mahesvary",
    "sikorawp",
    "zestaw małego terrorysty",
    "zabawka egad'a",
    "dragi witboya",
}

const int g_iAllowedPerksSize = sizeof(g_szAllowedPerksWeapons);
int g_iAllowedPerks[g_iAllowedPerksSize];

public void OnMapStart(){
    for(int i = 0; i < g_iAllowedPerksSize; i++){
        g_iAllowedPerks[i] = CodMod_GetPerkId(g_szAllowedPerksWeapons[i]);
    }
}

public void CodMod_OnPerkEnabled(int iClient, int iPerkId){
    if(g_bHasClass[iClient]){
        for(int i = 0; i < g_iAllowedPerksSize; i++){
            if(iPerkId == g_iAllowedPerks[i]){
                g_bRandomWeapon[iClient] = false;
                break;
            }
            g_bRandomWeapon[iClient] = true;
        }
    }
}


public void CodMod_OnPerkDisabled(int iClient, int iPerkId)
{
    if(g_bHasClass[iClient]){
        g_bRandomWeapon[iClient] = true;
    }
}
