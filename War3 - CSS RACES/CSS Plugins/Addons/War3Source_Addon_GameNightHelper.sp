#pragma semicolon 1

////
//
// - CHECK AT START OF EACH ROUND TO SEE IF PEOPLE ARE ON WRONG SIDE, AND RE-ARRANGE AS NECESSARY?
// - Or just don't be anal about teamswapping. Don't police it, work out a good method later.
//
////

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

//Trie variables/data structures
enum UserRecord
{
    String:ClientNameFromJoin[32],
    String:AuthString[32],
    CurrentTeam,
    TotalScore,
    CT_Score,
    T_Score,
    CT_Wins,
    T_Wins,
    CT_Survivals,
    T_Survivals,
    bool:bDisqualified
}
const MAX_USERS = 200;
new RecordData[MAX_USERS][UserRecord];
new RecordCount = 0;
new Handle:UserRecordIndex = INVALID_HANDLE;

//Game management variables
new bool:bPluginIsEnabled = false;
new bool:bEnablePluginOnRoundStart = false;
new bool:bSwapTeamsOnRoundStart = false;

//teambalance.sp interaction
new Handle:g_CvarTeamBalanceEnabled;

//new String:disqualifyKickString[] = "You have been disqualified. Your stats have been recorded and you can appeal this at www.sevensinsgaming.com";

public Plugin:myinfo =
{
    name = "SSG Game Night Helper",
    author = "Kibbles",
    description = "Various functions to help administrate Game Nights.",
    version = "1.0",
    url = "http://sevensinsgaming.com"
};

public OnPluginStart()
{
    RegAdminCmd("sm_gn_enable", Command_Enable, ADMFLAG_BAN, "Enables the Game Night plugin.");
    RegAdminCmd("sm_gn_disable", Command_Disable, ADMFLAG_KICK, "Disables the Game Night plugin.");
    RegAdminCmd("sm_gn_swapteams", Command_SwapTeams, ADMFLAG_KICK, "Swaps the team of all CTs and Ts on round end.");
    RegAdminCmd("sm_gn_swapplayer", Command_SwapPlayer, ADMFLAG_KICK, "Swaps the team of an individual player.");
    RegAdminCmd("sm_gn_resetplayerscore", Command_ResetPlayerScore, ADMFLAG_KICK, "Resets score/deaths for a targeted player.");
    RegAdminCmd("sm_gn_resetteamscores", Command_ResetTeamScores, ADMFLAG_KICK, "Resets win count for both teams.");
    RegAdminCmd("sm_gn_disqualify", Command_DisqualifyPlayer, ADMFLAG_KICK, "Marks a player as disqualified");
    RegAdminCmd("sm_gn_undisqualify", Command_UndisqualifyPlayer, ADMFLAG_KICK, "Removes a player from the disqualified list");
    RegAdminCmd("sm_gn_showdata", Command_ShowData, ADMFLAG_KICK, "Print current data to console.");
    RegAdminCmd("sm_gn_savedata", Command_SaveData, ADMFLAG_KICK, "Save current data to file.");
    RegAdminCmd("sm_gn_help", Command_Help, ADMFLAG_KICK, "Print out a help message.");
    
    HookEvent("round_start",Round_Start);
    HookEvent("round_end",Round_End);
    HookEvent("player_team", Event_PlayerTeam);
    
    g_CvarTeamBalanceEnabled = FindConVar("sm_team_balance_enable");
}


public OnMapStart()
{
    if (bPluginIsEnabled)
    {
        disableTeamBalance();
        ResetDatabase();
        InitialiseConnectedPlayers();
    }
}


public OnMapEnd()
{
    if (bPluginIsEnabled)
    {
        writeDataToFile();
    }
    enableTeamBalance();
}


public OnClientPostAdminCheck(client)
{
    if (ValidPlayer(client) && bPluginIsEnabled)
    {
        if (FindRecord(client) == -1)
        {
            CreateRecord(client);
        }
        /*if (UserRecord_GetDisqualifyStatus(userid))
        {
            CreateTimer(1.0, DelayedKick, client);
        }*/
    }
}
/*public Action:DelayedKick(Handle:timer, any:client)
{
    if (ValidPlayer(client))
    {
        KickClient(client, disqualifyKickString);
    }
}*/


