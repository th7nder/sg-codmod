#include <sourcemod>
#include <cstrike>
#include <currentmapmodel>

bool g_bTTModelFetched = false;
char g_szCurrentTTModel[255];

bool g_bCTModelFetched = false;
char g_szCurrentCTModel[255];



// bool GetCurrentMapModel(int iTeam, char szModel[], int iMaxSize)
public int Native_GetCurrentMapModel(Handle hPlugin, int iNumParams)
{
	if(iNumParams != 3)
	{
		LogError("Misusage of GetCurrentMapModel Plugin | Native requires 3 params");
		return 0;
	}

	int iTeam = GetNativeCell(1);
	int iSize = GetNativeCell(3);
	switch(iTeam)
	{
		case CS_TEAM_T:
		{
			if(!g_bTTModelFetched)
			{
				LogMessage("Fetching model that wasn't set yet - Terrorist");
				return 0;
			}

			SetNativeString(2, g_szCurrentTTModel, iSize);
			return 1;
		}

		case CS_TEAM_CT:
		{
			if(!g_bCTModelFetched)
			{
				LogMessage("Fetching model that wasn't set yet - CounterTerrorist");
				return 0;
			}

			SetNativeString(2, g_szCurrentCTModel, iSize);
			return 1;
		}

		default:
		{
			LogError("There is no model for such team! Use CS_TEAM_CT || CS_TEAM_T");
			return 0;
		}
	}

	return 0;
}

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] szError, int iMaxError){
    CreateNative("GetCurrentMapModel", Native_GetCurrentMapModel);
    return APLRes_Success;
}

public void OnPluginStart()
{
	HookEvent("player_spawn", Event_OnPlayerSpawn, EventHookMode_Post);
}

public void OnMapStart()
{
	g_bCTModelFetched = false;
	g_bTTModelFetched = false;
}

public Action Event_OnPlayerSpawn(Event hEvent, const char[] szEventName, bool bBroadcast)
{
	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
	switch(GetClientTeam(iClient))
	{
		case CS_TEAM_T:
		{
			if(!g_bTTModelFetched)
			{
				GetClientModel(iClient, g_szCurrentTTModel, sizeof(g_szCurrentTTModel));
				if(StrContains(g_szCurrentTTModel, "models/player/custom_player/legacy/tm") != -1) // check if default model
				{
					g_bTTModelFetched = true;
				}
			}
		}

		case CS_TEAM_CT:
		{
			if(!g_bCTModelFetched)
			{
				GetClientModel(iClient, g_szCurrentCTModel, sizeof(g_szCurrentCTModel));
				if(StrContains(g_szCurrentCTModel, "models/player/custom_player/legacy/ctm") != -1) // check if default model
				{
					g_bCTModelFetched = true;
				}
			}
		}
	}
}