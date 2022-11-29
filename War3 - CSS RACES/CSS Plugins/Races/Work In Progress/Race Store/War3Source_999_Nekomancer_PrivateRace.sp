/**
* File: War3Source_Nekomancer_PrivateRace
* Description: x NekomanceR x's private war3source race
* Author(s): Scruffy The Janitor
*/

#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdkhooks>
#include <sdktools>
#include <sdktools_functions>
#include <sdktools_tempents>
#include <sdktools_tempents_stocks>
#include <sdktools_sound>

new thisRaceID;
new SKILL_SPLASH, SKILL_STRUGGLE;

new Float:StruggleChance[2] = {0.0, 0.01};
new Float:StruggleDamage[2] = {0.0, 0.01};

new HaloSprite, BeamSprite;

public Plugin:myinfo = 
{
	name = "x NekomanceR x's Magikarp",
	author = "Scruffy The Janitor",
	description = "x NekomanceR x's private race 1",
	version = "1.0.0.1",
	url = "www.sevensinsgaming.com"
};

public OnRaceChanged( client, oldrace, newrace )
{
	if( newrace == thisRaceID )
	{
	
		new String:SteamID[64];
		GetClientAuthString( client, SteamID, 64 );
		if( !StrEqual( "STEAM_0:1:37439529", SteamID ) )
		{
			CreateTimer( 0.5, ChangeRace, client );
		}
	}
}

public Action:ChangeRace( Handle:timer, any:client )
{
	War3_SetRace( client, War3_GetRaceIDByShortname( "undead" ) );
	PrintHintText( client, "Race is restricted to x NekomanceR x" );
}


public OnMapStart()
{
	HaloSprite = PrecacheModel( "materials/sprites/halo01.vmt" );
	BeamSprite = PrecacheModel( "materials/sprites/laser.vmt" );
}

public OnWar3PluginReady()
{
	thisRaceID=War3_CreateNewRace("Magikarp","magikarp");
	SKILL_SPLASH=War3_AddRaceSkill(thisRaceID,"Splash","Does sweet fuck all",false);
	SKILL_STRUGGLE=War3_AddRaceSkill(thisRaceID,"Struggle","1% chance to do 1% extra damage",false);
	War3_CreateRaceEnd(thisRaceID);
}

public OnWar3EventPostHurt( victim, attacker, damage )
{
	if( War3_GetRace( attacker ) == thisRaceID && ValidPlayer( victim, true ) && ValidPlayer( attacker, true ) && GetClientTeam( victim ) != GetClientTeam( attacker ) )
	{
		new skill_splash = War3_GetSkillLevel( attacker, thisRaceID, SKILL_SPLASH );
		if(skill_splash > 0)
		{
		PrintCenterText( victim, "MAGIKARP USED SPLASH!" );
		}
		new skill_struggle = War3_GetSkillLevel( attacker, thisRaceID, SKILL_STRUGGLE );
		if(skill_struggle > 0)
		{
			if( GetRandomFloat( 0.0, 1.0 ) <= StruggleChance[skill_struggle] )
			{
				War3_DealDamage( victim, RoundToFloor( damage * StruggleDamage[skill_struggle] ), attacker, DMG_BULLET, "struggle" );
			}
		}
		new Float:attacker_pos[3];
		new Float:victim_pos[3];
				
		GetClientAbsOrigin( attacker, attacker_pos );
		GetClientAbsOrigin( victim, victim_pos );
				
		attacker_pos[2] += 40;
		victim_pos[2] += 40;
				
		TE_SetupBeamPoints( attacker_pos, victim_pos, BeamSprite, HaloSprite, 0, 0, 1.0, 5.0, 5.0, 0, 0.0, { 0, 0, 255, 255 }, 0 );
		TE_SendToAll();
	}
}