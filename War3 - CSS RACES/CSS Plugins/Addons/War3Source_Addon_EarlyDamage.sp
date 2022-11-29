/**
* File: War3Source_Addon_EarlyDamage.sp
* Description: Displays a list to admins of all players who do damage before 5 seconds have elapsed..
* Author(s): Remy Lebeau
*/

#pragma semicolon 1
#include <sourcemod>
#include <sdkhooks>
#include "W3SIncs/War3Source_Interface"
#include <smlib>

public Plugin:myinfo = 
{
    name = "War3Source Addon - 5 Second Rule",
    author = "Remy Lebeau",
    description = "Lists infringers of 5 second rule to admins",
    version = "1.2",
    url = "sevensinsgaming.com"
};

new Handle:g_hPlayerMenu = INVALID_HANDLE;
new g_iEarlyShooters[MAXPLAYERS];
new bool:g_bWarned[MAXPLAYERS];
new Float:damageTimer;
new Handle:freezetimecvar;
new bool:g_bMoleToggle[MAXPLAYERS];
new moleID;
new bool:g_bShouldDisplayMenu = false;
new bool:g_bWarningToggle = false;

public OnPluginStart()
{
    HookEvent("round_start",RoundStartEvent);
    HookEvent("round_end",RoundEndEvent);
    freezetimecvar = FindConVar("mp_freezetime");

}

public OnClientAuthorized(client)
{
    if(ValidPlayer(client))
    {
        g_bWarned[client] = false;
    }
}


public OnWar3PluginReady()
{
    moleID=War3_GetItemIdByShortname("mole");
}
public RoundStartEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    damageTimer = GetGameTime() + 5.0 + GetConVarFloat(freezetimecvar);
    CreateTimer(5.0 + GetConVarFloat(freezetimecvar),DisplayEarlyDamageMenu);
    if (g_hPlayerMenu != INVALID_HANDLE)
    {
        CloseHandle(g_hPlayerMenu);
        g_hPlayerMenu = INVALID_HANDLE;
    }
    g_hPlayerMenu = CreateMenu(Menu_EarlyDamage);
    g_bWarningToggle = false;
}

public Action:DisplayEarlyDamageMenu(Handle:timer,any:data)
{
    if(g_bShouldDisplayMenu)
    {
        SetMenuTitle(g_hPlayerMenu, "Early Damage Punishments");

        AddMenuItem(g_hPlayerMenu, "ignore", "Ignore offences");
        AddMenuItem(g_hPlayerMenu, "slaywarn", "Slay offending players who have a previous warning + warn new offenders");
        AddMenuItem(g_hPlayerMenu, "warn", "Warn offending players");
        AddMenuItem(g_hPlayerMenu, "slay", "Slay offending players");
        
        new AdminId:admin;
        for(new i = 1; i <= MaxClients; i++)
        {
            if(ValidPlayer(i))
            {
                new String:temp[256];
                GetClientName(i,temp,sizeof(temp));
                admin = GetUserAdmin(i);
                if(GetAdminFlag(admin,Admin_Slay))
                {
                    DisplayMenu(g_hPlayerMenu, i, 15);
                }
            }
        }
    }
}