public Round_Start(Handle:event,const String:name[],bool:dontBroadcast)
{
    if (bEnablePluginOnRoundStart)
    {
        bPluginIsEnabled = true;
        bEnablePluginOnRoundStart = false;
        
        resetAllTeamScores();
        disableTeamBalance();
    }
    if (bPluginIsEnabled)
    {
        if (bSwapTeamsOnRoundStart)
        {
            bSwapTeamsOnRoundStart = false;
            swapAllPlayerTeams();
            resetAllTeamScores();
        }
        resetAllPlayerScores();
        
        ////DEBUG
        for (new i=1; i<MaxClients; i++)
        {
            if (ValidPlayer(i) && GetUserAdmin(i) != INVALID_ADMIN_ID)
            {
                printDataToClient(i);
            }
        }
        ////DEBUG
    }
}


public Round_End(Handle:event,const String:name[],bool:dontBroadcast)
{
    if (bPluginIsEnabled)
    {
        new winningTeam = GetEventInt(event, "winner");
        for (new i=1; i<MaxClients; i++)
        {
            if (ValidPlayer(i))
            {
                new userTeam = UserRecord_GetCurrentTeam(i);
                new currentTeam = GetClientTeam(i);
                if (winningTeam == userTeam && currentTeam == userTeam)
                {
                    switch (winningTeam)
                    {
                        case TEAM_CT:
                        {
                            UserRecord_AddCTWin(i);
                        }
                        case TEAM_T:
                        {
                            UserRecord_AddTWin(i);
                        }
                    }
                }
                
                new score = GetClientFrags(i);
                if (score > 0 && currentTeam == userTeam)
                {
                    UserRecord_AddTotalScore(i, score);
                    switch (userTeam)
                    {
                        case TEAM_CT:
                        {
                            UserRecord_AddCTScore(i, score);
                        }
                        case TEAM_T:
                        {
                            UserRecord_AddTScore(i, score);
                        }
                    }
                }
                SetClientFrags(i, 0);
                SetClientDeaths(i, 0);
                
                if (IsPlayerAlive(i) && currentTeam == userTeam)
                {
                    switch (userTeam)
                    {
                        case TEAM_CT:
                        {
                            UserRecord_AddCTSurvival(i);
                        }
                        case TEAM_T:
                        {
                            UserRecord_AddTSurvival(i);
                        }
                    }
                }
            }
        }
    }
}


public Action:Command_Enable(client, args)
{
    if (!bPluginIsEnabled && !bEnablePluginOnRoundStart)
    {
        //Enables plugin
        printPluginMessageAll("Plugin will be enabled next round.");
        
        //Setup Trie, etc
        ResetDatabase();
        InitialiseConnectedPlayers();
        
        //set up flag to enable on round start
        bEnablePluginOnRoundStart = true;
    }
    else
    {
        printPluginMessage(client, "Plugin is already enabled.");
    }
}


public Action:Command_Disable(client, args)
{
    if (bPluginIsEnabled)
    {
        //Disables plugin
        bPluginIsEnabled = false;
        enableTeamBalance();
        writeDataToFile();
        printPluginMessageAll("Plugin has been disabled.");
    }
    else if (!bPluginIsEnabled && bEnablePluginOnRoundStart)
    {
        bEnablePluginOnRoundStart = false;
        printPluginMessageAll("Plugin will no longer be enabled next round.");
    }
    else
    {
        printPluginMessage(client, "Plugin is already disabled.");
    }
}


public Action:Command_SwapPlayer(client, args)
{
    //Swaps an individual immediately.
    if (bPluginIsEnabled)
    {
        new target = findTargetFromArgs(client, args);
        
        new recordTeam = UserRecord_GetCurrentTeam(target);
        switch (recordTeam)
        {
            case TEAM_T:
            {
                UserRecord_SetCurrentTeam(target, TEAM_CT);
            }
            case TEAM_CT:
            {
                UserRecord_SetCurrentTeam(target, TEAM_T);
            }
        }
        
        new team = GetClientTeam(target);
        if (team == recordTeam && (team == TEAM_T || team == TEAM_CT))
        {
            SwapClientTeam(target);
            new String:output[256];
            Format(output, sizeof(output), "%N has been swapped.", target);
            printPluginMessage(client, output);
        }
        else
        {
            new String:output[256];
            Format(output, sizeof(output), "%N's expected team has been changed, but they did not need swapping (or they are a spectator).", target);
            printPluginMessage(client, output);
        }
    }
}


