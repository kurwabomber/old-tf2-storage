/**
* File: War3Source_Genocide.sp
* Description: The Genocide race for SourceCraft.
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
new thisRaceID, SKILL_REGEN, SKILL_DMG, SKILL_GRENADE, ULT_DEJAVU;

// Chance/Data Arrays
new Float:GenocideDMGChance[5] = { 0.0, 0.18, 0.23, 0.27, 0.30 };
new Float:GenocideUltDuration[5] = { 0.0, 3.0, 4.0, 5.0, 6.0 };
new Float:HealthMultiplier[5] = { 0.0, 0.15, 0.20, 0.25, 0.30 };
new Float:DamageMultiplier[5] = { 0.0, 1.9, 2.1, 2.4, 4.4 };
new Float:ClientPos[64][3];
new Float:ClientAng[64][3];
new bool:bUltUsed[64];
new Health[64];
new Handle:g_hUltTimer[MAXPLAYERS + 1];


// Sounds
new String:grenade[] = "weapons/hegrenade/explode3.wav";

// Other
new HaloSprite, BeamSprite, RingBeam, FlameSprite;
new m_hMyWeapons;

public Plugin:myinfo = 
{
	name = "War3Source Race - Genocide",
	author = "xDr.HaaaaaaaXx",
	description = "The Vagabond race for War3Source.",
	version = "1.0.0.1",
	url = ""
};

public OnPluginStart()
{
	m_hMyWeapons = FindSendPropOffs( "CBaseCombatCharacter", "m_hMyWeapons" );
	HookEvent( "player_hurt", PlayerHurtEvent );
	HookEvent( "round_end" , RoundOverEvent);
}

public OnMapStart()
{
	HaloSprite = PrecacheModel( "materials/sprites/halo01.vmt" );
	BeamSprite = PrecacheModel( "materials/sprites/lgtning.vmt" );
	RingBeam = PrecacheModel( "materials/sprites/smoke.vmt" );
	FlameSprite = PrecacheModel( "materials/sprites/flatflame.vmt" );
	War3_PrecacheSound( grenade );
}

public OnWar3PluginReady()
{
	thisRaceID = War3_CreateNewRace( "Genocide", "genocide" );
	
	SKILL_REGEN = War3_AddRaceSkill( thisRaceID, "Regeneration", "Get a percentage of the damage you do back as health.", false );	
	SKILL_DMG = War3_AddRaceSkill( thisRaceID, "Genocide", "Strike enemy and do extra damage", false );
	SKILL_GRENADE = War3_AddRaceSkill( thisRaceID, "Grenades!", "Grenades do extra damage", false );
	ULT_DEJAVU = War3_AddRaceSkill( thisRaceID, "Deja Vu", "Go back in time 3 seconds", true );
	
	W3SkillCooldownOnSpawn( thisRaceID, ULT_DEJAVU, 15.0, _);
	
	War3_CreateRaceEnd( thisRaceID );
}

public OnRaceChanged( client,oldrace,newrace )
{
	if( newrace != thisRaceID )
	{
		War3_SetBuff( client, fInvisibilitySkill, thisRaceID, 1.0 );
		W3ResetAllBuffRace( client, thisRaceID );
	}
}

public OnWar3EventSpawn( client )
{
	new race = War3_GetRace( client );
	if( race == thisRaceID )
	{
		bUltUsed[client] = false;
		g_hUltTimer[client] = INVALID_HANDLE;
	}
}

public OnWar3EventPostHurt(victim, attacker, Float:damage, const String:weapon[32], bool:isWarcraft)
{
	if( W3GetDamageIsBullet() && ValidPlayer( victim, true ) && ValidPlayer( attacker, true ) && GetClientTeam( victim ) != GetClientTeam( attacker ) )
	{
		if( War3_GetRace( attacker ) == thisRaceID )
		{
			new skill_level = War3_GetSkillLevel( attacker, thisRaceID, SKILL_REGEN );
			if( !Hexed( attacker, false ) && GetRandomFloat( 0.0, 1.0 ) <= 0.33 && skill_level > 0 )
			{
				new Float:start_pos[3];
				new Float:target_pos[3];
				
				GetClientAbsOrigin( attacker, start_pos );
				GetClientAbsOrigin( victim, target_pos );
				
				start_pos[2] += 20;
				target_pos[2] += 20;
				
				TE_SetupBeamPoints( start_pos, target_pos, BeamSprite, HaloSprite, 0, 0, 2.0, 40.0, 40.0, 0, 0.0, { 255, 0, 0, 255 }, 0 );
				TE_SendToAll();
				
				TE_SetupBeamPoints( start_pos, target_pos, BeamSprite, HaloSprite, 0, 0, 2.0, 20.0, 20.0, 0, 0.0, { 255, 255, 255, 255 }, 0 );
				TE_SendToAll();
				
				War3_HealToBuffHP( attacker, RoundToFloor( damage * HealthMultiplier[skill_level] ) );
				W3FlashScreen( victim, RGBA_COLOR_RED );
			}
			
			new skill_dmg = War3_GetSkillLevel( attacker, thisRaceID, SKILL_DMG );
			if( !Hexed( attacker, false ) && GetRandomFloat( 0.0, 1.0 ) <= GenocideDMGChance[skill_dmg] && skill_dmg > 0 )
			{
				new String:wpnstr[32];
				GetClientWeapon( attacker, wpnstr, 32 );
				if( !StrEqual( wpnstr, "hegrenade" ) && !StrEqual( wpnstr, "weapon_knife" ) )
				{
					War3_DealDamage( victim, 10, attacker, DMG_BULLET, "genocide_crit" );
					
					W3PrintSkillDmgHintConsole( victim, attacker, War3_GetWar3DamageDealt(), SKILL_DMG );
					W3FlashScreen( victim, RGBA_COLOR_RED );
					
					new Float:pos[3];
					
					GetClientAbsOrigin( victim, pos );
					
					TE_SetupBeamRingPoint( pos, 20.0, 60.0, RingBeam, RingBeam, 0, 0, 1.0, 4.0, 0.0, { 255, 100, 0, 255 }, 0, FBEAM_ISACTIVE );
					TE_SendToAll();
				}
			}
		}
	}
}


public PlayerHurtEvent( Handle:event, const String:name[], bool:dontBroadcast )
{
	new victim = GetClientOfUserId( GetEventInt( event, "userid" ) );
	new attacker = GetClientOfUserId( GetEventInt( event, "attacker" ) );
	new String:weapon[64];
	GetEventString( event, "weapon", weapon, 64 );
	new damage = GetEventInt( event, "dmg_health" );
	
	if( victim > 0 && attacker > 0 && attacker != victim )
	{
		if( War3_GetRace( attacker ) == thisRaceID )
		{
			new skill_dmg = War3_GetSkillLevel( attacker, thisRaceID, SKILL_GRENADE );
			if( ValidPlayer( victim, true ) && skill_dmg > 0 )
			{
				if( StrEqual( weapon, "hegrenade" ) )
				{
					War3_DealDamage( victim, RoundToFloor( damage * DamageMultiplier[skill_dmg] ), attacker, DMG_BULLET, "genocide_grenade" );
					PrintHintText( victim, "Critical Grenade" );
					PrintHintText( attacker, "Critical Grenade" );
					
					new Float:pos[3];
					GetClientAbsOrigin( victim, pos );
					TE_SetupBeamRingPoint( pos, 20.0, 500.0, FlameSprite, FlameSprite, 0, 0, 2.0, 60.0, 0.8, { 255, 0, 0, 255 }, 1, FBEAM_ISACTIVE );
					TE_SendToAll();
					EmitSoundToAll( grenade, victim );
				}
			}
		}
	}
}

public OnUltimateCommand( client, race, bool:pressed )
{
	new userid = GetClientUserId( client );
	if( race == thisRaceID && pressed && userid > 1 && IsPlayerAlive( client ) && !Silenced( client ) )
	{
		new ult_level = War3_GetSkillLevel( client, race, ULT_DEJAVU );
		if( ult_level > 0 )
		{
			if( War3_SkillNotInCooldown( client, thisRaceID, ULT_DEJAVU, true ) && !bUltUsed[client] )
			{
				GetClientAbsOrigin( client, ClientPos[client] );
				GetClientEyeAngles( client, ClientAng[client] );
				Health[client] = GetClientHealth( client );
				
				g_hUltTimer[client] = CreateTimer( GenocideUltDuration[ult_level], TeleportClient, client );
				War3_CooldownMGR( client, GenocideUltDuration[ult_level] + 15.0, thisRaceID, ULT_DEJAVU);
				PrintHintText( client, "Deja Vu Activated!" );
				bUltUsed[client] = true;
			}
		}
		else
		{
			W3MsgUltNotLeveled( client );
		}
	}
}

public Action:TeleportClient( Handle:timer, any:client )
{
	if( bUltUsed[client] )
	{
		if( IsPlayerAlive( client ) )
		{
			SetEntityHealth( client, Health[client] );
			TeleportEntity( client, ClientPos[client], ClientAng[client], NULL_VECTOR );
		}
		else
		{
			War3_SpawnPlayer( client );
			SetEntityHealth( client, Health[client] );
			TeleportEntity( client, ClientPos[client], ClientAng[client], NULL_VECTOR );
			CreateTimer( 0.1, GivePlayerCachedDeathWPNFull, client );
		}
		PrintHintText( client, "Deja Vu" );
		bUltUsed[client] = false;
		g_hUltTimer[client] = INVALID_HANDLE;
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
					continue; // DONT REMOVE THESE
				}
				UTIL_Remove( ent );
			}
		}
		///NO RESETTING AMMO FOR FULL AMMO???
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
		
		new wep2 = GetPlayerWeaponSlot( client, 1 );
		if( !IsValidEdict( wep2 ) )
		{
			if( GetClientTeam( client ) == TEAM_T )
			{
				GivePlayerItem( client, "weapon_glock" );
			}
			else
			{
				GivePlayerItem( client, "weapon_usp" );
			}
		}
	}
}

public RoundOverEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	for(new i=1;i<=MaxClients;i++)
	{
		if(ValidPlayer(i) && (War3_GetRace( i ) == thisRaceID) )
		{
			bUltUsed[i] = true;
			
			if(g_hUltTimer[i] != INVALID_HANDLE)
			{
		        KillTimer(g_hUltTimer[i]);
		        g_hUltTimer[i]=INVALID_HANDLE;
		    }
		}
	}
}