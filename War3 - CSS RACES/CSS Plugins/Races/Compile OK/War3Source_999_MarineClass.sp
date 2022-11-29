/**
* File: War3Source_Marine_Class.sp
* Description: The Marine Class race for SourceCraft.
* Author(s): xDr.HaaaaaaaXx
*/

#pragma semicolon 1
#include <sourcemod>
#include <sdktools_tempents>
#include <sdktools_functions>
#include <sdktools_tempents_stocks>
#include <sdktools_entinput>
#include <sdktools_sound>
#include "W3SIncs/War3Source_Interface"
#include "W3SIncs/haaaxfunctions"



// War3Source stuff
new thisRaceID;

// Chance/Data Arrays
new Float:DamageMultiplier[5] = { 0.0, 0.25, 0.5, 0.75, 1.0 };
new Float:BeaconChance[5] = { 0.0, 0.50, 0.60, 0.70, 0.80 };
new Float:DamageChance[5] = { 0.0, 0.15, 0.20, 0.25, 0.30 };
new StrikeDamage[5] = { 0, 15, 20, 25, 30 };
new String:ult_sound[] = "weapons/stinger_fire1.wav";
new HaloSprite, UltSprite, ExplosionModel;

new SKILL_GUN, SKILL_TRAINING, SKILL_BEACON, ULT_ART;

public Plugin:myinfo = 
{
	name = "War3Source Race - Marine Class",
	author = "xDr.HaaaaaaaXx",
	description = "The Marine Class race for War3Source.",
	version = "1.0.0.1",
	url = ""
};

public OnMapStart()
{
	HaloSprite = PrecacheModel( "materials/sprites/halo01.vmt" );
	UltSprite = PrecacheModel( "materials/sprites/lgtning.vmt" );
	ExplosionModel = PrecacheModel( "materials/sprites/zerogxplode.vmt", false );
	War3_PrecacheSound( ult_sound );
}

public OnWar3PluginReady()
{
	thisRaceID = War3_CreateNewRace( "Marine Class", "marineclass" );
	
	SKILL_GUN = War3_AddRaceSkill( thisRaceID, "Gun", "You spawning with a MP5Navy/Famas/M4A1/M249", false );	
	SKILL_TRAINING = War3_AddRaceSkill( thisRaceID, "Aim Training", "You know where to aim and can make 75%-120% extra dmg by 35%-50% chance", false );	
	SKILL_BEACON = War3_AddRaceSkill( thisRaceID, "Hot Spot", "You got 50%-80% of makeing a beacon around enemy", false );
	ULT_ART = War3_AddRaceSkill( thisRaceID, "Artillery", "You can hit an enemy from everywhere whit a artillery cannon and gain 30 hp.", true );
	
	W3SkillCooldownOnSpawn( thisRaceID, ULT_ART, 5.0, _ );
	
	War3_CreateRaceEnd( thisRaceID );
}

public InitPassiveSkills( client )
{
	if( War3_GetRace( client ) == thisRaceID )
	{
		War3_SetBuff( client, iAdditionalMaxHealthNoHPChange, thisRaceID, 100);
		//War3_SetMaxHP( client, War3_GetMaxHP( client ) + 100 );
	}
}

public OnRaceChanged( client,oldrace,newrace )
{
	if( newrace == thisRaceID )
	{
		if( IsPlayerAlive( client ) )
		{
			InitPassiveSkills( client );
		}
	}
	else
	{
		W3ResetAllBuffRace( client, thisRaceID );
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
		if( War3_GetSkillLevel( client, thisRaceID, SKILL_GUN ) == 1 )
			GivePlayerItem( client, "weapon_mp5navy" );
		if( War3_GetSkillLevel( client, thisRaceID, SKILL_GUN ) == 2 )
			GivePlayerItem( client, "weapon_famas" );
		if( War3_GetSkillLevel( client, thisRaceID, SKILL_GUN ) == 3 )
			GivePlayerItem( client, "weapon_m4a1" );
		if( War3_GetSkillLevel( client, thisRaceID, SKILL_GUN ) == 4 )
			GivePlayerItem( client, "weapon_m249" );
	}
}

