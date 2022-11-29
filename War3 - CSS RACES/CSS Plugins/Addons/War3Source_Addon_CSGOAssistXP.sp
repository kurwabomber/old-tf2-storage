#pragma semicolon 1
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

Handle AssistXPDivisorConVar;
Handle AssistTimers[MAXPLAYERS+1];
new WasAssistedBy[MAXPLAYERS] = {-1, ...};

public Plugin:myinfo = 
{
    name = "W3S CSGO Assist XP",
    author = "Kibbles",
    description = "CSGO Assist XP for War3Source",
    version = "1.0",
    url = "http://sevensinsgaming.com"
};


public OnPluginStart()
{
    AssistXPDivisorConVar = CreateConVar("war3_csgo_assist_xp_divisor", "4", "Assist XP Divisor for War3Source CS:GO");
    HookEvent("round_start", Event_RoundStart);
    HookEvent("player_death", Event_PlayerDeath);
}


public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
    for (new i=0; i<MAXPLAYERS; i++)
    {
        WasAssistedBy[i] = -1;
    }
}


public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
    int deadClient = GetClientOfUserId(GetEventInt(event, "userid"));
    int attackerClient = GetClientOfUserId(GetEventInt(event, "attacker"));
    int assisterClient = GetClientOfUserId(GetEventInt(event, "assister"));
    
    if (ValidPlayer(deadClient) && ValidPlayer(attackerClient) && ValidPlayer(assisterClient)
        && GetClientTeam(deadClient) != GetClientTeam(assisterClient))
    {
        WasAssistedBy[attackerClient] = assisterClient;
    }
    
    return Plugin_Continue;
}


public OnWar3Event(W3EVENT:event,client)
{
    if(event==OnPostGiveXPGold && ValidPlayer(client))
    {
        DataPack assistPack;
        AssistTimers[client] = CreateDataTimer(0.2, AwardAssistXP, assistPack, TIMER_FLAG_NO_MAPCHANGE );
        assistPack.WriteCell(client);
        assistPack.WriteCell(W3GetVar(EventArg2));
    }
}

public Action:AwardAssistXP(Handle timer, Handle assistPack)
{
    ResetPack(assistPack);
    int attacker = ReadPackCell(assistPack);
    int KillXP = ReadPackCell(assistPack);
    int assister = WasAssistedBy[attacker];
    
    int ModifiedXP = KillXP / GetConVarInt(AssistXPDivisorConVar);
    
    if(ValidPlayer(assister))
    {
        char awardString[] = "assisting in a kill";
        W3GiveXPGold(assister, _, ModifiedXP, 0, awardString);
        WasAssistedBy[attacker] = -1;
    }
    AssistTimers[attacker] = INVALID_HANDLE;
}