#pragma semicolon 1

#include "W3SIncs/War3Source_Interface"
#include <sdkhooks>

public Plugin:myinfo = 
{
	name = "War3Source Race - Grenadier",
	author = "Ted Theodore Logan",
	description = "The grenadier race for War3Source.",
	version = "1.0.1",
};

/* Changelog
 * 1.0 - Release!
 */

//=======================================================================
//                             VARIABLES
//=======================================================================

new thisRaceID;
new SKILL_HE, ULT_LAUNCHER, SKILL_FLASH, SKILL_REGEN;
new g_CollisionOffset;

// Enhanced HE
#define MDL_FRAG "models/weapons/w_eq_fraggrenade_thrown.mdl"
#define SND_FRAG "weapons/hegrenade/explode5.wav"
new MiniNadeDamage = 20; // How much damage
new MiniNadeRadius = 150; // Radius of the explosion

// Grenade Launcher
#define SOUND_EXPLOSION "weapons/explode3.wav"
#define SOUND_NADELAUNCHER "weapons/grenade_launcher1.wav"
#define MDL_NADELAUNCHER "models/Items/ar2_grenade.mdl"
new Float:GRENADE_SPEED = 2000.0;
new Float:LauncherCooldown[5]={0.0, 30.0, 25.0, 20.0, 15.0};

// Enhanced Flash
new g_iMagnitude[MAXPLAYERS]; // How "intense" the flash on a player is (max 255)
new bool:g_bFlashed[MAXPLAYERS]; // Is this player flashed?
new Float:FlashDamage[5]={0.0, 12.0, 9.0, 6.0, 3.0}; // How much damage (flash intensity / value)

//=======================================================================
//                                 INIT
//=======================================================================

public OnWar3PluginReady(){
	thisRaceID = War3_CreateNewRace("Grenadier", "grenadier");
	SKILL_HE = War3_AddRaceSkill(thisRaceID, "Frag grenade", "Create 1/2/3/4 frag grenades when throwing a HE.", false, 4);
	SKILL_FLASH = War3_AddRaceSkill(thisRaceID, "Enhanced Flash", "Your flash grenades deal damage to enemys.", false, 4);
	SKILL_REGEN = War3_AddRaceSkill(thisRaceID, "Grenade recovery", "You passively gain Smoke/Flash/HE grenades", false, 3); 
	ULT_LAUNCHER = War3_AddRaceSkill(thisRaceID, "Grenade Launcher (Ultimate)", "Use your trusty grenade launcher. Cooldown 30/25/20/15 seconds", true, 4);
	
	War3_CreateRaceEnd(thisRaceID);
}

public OnPluginStart()
{
	if(War3_GetGame() != Game_CS)
		SetFailState("Only works in CS:S");
	
	HookEvent("player_blind", Event_PlayerBlind);
	HookEvent("flashbang_detonate", Event_FlashbangDetonate);
	HookEvent("hegrenade_detonate", Event_HEGrenadeDetonate);
	
	CreateTimer(20.0, GrenadeLoop, _, TIMER_REPEAT);
	
	g_CollisionOffset = FindSendPropInfo("CBaseEntity", "m_CollisionGroup");  
}

public OnMapStart()
{
	PrecacheSound(SND_FRAG, true);
	PrecacheModel(MDL_NADELAUNCHER);

	PrecacheSound(SOUND_NADELAUNCHER, true);
	PrecacheSound(SOUND_EXPLOSION, true);
}

//=======================================================================
//                                 ENHANCED HE
//=======================================================================

