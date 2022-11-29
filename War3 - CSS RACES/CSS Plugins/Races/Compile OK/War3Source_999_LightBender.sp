/**
* File: War3Source_Light_Bender.sp
* Description: The Light Bender race for SourceCraft.
* Author(s): xDr.HaaaaaaaXx
*/

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdktools_stocks>
#include <sdktools_functions>
#include "W3SIncs/War3Source_Interface"
#include "W3SIncs/haaaxfunctions"
//#include "W3SIncs/colors"



// War3Source stuff
new thisRaceID, SKILL_RED, SKILL_GREEN, SKILL_BLUE, ULT_DISCO;

new Float:RGBChance[6] = { 0.00, 0.05, 0.10, 0.15, 0.20, 0.25 };
new Float:ClientPos[64][3];
new ClientTarget[64];
new bool:bDiscoUsed[MAXPLAYERS];

new HaloSprite, BeamSprite;

public Plugin:myinfo = 
{
	name = "War3Source Race - Light Bender",
	author = "xDr.HaaaaaaaXx",
	description = "The Light Bender race for War3Source.",
	version = "1.0.0.1",
	url = ""
};

public OnMapStart()
{
	HaloSprite = PrecacheModel( "materials/sprites/halo01.vmt" );
	BeamSprite = PrecacheModel( "materials/sprites/laser.vmt" );
}

public OnWar3PluginReady()
{
	thisRaceID = War3_CreateNewRace( "Light Bender", "lightbender" );
	
	SKILL_RED = War3_AddRaceSkill( thisRaceID, "Red Laser: Burn", "Burn your targets", false, 5 );	
	SKILL_GREEN = War3_AddRaceSkill( thisRaceID, "Green Laser: Shake", "Shake your targets", false, 5 );	
	SKILL_BLUE = War3_AddRaceSkill( thisRaceID, "Blue Laser: Freeze", "Freeze your Targets", false, 5 );
	ULT_DISCO = War3_AddRaceSkill( thisRaceID, "Disco Ball", "Teleport an enemy into the air above you", true, 1);
	
	W3SkillCooldownOnSpawn( thisRaceID, ULT_DISCO, 25.0, _);

	War3_CreateRaceEnd( thisRaceID );
}

public OnRaceChanged( client, oldrace, newrace )
{
	if( newrace != thisRaceID )
	{
		W3ResetAllBuffRace( client, thisRaceID );
	}
}

public OnWar3EventSpawn( client )
{
	bDiscoUsed[client] = false;
}

public OnWar3EventDeath( victim, attacker )
{
	W3ResetAllBuffRace( victim, thisRaceID );
}

