#include <sourcemod>
#include <cstrike>
#include <entity>
#include <sdktools>
#include <sdkhooks>
#define _IN_CODMOD_ENGINE 1

int g_iOffsetActiveWeapon = -1;
#include <codmod301>
#include <smlib>
#include <emitsoundany>

#define CLASS_LIMIT 35
#define PERK_LIMIT 140
#define INFO_LIMIT 19



/**************************************************/
bool g_bFreezed[MAXPLAYERS+1] = {false};

/**************************************************/
Handle g_hSelectClassMenus[MAXPLAYERS+1] = {INVALID_HANDLE};

int g_iCommandoSecret = -1;
int g_iNanoarmor = -1;
int g_iTrykot = -1;
int g_iPrzeszycie = -1;
int g_iTypowySeba = -1;

int g_iWeaponCanUse[MAXPLAYERS+1][2048 + 1];

char g_saGrenadeWeaponNames[][] = {
    "weapon_flashbang",
    "weapon_molotov",
    "weapon_smokegrenade",
    "weapon_hegrenade",
    "weapon_decoy",
    "weapon_incgrenade",
    "weapon_tagrenade"
};

char g_szSidGiveItem[][64] = {
    "37282907", //Mahesvara
    "29118382", //th7
    "34914398", //Silver
    "47438709", //Nobody
    "32549176", //arek
};

int g_iaGrenadeOffsets[sizeof(g_saGrenadeWeaponNames)];


char g_saGrenadeAmmoTypes[][] = {
    "AMMO_TYPE_HEGRENADE",
    "AMMO_TYPE_FLASHBANG",
    "AMMO_TYPE_SMOKEGRENADE",
    "AMMO_TYPE_MOLOTOV",
    "AMMO_TYPE_DECOY"
};

Handle g_hWeaponCanUsePerk = INVALID_HANDLE;
Handle g_hOnPerkSkillUsed = INVALID_HANDLE;


enum registerIdxs {
    NAME = 0,
    DESC,
    CLANTAG
};


float g_fBlockedSkill[MAXPLAYERS+1] = {0.0};


new g_isPlayerVip[MAXPLAYERS+1] = {false};
new clientStats[MAXPLAYERS + 1][statsIdxs];
new Handle:hDatabase = INVALID_HANDLE;


new g_PlayersInfo[MAXPLAYERS +1][PlayerInfo];

new registeredClasses = 0;
new String:classes[CLASS_LIMIT][registerIdxs][256];
new classesStats[CLASS_LIMIT][statsIdxs];
new WeaponID:classesWeapons[CLASS_LIMIT][WEAPON_LIMIT];
new classesIsVip[CLASS_LIMIT] = {false};

new registeredPerks = 0;
new String:perks[PERK_LIMIT][registerIdxs][256];

int g_iCustomPerkPermission[MAXPLAYERS+1][PERK_LIMIT];


new changedClass[MAXPLAYERS+1] = {0};


Handle g_hDamagePerkForward = INVALID_HANDLE;
new Handle:g_DamageForward;
new Handle:g_WeaponUseForward;
new Handle:g_OnPlayerDieForward;
new Handle:g_OnPlayerSpawnForward;
new Handle:g_OnPerkEnabled;
new Handle:g_OnPerkDisabled;
new Handle:g_OnGiveExp;
new Handle:g_OnGiveExpMultiply;
new Handle:g_OnWeakenPerk;
new Handle:g_OnChangeClass;

new Handle:g_specTimer;

Handle g_hOnClassSkillUsed = INVALID_HANDLE;
Handle g_hOnTH7Dmg = INVALID_HANDLE;
Handle g_hOnTH7DmgPost = INVALID_HANDLE;


new g_bIsDefusing[MAXPLAYERS+1] = {false};

new g_PlayersClassesLevelInfo[MAXPLAYERS+1][CLASS_LIMIT + 1];

bool g_bImmuneToSkills[MAXPLAYERS+1] = {false};

int g_iStatsSpeeds[] = {
    1,
    2,
    5,
    10,
    20
};

int g_iStatsSpendingSpeed[MAXPLAYERS+1];

bool g_bTradeBlockade[MAXPLAYERS+1] = {false};

WeaponID g_iWeaponIDs[2048 + 1] = {WEAPON_NONE};
int g_iOffsetLaggedMovementValue = -1;
int g_iOffsetArmorValue;
int g_iFire, g_iExplosionSprite, g_iHaloSprite;//, g_iBeamSprite;

int g_iPreviousButtons[MAXPLAYERS+1] = {0};

float g_fLastPistolShot[MAXPLAYERS+1] = {0.0};
public Plugin:myinfo = {
    name = "Call of Duty Mod",
    author = "th7nder",
    description = "Imitiates Call of Duty in CS:S and CS:GO",
    version = "1.3",
    url = "http://th7.eu"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max){
    CreateNative("CodMod_DealDamage", CodMod_OnDealDamage);
    CreateNative("CodMod_GiveRandomPerk", CodMod_OnGiveRandomPerk);
    CreateNative("CodMod_RegisterClass", CodMod_OnRegisterClass);
    CreateNative("CodMod_RegisterPerk", CodMod_OnRegisterPerk);
    CreateNative("CodMod_UnregisterClass", CodMod_OnUnregisterClass);
    CreateNative("CodMod_UnregisterPerk", CodMod_OnUnregisterPerk);
    CreateNative("CodMod_GetClassId", CodMod_OnGetClassId);
    CreateNative("CodMod_SetStat", CodMod_OnSetStat);
    CreateNative("CodMod_GetStat", CodMod_OnGetStat);
    CreateNative("CodMod_GetPlayerInfo", CodMod_OnGetPlayerInfo);
    CreateNative("CodMod_SetPlayerInfo", CodMod_OnSetPlayerInfo);
    CreateNative("CodMod_GiveExp", CodMod_OnAddExp);
    CreateNative("CodMod_RegisterClassStrength", CodMod_OnRegisterClassStrength);
    CreateNative("CodMod_RegisterClassGravity", CodMod_OnRegisterClassGravity);
    CreateNative("CodMod_GetWeaponIntID", CodMod_OnGetWeaponIntID);
    CreateNative("CodMod_PerformEntityExplosion", Native_PerformEntityExplosion);
    CreateNative("CodMod_GetMaxHP", Native_GetMaxHP);
    CreateNative("CodMod_GetPlayerNades", Native_GetPlayerNades);
    CreateNative("CodMod_GetPerkId", Native_GetPerkId);
    CreateNative("CodMod_GetRoundIndex", Native_GetRoundIndex);
    CreateNative("CodMod_Freeze", Native_Freeze);
    CreateNative("CodMod_RadiusFreeze", Native_RadiusFreeze);
    CreateNative("CodMod_DestroyPerk", Native_DestroyPerk);
    CreateNative("CodMod_BlockSkill", Native_BlockSkill);
    CreateNative("CodMod_SetPerk", Native_SetPerk);
    CreateNative("CodMod_GetPerkName", Native_GetPerkName);
    CreateNative("CodMod_SetImmuneToSkills", Native_SetImmuneToSkills);
    CreateNative("CodMod_GetImmuneToSkills", Native_GetImmuneToSkills);
    CreateNative("CodMod_SetWeaponID", Native_SetWeaponID);

    CreateNative("CodMod_SetCustomPerkPermission", Native_SetCustomPerkPermission);
    CreateNative("CodMod_GetCustomPerkPermission", Native_GetCustomPerkPermission);

    return APLRes_Success;
}

public int Native_SetCustomPerkPermission(Handle hPlugin, int iArgs)
{
    int iClient = GetNativeCell(1);
    int iPerkId = GetNativeCell(2);
    int iValue = GetNativeCell(3);

    g_iCustomPerkPermission[iClient][iPerkId] = iValue;

    return 0;
}

public int Native_GetCustomPerkPermission(Handle hPlugin, int iArgs)
{
    int iClient = GetNativeCell(1);
    int iPerkId = GetNativeCell(2);

    return g_iCustomPerkPermission[iClient][iPerkId];
}

public int Native_SetWeaponID(Handle hPlugin, int iArgs)
{
    int iEntity = GetNativeCell(1);
    WeaponID iWeaponID = view_as<WeaponID>(GetNativeCell(2));

    g_iWeaponIDs[iEntity] = iWeaponID;
}

public int Native_SetImmuneToSkills(Handle hPlugin, int iArgs)
{
    int iClient = GetNativeCell(1);
    bool bValue = view_as<bool>(GetNativeCell(2));

    g_bImmuneToSkills[iClient] = bValue;
}

public int Native_GetImmuneToSkills(Handle hPlugin, int iArgs)
{
    int iClient = GetNativeCell(1);

    return g_bImmuneToSkills[iClient];
}

UserMsg g_msgHudMsg;
Handle g_hGameConf = INVALID_HANDLE;

