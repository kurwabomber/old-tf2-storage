// Includes
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <sm_chaosmvm>
#include <tf2attributes>
#include <tf2_isPlayerInSpawn>
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
new Float:fl_PlayerJumps[MAXPLAYERS+1] = 0.0;
new Float:fl_SlowOnHit[MAXPLAYERS+1] = 0.0;
new Float:fl_SplashRadius[MAXPLAYERS+1] = 50.0;
new Float:fl_SplashDamage[MAXPLAYERS+1] = 0.0;
new bool:b_Hooked[MAXPLAYERS+1] = false;
new g_ExplosionSprite;
//Stocks
stock bool:IsValidClient(client, bool:nobots = true)
{ 
    if (client <= 0 || client > MaxClients || !IsClientConnected(client) || (nobots && IsFakeClient(client)))
    {
        return false; 
    }
    return IsClientInGame(client); 
}
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
		fl_PlayerJumps[i] = 0.0;
		fl_SlowOnHit[i] = 0.0;
		fl_SplashRadius[i] = 50.0;
		fl_SplashDamage[i] = 0.0;
		if(b_Hooked[i] == false)
		{
			b_Hooked[i] = true;
			SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
		}
	}
	HookEvent("player_changeclass", Event_ResetCustom);
}
public Event_ResetCustom(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	fl_AbilLevel[client] = 0.0;
	fl_CritDamage[client] = 1.0;
	fl_EnableHeadshots[client] = 1.0;
	fl_ReflectChance[client] = 0.0;
	fl_BleedMult[client] = 1.0;
	fl_PlayerJumps[client] = 0.0;
	fl_SlowOnHit[client] = 0.0;
	fl_SplashRadius[client] = 50.0;
	fl_SplashDamage[client] = 0.0;
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
		fl_PlayerJumps[i] = 0.0;
		fl_SlowOnHit[i] = 0.0;
		fl_SplashRadius[i] = 50.0;
		fl_SplashDamage[i] = 0.0;
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
	fl_PlayerJumps[client] = 0.0;
	fl_SlowOnHit[client] = 0.0;
	fl_SplashRadius[client] = 50.0;
	fl_SplashDamage[client] = 0.0;
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
		fl_PlayerJumps[client] = 0.0;
		fl_SlowOnHit[client] = 0.0;
		fl_SplashRadius[client] = 50.0;
		fl_SplashDamage[client] = 0.0;
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
	if(StrEqual(effectname, "cmvm_playerjumps"))
	{
		fl_PlayerJumps[client] = value;
	}
	if(StrEqual(effectname, "cmvm_slowonhit"))
	{
		fl_SlowOnHit[client] = value;
	}	
	if(StrEqual(effectname, "cmvm_splashradius"))
	{
		fl_SplashRadius[client] = value;
	}	
	if(StrEqual(effectname, "cmvm_splashdamage"))
	{
		fl_SplashDamage[client] = value;
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
	new flags = GetEntityFlags(client);
	if((flags & FL_ONGROUND) && fl_PlayerJumps[client] > 0)
	{	
		TF2_RemoveCondition(client,TFCond_HalloweenSpeedBoost);
	}
	if(buttons & IN_JUMP && fl_PlayerJumps[client] > 0 && (flags & FL_ONGROUND)){
		TF2_AddCondition(client,TFCond_HalloweenSpeedBoost,(fl_PlayerJumps[client]) );
	}
	if(TF2_GetPlayerClass(client) == TFClass_Sniper)
	{
		if(IsValidClient(client))
		{
			new iWeapon = GetPlayerWeaponSlot(client, 0);
			if(IsValidEntity(iWeapon))
			{
				new Address:charge = TF2Attrib_GetByName(iWeapon, "Repair rate increased");
				if(charge != Address_Null)
				{
					new Float:chargepct = TF2Attrib_GetValue(charge);
					new Float:epic = chargepct*1.5;
					new Float:currentcharge = GetEntPropFloat(iWeapon, Prop_Send, "m_flChargedDamage");
					if(currentcharge < epic)
					{
						SetEntPropFloat(iWeapon, Prop_Send, "m_flChargedDamage", chargepct);
					}
				}
			}
		}
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
	if(StrEqual(effectname, "cmvm_playerjumps"))
	{
		return fl_PlayerJumps[client];
	}
	if(StrEqual(effectname, "cmvm_slowonhit"))
	{
		return fl_SlowOnHit[client];
	}
	if(StrEqual(effectname, "cmvm_splashradius"))
	{
		return fl_SplashRadius[client];
	}	
	if(StrEqual(effectname, "cmvm_splashdamage"))
	{
		return fl_SplashDamage[client];
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
		if(!IsValidClient(attacker)){
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
		//if(fl_ReflectChance[victim] != 0.0)
		//{
		//	if(fl_ReflectChance[victim] > GetRandomFloat(0.0, 1.0))
		//	{
		//		new Address:pAttr = TF2Attrib_GetByName(victim, "dmg taken increased");
		//		new Float:flValue = TF2Attrib_GetValue(pAttr);
		//		SDKHooks_TakeDamage(attacker,victim,victim,((damage/flValue)),DMG_GENERIC,-1,NULL_VECTOR,NULL_VECTOR);
		//	}
		//}
		if(fl_SlowOnHit[attacker] != 0.0 && attacker != victim)
		{
			TF2_AddCondition(victim, TFCond_TeleportedGlow, fl_SlowOnHit[attacker]);
		}
		if(attacker != victim && fl_SplashDamage[attacker] != 0.0)
		{
			new Address:dmgtaken = TF2Attrib_GetByName(victim, "dmg taken increased");
			if(dmgtaken  != Address_Null)
			{
				new Float:allres = TF2Attrib_GetValue(dmgtaken);
				SplashDamage(victim,fl_SplashDamage[attacker],fl_SplashRadius[attacker],damage,allres,attacker,weapon);
			}
			else
			{
				SplashDamage(victim,fl_SplashDamage[attacker],fl_SplashRadius[attacker],damage,1.0,attacker,weapon);
			}
		}
		if(attacker != victim){
			new hClientWeapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
			new Address:overrideproj = TF2Attrib_GetByName(hClientWeapon, "override projectile type");
			new Address:bulletspershot = TF2Attrib_GetByName(hClientWeapon, "bullets per shot bonus");
			if(overrideproj != Address_Null && bulletspershot != Address_Null){
			new Float:override = TF2Attrib_GetValue(overrideproj);
			new Float:bps = TF2Attrib_GetValue(bulletspershot);
			if(override == 2.0 || override == 6.0){
				damage *= bps;
				return Plugin_Changed;
			}
			}
		}
		if(damagetype == DMG_BULLET && fl_ReflectChance[attacker] != 0.0)
		{
			damagetype|=DMG_PREVENT_PHYSICS_FORCE;
			damagetype|=DMG_USE_HITLOCATIONS;
			return Plugin_Changed;
		}
		if(damagecustom == TF_CUSTOM_PLAYER_SENTRY && damagetype == DMG_BLAST)
		{
			damagetype|=DMG_PREVENT_PHYSICS_FORCE;
			new owner = GetEntPropEnt(attacker, Prop_Send, "m_hBuilder"); 
			if(IsValidClient(owner))
			{
				new melee = (GetPlayerWeaponSlot(owner,2));
				new Address:SentryDamage = TF2Attrib_GetByName(melee, "clip size bonus");
				if(SentryDamage != Address_Null)
				{
					new Float:sentryrocketdmg = TF2Attrib_GetValue(SentryDamage);
					damage *= sentryrocketdmg;
					return Plugin_Changed;
				}				
			}
		}
		new Address:pAttr = TF2Attrib_GetByName(victim, "sniper zoom penalty");
		if (pAttr != Address_Null && (damagetype & DMG_CRIT))
		{
			TF2_AddCondition(victim, TFCond_UberBulletResist, 0.25)
			return Plugin_Changed;
		}
		if(TF2Spawn_IsClientInSpawn(victim))
		{
			damage *= 0.0;
			return Plugin_Changed;
		}
		if(TF2Spawn_IsClientInSpawn(attacker))
		{
			damage *= 3.0;
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}
public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
	if (fl_EnableHeadshots[client] > GetRandomFloat(1.0, 2.0) )
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
SplashDamage(client, Float:dmg, Float:distance, Float:damageoriginal, Float:res, enemy, weapon)
{
	if(IsPlayerAlive(client))
	{
		// Find User Location
		new Float:uservec[3], Float:targetvec[3];
		GetClientAbsOrigin(client, uservec);
		
		// Look for all Clients
		for(new i=1; i<=MaxClients; i++)
		{
			if(!IsClientInGame(i)){continue;}
			
			// Get Target Location
			GetClientAbsOrigin(i, targetvec);
			
			// Check for close-by targets
			if(GetClientTeam(i) == GetClientTeam(client) && GetVectorDistance(uservec, targetvec, false) < distance)
			{
				new Float:force[3];
				GetEntPropVector(i, Prop_Data, "m_vecVelocity", force);
				force[2] = 500.0;
				SDKHooks_TakeDamage(i, enemy, enemy, ((dmg*damageoriginal)/(res*2)), DMG_GENERIC, weapon, force, NULL_VECTOR);
			}
		}
	}//
}
public void TF2_OnConditionRemoved(client, TFCond:cond)
{
	if(cond == TFCond_TeleportedGlow){
		TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.01);
	}
}
public OnEntityCreated(entity, const char[] classname)
{
	if(StrEqual(classname, "obj_sentrygun"))
    {
		if(IsValidEntity(entity))
		{
			SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamagePre_Sentry); 
		}
	}
	if(StrEqual(classname, "tf_projectile_energy_ball"))
	{
		if(IsValidEntity(entity))
		{
			CreateTimer(0.0, delay, EntIndexToEntRef(entity)); 
		}
	}
}
public Action:delay(Handle:timer, any:ref) 
{ 
    new entity = EntRefToEntIndex(ref); 

    if(IsValidEdict(entity)) 
    { 
		int client;
		client = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
		new ClientWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		new Address:projspeed = TF2Attrib_GetByName(ClientWeapon, "Projectile speed increased");
		if(projspeed != Address_Null)
		{
			new Float:vAngles[3]; // original
			new Float:vPosition[3]; // original
			GetClientEyeAngles(client, vAngles);
			GetClientEyePosition(client, vPosition);
			decl Float:vBuffer[3];
			GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
			decl Float:vVelocity[3];
			new Float:projspd = TF2Attrib_GetValue(projspeed);
			vVelocity[0] = vBuffer[0]*projspd*1100.0;
			vVelocity[1] = vBuffer[1]*projspd*1100.0;
			vVelocity[2] = vBuffer[2]*projspd*1100.0;
			TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, vVelocity);
		}
    } 
}
public Action:OnTakeDamagePre_Sentry(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom) 
{
	new owner = GetEntPropEnt(victim, Prop_Send, "m_hBuilder");
	if(IsValidClient(owner))
	{
		new melee = (GetPlayerWeaponSlot(owner,2));
		new Address:bulletspershot = TF2Attrib_GetByName(melee, "bullets per shot bonus");
		if(bulletspershot != Address_Null)
		{
			new Float:bps = TF2Attrib_GetValue(bulletspershot);
			damage *= bps;
		}
	}
	return Plugin_Changed;
}  

