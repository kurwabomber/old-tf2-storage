#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

#define VALID_RACE_LIST_LENGTH 4

new bool:bPluginIsEnabled;
new bool:bEnablePluginOnRoundStart;
new validRaceList[VALID_RACE_LIST_LENGTH];
new validRaceListLen = VALID_RACE_LIST_LENGTH;

public Plugin:myinfo =
{
    name = "SSG War3Source Old School Game Mode",
    author = "Kibbles",
    description = "Forces everyone to use Human Alliance, Undead Scourge, Night Elf or Orcish Horde",
    version = "1.0",
    url = "http://sevensinsgaming.com"
};

public OnPluginStart()
{
    RegAdminCmd("sm_oldschool_toggle", Command_Oldschool_Toggle, ADMFLAG_KICK, "Toggles the Oldschool plugin on/off.");
    
    HookEvent("round_start", Round_Start, EventHookMode_Pre);
    
    bPluginIsEnabled = false;
    bEnablePluginOnRoundStart = false;
}

public OnMapStart()
{
    bPluginIsEnabled = false;
}

public OnMapEnd()
{
    bEnablePluginOnRoundStart = false;
}

public OnWar3EventSpawn(client)
{
    if (bPluginIsEnabled && ValidPlayer(client, true))
    {
        RaceCheck(client);
    }
}

public OnRaceChanged(client, oldrace, newrace)
{
    if (bPluginIsEnabled && ValidPlayer(client) && newrace != oldrace)
    {
        RaceCheck(client);
    }
}

public Round_Start(Handle:event,const String:name[],bool:dontBroadcast)
{
    if (bEnablePluginOnRoundStart)
    {
        bPluginIsEnabled = true;
        bEnablePluginOnRoundStart = false;
        printPluginMessageAll("Plugin has been enabled.");
    }
    if (bPluginIsEnabled)
    {
        for (new i=1; i<=MaxClients; i++)
        {
            if (ValidPlayer(i, true))
            {
                RaceCheck(i);
            }
        }
    }
}

public Action:Command_Oldschool_Toggle(client, args)
{
    if (bPluginIsEnabled)
    {
        bPluginIsEnabled = false;
        printPluginMessageAll("Plugin has been disabled.");
    }
    else if (!bPluginIsEnabled && bEnablePluginOnRoundStart)
    {
        bEnablePluginOnRoundStart = false;
        printPluginMessageAll("Plugin will no longer be enabled next round.");
    }
    else
    {
        SetValidRaceList();
        bEnablePluginOnRoundStart = true;
        printPluginMessageAll("Plugin will be enabled next round.");
    }
    return Plugin_Handled;
}
static SetValidRaceList()
{
    validRaceList[0] = War3_GetRaceIDByShortname("undead");
    validRaceList[1] = War3_GetRaceIDByShortname("human");
    validRaceList[2] = War3_GetRaceIDByShortname("orc");
    validRaceList[3] = War3_GetRaceIDByShortname("nightelf");
}


//
// Race functions
//
static RaceCheck(client)
{
    switch (IsRaceValid(War3_GetRace(client)))
        {
            case true:
            {
                //
            }
            case false:
            {
                forceChangeRace(client, chooseRandomValidRace());
                printPluginMessage(client, "You can only use the first four races. Randomizing choice.");
            }
        }
}

static bool:IsRaceValid(race)
{
    new bool:isRaceValid = false;
    for (new i=0; i<validRaceListLen; i++)
    {
        if (race == validRaceList[i]) isRaceValid = true;
    }
    return isRaceValid;
}

static chooseRandomValidRace()
{
    return validRaceList[GetRandomInt(0,(validRaceListLen-1))];
}

static forceChangeRace(client, newRaceID)
{
    W3SetPlayerProp(client,RaceChosenTime,GetGameTime());
    W3SetPlayerProp(client,RaceSetByAdmin,true);
    War3_SetRace(client, newRaceID);
}

//
// Helper functions
//
static printPluginMessage(client, String:message[])
{
    new String:pluginString[512] = "{green}[Old School] {default}";
    StrCat(pluginString, sizeof(pluginString), message);
    CPrintToChat(client, pluginString);
}

static printPluginMessageAll(String:message[])
{
    new String:pluginString[512] = "{green}[Old School] {default}";
    StrCat(pluginString, sizeof(pluginString), message);
    CPrintToChatAll(pluginString);
}