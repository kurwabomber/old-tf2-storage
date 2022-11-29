/**
* File: War3Source_Lurker.sp
* Description: The Lurker race for SourceCraft.
* Author(s): xDr.HaaaaaaaXx 
*/

#pragma semicolon 1
#include <sourcemod>
#include <sdktools_tempents>
#include <sdktools_functions>
#include <sdktools_entinput>

#include "W3SIncs/War3Source_Interface"

// War3Source stuff
new thisRaceID, SKILL_INVIS, SKILL_SPEED, SKILL_SLOW, SKILL_DMG;

// Chance/Data Arrays
new Float:LurkerDamageMultiplier[5] = { 0.0, 1.6, 1.9, 2.1, 2.4 };
new Float:LurkerSlowSpeed[5] = { 1.0, 0.70, 0.65, 0.60, 0.55 };
new Float:LurkerSlowTime[5] = { 0.0, 2.0, 3.0, 4.0, 5.0 };
new Float:LurkerSpeed[5] = { 1.0, 1.2, 1.24, 1.28, 1.32 };
new Float:LurkerInvis[5] = { 1.0, 0.75, 0.5, 0.25, 0.01 };
new LurkerHealth[5] = { 0, -25, -50, -75, -99 };

public Plugin:myinfo = 
{
	name = "War3Source Race - Lurker",
	author = "xDr.HaaaaaaaXx",
	description = "The Lurker race for War3Source.",
	version = "1.0.0.1",
	url = ""
};

public OnWar3PluginReady()
{
	thisRaceID = War3_CreateNewRace( "Lurker", "lurker" );
	
	SKILL_INVIS = War3_AddRaceSkill( thisRaceID, "Stealth", "Invisible but lose hp", false );
	SKILL_SPEED = War3_AddRaceSkill( thisRaceID, "Training", "More speed", false );
	SKILL_SLOW = War3_AddRaceSkill( thisRaceID, "Exact Shoting", "Slow enemys", false );
	SKILL_DMG = War3_AddRaceSkill( thisRaceID, "Precision", "Extra damage", false );
	
	War3_CreateRaceEnd( thisRaceID );
}

public InitPassiveSkills( client )
{
	if( War3_GetRace( client ) == thisRaceID )
	{
		War3_SetBuff( client, fMaxSpeed, thisRaceID, LurkerSpeed[War3_GetSkillLevel( client, thisRaceID, SKILL_SPEED )] );
		
		War3_SetBuff( client, bDoNotInvisWeapon, thisRaceID, true );
		War3_SetBuff( client, fInvisibilitySkill, thisRaceID, LurkerInvis[War3_GetSkillLevel( client, thisRaceID, SKILL_INVIS )] );
		
// 		SetEntityHealth( client, LurkerHealth[War3_GetSkillLevel( client, thisRaceID, SKILL_INVIS )] );
		War3_SetBuff(client,iAdditionalMaxHealth,thisRaceID,LurkerHealth[War3_GetSkillLevel( client, thisRaceID, SKILL_INVIS )]);
//		War3_SetMaxHP( client, LurkerHealth[War3_GetSkillLevel( client, thisRaceID, SKILL_INVIS )] );
	}
}

public OnRaceChanged( client,oldrace,newrace )
{
	if( newrace != thisRaceID )
	{
		War3_WeaponRestrictTo( client, thisRaceID, "" );
		W3ResetAllBuffRace( client, thisRaceID );
	}
	else
	{	
		War3_WeaponRestrictTo( client, thisRaceID, "weapon_knife,weapon_usp" );
		if( IsPlayerAlive( client ) )
		{
			GivePlayerItem( client, "weapon_usp" );
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
		GivePlayerItem( client, "weapon_usp" );
		InitPassiveSkills( client );
		
	}
	War3_SetBuff( client, fSlow, thisRaceID, 1.0 );
}

public OnWar3EventDeath( victim, attacker )
{
	W3ResetAllBuffRace( victim, thisRaceID );
}

public OnWar3EventPostHurt(victim, attacker, Float:damage, const String:weapon[32], bool:isWarcraft)
{
	if( W3GetDamageIsBullet() && ValidPlayer( victim, true ) && ValidPlayer( attacker, true ) && GetClientTeam( victim ) != GetClientTeam( attacker ) )
	{
		if( War3_GetRace( attacker ) == thisRaceID )
		{
			new skill_level_dmg = War3_GetSkillLevel( attacker, thisRaceID, SKILL_DMG );
			if( !Hexed( attacker, false ) && GetRandomFloat( 0.0, 1.0 ) <= 0.15 && skill_level_dmg > 0 )
			{
				new String:wpnstr[32];
				GetClientWeapon( attacker, wpnstr, 32 );
				if( StrEqual( wpnstr, "weapon_usp" ) )
				{
					if( !W3HasImmunity( victim, Immunity_Skills ) )
					{
						War3_DealDamage( victim, RoundToFloor( damage * LurkerDamageMultiplier[War3_GetSkillLevel( attacker, thisRaceID, SKILL_DMG )] / 2 ), attacker, DMG_BULLET, "lurker_crit" );
						W3FlashScreen( victim, RGBA_COLOR_RED );

						W3PrintSkillDmgHintConsole( victim, attacker, War3_GetWar3DamageDealt(), SKILL_DMG );
					}
				}
			}
			
			new skill_level_slow = War3_GetSkillLevel( attacker, thisRaceID, SKILL_SLOW );
			if( !Hexed( attacker, false ) && GetRandomFloat( 0.0, 1.0 ) <= 0.30 && skill_level_slow > 0 )
			{
				new String:wpnstr[32];
				GetClientWeapon( attacker, wpnstr, 32 );
				if( StrEqual( wpnstr, "weapon_usp" ) )
				{
					if( !W3HasImmunity( victim, Immunity_Skills ) )
					{
						War3_SetBuff( victim, fSlow, thisRaceID, LurkerSlowSpeed[War3_GetSkillLevel( attacker, thisRaceID, SKILL_SLOW )] );
						
						CreateTimer( LurkerSlowTime[War3_GetSkillLevel( attacker, thisRaceID, SKILL_SLOW )], ResetSlow, victim );
						
						W3FlashScreen( victim, RGBA_COLOR_BLUE );
					}
				}
			}
		}
	}
}

public Action:ResetSlow( Handle:timer, any:client )
{
	if( ValidPlayer( client, true ) )
	{
		War3_SetBuff( client, fSlow, thisRaceID, 1.0 );
	}
}