public OnWar3EventPostHurt(victim, attacker, Float:damage, const String:weapon[32], bool:isWarcraft)
{
	if( W3GetDamageIsBullet() && ValidPlayer( victim, true ) && ValidPlayer( attacker, true ) && GetClientTeam( victim ) != GetClientTeam( attacker ) )
	{
		if( War3_GetRace( attacker ) == thisRaceID && !W3HasImmunity( victim, Immunity_Skills ))
		{
			new skill_red = War3_GetSkillLevel( attacker, thisRaceID, SKILL_RED );
			if( !Hexed( attacker, false ) && skill_red > 0 && GetRandomFloat( 0.0, 1.0 ) <= RGBChance[skill_red] )
			{
				IgniteEntity( victim, 2.0 );
				
				CPrintToChat( victim, "{red}Red Laser{default} :  Burn" );
				CPrintToChat( attacker, "{red}Red Laser{default} :  Burn" );
				
				new Float:StartPos[3];
				new Float:EndPos[3];
				
				GetClientAbsOrigin( victim, StartPos );
				
				GetClientAbsOrigin( victim, EndPos );
				
				EndPos[0] += GetRandomFloat( -100.0, 100.0 );
				EndPos[1] += GetRandomFloat( -100.0, 100.0 );
				EndPos[2] += GetRandomFloat( -100.0, 100.0 );

				TE_SetupBeamPoints( StartPos, EndPos, BeamSprite, HaloSprite, 0, 1, 30.0, 20.0, 2.0, 0, 0.0, { 255, 11, 15, 255 }, 1 );
				TE_SendToAll();
				
				GetClientAbsOrigin( victim, EndPos );
				
				EndPos[0] += GetRandomFloat( -100.0, 100.0 );
				EndPos[1] += GetRandomFloat( -100.0, 100.0 );
				EndPos[2] += GetRandomFloat( -100.0, 100.0 );
				
				TE_SetupBeamPoints( StartPos, EndPos, BeamSprite, HaloSprite, 0, 1, 30.0, 20.0, 2.0, 0, 0.0, { 255, 11, 15, 255 }, 1 );
				TE_SendToAll();
				
				GetClientAbsOrigin( victim, EndPos );
				
				EndPos[0] += GetRandomFloat( -100.0, 100.0 );
				EndPos[1] += GetRandomFloat( -100.0, 100.0 );
				EndPos[2] += GetRandomFloat( -100.0, 100.0 );
				
				TE_SetupBeamPoints( StartPos, EndPos, BeamSprite, HaloSprite, 0, 1, 30.0, 20.0, 2.0, 0, 0.0, { 255, 11, 15, 255 }, 1 );
				TE_SendToAll();
			}
			
			new skill_green = War3_GetSkillLevel( attacker, thisRaceID, SKILL_GREEN );
			if( !Hexed( attacker, false ) && skill_green > 0 && GetRandomFloat( 0.0, 1.0 ) <= RGBChance[skill_green] )
			{
				War3_ShakeScreen( victim );
				
				CPrintToChat( victim, "{green}Green Laser{default} :  Shake" );
				CPrintToChat( attacker, "{green}Green Laser{default} :  Shake" );
				
				new Float:StartPos[3];
				new Float:EndPos[3];
				
				GetClientAbsOrigin( victim, StartPos );
				
				GetClientAbsOrigin( victim, EndPos );
				
				EndPos[0] += GetRandomFloat( -100.0, 100.0 );
				EndPos[1] += GetRandomFloat( -100.0, 100.0 );
				EndPos[2] += GetRandomFloat( -100.0, 100.0 );

				TE_SetupBeamPoints( StartPos, EndPos, BeamSprite, HaloSprite, 0, 1, 30.0, 20.0, 2.0, 0, 0.0, { 11, 255, 15, 255 }, 1 );
				TE_SendToAll();
				
				GetClientAbsOrigin( victim, EndPos );
				
				EndPos[0] += GetRandomFloat( -100.0, 100.0 );
				EndPos[1] += GetRandomFloat( -100.0, 100.0 );
				EndPos[2] += GetRandomFloat( -100.0, 100.0 );
				
				TE_SetupBeamPoints( StartPos, EndPos, BeamSprite, HaloSprite, 0, 1, 30.0, 20.0, 2.0, 0, 0.0, { 11, 255, 15, 255 }, 1 );
				TE_SendToAll();
				
				GetClientAbsOrigin( victim, EndPos );
				
				EndPos[0] += GetRandomFloat( -100.0, 100.0 );
				EndPos[1] += GetRandomFloat( -100.0, 100.0 );
				EndPos[2] += GetRandomFloat( -100.0, 100.0 );
				
				TE_SetupBeamPoints( StartPos, EndPos, BeamSprite, HaloSprite, 0, 1, 30.0, 20.0, 2.0, 0, 0.0, { 11, 255, 15, 255 }, 1 );
				TE_SendToAll();
			}
			
			new skill_blue = War3_GetSkillLevel( attacker, thisRaceID, SKILL_BLUE );
			if( !Hexed( attacker, false ) && skill_blue > 0 && GetRandomFloat( 0.0, 1.0 ) <= RGBChance[skill_blue] )
			{
				War3_SetBuff( victim, bNoMoveMode, thisRaceID, true );
				CreateTimer( 1.0, StopFreeze, victim );
				
				CPrintToChat( victim, "{blue}Blue Laser{default} :  Freeze" );
				CPrintToChat( attacker, "{blue}Blue Laser{default} :  Freeze" );
				
				new Float:StartPos[3];
				new Float:EndPos[3];
				
				GetClientAbsOrigin( victim, StartPos );
				GetClientAbsOrigin( victim, EndPos );
				
				EndPos[0] += GetRandomFloat( -100.0, 100.0 );
				EndPos[1] += GetRandomFloat( -100.0, 100.0 );
				EndPos[2] += GetRandomFloat( -100.0, 100.0 );

				TE_SetupBeamPoints( StartPos, EndPos, BeamSprite, HaloSprite, 0, 1, 30.0, 20.0, 2.0, 0, 0.0, { 15, 11, 255, 255 }, 1 );
				TE_SendToAll();
				
				GetClientAbsOrigin( victim, EndPos );
				
				EndPos[0] += GetRandomFloat( -100.0, 100.0 );
				EndPos[1] += GetRandomFloat( -100.0, 100.0 );
				EndPos[2] += GetRandomFloat( -100.0, 100.0 );
				
				TE_SetupBeamPoints( StartPos, EndPos, BeamSprite, HaloSprite, 0, 1, 30.0, 20.0, 2.0, 0, 0.0, { 15, 11, 255, 255 }, 1 );
				TE_SendToAll();
				
				GetClientAbsOrigin( victim, EndPos );
				
				EndPos[0] += GetRandomFloat( -100.0, 100.0 );
				EndPos[1] += GetRandomFloat( -100.0, 100.0 );
				EndPos[2] += GetRandomFloat( -100.0, 100.0 );
				
				TE_SetupBeamPoints( StartPos, EndPos, BeamSprite, HaloSprite, 0, 1, 30.0, 20.0, 2.0, 0, 0.0, { 15, 11, 255, 255 }, 1 );
				TE_SendToAll();
			}
		}
	}
}

