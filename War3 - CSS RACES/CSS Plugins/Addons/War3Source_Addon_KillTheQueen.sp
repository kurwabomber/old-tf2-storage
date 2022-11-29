#pragma semicolon 1

#include <cstrike>
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

new bool:killTheQueenEnabled;
new T_Queen;
new CT_Queen;
new bool:noRespawnEnabled;
new bool:hasDiedThisRound[MAXPLAYERS+1];
new bool:allowedToRespawn[MAXPLAYERS+1];

public Plugin:myinfo =
{
	name = "SSG Kill The Queen plugin",
	author = "Kibbles",
	description = "Each team is assigned a Queen. If the queen dies, their team is killed. !ktq_toggle to use.",
	version = "1.0",
	url = "http://sevensinsgaming.com"
};

public OnPluginStart()
{
    RegAdminCmd("sm_ktq_toggle", Command_ktq_toggle, ADMFLAG_SLAY, "Toggles Kill The Queen on/off.");
    RegAdminCmd("sm_ktq_t", Command_ktq_t, ADMFLAG_SLAY, "Sets a new random T queen.");
    RegAdminCmd("sm_ktq_ct", Command_ktq_ct, ADMFLAG_SLAY, "Sets a new random CT queen.");
    RegAdminCmd("sm_ktq_respawn", Command_ktq_respawn, ADMFLAG_SLAY, "Toggle Anti-Respawn on/off.");
    RegAdminCmd("sm_ktq_except", Command_ktq_except, ADMFLAG_SLAY, "Make player immune to Anti-Respawn.");
    RegAdminCmd("sm_ktq_help", Command_ktq_help, ADMFLAG_SLAY, "Display a help menu for Kill The Queen.");
    
    HookEvent("round_start",Round_Start);
    HookEvent("round_end",Round_End);
    
    noRespawnEnabled = false;
}


//
// Kill The Queen functions
//
public OnMapStart()
{
    killTheQueenEnabled = false;
    resetDeathTracker();
    
    for (new i=1; i<=MAXPLAYERS; i++)
    {
        allowedToRespawn[i] = false;
    }
}

public OnMapEnd()
{
    killTheQueenEnabled = false;
}

public OnRaceChanged(client, oldrace, newrace)
{
    if (killTheQueenEnabled)
    {
        new odditySniperID = War3_GetRaceIDByShortname("odsniper");
        new marineClassID = War3_GetRaceIDByShortname("marineclass");
        
        if (newrace == odditySniperID || newrace == marineClassID)
        {
            forceChangeRace(client, oldrace);
        }
    }
}

public OnClientDisconnect(client)
{
    if (killTheQueenEnabled)
    {
        if (client == T_Queen || client == CT_Queen)
        {
            printPluginMessageAll("One of the Queens has left. Starting a new round in 3 seconds.");
            CS_TerminateRound(3.0, CSRoundEnd_Draw);
        }
    }
}

public OnWar3EventSpawn(client)
{
    if (ValidPlayer(client, true) && killTheQueenEnabled && noRespawnEnabled)
    {
        //On a timer to avoid clashing with round_start.
        CreateTimer(0.5, slayClient, client);
    }
}

public Action:slayClient(Handle:timer,any:client)
{
    if (hasDiedThisRound[client] && !allowedToRespawn[client])
    {
        new damage = War3_GetMaxHP(client)*2;
        War3_DealDamage(client, damage, _, _, "Anti-Respawn");
        
        new String:output[256];
        Format(output, sizeof(output), "%N has been slayed. Do not respawn teammates!", client);
        
        printPluginMessageAll(output);
    }
}

public OnWar3EventDeath(victim, attacker, deathrace)
{
    if (ValidPlayer(victim) && killTheQueenEnabled)
    {
        if (victim == T_Queen)
        {
            slayTTeam();
        }
        else if (victim == CT_Queen)
        {
            slayCTTeam();
        }
        else
        {
            hasDiedThisRound[victim] = true;
        }
    }
}

public Round_Start(Handle:event,const String:name[],bool:dontBroadcast)
{
    if (killTheQueenEnabled)
    {
        if (noRespawnEnabled)
        {
            //This call to resetDeathTracker should catch anyone who dies between round_end and round_start.
            resetDeathTracker();
            printPluginMessageAll("Death Tracker is active. Anyone who respawns will be slayed.");
        }
        
        T_Queen = -1;
        CT_Queen = -1;
        
        setQueens();
    }
}

public Round_End(Handle:event,const String:name[],bool:dontBroadcast)
{
    resetDeathTracker();
}

