#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

public Plugin:myinfo =
{
    name = "Basic Lag Tester",
    author = "Remy Lebeau",
    description = "Logs a timestap to a log file once per second.",
    version = "1.0",
    url = "http://www.sevensinsgaming.com"
};

new Handle:g_hCvarLagLogEnable = INVALID_HANDLE;

public OnPluginStart()
{
    g_hCvarLagLogEnable = CreateConVar("sm_laglogenable", "0", "Enable/Disable logging a timestamp every second.");
    CreateTimer(1.0, LogTimer, _, TIMER_REPEAT);
}


public Action:LogTimer(Handle:timer)
{
    if(GetConVarBool(g_hCvarLagLogEnable))
    {
        new String:buffer[100];
        FormatTime(buffer, sizeof(buffer), NULL_STRING, -1);
        LogMessage("%s",buffer);    
    }
}