/* Code borrowed from homing missles http://forums.alliedmods.net/showthread.php?p=986941 */
public Action:ExplodeMiniGrenade(Handle:h, any:grenade)
{
	new Float:GrenadePos[3];
	GetEntPropVector(grenade, Prop_Send, "m_vecOrigin", GrenadePos);
	
	new GrenadeOwner = GetEntPropEnt(grenade, Prop_Send, "m_hThrower");
	new GrenadeOwnerTeam = GetEntProp(grenade, Prop_Send, "m_iTeamNum");
	
	new ExplosionIndex = CreateEntityByName("env_explosion");
	if (ExplosionIndex != -1)
	{
		DispatchKeyValue(ExplosionIndex, "classname", "hegrenade_projectile");
		
		SetEntProp(ExplosionIndex, Prop_Data, "m_spawnflags", 6146);
		SetEntProp(ExplosionIndex, Prop_Data, "m_iMagnitude", MiniNadeDamage);
		SetEntProp(ExplosionIndex, Prop_Data, "m_iRadiusOverride", MiniNadeRadius);
		
		DispatchSpawn(ExplosionIndex);
		ActivateEntity(ExplosionIndex);
		
		TeleportEntity(ExplosionIndex, GrenadePos, NULL_VECTOR, NULL_VECTOR);
		SetEntPropEnt(ExplosionIndex, Prop_Send, "m_hOwnerEntity", GrenadeOwner);
		SetEntProp(ExplosionIndex, Prop_Send, "m_iTeamNum", GrenadeOwnerTeam);
		
		EmitSoundToAll(SND_FRAG, ExplosionIndex, 1, 90);
		
		AcceptEntityInput(ExplosionIndex, "Explode");
		
		DispatchKeyValue(ExplosionIndex, "classname", "env_explosion");
		
		AcceptEntityInput(ExplosionIndex, "Kill");
	}
	
	AcceptEntityInput(grenade, "Kill");
}

public Event_HEGrenadeDetonate(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(War3_GetRace(client) == thisRaceID)
	{
		new skill = War3_GetSkillLevel(client, thisRaceID, SKILL_HE);
		if(skill > 0)
		{
			new Float:pos[3];
			pos[0] = GetEventFloat(event, "x");
			pos[1] = GetEventFloat(event, "y");
			pos[2] = GetEventFloat(event, "z") + 20.0;
			
			new ent;
			new Float:velocity[3];
			
			for(new i = 0; i < skill; i++)
			{
				ent = CreateEntityByName("hegrenade_projectile");
				if (IsValidEntity(ent))
				{
					// Thrower
					SetEntPropEnt(ent, Prop_Send, "m_hThrower", client);
					SetEntProp(ent, Prop_Send, "m_iTeamNum", GetClientTeam(client));
					// Noblock
					SetEntData(ent, g_CollisionOffset, 2, 1, true);
					
					SetEntityModel(ent, MDL_FRAG);
					DispatchSpawn(ent);	
					
					velocity[0] = GetRandomFloat() * 500;
					velocity[1] = GetRandomFloat() * 500;
					velocity[2] = GetRandomFloat() * 500;
					
					TeleportEntity(ent, pos, NULL_VECTOR, velocity);
					
					CreateTimer(1.0, ExplodeMiniGrenade, ent);
				}
			}
		}
	}
}

//=======================================================================
//                                 ENHANCED FLASH
//=======================================================================

/* Called when a player is blinded by a flashbang */
public Event_PlayerBlind(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	/* Get the flash magnitude (max is 255) */
	new Float:magnitude = GetEntPropFloat(client, Prop_Send, "m_flFlashMaxAlpha");
	g_iMagnitude[client] = RoundToCeil(magnitude);
	/* Mark the player as being flashed */
	g_bFlashed[client] = true;
}

/* Called when a flashbang has detonated (after the players have already been blinded) */
public Event_FlashbangDetonate(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Thrower
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(War3_GetRace(client) == thisRaceID)
	{
		new skill = War3_GetSkillLevel(client, thisRaceID, SKILL_FLASH);
		if(skill > 0)
		{
			for (new i = 1; i <= MaxClients; i++)
			{
				if (g_bFlashed[i] == true)
				{
					if (ValidPlayer(i, true) && GetClientTeam(i) != GetClientTeam(client))
					{
						new damage = RoundToFloor(g_iMagnitude[i] / FlashDamage[skill]);
						War3_DealDamage(i, damage, client, _, "enhanced flash", W3DMGORIGIN_SKILL, W3DMGTYPE_PHYSICAL);
					}
		
					g_bFlashed[i] = false;
				}
			}
		}
	}
}

