#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <codmod301>


int g_iHealthshotOwners[2048] = {-1};
public void OnPluginStart()
{

        RegAdminCmd("health", Give, ADMFLAG_GENERIC);
}

public Action Give(int iClient, int iArgs)
{
        int entity = GivePlayerItem(iClient, "weapon_healthshot");
        g_iHealthshotOwners[entity] = iClient;
}




public OnEntityDestroyed(entity)
{
        char name[32];
        GetEdictClassname(entity, name, sizeof(name));
        if (!strcmp(name, "weapon_healthshot"))
        {   
                LogMessage("Entity Destoryed: (index %i , name %s , client %i )", entity, name, g_iHealthshotOwners[entity]);
        }
}
