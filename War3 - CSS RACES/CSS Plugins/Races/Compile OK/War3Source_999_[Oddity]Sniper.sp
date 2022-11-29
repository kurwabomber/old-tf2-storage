/**
* File: War3Source_Sniper.sp
* Description: The Sniper race for SourceCraft.
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
new Float:BeaconChance[6] = { 0.0, 0.05, 0.10, 0.15, 0.20, 0.25 };
new Float:DisgChance[6] = { 0.0, 0.15, 0.3, 0.45, 0.6, 0.75 };
new Float:UltDuration[6] = { 0.0, 1.0, 1.5, 2.0, 2.5, 3.0 };
new Float:UltBreakDelay[6] = { 0.0, 0.6, 0.7, 0.8, 0.9, 1.0 };
new bool:BreakOnShot[MAXPLAYERS+1] = { false, ... };
new bool:InHiding[MAXPLAYERS+1] = { false, ... };
//new CashMax[6] = { 0, 30, 45, 60, 100, 150 };
//new CashMin[6] = { 0, 20, 30, 45, 75, 100 };
new Float:GoldChance[6] = { 0.0, 0.1, 0.2, 0.3, 0.4, 0.5 };
new GoldQuantity = 2;
new XPMin[6] = { 0, 10, 20, 30, 40, 50 };
new XPMax[6] = { 0, 20, 40, 60, 80, 100 };
new HaloSprite, BeamSprite;
//new MoneyOffsetCS;

new SKILL_SKIN, SKILL_XP, SKILL_BEACON, SKILL_HIDE;

public Plugin:myinfo = 
{
	name = "War3Source Race - Sniper",
	author = "xDr.HaaaaaaaXx",
	description = "The Sniper race for War3Source.",
	version = "1.0.0.1",
	url = ""
};

public OnMapStart()
{
	BeamSprite = PrecacheModel( "materials/sprites/lgtning.vmt" );
	HaloSprite = PrecacheModel( "materials/sprites/halo01.vmt" );
}

public OnPluginStart()
{
	//MoneyOffsetCS = FindSendPropInfo( "CCSPlayer", "m_iAccount" );
}

public OnWar3PluginReady()
{
	thisRaceID = War3_CreateNewRace( "[Oddity]Sniper", "odsniper" );
	
	SKILL_SKIN = War3_AddRaceSkill( thisRaceID, "Disguise", "You may spawn and look like the enemy", false, 5 );
	SKILL_XP = War3_AddRaceSkill( thisRaceID, "Scope Master", "You get 10-100 XP and maybe 2 gold on a scout kill", false, 5 );
	SKILL_BEACON = War3_AddRaceSkill( thisRaceID, "One bullet one kill", "You beacon enemies in order to track them", false, 5 );
	SKILL_HIDE = War3_AddRaceSkill( thisRaceID, "Sniper", "Go invisible for 0.5 + (0.5 x level) seconds when hit\nAfter 0.5 + (0.1 x level) seconds shooting will break invis", false, 5 );
	
	War3_CreateRaceEnd( thisRaceID );
}

public OnRaceChanged ( client,oldrace,newrace )
{
	if( newrace != thisRaceID )
	{
		War3_WeaponRestrictTo( client, thisRaceID, "" );
		W3ResetAllBuffRace( client, thisRaceID );
	}
	else
	{
		War3_WeaponRestrictTo( client, thisRaceID, "weapon_knife,weapon_scout" );
		if( IsPlayerAlive( client ) )
		{
			GivePlayerItem( client, "weapon_scout" );
		}
	}
}

public OnWar3EventSpawn( client )
{
	new race = War3_GetRace( client );
	if( race == thisRaceID )
	{
		GivePlayerItem( client, "weapon_scout" );
		War3_SetBuff( client, fInvisibilitySkill, thisRaceID, 1.0 );
		War3_SetBuff( client, fMaxSpeed, thisRaceID, 1.0 );
		War3_SetBuff( client, bDisarm, thisRaceID, false  );
		InHiding[client] = false;
		if( War3_GetSkillLevel( client, thisRaceID, SKILL_SKIN ) > 0 && GetRandomFloat( 0.0, 1.0 ) <= DisgChance[War3_GetSkillLevel( client, thisRaceID, SKILL_SKIN )] )
		{
			if( GetClientTeam( client ) == TEAM_T )
			{
				SetEntityModel( client, "models/player/ct_urban.mdl" );
			}
			if( GetClientTeam( client ) == TEAM_CT )
			{
				SetEntityModel( client, "models/player/t_leet.mdl" );
			}
			PrintToChat( client, "\x05: \x03You are disguised as enemy!!!" );
			PrintHintText( client, "You are disguised!" );
		}
	}
}

public OnWar3EventDeath( victim, attacker )
{
	if( W3GetDamageIsBullet() && ValidPlayer( victim ) && ValidPlayer( attacker, true ) && GetClientTeam( victim ) != GetClientTeam( attacker ) )
	{
		if( War3_GetRace( attacker ) == thisRaceID )
		{
			new skill_xp = War3_GetSkillLevel( attacker, thisRaceID, SKILL_XP );
			if( !Hexed( attacker, false ) && skill_xp > 0 )
			{
				new String:wpnstr[32];
				GetClientWeapon( attacker, wpnstr, 32 );
				if( StrEqual( wpnstr, "weapon_scout" ) )
				{
					new xp = GetRandomInt( XPMin[skill_xp], XPMax[skill_xp] );
					//new cash = GetRandomInt( CashMin[skill_xp], CashMax[skill_xp] );
					new goldGiven = 0;
				
					//SetMoney( attacker, GetMoney( attacker ) + cash );
					new String:tempStr[128] = "";
					new String:outputStr[128] = "";
					
					War3_SetXP( attacker, thisRaceID, War3_GetXP( attacker, thisRaceID ) + xp );
					StrCat( tempStr, sizeof(tempStr), "Reward for killing an enemy: %i XP" );
					
					if ( GetRandomFloat( 0.0, 1.0 ) <= GoldChance[skill_xp] )
					{
						War3_SetGold( attacker, War3_GetGold( attacker ) + GoldQuantity);
						goldGiven = GoldQuantity;
						StrCat( tempStr, sizeof(tempStr), ", %i gold" );
					}
					
					if (goldGiven > 0)
					{
						Format( outputStr, sizeof(outputStr), tempStr, xp, goldGiven );
					}
					else
					{
						Format( outputStr, sizeof(outputStr), tempStr, xp );
					}
					
					PrintToChat( attacker, outputStr );
				
					new Float:start_pos[3];
					new Float:target_pos[3];
				
					GetClientAbsOrigin( attacker, start_pos );
					GetClientAbsOrigin( victim, target_pos );
				
					start_pos[2] += 40;
					target_pos[2] += 40;
				
					TE_SetupBeamPoints( start_pos, target_pos, BeamSprite, HaloSprite, 0, 0, 1.0, 10.0, 10.0, 0, 0.0, { 255, 200, 0, 255 }, 0 );
					TE_SendToAll();
					
					new skill_hide = War3_GetSkillLevel( attacker, thisRaceID, SKILL_HIDE );
					if ( skill_hide > 0 && InHiding[attacker] )
					{
						stopHide( attacker );
					}
				}
			}
			
			new skill_beacon = War3_GetSkillLevel( attacker, thisRaceID, SKILL_BEACON );
			if( !Hexed( attacker, false ) && skill_beacon > 0 && GetRandomFloat( 0.0, 1.0 ) <= BeaconChance[skill_beacon] )
			{
				ServerCommand( "sm_beacon #%d 1", GetClientUserId( victim ) );
			}
		}
	}
}

public OnW3TakeDmgBullet( victim, attacker, Float:damage )
{
	if( IS_PLAYER( victim ) && IS_PLAYER( attacker ) && victim > 0 && attacker > 0 && attacker != victim )
	{
		new vteam = GetClientTeam( victim );
		new ateam = GetClientTeam( attacker );
		if( vteam != ateam )
		{
			new race_victim = War3_GetRace( victim );
			new skill_hide = War3_GetSkillLevel( victim, thisRaceID, SKILL_HIDE );
			if( race_victim == thisRaceID && skill_hide > 0 && !Hexed( victim, false ) && War3_SkillNotInCooldown( victim, thisRaceID, SKILL_HIDE, false ) ) 
			{
				W3FlashScreen( victim, RGBA_COLOR_RED );
				
				PrintHintText( victim, "\x01: \x05You have been seen. \x04RELOCATE FAST!" );
				
				InHiding[victim] = true;
				
				War3_SetBuff( victim, fInvisibilitySkill, thisRaceID, 0.01 );
				War3_SetBuff( victim, fMaxSpeed, thisRaceID, 1.5 );
				War3_SetBuff( victim, bDoNotInvisWeapon, thisRaceID, false);
				
				CreateTimer( UltBreakDelay[skill_hide], BreakInvis, victim);
				CreateTimer( UltDuration[skill_hide], StopHide, victim );
				
				
			}
		}
	}
}

public OnWeaponFired( client )
{
	if ( ValidPlayer( client, true ) && War3_GetRace( client ) == thisRaceID && InHiding[client] && BreakOnShot[client] )
	{
		stopHide( client );
	}
}

public Action:BreakInvis( Handle:timer, any:client )
{
	if( ValidPlayer( client, true ) && InHiding[client] )
	{
		BreakOnShot[client] = true;
	}
}

public Action:StopHide( Handle:timer, any:client )
{
	if( ValidPlayer( client, true ) && InHiding[client] )
	{
		stopHide( client );
	}
}

public stopHide( any:client )
{
	War3_SetBuff( client, fInvisibilitySkill, thisRaceID, 1.0 );
	War3_SetBuff( client, fMaxSpeed, thisRaceID, 1.0 );
	if (IsPlayerAlive(client))
	{
		PrintHintText( client, "No longer invisible" );
	}
	BreakOnShot[client] = false;
	InHiding[client] = false;
	War3_CooldownMGR( client, 10.0, thisRaceID, SKILL_HIDE, true, true );
}

/*stock GetMoney( player )
{
	return GetEntData( player, MoneyOffsetCS );
}

stock SetMoney( player, money )
{
	SetEntData( player, MoneyOffsetCS, money );
}*/