#include <sdktools>
#include <cstrike>

new String:g_sArmsModel[MAXPLAYERS+1][128]
	
// ====[ CONSTANTS ]=========================================================================
#define PLUGIN_NAME     "CS:GO Replace Anarchists Faction"
#define PLUGIN_VERSION  "1.0.0"

public Plugin:myinfo =
{
	name        = PLUGIN_NAME,
	author      = "Artful",
	description = "Replaces Anarchists with Leet Crew - CS:GO",
	version     = PLUGIN_VERSION,
}

public OnPluginStart()
{
	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);
}

public OnMapStart()
{
	PrecacheModel("models/player/tm_leet_variantb.mdl");
	PrecacheModel("models/weapons/t_arms_leet.mdl");
}

public OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsValidClient(client) && (GetClientTeam(client) == CS_TEAM_T))
	{
		GetEntPropString(client, Prop_Send, "m_szArmsModel", g_sArmsModel[client], 128);
		if (StrEqual(g_sArmsModel[client],"models/weapons/t_arms_anarchist.mdl"))
		{
			SetEntityModel(client, "models/player/tm_leet_variantb.mdl");
			SetEntPropString(client, Prop_Send, "m_szArmsModel", "models/weapons/t_arms_leet.mdl");
		}
	}
}

bool:IsValidClient(client) return (1 <= client <= MaxClients && IsClientInGame(client)) ? true : false;