public Menu_EarlyDamage(Handle:menu, MenuAction:action, param1, param2)
{
    if (action == MenuAction_Select)
    {
    
        if (g_bWarningToggle)
        {
            if (ValidPlayer(param1))
            {
                new String:pluginString[512];
                Format(pluginString, sizeof(pluginString), "Another admin has already issued warnings/punishments.");
                printPluginMessage(param1,pluginString);
            }
        }
        else
        {
            g_bWarningToggle = true;
            new String:info[16];
     
            /* Get item info */
            new bool:found = GetMenuItem(menu, param2, info, sizeof(info));
            
            if (found)
            {
                if( StrEqual( info, "warn" ) )
                {
                    for(new i = 1; i <= MaxClients; i++)
                    {
                        if(ValidPlayer(i) && g_iEarlyShooters[i])
                        {
                            new String:pluginString[512];
                            Format(pluginString, sizeof(pluginString), "WARNING: DO NOT attack in under 5 seconds.");
                            printPluginMessage(i,pluginString);
                            g_bWarned[i] = true;
                        }
                    }
                }
                if( StrEqual( info, "slay" ) )
                {
                    for(new i = 1; i <= MaxClients; i++)
                    {
                        if(ValidPlayer(i) && g_iEarlyShooters[i])
                        {
                            new String:pluginString[512];
                            Format(pluginString, sizeof(pluginString), "PUNISHMENT: You attacked an enemy in under 5 seconds.");
                            printPluginMessage(i,pluginString);
                            ServerCommand( "sm_slay #%d", GetClientUserId( i ) );
                        }
                    }
                }
                if( StrEqual( info, "slaywarn" ) )
                {
                    for(new i = 1; i <= MaxClients; i++)
                    {
                        if(ValidPlayer(i) && g_iEarlyShooters[i])
                        {
                            if(g_bWarned[i])
                            {
                                new String:pluginString[512];
                                Format(pluginString, sizeof(pluginString), "PUNISHMENT: You attacked an enemy in under 5 seconds.");
                                printPluginMessage(i,pluginString);
                                ServerCommand( "sm_slay #%d", GetClientUserId( i ) );
                            }
                            else
                            {
                                new String:pluginString[512];
                                Format(pluginString, sizeof(pluginString), "WARNING: DO NOT attack in under 5 seconds.");
                                printPluginMessage(i,pluginString);
                                g_bWarned[i] = true;
                            }
                            
                        }
                    }
                }
            }

        }
    }

}


public RoundEndEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    for(new i = 1; i <= MaxClients; i++)
    {
        if(ValidPlayer(i))
        {
            g_bMoleToggle[i] = false;
        }
        
    }
    if (g_hPlayerMenu != INVALID_HANDLE)
    {
        CloseHandle(g_hPlayerMenu);
        g_hPlayerMenu = INVALID_HANDLE;
    }
    g_bShouldDisplayMenu = false;
}

public OnWar3EventSpawn(client)
{
    if(ValidPlayer(client,true)) 
    {
        g_bMoleToggle[client] = false;
        g_iEarlyShooters[client] = false;
        new String:itemname[64];
        W3GetItemShortname(moleID,itemname,sizeof(itemname));
        new race_client = War3_GetRace( client );
        
        new wardenID = War3_GetRaceIDByShortname("warden");
        new agentID = War3_GetRaceIDByShortname("agent");
        new assassinID = War3_GetRaceIDByShortname("lassassin");
        
        if (race_client == wardenID && wardenID > 0)
            g_bMoleToggle[client] = true;
        if (race_client == agentID && agentID > 0)
            g_bMoleToggle[client] = true;
        if (race_client == assassinID && assassinID > 0)
            g_bMoleToggle[client] = true;
            
        if(moleID>0 && War3_GetOwnsItem(client,moleID))
        {
            g_bMoleToggle[client] = true;
        }
    }
}

public OnW3TakeDmgBulletPre(victim,attacker,Float:damage)
{
    if(ValidPlayer(victim)&&ValidPlayer(attacker)&&attacker!=victim && GetClientTeam(attacker) != GetClientTeam(victim))
    {
        if(GetGameTime() < damageTimer && !g_bMoleToggle[attacker] && !g_bMoleToggle[victim])
        {
            sendAdminNotification(attacker, victim, 5.0 - (damageTimer - GetGameTime()) );
            g_iEarlyShooters[attacker] = true;
            g_bShouldDisplayMenu = true;
        }
    }
}

static sendAdminNotification(attacker, victim, Float:time)
{   
    new AdminId:admin;
    for(new i = 1; i <= MaxClients; i++)
    {
        if(ValidPlayer(i))
        {
            admin = GetUserAdmin(i);
            if(GetAdminFlag(admin,Admin_Generic))
            {
                new String:victimname[512], String:attackername[512];
                GetClientName(victim,victimname, sizeof(victimname));
                GetClientName(attacker,attackername, sizeof(attackername));
                new String:pluginString[512];
                Format(pluginString, sizeof(pluginString), "%s attacked %s in %.1f seconds", attackername, victimname, time);
                printPluginMessage(i,pluginString);
                // Send message to admin!
            }
        }
    }
}

static printPluginMessage(client, String:message[])
{
    new String:pluginString[512] = "{red}[5 SECOND RULE] {default}";
    StrCat(pluginString, sizeof(pluginString), message);
    CPrintToChat(client, pluginString);
}

