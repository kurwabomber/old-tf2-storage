/**
* File: War3Source_Addon_PrivateAccess.sp
* Description: Controls the access to private races
* Author(s): Necavi, Remy Lebeau
* Current functions:     Allows / Disallows access by specific people to private races
*                        Creates a brief effect over private races when they spawn
*                         Requires - config/war3souce_privateraces.cfg
*/

#pragma semicolon 1
#include <sourcemod>
#include <sdkhooks>
#include "W3SIncs/War3Source_Interface"


public Plugin:myinfo = 
{
    name = "War3Source Addon - Private Access",
    author = "Necavi and Remy Lebeau",
    description = "Controls access to private races",
    version = "3.0.2",
    url = "http://war3source.com"
};


new HaloSprite, BeamSprite;

new bool:g_bIsOnPrivateRace[MAXPLAYERS];
new Handle:g_hPrivateRaces = INVALID_HANDLE;
new Handle:g_hRaceAccessLists = INVALID_HANDLE;
//new String:g_sServerUrl[256] = "http://war3source.com";
new g_iRequiredPlayers = 1;

public OnPluginStart()
{
    HookEvent("round_start",RoundStartEvent);
    RegAdminCmd("war3_reload_private_races",Command_Reload, ADMFLAG_RCON,"Reloads the private race access file");
    RegAdminCmd("war3_add_player_to_race", Command_AddPlayer, ADMFLAG_RCON, "Adds a player to a restricted race.");
    RegAdminCmd("war3_remove_player_from_race", Command_RemovePlayer, ADMFLAG_RCON, "Removes a player from a restricted race.");
    new Handle:cvarReqPlayers = CreateConVar("war3_private_race_min_players","1", "The minimum number of players required to use private races",0, true, 0.0, true, float(MaxClients));
    HookConVarChange(cvarReqPlayers, ConVar_ReqPlayers);
    //new Handle:cvarClanUrl = FindConVar("war3_clanurl");
    //GetConVarString(cvarClanUrl, g_sServerUrl, sizeof(g_sServerUrl));
    //HookConVarChange(cvarClanUrl, ConVar_ClanUrl);
    ReloadConfig();    

}

public OnMapStart()
{
    
    HaloSprite=War3_PrecacheHaloSprite();
    BeamSprite=War3_PrecacheBeamSprite();
    
}
public ConVar_ReqPlayers(Handle:convar, const String:oldValue[], const String:newValue[]) {
    g_iRequiredPlayers = StringToInt(newValue);
}
/*public ConVar_ClanUrl(Handle:convar, const String:oldValue[], const String:newValue[]) {
    strcopy(g_sServerUrl, sizeof(g_sServerUrl), newValue);
}*/
public Action:Command_RemovePlayer(client, args) {
    if(args != 2) {
        ReplyToCommand(client, "Insufficient parameters: sm_remove_player_from_race <race short name> <player steam ID>");
    } else {
        new String:file[PLATFORM_MAX_PATH];
        BuildPath(Path_SM, file, sizeof(file), "configs/war3source_privateraces.cfg");
        
        if (FileExists(file))
        {
            new Handle:accesslist = CreateKeyValues("Private Races");
            FileToKeyValues(accesslist, file);
            new String:sRaceShortName[16];
            new String:sSteamID[32];
            GetCmdArg(1, sRaceShortName, sizeof(sRaceShortName));
            GetCmdArg(2, sSteamID, sizeof(sSteamID));
            KvJumpToKey(accesslist, sRaceShortName);
            KvDeleteKey(accesslist, sSteamID);
            if(!KvGotoFirstSubKey(accesslist, false)) {
                KvDeleteThis(accesslist);
            }
            KvRewind(accesslist);
            KeyValuesToFile(accesslist, file);
            ParseKeyValues(accesslist);
            CloseHandle(accesslist);
            
            ReplyToCommand(client, "Successfully removed %s from %s's private access list!", sSteamID, sRaceShortName);
        }
    }
}
public Action:Command_AddPlayer(client, args) {
    if(args != 3) {
        ReplyToCommand(client, "Insufficient parameters: sm_add_player_to_race <race short name> <player steam ID> <player name>");
    } else {
        new String:file[PLATFORM_MAX_PATH];
        BuildPath(Path_SM, file, sizeof(file), "configs/war3source_privateraces.cfg");
        
        if (FileExists(file))
        {
            new Handle:accesslist = CreateKeyValues("Private Races");
            FileToKeyValues(accesslist, file);
            new String:sRaceShortName[16];
            new String:sSteamID[32];
            new String:sPlayerName[32];
            GetCmdArg(1, sRaceShortName, sizeof(sRaceShortName));
            GetCmdArg(2, sSteamID, sizeof(sSteamID));
            GetCmdArg(3, sPlayerName, sizeof(sPlayerName));
            KvJumpToKey(accesslist, sRaceShortName, true);
            KvSetString(accesslist, sSteamID, sPlayerName);
            KvRewind(accesslist);
            KeyValuesToFile(accesslist, file);
            ParseKeyValues(accesslist);
            CloseHandle(accesslist);
            
            ReplyToCommand(client, "Successfully added %s to %s's private access list!", sPlayerName, sRaceShortName);
        }
        
    }
}
public Action:Command_Reload(client, args) 
{
    if(!ReloadConfig()) {
        ReplyToCommand(client, "Unable to reload config! Please check the formatting.");
    } else {
        ReplyToCommand(client, "Private race list reloaded successfully!");
    }
    return Plugin_Handled;
}
public OnClientConnected(client) {
    g_bIsOnPrivateRace[client] = false;
}
bool:ReloadConfig() 
{
    new String:file[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, file, sizeof(file), "configs/war3source_privateraces.cfg");
    
    if (FileExists(file))
    {
        new Handle:accesslist = CreateKeyValues("Private Races");
        FileToKeyValues(accesslist, file);
        ParseKeyValues(accesslist);
        CloseHandle(accesslist);
    } else {
        return false;
    }
    return true;
}
ParseKeyValues(Handle:accesslist) {

    if(g_hPrivateRaces == INVALID_HANDLE) {
        g_hPrivateRaces = CreateArray(4);
    } else {
        ClearArray(g_hPrivateRaces);
    }
    
    if(g_hRaceAccessLists == INVALID_HANDLE) {
        g_hRaceAccessLists = CreateArray(4);
    } else {
        for(new i = 0; i < GetArraySize(g_hRaceAccessLists); i++) {
            CloseHandle(GetArrayCell(g_hRaceAccessLists, i));
        }
        ClearArray(g_hRaceAccessLists);
    }
    KvRewind(accesslist);
    KvGotoFirstSubKey(accesslist);
        
    new String:sRaceShortName[16];
    new String:sSteamID[32];
    new index;
    do 
    {
        KvGetSectionName(accesslist, sRaceShortName, sizeof(sRaceShortName));
        PushArrayCell(g_hPrivateRaces, War3_GetRaceIDByShortname(sRaceShortName));
        index = PushArrayCell(g_hRaceAccessLists, CreateArray(32));
        if(KvGotoFirstSubKey(accesslist, false)) {
            do
            {
                KvGetSectionName(accesslist, sSteamID, sizeof(sSteamID));
                PushArrayString(GetArrayCell(g_hRaceAccessLists, index), sSteamID);
            } while(KvGotoNextKey(accesslist, false));
        }
        KvGoBack(accesslist);
    } while (KvGotoNextKey(accesslist));    
}
/***************************************************************************
*
*
*                EVENT CONTROL FUNCTIONS
*
*
***************************************************************************/


