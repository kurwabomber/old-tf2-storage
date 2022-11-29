/**
* File: War3Source_Addon_Rambo.sp
* Description: Enables or Disables Rambo mode for war3 CSS
* Author(s): Remy Lebeau
* Current functions:     
*/

#pragma semicolon 1
#include <sourcemod>
#include <sdkhooks>
#include "W3SIncs/War3Source_Interface"
#include "W3SIncs/RemyFunctions"
#include <smlib>


public Plugin:myinfo = 
{
    name = "War3Source Addon - Rambo",
    author = "Remy Lebeau",
    description = "Toggles Rambo Game Mode",
    version = "2.0",
    url = "sevensinsgaming.com"
};


#define RAMBO_DAMAGE 0
#define RAMBO_INDEX 1
new RamboDamage[MAXPLAYERS][MAXPLAYERS];

new bool:g_bRamboEnabled = false;
new g_iCurrentRambo = -1;
new Handle:g_hAutoTeamBalance = INVALID_HANDLE;
new Handle:g_hRestartGame = INVALID_HANDLE;
new MoneyOffsetCS;


public APLRes:AskPluginLoad2Custom(Handle:myself, bool:late, String:error[], err_max)
{
   CreateNative("My_CheckRamboToggle", Native_My_CheckRamboToggle);
   CreateNative("My_RamboDamage", Native_My_RamboDamage);
   CreateNative("My_GetRamboID", Native_My_GetRamboID);
   return APLRes_Success;
}

public OnPluginStart()
{
    HookEvent("round_start",RoundStartEvent);
    HookEvent("round_end",RoundOverEvent);
    
    HookEvent("player_spawn", Event_PlayerSpawn); 
    
    RegAdminCmd("sm_rambo_toggle",Command_Rambo, ADMFLAG_SLAY,"Toggles Rambo Mode");
    RegAdminCmd("sm_rambo_set",Command_RamboSet, ADMFLAG_SLAY,"Sets the current rambo player");

    g_hAutoTeamBalance = FindConVar("mp_autoteambalance");
    g_hRestartGame  = FindConVar("mp_restartgame");
    
    MoneyOffsetCS=FindSendPropInfo("CCSPlayer","m_iAccount");
}

public OnMapStart()
{
    g_bRamboEnabled = false;
}

public OnMapEnd()
{
    g_bRamboEnabled = false;
}

public OnWar3EventSpawn( client )
{
    if(g_bRamboEnabled)
    {
        if(ValidPlayer(client))
        {   
            if(client != g_iCurrentRambo)
            {
                SetMoney(client, 16000);
                if(TEAM_T==GetClientTeam(client))
                {
                    ChangeClientTeam(client, TEAM_CT);
                }
            }
            else
            {
                if(TEAM_CT==GetClientTeam(client))
                {
                    ChangeClientTeam(client, TEAM_T);
                }
                
                new ramboID = War3_GetRaceIDByShortname("rambo");
                
                W3SetPlayerProp(client,RaceChosenTime,GetGameTime());
                W3SetPlayerProp(client,RaceSetByAdmin,true);
                
                War3_SetRace(client,ramboID);
                
            } 
        }
    }
}    

public Action:Command_Rambo(client, args) 
{
    if(g_iCurrentRambo == -1)
    {
        PrintToConsole(client,"[War3Source] Set a player to be rambo first - use sm_rambo_set");
    }
    else
    {
        if(g_bRamboEnabled)
        {
            g_bRamboEnabled = false;  
            HUD_Override(false);          
            Client_PrintToChatAll(false, "{R}.: RAMBO MODE IS OFF :.");
            SetConVarInt(g_hAutoTeamBalance, true);
            ServerCommand( "sm_slay @all");
            
        }
        else
        {
            g_bRamboEnabled = true;
            HUD_Override(true);
            Client_PrintToChatAll(false, "{G}.: RAMBO MODE IS ON :.");
            SetConVarInt(g_hAutoTeamBalance, false);
            ServerCommand( "sm_slay @all");
            for(new x=1;x<=MaxClients;x++)
            {
                if(ValidPlayer(x))
                {
                    if(x != g_iCurrentRambo)
                    {
                         CS_SwitchTeam(x, TEAM_CT);
                    }
                    else
                    {
                        CS_SwitchTeam(x, TEAM_T);
                    }
                }
            }
            
            
            SetConVarInt(g_hRestartGame, 2);
            
        }
    }
    return Plugin_Handled;
}



