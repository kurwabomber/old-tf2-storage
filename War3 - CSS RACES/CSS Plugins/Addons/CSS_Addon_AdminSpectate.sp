#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <smlib>

#define TEAM_SPECTATOR 1

new bool:g_bIsStealthed[MAXPLAYERS + 2] = { false, ...};
new g_SpecTarget[MAXPLAYERS] = { -1, ...};
new Handle:cvarAdminStealthSpectateActive;

//ASS = Admin Stealth Spectate. Not advertised through 'sm plugin' to avoid general knowledge.
public Plugin:myinfo = 
{
    name = "ASS",
    author = "Kibbes",
    description = "ASS mod.",
    version = "1.1",
    url = "http://sevensinsgaming.com/"
};

public OnPluginStart()
{
    cvarAdminStealthSpectateActive = CreateConVar("sm_ass_enable", "1", "Toggle for the ASS plugin.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    RegAdminCmd("sm_spec", Command_StealthSpec_toggle, ADMFLAG_SLAY, "Allows an administrator to toggle stealth spectating on/off.");
    RegAdminCmd("sm_spectarget", Command_StealthSpec_setTarget, ADMFLAG_SLAY, "Allows an administrator to spectate a particular target whenever they're alive.");
    RegConsoleCmd("say", Command_Block);
    RegConsoleCmd("say_team", Command_Block);
    HookEvent("player_team", Event_PlayerTeam, EventHookMode_Pre);
    HookEvent("player_spawn", Event_PlayerSpawn);
}

public OnMapStart()
{
    new PMIndex = FindEntityByClassname(0, "cs_player_manager");
    SDKHook(PMIndex, SDKHook_ThinkPost, OnThinkPost);
    
    for (new i=1; i<=MaxClients; i++)
    {
        g_bIsStealthed[i] = false;
        g_SpecTarget[i] = -1;
    }
} 
public OnThinkPost(entity)
{
    if (GetConVarBool(cvarAdminStealthSpectateActive))
    {
        new IsConnected[65];
        new IsConnectedOffset = FindSendPropOffs("CCSPlayerResource", "m_bConnected");
        GetEntDataArray(entity, IsConnectedOffset, IsConnected, 65);
        for (new i=1; i<=MaxClients; i++)
        {
            if (ValidPlayer(i) && g_bIsStealthed[i])
            {
                IsConnected[i] = 0;
            }
        }
        SetEntDataArray(entity, IsConnectedOffset, IsConnected, 65);
    }
}

public Action:Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
    if (GetConVarBool(cvarAdminStealthSpectateActive))
    {
        new client = GetClientOfUserId(GetEventInt(event, "userid"));
        new team = GetEventInt(event, "team");
        if (g_bIsStealthed[client] && team == TEAM_SPECTATOR)
        {
            return Plugin_Handled;
        }
        else if (g_bIsStealthed[client] && team != TEAM_SPECTATOR)
        {
            CreateTimer(0.1, ReturnClientToSpec, client);
            return Plugin_Handled;
        }
        else
        {
            return Plugin_Continue;
        }
    }
    else
    {
        return Plugin_Continue;
    }
}
public Action:ReturnClientToSpec(Handle:timer, any:client)
{
    ChangeClientTeam(client, TEAM_SPECTATOR);
    printPluginMessage(client, "Can not join teams while in stealth mode.");
    
    return Plugin_Handled;
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
    if (GetConVarBool(cvarAdminStealthSpectateActive))
    {
        new client = GetClientOfUserId(GetEventInt(event, "userid"));
        for (new i=1; i<=MaxClients; i++)
        {
            if (g_bIsStealthed[i] && ValidSpectator(i) && client == g_SpecTarget[i] && ValidPlayer(client))
            {
                SetObserverTarget(i, client);
            }
        }
    }
    return Plugin_Continue;
}
static SetObserverTarget(client, target)
{
    new bool:resetFOV = (Client_GetFOV(client) != 0) ? true : false;
    Client_SetObserverTarget(client, target, resetFOV);
    printPluginMessage(client, "Switching to targeted player");
}