public Action:Command_SwapTeams(client, args)
{
    //Toggles flag to swap at the start of the round
    if (bPluginIsEnabled)
    {
        if (!bSwapTeamsOnRoundStart)
        {
            bSwapTeamsOnRoundStart = true;
            printPluginMessageAll("Teams will be swapped next round.");
        }
        else
        {
            bSwapTeamsOnRoundStart = false;
            printPluginMessageAll("Teams will no longer be swapped next round.");
        }
    }
}


public Action:Command_ResetPlayerScore(client, args)
{
    //Resets a player's score for the current round.
    if (bPluginIsEnabled)
    {
        new target = findTargetFromArgs(client, args);

        if (ValidPlayer(target))
        {
            SetClientFrags(target, 0);
            SetClientDeaths(target, 0);
            
            new String:output[256];
            Format(output, sizeof(output), "%N's score has been reset for this round.", target);
            printPluginMessageAll(output);
        }
    }
}


public Action:Command_ResetTeamScores(client, args)
{
    if (bPluginIsEnabled)
    {
        resetAllTeamScores();
    }
    return Plugin_Handled;
}


public Action:Command_DisqualifyPlayer(client, args)
{
    //Adds a player to the kick list.
    if (bPluginIsEnabled)
    {
        new target = findTargetFromArgs(client, args);
        if (ValidPlayer(target))
        {
            UserRecord_SetDisqualifyStatus(target, true);
            
            new String:output[256];
            Format(output, sizeof(output), "%N has been disqualified.", target);
            printPluginMessageAll(output);
            
            //KickClient(target, disqualifyKickString);
        }
        else
        {
            printPluginMessage(client, "Invalid Target.");
        }
    }
}


public Action:Command_UndisqualifyPlayer(client, args)
{
    //Removes a player from the kick list.
    if (bPluginIsEnabled)
    {
        new target = findTargetFromArgs(client, args);
        
        if (ValidPlayer(target))
        {
            UserRecord_SetDisqualifyStatus(target, false);
            
            new String:output[256];
            Format(output, sizeof(output), "%N is not disqualified any more.", target);
            printPluginMessageAll(output);
        }
        else
        {
            printPluginMessage(client, "Invalid Target.");
        }
    }
}


public Action:Command_ShowData(client, args)
{
    if (ValidPlayer(client))
    {
        printDataToClient(client);
    }
}


public Action:Command_SaveData(client, args)
{
    if (ValidPlayer(client))
    {
        printPluginMessage(client, "Attempting to save data.");
        writeDataToFile(client);
    }
}


public Action:Command_Help(client, args)
{
    printPluginMessage(client, "{green}sm_gn_enable");
    printPluginMessage(client, "{green}sm_gn_disable");
    printPluginMessage(client, "{green}sm_gn_swapteams");
    printPluginMessage(client, "{green}sm_gn_swapplayer");
    printPluginMessage(client, "{green}sm_gn_resetplayerscore");
    printPluginMessage(client, "{green}sm_gn_resetteamscores");
    printPluginMessage(client, "{green}sm_gn_disqualify");
    printPluginMessage(client, "{green}sm_gn_undisqualify");
    printPluginMessage(client, "{green}sm_gn_showdata");
    printPluginMessage(client, "{green}sm_gn_savedata");
    printPluginMessage(client, "{green}sm_gn_help");
}


