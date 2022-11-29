/**
* File: War3Source_Flame_Predator.sp
* Description: The Flame Predator race for SourceCraft.
* Author(s): xDr.HaaaaaaaXx
*/

#pragma semicolon 1
#include <tf2>
#include <sourcemod>
#include <sdktools>
#include <sdktools_stocks>
#include <sdktools_tempents>
#include <sdktools_functions>
#include <sdktools_tempents_stocks>
#include <sdktools_entinput>
#include <sdktools_sound>

#include "W3SIncs/War3Source_Interface"

// War3Source stuff
new thisRaceID, SKILL_SPEEDHP, SKILL_INVIS, SKILL_LEVI, SKILL_DROP, SKILL_FIRE, SKILL_SUICIDE;

// Chance/Data Arrays
new Float:InfernoRadius[5] = { 0.0, 200.0, 233.0, 275.0, 333.0 };
new Float:InfernoDamage[5] = { 0.0, 166.0, 200.0, 233.0, 266.0 };
new Float:InfernoChance[5] = { 0.0, 0.20, 0.27, 0.33, 0.40 };
new Float:FlameSpeed[5] = { 1.0, 1.1, 1.2, 1.3, 1.4 };
new Float:FlameInvis[5] = { 1.0, 0.55, 0.50, 0.45, 0.40 };
new Float:DropChance[5] = { 0.0, 0.18, 0.23, 0.27, 0.30 };
new Float:BurnChance[5] = { 0.0, 0.15, 0.20, 0.25, 0.30 };
new Float:FlameGravity[5] = { 1.0, 0.7, 0.6, 0.5, 0.4 };
new Float:BurnTime[5] = { 0.0, 2.0, 2.5, 3.0, 3.5 };
new FlameHP[5] = { 0, 25, 30, 35, 40 };
new Float:InfernoLocation[MAXPLAYERS][3];

// Sounds
new String:InfernoSound[] = "war3source/particle_suck1.wav";

// Other
new HaloSprite, BeamSprite, ExplosionModel;

public Plugin:myinfo = 
{
	name = "War3Source Race - Flame Predator",
	author = "xDr.HaaaaaaaXx",
	description = "The Flame Predator race for War3Source.",
	version = "1.0.0.1",
	url = ""
};

public OnPluginStart()
{
	LoadTranslations( "w3s.race.undead.phrases" );
}

public OnMapStart()
{	
	ExplosionModel = PrecacheModel( "materials/sprites/zerogxplode.vmt", false );
	BeamSprite = PrecacheModel( "materials/sprites/lgtning.vmt" );
	HaloSprite = PrecacheModel( "materials/sprites/halo01.vmt" );
	PrecacheSound( "weapons/explode5.wav", false );
	War3_AddCustomSound( InfernoSound );
}

public OnWar3PluginReady()
{
	thisRaceID = War3_CreateNewRace( "Flame Predator", "flamepredator" );
	
	SKILL_SPEEDHP = War3_AddRaceSkill( thisRaceID, "Berserk", "Pump yourself with adrenaline to gain 45-60% more speed and 25-40 HP", false );	
	SKILL_INVIS = War3_AddRaceSkill( thisRaceID, "Cloak of Invisibility", "Put on your cloak to be 76-88% invisible.", false );	
	SKILL_LEVI = War3_AddRaceSkill( thisRaceID, "Levitation", "Reduce your gravity by 30-60%", false );
	SKILL_DROP = War3_AddRaceSkill( thisRaceID, "Claw Attack", "Hit an enemy, 30-40% chance to force a stun.", false );
	SKILL_FIRE = War3_AddRaceSkill( thisRaceID, "Burning Blade", "Hit an enemy, 20-35% chance that he catch on fire", false );
	SKILL_SUICIDE = War3_AddRaceSkill( thisRaceID, "Burning Inferno", "20-40% chance that you deal 166-266 damage in 20-33ft range on death", true );
	
	War3_CreateRaceEnd( thisRaceID );
}

public InitPassiveSkills( client )
{
	if( War3_GetRace( client ) == thisRaceID )
	{
		War3_SetBuff( client, fInvisibilitySkill, thisRaceID, FlameInvis[War3_GetSkillLevel( client, thisRaceID, SKILL_INVIS )] );
		War3_SetBuff( client, fMaxSpeed, thisRaceID, FlameSpeed[War3_GetSkillLevel( client, thisRaceID, SKILL_SPEEDHP )] );
		War3_SetBuff( client, fLowGravitySkill, thisRaceID, FlameGravity[War3_GetSkillLevel( client, thisRaceID, SKILL_LEVI )] );
		War3_SetBuff(client, iAdditionalMaxHealth,thisRaceID, FlameHP[War3_GetSkillLevel( client, thisRaceID, SKILL_SPEEDHP )]);	

		if( War3_GetMaxHP( client ) > GetClientHealth( client ) )
		{
			War3_HealToMaxHP( client, ( War3_GetMaxHP( client ) - GetClientHealth( client ) ) );
		}
	}
}

public OnRaceChanged( client, oldrace, newrace )
{
	if( newrace != thisRaceID )
	{
		War3_WeaponRestrictTo( client, thisRaceID, "" );
		W3ResetAllBuffRace( client, thisRaceID );
	}
	else
	{	
		TF2_RemoveWeaponSlot(client, 0);
		TF2_RemoveWeaponSlot(client, 1);
		if( ValidPlayer( client, true ) )
		{
			InitPassiveSkills( client );
		}
	}
}

