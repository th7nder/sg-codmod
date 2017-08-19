#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <codmod301>




public Plugin:myinfo = {
	name = "Call of Duty Mod - TeamMate",
	author = "th7nder",
	description = "CODMOD's TeamMateAttack",
	version = "1.0",
	url = "http://th7.eu"
};
public OnPluginStart()
{
    HookUserMessage(GetUserMessageId("TextMsg"), TextMsg, true);
}

public Action:TextMsg(UserMsg:msg_id, Handle:pb, players[], playersNum, bool:reliable, bool:init)
{
    if(!reliable)
    {
        return Plugin_Continue;
    }


    new String:buffer[255];
    new repeat = PbGetRepeatedFieldCount(pb, "params");

    for(new i = 0; i < repeat; i++)
    {
		PbReadString(pb, "params", buffer, sizeof(buffer), i);
		if(StrEqual(buffer, "#Cstrike_TitlesTXT_Game_teammate_attack")){
			return Plugin_Handled;
		}

		if(StrContains(buffer, "#Player_Cash_Award_") == 0 || StrContains(buffer, "#Team_Cash_Award_") == 0)
			return Plugin_Handled;
    }

    return Plugin_Continue;
}