public Action:Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
    if (bPluginIsEnabled)
    {
        new userid = GetEventInt(event, "userid");
        new client = GetClientOfUserId(userid);
        new team = GetEventInt(event, "team");
        
        new userCurrentTeam = UserRecord_GetCurrentTeam(client);
        if (userCurrentTeam == TEAM_SPECTATOR && (team == TEAM_CT || team == TEAM_T))
        {
            UserRecord_SetCurrentTeam(client, team);
            return Plugin_Handled;
        }
        else if (userCurrentTeam != team && (team == TEAM_CT || team == TEAM_T || team == TEAM_SPECTATOR))
        {
            //CreateTimer(0.1, SwitchPlayerTeam, client);
            if (team != UserRecord_GetCurrentTeam(client) && (team == TEAM_CT || team == TEAM_T))
            {
                ServerCommand("sm_tbswitchnow %c%N%c", 34, client, 34);
                printPluginMessage(client, "You may not change teams while this plugin is active.");
            }
            else if (team != UserRecord_GetCurrentTeam(client) && team == TEAM_SPECTATOR)
            {
                //ChangeClientTeam(client, userCurrentTeam);
                CreateTimer(0.1, SwitchPlayerToTeam, client);
                printPluginMessage(client, "You may not change back to spectator while this plugin is active.");
            }
            
            return Plugin_Handled;
        }
    }
    return Plugin_Continue;
}
public Action:SwitchPlayerToTeam(Handle:timer, any:client)
{
    if (ValidPlayer(client))
    {
        new userCurrentTeam = UserRecord_GetCurrentTeam(client);
        ChangeClientTeam(client, userCurrentTeam);
    }
}


//
// Team Swap functions
//
static swapAllPlayerTeams()
{
    //
    // This should also reset the team scores on the scoreboard
    //
    
    for (new i=0; i<MAX_USERS; i++)
    {
        new recordTeam = UserRecord_GetCurrentTeamByIndex(i);
        switch (recordTeam)
        {
            case TEAM_T:
            {
                UserRecord_SetCurrentTeamByIndex(i, TEAM_CT);
            }
            case TEAM_CT:
            {
                UserRecord_SetCurrentTeamByIndex(i, TEAM_T);
            }
        }
    }
    for (new j=1; j<=MaxClients; j++)
    {
        if (ValidPlayer(j))
        {
            new team = GetClientTeam(j);
            //CS_SwitchTeam(j, RecordData[FindRecord(GetjUserId(i))][CurrentTeam]);
            if (team != UserRecord_GetCurrentTeam(j) && (team == TEAM_T || team == TEAM_CT))
            {
                SwapClientTeam(j);
            }
        }
    }
}
static SwapClientTeam(client)
{
    ServerCommand("sm_tbswitchnow %c%N%c", 34, client, 34);
}


//
// Score helper functions
//
static resetAllPlayerScores()
{
    for (new i=1; i<=MaxClients; i++)
    {
        if (ValidPlayer(i))
        {
            SetClientFrags(i, 0);
            SetClientDeaths(i, 0);
        }
    }
}

static resetAllTeamScores()
{
    SetTeamScore(TEAM_T, 0);
    SetTeamScore(TEAM_CT, 0);
}

static SetClientFrags(ent, frags)
{
    SetEntProp(ent, Prop_Data, "m_iFrags", frags);
}

static SetClientDeaths(ent, deaths)
{
    SetEntProp(ent, Prop_Data, "m_iDeaths", deaths);
}


//
// DB/Trie functions
//
static CreateRecord(client)
{
    // Set Record data.
    if (FindRecord(client) == -1)
    {
        Format(RecordData[RecordCount][ClientNameFromJoin], 32, "%N", client);
        GetClientAuthString(client, RecordData[RecordCount][AuthString], 32);
        RecordData[RecordCount][CurrentTeam] = TEAM_SPECTATOR;
        RecordData[RecordCount][TotalScore] = 0;
        RecordData[RecordCount][CT_Score] = 0;
        RecordData[RecordCount][T_Score] = 0;
        RecordData[RecordCount][CT_Wins] = 0;
        RecordData[RecordCount][T_Wins] = 0;
        RecordData[RecordCount][CT_Survivals] = 0;
        RecordData[RecordCount][T_Survivals] = 0;
        RecordData[RecordCount][bDisqualified] = false;
        
        // Add name to index.
        SetTrieValue(UserRecordIndex, RecordData[RecordCount][AuthString], RecordCount);
        
        RecordCount++;
    }
}

