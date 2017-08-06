#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <dhooks>


#include <codmod301>
public Plugin:myinfo = {
  name = "Infinite ammo",
  author = "th7nder",
  description = "Infinite AMMO by th7",
  version = "1.0",
  url = "http://serwery-go.pl"
};

int g_iOffsetAmmo = -1;
int g_iOffsetPrimaryReserve = -1
int g_iOffsetPrimaryAmmo = -1;
int g_iOffsetActiveWeapon = -1;
int g_iOffsetSecondaryAmmo = -1;

public void OnPluginStart(){
    g_iOffsetAmmo = FindSendPropInfo("CCSPlayer", "m_iAmmo");
    g_iOffsetPrimaryReserve = FindSendPropInfo("CWeaponCSBase", "m_iPrimaryReserveAmmoCount");
    g_iOffsetPrimaryAmmo = FindSendPropInfo("CWeaponCSBase", "m_iPrimaryAmmoType");
    g_iOffsetSecondaryAmmo = FindSendPropInfo("CWeaponCSBase", "m_iSecondaryAmmoType");
    g_iOffsetActiveWeapon = FindSendPropInfo("CBasePlayer", "m_hActiveWeapon");

}

public void OnEntityCreated(int iEntity, const char[] szClassname){
  if(StrContains(szClassname, "weapon_") != -1){
    SDKHookEx(iEntity, SDKHook_Reload, OnWeaponReload);
  }
}


public Action OnWeaponReload(int iWeapon){
  int iOwner = GetEntPropEnt(iWeapon, Prop_Send, "m_hOwner");
  if(IsValidPlayer(iOwner) && !IsWeaponGrenade(CodMod_GetWeaponID(iWeapon))){
    //PrintToChat(iOwner, "reloading");*/
    //float fTime = GetEntPropFloat(iWeapon, Prop_Send, "m_flNextPrimaryAttack");
    CreateTimer(1.5, Timer_Restock, GetClientSerial(iOwner));
  }
}

public Action Timer_Restock(Handle hTimer, int iSerial){
  int iOwner = GetClientFromSerial(iSerial);
  if(IsValidPlayer(iOwner)){
    int iWeapon = GetEntDataEnt2(iOwner, g_iOffsetActiveWeapon);
    if(iWeapon != -1 && IsValidEdict(iWeapon)){
          WeaponID iWeaponID = CodMod_GetWeaponID(iWeapon);
          if(IsWeaponGrenade(iWeaponID) || iWeaponID == WEAPON_TASER){
            return Plugin_Stop;
          }
          int iAmmo = g_iWeaponClip[int*(iWeaponID)][1];
          if(iAmmo == -1){
            return Plugin_Stop;
          }

          SetEntData(iWeapon, g_iOffsetPrimaryReserve, iAmmo, true);
          SetEntProp(iWeapon, Prop_Send, "m_iSecondaryReserveAmmoCount", iAmmo);

          int iPrimaryAmmoType = GetEntData(iWeapon, g_iOffsetPrimaryAmmo);
          if(iPrimaryAmmoType != -1){
            SetEntData(iOwner, g_iOffsetAmmo + (iPrimaryAmmoType * 4), iAmmo, true);
          }

          int iSecondaryAmmoType = GetEntData(iWeapon, g_iOffsetSecondaryAmmo);
          if(iSecondaryAmmoType != -1){
            SetEntData(iOwner, g_iOffsetAmmo + (iSecondaryAmmoType * 4), iAmmo, true);
          }

    }
  }

  return Plugin_Stop;
}