//=======================================================================
//                              GRENADE LAUNCHER
//=======================================================================

/* Taken from http://forums.alliedmods.net/showthread.php?t=134402 */
public bool:IsEntityCollidable(entity, bool:includeplayer, bool:includehostage, bool:includeprojectile)
{
	
	decl String:classname[64];
	GetEdictClassname(entity, classname, 64);
	
	if((StrEqual(classname, "player", false) && includeplayer) || (StrEqual(classname, "hostage_entity", false) && includehostage)
		||StrContains(classname, "physics", false) != -1 || StrContains(classname, "prop", false) != -1
		|| StrContains(classname, "door", false)  != -1 || StrContains(classname, "weapon", false)  != -1
		|| StrContains(classname, "break", false)  != -1 || ((StrContains(classname, "projectile", false)  != -1) && includeprojectile)
		|| StrContains(classname, "brush", false)  != -1 || StrContains(classname, "button", false)  != -1
		|| StrContains(classname, "physbox", false)  != -1 || StrContains(classname, "plat", false)  != -1
		|| StrEqual(classname, "func_conveyor", false) || StrEqual(classname, "func_fish_pool", false)
		|| StrEqual(classname, "func_guntarget", false) || StrEqual(classname, "func_lod", false)
		|| StrEqual(classname, "func_monitor", false) || StrEqual(classname, "func_movelinear", false)
		|| StrEqual(classname, "func_reflective_glass", false) || StrEqual(classname, "func_rotating", false)
		|| StrEqual(classname, "func_tanktrain", false) || StrEqual(classname, "func_trackautochange", false)
		|| StrEqual(classname, "func_trackchange", false) || StrEqual(classname, "func_tracktrain", false)
		|| StrEqual(classname, "func_train", false) || StrEqual(classname, "func_traincontrols", false)
		|| StrEqual(classname, "func_vehicleclip", false) || StrEqual(classname, "func_traincontrols", false)
		|| StrEqual(classname, "func_water", false) || StrEqual(classname, "func_water_analog", false)){
		
		return true;
		
	}
	
	return false;
	
}