static FindRecord(client)
{
    new RecordIndex = -1;
    
    // Lookup the Record name in the trie index. The value is inserted into the
    // RecordIndex variable.
    if (ValidPlayer(client))
    {
        new String:tmpAuth[32];
        GetClientAuthString(client, tmpAuth, 32);
        if (!GetTrieValue(UserRecordIndex, tmpAuth, RecordIndex))
        {
            // Not found.
            return -1;
        }
    }
    
    return RecordIndex;
}

static ResetRecords()
{
    RecordCount = 0;
    for (new i=0; i<MAX_USERS; i++)
    {
        strcopy(RecordData[i][AuthString], 32, "");
        RecordData[i][CurrentTeam] = TEAM_SPECTATOR;
        RecordData[i][TotalScore] = 0;
        RecordData[i][CT_Score] = 0;
        RecordData[i][T_Score] = 0;
        RecordData[i][CT_Wins] = 0;
        RecordData[i][T_Wins] = 0;
        RecordData[i][CT_Survivals] = 0;
        RecordData[i][T_Survivals] = 0;
        RecordData[i][bDisqualified] = false;
    }
}

static ResetTrie()
{
    if (UserRecordIndex != INVALID_HANDLE)
    {
        ClearTrie(UserRecordIndex);
    }
    else
    {
        UserRecordIndex = CreateTrie();
    }
}

static ResetDatabase()
{
    ResetRecords();
    ResetTrie();
}

static InitialiseConnectedPlayers()
{
    //Must be called directly after ResetDatabase, or might create double records.
    new team = TEAM_SPECTATOR;
    for (new i=1; i<MaxClients; i++)
    {
        if (ValidPlayer(i))
        {
            CreateRecord(i);
            
            team = GetClientTeam(i);
            if (team == TEAM_CT || team == TEAM_T)
            {
                UserRecord_SetCurrentTeam(i, team);
            }
        }
    }
}

static UserRecord_GetClientNameFromJoin(client, String:dest[], destLen)
{
    strcopy(dest, destLen, RecordData[FindRecord(client)][GetClientNameFromJoin]);
}

static UserRecord_GetAuthString(client, String:dest[], destLen)
{
    strcopy(dest, destLen, RecordData[FindRecord(client)][AuthString]);
}

static UserRecord_GetCurrentTeam(client)
{
    return RecordData[FindRecord(client)][CurrentTeam];
}

static UserRecord_SetCurrentTeam(client, team)
{
    RecordData[FindRecord(client)][CurrentTeam] = team;
}

static UserRecord_GetCurrentTeamByIndex(index)
{
    return RecordData[index][CurrentTeam];
}

static UserRecord_SetCurrentTeamByIndex(index, team)
{
    RecordData[index][CurrentTeam] = team;
}

static UserRecord_GetTotalScore(client)
{
    return RecordData[FindRecord(client)][TotalScore];
}

static UserRecord_AddTotalScore(client, score)
{
    RecordData[FindRecord(client)][TotalScore] += score;
}

static UserRecord_GetCTScore(client)
{
    return RecordData[FindRecord(client)][CT_Score];
}

static UserRecord_AddCTScore(client, score)
{
    RecordData[FindRecord(client)][CT_Score] += score;
}

static UserRecord_GetTScore(client)
{
    return RecordData[FindRecord(client)][T_Score];
}

static UserRecord_AddTScore(client, score)
{
    RecordData[FindRecord(client)][T_Score] += score;
}

static UserRecord_GetCTWins(client)
{
    return RecordData[FindRecord(client)][CT_Wins];
}

static UserRecord_AddCTWin(client)
{
    RecordData[FindRecord(client)][CT_Wins] += 1;
}

static UserRecord_GetTWins(client)
{
    return RecordData[FindRecord(client)][T_Wins];
}

static UserRecord_AddTWin(client)
{
    RecordData[FindRecord(client)][T_Wins] += 1;
}

static UserRecord_GetCTSurvivals(client)
{
    return RecordData[FindRecord(client)][CT_Survivals];
}

static UserRecord_AddCTSurvival(client)
{
    RecordData[FindRecord(client)][CT_Survivals] += 1;
}

static UserRecord_GetTSurvivals(client)
{
    return RecordData[FindRecord(client)][T_Survivals];
}

static UserRecord_AddTSurvival(client)
{
    RecordData[FindRecord(client)][T_Survivals] += 1;
}

