#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <smlib>

public Plugin:myinfo =
{
    name = "Restart Announcer",
    author = "Remy Lebeau",
    description = "Provides a way to announce a server restart from console",
    version = "1.0",
    url = "http://www.sevensinsgaming.com"
};

public OnPluginStart()
{
    RegAdminCmd("sm_announce_restart", Server_Restart_Announce, ADMFLAG_RCON, "Allows an administrator to announce and initiate a server restart from the console. \nsm_announce_restart_cancel to cancel restart");
    RegAdminCmd("sm_announce_restart_cancel", Server_Restart_Announce_Cancel, ADMFLAG_RCON, "Allows an administrator to announce and initiate a server restart from the console. ");
    
}

new String:sound[] = "war3source/incoming_server_restart.mp3";

public OnMapStart()
{

    decl String:path[PLATFORM_MAX_PATH];
    Format(path, sizeof(path), "sound/%s", sound);
    if (FileExists(path)) 
    {
        AddFileToDownloadsTable(path);
        PrecacheSound(sound, true);
    }

}

#define CHAT_MESSAGE "The server will restart in {R}30{N} seconds. \nA server restart typically takes 10-20 seconds, so you should be able to reconnect shortly after the server quits."
#define CSAY_MESSAGE "Server restart. See chat for details"
new Handle:g_hServer_Restart_Timer = INVALID_HANDLE;
new Handle:g_hServer_Restart_Timer_20= INVALID_HANDLE;
new Handle:g_hServer_Restart_Timer_10= INVALID_HANDLE;
new Handle:g_hServer_Restart_Timer_5= INVALID_HANDLE;
new Handle:g_hServer_Restart_Timer_4= INVALID_HANDLE;
new Handle:g_hServer_Restart_Timer_3= INVALID_HANDLE;
new Handle:g_hServer_Restart_Timer_2= INVALID_HANDLE;
new Handle:g_hServer_Restart_Timer_1= INVALID_HANDLE;


public Action:Server_Restart_Announce(client, args)
{
    Client_PrintToChatAll(false,"%s", CHAT_MESSAGE);
    PrintHintTextToAll("%s", CSAY_MESSAGE);
    PrintHintTextToAll("%s", CSAY_MESSAGE);
    PrintHintTextToAll("%s", CSAY_MESSAGE);
    PrintCenterTextAll("%s", CSAY_MESSAGE);
    PrintCenterTextAll("%s", CSAY_MESSAGE);
    PrintToServer("Restart innitiated - server will restart in 30 seconds.  Use sm_announce_restart_cancel to cancel restart ");
    for(new i=1;i<=MaxClients;i++)
    {
        if(IsClientInGame(i))
        {
            EmitSoundToClient(i, sound);
        }
    }

    g_hServer_Restart_Timer = CreateTimer(30.0, Server_Restart);
    g_hServer_Restart_Timer_20 = CreateTimer(10.0, Restart_Message_20);
    g_hServer_Restart_Timer_10 = CreateTimer(20.0, Restart_Message_10);
    g_hServer_Restart_Timer_5 = CreateTimer(25.0, Restart_Message_5);
    g_hServer_Restart_Timer_4 = CreateTimer(26.0, Restart_Message_4);
    g_hServer_Restart_Timer_3 = CreateTimer(27.0, Restart_Message_3);
    g_hServer_Restart_Timer_2 = CreateTimer(28.0, Restart_Message_2);
    g_hServer_Restart_Timer_1 = CreateTimer(29.0, Restart_Message_1);
}
public Action:Server_Restart_Announce_Cancel(client, args)
{
    if(g_hServer_Restart_Timer != INVALID_HANDLE)
    {
        Client_PrintToChatAll(false,"{R}SERVER RESTART CANCELLED BY ADMIN");
        Client_PrintToChatAll(false,"{R}SERVER RESTART CANCELLED BY ADMIN");
        Client_PrintToChatAll(false,"{R}SERVER RESTART CANCELLED BY ADMIN");
        KillTimer(g_hServer_Restart_Timer);
        g_hServer_Restart_Timer = INVALID_HANDLE;
    }
    if(g_hServer_Restart_Timer_20 != INVALID_HANDLE)
    {
        KillTimer(g_hServer_Restart_Timer_20);
        g_hServer_Restart_Timer_20 = INVALID_HANDLE;
    }
    if(g_hServer_Restart_Timer_10 != INVALID_HANDLE)
    {
        KillTimer(g_hServer_Restart_Timer_10);
        g_hServer_Restart_Timer_10 = INVALID_HANDLE;
    }
    if(g_hServer_Restart_Timer_5 != INVALID_HANDLE)
    {
        KillTimer(g_hServer_Restart_Timer_5);
        g_hServer_Restart_Timer_5 = INVALID_HANDLE;
    }
    if(g_hServer_Restart_Timer_4 != INVALID_HANDLE)
    {
        KillTimer(g_hServer_Restart_Timer_4);
        g_hServer_Restart_Timer_4 = INVALID_HANDLE;
    }
    if(g_hServer_Restart_Timer_3 != INVALID_HANDLE)
    {
        KillTimer(g_hServer_Restart_Timer_3);
        g_hServer_Restart_Timer_3 = INVALID_HANDLE;
    }
    if(g_hServer_Restart_Timer_2 != INVALID_HANDLE)
    {
        KillTimer(g_hServer_Restart_Timer_2);
        g_hServer_Restart_Timer_2 = INVALID_HANDLE;
    }
    if(g_hServer_Restart_Timer_1 != INVALID_HANDLE)
    {
        KillTimer(g_hServer_Restart_Timer_1);
        g_hServer_Restart_Timer_1 = INVALID_HANDLE;
    }

}