public OnUltimateCommand(client, race, bool:pressed)
{
	if(ValidPlayer(client, true) && race == thisRaceID && pressed && War3_SkillNotInCooldown(client, thisRaceID, ULT_LAUNCHER, true) && !Silenced(client))
	{
		new skill = War3_GetSkillLevel(client, thisRaceID, ULT_LAUNCHER);
		if(skill > 0)
		{
			new usingweapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
			if(usingweapon != -1)
			{
				if(!GetEntProp(usingweapon, Prop_Data, "m_bInReload") && GetEntPropFloat(usingweapon, Prop_Data, "m_flNextPrimaryAttack") <= GetGameTime() && GetEntPropFloat(client, Prop_Data, "m_flNextAttack") <= GetGameTime())
				{
						SetEntPropFloat(usingweapon, Prop_Data, "m_flNextPrimaryAttack", FloatAdd(GetGameTime(), 1.0));
						
						decl Float:clienteyeangle[3], Float:anglevector[3], Float:clienteyeposition[3], Float:resultposition[3], entity;
						GetClientEyeAngles(client, clienteyeangle);
						GetClientEyePosition(client, clienteyeposition);
						GetAngleVectors(clienteyeangle, anglevector, NULL_VECTOR, NULL_VECTOR);
						NormalizeVector(anglevector, anglevector);
						AddVectors(clienteyeposition, anglevector, resultposition);
						NormalizeVector(anglevector, anglevector);
						ScaleVector(anglevector, GRENADE_SPEED);
						
						decl Float:playerspeed[3];
						GetEntPropVector(client, Prop_Data, "m_vecVelocity", playerspeed);
						AddVectors(anglevector, playerspeed, anglevector);
						
						entity = CreateEntityByName("hegrenade_projectile");
						SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client);
						SetEntProp(entity, Prop_Data, "m_takedamage", 0);
						SetEntProp(entity, Prop_Send, "m_iTeamNum", GetClientTeam(client));
						DispatchSpawn(entity);
						SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client);
						SetEntityModel(entity, MDL_NADELAUNCHER);
						EmitSoundToAll(SOUND_NADELAUNCHER, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, clienteyeposition, NULL_VECTOR, true, 0.0);
	
						SDKHook(entity, SDKHook_StartTouch, GrenadeTouchHook);
						SDKHook(entity, SDKHook_OnTakeDamage, GrenadeDamageHook);
						
						SetEntProp(entity, Prop_Data, "m_takedamage", 2);
						
						TeleportEntity(entity, resultposition, clienteyeangle, anglevector);
						
						new gascloud = CreateEntityByName("env_smoketrail");
						DispatchKeyValueVector(gascloud,"Origin", resultposition);
						DispatchKeyValueVector(gascloud,"Angles", clienteyeangle);
						new Float:smokecolor[3] = {1.0, 1.0, 1.0};
						new Float:endcolor[3] = {0.0, 0.0, 0.0};
						SetEntPropVector(gascloud, Prop_Send, "m_StartColor", smokecolor);
						SetEntPropVector(gascloud, Prop_Send, "m_EndColor", endcolor);
						SetEntPropFloat(gascloud, Prop_Send, "m_Opacity", 0.2);
						SetEntPropFloat(gascloud, Prop_Send, "m_SpawnRate", 48.0);
						SetEntPropFloat(gascloud, Prop_Send, "m_ParticleLifetime", 1.0);
						SetEntPropFloat(gascloud, Prop_Send, "m_StartSize", 5.0);
						SetEntPropFloat(gascloud, Prop_Send, "m_EndSize", 30.0);
						SetEntPropFloat(gascloud, Prop_Send, "m_SpawnRadius", 0.0);
						SetEntPropFloat(gascloud, Prop_Send, "m_MinSpeed", 0.0);
						SetEntPropFloat(gascloud, Prop_Send, "m_MaxSpeed", 10.0);
						DispatchSpawn(gascloud);
						SetVariantString("!activator");
						AcceptEntityInput(gascloud, "SetParent", entity);
						SetEntPropEnt(entity, Prop_Send, "m_hEffectEntity", gascloud);
									
						/* Make the view rock upwards */
						new Float:angle[3] = {0.0, 0.0, 0.0};
						
						angle[0] = -12.0;
						angle[1] = GetRandomFloat(-4.0, 4.0);
						
						decl Float:oldangle[3];
						
						GetEntPropVector(client, Prop_Send, "m_vecPunchAngle", oldangle);
						
						oldangle[0] = oldangle[0] + angle[0];
						oldangle[1] = oldangle[1] + angle[1];
						oldangle[2] = oldangle[2] + angle[2];
						
						SetEntPropVector(client, Prop_Send, "m_vecPunchAngle", oldangle);
						SetEntPropVector(client, Prop_Send, "m_vecPunchAngleVel", angle);
						
						War3_CooldownMGR(client, LauncherCooldown[skill], thisRaceID, ULT_LAUNCHER, true, _);
				}
			}
		}
	}
}

public Action:GrenadeTouchHook(entity, other){
	
	if(other != 0){
		
		if(other == GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")){
			
			return Plugin_Continue;
			
		}else{
		
			if(!IsEntityCollidable(other, true, true, true)){
				
				return Plugin_Continue;
				
			}
			
		}
			
	}
	
	GrenadeActive(entity);
	
	return Plugin_Continue;
	
}

public Action:GrenadeDamageHook(entity, &attacker, &inflictor, &Float:damage, &damagetype){
	
	if(GetEntProp(entity, Prop_Data, "m_takedamage") == 2)
	{
		GrenadeActive(entity);
	}
	
	return Plugin_Continue;
	
}