Handle g_hOnPerkRegistered = INVALID_HANDLE;
public OnPluginStart(){
    g_hGameConf = LoadGameConfigFile("grenades.games");
    g_msgHudMsg = GetUserMessageId("HudMsg");
    g_iOffsetActiveWeapon = FindSendPropInfo("CBasePlayer", "m_hActiveWeapon");

    g_hOnPerkRegistered = CreateGlobalForward("CodMod_OnPerkRegistered", ET_Ignore, Param_Cell, Param_String);
    g_OnChangeClass = CreateGlobalForward("CodMod_OnChangeClass", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
    g_DamageForward = CreateGlobalForward("CodMod_OnPlayerDamaged", ET_Ignore, Param_Cell, Param_Cell, Param_FloatByRef, Param_Cell, Param_Cell);
    g_hDamagePerkForward = CreateGlobalForward("CodMod_OnPlayerDamagedPerk", ET_Ignore, Param_Cell, Param_Cell, Param_FloatByRef, Param_Cell, Param_Cell);
    g_OnPlayerDieForward = CreateGlobalForward("CodMod_OnPlayerDie", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
    g_WeaponUseForward = CreateGlobalForward("CodMod_OnWeaponCanUse", ET_Single, Param_Cell, Param_Cell, Param_CellByRef, Param_Cell);
    g_hWeaponCanUsePerk = CreateGlobalForward("CodMod_OnWeaponCanUsePerk", ET_Single, Param_Cell, Param_Cell, Param_CellByRef, Param_Cell);
    g_OnPlayerSpawnForward = CreateGlobalForward("CodMod_OnPlayerSpawn", ET_Ignore, Param_Cell);
    g_OnPerkEnabled = CreateGlobalForward("CodMod_OnPerkEnabled", ET_Ignore, Param_Cell, Param_Cell);
    g_OnPerkDisabled = CreateGlobalForward("CodMod_OnPerkDisabled", ET_Ignore, Param_Cell, Param_Cell);
    g_OnGiveExp = CreateGlobalForward("CodMod_OnGiveExp", ET_Ignore, Param_Cell, Param_Cell, Param_CellByRef, Param_Cell);
    g_OnGiveExpMultiply = CreateGlobalForward("CodMod_OnGiveExpMultiply", ET_Ignore, Param_Cell, Param_FloatByRef);
    g_OnWeakenPerk = CreateGlobalForward("CodMod_OnWeakenPerk", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
    g_hOnClassSkillUsed = CreateGlobalForward("CodMod_OnClassSkillUsed", ET_Ignore, Param_Cell);
    g_hOnPerkSkillUsed = CreateGlobalForward("CodMod_OnPerkSkillUsed", ET_Ignore, Param_Cell);
    g_hOnTH7Dmg = CreateGlobalForward("CodMod_OnTH7Dmg", ET_Ignore, Param_Cell, Param_Cell, Param_FloatByRef, Param_Cell);
    g_hOnTH7DmgPost = CreateGlobalForward("CodMod_OnTH7DmgPost", ET_Ignore, Param_Cell, Param_Cell, Param_FloatByRef, Param_Cell);


    Format(classes[0][NAME], 128, "Brak klasy");
    Format(classes[0][DESC], 128, "Wybierz klasę, wpisując: !klasa");
    Format(classes[0][CLANTAG], 128, "[Brak klasy]");
    Format(perks[0][NAME], 128, "Brak perku");
    Format(perks[0][DESC], 128, "Zabij kogoś, aby otrzymać perk!");

    SQL_Initialize();
    RegConsoleCmd("klasa", Menu_SelectClass);
    RegConsoleCmd("klasy", Menu_ClassInfo);
    RegConsoleCmd("staty", Menu_Stats);
    RegConsoleCmd("perk", Info_Perk);
    RegConsoleCmd("r", Reset_Stats);
    RegConsoleCmd("p", Info_Perk);
    RegConsoleCmd("i", Display_ClassInfo2);
    RegConsoleCmd("d", Drop_Perk);
    RegConsoleCmd("wyrzuc", Drop_Perk);
    RegConsoleCmd("wyrzucperk", Drop_Perk);
    RegConsoleCmd("wyrzuć", Drop_Perk);
    RegConsoleCmd("wyrzućperk", Drop_Perk);
    RegConsoleCmd("perki", Menu_PerkInfo);
    RegConsoleCmd("info", Display_ClassInfo2);
    RegConsoleCmd("reset", Reset_Stats);
    RegConsoleCmd("daj", Regive_Perk);
    RegConsoleCmd("dajperk", Regive_Perk);
    RegConsoleCmd("wymiana", Exchange_Perk);
    RegConsoleCmd("wymień", Exchange_Perk);
    RegConsoleCmd("wymien", Exchange_Perk);
    RegConsoleCmd("top15", Display_Top15);
    RegConsoleCmd("bw", Exchange_Blockade);
    HookEvent("player_spawn", Event_OnPlayerSpawn);
    HookEvent("player_death", Event_OnPlayerDie);
    HookEvent("bomb_planted", Event_OnBombPlanted);
    HookEvent("bomb_exploded", Event_OnBombExploded);
    HookEvent("bomb_defused", Event_OnBombDefused);
    HookEvent("hostage_rescued", Event_OnHostageRescued);
    HookEvent("round_end", Event_OnRoundEnd);
    HookEvent("round_start", Event_OnRoundStart);
    HookEvent("round_mvp", Event_OnRoundMVP);
    HookEvent("weapon_fire", Event_OnWeaponFire);

    HookEvent("bomb_begindefuse", Event_OnBombBeginDefuse);
    HookEvent("bomb_abortdefuse", Event_OnBombAbortDefuse);


    RegConsoleCmd("codmod_skill", Command_OnCodModSkill);
    RegConsoleCmd("codmod_special", Command_OnCodModSkill);

    RegConsoleCmd("codmod_perk", Command_OnCodModPerk);
    RegConsoleCmd("codmod_special_perk", Command_OnCodModPerk);

    RegAdminCmd("th7perk", Command_GivePerk, ADMFLAG_CUSTOM6);

    HookUserMessage(GetUserMessageId("SayText2"), SayText2, true);
    g_iOffsetLaggedMovementValue = FindSendPropInfo("CBasePlayer", "m_flLaggedMovementValue");
    g_iOffsetArmorValue = FindSendPropInfo("CCSPlayer", "m_ArmorValue");

    RegConsoleCmd("bindy", Command_Binds);

    AddCommandListener(Listener_Buy, "buy")
}


public Action Listener_Buy(int client, const char[] szCommand, int iArgc)
{
    char weapon[128];
    GetCmdArg(1, weapon, sizeof(weapon));
    if(StrEqual(weapon, "fn57"))
    {
        Format(weapon, sizeof(weapon), "fiveseven");
    }


    if(StrContains(weapon, "defuser") != -1)
        return Plugin_Continue;

    if(StrContains(weapon, "g3sg1") != -1 || StrContains(weapon, "scar20") != -1){
        return Plugin_Handled;
    }

    if(StrEqual(classes[g_PlayersInfo[client][CLASS]][NAME], "Szpieg [Premium]")){
        if(WeaponIsPistol(CodMod_GetWeaponIDByName(weapon))){
            return Plugin_Continue;
        }
    }

    WeaponID iWeaponID = CodMod_GetWeaponIDByName(weapon);
    int canUseForward = 1;
    Call_StartForward(g_WeaponUseForward);
    Call_PushCell(client);
    Call_PushCell(iWeaponID);
    Call_PushCellRef(canUseForward);
    Call_PushCell(true);
    Call_Finish();

    Call_StartForward(g_hWeaponCanUsePerk);
    Call_PushCell(client);
    Call_PushCell(iWeaponID);
    Call_PushCellRef(canUseForward);
    Call_PushCell(true);
    Call_Finish();


    if(canUseForward == 0){
        return Plugin_Handled;
    }

    if(canUseForward == 2){
        return Plugin_Continue;
    }


    return Plugin_Handled;
}

public int Native_GetPerkName(Handle hPlugin, int iNumParams)
{
    int iPerkId = GetNativeCell(1);
    SetNativeString(2, perks[iPerkId][NAME], 64);
    return 0;
}

public bool canGiveItem(char szAuthId[64]) {
    for(int i = 0; i < sizeof(g_szSidGiveItem); i++) {
        if(StrContains(szAuthId, g_szSidGiveItem[i]) != -1) {
            return true;
        }
    }
    return false;
}

public Action Command_GivePerk(int iClient, int iArgs)
{
    char szAuthId[64];
    GetClientAuthId(iClient, AuthId_Steam2, szAuthId, 64);
    if(canGiveItem(szAuthId))
    {
        char szArgs[128];
        GetCmdArgString(szArgs, 128);
        for(int i = 1; i <= registeredPerks; i++)
        {
            if(StrContains(szArgs, perks[i][NAME], false) != -1)
            {
                LogMessage("th7perk: %s %s", szArgs, szAuthId);
                PrintToChat(iClient, "%sOtrzymałeś perk! %s", PREFIX_INFO, perks[SetPerk(iClient, i, 100)][NAME]);
                break;
            }
        }
    }

    return Plugin_Handled;
}

public int Native_SetPerk(Handle hPlugin, int iNumParams)
{
    int iClient = GetNativeCell(1);
    int iPerkId = GetNativeCell(2);
    int iPerkArmor = GetNativeCell(3);
    Call_PerkDisabled(iClient);
    SetPerk(iClient, iPerkId, iPerkArmor);
    return 0;
}

public int Native_BlockSkill(Handle hPlugin, int iNumParams)
{
    int iClient = GetNativeCell(1);
    float fTime = view_as<float>(GetNativeCell(2));

    g_fBlockedSkill[iClient] = GetGameTime() + fTime;
}

public int Native_DestroyPerk(Handle hPlugin, int iNumParams)
{
    int iClient = GetNativeCell(1);
    CodMod_WeakenPerk(iClient, 100, 100);
}

public Action Command_Binds(int iClient, int iArgs){
    if(IsClientInGame(iClient)){
        PrintToChat(iClient, "%s Bindy to: codmod_skill oraz codmod_perk", PREFIX_INFO);
    }

    return Plugin_Handled;
}

public Action Command_OnCodModSkill(int iClient, int iArgs){
    if(!CodMod_GetClass(iClient) || !IsClientInGame(iClient)){
        return Plugin_Handled;
    }

    if(GetGameTime() < g_fBlockedSkill[iClient])
    {
        PrintToChat(iClient, "%s Twoje skille zostały zablokowane przez impuls EMP!", PREFIX_INFO);
        return Plugin_Handled;
    }

    Call_StartForward(g_hOnClassSkillUsed);
    Call_PushCell(iClient);
    Call_Finish();

    return Plugin_Handled;
}

public Action Command_OnCodModPerk(int iClient, int iArgs){
    if(!CodMod_GetClass(iClient) || !IsClientInGame(iClient)){
        return Plugin_Handled;
    }

    Call_StartForward(g_hOnPerkSkillUsed);
    Call_PushCell(iClient);
    Call_Finish();

    return Plugin_Handled;
}

public Action Exchange_Blockade(int iClient, int iArgs){
    if(IsClientInGame(iClient)){
        g_bTradeBlockade[iClient] = !g_bTradeBlockade[iClient];
        if(g_bTradeBlockade[iClient]){
            PrintToChat(iClient, "%s Blokada na wymiany włączona!", PREFIX_INFO);
        } else {
            PrintToChat(iClient, "%s Blokada na wymiany wyłączona!", PREFIX_INFO);
        }
    }
}

public Action:SayText2(UserMsg:msg_id, Handle:pb, players[], playersNum, bool:reliable, bool:init) {
    if(!reliable)
    return Plugin_Continue;

    new client = PbReadInt(pb, "ent_idx");
    new String:sBuffer[255];
    PbReadString(pb, "params", sBuffer, sizeof(sBuffer), 0);
    Format(sBuffer, 255, "[Lv. %d]%s %s", CodMod_GetLevel(client), classes[g_PlayersInfo[client][CLASS]][CLANTAG], sBuffer);
    //ReplaceString(sBuffer, 255, " [Premium]", "", false);
    PbSetString(pb, "params", sBuffer, 0);
    return Plugin_Continue;
}



public CodMod_GetReqExp(client){
    int iLevel = CodMod_GetLevel(client);
    if(iLevel > 125){
        return iLevel * 1000;
    }
    return iLevel * 500;
}

public CodMod_GetExpForKill(victim) {
    //return 200;
    return 300;
    //return 750;
}


public int CodMod_OnSetStat(Handle hPlugin, int iNumParams){
    if(iNumParams < 3){
        LogError("CHUJOWY USAGE: CodMod_OnSetStat");
        return 0;
    }

    int iClient = GetNativeCell(1);
    if(!IsValidPlayer(iClient)){
        return 0;
    }



    statsIdxs iStat = view_as<statsIdxs>(GetNativeCell(2));
    int iAmount = GetNativeCell(3);
    clientStats[iClient][iStat] = iAmount;

    return 0;
}

public int CodMod_OnGetStat(Handle hPlugin, int iNumParams){
    if(iNumParams < 2){
        LogError("CHUJOWY USAGE: CodMod_OnGetStat");
        return 0;
    }

    int iClient = GetNativeCell(1);
    if(!IsValidPlayer(iClient)){
        return 0;
    }
    statsIdxs iStat = view_as<statsIdxs>(GetNativeCell(2));

    return clientStats[iClient][iStat];
}


public int CodMod_OnGetWeaponIntID(Handle hPlugin, int iNumParams){
    int weapon = GetNativeCell(1);
    if(weapon < MAXPLAYERS || !IsValidEntity(weapon)){
        return -1;
    }

    if(g_iWeaponIDs[weapon] != WEAPON_NOT){
        return view_as<int>(g_iWeaponIDs[weapon]);
    }

    char szWeapon[64];
    GetRealWeaponName(weapon, szWeapon, 64)
    ReplaceString(szWeapon, 64, "weapon_", "");
    for(WeaponID i = WEAPON_NONE; i <= WEAPON_TAGRENADE; i++){
        if(StrEqual(szWeapon, weaponNames[i])){
            g_iWeaponIDs[weapon] = i;
            return view_as<int>(g_iWeaponIDs[weapon]);
        }
    }

    return -1;
}


public int CodMod_OnAddExp(Handle:plugin, numParams){
    new client = GetNativeCell(1);
    new amount = GetNativeCell(2);
    return CodMod_AddExpFill(client, amount, true);
}



public CodMod_OnGetPlayerInfo(Handle:plugin, numParams){
    new client = GetNativeCell(1);
    new PlayerInfo:which = view_as<PlayerInfo>(GetNativeCell(2));

    return g_PlayersInfo[client][which];
}


public CodMod_OnSetPlayerInfo(Handle:plugin, numParams){
    new client = GetNativeCell(1);
    new PlayerInfo:which = view_as<PlayerInfo>(GetNativeCell(2));
    int amount = GetNativeCell(3);



    g_PlayersInfo[client][which] = amount;
}

stock bool Player_IsVIP(int iClient){
	if (CheckCommandAccess(iClient, "codmod_vip", ADMFLAG_CUSTOM1, false)) {
		return true;
	} else {
		return false;
	}
}

stock int CodMod_AddExpFill(client, amount, bool bOverride=false){
    if(CodMod_GetLevel(client) >= MAX_LEVEL)
        return -1;

    if(GetPlayerCount() < 5 && !bOverride) return -1;

    float multiply = 1.0;
    Call_StartForward(g_OnGiveExpMultiply);
    Call_PushCell(client);
    Call_PushFloatRef(multiply);
    Call_Finish();

    if(g_isPlayerVip[client])
        multiply += 0.05;


    decl String:time[5];
    FormatTime(time, 5, "%H", GetTime());
    new hour = StringToInt(time);
    if(hour >= 23 && hour < 6){
        multiply += 0.2;
    }

    FormatTime(time, 5, "%w", GetTime());
    new day = StringToInt(time);
    if((day == 0 || day == 6 || (day == 5 && hour >= 18))) {
        if(g_isPlayerVip[client])
            multiply += 0.20;
    }

    amount = RoundFloat(multiply * float(amount));
    PrintToChat(client, "%sOtrzymałeś \x04 %d doświadczenia\x04!", PREFIX_INFO, amount);
    CodMod_SetExp(client, CodMod_GetCurrExp(client) + amount);
    new currExp = CodMod_GetCurrExp(client);
    new reqExp = CodMod_GetReqExp(client);

    bool bLevelUP = false;
    while(currExp > reqExp && CodMod_GetLevel(client) + 1 <= 201){
        CodMod_SetExp(client, currExp - reqExp);
        CodMod_SetLevel(client, CodMod_GetLevel(client) + 1);
        currExp = CodMod_GetCurrExp(client);
        reqExp = CodMod_GetReqExp(client);
        PrintToChat(client, "%sAwansowałeś na %d poziom!", PREFIX, CodMod_GetLevel(client));
        bLevelUP = true;
    }

    DB_UpdatePlayer(client);

    if(bLevelUP){
        BuildSelectClassMenu(client);
    }

    return amount;
}

char g_szBlockedWeaponPerks[][] = {
    "buty luigiego",
    "siatka kamuflująca"
    /*"zestaw rushera",
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
    "Buty Luigiego",
    "tajemnica komandosa",
    "turbo milka",
    "dragi witboya",
    "typowy seba",
    "siatka kamuflująca",
    "zestaw małego terrorysty",
    "SikorAwp",
    "sekret mrozza",
    "obrona mahesvary",
    "zabawka egad'a"*/
}

const int g_iBlockedWeaponPerksSize = sizeof(g_szBlockedWeaponPerks);
int g_iBlockedWeaponPerks[g_iBlockedWeaponPerksSize];
int g_iCommandoID = -1;
int g_iElitSniperID = -1
int g_iCamouflageMask = -1
int g_iRoundIndex = -1;
int g_iBeamSprite = -1;
public OnMapStart(){
    g_iRoundIndex = 0;
    AddFileToDownloadsTable("materials/sprites/fire1.vmt")
    AddFileToDownloadsTable("materials/sprites/flames1/flame.vtf")
    g_iFire = PrecacheModel("materials/sprites/fire1.vmt");

    AddFileToDownloadsTable("materials/sprites/fire.vtf")
    AddFileToDownloadsTable("materials/sprites/fire.vmt")
    g_iExplosionSprite = PrecacheModel("materials/sprites/fire.vmt");

    g_iHaloSprite = PrecacheModel("materials/sprites/halo.vmt");
    g_iBeamSprite = PrecacheModel("materials/sprites/laserbeam.vmt");

    PrecacheModel(ROCKET_MODEL);
    AddFileToDownloadsTable("models/serwery-go_diablo/serwery-go_fireball_smallv2.vvd")
    AddFileToDownloadsTable("models/serwery-go_diablo/serwery-go_fireball_smallv2.mdl")
    AddFileToDownloadsTable("models/serwery-go_diablo/serwery-go_fireball_smallv2.phy")
    AddFileToDownloadsTable("models/serwery-go_diablo/serwery-go_fireball_smallv2.dx90.vtx")

    /*AddFileToDownloadsTable("models/serwery-go.pl_codmod/rakieta/rakieta_new.mdl");
    AddFileToDownloadsTable("models/serwery-go.pl_codmod/rakieta/rakieta_new.phy");
    AddFileToDownloadsTable("models/serwery-go.pl_codmod/rakieta/rakieta_new.vvd");
    AddFileToDownloadsTable("models/serwery-go.pl_codmod/rakieta/rakieta_new.dx90.vtx");

    AddFileToDownloadsTable("materials/serwery-go.pl_codmod/rakieta/serwery-go_rakieta.vmt");
    AddFileToDownloadsTable("materials/serwery-go.pl_codmod/rakieta/serwery-go_rakieta.vtf");*/

    PrecacheModel("models/serwery-go_ndm/sg_dynamite.mdl");
    AddFileToDownloadsTable("models/serwery-go_ndm/sg_dynamite.mdl");
    AddFileToDownloadsTable("models/serwery-go_ndm/sg_dynamite.vvd");
    AddFileToDownloadsTable("models/serwery-go_ndm/sg_dynamite.dx90.vtx");

    AddFileToDownloadsTable("materials/models/serwery-go_ndm/c4base.vmt")
    AddFileToDownloadsTable("materials/models/serwery-go_ndm/c4timer.vmt")
    AddFileToDownloadsTable("materials/models/serwery-go_ndm/c4wires.vmt")
    AddFileToDownloadsTable("materials/models/serwery-go_ndm/cbase_front.vmt")
    AddFileToDownloadsTable("materials/models/serwery-go_ndm/clock copy.vmt")

    AddFileToDownloadsTable("materials/models/serwery-go_ndm/c4base.vtf")
    AddFileToDownloadsTable("materials/models/serwery-go_ndm/c4timer.vtf")
    AddFileToDownloadsTable("materials/models/serwery-go_ndm/c4wires.vtf")
    AddFileToDownloadsTable("materials/models/serwery-go_ndm/cbase_front.vtf")
    AddFileToDownloadsTable("materials/models/serwery-go_ndm/clock_copy.vtf")

    PrecacheModel("models/serwery-go.pl_codmod/apteczka/apteczka.mdl");

    AddFileToDownloadsTable("models/serwery-go.pl_codmod/apteczka/apteczka.mdl");
    AddFileToDownloadsTable("models/serwery-go.pl_codmod/apteczka/apteczka.phy");
    AddFileToDownloadsTable("models/serwery-go.pl_codmod/apteczka/apteczka.vvd");
    AddFileToDownloadsTable("models/serwery-go.pl_codmod/apteczka/apteczka.dx90.vtx");

    AddFileToDownloadsTable("materials/serwery-go.pl_codmod/apteczka/serwery-go_apteczka.vmt");
    AddFileToDownloadsTable("materials/serwery-go.pl_codmod/apteczka/serwery-go_apteczka.vtf");




    AddFileToDownloadsTable("sound/serwery-go_ndm/explosion_nuke.mp3");
    AddToStringTable(FindStringTable("soundprecache"), "*serwery-go_ndm/explosion_nuke.mp3");

    PrecacheModel("models/serwery-go_ndm/sg_mine.mdl");
    AddFileToDownloadsTable("models/serwery-go_ndm/sg_mine.mdl");
    AddFileToDownloadsTable("models/serwery-go_ndm/sg_mine.phy");
    AddFileToDownloadsTable("models/serwery-go_ndm/sg_mine.vvd");
    AddFileToDownloadsTable("models/serwery-go_ndm/sg_mine.dx90.vtx");

    AddFileToDownloadsTable("materials/models/serwery-go_ndm/sg_mine.vtf");
    AddFileToDownloadsTable("materials/models/serwery-go_ndm/sg_mine.vmt");

    AddFileToDownloadsTable("sound/misc/serwery-go/codmod/levelup.mp3");
    AddFileToDownloadsTable("sound/misc/serwery-go/codmod/aleurwal.mp3");
    AddToStringTable(FindStringTable("soundprecache"), "*misc/serwery-go/codmod/levelup.mp3");

    g_specTimer = CreateTimer(0.5, Timer_Spectactor, _, TIMER_REPEAT);
    PrecacheFolder("materials/models/serwery-go_zp/");
    PrecacheFolder("models/serwery-go_zp/");

    if (!g_iaGrenadeOffsets[0]) {
        g_iaGrenadeOffsets[0] = GetAmmoDef_Index(g_saGrenadeAmmoTypes[1]); // flashbang
        g_iaGrenadeOffsets[1] = GetAmmoDef_Index(g_saGrenadeAmmoTypes[3]); // molotov
        g_iaGrenadeOffsets[2] = GetAmmoDef_Index(g_saGrenadeAmmoTypes[2]); // smokegrenade
        g_iaGrenadeOffsets[3] = GetAmmoDef_Index(g_saGrenadeAmmoTypes[0]); // hegrenade
        g_iaGrenadeOffsets[4] = GetAmmoDef_Index(g_saGrenadeAmmoTypes[4]); // decoy
        g_iaGrenadeOffsets[5] = GetAmmoDef_Index(g_saGrenadeAmmoTypes[3]); // incgrenade
        /*int end = sizeof(g_saGrenadeWeaponNames);
        for (int i=0; i<end; i++) {
            int entindex = CreateEntityByName(g_saGrenadeWeaponNames[i]);
            //DispatchSpawn(entindex);
            g_iaGrenadeOffsets[i] = GetEntProp(entindex, Prop_Send, "m_iPrimaryAmmoType");
            AcceptEntityInput(entindex, "Kill");
        }*/
    }

    for(int i = 0; i < g_iBlockedWeaponPerksSize; i++){
        g_iBlockedWeaponPerks[i] = CodMod_GetPerkId(g_szBlockedWeaponPerks[i]);
    }

    g_iCommandoSecret = -1;
    g_iNanoarmor = -1;
    g_iCamouflageMask = -1
    g_iPrzeszycie = -1;
    g_iTypowySeba = -1;
    for(int i = 0; i < PERK_LIMIT; i++){
        if(StrEqual(perks[i][NAME], "Tajemnica Komandosa")){
            g_iCommandoSecret = i;
        }

        if(StrEqual(perks[i][NAME], "Nanopancerz")){
            g_iNanoarmor = i;
        }

        if(StrEqual(perks[i][NAME], "Siatka Kamuflująca")){
            g_iCamouflageMask = i;
        }

        if(StrEqual(perks[i][NAME], "Trykot Formixa")){
            g_iTrykot = i;
        }

        if(StrEqual(perks[i][NAME], "Przeszycie"))
        {
            g_iPrzeszycie = i;
        }

        if(StrEqual(perks[i][NAME], "Typowy Seba"))
        {
            g_iTypowySeba = i;
        }

        if(g_iCommandoSecret != -1 && g_iNanoarmor != -1 && g_iTrykot != -1 && g_iPrzeszycie != -1 && g_iTypowySeba != -1){
            break;
        }
    }
    g_iCommandoID = -1;
    g_iCommandoID = CodMod_GetClassId("Komandos [Premium]");
    g_iElitSniperID = -1
    g_iElitSniperID = CodMod_GetClassId("Elitarny Snajper [Premium]")
}

public OnMapEnd(){
    if(g_specTimer != INVALID_HANDLE){
        KillTimer(g_specTimer);
        g_specTimer = INVALID_HANDLE;
    }

}


public OnPluginEnd(){
    UnhookEvent("player_spawn", Event_OnPlayerSpawn);
    UnhookEvent("player_death", Event_OnPlayerDie);
    UnhookEvent("bomb_planted", Event_OnBombPlanted);
    UnhookEvent("bomb_exploded", Event_OnBombExploded);
    UnhookEvent("bomb_defused", Event_OnBombDefused);
    UnhookEvent("hostage_rescued", Event_OnHostageRescued);
    UnhookEvent("round_end", Event_OnRoundEnd);

    if(g_specTimer != INVALID_HANDLE)
        KillTimer(g_specTimer);

    CloseHandle(hDatabase);
}


public Event_OnRoundEnd(Handle:event, const String:name[], bool:broadcast){
    new team = GetEventInt(event, "winner");


    new roundWin = 800;
    for(new i = 1; i <= MaxClients; i++){
        if(!IsClientInGame(i))
            continue;

        if(GetClientTeam(i) != team ||  IsFakeClient(i) || !IsPlayerAlive(i))
            continue;

        CodMod_AddExpFill(i, roundWin);

    }
}


public Event_OnRoundStart(Event hEvent, const char[] szEvent, bool bBroadcast){
    g_iRoundIndex++;
    for(new i = 1; i <= MaxClients; i++){
        for(int j = MAXPLAYERS + 1; j < 2048; j++){
            g_iWeaponCanUse[i][j] = -1;
        }
    }


}



public Event_OnRoundMVP(Handle:event, const String:name[], bool:broadcast){
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    CodMod_AddExpFill(client, 400);
    PrintToChat(client, "%sOtrzymałeś dodatkowe 400 expa za bycie MVP!", PREFIX);

}
public Event_OnBombBeginDefuse(Handle:event, const String:name[], bool:broadcast){
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    g_bIsDefusing[client] = true;
}

public Event_OnBombAbortDefuse(Handle:event, const String:name[], bool:broadcast){
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    g_bIsDefusing[client] = false;
}

public Event_OnBombPlanted(Handle:event, const String:name[], bool:broadcast){
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if(CodMod_GetClass(client)){
        CodMod_AddExpFill(client, 400);
    }
}


public Event_OnBombExploded(Handle:event, const String:name[], bool:broadcast){
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if(CodMod_GetClass(client)){
        CodMod_AddExpFill(client, 600);
    }
}

public Event_OnBombDefused(Handle:event, const String:name[], bool:broadcast){
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if(CodMod_GetClass(client)){
        CodMod_AddExpFill(client, 600);
    }
}


public Event_OnHostageRescued(Handle:event, const String:name[], bool:broadcast){
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if(CodMod_GetClass(client)){
        CodMod_AddExpFill(client, 600);
    }
}

public Action:Timer_Spectactor(Handle:timer) {
    for(new i = 1; i <= MaxClients; i++){
        if(!IsClientInGame(i) || !IsClientObserver(i) || IsPlayerAlive(i))
            continue;


        new iTarget = GetEntPropEnt(i, Prop_Send, "m_hObserverTarget");
        if(iTarget < 1 || iTarget > MaxClients)
            continue;

        if(IsClientInGame(iTarget) && IsPlayerAlive(iTarget))
            Display_ClassInfoAbout(iTarget, i);

    }

    return Plugin_Continue;
}

public CodMod_OnGetClassId(Handle:plugin, numParams){
    new nameLen;
    GetNativeStringLength(1, nameLen);
    new String:className[nameLen + 1];
    GetNativeString(1, className, nameLen + 1);

    for(new i = 1; i <= registeredClasses; i++){
        if(StrEqual(classes[i][NAME], className)){
            return i;
        }
    }

    return 0;

}

public Native_GetRoundIndex(Handle hPlugin, int iNumParams)
{
    return g_iRoundIndex;
}

public Native_GetPerkId(Handle hPlugin, int iNumParams){
    char className[256];
    GetNativeString(1, className, 256);

    for(new i = 1; i <= registeredPerks; i++){
        if(StrEqual(perks[i][NAME], className, false)){
            return i;
        }
    }

    return 0;

}

public CodMod_OnRegisterClassStrength(Handle:hPlugin, iNumParams){
    char szName[64];
    GetNativeString(1, szName, sizeof(szName));
    classesStats[CodMod_GetClassId(szName)][STRENGTH] = GetNativeCell(2);
}

public CodMod_OnRegisterClassGravity(Handle:hPlugin, iNumParams){
    char szName[64];
    GetNativeString(1, szName, sizeof(szName));
    classesStats[CodMod_GetClassId(szName)][GRAVITY] = GetNativeCell(2);
}

public CodMod_OnRegisterClass(Handle:plugin, numParams){

    new nameLen, descLen;
    GetNativeStringLength(1, nameLen);
    GetNativeStringLength(2, descLen);

    new String:currName[nameLen + 1];
    new String:currDesc[descLen + 1];
    new health, armor, dexterity, intelligence, classId, startingHP;
    new bool:usedId = false;

    GetNativeString(1, currName, nameLen + 1);
    GetNativeString(2, currDesc, descLen + 1);
    health = GetNativeCell(3);
    armor = GetNativeCell(4);
    dexterity = GetNativeCell(5);
    intelligence = GetNativeCell(6);
    startingHP = GetNativeCell(9);


    if(registeredClasses > 0) {
        for(new i = 1; i <= registeredClasses; i++){
            if(StrEqual(classes[i][NAME], currName)){
                return i;
            }
            if(StrEqual(classes[i][NAME], "UNREG")){
                classId = i;
                usedId = true;
                break;
            }
        }
    }

    if(!usedId) {
        registeredClasses++;
        classId = registeredClasses;
    }

    GetNativeArray(7, classesWeapons[classId], WEAPON_LIMIT);

    Format(classes[classId][NAME],  128, currName);
    Format(classes[classId][DESC], 200, currDesc);
    Format(classes[classId][CLANTAG], 128, "[%s]", classes[classId][NAME]);
    ReplaceString(classes[classId][CLANTAG], 64, "[Premium]", "[P]");
    ReplaceString(classes[classId][CLANTAG], 64, "Wsparcie", "W.");
    ReplaceString(classes[classId][CLANTAG], 64, "Specjalista", "Spec.");
    ReplaceString(classes[classId][CLANTAG], 64, "Elitarny", "E.");
    ReplaceString(classes[classId][CLANTAG], 64, "Strzelec", "S.");

    classesStats[classId][HP] = health;
    classesStats[classId][ARMOR] = armor;
    classesStats[classId][DEX] = dexterity;
    classesStats[classId][INT] = intelligence;
    classesStats[classId][STRENGTH] = 0;
    classesStats[classId][STARTING_HP] = startingHP;


    classesIsVip[classId] = GetNativeCell(8);

    return classId;
}

stock RemoveCustomPerkPermission(int iPerkId)
{
    for(int i = 0; i <= MaxClients; i++)
    {
        g_iCustomPerkPermission[i][iPerkId] = 0;
    }
}

public CodMod_OnRegisterPerk(Handle:plugin, numParams){
    new nameLen, descLen, perkId;
    new bool:usedId = false;
    GetNativeStringLength(1, nameLen);
    GetNativeStringLength(2, descLen);
    new String:currName[nameLen + 1];
    new String:currDesc[descLen + 1];
    GetNativeString(1, currName, nameLen + 1);
    GetNativeString(2, currDesc, descLen + 1);



    if(registeredPerks > 0) {
        for(new i = 1; i <= registeredPerks; i++){
            if(StrEqual(perks[i][NAME], currName))
            {
                if(StrEqual(currName, "Przeszycie"))
                {
                    g_iPrzeszycie = i;
                }

                if(StrEqual(currName, "Typowy Seba"))
                {
                    g_iTypowySeba = i;
                }

                RemoveCustomPerkPermission(i);

                
                Call_StartForward(g_hOnPerkRegistered);
                Call_PushCell(perkId);
                Call_PushString(currName);
                Call_Finish();
                return i;
            }
            if(StrEqual(perks[i][NAME], "UNREG")){
                perkId = i;
                usedId = true;
                break;
            }
        }
    }

    if(!usedId) {
        registeredPerks++;
        perkId = registeredPerks;
    }


    if(StrEqual(currName, "Przeszycie"))
    {
        g_iPrzeszycie = perkId;
    }


    if(StrEqual(currName, "Typowy Seba"))
    {
        g_iTypowySeba = perkId;
    }


    RemoveCustomPerkPermission(perkId);
    Format(perks[perkId][NAME], 128, currName);
    Format(perks[perkId][DESC], 128, currDesc);

    Call_StartForward(g_hOnPerkRegistered);
    Call_PushCell(perkId);
    Call_PushString(currName);
    Call_Finish();

    return perkId;
}


public CodMod_OnUnregisterClass(Handle:plugin, numParams){
    new classId = GetNativeCell(1);
    if(classId > 0){
        Format(classes[classId][NAME], 128, "UNREG");
        Format(classes[classId][DESC], 128, "UNREG");

        for(new i = 1; i <= MaxClients; i++) {
            if(IsClientInGame(i)) {
                if(CodMod_GetClass(i) == classId){
                    CodMod_SetClass(i, 0);
                    if(IsPlayerAlive(i))
                        Client_RemoveAllWeapons(i);
                }
            }
        }


    }
}

public CodMod_OnUnregisterPerk(Handle:plugin, numParams){
    new perkId = GetNativeCell(1);
    if(perkId > 0){
        Format(perks[perkId][NAME], 128, "UNREG");
        Format(perks[perkId][DESC], 128, "UNREG");
        for(new i = 1; i <= MaxClients; i++) {
            if(IsClientInGame(i)) {
                if(CodMod_GetPerk(i) == perkId){
                    CodMod_DropPerk(i);
                }
            }
        }
    }
}


public void OnClientPutInServer(int client) {
    SDKHook(client, SDKHook_OnTakeDamage, SDK_OnTakeDamage);
    SDKHook(client, SDKHook_WeaponCanUse, SDK_OnWeaponEquip);
    SDKHook(client, SDKHook_PostThink, SDK_OnPostThinkPost);

    for(int i = 0; i <= registeredPerks; i++)
    {
        g_iCustomPerkPermission[client][i] = 0;
    }

    g_bImmuneToSkills[client] = false;
    g_bFreezed[client] = false;
    g_bTradeBlockade[client] = false;
    g_isPlayerVip[client] = false;
    g_bIsDefusing[client] = false;
    g_iStatsSpendingSpeed[client] = 0;

    g_fBlockedSkill[client] = 0.0;
    g_PlayersInfo[client][PERK] = 0;
    g_PlayersInfo[client][PERK_ARMOR] = 0;

    g_PlayersInfo[client][HP_OVERRIDE] = 0;


    new String:sAuth[32];

    GetClientAuthId(client, AuthId_Steam2, sAuth, 32);
    for(new i = 0; i <= CLASS_LIMIT; i++)
        g_PlayersClassesLevelInfo[client][i] = 0;

    g_hSelectClassMenus[client] = INVALID_HANDLE;
    new String:query[ARRAY_LENGTH];
    Format(query, 255, "SELECT `class_name`, `level` FROM `codmod` WHERE `player_sid`='%s'", sAuth);
    if(hDatabase == INVALID_HANDLE){
        SQL_Initialize();
    }
    SQL_TQuery(hDatabase, MenuLevelsCallback, query, GetClientSerial(client), DBPrio_High);

    if(GetUserAdmin(client) != INVALID_ADMIN_ID){
        if(!(GetAdminFlags(GetUserAdmin(client), Access_Effective) & ADMFLAG_CUSTOM1) && !(GetAdminFlags(GetUserAdmin(client), Access_Real) & ADMFLAG_CUSTOM1)){
            g_isPlayerVip[client] = false;
            return;
        }
        g_isPlayerVip[client] = true;
    }
}


public MenuLevelsCallback(Handle:owner, Handle:result, const String:error[], any:client){
    new String:auth[48];
    new String:sClassName[64];
    client = GetClientFromSerial(client)
    if(!IsValidPlayer(client) || !IsClientInGame(client))
        return;

    GetClientAuthId(client, AuthId_Steam2, auth, 48);
    if (result == INVALID_HANDLE) {
        LogError("ERROR, ERROR, HASO NIEPRAWIDOWE: %s", error);
    } else {
        while(SQL_FetchRow(result)){
            SQL_FetchString(result, 0, sClassName, 64);
            g_PlayersClassesLevelInfo[client][CodMod_GetClassId(sClassName)] = SQL_FetchInt(result, 1);
        }

        BuildSelectClassMenu(client);
    }

}

public OnClientDisconnect(client){
    if(g_hSelectClassMenus[client] != INVALID_HANDLE){
        CloseHandle(g_hSelectClassMenus[client]);
    }
    g_hSelectClassMenus[client] = INVALID_HANDLE;
    SDKUnhook(client, SDKHook_OnTakeDamage, SDK_OnTakeDamage);
    SDKUnhook(client, SDKHook_PostThink, SDK_OnPostThinkPost);
    SDKUnhook(client, SDKHook_WeaponCanUse, SDK_OnWeaponEquip);
    //DB_UpdatePlayer(client);
    changedClass[client] = 0;
    CodMod_SetClass(client, 0);
    SetPerk(client, 0, 0);
    CodMod_SetStat(client, HP, 0);
    CodMod_SetStat(client, ARMOR, 0);
    CodMod_SetStat(client, DEX, 0);
    CodMod_SetStat(client, INT, 0);
    CodMod_SetStat(client, STRENGTH, 0);
    CodMod_SetStat(client, GRAVITY, 0);

    CodMod_SetStat(client, HP_PERK, 0);
    CodMod_SetStat(client, ARMOR_PERK, 0);
    CodMod_SetStat(client, DEX_PERK, 0);
    CodMod_SetStat(client, INT_PERK, 0);
    CodMod_SetStat(client, GRAVITY_PERK, 0);
    CodMod_SetStat(client, STRENGTH_PERK, 0);
}

public SDK_OnPostThinkPost(client) {
    if(!IsPlayerAlive(client) || !g_PlayersInfo[client][CLASS])
        return;

    SetEntDataFloat(client, g_iOffsetLaggedMovementValue, 1.0 + ((float(clientStats[client][DEX] + clientStats[client][DEX_PERK]) / 100.0) * 0.3), true)
    int iGravity = clientStats[client][GRAVITY] + clientStats[client][GRAVITY_PERK];
    if(iGravity > 130){
        iGravity = 130;
    }

    SetEntityGravity(client, 1.0 - (float(iGravity) * 0.004))

}


public Action SDK_OnTakeDamage(victim, &attacker, &inflictor, float &damage, int &damagetype, int &iWeapon, const float fDamageForce[3], const float fDamagePosition[3]) {
    if(attacker == 0 || attacker > MAXPLAYERS || CodMod_GetPerk(attacker) != g_iPrzeszycie)
    {
        damage *= (1.0 - ((float(CodMod_GetWholeStat(victim, ARMOR)) * 0.01) / 2.0));
    }
    //if(damagetype & DMG_BLAST){
    //    return Plugin_Changed;
    //}

    if(attacker != 0 && attacker < MAXPLAYERS && GetClientTeam(victim) == GetClientTeam(attacker)){
        return Plugin_Changed;
    }





    WeaponID weaponID = WEAPON_NONE;
    /*if(inflictor != attacker){
        weaponID = CodMod_GetWeaponID(inflictor);
    } else {
        weaponID = CodMod_GetClientWeaponID(attacker);
    }*/
     /* int iRealAttacker = attacker;
      if(attacker > MAXPLAYERS){
        char szAttacker[64];
        GetEdictClassname(attacker, szAttacker, 64);
        if(StrEqual(szAttacker, "entityflame")){
          return Plugin_Handled;
        }
        weaponID = CodMod_GetWeaponIDByName(szAttacker);
        int iOwner = GetEntPropEnt(attacker, Prop_Send, "m_hOwnerEntity");
        if(IsValidPlayer(iOwner)){
          if(StrEqual(szAttacker, "inferno")){
            weaponID = WEAPON_MOLOTOV;
          }
          attacker = iOwner;
        } else {
          attacker = 0;
        }

      } else if(IsValidPlayer(attacker)){
          int iEntity = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
          if(iEntity != -1 && IsValidEntity(iEntity)){
            weaponID = CodMod_GetClientWeaponID(attacker);
          }
      }*/


    int iRealAttacker = attacker;
    if(inflictor > MAXPLAYERS){
        char szAttacker[64];
        GetEntPropString(inflictor, Prop_Data, "m_iClassname", szAttacker, 31);
        int iOwner = GetEntPropEnt(inflictor, Prop_Send, "m_hOwnerEntity");
        if(IsValidPlayer(iOwner)){
            if(StrEqual(szAttacker, "inferno")){
                weaponID = WEAPON_MOLOTOV;
            } else if(StrEqual(szAttacker, "hegrenade_projectile")){
                weaponID = WEAPON_HEGRENADE;
            }
            attacker = iOwner;
        } else {
            attacker = 0;
        }
    } else if(IsValidPlayer(attacker)){
        weaponID = CodMod_GetClientWeaponID(attacker);
        if(damagetype & DMG_BURN){
            weaponID = WEAPON_MOLOTOV;
        }
    }

    int iVictimPerk = CodMod_GetPerk(victim);
    if(iVictimPerk == g_iCommandoSecret && weaponID != WEAPON_KNIFE){
        return Plugin_Handled;
    }

    if(IsValidPlayer(attacker) && weaponID != WEAPON_MOLOTOV && weaponID != WEAPON_INCGRENADE && weaponID != WEAPON_HEGRENADE){
        damage += float(clientStats[attacker][STRENGTH]) * STRENGTH_MULTIPLIER;
    }

    if(weaponID == WEAPON_MOLOTOV)
    {
        attacker = iRealAttacker;
        return Plugin_Changed;
    }

    float fDamageBefore = damage;
    Call_StartForward(g_DamageForward);
    Call_PushCell(attacker);
    Call_PushCell(victim);
    Call_PushFloatRef(damage);
    Call_PushCell(weaponID);
    int iDMGType = damagetype;
    Call_PushCell(iDMGType);
    Call_Finish();

    float fDamageBeforePerk = damage;
    Call_StartForward(g_hDamagePerkForward);
    Call_PushCell(attacker);
    Call_PushCell(victim);
    Call_PushFloatRef(damage);
    Call_PushCell(weaponID);
    Call_PushCell(iDMGType);
    Call_Finish();

    if(iVictimPerk == g_iNanoarmor){
      if(damage / fDamageBefore > 10.0 || damage / fDamageBeforePerk > 10.0){
        damage = fDamageBefore;
      }
    }

    if(iVictimPerk == g_iTrykot && weaponID == WEAPON_AWP)
    {
        damage = 0.0;
    }

    if(damage >= 10000.0){
        damage = 10000.0;
    }


    attacker = iRealAttacker;
    return Plugin_Changed;
}




public OnEntityCreated(iEnt, const String:szClassname[])
{
    if(iEnt > 0 && iEnt < 2048 && StrContains(szClassname, "weapon_") != -1){
        for(int i = 1; i <= MaxClients; i++){
            g_iWeaponCanUse[i][iEnt] = -1;
        }
        g_iWeaponIDs[iEnt] = WEAPON_NOT;
        //CodMod_GetWeaponID(iEnt);

    }
}


public CodMod_SetClass(client, class){
    new previousClass = CodMod_GetClass(client);
    Call_StartForward(g_OnChangeClass);
    Call_PushCell(client);
    Call_PushCell(previousClass);
    Call_PushCell(class);
    Call_Finish();

    g_PlayersInfo[client][CLASS] = class;
}


public Action CS_OnBuyCommand(client, const char[] weapon){
    return Plugin_Continue;

    /*
    if(StrContains(weapon, "defuser") != -1)
        return Plugin_Continue;

    if(StrContains(weapon, "g3sg1") != -1 || StrContains(weapon, "scar20") != -1){
        return Plugin_Handled;
    }

    if(StrEqual(classes[g_PlayersInfo[client][CLASS]][NAME], "Szpieg [Premium]")){
        if(WeaponIsPistol(CodMod_GetWeaponIDByName(weapon))){
            return Plugin_Continue;
        }
    }

    WeaponID iWeaponID = CodMod_GetWeaponIDByName(weapon);
    int canUseForward = 1;
    Call_StartForward(g_WeaponUseForward);
    Call_PushCell(client);
    Call_PushCell(iWeaponID);
    Call_PushCellRef(canUseForward);
    Call_PushCell(true);
    Call_Finish();

    Call_StartForward(g_hWeaponCanUsePerk);
    Call_PushCell(client);
    Call_PushCell(iWeaponID);
    Call_PushCellRef(canUseForward);
    Call_PushCell(true);
    Call_Finish();


    if(canUseForward == 0){
        return Plugin_Handled;
    }

    if(canUseForward == 2){
        return Plugin_Continue;
    }


    return Plugin_Handled;*/
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon){
    if(g_PlayersInfo[client][CLASS] && IsPlayerAlive(client)){
        if(g_PlayersInfo[client][HP_OVERRIDE]){
            SetEntityHealth(client, g_PlayersInfo[client][HP_OVERRIDE]);
        }
    }

    /*if(buttons & IN_ATTACK && !(g_iPreviousButtons[client] & IN_ATTACK) && g_fLastPistolShot[client] - GetGameTime() < 0.15){
        WeaponID iWeaponID = CodMod_GetClientWeaponID(client);
        if(WeaponIsPistol(iWeaponID)){
            int iEntity = GetEntDataEnt2(client, g_iOffsetActiveWeapon);
            SetEntPropFloat(iEntity, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + 0.15);
        }
    }*/

    g_iPreviousButtons[client] = buttons;


    return Plugin_Changed;
}



public Action SDK_OnWeaponEquip(int iClient, int iWeapon){
    if(!IsPlayerAlive(iClient))
    {
        return Plugin_Continue;
    }

    if(g_iWeaponCanUse[iClient][iWeapon] != -1){
        if(g_iWeaponCanUse[iClient][iWeapon] == 0){
            return Plugin_Handled;
        } else {
            return Plugin_Continue;
        }
    }

    WeaponID iWeaponID = CodMod_GetWeaponID(iWeapon);
    if(iWeaponID == WEAPON_C4){
        g_iWeaponCanUse[iClient][iWeapon] = 2;
        return Plugin_Continue;
    }


    if(iWeaponID == WEAPON_KNIFE || iWeaponID == WEAPON_TAGRENADE || iWeaponID == WEAPON_FLASHBANG || iWeaponID == WEAPON_HEGRENADE || iWeaponID == WEAPON_SMOKEGRENADE || iWeaponID == WEAPON_MOLOTOV || iWeaponID == WEAPON_DECOY || iWeaponID == WEAPON_INCGRENADE){
        g_iWeaponCanUse[iClient][iWeapon] = 2;
        return Plugin_Continue;
    }

    int iClassId = CodMod_GetClass(iClient);
    if(iClassId == 0){
        g_iWeaponCanUse[iClient][iWeapon] = 0;
        return Plugin_Handled;
    }

    if(iClassId == g_iCommandoID && iWeaponID != WEAPON_C4 && iWeaponID != WEAPON_KNIFE && iWeaponID != WEAPON_DEAGLE){
        if(iWeaponID == WEAPON_TASER && CodMod_GetPerk(iClient) == g_iTypowySeba)
        {
            g_iWeaponCanUse[iClient][iWeapon] = 2;
            return Plugin_Continue;
        }
        
        g_iWeaponCanUse[iClient][iWeapon] = 0;
        return Plugin_Handled;
    }


    int canUseForward = 1;
    Call_StartForward(g_WeaponUseForward);
    Call_PushCell(iClient);
    Call_PushCell(iWeaponID);
    Call_PushCellRef(canUseForward);
    Call_PushCell(false);
    Call_Finish();

    Call_StartForward(g_hWeaponCanUsePerk);
    Call_PushCell(iClient);
    Call_PushCell(iWeaponID);
    Call_PushCellRef(canUseForward);
    Call_PushCell(false);
    Call_Finish();

    if(canUseForward == 0){
        g_iWeaponCanUse[iClient][iWeapon] = 0;
        return Plugin_Handled;
    }

    if(canUseForward == 2){
        g_iWeaponCanUse[iClient][iWeapon] = 2;
        return Plugin_Continue;
    }

    for(new i = 0; i < WEAPON_LIMIT; i++){
        if(classesWeapons[iClassId][i] == WEAPON_NONE)
            continue;

        if(classesWeapons[iClassId][i] == WEAPON_STANDARDPISTOLS){
            if(iWeaponID == WEAPON_GLOCK || iWeaponID == WEAPON_HKP2000 || iWeaponID == WEAPON_USP){
                g_iWeaponCanUse[iClient][iWeapon] = 2;
                return Plugin_Continue;
            }
        }
        if(classesWeapons[iClassId][i] == iWeaponID){
            g_iWeaponCanUse[iClient][iWeapon] = 2;
            return Plugin_Continue;
        }
    }

    g_iWeaponCanUse[iClient][iWeapon] = 0;
    return Plugin_Handled;

}

public Action Event_OnPlayerSpawn(Handle:event, const String:name[], bool:broadcast){
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if(!IsPlayerAlive(client)) return Plugin_Stop; // omg fix

    g_bIsDefusing[client] = false;
    if(Player_IsVIP(client)){
        g_isPlayerVip[client] = true;
    }

    GivePlayerItem(client, "item_assaultsuit");

    g_bFreezed[client] = false;
    new classId = CodMod_GetClass(client);
    //if(StrContains(classes[classId][NAME], "Najemnik") == -1 && StrContains(classes[classId][NAME], "Chachment") == -1 && StrContains(classes[classId][NAME], "El Pistolero") == -1)
    //    Client_RemoveAllWeapons(client, "weapon_knife");

    if(changedClass[client]){
        DB_UpdatePlayer(client);
        CodMod_SetClass(client, 0);
        classId = changedClass[client];
        SelectClass(client, changedClass[client]);
        changedClass[client] = 0;
    }

    UpdateHealth(client);
    UpdateWeapons(client);

    if(classId){
        CS_SetClientClanTag(client, classes[CodMod_GetClass(client)][CLANTAG]);
    }


    CreateTimer(1.7, Timer_OnPlayerSpawn, GetClientSerial(client));

    return Plugin_Continue;
}

public Action:Timer_OnPlayerSpawn(Handle:timer, any:client){
    client = GetClientFromSerial(client);
    if(client == 0 || !IsClientInGame(client))
        return Plugin_Stop;

    if(!IsPlayerAlive(client)) return Plugin_Stop; //omg fix
    new classId = CodMod_GetClass(client);
    Call_StartForward(g_OnPlayerSpawnForward);
    Call_PushCell(client);
    Call_Finish();
    if(classId){
        Display_ClassInfo(client);
        if(GetAvailPoints(client) >= 1){
            Menu_Stats(client, 0);
        }

    } else {
        Menu_SelectClass(client, 0);
    }

    return Plugin_Stop;
}

public Action Event_OnWeaponFire(Event hEvent, const char[] szEvent, bool bBroadcast){
    int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
    if(WeaponIsPistol(CodMod_GetClientWeaponID(iClient))){
        g_fLastPistolShot[iClient] = GetGameTime();
    }
}

public Action:Event_OnPlayerDie(Handle:event, const String:name[], bool:broadcast){
    new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
    new victim = GetClientOfUserId(GetEventInt(event, "userid"));
    int iAssister = GetEventInt(event, "assister");
    if(iAssister != 0){
        iAssister = GetClientOfUserId(iAssister);
    }

    new bool:headshot = GetEventBool(event, "headshot");
    if(attacker == 0 || victim == 0)
        return Plugin_Handled;

    if(!IsClientInGame(attacker))
        return Plugin_Handled;

    if(!CodMod_GetClass(attacker))
        return Plugin_Handled;

    if(attacker == victim){
        CodMod_WeakenPerk(attacker);
        return Plugin_Handled;
    }
    Call_StartForward(g_OnPlayerDieForward);
    Call_PushCell(attacker);
    Call_PushCell(victim);
    Call_PushCell(headshot);
    Call_Finish();


    new Float:multiply = 1.0;
    if(headshot){
        multiply += 0.5;
    }

    new Float:fAttackerOrigin[3];
    GetClientAbsOrigin(attacker, fAttackerOrigin);

    new Float:fVictimOrigin[3];
    GetClientAbsOrigin(victim, fVictimOrigin);


    if(GetClientTeam(attacker) == CS_TEAM_T){

        new bombIndex = -1;
        bombIndex = FindEntityByClassname(bombIndex, "planted_c4");
        if(bombIndex != -1){
            decl Float:bombVec[3];
            GetEntPropVector(bombIndex, Prop_Send, "m_vecOrigin", bombVec);
            if(GetVectorDistance(fAttackerOrigin, bombVec) <= 180.0){
                PrintToChat(attacker, "%sDostałeś dodatkowe 200 expa za obronę paki!", PREFIX);
                multiply += 1.0;
            }
        }
    }

    if(g_bIsDefusing[victim]){
        PrintToChat(attacker, "%sDostałeś dodatkowe 400 expa za przerwanie rozbrajania paki!", PREFIX);
        multiply += 1.0;
    }


    if(IsValidPlayer(iAssister) && iAssister != attacker && iAssister != victim){
        CodMod_AddExpFill(iAssister, 250);
    }
    if(GameRules_GetProp("m_bWarmupPeriod") == 0) {
        GiveExp(attacker, victim, multiply, headshot);
        if(!CodMod_GetPerk(attacker)) {
            Timer_GivePerk(attacker);
        }// else {
            //CodMod_WeakenPerk(attacker, 1, 10);
        //}
    }
    if(CodMod_GetPerk(victim)){
        CodMod_WeakenPerk(victim, 10, 10);
    }
    return Plugin_Handled;
}

stock int GetPlayerCount()
{
    int sum = 0;
    for(int i = 1; i <= MaxClients; i++)
    {
        if(IsClientInGame(i) && (GetClientTeam(i) == CS_TEAM_T || GetClientTeam(i) == CS_TEAM_CT))
        {
            sum++;
        }
    }

    return sum;
}


stock GiveExp(attacker, victim, Float:multiply = 1.0, bool bHeadshot){
    if(GetPlayerCount() < 4) return;
    decl String:time[5];
    FormatTime(time, 5, "%H", GetTime());
    new hour = StringToInt(time);
    if(hour >= 23 && hour < 6){
        multiply += 0.2;
    }

    FormatTime(time, 5, "%w", GetTime());
    new day = StringToInt(time);
    if((day == 0 || day == 6 || (day == 5 && hour >= 18))) {
        if(g_isPlayerVip[attacker])
            multiply += 0.25;
    }

    Call_StartForward(g_OnGiveExpMultiply);
    Call_PushCell(attacker);
    Call_PushFloatRef(multiply);
    Call_Finish();

    if(g_isPlayerVip[attacker])
        multiply += 0.05;

    /*decl String:buffer[64];
    CS_GetClientClanTag(attacker, buffer, 64);
    if(StrEqual(buffer, "Serwery-GO"))
        multiply += 0.025;*/

    new levelBonus = 0;
    new levelDifference = CodMod_GetLevel(attacker) - CodMod_GetLevel(victim);
    if(levelDifference < 0){
        levelDifference = -levelDifference;

        if((levelDifference % 10) == 0 && levelDifference != 0){
            levelBonus = (levelDifference / 10) * 100;
        } else {
            levelBonus = ((levelDifference - (levelDifference % 10)) / 10) * 100;
        }

    }

    int iLevel = CodMod_GetLevel(attacker);

    int lowLevelBonus = (201 - iLevel) * 2;
    new expForVictim = RoundFloat(float(CodMod_GetExpForKill(victim)) * multiply) + levelBonus;//CodMod_GetExpForKill(victim);
    new expForLevel = CodMod_GetReqExp(attacker);

    if(iLevel < 50){
        lowLevelBonus *= 3;
    } else {
        lowLevelBonus *= 2;
    }

    expForVictim += lowLevelBonus;

    /*if(CodMod_GetLevel(attacker) <= 50){
        expForVictim =  RoundFloat(expForVictim * 1.8);
    }*/

    Call_StartForward(g_OnGiveExp);
    Call_PushCell(attacker);
    Call_PushCell(victim);
    Call_PushCellRef(expForVictim);
    Call_PushCell(bHeadshot)
    Call_Finish();


    bool bLevelUP = false;
    if(CodMod_GetCurrExp(attacker) + expForVictim >= CodMod_GetReqExp(attacker) && CodMod_GetLevel(attacker) < MAX_LEVEL){
        EmitSoundToClient(attacker, "*misc/serwery-go/codmod/levelup.mp3");
        CodMod_AddExp(attacker, expForVictim - expForLevel);
        CodMod_SetLevel(attacker, CodMod_GetLevel(attacker) + 1);
        PrintToChat(attacker, "%sAwansowałeś na %d poziom!", PREFIX, CodMod_GetLevel(attacker));

        while(CodMod_GetCurrExp(attacker) >= CodMod_GetReqExp(attacker)){
            CodMod_AddExp(attacker, -CodMod_GetReqExp(attacker));
            CodMod_SetLevel(attacker, CodMod_GetLevel(attacker) + 1);
            PrintToChat(attacker, "%sAwansowałeś na %d poziom!", PREFIX, CodMod_GetLevel(attacker));
        }

        bLevelUP = true;

    } else {
        CodMod_AddExp(attacker, expForVictim);
    }

    PrintToChat(attacker, "%sOtrzymałeś \x07 %d \x04 doświadczenia za zabójstwo!", PREFIX_INFO, expForVictim);
    Display_ClassInfo(attacker);


    DB_UpdatePlayer(attacker);
    if(bLevelUP){
        BuildSelectClassMenu(attacker);
    }
}

public int GetRandomIntEx(int iStart, int iEnd){
    int iAmount = GetRandomInt(1, 5);
    int iReturn = 0;
    for(int i = 0 ; i <= iAmount; i++){
        iReturn = GetRandomInt(iStart, iEnd);
    }

    return iReturn;
}

public Timer_GivePerk(client){
    /*new randomPerkId = GetRandomIntEx(1, registeredPerks);
    while(StrEqual(perks[randomPerkId][NAME], "UNREG")){
        randomPerkId = GetRandomIntEx(1, registeredPerks);
    }

    SetPerk(client, randomPerkId, 100);
    PrintToChat(client, "%sOtrzymałeś perk: %s!", PREFIX, perks[randomPerkId][NAME]);*/
    CodMod_GiveRandomPerk(client);
}

stock Display_ClassInfo(client){
    //if(CodMod_GetClass(client)){
     //   PrintHintText(client, "<font size='18'><font color='#0B52B6'> Serwery</font>-<font color='#BF0000'>GO.pl</font>\n <font color='#00CC00'>%s</font> Lvl: %d Exp: %d/%d\n %s</font>", classes[CodMod_GetClass(client)][CLANTAG], CodMod_GetLevel(client), CodMod_GetCurrExp(client), CodMod_GetReqExp(client), perks[CodMod_GetPerk(client)][NAME]);
    //} else
    //    PrintHintText(client, "<font color='#0B52B6'> Serwery</font>-<font color='#BF0000'>GO.pl</font>\nNie masz klasy!");
    if(CodMod_GetClass(client))
    {
        PrintHintText(client, "<font size='18'><font color='#0B52B6'> Serwery</font>-<font color='#BF0000'>GO.pl</font>\n <font color='#00CC00'>%s</font> Lvl: %d Exp: %d/%d\n %s</font>", classes[CodMod_GetClass(client)][CLANTAG], CodMod_GetLevel(client), CodMod_GetCurrExp(client), CodMod_GetReqExp(client), perks[CodMod_GetPerk(client)][NAME]);
    }
    else
    {
        HudMsg(client, 2, Float:{0.01, 0.25}, {0, 255, 0, 200}, {0, 255, 0, 200}, 0, 0.1, 0.1, 0.4 + 0.1, 0.0, "[Klasa: Brak Klasy]\nWpisz !klasa aby wybrać");
    }
}

// 0.25 -> 0.43

stock Display_ClassInfoAbout(client, who){
    if(CodMod_GetClass(client)){
        PrintHintText(who, "<font size='18'><font color='#0B52B6'> Serwery</font>-<font color='#BF0000'>GO.pl</font>\n <font color='#00CC00'>%s</font> Lvl: %d Exp: %d/%d\n %s</font>", classes[CodMod_GetClass(client)][CLANTAG], CodMod_GetLevel(client), CodMod_GetCurrExp(client), CodMod_GetReqExp(client), perks[CodMod_GetPerk(client)][NAME]);

    }else
    {
        HudMsg(who, 2, Float:{0.01, 0.25}, {0, 255, 0, 200}, {0, 255, 0, 200}, 0, 0.1, 0.1, 0.4 + 0.1, 0.0, "[Klasa: Brak Klasy]\nWpisz !klasa aby wybrać");
        //PrintHintText(who, "<font color='#0B52B6'> Serwery</font>-<font color='#BF0000'>GO.pl</font>\nGracz nie posiada klasy.");
    }
}

public Action:Display_ClassInfo2(client, args){
    Display_ClassInfo(client);
    return Plugin_Handled;
}

public void BuildSelectClassMenu(int iClient){
    if(g_hSelectClassMenus[iClient] != INVALID_HANDLE){
        CloseHandle(g_hSelectClassMenus[iClient]);
        g_hSelectClassMenus[iClient] = INVALID_HANDLE;
    }

    g_hSelectClassMenus[iClient] = CreateMenu(Menu_SelectClass_Handler, MENU_ACTIONS_ALL);
    SetMenuTitle(g_hSelectClassMenus[iClient], "%s", "Wybierz klase: ");

    int iPremiums[10];
    int iPremiumCounter = 0;
    char sBuffer[72];

    char szNumber[10];
    for(new i = 1; i <= registeredClasses; i++){
        if(StrEqual(classes[i][NAME], "UNREG")){
            continue;
        }

        if(StrContains(classes[i][NAME], "[Premium]") != -1){
            iPremiums[iPremiumCounter++] = i;
            continue;
        }

        if(g_PlayersClassesLevelInfo[iClient][i] == 0)
            Format(sBuffer, 72, "%s [Lv. 1]", classes[i][NAME]);
        else
            Format(sBuffer, 72, "%s [Lv. %d]", classes[i][NAME], g_PlayersClassesLevelInfo[iClient][i]);

        IntToString(i, STRING(szNumber));
        AddMenuItem(g_hSelectClassMenus[iClient], szNumber, sBuffer);
    }

    for(int i = 0; i < iPremiumCounter; i++){
        if(g_PlayersClassesLevelInfo[iClient][iPremiums[i]] == 0)
            Format(sBuffer, 72, "%s [Lv. 1]", classes[iPremiums[i]][NAME]);
        else
            Format(sBuffer, 72, "%s [Lv. %d]", classes[iPremiums[i]][NAME], g_PlayersClassesLevelInfo[iClient][iPremiums[i]]);

        IntToString(iPremiums[i], STRING(szNumber));
        AddMenuItem(g_hSelectClassMenus[iClient], szNumber, sBuffer);
    }

    SetMenuExitButton(g_hSelectClassMenus[iClient], true);
}

public Action Menu_SelectClass(int client, int args) {
    if(IsClientInGame(client)){
        if(g_hSelectClassMenus[client] != INVALID_HANDLE){
            DisplayMenu(g_hSelectClassMenus[client], client, 20);
        } else {
            PrintHintText(client, "Trwa ładowanie...");
        }
    }
    return Plugin_Handled;
}


/*public Action:Menu_SelectClass(client, args) {
    if(registeredClasses < 1){
        PrintToServer("%d", registeredClasses);
        PrintHintText(client, "Niestety, aktualnie w grze nie ma dostępnych klas.");
        return Plugin_Handled;
    }
    new Handle:menu = CreateMenu(Menu_SelectClass_Handler, MENU_ACTIONS_ALL);
    SetMenuTitle(menu, "%s", "Wybierz klase: ");


    decl String:sBuffer[72];
    decl String:count[2];
    for(new i = 1; i <= registeredClasses; i++){
        if(StrEqual(classes[i][NAME], "UNREG")){
            continue;
        }

        IntToString(i, count, 2);
        if(g_PlayersClassesLevelInfo[client][i] == 0)
            Format(sBuffer, 72, "%s [Lv. 1]", classes[i][NAME]);
        else
            Format(sBuffer, 72, "%s [Lv. %d]", classes[i][NAME], g_PlayersClassesLevelInfo[client][i]);
        AddMenuItem(menu, count, sBuffer);
    }

    SetMenuExitButton(menu, true);
    DisplayMenu(menu, client, 20);
    return Plugin_Handled;
}*/

public Menu_SelectClass_Handler(Handle:menu, MenuAction:action, client, class){
    switch(action) {
        case MenuAction_Select:
        {
            char szItem[32];
            GetMenuItem(menu, class, STRING(szItem));
            int iClass = StringToInt(szItem);
            SelectClass(client, iClass);
        }

        case MenuAction_End:
        {
            //CloseHandle(menu);
        }
    }
}


public Action:Menu_Stats(client, args) {
    new classId = CodMod_GetClass(client);
    if(!classId)
        return Plugin_Handled;

    new Handle:menu = CreateMenu(Menu_Stats_Handler, MENU_ACTIONS_ALL);


    new availablePoints = GetAvailPoints(client);
    SetMenuTitle(menu, "%s %d", "Dostępne punkty:", availablePoints);

    new String:stats[statsIdxs][64];
    Format(stats[HP], 64, "Witalność: %d [1pkt - 2HP]", clientStats[client][HP] + clientStats[client][HP_PERK]);
    Format(stats[ARMOR], 64, "Wytrzymałość: %d [Redukuje otrzymywane dmg]", clientStats[client][ARMOR] + clientStats[client][ARMOR_PERK]);
    Format(stats[DEX], 64, "Szybkość: %d [Zwiększa prędkość]", clientStats[client][DEX] + clientStats[client][DEX_PERK]);
    Format(stats[INT], 64, "Inteligencja: %d [Polepsza skille klas oraz niektóre perki]", clientStats[client][INT] + clientStats[client][INT_PERK]);
    Format(stats[STRENGTH], 64, "Siła: %d [Zwiększa zadawany damage]", clientStats[client][STRENGTH] + clientStats[client][STRENGTH_PERK]);
    Format(stats[GRAVITY], 64, "Grawitacja: %d [Zmniejsza grawitacje]", clientStats[client][GRAVITY] + clientStats[client][GRAVITY_PERK]);




    AddMenuItem(menu, "1", stats[HP]);
    AddMenuItem(menu, "2", stats[ARMOR]);
    AddMenuItem(menu, "3", stats[DEX]);
    AddMenuItem(menu, "4", stats[INT]);
    AddMenuItem(menu, "5", stats[STRENGTH]);
    AddMenuItem(menu, "6", stats[GRAVITY]);

    char szHelper[32];
    Format(szHelper, sizeof(szHelper), "Prędkość rozdawania: [%d]", g_iStatsSpeeds[g_iStatsSpendingSpeed[client]]);
    AddMenuItem(menu, "7", szHelper);

    SetMenuExitButton(menu, true);
    DisplayMenu(menu, client, 20);
    return Plugin_Handled;
}

public Menu_Stats_Handler(Handle:menu, MenuAction:action, client, stat){
    switch(action) {
        case MenuAction_Select:
        {
            if(stat == 6){
                if(g_iStatsSpendingSpeed[client] + 1 > sizeof(g_iStatsSpeeds) - 1){
                    g_iStatsSpendingSpeed[client] = 0;
                } else {
                    g_iStatsSpendingSpeed[client]++;
                }
                Menu_Stats(client, 0);
                return;
            }

            int iReturn = AddStat(client, statsIdxs:stat);
            if(iReturn == -2){
                PrintToChat(client, "%sMasz za mało punktów do tej prędkości rozdawania!", PREFIX_INFO);
            } else if(iReturn > 0) {
                Menu_Stats(client, 0);
            }

        }

        case MenuAction_End:
        {
            CloseHandle(menu);
        }
    }
}


public Action:Menu_ClassInfo(client, args) {
    if(registeredClasses < 1){
        PrintToServer("%d", registeredClasses);
        PrintHintText(client, "Niestety, aktualnie w grze nie ma dostępnych klas.");
        return Plugin_Handled;
    }
    new Handle:menu = CreateMenu(Menu_ClassInfo_Handler, MENU_ACTIONS_ALL);
    SetMenuTitle(menu, "%s", "Wyświetl info o: ");

    decl String:count[2];
    for(new i = 1; i <= registeredClasses; i++){
        if(StrEqual(classes[i][NAME], "UNREG")){
            continue;
        }

        IntToString(i, count, 2);
        AddMenuItem(menu, count, classes[i][NAME]);
    }

    SetMenuExitButton(menu, true);
    DisplayMenu(menu, client, 20);
    return Plugin_Handled;
}

public Menu_ClassInfo_Handler(Handle:menu, MenuAction:action, client, class){
    switch(action) {
        case MenuAction_Select:
        {
            //PrintToChat(client, "%s %s - %s", PREFIX_INFO, classes[class+1][NAME], classes[class+1][DESC]);
            ShowClassPanel(client, class+1);
        }

        case MenuAction_End:
        {
            CloseHandle(menu);
        }
    }
}



stock void ShowClassPanel(int iClient, int iClass){
    Panel pPanel = new Panel(null);
    pPanel.DrawItem("Klasa: ");
    pPanel.DrawText(classes[iClass][NAME]);

    pPanel.DrawItem("Opis: ");
    pPanel.DrawText(classes[iClass][DESC]);

    pPanel.DrawItem("Statystyki: ");
    char szHelper[64];
    Format(szHelper, sizeof(szHelper), "Wit: %d | Wytrz: %d | Int: %d | Szyb: %d | Siła: %d", classesStats[iClass][HP], classesStats[iClass][ARMOR], classesStats[iClass][INT], classesStats[iClass][DEX], classesStats[iClass][STRENGTH]);
    pPanel.DrawText(szHelper);

    pPanel.DrawItem("Bronie: ");
    for(int i = 0; i < WEAPON_LIMIT; i++){
        if(classesWeapons[iClass][i] == WEAPON_NONE)
            continue;
        pPanel.DrawText(weaponNames[classesWeapons[iClass][i]]);
    }

    pPanel.DrawItem("Wyjście");


    pPanel.Send(iClient, ShowClassPanel_Handler, 30);

}


public int ShowClassPanel_Handler(Menu mMenu, MenuAction maAction, int iClient, int iItem){
    if(maAction == MenuAction_Select){
        if(iItem != 5)
            Menu_ClassInfo(iClient, 0);

    } else if(maAction == MenuAction_End || maAction == MenuAction_Cancel) {
        delete mMenu;
        Menu_ClassInfo(iClient, 0);
    }
}


public Action:Display_Top15(client, args){
    new Handle:menu = CreateMenu(Menu_Stats_Handler, MENU_ACTIONS_ALL);
    SetMenuExitButton(menu, true);


    decl String:query[ARRAY_LENGTH];
    Format(query, 255, "SELECT `player_name`, `class_name`, `level` FROM `codmod` ORDER BY `level` DESC LIMIT 15");
    new Handle:result = SQL_HandleQuery(query);


    decl String:name[128];
    decl String:className[64];
    new level = 0;
    decl String:toDisplay[255];
    while(SQL_FetchRow(result)){
        SQL_FetchString(result, 0, name, 128);
        SQL_FetchString(result, 1, className, 64);
        level = SQL_FetchInt(result, 2);
        Format(toDisplay, 255, "%s - %s: %d poziom", name, className, level);
        AddMenuItem(menu, "0", toDisplay);
    }
    CloseHandle(result);
    DisplayMenu(menu, client, 20);
    return Plugin_Handled;
}
public Action:Info_Perk(client, args) {
    new perkId = CodMod_GetPerk(client);
    if(perkId)
        PrintToChat(client, "%s Perk: %s Wytrzymałość: %d Opis: %s", PREFIX_INFO, perks[perkId][NAME], CodMod_GetPerkArmor(client), perks[perkId][DESC]);
    else
        PrintToChat(client, "%s Zabij kogoś aby otrzymać perk!", PREFIX_INFO);
    return Plugin_Handled;
}

public Action:Reset_Stats(client, args) {
    new classId = CodMod_GetClass(client);
    if(!classId)
        return Plugin_Handled;

    CodMod_SetStat(client, HP, classesStats[classId][HP]);
    CodMod_SetStat(client, ARMOR, classesStats[classId][ARMOR]);
    CodMod_SetStat(client, INT, classesStats[classId][INT]);
    CodMod_SetStat(client, DEX, classesStats[classId][DEX]);
    CodMod_SetStat(client, STRENGTH, classesStats[classId][STRENGTH]);
    CodMod_SetStat(client, GRAVITY, classesStats[classId][GRAVITY]);
    PrintToChat(client, "%sTwoje statystyki zostały zresetowane!", PREFIX);
    //DB_UpdatePlayer(client);
    return Plugin_Handled;
}


public Action:Regive_Perk(client, args) {
    if(CodMod_GetPerk(client) == 0){
        PrintToChat(client, "%sMusisz posiadać perk, aby go oddać!", PREFIX_INFO);
        return Plugin_Handled;
    }

    new Handle:menu = CreateMenu(Menu_Regive_Perk_Handler, MENU_ACTIONS_ALL);
    SetMenuTitle(menu, "%s", "Komu chcesz oddać perk?");
    SetMenuExitButton(menu, true);
    decl String:name[128];
    decl String:clientId[3];
    for(new i = 1; i <= MaxClients; i++){
        if(!IsClientInGame(i) || IsFakeClient(i) || i == client)
            continue;
        IntToString(i, clientId, 3);
        GetClientName(i, name, 128);
        AddMenuItem(menu, clientId, name);
    }
    DisplayMenu(menu, client, 10);
    return Plugin_Handled;
}

public Menu_Regive_Perk_Handler(Handle:menu, MenuAction:action, client, position){
    switch(action) {
        case MenuAction_Select:
        {
            decl String:menuInfo[3];
            GetMenuItem(menu, position, menuInfo, 3);
            new receiver = StringToInt(menuInfo);
            Regive_Perk_To(client, receiver);
        }

        case MenuAction_End:
        {
            CloseHandle(menu);
        }
    }

}

public Regive_Perk_To(from, to){
    if(!to){
        PrintToChat(from, "%sGracz o takim nicku nie jest w grze, lub nie istnieje!", PREFIX_INFO);
        return;
    }

    decl String:giverName[128];
    GetClientName(from, giverName, 128);

    new Handle:menu = CreateMenu(Menu_Regive_Perk_Give_Handler, MENU_ACTIONS_ALL);
    SetMenuTitle(menu, "%s %s %s %d %s %s", "Czy chcesz otrzymać perk: ", perks[CodMod_GetPerk(from)][NAME], " o wytrzymałości: ", CodMod_GetPerkArmor(from), " od gracza: ", giverName);

    decl String:clientIdString[3];
    IntToString(from, clientIdString, 3);
    AddMenuItem(menu, clientIdString, "Tak");
    AddMenuItem(menu, clientIdString, "Nie");

    SetMenuExitButton(menu, false);
    DisplayMenu(menu, to, 10);

    return;
}


public Menu_Regive_Perk_Give_Handler(Handle:menu, MenuAction:action, client, position){
    decl String:menuInfo[6];
    GetMenuItem(menu, position, menuInfo, 6);
    new giver = StringToInt(menuInfo);
    switch(action) {
        case MenuAction_Select:
        {
            if(position == 0){
                Call_PerkDisabled(client);
                SetPerk(client, CodMod_GetPerk(giver), CodMod_GetPerkArmor(giver));
                CodMod_DropPerk(giver);
                PrintToChat(client, "%s Gracz oddał Ci perk", PREFIX);
                PrintToChat(giver, "%s Perk został oddany!", PREFIX);
            } else {
                PrintToChat(giver, "%s Gracz nie chciał przyjąć Twojego perku", PREFIX);
            }
        }

        case MenuAction_End:
        {
            CloseHandle(menu);
        }
    }
}

// Exchange
public Action:Exchange_Perk(client, args) {
    if(CodMod_GetPerk(client) == 0){
        PrintToChat(client, "%sMusisz posiadać perk, aby się nim wymienić!", PREFIX_INFO);
        return Plugin_Handled;
    }

    new Handle:menu = CreateMenu(Menu_Exchange_Perk_Handler, MENU_ACTIONS_ALL);
    SetMenuTitle(menu, "%s", "Z kim chcesz się wymienić?");
    SetMenuExitButton(menu, true);
    decl String:name[128];
    decl String:clientId[3];
    for(new i = 1; i <= MaxClients; i++){
        if(!IsClientInGame(i) || IsFakeClient(i) || i == client || g_bTradeBlockade[i])
            continue;
        IntToString(i, clientId, 3);
        GetClientName(i, name, 128);
        Format(name, 128, "%s %s", name, perks[CodMod_GetPerk(i)][NAME]);
        AddMenuItem(menu, clientId, name);
    }
    DisplayMenu(menu, client, 10);
    return Plugin_Handled;
}

public Menu_Exchange_Perk_Handler(Handle:menu, MenuAction:action, client, position){
    switch(action) {
        case MenuAction_Select:
        {
            decl String:menuInfo[3];
            GetMenuItem(menu, position, menuInfo, 3);
            new receiver = StringToInt(menuInfo);
            Exchange_Perk_To(client, receiver);
        }

        case MenuAction_End:
        {
            CloseHandle(menu);
        }
    }

}

public Exchange_Perk_To(from, to){
    if(!to){
        PrintToChat(from, "%sGracz o takim nicku nie jest w grze, lub nie istnieje!", PREFIX_INFO);
        return;
    }

    decl String:giverName[128];
    GetClientName(from, giverName, 128);

    new Handle:menu = CreateMenu(Menu_Exchange_Perk_Give_Handler, MENU_ACTIONS_ALL);
    SetMenuTitle(menu, "%s %s %s %d %s %s", "Czy się wymienić na perk: ", perks[CodMod_GetPerk(from)][NAME], " o wytrzymałości:", CodMod_GetPerkArmor(from), " z graczem:", giverName);

    decl String:clientIdString[3];
    IntToString(from, clientIdString, 3);
    AddMenuItem(menu, clientIdString, "Tak");
    AddMenuItem(menu, clientIdString, "Nie");

    SetMenuExitButton(menu, false);
    DisplayMenu(menu, to, 10);

    return;
}


public Menu_Exchange_Perk_Give_Handler(Handle:menu, MenuAction:action, client, position){
    decl String:menuInfo[6];
    GetMenuItem(menu, position, menuInfo, 6);
    new giver = StringToInt(menuInfo);
    switch(action) {
        case MenuAction_Select:
        {
            if(position == 0){
                new perk = CodMod_GetPerk(client);
                new perk_armor = CodMod_GetPerkArmor(client);
                if(CodMod_GetPerk(giver) == 0 || perk == 0){
                  PrintToChat(giver, "%sWymiana nie powiodła się!", PREFIX);
                  return;
                }
                Call_PerkDisabled(client);
                SetPerk(client, CodMod_GetPerk(giver), CodMod_GetPerkArmor(giver));
                Call_PerkDisabled(giver);
                SetPerk(giver, perk, perk_armor);
                PrintToChat(client, "%sWymieniłeś się perkiem!", PREFIX);
                PrintToChat(giver, "%sWymieniłeś się perkiem!", PREFIX);
            } else {
                PrintToChat(giver, "%sWymiana nie powiodła się!", PREFIX);
            }
        }

        case MenuAction_End:
        {
            PrintToChat(giver, "%sWymiana nie powiodła się!", PREFIX);
            CloseHandle(menu);
        }
    }
}

public Action:Drop_Perk(client, args) {
    CodMod_DropPerk(client);
}

public Action:Menu_PerkInfo(client, args) {
    if(registeredClasses < 1){
        PrintHintText(client, "Niestety, aktualnie w grze nie ma dostępnych perków.");
        return Plugin_Handled;
    }
    new Handle:menu = CreateMenu(Menu_PerkInfo_Handler, MENU_ACTIONS_ALL);
    SetMenuTitle(menu, "%s", "Wyświetl info o: ");

    decl String:count[2];
    for(new i = 1; i <= registeredPerks; i++){
        if(StrEqual(perks[i][NAME], "UNREG")){
            continue;
        }

        IntToString(i, count, 2);
        AddMenuItem(menu, count, perks[i][NAME]);
    }

    SetMenuExitButton(menu, true);
    DisplayMenu(menu, client, 20);
    return Plugin_Handled;
}

public Menu_PerkInfo_Handler(Handle:menu, MenuAction:action, client, perk){
    switch(action) {
        case MenuAction_Select:
        {
            PrintToChat(client, "%s %s - %s", PREFIX_INFO, perks[perk+1][NAME], perks[perk+1][DESC]);
            Menu_PerkInfo(client, 0);

            /*if(CheckCommandAccess(client, "th7_cheats", ADMFLAG_CUSTOM6))
            {
                SetPerk(client, perk+1, 100);
                PrintToChat(client, "%sOtrzymałeś perk! %s", PREFIX_INFO, perks[perk+1][NAME]);
            }*/

        }

        case MenuAction_End:
        {
            CloseHandle(menu);
        }
    }
}

stock GetAvailPoints(client){
    new hp, armor, dex, int_stat, strength;
    new classId = CodMod_GetClass(client);
    hp = clientStats[client][HP] - classesStats[classId][HP];
    armor = clientStats[client][ARMOR] - classesStats[classId][ARMOR];
    dex = clientStats[client][DEX] - classesStats[classId][DEX];
    int_stat = clientStats[client][INT] - classesStats[classId][INT];
    strength = clientStats[client][STRENGTH] - classesStats[classId][STRENGTH];
    new gravity = clientStats[client][GRAVITY] - classesStats[classId][GRAVITY];

    int availablePoints = 0;
    /*if(classesIsVip[classId]){
        availablePoints = 30;
    } else {
        availablePoints = 25;
    }*/

    availablePoints += (CodMod_GetLevel(client) * 2) - (hp + armor + dex + int_stat + strength + gravity);
    return availablePoints;
}

stock AddStat(client, statsIdxs:stat){
    new hp, armor, dex, int_stat, strength, gravity;
    new classId = CodMod_GetClass(client);
    hp = clientStats[client][HP] - classesStats[classId][HP];
    armor = clientStats[client][ARMOR] - classesStats[classId][ARMOR];
    dex = clientStats[client][DEX] - classesStats[classId][DEX];
    int_stat = clientStats[client][INT] - classesStats[classId][INT];
    strength = clientStats[client][STRENGTH] - classesStats[classId][STRENGTH];
    gravity = clientStats[client][GRAVITY] - classesStats[classId][GRAVITY];
    new availablePoints = GetAvailPoints(client);

    int iSpeed = g_iStatsSpeeds[g_iStatsSpendingSpeed[client]];
    if(availablePoints >= iSpeed){
        if(hp + classesStats[classId][HP] + iSpeed > MAX_STAT && stat == HP){
            PrintToChat(client, "%sNie możesz dać więcej niż %d w jedną statystykę!", PREFIX, MAX_STAT);
            return 0;
        }

        if(armor + classesStats[classId][ARMOR] + iSpeed > MAX_STAT && stat == ARMOR){
            PrintToChat(client, "%sNie możesz dać więcej niż %d w jedną statystykę!", PREFIX, MAX_STAT);
            return 0;
        }

        if(int_stat + classesStats[classId][INT] + iSpeed > MAX_STAT && stat == INT){
            PrintToChat(client, "%sNie możesz dać więcej niż %d w jedną statystykę!", PREFIX, MAX_STAT);
            return 0;
        }

        if(dex + classesStats[classId][DEX] + iSpeed > MAX_STAT && stat == DEX){
            PrintToChat(client, "%sNie możesz dać więcej niż %d w jedną statystykę!", PREFIX, MAX_STAT);
            return 0;
        }

        if(strength + classesStats[classId][STRENGTH] + iSpeed > MAX_STAT && stat == STRENGTH){
            PrintToChat(client, "%sNie możesz dać więcej niż %d w jedną statystykę!", PREFIX, MAX_STAT);
            return 0;
        }


        if(gravity + classesStats[classId][GRAVITY] + iSpeed > MAX_STAT && stat == GRAVITY){
            PrintToChat(client, "%sNie możesz dać więcej niż %d w jedną statystykę!", PREFIX, MAX_STAT);
            return 0;
        }

        clientStats[client][stat] += iSpeed;
        return availablePoints - iSpeed;
    } else if(iSpeed > 1) {
        return -2;
    }

    return 0;
}


stock SelectClass(client, classId){
    if(CodMod_GetClass(client)){
        PrintToChat(client, "%sKlasa zostanie zmieniona w następnej rundzie.", PREFIX);
        changedClass[client] = classId;
        //DB_UpdatePlayer(client);
        return;
    }
    if(classesIsVip[classId]){
        if(GetUserAdmin(client) != INVALID_ADMIN_ID){
            if(!(GetAdminFlags(GetUserAdmin(client), Access_Effective) & classesIsVip[classId]) && !(GetAdminFlags(GetUserAdmin(client), Access_Real) & classesIsVip[classId])){
                PrintToChat(client, "%sNiestety, klasa którą wybrałeś jest PREMIUM odwiedź stronę http://Serwery-GO.pl aby uzyskać klasę PREMIUM.", PREFIX);
                return;
            }
        } else {
            PrintToChat(client, "%sNiestety, klasa którą wybrałeś jest PREMIUM odwiedź stronę http://Serwery-GO.pl aby uzyskać klasę PREMIUM.", PREFIX);
            return;
        }
    }


    
    if(IsPlayerAlive(client)){
        Client_RemoveAllWeapons(client, "weapon_knife");
    }


    CodMod_DropPerk(client);
    // quality change
    CodMod_SetClass(client, classId);



    decl String:auth[48];
    GetClientAuthId(client, AuthId_Steam2, auth, 48);

    decl String:getQuery[ARRAY_LENGTH];
    Format(getQuery, 255, "SELECT `exp`, `level`, `hp`, `armor`, `int`, `dex`, `strength`,`gravity` FROM `codmod` WHERE `player_sid`='%s' AND `class_name`='%s' LIMIT 1", auth, classes[classId][NAME]);
    SQL_TQuery(hDatabase, GetClassCallback, getQuery, GetClientSerial(client), DBPrio_High);

    CS_SetClientClanTag(client, classes[classId][CLANTAG]);

// moved

}

public GetClassCallback(Handle:owner, Handle:result, const String:error[], any:client){
    client = GetClientFromSerial(client)
    if(!IsValidPlayer(client)){
        return
    }
    new classId = CodMod_GetClass(client);
    new hp, armor, int_stat, dex, exp, strength, level, gravity;

    new String:clientName[255];
    GetClientName(client, clientName, 255);
    clientName = SQL_Escape(clientName);

    new String:auth[48];
    GetClientAuthId(client, AuthId_Steam2, auth, 48);

    if(result == INVALID_HANDLE){
        hp = classesStats[classId][HP]
        armor = classesStats[classId][ARMOR];
        int_stat = classesStats[classId][INT];
        dex = classesStats[classId][DEX];
    } else {
        if(SQL_FetchRow(result)){
            exp = SQL_FetchInt(result, 0);
            level = SQL_FetchInt(result, 1);
            hp = SQL_FetchInt(result, 2);
            armor = SQL_FetchInt(result, 3);
            int_stat = SQL_FetchInt(result, 4);
            dex = SQL_FetchInt(result, 5);
            strength = SQL_FetchInt(result, 6);
            gravity = SQL_FetchInt(result, 7);

            CodMod_SetLevel(client, level);
            CodMod_SetExp(client, exp);
        } else {
            hp = classesStats[classId][HP]
            armor = classesStats[classId][ARMOR];
            int_stat = classesStats[classId][INT];
            dex = classesStats[classId][DEX];
            strength = classesStats[classId][STRENGTH];
            gravity = classesStats[classId][GRAVITY];
            decl String:insertQuery[ARRAY_LENGTH];
            Format(insertQuery, ARRAY_LENGTH, "INSERT INTO `codmod` SET `player_name`='%s', `player_sid`='%s', `class_name`='%s', `exp`=0, `level`=1, `hp`=%d, `armor`=%d, `dex`=%d, `int`=%d, `strength`=%d, `gravity`=%d", clientName, auth, classes[classId][NAME], classesStats[classId][HP], classesStats[classId][ARMOR], classesStats[classId][DEX], classesStats[classId][INT], classesStats[classId][STRENGTH], classesStats[classId][GRAVITY]);
            SQL_DirectQuery(insertQuery);
            CodMod_SetLevel(client, 1);
            CodMod_SetExp(client, 0);
        }
    }

    CodMod_SetStat(client, HP, hp);
    CodMod_SetStat(client, ARMOR, armor);
    CodMod_SetStat(client, DEX, dex);
    CodMod_SetStat(client, INT, int_stat);
    CodMod_SetStat(client, STRENGTH, strength);
    CodMod_SetStat(client, GRAVITY, gravity);

    if(IsPlayerAlive(client)){
        UpdateHealth(client) // STAT HP
        UpdateWeapons(client);
    }
}

public int Native_GetMaxHP(Handle hPlugin, int iNumParams){
    int client = GetNativeCell(1);

    int iReturn = classesStats[CodMod_GetClass(client)][STARTING_HP] + (((clientStats[client][HP]) + (clientStats[client][HP_PERK])) * HP_MULTIPLIER);
    return iReturn;
}


public int Native_GetPlayerNades(Handle hPlugin, int iNumParams){
    int iClient = GetNativeCell(1);
    int iNadeID = GetNativeCell(2);

    return GetEntProp(iClient, Prop_Data, "m_iAmmo", _, g_iaGrenadeOffsets[iNadeID]);
}

stock UpdateHealth(client){
    new toSet = classesStats[CodMod_GetClass(client)][STARTING_HP] + (((clientStats[client][HP]) + (clientStats[client][HP_PERK])) * HP_MULTIPLIER);
    if(toSet < 1)
        toSet = 1;

    if(g_PlayersInfo[client][HP_OVERRIDE]){
        toSet = g_PlayersInfo[client][HP_OVERRIDE];
    }


    SetEntityHealth(client, toSet);
    SetEntProp(client, Prop_Data,"m_iMaxHealth", toSet);
    //SetEntData(client, g_iOffsetArmorValue, 100 + ((clientStats[client][ARMOR] + clientStats[client][ARMOR_PERK]) * ARMOR_MULTIPLIER));
}

stock UpdateWeapons(client){
    new classId = CodMod_GetClass(client);
    if(!classId)
        return;


    //new String:weaponClassName[64];
    for(new i = 0; i < WEAPON_LIMIT; i++){
        if(classesWeapons[classId][i] == WEAPON_NONE)
            continue;

        new String:nameOfWeapon[32];
        Format(nameOfWeapon, 32, "weapon_%s", weaponNames[classesWeapons[classId][i]]);
        if(classesWeapons[classId][i] == WEAPON_STANDARDPISTOLS){
            if(GetClientTeam(client) == CS_TEAM_T){
                Format(nameOfWeapon, 32, "weapon_%s", weaponNames[WEAPON_GLOCK]);
            } else {
                Format(nameOfWeapon, 32, "weapon_%s", weaponNames[WEAPON_HKP2000]);
            }
            //PrintToChat(client, nameOfWeapon);

        }


        new weaponIndex, bool:hasWeapon = false;
        for(new slot = 0; slot <= 2; slot++){
            weaponIndex = GetPlayerWeaponSlot(client, slot);
            if(weaponIndex != -1){
                /*GetRealWeaponName(weaponIndex, weaponClassName, 64)
                if(StrEqual(weaponClassName, nameOfWeapon)){
                    hasWeapon = true;
                }*/
                if(CodMod_GetWeaponID(weaponIndex) == classesWeapons[classId][i]){
                    hasWeapon = true;
                }
            }
        }

        if(classesWeapons[classId][i] == WEAPON_HEGRENADE){
            if(GetClientHEGrenades(client))
                hasWeapon = true;
        } else if(classesWeapons[classId][i] == WEAPON_FLASHBANG){
            if(GetClientFlashbangs(client) >= 2)
                hasWeapon = true;
        } else if(classesWeapons[classId][i] == WEAPON_SMOKEGRENADE){
            if(GetClientSmokeGrenades(client))
                hasWeapon = true;
        } else if(classesWeapons[classId][i] == WEAPON_MOLOTOV){
            if(GetClientMolotovs(client))
                hasWeapon = true;
        } else if(classesWeapons[classId][i] == WEAPON_TAGRENADE){
            if(GetClientTacticals(client)){
                hasWeapon = true;
            }
        }
        if(classesWeapons[classId][i] == WEAPON_HEALTHSHOT) {
            hasWeapon = false;
        }


        if(hasWeapon == false) {
            int iEntity = GivePlayerItem(client, nameOfWeapon);
            if(classesWeapons[classId][i] != WEAPON_STANDARDPISTOLS)
                g_iWeaponIDs[iEntity] = classesWeapons[classId][i];
        }

    }
}

stock DB_UpdatePlayer(client){
    new classId = CodMod_GetClass(client);
    if(!classId){
        return;
    }

    g_PlayersClassesLevelInfo[client][classId] = g_PlayersInfo[client][LEVEL];
    decl String:auth[48];
    GetClientAuthId(client, AuthId_Steam2, auth, 48);

    char szClientName[64];
    char szEscaped[128];
    GetClientName(client, szClientName, 64);
    SQL_EscapeString(hDatabase, szClientName, szEscaped, 128);

    decl String:insertQuery[ARRAY_LENGTH];
    Format(insertQuery, ARRAY_LENGTH, "UPDATE `codmod` SET `player_name`='%s', `exp`=%d, `level`=%d, `hp`=%d, `armor`=%d, `dex`=%d, `int`=%d, `strength`=%d, `gravity`=%d WHERE `player_sid`='%s' AND `class_name`='%s'", szEscaped, CodMod_GetCurrExp(client), CodMod_GetLevel(client), clientStats[client][HP], clientStats[client][ARMOR], clientStats[client][DEX], clientStats[client][INT], clientStats[client][STRENGTH], clientStats[client][GRAVITY], auth, classes[classId][NAME]);
    SQL_DirectQuery(insertQuery);
}

stock CodMod_WeakenPerk(client, start=10, end=22){
    new amount = GetRandomInt(start, end);
    Call_StartForward(g_OnWeakenPerk);
    Call_PushCell(client);
    Call_PushCell(CodMod_GetPerk(client));
    Call_PushCell(amount);
    Call_Finish();

    g_PlayersInfo[client][PERK_ARMOR] = CodMod_GetPerkArmor(client) - amount;
    if(CodMod_GetPerkArmor(client) <= 0){
        CodMod_DropPerk(client);
    }
}
public CodMod_OnGiveRandomPerk(Handle:plugin, numParams){
    new client = GetNativeCell(1);
    CodMod_DropPerk(client);
    int perkId = 0;
    do
    {
        perkId = GetRandomInt(1, registeredPerks);

    } while(StrEqual(perks[perkId][NAME], "UNREG"));



    PrintToChat(client, "%sOtrzymałeś perk! %s", PREFIX_INFO, perks[SetPerk(client, perkId, 100)][NAME]);
}

stock CodMod_DropPerk(client){
    new perkId = CodMod_GetPerk(client);
    if(perkId){
        Call_StartForward(g_OnPerkDisabled);
        Call_PushCell(client);
        Call_PushCell(perkId);
        Call_Finish();
        PrintToChat(client, "%s Twój perk został zniszczony!", PREFIX);
    }

    SetPerk(client, 0, 0);
}
stock Call_PerkDisabled(client){
    new perkId = CodMod_GetPerk(client);
    if(perkId){
        Call_StartForward(g_OnPerkDisabled);
        Call_PushCell(client);
        Call_PushCell(perkId);
        Call_Finish();
    }
}

bool IsCommandoPerkBlocked(int perk){
  for(int i = 0; i < g_iBlockedWeaponPerksSize; i++){
      if(perk == g_iBlockedWeaponPerks[i]){
          return true;
      }
  }

  return false;
}

stock SetPerk(int client, int perk, int armoramount){
    if(perk != 0 && g_iCommandoID != -1 && CodMod_GetClass(client) == g_iCommandoID){
        while(IsCommandoPerkBlocked(perk)){
          perk = GetRandomInt(1, registeredPerks);
        }
    }

    while(CodMod_GetClass(client) == g_iElitSniperID && perk == g_iCamouflageMask){
        perk = GetRandomInt(1, registeredPerks)
    }


    g_PlayersInfo[client][PERK] = perk;
    g_PlayersInfo[client][PERK_ARMOR] = armoramount;

    if(perk){
        Call_StartForward(g_OnPerkEnabled);
        Call_PushCell(client);
        Call_PushCell(perk);
        Call_Finish();
    }

    return perk
}


public EmptyCallback(Handle:owner, Handle:hndl, const String:error[], any:client){
    if (hndl == INVALID_HANDLE)
    {
        LogError("ZJEBAO SIE, %s", error);
        return;
    }
}

public ConnectCallback(Handle:owner, Handle:hndl, const String:error[], any:client){
    if (hndl == INVALID_HANDLE) {
        LogError("ZJEBAO SIE CONNECTION, %s", error);
        hDatabase = INVALID_HANDLE;
    } else {
        hDatabase = CloneHandle(hndl);
        SQL_SetCharset(hDatabase, "utf8mb4");
        SQL_DirectQuery("CREATE TABLE IF NOT EXISTS `codmod` (`id` int(11) NOT NULL AUTO_INCREMENT, `player_name` varchar(255) DEFAULT NULL, `player_sid` varchar(255) DEFAULT NULL, `class_name` varchar(255) DEFAULT NULL, `exp` int(11) DEFAULT NULL, `level` int(8) DEFAULT NULL, `hp` int(8) DEFAULT NULL, `armor` int(8) DEFAULT NULL, `int` int(8) DEFAULT NULL, `dex` int(8) DEFAULT NULL, `strength` int(8) DEFAULT NULL, `gravity` int(8) DEFAULT NULL, PRIMARY KEY (`id`)) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4");
    }
}


/****************************************************** TOOLS ************************************/
stock SQL_Initialize(){
    SQL_TConnect(ConnectCallback);
}

stock String:SQL_Escape(String:string[]){
    decl String:escaped[ARRAY_LENGTH];
    SQL_EscapeString(hDatabase, string, escaped, sizeof(escaped));
    return escaped;
}

stock bool:SQL_DirectQuery(const String:query[]){
    if(hDatabase == INVALID_HANDLE){
        SQL_Initialize();
    }
    SQL_TQuery(hDatabase, EmptyCallback, query, 0, DBPrio_High);
    return true;
}

public CheckCallback(Handle:owner, Handle:hndl, const String:error[], any:client){
    if (hndl == INVALID_HANDLE)
    {
        LogError("ZJEBAO SIE, %s", error);
        return 0;
    } else {
        if(SQL_FetchRow(hndl)){
            return 1;
        } else {
            return 0;
        }
    }
}

stock Handle:SQL_HandleQuery(String:query[]) {
    new Handle:hResult = SQL_Query(hDatabase, query);
    if(hResult == INVALID_HANDLE){
        decl String:error[ARRAY_LENGTH];
        SQL_GetError(hDatabase, error, ARRAY_LENGTH);
        PrintToServer("Error - SQL_CheckQuery: %s \t Query: %s", error, query);
        return INVALID_HANDLE;
    } else {
        return hResult;
    }
}


stock GetClientHEGrenades(client)  {
    return GetEntProp(client, Prop_Data, "m_iAmmo", _, g_iaGrenadeOffsets[3]);
}

stock GetClientSmokeGrenades(client) {
    return GetEntProp(client, Prop_Data, "m_iAmmo", _, g_iaGrenadeOffsets[2]);
}


stock GetClientDecoys(client) {
    return GetEntProp(client, Prop_Data, "m_iAmmo", _, g_iaGrenadeOffsets[4]);
}

stock GetClientFlashbangs(client) {
    return GetEntProp(client, Prop_Data, "m_iAmmo", _, g_iaGrenadeOffsets[0]);
}

stock GetClientMolotovs(client) {
    return GetEntProp(client, Prop_Data, "m_iAmmo", _, g_iaGrenadeOffsets[1]);
}

stock GetClientInc(client) {
    return GetEntProp(client, Prop_Data, "m_iAmmo", _, g_iaGrenadeOffsets[5]);
}

stock GetClientTacticals(client) {
    return GetEntProp(client, Prop_Data, "m_iAmmo", _, g_iaGrenadeOffsets[6]);
}


public int Native_PerformEntityExplosion(Handle hPlugin, int iNumParams){
    int iEntity = GetNativeCell(1);
    int iOwner = GetNativeCell(2);
    if(!IsValidPlayer(iOwner)){
        return 0;
    }

    Player_PerformEntityExplosion(iEntity, iOwner, view_as<float>(GetNativeCell(3)), GetNativeCell(4), view_as<float>(GetNativeCell(5)), GetNativeCell(6));

    return 0;
}

public CodMod_OnDealDamage(Handle hPlugin, int iNumParams){
    int iAttacker = GetNativeCell(1);
    int iVictim = GetNativeCell(2);
    float fDamage = view_as<float>(GetNativeCell(3));
    int iTH7Dmg = GetNativeCell(4);

    if(iVictim == 0){
      return -1;
    }

    Call_StartForward(g_hOnTH7Dmg);
    Call_PushCell(iVictim);
    Call_PushCell(iAttacker);
    Call_PushFloatRef(fDamage);
    Call_PushCell(iTH7Dmg);
    Call_Finish();

    Call_StartForward(g_hOnTH7DmgPost);
    Call_PushCell(iVictim);
    Call_PushCell(iAttacker);
    Call_PushFloatRef(fDamage);
    Call_PushCell(iTH7Dmg);
    Call_Finish();

    if(fDamage != 0.0){
        Handle hPack = CreateDataPack();
        WritePackCell(hPack, GetClientSerial(iVictim));
        if(iAttacker == 0){
          WritePackCell(hPack, 0);
        } else {
          WritePackCell(hPack, GetClientSerial(iAttacker));
        }

        WritePackFloat(hPack, fDamage);
        CreateTimer(0.02, Timer_DealDamageNative, hPack);
    }

    return 0;
}

public Action Timer_DealDamageNative(Handle hTimer, Handle hPack){
    ResetPack(hPack);
    int iVictim = GetClientFromSerial(ReadPackCell(hPack));
    int iAttacker = GetClientFromSerial(ReadPackCell(hPack));
    float fDamage = ReadPackFloat(hPack);
    CloseHandle(hPack);

    int iArmor = GetEntData(iVictim, g_iOffsetArmorValue);
    SetEntData(iVictim, g_iOffsetArmorValue, 0, _, true);
    if(IsValidPlayer(iAttacker) && !IsPlayerAlive(iAttacker)){
        //SetEntProp(iAttacker, Prop_Data, "m_lifeState", 1);
        SDKHooks_TakeDamage(iVictim, iAttacker, iAttacker, fDamage);
        //SetEntProp(iAttacker, Prop_Send, "m_lifeState", 0);
    } else {
        SDKHooks_TakeDamage(iVictim, iAttacker, iAttacker, fDamage);
    }


    SetEntData(iVictim, g_iOffsetArmorValue, iArmor, _, true);

    return Plugin_Stop;
}


public void Player_PerformEntityExplosion(int iEntity, int iOwner, float fDamage, int iRadius, float fIgniteTime, int iTH7Dmg){
    if(!IsValidPlayer(iOwner) || !IsValidEntity(iEntity))
        return;

    /*char szEntityName[32];
    GetEntPropString(iEntity, Prop_Data, "m_iName", szEntityName, sizeof(szEntityName));
    if(StrContains(szEntityName, "cm") == -1)
        return;*/

    float fVec[3];
    GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", fVec);

    int iColor[4]={188, 220 ,255, 200};

    TE_SetupExplosion(fVec, g_iExplosionSprite, 10.0, 1, 0, iRadius, 5000);
    TE_SendToAll();
    TE_SetupBeamRingPoint(fVec, 10.0, float(iRadius), g_iFire, g_iHaloSprite, 0, 10, 0.6, 10.0, 0.5, iColor, 10, 0);
    TE_SendToAll();
    fVec[2] += 10.0;
    TE_SetupExplosion(fVec, g_iExplosionSprite, 10.0, 1, 0, iRadius, 5000);
    TE_SendToAll();

    int iTeam = GetClientTeam(iOwner);

    float fBaseDamage = fDamage;
    int iRandom = GetRandomInt(1,4);
    for (int i = 1; i <= MaxClients; ++i) {
        if (!IsValidPlayer(i) || !IsPlayerAlive(i) || iTeam == GetClientTeam(i) || i == iOwner)
            continue;
        fDamage = fBaseDamage;

        float fPos[3];
        GetClientAbsOrigin(i, fPos);
        float fDistance = GetVectorDistance(fVec, fPos);
        if (fDistance > float(iRadius))
            continue;

        if(iTH7Dmg != TH7_DMG_MINE && iTH7Dmg != TH7_DMG_LASERMINE && !IsEntityVisible(iOwner, i))
            continue;

        //fDamage = fDamage * (float(iRadius) - fDistance) / float(iRadius);
        CodMod_DealDamage(iOwner, i, fDamage, iTH7Dmg);
        if(CodMod_GetClass(iOwner) == CodMod_GetClassId("Wsparcie Ogniowe") && iTH7Dmg == TH7_DMG_ROCKET ){
            if(iRandom == 1) {
                CodMod_Burn(iOwner, i, 3.0, 1.0, 7.0 )
            }
        }


        TE_SetupExplosion(fPos, g_iExplosionSprite, 0.05, 1, 0, 1, 1);
        TE_SendToAll();
    }

    EmitAmbientSound("*serwery-go_ndm/explosion_nuke.mp3", fVec, iEntity, SNDLEVEL_RAIDSIREN);
    if(iEntity > MAXPLAYERS + 1 && IsValidEntity(iEntity))
        RemoveEdict(iEntity);
}


/**********************************************************************************************************/
#define SOUND_FROSTNADE_EXPLODE    "ui/freeze_cam.wav"

public int Native_Freeze(Handle hPlugin, int iNumParams)
{
    int iClient = GetNativeCell(1);
    float fTime = view_as<float>(GetNativeCell(2));

    return view_as<int>(Freeze(iClient, fTime));
}

public bool Freeze(int iClient, float fTime)
{
    if(!g_bFreezed[iClient])
    {
        g_bFreezed[iClient] = true;
        SetEntityMoveType(iClient, MOVETYPE_NONE);
        Handle hPack = CreateDataPack();
        WritePackCell(hPack, GetClientSerial(iClient));
        WritePackCell(hPack, g_iRoundIndex);
        CreateTimer(fTime, Timer_Unfreeze, hPack);
        return true;
    }
    return false;
}

public Action Timer_Unfreeze(Handle hTimer, Handle hData)
{
    ResetPack(hData);
    int iClient = GetClientFromSerial(ReadPackCell(hData));
    int iRoundIndex = ReadPackCell(hData);
    delete hData;

    if(g_iRoundIndex != iRoundIndex || !IsValidPlayer(iClient)) return Plugin_Stop;

    if(IsPlayerAlive(iClient))
    {
        SetEntityMoveType(iClient, MOVETYPE_WALK);
    }
    g_bFreezed[iClient] = false;
    return Plugin_Stop;
}


public int Native_RadiusFreeze(Handle hPlugin, int iNumParams)
{
    int iEntity = GetNativeCell(1);
    int iRadius = GetNativeCell(2);
    float fTime = view_as<float>(GetNativeCell(3));

    return view_as<int>(RadiusFreeze(iEntity, iRadius, fTime));
}

public bool RadiusFreeze(int iEntity, int iRadius, float fTime)
{
    float fOrigin[3];
    float pVictimOrigin[3];
    float iDirection[3] = {0.0, 0.0, 0.0};

    int iOwner = 0;
    if(iEntity > MAXPLAYERS)
    {
        iOwner = GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity");
    }
    else
    {
        iOwner = iEntity;
    }

    GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", fOrigin);
    int iGrenadeRadiusFreezing = iRadius;
    EmitAmbientSound(SOUND_FROSTNADE_EXPLODE, fOrigin, iEntity, SNDLEVEL_NORMAL);
    TE_SetupBeamRingPoint(fOrigin, 10.0, float(iGrenadeRadiusFreezing), g_iBeamSprite, g_iHaloSprite, 0, 10, 0.3, 8.0, 0.0,  {20,63,255,255}, 10, 0);
    TE_SendToAll();
    for (int iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
    {

        if (IsValidPlayer(iPlayer) && IsPlayerAlive(iPlayer) && iPlayer != iOwner && GetClientTeam(iPlayer) != GetClientTeam(iOwner) )
        {

            GetClientAbsOrigin(iPlayer, pVictimOrigin);
            pVictimOrigin[2] += 2.0;

            if (GetVectorDistance(fOrigin, pVictimOrigin) <= iGrenadeRadiusFreezing)
            {
                Handle trTrace = TR_TraceRayFilterEx(fOrigin, pVictimOrigin, MASK_SOLID, RayType_EndPoint, IsPlayerTarget, iPlayer);

                if ((TR_DidHit(trTrace) && TR_GetEntityIndex(trTrace) == iPlayer) || (GetVectorDistance(fOrigin, pVictimOrigin) <= 100.0))
                {

                    if(Freeze(iPlayer, fTime))
                    {
                        PrintToChat(iPlayer, "%s Zostałeś zamrożony przez %N!", PREFIX_SKILL, iOwner);
                        PrintToChat(iOwner, "%s Zamroziłeś %N!", PREFIX_SKILL, iPlayer);
                    }



                    CloseHandle(trTrace);
                }
                else
                {

                    CloseHandle(trTrace);
                    GetClientEyePosition(iPlayer, pVictimOrigin);
                    pVictimOrigin[2] -= 2.0;
                    trTrace = TR_TraceRayFilterEx(fOrigin, pVictimOrigin, MASK_SOLID, RayType_EndPoint, IsPlayerTarget, iPlayer);

                    if ((TR_DidHit(trTrace) && TR_GetEntityIndex(trTrace) == iPlayer) || (GetVectorDistance(fOrigin, pVictimOrigin) <= 100.0))
                    {
                        if(Freeze(iPlayer, fTime))
                        {
                            PrintToChat(iPlayer, "%s Zostałeś zamrożony przez %N!", PREFIX_SKILL, iOwner);
                            PrintToChat(iOwner, "%s Zamroziłeś %N!", PREFIX_SKILL, iPlayer);
                        }
                    }

                    CloseHandle(trTrace);
                }
            }
        }
    }


    TE_SetupSparks(fOrigin, iDirection, 5000, 1000);
    TE_SendToAll();

    return true;

}




public bool IsPlayerTarget(int sEntity, int iContentsMask, any iVictim)
{
	return (iVictim == sEntity);
}

stock void ShowSpecMessage(iClient, const String:szMessage[])
{
    HudMsg(iClient, 1, Float:{0.8, -1.0}, {255, 0, 0, 255}, {0, 255, 0, 255}, 0, 0.1, 0.1, SPEC_MESSAGE_DELAY + 0.1, 0.0, szMessage);
}

HudMsg(iClient, iChannel, const Float:fPosition[2], const iColor1[4], const iColor2[4], iEffect, Float:fFadeInTime, Float:fFadeOutTime, Float:fHoldTime, Float:fEffectTime, const String:szText[], any:...)
{
    if(GetUserMessageType() != UM_Protobuf)
        return false;

    decl String:szBuffer[256];
    VFormat(szBuffer, sizeof(szBuffer), szText, 12);

    decl iClients[1];
    iClients[0] = iClient;

    new Handle:hMessage = StartMessageEx(g_msgHudMsg, iClients, 1);
    PbSetInt(hMessage, "channel", iChannel);
    PbSetVector2D(hMessage, "pos", fPosition);
    PbSetColor(hMessage, "clr1", iColor1);
    PbSetColor(hMessage, "clr2", iColor2);
    PbSetInt(hMessage, "effect", iEffect);
    PbSetFloat(hMessage, "fade_in_time", fFadeInTime);
    PbSetFloat(hMessage, "fade_out_time", fFadeOutTime);
    PbSetFloat(hMessage, "hold_time", fHoldTime);
    PbSetFloat(hMessage, "fx_time", fEffectTime);
    PbSetString(hMessage, "text", szBuffer);
    EndMessage();

    return true;
}

int GetAmmoDef_Index(const char[] type)
{
    static Handle call = null;
    if (call == null) {
        StartPrepSDKCall(SDKCall_Raw);
        PrepSDKCall_SetFromConf(g_hGameConf, SDKConf_Signature, "GetAmmoDef_Index");
        PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
        PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
        call = EndPrepSDKCall();
        if (!call)
            SetFailState("Can't load function call.");
    }
    return SDKCall(call, GetAmmoDef(), type);
}

any GetAmmoDef()
{
    static Handle call = null;
    if (call == null) {
        StartPrepSDKCall(SDKCall_Static);
        PrepSDKCall_SetFromConf(g_hGameConf, SDKConf_Signature, "GetAmmoDef");
        PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
        // No args
        call = EndPrepSDKCall();
        if (!call)
            SetFailState("Can't load function call.");
    }
    return SDKCall(call);
}