public OnSkillLevelChanged( client, race, skill, newskilllevel )
{
	InitPassiveSkills( client );
}

public OnWar3EventSpawn( client )
{
	new race = War3_GetRace( client );
	if( race == thisRaceID )
	{
		InitPassiveSkills( client );
		TF2_RemoveWeaponSlot(client, 0);
		TF2_RemoveWeaponSlot(client, 1);
	}
}

public OnWar3EventPostHurt(victim, attacker, Float:damage, const String:weapon[32], bool:isWarcraft)
{
	if( W3GetDamageIsBullet() && ValidPlayer( victim, true ) && ValidPlayer( attacker, true ) && GetClientTeam( victim ) != GetClientTeam( attacker ) )
	{
		if( War3_GetRace( attacker ) == thisRaceID )
		{
			new skill_drop = War3_GetSkillLevel( attacker, thisRaceID, SKILL_DROP );
			if( !Hexed( attacker, false ) && GetRandomFloat( 0.0, 1.0 ) <= DropChance[skill_drop] )
			{
				if( !W3HasImmunity( victim, Immunity_Skills ) )
				{
					TF2_AddCondition(victim, TFCond_Dazed, 0.04)
				}
			}
			
			new skill_fire = War3_GetSkillLevel( attacker, thisRaceID, SKILL_FIRE );
			if( !Hexed( attacker, false ) && GetRandomFloat( 0.0, 1.0 ) <= BurnChance[skill_fire] )
			{
				if( !W3HasImmunity( victim, Immunity_Skills ) )
				{
					IgniteEntity( victim, BurnTime[skill_fire] );
				}
			}
		}
	}
}

public OnWar3EventDeath( victim, attacker )
{
	new race = War3_GetRace( victim );
	new skill = War3_GetSkillLevel( victim, thisRaceID, SKILL_SUICIDE );
	if( race == thisRaceID && skill > 0 && !Hexed( victim ) && GetRandomFloat( 0.0, 1.0 ) <= InfernoChance[skill] )
	{
		GetClientAbsOrigin( victim, InfernoLocation[victim] );
		CreateTimer( 0.15, DelayedInferno, victim );
	}
	W3ResetAllBuffRace( victim, thisRaceID );
}

public Action:DelayedInferno( Handle:timer, any:client )
{
	SuicideBomber( client, War3_GetSkillLevel( client, thisRaceID, SKILL_SUICIDE ) );
}

public SuicideBomber( client, level )
{
	if( level > 0 )
	{
		new Float:radius = InfernoRadius[level];
		new our_team = GetClientTeam( client ); 
		new Float:client_location[3];
		for( new i = 0; i < 3; i++ )
		{
			client_location[i] = InfernoLocation[client][i];
		}
		
		TE_SetupExplosion( client_location, ExplosionModel, 10.0, 1, 0, RoundToFloor( radius ), 160 );
		TE_SendToAll();
		
		client_location[2] -= 40.0;
		
		TE_SetupBeamRingPoint( client_location, 10.0, radius, BeamSprite, HaloSprite, 0, 15, 0.5, 10.0, 10.0, { 255, 255, 255, 33 }, 120, 0 );
		TE_SendToAll();
		
		new beamcolor[] = { 0, 200, 255, 255 };
		if( our_team == 2 )
		{
			beamcolor[0] = 255;
			beamcolor[1] = 0;
			beamcolor[2] = 0;
		}
		TE_SetupBeamRingPoint( client_location, 20.0, radius + 10.0, BeamSprite, HaloSprite, 0, 15, 0.5, 10.0, 10.0, beamcolor, 120, 0 );
		TE_SendToAll();
		
		client_location[2] += 40.0;
		
		EmitSoundToAll( InfernoSound, client );
		EmitSoundToAll( "weapons/explode5.wav", client );
	
		new Float:location_check[3];
		for( new x = 1; x <= MaxClients; x++ )
		{
			if( ValidPlayer( x, true ) && client != x )
			{
				new team = GetClientTeam( x );
				if( team != our_team )
				{
					GetClientAbsOrigin( x, location_check );
					new Float:distance = GetVectorDistance( client_location, location_check );
					if( distance < radius )
					{
						if( !W3HasImmunity( x, Immunity_Ultimates ) )
						{
							new Float:factor = ( radius - distance ) / radius;
							new damage;
							damage = RoundFloat( InfernoDamage[level] * factor );
							
							War3_DealDamage( x, damage, client, _, "suicidebomber", W3DMGORIGIN_ULTIMATE, W3DMGTYPE_PHYSICAL );
							PrintToConsole( client, "%T", "Suicide bomber damage: {amount} to {amount} at distance {amount}", client, War3_GetWar3DamageDealt(), x, distance );
							
							War3_ShakeScreen( x, 3.0 * factor, 250.0 * factor, 30.0 );
							W3FlashScreen( x, RGBA_COLOR_RED );
						}
						else
						{
							PrintToConsole( client, "%T", "Could not damage player {player} due to immunity", client, x );
						}
					}
				}
			}
		}
	}
}