#pragma semicolon 1

// Includes
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <sm_chaosmvm>
#include <tf2attributes>

// Defines
#define ABIL_VERSION "1.0"
#define MAX_DISTANCE 400.0
#define SND_EXPLODE "sound/weapons/rocket_directhit_explode3.wav"
#define TF_DMG_BULLET	(DMG_BULLET | DMG_BUCKSHOT)
#define TF_DMG_MELEE	(DMG_CLUB)
#define TF_DMG_BLEED	(DMG_SLASH)
// Plugin Info
public Plugin:myinfo =
{
	name = "Chaos MVM Custom Attributes",
	author = "X Kirby, Added attributes by Razor.",
	description = "stuff for custom attrs i guess.",
	version = ABIL_VERSION,
	url = "n/a",
}

// Variables
new Float:fl_AbilLevel[MAXPLAYERS+1] = 0.0;
new Float:fl_CritDamage[MAXPLAYERS+1] = 1.0;
new Float:fl_EnableHeadshots[MAXPLAYERS+1] = 1.0;//crit chance
new Float:fl_ReflectChance[MAXPLAYERS+1] = 0.0;
new Float:fl_BleedMult[MAXPLAYERS+1] = 1.0;
new Float:fl_PlayerSizeMult[MAXPLAYERS+1] = 1.0;
new Float:fl_SlowOnHit[MAXPLAYERS+1] = 0.0;
new bool:b_Hooked[MAXPLAYERS+1] = false;
new g_ExplosionSprite;
// On Plugin Start
public OnPluginStart()
{
	// Explosion Effect Precache
	g_ExplosionSprite = PrecacheModel("sprites/sprite_fire01.vmt");
	PrecacheSound(SND_EXPLODE);
	for(new i=1; i<=MAXPLAYERS; i++)
	{
		if(!IsValidEntity(i)){continue;}
		fl_AbilLevel[i] = 0.0;
		fl_CritDamage[i] = 1.0;
		fl_EnableHeadshots[i] = 1.0;
		fl_ReflectChance[i] = 0.0;
		fl_BleedMult[i] = 1.0;
		fl_PlayerSizeMult[i] = 1.0;
		fl_SlowOnHit[i] = 0.0;
		if(b_Hooked[i] == false)
		{
			b_Hooked[i] = true;
			SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
		}
	}
	HookEvent("player_changeclass", Event_ResetCustom);
	HookEvent("player_spawn", Event_Respawn);
}
public Event_ResetCustom(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	fl_AbilLevel[client] = 0.0;
	fl_CritDamage[client] = 1.0;
	fl_EnableHeadshots[client] = 1.0;
	fl_ReflectChance[client] = 0.0;
	fl_BleedMult[client] = 1.0;
	fl_PlayerSizeMult[client] = 1.0;
	fl_SlowOnHit[client] = 0.0;
}
public Event_Respawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	UpdatePlayerHitbox(client, fl_PlayerSizeMult[client]);
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", fl_PlayerSizeMult[client]);
}
stock UpdatePlayerHitbox(const client, const Float:fScale)
{
	static const Float:vecTF2PlayerMin[3] = { -24.5, -24.5, 0.0 }, Float:vecTF2PlayerMax[3] = { 24.5,  24.5, 83.0 };
	
	decl Float:vecScaledPlayerMin[3], Float:vecScaledPlayerMax[3];

	vecScaledPlayerMin = vecTF2PlayerMin;
	vecScaledPlayerMax = vecTF2PlayerMax;
	
	ScaleVector(vecScaledPlayerMin, fScale);
	ScaleVector(vecScaledPlayerMax, fScale);
	
	SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMins", vecScaledPlayerMin);
	SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMaxs", vecScaledPlayerMax);
}
// On Map Start
public OnMapStart()
{
	for(new i=1; i<=MAXPLAYERS; i++)
	{
		if(!IsValidEntity(i)){continue;}
		fl_AbilLevel[i] = 0.0;
		fl_CritDamage[i] = 1.0;
		fl_EnableHeadshots[i] = 1.0;
		fl_ReflectChance[i] = 0.0;
		fl_BleedMult[i] = 1.0;
		fl_PlayerSizeMult[i] = 1.0;
		fl_SlowOnHit[i] = 0.0;
		if(b_Hooked[i] == false)
		{
			b_Hooked[i] = true;
			SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
		}
	}
}

