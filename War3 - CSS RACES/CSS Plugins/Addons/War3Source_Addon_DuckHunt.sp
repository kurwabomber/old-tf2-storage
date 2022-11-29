/**
* File: War3Source_Addon_DuckHunt.sp
* Description: Enables or Disables DuckHunt mode for war3 CSS
* Author(s): Remy Lebeau
* Current functions:     Changes all T players to druid race (requires the race to be installed)
*                        Restricts all CT players to shotgun, and spawns them with one
*                        Gives all T players a sock upon spawn
*/

#pragma semicolon 1
#include <sourcemod>
#include <sdkhooks>
#include "W3SIncs/War3Source_Interface"
#include <smlib>


public Plugin:myinfo = 
{
    name = "War3Source Addon - DuckHunt",
    author = "Remy Lebeau",
    description = "Toggles Duck Hunt Game Mode",
    version = "0.0.1",
    url = "sevensinsgaming.com"
};




new bool:g_bDuckhuntEnabled = false;
new Handle:g_hRestartGame = INVALID_HANDLE;

public OnPluginStart()
{
    HookEvent("round_start",RoundStartEvent);
    RegAdminCmd("sm_duckhunt_toggle",Command_Duckhunt, ADMFLAG_SLAY,"Toggles Duck Hunt Mode");
    g_hRestartGame  = FindConVar("mp_restartgame");

}



public OnMapStart()
{
    g_bDuckhuntEnabled = false;
    new String:temp[150];
    GetCurrentMap(temp, sizeof(temp));
    if( StrEqual( temp, "cs_duckhunt_v3",false ))
    {
        g_bDuckhuntEnabled = true;
        Client_PrintToChatAll(false, "{G}.: DUCKHUNT MODE IS ON :.");
    }
    
}

public OnMapEnd()
{
    g_bDuckhuntEnabled = false;
}

public OnWar3EventSpawn( client )
{
    if(g_bDuckhuntEnabled && ValidPlayer(client,true))
    {
        if (GetClientTeam(client) == TEAM_T)
        {
            new duckID = War3_GetRaceIDByShortname("druidt");
            new sockID = War3_GetItemIdByShortname("sock");

            
            W3SetPlayerProp(client,RaceChosenTime,GetGameTime());
            W3SetPlayerProp(client,RaceSetByAdmin,true);
            
            War3_SetRace(client,duckID);
            
            
            W3SetVar(TheItemBoughtOrLost,sockID);
            W3CreateEvent(DoForwardClientBoughtItem,client);
            
        }
        else
        {
            new raceID = War3_GetRaceIDByShortname("crazyeight");

            
            W3SetPlayerProp(client,RaceChosenTime,GetGameTime());
            W3SetPlayerProp(client,RaceSetByAdmin,true);
            
            War3_SetRace(client,raceID);
        }
    }
}    

public Action:Command_Duckhunt(client, args) 
{
    if(g_bDuckhuntEnabled)
    {
        g_bDuckhuntEnabled = false;
        new raceID = War3_GetRaceIDByShortname("undead");
        Client_PrintToChatAll(false, "{R}.: DUCKHUNT MODE IS OFF :.");
        for(new i=1;i<=MaxClients;i++)
        {
            if(ValidPlayer(i))
            {
                War3_SetRace(i,raceID);
            }
        }
        ServerCommand( "sm_slay @all");
        
    }
    else
    {
        g_bDuckhuntEnabled = true;
        Client_PrintToChatAll(false, "{G}.: DUCKHUNT MODE IS ON :.");
        ServerCommand( "sm_slay @all");
        SetConVarInt(g_hRestartGame, 2);
        
    }
    return Plugin_Handled;
}


public RoundStartEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    if(g_bDuckhuntEnabled)
    {
        PrintCenterTextAll( ".: !DUCKHUNT! :.\n.: !DUCKHUNT! :.\n.: !DUCKHUNT! :.");        
    }
}



/***************************************************************************
*
*
*                HELPER FUNCTIONS / TIMERS
*
*
***************************************************************************/