public Action:Server_Restart(Handle:timer, any:data)
{
    g_hServer_Restart_Timer = INVALID_HANDLE;
    ServerCommand( "sm_rcon quit" );
    return Plugin_Handled;
}

public Action:Restart_Message_20(Handle:timer, any:time)
{
    Client_PrintToChatAll(false,"The server will restart in {R}20{N} seconds. \nA server restart typically takes 10-20 seconds, so you should be able to reconnect shortly after the server quits.");
    PrintCenterTextAll("%s", CSAY_MESSAGE);
    for(new i=1;i<=MaxClients;i++)
    {
        if(IsClientInGame(i))
        {
            EmitSoundToClient(i, sound);
        }
    }
    g_hServer_Restart_Timer_20 = INVALID_HANDLE;
    return Plugin_Continue;
}

public Action:Restart_Message_10(Handle:timer, any:time)
{
    Client_PrintToChatAll(false,"The server will restart in {R}10{N} seconds. \nA server restart typically takes 10-20 seconds, so you should be able to reconnect shortly after the server quits.");
    PrintCenterTextAll("%s", CSAY_MESSAGE);
    for(new i=1;i<=MaxClients;i++)
    {
        if(IsClientInGame(i))
        {
            EmitSoundToClient(i, sound);
        }
    }
    g_hServer_Restart_Timer_10 = INVALID_HANDLE;
    return Plugin_Continue;
}

public Action:Restart_Message_5(Handle:timer, any:time)
{
    Client_PrintToChatAll(false,"{R}Server will restart in 5 seconds");
    PrintHintTextToAll("Server will restart in 5 seconds");
    g_hServer_Restart_Timer_5 = INVALID_HANDLE;
    return Plugin_Continue;
}

public Action:Restart_Message_4(Handle:timer, any:time)
{
    Client_PrintToChatAll(false,"{R}Server will restart in 4 seconds");
    PrintHintTextToAll("Server will restart in 4 seconds");
    g_hServer_Restart_Timer_4 = INVALID_HANDLE;
    return Plugin_Continue;
}

public Action:Restart_Message_3(Handle:timer, any:time)
{
    Client_PrintToChatAll(false,"{R}Server will restart in 3 seconds");
    PrintHintTextToAll("Server will restart in 3 seconds");
    g_hServer_Restart_Timer_3 = INVALID_HANDLE;
    return Plugin_Continue;
}

public Action:Restart_Message_2(Handle:timer, any:time)
{
    Client_PrintToChatAll(false,"{R}Server will restart in 2 seconds");
    PrintHintTextToAll("Server will restart in 2 seconds");
    g_hServer_Restart_Timer_2 = INVALID_HANDLE;
    return Plugin_Continue;
}

public Action:Restart_Message_1(Handle:timer, any:time)
{
    Client_PrintToChatAll(false,"{R}Server will restart in 1 seconds");
    PrintHintTextToAll("Server will restart in 1 seconds");
    g_hServer_Restart_Timer_1 = INVALID_HANDLE;
    return Plugin_Continue;
}