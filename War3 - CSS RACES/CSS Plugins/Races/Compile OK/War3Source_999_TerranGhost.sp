/**
* File: War3Source_Terran_Ghost.sp
* Description: The Terran Ghost race for SourceCraft.
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
new Float:UltDuration[6] = { 0.0, 1.0, 2.0, 2.5, 3.0, 3.5 };
new Float:UltDelay[6] = { 0.0, 25.0, 24.0, 23.0, 22.0, 20.0 };
new Float:ScoutChance[6] = { 0.0, 0.20, 0.40, 0.60, 0.80, 1.0 };
new Float:FreezeChance[6] = { 0.0, 0.10, 0.20, 0.30, 0.40, 0.50 };
new Float:DamageMultiplier[6] = { 0.0, 0.2, 0.4, 0.6, 0.8, 1.0 };
new HaloSprite, BeamSprite;

new bool:bIsLockdown[MAXPLAYERSCUSTOM];

new SKILL_SCOUT, SKILL_FREEZE, SKILL_DMG, ULT_INVIS;

public Plugin:myinfo = 
{
	name = "War3Source Race - Terran Ghost",
	author = "xDr.HaaaaaaaXx",
	description = "Terran Ghost race for War3Source.",
	version = "1.0.0.2",
	url = ""
};

public OnMapStart()
{
	HaloSprite = PrecacheModel( "materials/sprites/halo01.vmt" );
	BeamSprite = PrecacheModel( "materials/sprites/lgtning.vmt" );
}

public OnWar3PluginReady()
{
	thisRaceID = War3_CreateNewRace( "Terran Ghost", "terrghost" );
	
	SKILL_SCOUT = War3_AddRaceSkill( thisRaceID, "Canister", "A chance to spawn with a Scout. (20/40/60/80/100)%", false, 5 );	
	SKILL_FREEZE = War3_AddRaceSkill( thisRaceID, "Lockdown", "A chance of freezing enemies. (10/20/30/40/50)%", false, 5 );	
	SKILL_DMG = War3_AddRaceSkill( thisRaceID, "U-238 Shells", "Scout shots can do bonus damage.", false, 5 );
	ULT_INVIS = War3_AddRaceSkill( thisRaceID, "Personal Cloaking", "Become invisible for a short time. (2/4/6/7)s", true, 5 );
	
	W3SkillCooldownOnSpawn( thisRaceID, ULT_INVIS, 5.0, _);
	
	War3_CreateRaceEnd( thisRaceID );
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
		War3_WeaponRestrictTo( client, thisRaceID, "weapon_knife,weapon_scout,weapon_deagle,weapon_glock,weapon_usp" );
	}
}

public OnWar3EventSpawn( client )
{
	new race = War3_GetRace( client );
	if( race == thisRaceID )
	{
		new skill_scout = War3_GetSkillLevel( client, thisRaceID, SKILL_SCOUT );
		if( skill_scout > 0 && GetRandomFloat( 0.0, 1.0 ) <= ScoutChance[skill_scout] )
		{
			GivePlayerItem( client, "weapon_scout" );
		}
		War3_SetBuff( client, fInvisibilitySkill, thisRaceID, 1.0 );
	}
	
	if(bIsLockdown[client])
	{
		bIsLockdown[client]=false;
		War3_SetBuff(client,bNoMoveMode,thisRaceID,false);
	}
}

public OnWar3EventDeath( victim, attacker )
{
	W3ResetAllBuffRace( victim, thisRaceID );
	War3_SetBuff( victim, bNoMoveMode, thisRaceID, false );

}

public OnWar3EventPostHurt(victim, attacker, Float:damage, const String:weapon[32], bool:isWarcraft)
{
	if( W3GetDamageIsBullet() && ValidPlayer( victim, true ) && ValidPlayer( attacker, true ) && GetClientTeam( victim ) != GetClientTeam( attacker ) )
	{
		if( War3_GetRace( attacker ) == thisRaceID )
		{
			new skill_dmg = War3_GetSkillLevel( attacker, thisRaceID, SKILL_DMG );
			if( !Hexed( attacker, false ) && skill_dmg > 0 && GetRandomFloat( 0.0, 1.0 ) <= 0.45 && !W3HasImmunity( victim, Immunity_Skills ) )
			{
				new String:wpnstr[32];
				GetClientWeapon( attacker, wpnstr, 32 );
				if( StrEqual( wpnstr, "weapon_scout" ) )
				{
					new Float:start_pos[3];
					new Float:target_pos[3];
				
					GetClientAbsOrigin( attacker, start_pos );
					GetClientAbsOrigin( victim, target_pos );
				
					start_pos[2] += 40;
					target_pos[2] += 40;
				
					TE_SetupBeamPoints( start_pos, target_pos, BeamSprite, HaloSprite, 0, 0, 1.0, 3.0, 6.0, 0, 0.0, { 100, 255, 55, 255 }, 0 );
					TE_SendToAll();
					
					War3_DealDamage( victim, RoundToFloor( damage * DamageMultiplier[skill_dmg] ), attacker, DMG_BULLET, "terran_ghost_crit" );
				
					W3PrintSkillDmgHintConsole( victim, attacker, War3_GetWar3DamageDealt(), SKILL_DMG );
					W3FlashScreen( victim, RGBA_COLOR_RED );
				}
			}
			
			new skill_freeze = War3_GetSkillLevel( attacker, thisRaceID, SKILL_FREEZE );
			if( !Hexed( attacker, false ) && skill_freeze > 0 && GetRandomFloat( 0.0, 1.0 ) <= FreezeChance[skill_dmg] && !W3HasImmunity( victim, Immunity_Skills  ) )
			{
				new String:wpnstr[32];
				GetClientWeapon( attacker, wpnstr, 32 );
				if( StrEqual( wpnstr, "weapon_scout" ) )
				{
					new Float:target_pos[3];
					
					GetClientAbsOrigin( victim, target_pos );
					
					TE_SetupGlowSprite( target_pos, BeamSprite, 1.0, 2.0, 90 );
					TE_SendToAll();
					
					bIsLockdown[victim]=true;
					War3_SetBuff( victim, bNoMoveMode, thisRaceID, true );
					CreateTimer( 1.0, StopFreeze, victim );
					
					W3FlashScreen( victim, RGBA_COLOR_BLUE );
				}
			}
		}
	}
}

public Action:StopFreeze( Handle:timer, any:client )
{
	if( ValidPlayer( client, true ) )
	{
		bIsLockdown[client]=false;
		War3_SetBuff( client, bNoMoveMode, thisRaceID, false );
	}
}

public OnUltimateCommand( client, race, bool:pressed )
{
	if( race == thisRaceID && pressed && IsPlayerAlive( client ) && !Silenced( client ) )
	{
		new ult_level = War3_GetSkillLevel( client, race, ULT_INVIS );
		if( ult_level > 0 )
		{
			if( War3_SkillNotInCooldown( client, thisRaceID, ULT_INVIS, true ) )
			{
				War3_SetBuff( client, fInvisibilitySkill, thisRaceID, 0.0 );
				
				PrintHintText(client,"Cloaking: Activated");

				CreateTimer( UltDuration[ult_level], StopInvi, client );
				
				War3_CooldownMGR( client, UltDelay[ult_level] + UltDuration[ult_level], thisRaceID, ULT_INVIS);
			}
		}
		else
		{
			W3MsgUltNotLeveled( client );
		}
	}
}

public Action:StopInvi( Handle:timer, any:client )
{
	if( ValidPlayer( client, true ) )
	{
		War3_SetBuff( client, fInvisibilitySkill, thisRaceID, 1.0 );
		
		PrintHintText(client,"Cloaking: Deactivated");
	}
}