public makeExplosion(attacker, inflictor, const Float:attackposition[3], magnitude, radiusoverride, Float:damageforce, flags)
{	
	new explosion = CreateEntityByName("env_explosion");
	
	if(explosion != -1)
	{
		DispatchKeyValue(explosion, "classname", "hegrenade_projectile");
		DispatchKeyValueVector(explosion, "Origin", attackposition);
		
		decl String:intbuffer[64];
		IntToString(magnitude, intbuffer, 64);
		DispatchKeyValue(explosion, "iMagnitude", intbuffer);
		
		if(radiusoverride > 0)
		{
			IntToString(radiusoverride, intbuffer, 64);
			DispatchKeyValue(explosion,"iRadiusOverride", intbuffer);
		}
		
		if(damageforce > 0.0)
			DispatchKeyValueFloat(explosion,"DamageForce", damageforce);
		
		if(flags != 0)
		{
			IntToString(flags, intbuffer, 64);
			DispatchKeyValue(explosion,"spawnflags", intbuffer);
		}
		
		DispatchSpawn(explosion);
		
		if(ValidPlayer(attacker))
			SetEntPropEnt(explosion, Prop_Send, "m_hOwnerEntity", attacker);
		if(inflictor != -1)
			SetEntPropEnt(explosion, Prop_Data, "m_hInflictor", inflictor);
		
		AcceptEntityInput(explosion, "Explode");
		DispatchKeyValue(explosion, "classname", "env_explosion");
		AcceptEntityInput(explosion, "Kill");
	}
}

public GrenadeActive(entity){
	
	SDKUnhook(entity, SDKHook_StartTouch, GrenadeTouchHook);
	SDKUnhook(entity, SDKHook_OnTakeDamage, GrenadeDamageHook);
	
	if(GetEntProp(entity, Prop_Data, "m_takedamage") == 2)
	{
		SetEntProp(entity, Prop_Data, "m_takedamage", 0);
		decl Float:entityposition[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", entityposition);
		new client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
		new gasentity = GetEntPropEnt(entity, Prop_Send, "m_hEffectEntity");
		AcceptEntityInput(gasentity, "Kill");
		AcceptEntityInput(entity, "Kill");
		makeExplosion(client, entity, entityposition, 120, 120, 0.0, 0);
		EmitSoundToAll(SOUND_EXPLOSION, SOUND_FROM_WORLD, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, entityposition, NULL_VECTOR, true, 0.0);
	}
}

//=======================================================================
//                              GRENADE RECOVERY
//=======================================================================

// Checks if a player has the passed grenade. If not it gives it to him
giveGrenade(client, String:grenade[])
{
	for(new s=0; s < 10; s++)
	{
		new ent = War3_CachedWeapon(client, s);
		if(ent > 0 && IsValidEdict(ent))
		{
			decl String:wepName[64];
			GetEdictClassname(ent, wepName, sizeof(wepName));
			if(StrEqual(wepName, grenade, false))
			{
				return;
			}
		}
	}
	GivePlayerItem(client, grenade);
	return;
}

public Action:GrenadeLoop(Handle:timer,any:data)
{
	for(new x=1; x <= MaxClients; x++)
	{
		if(ValidPlayer(x, true) && War3_GetRace(x) == thisRaceID)
		{
			new skill = War3_GetSkillLevel(x, thisRaceID, SKILL_REGEN);
			if(skill > 0 )
			{
				switch(skill)
				{
					case(1):
					{
						giveGrenade(x, "weapon_smokegrenade");
					}
					case(2):
					{
						giveGrenade(x, "weapon_smokegrenade");
						giveGrenade(x, "weapon_flashbang");
					}
					case(3):
					{
						giveGrenade(x, "weapon_smokegrenade");
						giveGrenade(x, "weapon_flashbang");
						giveGrenade(x, "weapon_hegrenade");
					}
				}
			}
		}
	}
}