// On Client Put In Server
public OnClientPutInServer(client)
{
	fl_AbilLevel[client] = 0.0;
	fl_CritDamage[client] = 1.0;
	fl_EnableHeadshots[client] = 1.0;
	fl_ReflectChance[client] = 0.0;
	fl_BleedMult[client] = 1.0;
	fl_PlayerSizeMult[client] = 1.0;
	fl_SlowOnHit[client] = 0.0;
	if(b_Hooked[client] == false)
	{
		b_Hooked[client] = true;
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}

// On Client Disconnect
public OnClientDisconnect(client)
{
	if(IsClientInGame(client))
	{
		fl_AbilLevel[client] = 0.0;
		fl_CritDamage[client] = 1.0;
		fl_EnableHeadshots[client] = 1.0;
		fl_ReflectChance[client] = 0.0;
		fl_BleedMult[client] = 1.0;
		fl_PlayerSizeMult[client] = 1.0;
		fl_SlowOnHit[client] = 0.0;
		b_Hooked[client] = false;
		SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}

// Set Attribute Value
public SetAttribValue(client, String:effectname[256], Float:value)
{
	if(StrEqual(effectname, "cmvm_abil_meteorcrash"))
	{
		fl_AbilLevel[client] = value;
	}
	if(StrEqual(effectname, "cmvm_critdamagemult"))
	{
		fl_CritDamage[client] = value;
	}
	if(StrEqual(effectname, "cmvm_enableheadshots"))
	{
		fl_EnableHeadshots[client] = value;
	}
	if(StrEqual(effectname, "cmvm_reflectchance"))
	{
		fl_ReflectChance[client] = value;
	}
	if(StrEqual(effectname, "cmvm_bleeddamagemult"))
	{
		fl_BleedMult[client] = value;
	}
	if(StrEqual(effectname, "cmvm_resizeplayer"))
	{
		fl_PlayerSizeMult[client] = value;
	}
	if(StrEqual(effectname, "cmvm_slowonhit"))
	{
		fl_SlowOnHit[client] = value;
	}	
}
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(TF2_IsPlayerInCondition(client, TFCond_TeleportedGlow)){
	TF2Attrib_SetByName(client,"move speed penalty", 0.6);
	}
	else{
	TF2Attrib_SetByName(client,"move speed penalty", 1.0);
	}
}
// Get Attribute Value
public Float:GetAttribValue(client, String:effectname[256])
{
	if(StrEqual(effectname, "cmvm_abil_meteorcrash"))
	{
		return fl_AbilLevel[client];
	}
	if(StrEqual(effectname, "cmvm_critdamagemult"))
	{
		return fl_CritDamage[client];
	}
	if(StrEqual(effectname, "cmvm_reflectchance"))
	{
		return fl_ReflectChance[client];
	}
	if(StrEqual(effectname, "cmvm_enableheadshots"))
	{
		return fl_EnableHeadshots[client];
	}
	if(StrEqual(effectname, "cmvm_bleeddamagemult"))
	{
		return fl_BleedMult[client];
	}
	if(StrEqual(effectname, "cmvm_resizeplayer"))
	{
		return fl_PlayerSizeMult[client];
	}
	if(StrEqual(effectname, "cmvm_slowonhit"))
	{
		return fl_SlowOnHit[client];
	}
	return 0.0;
}

// On Take Damage
public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	if(victim > 0 && victim <= MaxClients && weapon != -1 && (attacker > 0 || attacker <= MaxClients))
	{
		if(!IsClientInGame(victim))
		{
			return Plugin_Continue;
		}

		// Perform an Explosion if you take Fall Damage
		if(damagetype == DMG_FALL && fl_AbilLevel[victim] > 0.0)
		{
			FallExplosion(victim, damage * fl_AbilLevel[victim], MAX_DISTANCE);
			return Plugin_Changed;
		}
		if(damagetype & DMG_CRIT && fl_CritDamage[attacker] != 1.0)
		{
			damage *= fl_CritDamage[attacker];
			return Plugin_Changed;
		}
		if(damagetype & TF_DMG_BLEED)
		{
			damage *= fl_BleedMult[attacker];
			return Plugin_Changed;
		}
		if(fl_ReflectChance[victim] != 0.0)
		{
			if(fl_ReflectChance[victim] > GetRandomFloat(0.0, 1.0))
			{
				new Adresss:pAttr = TF2Attrib_GetByName(victim, "dmg taken increased");
				new Float:flValue = TF2Attrib_GetValue(pAttr);
				new Float:forcereflect[3];
				GetEntPropVector(attacker, Prop_Data, "m_vecVelocity", forcereflect);
				forcereflect[2] = 150.0;
				SDKHooks_TakeDamage(attacker,victim,victim,((damage/flValue)),damagetype,-1,forcereflect,NULL_VECTOR);
			}
		}
		if(fl_SlowOnHit[attacker] != 0.0 && attacker != victim)
		{
			TF2_AddCondition(victim, TFCond_TeleportedGlow, fl_SlowOnHit[attacker]);
		}
	}
	return Plugin_Continue;
}
public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
	if (fl_EnableHeadshots[client] > GetRandomFloat(1.0, 2.0))
	{
		result = true;
		return Plugin_Handled;	
	}
	
	result = false;
	
	return Plugin_Handled;
}
// Fall Damage Explosion
FallExplosion(client, Float:dmg, Float:distance)
{
	if(IsPlayerAlive(client))
	{
		// Find User Location
		new Float:uservec[3], Float:targetvec[3];
		GetClientAbsOrigin(client, uservec);
		
		// Play Effects
		TE_SetupExplosion(uservec, g_ExplosionSprite, 2.0, 1, TE_EXPLFLAG_NONE, 300, 4);
		TE_SendToAll(0.0);
		EmitSoundToAll(SND_EXPLODE, client);
		
		// Look for all Clients
		for(new i=1; i<=MaxClients; i++)
		{
			if(!IsClientInGame(i)){continue;}
			
			// Get Target Location
			GetClientAbsOrigin(i, targetvec);
			
			// Check for close-by targets
			if(i != client && GetClientTeam(i) != GetClientTeam(client) && GetVectorDistance(uservec, targetvec, false) < distance)
			{
				TE_SetupExplosion(targetvec, g_ExplosionSprite, 2.0, 1, TE_EXPLFLAG_NONE, 300, 4);
				TE_SendToAll(0.0);
				
				new Float:force[3];
				GetEntPropVector(i, Prop_Data, "m_vecVelocity", force);
				force[2] = 500.0;
				SDKHooks_TakeDamage(i, client, client, dmg, DMG_BLAST, -1, force, NULL_VECTOR);
			}
		}
	}
}