static bool:UserRecord_GetDisqualifyStatus(client)
{
    return RecordData[FindRecord(client)][bDisqualified];
}

static UserRecord_SetDisqualifyStatus(client, bool:flag)
{
    RecordData[FindRecord(client)][bDisqualified] = flag;
}

//
// Data output functions
//
static printDataToClient(client)
{
    new String:mapName[128];
    GetCurrentMap(mapName, 128);
    new String:curTime[128];
    FormatTime(curTime, 128, "%Y-%m-%d %H%M", GetTime());
    
    PrintToConsole(client, "-----------START------------------------------------------------------------------------------------------------------------------------------------------------------------");
    PrintToConsole(client, "|%82s --- %83s|", curTime, mapName);
    PrintToConsole(client, "+--------------------------------+--------------------------------+------------+---------+--------+--------+-------+-------------+------------+--------------|-------------|");
    PrintToConsole(client, "|Profile Name                    |AuthString                      |Total Score |CT Score |T Score |CT Wins |T Wins |CT Survivals |T Survivals |Expected Team |Disqualified |");
    PrintToConsole(client, "+--------------------------------+--------------------------------+------------+---------+--------+--------+-------+-------------+------------+--------------|-------------|");
    for (new i=0; i<MAX_USERS; i++)
    {
        //Getter functions have been included, but direct access is used here for efficiency.
        new String:clientNameFromJoin[32];
        strcopy(clientNameFromJoin, 32, RecordData[i][ClientNameFromJoin]);
        
        new String:authString[32];
        strcopy(authString, 32, RecordData[i][AuthString]);
        if (strlen(authString) == 0)
        {
            continue;
        }
        
        new currentTeam = RecordData[i][CurrentTeam];
        new totalScore = RecordData[i][TotalScore];
        new ctScore = RecordData[i][CT_Score];
        new tScore = RecordData[i][T_Score];
        new ctWins = RecordData[i][CT_Wins];
        new tWins = RecordData[i][T_Wins];
        new ctSurvivals = RecordData[i][CT_Survivals];
        new tSurvivals = RecordData[i][T_Survivals];
        new bool:disqualifyStatus = RecordData[i][bDisqualified];
        
        new String:disqualifyString[5] = "";
        StrCat(disqualifyString, 5, (disqualifyStatus ? "True" : ""));
        
        new String:expectedTeam[5];
        switch (currentTeam)
        {
            case TEAM_CT:
            {
                strcopy(expectedTeam, 5, "CT");
            }
            case TEAM_T:
            {
                strcopy(expectedTeam, 5, "T");
            }
            case TEAM_SPECTATOR:
            {
                strcopy(expectedTeam, 5, "Spec");
            }
        }
        
        PrintToConsole(client, "|%32s|%32s|%12i|%9i|%8i|%8i|%7i|%13i|%12i|%14s|%13s|", clientNameFromJoin, authString, totalScore, ctScore, tScore, ctWins, tWins, ctSurvivals, tSurvivals, expectedTeam, disqualifyString);
    }
    PrintToConsole(client, "+--------------------------------+--------------------------------+------------+---------+--------+--------+-------+-------------+------------+--------------|-------------|");
    PrintToConsole(client, "------------END-------------------------------------------------------------------------------------------------------------------------------------------------------------");
}

