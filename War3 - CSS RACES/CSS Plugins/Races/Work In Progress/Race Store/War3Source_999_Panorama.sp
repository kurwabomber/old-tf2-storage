/**
* File: War3Source_Panorama.sp
* Description: The Panorama race for SourceCraft.
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
new thisRaceID, SKILL_WALL, SKILL_DRUG, SKILL_REMATCH, ULT_ZOOM;

// Chance/Data Arrays
new Float:Step[5] = { 12.0, 45.0, 55.0, 100.0, 200.0 };
new Float:RematchChance[5] = { 0.0, 0.25, 0.27, 0.28, 0.46 };
new Float:DrugChance[5] = { 0.0, 0.18, 0.23, 0.27, 0.33 };
new Float:RematchDelay[5] = { 0.0, 3.0, 5.0, 7.0, 8.0 };
new Zoom[5] = { 0, 44, 33, 22, 11 };
new Float:AttackerPos[64][3];
new Float:ClientPos[64][3];
new bool:Zoomed[64];

// Sounds
new String:spawn[] = "weapons/physcannon/superphys_launch2.wav";
new String:death[] = "weapons/physcannon/physcannon_drop.wav";
new String:spawn1[] = "ambient/atmosphere/cave_hit1.wav";
new String:zoom[] = "weapons/zoom.wav";
new String:on[] = "items/nvg_on.wav";
new String:off[] = "items/nvg_off.wav";
new String:attack[] = "ambient/wind/wind_snippet2.wav";

// Other
new FOV, m_hMyWeapons;
new GlowSprite;

public Plugin:myinfo = 
{
	name = "War3Source Race - Panorama",
	author = "xDr.HaaaaaaaXx -ZERO <ibis>",
	description = "Panorama race for War3Source.",
	version = "1.0.0.1",
	url = ""
};

public OnPluginStart()
{
	m_hMyWeapons = FindSendPropOffs( "CBaseCombatCharacter", "m_hMyWeapons" );
	FOV = FindSendPropInfo( "CBasePlayer", "m_iFOV" );
	HookEvent( "player_death", PlayerDeathEvent );
}

public OnMapStart()
{
	War3_PrecacheSound( spawn );
	War3_PrecacheSound( death );
	War3_PrecacheSound( spawn1 );
	War3_PrecacheSound( zoom );
	War3_PrecacheSound( on );
	War3_PrecacheSound( off );
	War3_PrecacheSound( attack );
	GlowSprite = PrecacheModel( "models/effects/portalfunnel.mdl" );
}

public OnWar3PluginReady()
{
	thisRaceID = War3_CreateNewRace( "Panorama", "panorama" );
	
	SKILL_WALL = War3_AddRaceSkill( thisRaceID, "Wall Climb", "Climb Tall Walls in a single Step", false );	
	SKILL_DRUG = War3_AddRaceSkill( thisRaceID, "Flip View", "Flip the enemies View up side down", false );	
	SKILL_REMATCH = War3_AddRaceSkill( thisRaceID, "Rematch", "Go back in time and Rematch your Enemy", false );
	ULT_ZOOM = War3_AddRaceSkill( thisRaceID, "Zoom", "Use a Scope on any weapon", true );
	
	War3_CreateRaceEnd( thisRaceID );
}

public InitPassiveSkills( client )
{
	if( War3_GetRace( client ) == thisRaceID )
	{
		new skill_wall = War3_GetSkillLevel( client, thisRaceID, SKILL_WALL );
		SetEntPropFloat( client, Prop_Send, "m_flStepSize", Step[skill_wall] );
	}
}

public OnRaceChanged( client, oldrace, newrace )
{
	if( newrace != thisRaceID )
	{
		SetEntPropFloat( client, Prop_Send, "m_flStepSize", 18.0 ); 
		W3ResetAllBuffRace( client, thisRaceID );
	}
	else
	{	
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
		EmitSoundToAll( spawn1, client );
	}
}

public OnWar3EventPostHurt( victim, attacker, damage )
{
	if( W3GetDamageIsBullet() && ValidPlayer( victim, true ) && ValidPlayer( attacker, true ) && GetClientTeam( victim ) != GetClientTeam( attacker ) )
	{
		if( War3_GetRace( attacker ) == thisRaceID )
		{
			new skill_level = War3_GetSkillLevel( attacker, thisRaceID, SKILL_DRUG );
			if( !Hexed( attacker, false ) && GetRandomFloat( 0.0, 1.0 ) <= DrugChance[skill_level] )
			{
				new Float:pos[3];
				
				GetClientAbsOrigin( victim, pos );
				
				TE_SetupGlowSprite( pos, GlowSprite, 3.0, 0.5, 255 );
				TE_SendToAll();
				
				Drug( victim, 1.0 );
				
				EmitSoundToAll( attack, attacker );
				EmitSoundToAll( attack, victim );
			}
		}
	}
}

stock Drug( client, Float:duration )
{
	if( IsPlayerAlive( client ) )
	{
		new Float:pos[3];
		new Float:angs[3];
		
		GetClientAbsOrigin( client, pos );
		GetClientEyeAngles( client, angs );
		
		angs[2] = 180.0;
		
		TeleportEntity( client, pos, angs, NULL_VECTOR );
		
		CreateTimer( duration, StopDrug, client );
	}
}

public Action:StopDrug( Handle:timer, any:client )
{
	new Float:pos[3];
	new Float:angs[3];
	
	GetClientAbsOrigin( client, pos );
	GetClientEyeAngles( client, angs );
	
	angs[2] = 0.0;
	
	TeleportEntity( client, pos, angs, NULL_VECTOR );
}

public OnUltimateCommand( client, race, bool:pressed )
{
	if( race == thisRaceID && pressed && IsPlayerAlive( client ) && !Silenced( client ) )
	{
		new ult_level = War3_GetSkillLevel( client, race, ULT_ZOOM );
		if( ult_level > 0 )
		{
			if( War3_SkillNotInCooldown( client, thisRaceID, ULT_ZOOM, true ) )
			{
				ToggleZoom( client );
			}
		}
		else
		{
			W3MsgUltNotLeveled( client );
		}
	}
}

stock ToggleZoom( client )
{
	if( Zoomed[client] )
	{
		StopZoom( client );
	}
	else
	{
		StartZoom( client );
	}
	EmitSoundToAll( zoom, client );
}

stock StopZoom( client )
{
	if( Zoomed[client] )
	{
		SetEntData( client, FOV, 0 );
		EmitSoundToAll( off, client );
		Zoomed[client] = false;
	}
}

stock StartZoom( client )
{
	if ( !Zoomed[client] )
	{
		new zoom_level = War3_GetSkillLevel( client, thisRaceID, ULT_ZOOM );
		SetEntData( client, FOV, Zoom[zoom_level] );
		EmitSoundToAll( on, client );
		Zoomed[client] = true;
	}
}

public PlayerDeathEvent( Handle:event, const String:name[], bool:dontBroadcast )
{
	new client = GetClientOfUserId( GetEventInt( event, "userid" ) );
	new attacker = GetClientOfUserId( GetEventInt( event, "attacker" ) );
	if( War3_GetRace( client ) == thisRaceID && attacker != client && attacker != 0 )
	{
		new skill_time = War3_GetSkillLevel( client, thisRaceID, SKILL_REMATCH );
		if( skill_time > 0 && GetRandomFloat( 0.0, 1.0 ) <= RematchChance[skill_time] )
		{
			GetClientAbsOrigin( client, ClientPos[client] );
			GetClientAbsOrigin( attacker, AttackerPos[attacker] );
			
			CreateTimer( RematchDelay[skill_time], SpawnClient, client );
			CreateTimer( RematchDelay[skill_time], SpawnAttacker, attacker );
			
			PrintToChat( client, "\x05: \x03In \x04%f \x03seconds \x04Time's Element \x03will peice together your last Moment", RematchDelay[skill_time] );
			PrintToChat( attacker, "\x05: \x03In \x04%f \x03seconds you go back in time to this verry moment", RematchDelay[skill_time] );
			
			EmitSoundToAll( death, client );
			EmitSoundToAll( death, attacker );
		}
	}
}

public Action:SpawnClient( Handle:timer, any:client )
{
	if( ValidPlayer( client, false ) )
	{
		War3_SpawnPlayer( client );
		CreateTimer( 0.2, TeleportClient, client );
	}
}

public Action:TeleportClient( Handle:timer, any:client )
{
	if( ValidPlayer( client, true ) )
	{
		new Float:ang[3];
		War3_CachedAngle( client, ang );
		TeleportEntity( client, ClientPos[client], ang, NULL_VECTOR );
		EmitSoundToAll( spawn, client );
		CreateTimer( 0.1, GivePlayerCachedDeathWPNFull, client );
	}
}

public Action:SpawnAttacker( Handle:timer, any:attacker )
{
	if( ValidPlayer( attacker, false ) )
	{
		War3_SpawnPlayer( attacker );
		CreateTimer( 0.2, TeleportAttacker, attacker );
	}
}

public Action:TeleportAttacker( Handle:timer, any:attacker )
{
	if( ValidPlayer( attacker, true ) )
	{
		new Float:ang[3];
		War3_CachedAngle( attacker, ang );
		TeleportEntity( attacker, AttackerPos[attacker], ang, NULL_VECTOR );
		EmitSoundToAll( spawn, attacker );
		CreateTimer( 0.1, GivePlayerCachedDeathWPNFull, attacker );
	}
}

public Action:GivePlayerCachedDeathWPNFull( Handle:h, any:client )
{
	if( ValidPlayer( client, true ) )
	{
		for( new s = 0; s < 10; s++ )
		{
			new ent = GetEntDataEnt2( client, m_hMyWeapons + ( s * 4 ) );
			if( ent > 0 && IsValidEdict( ent ) )
			{
				new String:ename[64];
				GetEdictClassname( ent, ename, sizeof( ename ) );
				if( StrEqual( ename, "weapon_c4" ) || StrEqual( ename, "weapon_knife" ) )
				{
					continue;
				}
				UTIL_Remove( ent );
			}
		}
		for( new s = 0; s < 10; s++ )
		{
			new String:wep_check[64];
			War3_CachedDeadWeaponName( client, s, wep_check, sizeof( wep_check ) );
			if( !StrEqual( wep_check, "" ) && !StrEqual( wep_check, "", false ) && !StrEqual( wep_check, "weapon_c4" ) && !StrEqual( wep_check, "weapon_knife" ) )
			{
				GivePlayerItem( client, wep_check );
			}
		}
		War3_SetCSArmor( client, 100 );
		War3_SetCSArmorHasHelmet( client, true );
	}
}