public Action:Command_ktq_toggle(client, args)
{
    if (killTheQueenEnabled)
    {
        if (T_Queen > 0)
        {
            unbeaconTQueen();
            T_Queen = -1;
        }
        if (CT_Queen > 0)
        {
            unbeaconCTQueen();
            CT_Queen = -1;
        }
        resetDeathTracker();
        
        killTheQueenEnabled = false;
        printPluginMessageAll("Kill The Queen has been disabled.");
    }
    else
    {
        killTheQueenEnabled = true;
        
        new odditySniperID = War3_GetRaceIDByShortname("odsniper");
        new marineClassID = War3_GetRaceIDByShortname("marineclass");
        for (new i=1; i<=MAXPLAYERS; i++)
        {
            new clientRace = War3_GetRace(i);
            if (clientRace == odditySniperID || clientRace == marineClassID)
            {
                forceChangeRace(i);
            }
        }
        
        printPluginMessageAll("Kill The Queen has been enabled, and will begin next round.");
        printPluginMessage(client, "Type {green}!ktq_help {default}for a list of commands.");
    }
    
    return Plugin_Handled;
}

public Action:Command_ktq_t(client, args)
{
    if (killTheQueenEnabled)
    {
        if (T_Queen > 0)
        {
            unbeaconTQueen();
        }
        setTQueen();
        printPluginMessageAll("A new Terrorist Queen has been chosen.");
        beaconTQueen();
    }
    else
    {
        printPluginMessage(client, "Type {green}!ktq_toggle {default}to enable this command..");
    }
    
    return Plugin_Handled;
}

public Action:Command_ktq_ct(client, args)
{
    if (killTheQueenEnabled)
    {
        if (CT_Queen > 0)
        {
            unbeaconCTQueen();
        }
        setCTQueen();
        printPluginMessageAll("A new Counter-Terrorist Queen has been chosen.");
        beaconCTQueen();
    }
    else
    {
        printPluginMessage(client, "Type {green}!ktq_toggle {default}to enable this command.");
    }
    
    return Plugin_Handled;
}

public Action:Command_ktq_respawn(client, args)
{
    if (killTheQueenEnabled)
    {
        if (noRespawnEnabled)
        {
            noRespawnEnabled = false;
            resetDeathTracker();
            printPluginMessageAll("Death Tracker has been disabled. Team mates can be respawned.");
        }
        else
        {
            noRespawnEnabled = true;
            resetDeathTracker();
            printPluginMessageAll("Death Tracker has been enabled. Anyone who respawns will be slayed.");
        }
    }
    
    return Plugin_Handled;
}

public Action:Command_ktq_except(client, args)
{
    if (killTheQueenEnabled)
    {
        if (args < 1)
        {
            printPluginMessage(client, "Usage is: {green}!ktq_except <#userid|name>");
            return Plugin_Handled;
        }
        
        //Parsing code taken from slay.sp
        decl String:arg[65];
        GetCmdArg(1, arg, sizeof(arg));

        decl String:target_name[MAX_TARGET_LENGTH];
        decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
        
        if ((target_count = ProcessTargetString(
                arg,
                client,
                target_list,
                MAXPLAYERS,
                COMMAND_FILTER_ALIVE,
                target_name,
                sizeof(target_name),
                tn_is_ml)) <= 0)
        {
            new String:output[256];
            Format(output, sizeof(output), "No targets could be found for: %s", arg);
            printPluginMessage(client, output);
            return Plugin_Handled;
        }
        
        for (new i = 0; i < target_count; i++)
        {
            if (allowedToRespawn[target_list[i]])
            {
                allowedToRespawn[target_list[i]] = false;
                new String:output[256];
                Format(output, sizeof(output), "%N is not allowed to respawn any more.", target_list[i]);
                printPluginMessage(client, output);
            }
            else
            {
                allowedToRespawn[target_list[i]] = true;
                new String:output[256];
                Format(output, sizeof(output), "%N is now allowed to respawn.", target_list[i]);
                printPluginMessage(client, output);
            }
        }
    }
    else
    {
        printPluginMessage(client, "Type {green}!ktq_toggle {default}to enable this command.");
    }
    
    return Plugin_Handled;
}

public Action:Command_ktq_help(client, args)
{
    printPluginMessage(client, "{green}!ktq_toggle {default}turns Kill The Queen on/off.");
    printPluginMessage(client, "{green}!ktq_respawn {default}turns Anti-Respawn on/off.");
    printPluginMessage(client, "{green}!ktq_except <#userid|name> {default}allows a player to respawn.");
    printPluginMessage(client, "{green}!ktq_t {default}selects a new Terrorist Queen.");
    printPluginMessage(client, "{green}!ktq_ct {default}selects a new Counter-Terrorist Queen.");
    
    return Plugin_Handled;
}