public OnW3Denyable(W3DENY:event, client)
{
    if(event==DN_CanSelectRace)
    {
        if (GetArraySize(g_hPrivateRaces) == 0 )
        {
            return;
        }    
        g_bIsOnPrivateRace[client] = false;
        if(g_iRequiredPlayers < (GetTeamClientCount(2) + GetTeamClientCount(3))) 
        {
            new index = FindValueInArray(g_hPrivateRaces,W3GetVar(EventArg1));
            if(index != -1) {
                new String:auth[32];
                GetClientAuthString(client, auth, sizeof(auth));
                if(FindStringInArray(GetArrayCell(g_hRaceAccessLists, index), auth) != -1) {
                    //CPrintToChat( client, "{green}Access: - GRANTED - {default}Welcome back." );    
                    g_bIsOnPrivateRace[client] = true;
                } else {
                    CPrintToChat( client, "{red}Access: - DENIED - {default}Get your own private race at http://sevensinsgaming.com" );    
                    W3Deny();
                }
            }
        } 
    }
}


public RoundStartEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    for(new i=1;i<=MaxClients;i++)
    {
        if(ValidPlayer(i,true)&& (g_bIsOnPrivateRace[i] == true))
        {
            War3_HighlightPrivate(i);    
        }
    }
}




/***************************************************************************
*
*
*                HELPER FUNCTIONS / TIMERS
*
*
***************************************************************************/





/***************************************************************************
*
*
*                BEAM HIGHLIGHT FOR CUSTOM/PRIVATE RACES
*
*
***************************************************************************/


stock War3_HighlightPrivate(client)
{
    CreateTimer(0.1, TopBeam, client);
    CreateTimer(0.3, MidBeam, client);
    CreateTimer(0.6, BottomBeam, client);
    CreateTimer(0.9, TopBeam, client);
    CreateTimer(1.2, MidBeam, client);
    CreateTimer(1.5, BottomBeam, client);
    CreateTimer(1.8, TopBeam, client);
    CreateTimer(2.1, MidBeam, client);
    CreateTimer(2.4, BottomBeam, client);
}

public Action:BottomBeam( Handle:timer, any:client )
{
    new Float:effect_vec[3];
    GetClientAbsOrigin(client,effect_vec);
    effect_vec[2] +=15.0;
    TE_SetupBeamRingPoint(effect_vec,45.0,44.0,BeamSprite,HaloSprite,0,15,0.3,5.0,0.0,{3,255,242,255},10,0);
    TE_SendToAll();
}

public Action:MidBeam( Handle:timer, any:client )
{
    new Float:effect_vec[3];
    GetClientAbsOrigin(client,effect_vec);
    effect_vec[2] +=30.0;
    TE_SetupBeamRingPoint(effect_vec,45.0,44.0,BeamSprite,HaloSprite,0,15,0.3,5.0,0.0,{3,255,242,255},10,0);
    TE_SendToAll();
}


public Action:TopBeam( Handle:timer, any:client )
{    
    new Float:effect_vec[3];
    GetClientAbsOrigin(client,effect_vec);
    effect_vec[2] += 45.0;
    TE_SetupBeamRingPoint(effect_vec,45.0,44.0,BeamSprite,HaloSprite,0,15,0.3,5.0,0.0,{3,255,242,255},10,0);
    TE_SendToAll();
}