public Action:Command_Block(client, args)
{
    if (GetConVarBool(cvarAdminStealthSpectateActive))
    {
        if (g_bIsStealthed[client])
        {
            return Plugin_Handled;
        }
    }
    return Plugin_Continue;
}

public Action:Command_StealthSpec_toggle(client, args)
{
    if (GetConVarBool(cvarAdminStealthSpectateActive))
    {
        ToggleStealth(client);
        //LogAction(client, -1, "%N has toggled stealth mode.", client);
    }
    return Plugin_Handled;
}
ToggleStealth(client)
{
    if(g_bIsStealthed[client]) 
    {
        StealthOff(client);
    } 
    else 
    {
        StealthOn(client);
    }
}
StealthOn(client, bool:announce=true)
{
    g_bIsStealthed[client] = true;
    ChangeClientTeam(client, TEAM_SPECTATOR);
    if (announce)
    {
        new String:clientSteamID[128];
        getClientSteamID(client, clientSteamID, sizeof(clientSteamID));
        Client_PrintToChatAll(false, "Player %N left the game (Disconnect by user.)", client);
        //Client_PrintToChatAll(false, "{G}%N({N}%s{G}){N} disconnected from {G}AU{N}", client, clientSteamID);
    }
    printPluginMessage(client, "You are now in stealth mode.");

}
StealthOff(client, bool:announce=true)
{
    g_bIsStealthed[client] = false;
    if (announce)
    {
        new String:clientSteamID[128];
        getClientSteamID(client, clientSteamID, sizeof(clientSteamID));
        Client_PrintToChatAll(false, "Player %N has joined the game", client);
        //Client_PrintToChatAll(false, "{G}%N({N}%s{G}){N} connected from {G}AU{N}", client, clientSteamID);
    }
    printPluginMessage(client, "You are no longer in stealth mode.");

}
public OnClientDisconnect(client)
{
    if (GetConVarBool(cvarAdminStealthSpectateActive))
    {
        for (new i=1; i<=MaxClients; i++)
        {
            if (client == g_SpecTarget[i])
            {
                UnsetTarget(i, client);
            }
        }
        if(g_bIsStealthed[client])
        {
            StealthOff(client, false);
        }
    }
}
static UnsetTarget(client, target)
{
    new String:output[256];
    Format(output, 256, "%N has disconnected. No longer targeting.", target);
    printPluginMessage(client, output);
    g_SpecTarget[client] = -1;
}

public Action:Command_StealthSpec_setTarget(client, args)
{
    if (GetConVarBool(cvarAdminStealthSpectateActive))
    {
        if (args < 1)
        {
            g_SpecTarget[client] = -1;
            printPluginMessage(client, "Targeting has been disabled.");
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
        if (target_count > 1) {
            new String:output[256];
            Format(output, sizeof(output), "More than one target found for: %s, please narrow your search.", arg);
            printPluginMessage(client, output);
            return Plugin_Handled;
        }
        
        g_SpecTarget[client] = target_list[0];
        new String:output[256];
        Format(output, sizeof(output), "Now targeting %N.", g_SpecTarget[client]);
        printPluginMessage(client, output);
        
        if (ValidSpectator(client) && ValidPlayer(g_SpecTarget[client]) && IsPlayerAlive(g_SpecTarget[client]))
        {
            SetObserverTarget(client, g_SpecTarget[client]);
        }
    }
    
    return Plugin_Handled;
}


//
// Helper functions
//
static printPluginMessage(client, String:message[])
{
    new String:pluginString[512] = "{G}[StealthSpec] {N}";
    StrCat(pluginString, sizeof(pluginString), message);
    Client_PrintToChat(client, false, pluginString);
}

static getClientSteamID(client, String:buffer[], bufferLen)
{
    GetClientAuthString(client, buffer, bufferLen);
}

static bool:ValidPlayer(client)
{
	if(client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client))
	{
		return true;
	}
	return false;
}

static bool:ValidSpectator(client)
{
    if(ValidPlayer(client) && !IsPlayerAlive(client))
    {
        return true;
    }
    return false;
}