public bool:setQueens()
{
    //This while look is unnecessary now, but just in case... :P
    new timeoutCount = 0;
    while ((T_Queen == -1 || CT_Queen == -1) && timeoutCount < MAXPLAYERS)
    {
        setTQueen();
        setCTQueen();
        
        timeoutCount++;
    }
    
    if (T_Queen == -1 || CT_Queen == -1)
    {
        printPluginMessageAll("Something went horribly wrong. Please type {green}!ktq_toggle {default}and contact the developer.");
        killTheQueenEnabled = false;
        return false;
    }
    
    beaconTQueen();
    beaconCTQueen();
    
    return true;
}

public setTQueen()
{
    new teamSizeT = 0;
    
    for (new i=1; i<=MAXPLAYERS; i++)
    {
        if (ValidPlayer(i, true) && GetClientTeam(i) == TEAM_T)
        {
            teamSizeT++;
        }
    }
    
    new randomTIndex = GetRandomInt(1, teamSizeT);
    
    new T_Count = 1;
    new bool:queenNotChosen = true;
    for (new i=1; i<=MAXPLAYERS; i++)
    {
        if (ValidPlayer(i, true))
        {
            if (GetClientTeam(i) == TEAM_T)
            {
                if (T_Count == randomTIndex && queenNotChosen)
                {
                    T_Queen = i;
                    queenNotChosen = false;
                }
                else
                {
                    T_Count++;
                }
            }
        }
    }
}

public setCTQueen()
{
    new teamSizeCT = 0;
    
    for (new i=1; i<=MAXPLAYERS; i++)
    {
        if (ValidPlayer(i, true) && GetClientTeam(i) == TEAM_CT)
        {
            teamSizeCT++;
        }
    }
    
    new randomCTIndex = GetRandomInt(1, teamSizeCT);
    
    new CT_Count = 1;
    new bool:queenNotChosen = true;
    for (new i=1; i<=MAXPLAYERS; i++)
    {
        if (ValidPlayer(i, true))
        {
            if (GetClientTeam(i) == TEAM_CT)
            {
                if (CT_Count == randomCTIndex && queenNotChosen)
                {
                    CT_Queen = i;
                    queenNotChosen = false;
                }
                else
                {
                    CT_Count++;
                }
            }
        }
    }
}

public beaconTQueen()
{
    ServerCommand("sm_beacon #%d 1", GetClientUserId(T_Queen));
    
}

public unbeaconTQueen()
{
    ServerCommand("sm_beacon #%d 0", GetClientUserId(T_Queen));
}

public beaconCTQueen()
{
    ServerCommand("sm_beacon #%d 1", GetClientUserId(CT_Queen));
}

public unbeaconCTQueen()
{
    ServerCommand("sm_beacon #%d 0", GetClientUserId(CT_Queen));
}

public slayTTeam()
{
    ServerCommand("sm_slay @ts");
}

public slayCTTeam()
{
    ServerCommand("sm_slay @cts");
}


//
// Helper functions
//
static printPluginMessage(client, String:message[])
{
    new String:pluginString[512] = "{green}[KTQ Plugin] {default}";
    StrCat(pluginString, sizeof(pluginString), message);
    CPrintToChat(client, pluginString);
}

static printPluginMessageAll(String:message[])
{
    new String:pluginString[512] = "{green}[KTQ Plugin] {default}";
    StrCat(pluginString, sizeof(pluginString), message);
    CPrintToChatAll(pluginString);
}

static resetDeathTracker()
{
    for (new i=1; i<=MAXPLAYERS; i++)
    {
        hasDiedThisRound[i] = false;
    }
}

static forceChangeRace(client, newRaceID=-1)
{
    new oldRaceID = War3_GetRace(client);

    W3SetPlayerProp(client,RaceChosenTime,GetGameTime());
    W3SetPlayerProp(client,RaceSetByAdmin,true);
    
    if (newRaceID == -1)
    {
        newRaceID = War3_GetRaceIDByShortname("human");
    }
    War3_SetRace(client,newRaceID);
    
    new String:raceName[128];
    War3_GetRaceName(oldRaceID, raceName, sizeof(raceName));
    new String:output[256];
    Format(output, sizeof(output), "%s is not allowed while playing Kill The Queen.", raceName);
    printPluginMessage(client, output);
}