//
// File management functions
//
static writeDataToFile(client=-1)
{
    new String:currentPath[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, currentPath, PLATFORM_MAX_PATH, "");
    
    new String:fileDirectory[15] = "GameNightLogs/";
    StrCat(currentPath, PLATFORM_MAX_PATH, fileDirectory);
    if (!DirExists(currentPath))
    {
        //CreateDirectory(currentPath, 511);//d511 = o777 = rwx
        CreateDirectory(currentPath, 455);//d455 = o707 = rx
    }
    
    new String:mapName[128];
    GetCurrentMap(mapName, 128);
    
    new String:curTime[128];
    FormatTime(curTime, 128, "%Y-%m-%d %H%M", GetTime());
    
    new String:fileName[262];
    StrCat(fileName, 262, curTime);
    StrCat(fileName, 262, "___");
    StrCat(fileName, 262, mapName);
    StrCat(fileName, 262, ".txt");
    
    StrCat(currentPath, PLATFORM_MAX_PATH, fileName);
    
    new Handle:hFile = OpenFile(currentPath, "w");
    
    WriteFileLine(hFile, "-----------START------------------------------------------------------------------------------------------------------------------------------------------------------------");
    WriteFileLine(hFile, "|%15s --- %150s|", curTime, mapName);
    WriteFileLine(hFile, "+--------------------------------+--------------------------------+------------+---------+--------+--------+-------+-------------+------------+--------------|-------------|");
    WriteFileLine(hFile, "|Profile Name On Join            |AuthString                      |Total Score |CT Score |T Score |CT Wins |T Wins |CT Survivals |T Survivals |Expected Team |Disqualified |");
    WriteFileLine(hFile, "+--------------------------------+--------------------------------+------------+---------+--------+--------+-------+-------------+------------+--------------|-------------|");
    for (new i=0; i<MAX_USERS; i++)
    {
        //Getter functions have been included, but direct access is used here for efficiency.
        new String:clientNameFromJoin[32];
        strcopy(clientNameFromJoin, 32, RecordData[i][ClientNameFromJoin]);
        
        new String:authString[32];
        strcopy(authString, 32, RecordData[i][AuthString]);
        if (strlen(authString) == 0)
        {
            continue;
        }
        
        new currentTeam = RecordData[i][CurrentTeam];
        new totalScore = RecordData[i][TotalScore];
        new ctScore = RecordData[i][CT_Score];
        new tScore = RecordData[i][T_Score];
        new ctWins = RecordData[i][CT_Wins];
        new tWins = RecordData[i][T_Wins];
        new ctSurvivals = RecordData[i][CT_Survivals];
        new tSurvivals = RecordData[i][T_Survivals];
        new bool:disqualifyStatus = RecordData[i][bDisqualified];
        
        new String:disqualifyString[5] = "";
        StrCat(disqualifyString, 5, (disqualifyStatus ? "True" : ""));
        
        new String:expectedTeam[5];
        switch (currentTeam)
        {
            case TEAM_CT:
            {
                strcopy(expectedTeam, 5, "CT");
            }
            case TEAM_T:
            {
                strcopy(expectedTeam, 5, "T");
            }
            case TEAM_SPECTATOR:
            {
                strcopy(expectedTeam, 5, "Spec");
            }
        }
        
        WriteFileLine(hFile, "|%32s|%32s|%12i|%9i|%8i|%8i|%7i|%13i|%12i|%14s|%13s|", clientNameFromJoin, authString, totalScore, ctScore, tScore, ctWins, tWins, ctSurvivals, tSurvivals, expectedTeam, disqualifyString);
    }
    WriteFileLine(hFile, "+--------------------------------+--------------------------------+------------+---------+--------+--------+-------+-------------+------------+--------------|-------------|");
    WriteFileLine(hFile, "------------END-------------------------------------------------------------------------------------------------------------------------------------------------------------");

    FlushFile(hFile);
    CloseHandle(hFile);
    
    if (ValidPlayer(client))
    {
        printPluginMessage(client, "Data saved.");
    }
}

//
// teambalance.sp interaction functions
//
static enableTeamBalance()
{
    SetConVarBool(g_CvarTeamBalanceEnabled, true);
}

static disableTeamBalance()
{
    SetConVarBool(g_CvarTeamBalanceEnabled, false);
}

//
// General helper functions
//
static printPluginMessage(client, String:message[])
{
    new String:pluginString[512] = "{green}[Game Night] {default}";
    StrCat(pluginString, sizeof(pluginString), message);
    CPrintToChat(client, pluginString);
}

static printPluginMessageAll(String:message[])
{
    new String:pluginString[512] = "{green}[Game Night] {default}";
    StrCat(pluginString, sizeof(pluginString), message);
    CPrintToChatAll(pluginString);
}

static findTargetFromArgs(client, args)
{
    if (args < 1)
    {
        printPluginMessage(client, "Incorrect usage.");
        return -1;
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
        return -1;
    }
    if (target_count > 1) {
        new String:output[256];
        Format(output, sizeof(output), "More than one target found for: %s, please narrow your search.", arg);
        printPluginMessage(client, output);
        return -1;
    }
    
    return target_list[0];
}