public Action:Command_RamboSet(client,args)
{
    if(args!=1)
        PrintToConsole(client,"[War3Source] The syntax of the command is: sm_rambo_set <player>");
    else
    {
        decl String:match[64];
        GetCmdArg(1,match,sizeof(match));
        
        new results=0;
        
        for(new x=1;x<=MaxClients;x++)
        {
            if(ValidPlayer(x))
            {    
                new String:name[64];
                GetClientName(x,name,sizeof(name));
                
                if(StrContains(name,match,false)!=-1)
                {
                    g_iCurrentRambo = x;
//                    PrintToChatAll("[War3Source] Match - |%s|,  g_iCurrentRambo = |%d|, x = |%d|",name, g_iCurrentRambo, x);
                    results++;
                    break;
                }
            }
        }
        if(results==0)
        {
            PrintToConsole(client,"%T","[War3Source] No players matched your query",client);
        }
        else
        {
            decl String:name[64];
            GetClientName(g_iCurrentRambo,name,sizeof(name));
            PrintToConsole(client,"[War3Source] You have set %s to Rambo",name);
        }

    }
    return Plugin_Handled;
}


public OnWar3EventDeath(victim,attacker,deathrace)
{
    if(ValidPlayer(victim)&&ValidPlayer(attacker)&&victim>0&&attacker>0&&attacker!=victim)
    {
        new vteam=GetClientTeam(victim);
        new ateam=GetClientTeam(attacker);
        if(vteam!=ateam)
        {
            new race_victim=War3_GetRace(victim);
            if(race_victim==War3_GetRaceIDByShortname("rambo") && g_bRamboEnabled)
            {
                new String:name[64];
                GetClientName(attacker,name,sizeof(name));
                PrintCenterTextAll( ".: !RAMBO LOSES! :.\n.: !%s KILLED RAMBO! :.", name);
                g_iCurrentRambo=attacker;
                W3GiveXPGold(attacker,XPAwardByKill,1000,10,"Killing Rambo");
                
                for(new i=0;i<=MaxClients;i++)
                {
                    if(ValidPlayer(i))
                    {
                        new iteam=GetClientTeam(i);
            
                        if(iteam == ateam)
                        {
                            if (ValidPlayer(i,true))
                            {
                                W3GiveXPGold(i,XPAwardByKill,250,5,"Your team defeated Rambo.");
                            }
                            else
                            {
                                W3GiveXPGold(i,XPAwardByKill,150,2,"Your team defeated Rambo.");
                            }
                        }
                    }
                }
            }
        }
    }
}




/***************************************************************************
*
*
*                RANKING CODE
*
*
#DEFINE RAMBO_DAMAGE 0
#DEFINE RAMBO_INDEX 1
new RamboDamage[MAXPLAYERS][MAXPLAYERS];
***************************************************************************/


public OnWar3EventPostHurt(victim, attacker, Float:damage, const String:weapon[32], bool:isWarcraft)
{
    if(g_bRamboEnabled)
    {
        if( ValidPlayer( victim ) && ValidPlayer( attacker ) && attacker != victim)
        {
            if( War3_GetRace( victim ) == War3_GetRaceIDByShortname("rambo") )
            {
                RamboDamage[attacker][RAMBO_DAMAGE] = RamboDamage[attacker][RAMBO_DAMAGE] + RoundToFloor(damage);
                RamboDamage[attacker][RAMBO_INDEX] = attacker;
            }
        }
    }
}

public SortItems(a[], b[], const array[][], Handle:hndl)
{
    if (b[RAMBO_DAMAGE] == a[RAMBO_DAMAGE])
    {
        return 0;
    }
    else if (b[RAMBO_DAMAGE] > a[RAMBO_DAMAGE])
    {
        return 1;
    }
    else
    {
        return -1;
    }
}





/***************************************************************************
*
*
*                HELPER FUNCTIONS / TIMERS
*
*
***************************************************************************/



public RoundStartEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    if(g_bRamboEnabled)
    {
        PrintCenterTextAll( ".: !RAMBO! :.\n.: !RAMBO! :.\n.: !RAMBO! :.");        
    }
}



public RoundOverEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    if(g_bRamboEnabled)
    {
        CreateTimer( 3.0, SetRambo);
        
        SortCustom2D(RamboDamage, MAXPLAYERS, SortItems);
        
        new String:Name1[256];
        new String:Name2[256];
        new String:Name3[256];
        

        GetClientName (RamboDamage[0][RAMBO_INDEX], Name1, 256 );
        GetClientName (RamboDamage[1][RAMBO_INDEX], Name2, 256 );
        GetClientName (RamboDamage[2][RAMBO_INDEX], Name3, 256 );
        
        PrintToChatAll( ".: !%s DEALT THE MOST DAMAGE |%d|! :.\n.: !%s DEALT 2ND MOST DAMAGE |%d|! :.\n.: !%s DEALT 3RD MOST DAMAGE |%d|! :.",Name1, RamboDamage[0][RAMBO_DAMAGE],Name2, RamboDamage[1][RAMBO_DAMAGE],Name3, RamboDamage[2][RAMBO_DAMAGE]);
        
        
        for (new i = 0; i < MAXPLAYERS; i++)
        {
            RamboDamage[i][RAMBO_DAMAGE] = 0;
            RamboDamage[i][RAMBO_INDEX] = 0;
        }

        
    }        
}
public Action:SetRambo( Handle:timer)
{
    for(new client=1;client<=MaxClients;client++)
        {
    
            if(ValidPlayer(client))
            {   
                if(client != g_iCurrentRambo)
                {
                     CS_SwitchTeam(client, TEAM_CT);
                }
                else
                {
                    
                    CS_SwitchTeam(client, TEAM_T);
                    
                    new ramboID = War3_GetRaceIDByShortname("rambo");
        
                    
                    W3SetPlayerProp(client,RaceChosenTime,GetGameTime());
                    W3SetPlayerProp(client,RaceSetByAdmin,true);
                    
                    War3_SetRace(client,ramboID);
                }       
            }
        }
}


public OnW3Denyable(W3DENY:event, client)
{
    if(event==DN_CanSelectRace)
    {
        new race_selected=W3GetVar(EventArg1);
                
        new raceID = War3_GetRaceIDByShortname("rambo");
        if (race_selected == raceID)
        {    
            if(!g_bRamboEnabled)
            {
                CPrintToChat( client, "{red}Access: - DENIED - {default}Rambo mode is not enabled." );    
                W3Deny();
            }
            else
            {
                if(client != g_iCurrentRambo)
                {
                    CPrintToChat( client, "{red}Access: - DENIED - {default}There can be only one Rambo - ask an Admin to set you next!" );    
                    W3Deny();
                }
            }
        }
    }
}

stock SetMoney(player,money)
{
    SetEntData(player,MoneyOffsetCS,money);
}



public Native_My_CheckRamboToggle(Handle:plugin, numParams)
{
    return _:g_bRamboEnabled;
}


public Native_My_RamboDamage(Handle:plugin, numParams)
{
    new num1 = GetNativeCell(1);
    if(ValidPlayer(num1))
        return _:RamboDamage[num1][RAMBO_DAMAGE];
        
    return 0;    
}

public Native_My_GetRamboID(Handle:plugin, numParams)
{
    return _:g_iCurrentRambo;
}



public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    CreateTimer(1.0, HudInfo_Timer, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action:HudInfo_Timer(Handle:timer, any:client)
{
    if(g_bRamboEnabled && ValidPlayer(g_iCurrentRambo))
    {
        decl String:HUD_Text[500];
        new g_iRamboHealth = GetClientHealth(g_iCurrentRambo);
        new g_iTeamCount = 0;
        for( new i = 1; i <= MaxClients; i++ )
        {
            if(ValidPlayer(i,true))
            {
                if(GetClientTeam( i ) == TEAM_CT)
                {
                    g_iTeamCount++;
                }
            }
        }  
        for( new i = 1; i <= MaxClients; i++ )
        {
            if(ValidPlayer(i))
            {
                new race=War3_GetRace(i);
                if (race > 0)
                {
                    new String:racename[64];
                    War3_GetRaceName(race,racename,sizeof(racename));
                    Format(HUD_Text, sizeof(HUD_Text), "Race: %s\nRambo's HP: %i\nRemaining CT: %i/%i\nDamage Dealt: %i", 
                        racename,
                        g_iRamboHealth,
                        g_iTeamCount,
                        GetTeamClientCount(TEAM_CT),
                        RamboDamage[i][RAMBO_DAMAGE]);
                    HUD_Message(GetClientUserId(i),HUD_Text);
                    
                }
            }
        
        }

    }
}