public OnWar3EventPostHurt(victim, attacker, Float:damage, const String:weapon[32], bool:isWarcraft)
{
	if( W3GetDamageIsBullet() && ValidPlayer( victim, true ) && ValidPlayer( attacker, true ) && GetClientTeam( victim ) != GetClientTeam( attacker ) )
	{
		if( War3_GetRace( attacker ) == thisRaceID && !W3HasImmunity(victim,Immunity_Skills))
		{
			new skill_training = War3_GetSkillLevel( attacker, thisRaceID, SKILL_TRAINING );
			if( !Hexed( attacker, false ) && GetRandomFloat( 0.0, 1.0 ) <= DamageChance[skill_training] && skill_training > 0 )
			{
				new Float:start_pos[3];
				new Float:target_pos[3];
				
				GetClientAbsOrigin( attacker, start_pos );
				GetClientAbsOrigin( victim, target_pos );
				
				start_pos[2] += 40;
				target_pos[2] += 40;
				
				TE_SetupBeamPoints( start_pos, target_pos, HaloSprite, HaloSprite, 0, 0, 1.0, 5.0, 5.0, 0, 0.0, { 133, 177, 155, 255 }, 40 );
				TE_SendToAll();
				War3_DealDamage( victim, RoundToFloor( damage * DamageMultiplier[skill_training] ), attacker, DMG_BULLET, "marine_crit" );
				
				W3PrintSkillDmgHintConsole( victim, attacker, War3_GetWar3DamageDealt(), SKILL_TRAINING );
				W3FlashScreen( victim, RGBA_COLOR_RED );
			}
			
			new skill_beacon = War3_GetSkillLevel( attacker, thisRaceID, SKILL_BEACON );
			if( !Hexed( attacker, false ) && GetRandomFloat( 0.0, 1.0 ) <= BeaconChance[skill_beacon] && skill_beacon > 0 )
			{
				ServerCommand( "sm_beacon #%d 1", GetClientUserId( victim ) );
				
				new Float:start_pos[3];
				new Float:target_pos[3];
				
				GetClientAbsOrigin( attacker, start_pos );
				GetClientAbsOrigin( victim, target_pos );
				
				start_pos[2] += 40;
				target_pos[2] += 40;
				
				TE_SetupBeamPoints( start_pos, target_pos, HaloSprite, HaloSprite, 0, 0, 1.0, 5.0, 5.0, 0, 0.0, { 132, 143, 189, 255 }, 40 );
				TE_SendToAll();
			}
		}
	}
}

public OnUltimateCommand( client, race, bool:pressed )
{
	if( race == thisRaceID && pressed && IsPlayerAlive( client ) && !Silenced( client ) )
	{
		new ult_level = War3_GetSkillLevel( client, race, ULT_ART );
		if( ult_level > 0 )
		{
			if( War3_SkillNotInCooldown( client, thisRaceID, ULT_ART, true ) )
			{
				Strike( client );
			}
		}
		else
		{
			W3MsgUltNotLeveled( client );
		}
	}
}

stock Strike( client )
{
	new ult_level = War3_GetSkillLevel( client, thisRaceID, ULT_ART );
	new bestTarget;
	
	if( GetClientTeam( client ) == TEAM_T )
		bestTarget = War3_GetRandomPlayer(client, "#ct", true, true );
	if( GetClientTeam( client ) == TEAM_CT )
		bestTarget = War3_GetRandomPlayer(client, "#t", true, true );
	
	if( bestTarget == 0 )
	{
		PrintHintText( client, "No Target Found" );
	}
	else
	{
		War3_DealDamage( bestTarget, StrikeDamage[ult_level], client, DMG_BULLET, "marine_artillery" );
		War3_HealToMaxHP( client, StrikeDamage[ult_level] );

		W3PrintSkillDmgHintConsole( bestTarget, client, War3_GetWar3DamageDealt(), ULT_ART );
		War3_ShakeScreen( bestTarget, 3.0, 250.0, 40.0 );
		W3FlashScreen( bestTarget, RGBA_COLOR_RED );
		
		EmitSoundToAll( ult_sound, client );
		
		new Float:TargetPos[3];
		new Float:ClientPos[3];
		
		GetClientAbsOrigin( bestTarget, TargetPos );
		GetClientAbsOrigin( client, ClientPos );
		
		TargetPos[2] += 50.0;
		ClientPos[2] += 40.0;
		
		TE_SetupExplosion( TargetPos, ExplosionModel, 10.0, 1, 0, 333, 160 );
		TE_SendToAll();
		
		TE_SetupBeamRingPoint( ClientPos, 20.0, 50.0, UltSprite, HaloSprite, 0, 0, 3.0, 60.0, 0.8, { 0, 200, 100, 200 }, 1, FBEAM_ISACTIVE );
		TE_SendToAll();

		War3_CooldownMGR( client, 30.0, thisRaceID, ULT_ART);
	}
}