public Action:StopFreeze( Handle:timer, any:client )
{
	if( ValidPlayer( client, true ) )
	{
		War3_SetBuff( client, bNoMoveMode, thisRaceID, false );
	}
}

public OnUltimateCommand( client, race, bool:pressed )
{
	if( race == thisRaceID && pressed && ValidPlayer( client, true ) )
	{
		new ult_level = War3_GetSkillLevel( client, race, ULT_DISCO );
		if( ult_level > 0 )
		{
			if( War3_SkillNotInCooldown( client, thisRaceID, ULT_DISCO, true ) )
			{
				if(!bDiscoUsed[client])
				{
					bDiscoUsed[client] = true;
					Disco( client );
				}
				else
				{
					PrintHintText(client,"You have already used Disco Ball once this round.");
				}
			}
		}
		else
		{
			PrintHintText( client, "Level Your Ultimate First" );
		}
	}
}

stock Disco( client )
{
	if( GetClientTeam( client ) == TEAM_T )
		ClientTarget[client] = War3_GetRandomPlayer(client, "#ct", true, true );
	if( GetClientTeam( client ) == TEAM_CT )
		ClientTarget[client] = War3_GetRandomPlayer(client, "#t", true, true );
	
	if( ClientTarget[client] == 0 )
	{
		PrintHintText( client, "No Target Found" );
	}
	else
	{
		GetClientAbsOrigin( client, ClientPos[client] );
		CreateTimer( 3.0, Teleport, client );
		CreateTimer( 3.1, Freeze, client );
		CreateTimer( 4.5, UnFreeze, client );
		
		new String:NameAttacker[64];
		GetClientName( client, NameAttacker, 64 );
		
		new String:NameVictim[64];
		GetClientName( ClientTarget[client], NameVictim, 64 );
		
		PrintToChat( client, "\x05: \x4%s \x03will teleport to you and become a \x04Disco Ball \x03in \x043 \x03seconds", NameVictim );
		PrintToChat( ClientTarget[client], "\x05: \x03You will teleport to \x04%s \x03and become a \x04Disco Ball \x03in \x043 \x03seconds", NameAttacker );
		
		War3_CooldownMGR( client, 30.0, thisRaceID, ULT_DISCO, _, _ );
	}
}

public Action:Teleport( Handle:timer, any:client )
{
	if( ValidPlayer( ClientTarget[client], true ) )
	{
		ClientPos[client][2] += 150;
		TeleportEntity( ClientTarget[client], ClientPos[client], NULL_VECTOR, NULL_VECTOR );
	}
}

public Action:Freeze( Handle:timer, any:client )
{
	if( ValidPlayer( ClientTarget[client], true ) )
	{
		War3_SetBuff( ClientTarget[client], bBashed, thisRaceID, true );
	}
}

public Action:UnFreeze( Handle:timer, any:client )
{
	if( ValidPlayer( ClientTarget[client], true ) )
	{
		War3_SetBuff( ClientTarget[client], bBashed, thisRaceID, false );
	}
}