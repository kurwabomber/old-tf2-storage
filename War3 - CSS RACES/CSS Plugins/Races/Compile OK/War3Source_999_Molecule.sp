/**
* File: War3Source_Molecule.sp
* Description: The Molecule race for SourceCraft.
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

// War3Source stuff
new thisRaceID;

// Chance/Data Arrays
new Float:DamageMultiplier[6] = { 0.0, 0.15, 0.175, 0.2, 0.225, 0.25 };
new Float:EvadeChance[6] = { 0.0, 0.03, 0.06, 0.09, 0.12, 0.15 };
new Float:MoleculeSpeed[6] = { 1.0, 1.05, 1.10, 1.15, 1.2, 1.25 };
new Float:RandMax[6] = { 0.0, 0.08, 0.16, 0.24, 0.32, 0.4 };
new Float:RandMin = 0.0;
new Float:UltDuration[6] = { 0.0, 1.0, 1.5, 2.0, 2.5, 3.0 };
new String:spawn[] = "weapons/explode3.wav";
new ShieldSprite, AttackSprite, EvadeSprite;
new bool:GOD[64];

new SKILL_SPEED, SKILL_DMG, SKILL_EVADE, ULT_FIELD;

public Plugin:myinfo = 
{
	name = "War3Source Race - Molecule",
	author = "xDr.HaaaaaaaXx",
	description = "Molecule race for War3Source.",
	version = "1.0.1",
	url = ""
};

public OnMapStart()
{
	War3_PrecacheSound( spawn );
	ShieldSprite = PrecacheModel( "sprites/strider_blackball.vmt" );
	AttackSprite = PrecacheModel( "sprites/physring1.vmt" );
	EvadeSprite = PrecacheModel( "sprites/blueshaft1.vmt" );
}

public OnWar3PluginReady()
{
	thisRaceID = War3_CreateNewRace( "Molecule", "molecule" );
	
	SKILL_SPEED = War3_AddRaceSkill( thisRaceID, "Speed", "Gain speed up to 1.25", false, 5 );	
	SKILL_DMG = War3_AddRaceSkill( thisRaceID, "Electric Shock", "Electrocute your enemy", false, 5 );	
	SKILL_EVADE = War3_AddRaceSkill( thisRaceID, "Evade", "Chance of evading shots", false, 5 );
	ULT_FIELD = War3_AddRaceSkill( thisRaceID, "Force Field", "Enclose yourself inside a bullet proof sphere", true, 5 );
	
	W3SkillCooldownOnSpawn( thisRaceID, ULT_FIELD, 5.0, _ );
	
	War3_CreateRaceEnd( thisRaceID );
	
	War3_AddSkillBuff(thisRaceID, SKILL_EVADE, fDodgeChance, EvadeChance);
}

public InitPassiveSkills( client )
{
	if( War3_GetRace( client ) == thisRaceID )
	{
		War3_SetBuff( client, fMaxSpeed, thisRaceID, MoleculeSpeed[War3_GetSkillLevel( client, thisRaceID, SKILL_SPEED )] );
	}
}

public OnRaceChanged( client, oldrace, newrace )
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
		EmitSoundToAll( spawn, client );
	}
}

public OnWar3EventDeath( victim, attacker )
{
	W3ResetAllBuffRace( victim, thisRaceID );
	GOD[victim] = false;
}

public OnWar3EventPostHurt(victim, attacker, Float:damage, const String:weapon[32], bool:isWarcraft)
{
	if( W3GetDamageIsBullet() && ValidPlayer( victim, true ) && ValidPlayer( attacker, true ) && GetClientTeam( victim ) != GetClientTeam( attacker ) )
	{
		if( War3_GetRace( attacker ) == thisRaceID )
		{
			new skill_dmg = War3_GetSkillLevel( attacker, thisRaceID, SKILL_DMG );
			if( !Hexed( attacker, false ) && skill_dmg > 0 && GetRandomFloat( RandMin, 1.0 ) <= RandMax[skill_dmg] )
			{
				new String:wpnstr[32];
				GetClientWeapon( attacker, wpnstr, 32 );
				if( !StrEqual( wpnstr, "weapon_knife" ) )
				{
					War3_DealDamage( victim, RoundToFloor( damage * DamageMultiplier[skill_dmg] ), attacker, DMG_BULLET, "electric_crit" );
				
					W3PrintSkillDmgHintConsole( victim, attacker, War3_GetWar3DamageDealt(), SKILL_DMG );
					
					W3FlashScreen( victim, RGBA_COLOR_RED );
					
					new Float:pos[3];
					
					GetClientAbsOrigin( victim, pos );
					
					pos[2] += 15;
					
					TE_SetupGlowSprite( pos, AttackSprite, 3.0, 0.25, 255 );
					TE_SendToAll();
				}
			}
		}
	}
}


public OnW3TakeDmgAllPre( victim, attacker, Float:damage )
{
	if( IS_PLAYER( victim ) && IS_PLAYER( attacker ) && victim > 0 && attacker > 0 && attacker != victim )
	{
		new vteam = GetClientTeam( victim );
		new ateam = GetClientTeam( attacker );
		if( vteam != ateam )
		{
			new race_victim = War3_GetRace( victim );
			new ult_level = War3_GetSkillLevel( victim, thisRaceID, ULT_FIELD );
			if( race_victim == thisRaceID && ult_level > 0 && GOD[victim] )
			{
				if( !W3HasImmunity( attacker, Immunity_Ultimates ) )
				{
					War3_DamageModPercent( 0.0 );
					
					new Float:startpos[3];
					new Float:endpos[3];
					
					GetClientAbsOrigin( attacker, startpos );
					GetClientAbsOrigin( victim, endpos );
					
					TE_SetupBeamPoints( startpos, endpos, EvadeSprite, EvadeSprite, 0, 0, 1.0, 1.0, 1.0, 0, 0.0, { 255, 255, 255, 255 }, 0 );
					TE_SendToAll();
				}
				else
				{
					W3MsgEnemyHasImmunity( victim, true );
				}
			}
		}
	}
}

public OnUltimateCommand( client, race, bool:pressed )
{
	if( race == thisRaceID && pressed && IsPlayerAlive( client ) && !Silenced( client ) )
	{
		new ult_level = War3_GetSkillLevel( client, race, ULT_FIELD );
		if( ult_level > 0 )
		{
			if( War3_SkillNotInCooldown( client, thisRaceID, ULT_FIELD, true ) )
			{
				War3_SetBuff( client, bNoMoveMode, thisRaceID, true );
				
				GOD[client] = true;
				
				CreateTimer( UltDuration[ult_level], StopGod, client );
				
				War3_CooldownMGR( client, UltDuration[ult_level] + 15.0, thisRaceID, ULT_FIELD, _, _ );
				
				new Float:pos[3];
				
				GetClientAbsOrigin( client, pos );
				
				pos[2] += 15;
				
				TE_SetupGlowSprite( pos, ShieldSprite, UltDuration[ult_level], 1.5, 255 );
				TE_SendToAll();
			}
		}
		else
		{
			W3MsgUltNotLeveled( client );
		}
	}
}

public Action:StopGod( Handle:timer, any:client )
{
	if( ValidPlayer( client, true ) )
	{
		War3_SetBuff( client, bNoMoveMode, thisRaceID, false );
		
		GOD[client] = false;
	}
}