/**
* File: War3Source_Strider_Hiryu.sp
* Description: The Strider Hiryu race for SourceCraft.
* Author(s): xDr.HaaaaaaaXx
*/

#pragma semicolon 1
#include <cstrike>
#include <sourcemod>
#include <sdktools_tempents>
#include <sdktools_functions>
#include <sdktools_tempents_stocks>
#include <sdktools_entinput>
#include <sdktools_sound>

#include "W3SIncs/War3Source_Interface"

// War3Source stuff
new thisRaceID, SKILL_FLY, SKILL_GRAV, SKILL_WARD, ULT_PORTAL;

// Chance/Data Arrays
// skill 1
new String:FlySoundOut[] = "weapons/mortar/mortar_explode1.wav";
new String:FlySoundIn[] = "weapons/mortar/mortar_explode3.wav";
new String:Temp1[MAXPLAYERS][32], String:Temp2[MAXPLAYERS][32];
new Float:FlyInvis[5] = { 1.0, 0.55, 0.45, 0.35, 0.25 };
new Float:FlySpeed[5] = { 1.0, 1.0, 2.0, 3.0, 4.0 };
new Float:FireSize[5] = { 0.0, 0.5, 1.0, 1.5, 2.0 };
new FlySprite;

// skill 2
new String:GravSound[] = "ambient/machines/teleport3.wav";
new Float:GravChance[5] = { 0.0, 0.1, 0.2, 0.3, 0.5 };
new Float:oldGrav[MAXPLAYERS];
new GravSprite1, GravSprite2;

// skill 3
#define MAXWARDS 64*4
#define WARDRADIUS 140
#define WARDDAMAGE 15
#define WARDBELOW -2.0
#define WARDABOVE 160.0

new WardStartingArr[] = { 0, 1, 2, 3, 4 };
new Float:LastThunderClap[MAXPLAYERS];
new Float:WardLocation[MAXWARDS][3];
new CurrentWardCount[MAXPLAYERS];
new BeamSprite, WardSprite;
new WardOwner[MAXWARDS];

// skill 4
new Float:SavedPos[MAXPLAYERS][3];
new bool:bSavedPos[MAXPLAYERS];

public Plugin:myinfo = 
{
	name = "War3Source Race - Strider Hiryu",
	author = "xDr.HaaaaaaaXx",
	description = "The Strider Hiryu race for War3Source.",
	version = "1.0.1",
	url = ""
};

public OnWar3PluginReady()
{
	thisRaceID = War3_CreateNewRace( "Strider Hiryu", "strider" );
	
	SKILL_FLY = War3_AddRaceSkill( thisRaceID, "Flying Dragon", "Hold +ability1 to fly, release to land.", false );
	SKILL_GRAV = War3_AddRaceSkill( thisRaceID, "Advanced High Jump", "Chance to Advance your High Jump Skill one level per kill", false );
	SKILL_WARD = War3_AddRaceSkill( thisRaceID, "Kayakujutsu", "The art of using fire and explosives (+ability)", false );
	ULT_PORTAL = War3_AddRaceSkill( thisRaceID, "Portal", "Press ultimate to save your location, press ultimate again to teleport to your saved location", true );

	W3SkillCooldownOnSpawn( thisRaceID, ULT_PORTAL, 5.0, _);

	War3_CreateRaceEnd( thisRaceID );
}

public OnMapStart()
{
	FlySprite = PrecacheModel( "sprites/fire.vmt" );
	GravSprite1 = PrecacheModel( "sprites/steam1.vmt" );
	GravSprite2 = PrecacheModel( "effects/strider_bulge_dudv_dx60.vmt" );
	BeamSprite = PrecacheModel( "sprites/lgtning.vmt" );
	WardSprite = PrecacheModel( "sprites/smoke.vmt" );
	War3_PrecacheSound( FlySoundOut );
	War3_PrecacheSound( FlySoundIn );
	War3_PrecacheSound( GravSound );
}

public OnPluginStart()
{
	HookEvent( "player_death", PlayerDeathEvent );
	CreateTimer( 0.14, CalcWards, _, TIMER_REPEAT );
}

public OnWar3PlayerAuthed( client )
{
	LastThunderClap[client] = 0.0;
}

public OnRaceChanged( client,oldrace,newrace )
{
	if( newrace != thisRaceID )
	{
		W3ResetAllBuffRace( client, thisRaceID );
		RemoveWards( client );
	}
}

public OnWar3EventSpawn( client )
{
	new race = War3_GetRace( client );
	if( race == thisRaceID )
	{
		War3_SetBuff( client, fLowGravitySkill, thisRaceID, 1.0 );
		oldGrav[client] = 1.0;
	}
	RemoveWards( client );
	bSavedPos[client] = false;
}

public PlayerDeathEvent( Handle:event, const String:name[], bool:dontBroadcast )
{
	new victim = GetClientOfUserId( GetEventInt( event, "userid" ) );
	new attacker = GetClientOfUserId( GetEventInt( event, "attacker" ) );
	if( victim > 0 && attacker > 0 && attacker != victim )
	{
		new skill_grav = War3_GetSkillLevel( attacker, thisRaceID, SKILL_GRAV );
		if( War3_GetRace( attacker ) == thisRaceID && skill_grav > 0 && GetRandomFloat( 0.0, 1.0 ) <= GravChance[skill_grav] )
		{
			new Float:newGrav = oldGrav[attacker] - 0.15;
			
			if( newGrav < 0.25 )
				newGrav = 0.25;
				
			if( oldGrav[attacker] > newGrav )
				oldGrav[attacker] = newGrav;
				
			War3_SetBuff( attacker, fLowGravitySkill, thisRaceID, newGrav );
			
			PrintToChat( attacker, "Your skill High Jump has advanced to the next level" );
			
			EmitSoundToAll( GravSound, attacker );
			
			new Float:attacker_pos[3];
			new Float:victim_pos[3];
			
			GetClientAbsOrigin( attacker, attacker_pos );
			GetClientAbsOrigin( victim, victim_pos );
			
			attacker_pos[2] += 50;
			victim_pos[2] -= 20;
			
			TE_SetupBeamRingPoint( attacker_pos, 90.0, 150.0, GravSprite1, GravSprite1, 0, 0, 3.0, 20.0, 2.0, { 15, 20, 255, 200 }, 1, FBEAM_ISACTIVE );
			TE_SendToAll();
			
			TE_SetupBeamPoints( attacker_pos, victim_pos, GravSprite2, GravSprite2, 0, 0, 3.0, 3.0, 13.0, 0, 0.0, { 155, 155, 155, 255 }, 0 );
			TE_SendToAll();
		}
	}
	if( ValidPlayer( victim, false ) )
	{
		new race = War3_GetRace( victim );
		if( race == thisRaceID )
		{
			War3_WeaponRestrictTo( victim, thisRaceID, "" );
		}
	}
	W3ResetAllBuffRace( victim, thisRaceID );
}

public OnAbilityCommand( client, ability, bool:pressed )
{
	if( War3_GetRace( client ) == thisRaceID && ability == 0 && pressed && IsPlayerAlive( client ) )
	{
		new skill_level = War3_GetSkillLevel( client, thisRaceID, SKILL_WARD );
		if( skill_level > 0 )
		{
			if( !Silenced( client ) && CurrentWardCount[client] < WardStartingArr[skill_level] )
			{
				CreateWard( client );
				CurrentWardCount[client]++;
				W3MsgCreatedWard( client, CurrentWardCount[client], WardStartingArr[skill_level] );
			}
			else
			{
				W3MsgNoWardsLeft( client );
			}
		}
	}
	
	if( War3_GetRace( client ) == thisRaceID && ability == 1 && pressed && IsPlayerAlive( client ) )
	{
		new skill_level = War3_GetSkillLevel( client, thisRaceID, SKILL_FLY );
		if( skill_level > 0 )
		{
			if( War3_SkillNotInCooldown( client, thisRaceID, SKILL_FLY, true ) )
			{
				if( ValidPlayer( client, true ) )
				{
					War3_SetBuff( client, bFlyMode, thisRaceID, true );
					War3_SetBuff( client, fMaxSpeed, thisRaceID, FlySpeed[War3_GetSkillLevel( client, thisRaceID, SKILL_FLY )] );
					War3_SetBuff( client, fInvisibilitySkill, thisRaceID, FlyInvis[War3_GetSkillLevel( client, thisRaceID, SKILL_FLY )] );
					
					new Float:pos[3];
					GetClientAbsOrigin( client, pos );
					
					pos[2] += 15;
					
					TE_SetupGlowSprite( pos, FlySprite, 2.0, FireSize[War3_GetSkillLevel( client, thisRaceID, SKILL_FLY )], 255 );
					TE_SendToAll();
					
					pos[1] += 50;
					
					TE_SetupGlowSprite( pos, FlySprite, 2.0, FireSize[War3_GetSkillLevel( client, thisRaceID, SKILL_FLY )], 255 );
					TE_SendToAll();
					
					EmitSoundToAll( FlySoundIn, client );
					
					new wep1 = GetPlayerWeaponSlot( client, CS_SLOT_PRIMARY );
					new wep2 = GetPlayerWeaponSlot( client, CS_SLOT_SECONDARY );
					new wep3 = GetPlayerWeaponSlot( client, 2 );
					
					EquipPlayerWeapon( client, wep3 );
					
					if( IsValidEdict( wep1 ) )
						GetEdictClassname( wep1, Temp1[client], 32 );
						
					if( IsValidEdict( wep2 ) )
						GetEdictClassname( wep2, Temp2[client], 32 );
					
					if( IsValidEdict( wep1 ) )
						UTIL_Remove( wep1 );
						
					if( IsValidEdict( wep2 ) )
						UTIL_Remove( wep2 );
					
					War3_WeaponRestrictTo( client, thisRaceID, "weapon_knife" );
				}
			}
		}
	}
	
	if( War3_GetRace( client ) == thisRaceID && ability == 1 && !pressed && IsPlayerAlive( client ) )
	{
		new skill_level = War3_GetSkillLevel( client, thisRaceID, SKILL_FLY );
		if( skill_level > 0 )
		{
			if( War3_SkillNotInCooldown( client, thisRaceID, SKILL_FLY, true ) )
			{
				if( ValidPlayer( client, true ) )
				{
					War3_SetBuff( client, bFlyMode, thisRaceID, false );
					War3_SetBuff( client, fMaxSpeed, thisRaceID, 1.0 );
					War3_SetBuff( client, fInvisibilitySkill, thisRaceID, 1.0 );
					War3_WeaponRestrictTo( client, thisRaceID, "" );
					
					new Float:pos[3];
					GetClientAbsOrigin( client, pos );
					
					pos[2] += 15;
					
					TE_SetupGlowSprite( pos, FlySprite, 2.0, FireSize[War3_GetSkillLevel( client, thisRaceID, SKILL_FLY )], 255 );
					TE_SendToAll();
					
					pos[1] += 50;
					
					TE_SetupGlowSprite( pos, FlySprite, 2.0, FireSize[War3_GetSkillLevel( client, thisRaceID, SKILL_FLY )], 255 );
					TE_SendToAll();
					
					EmitSoundToAll( FlySoundOut, client );
					
					GivePlayerItem( client, Temp1[client] );
					GivePlayerItem( client, Temp2[client] );
					
					War3_CooldownMGR( client, 3.0, thisRaceID, SKILL_FLY);
				}
			}
		}
	}
}

public CreateWard( client )
{
	for( new i = 0; i < MAXWARDS; i++ )
	{
		if( WardOwner[i] == 0 )
		{
			WardOwner[i] = client;
			GetClientAbsOrigin( client, WardLocation[i] );
			break;
		}
	}
}

public RemoveWards( client )
{
	for( new i = 0; i < MAXWARDS; i++ )
	{
		if( WardOwner[i] == client )
		{
			WardOwner[i] = 0;
		}
	}
	CurrentWardCount[client] = 0;
}

public Action:CalcWards( Handle:timer, any:userid )
{
	new client;
	for( new i = 0; i < MAXWARDS; i++ )
	{
		if( WardOwner[i] != 0 )
		{
			client = WardOwner[i];
			if( !ValidPlayer( client, true ) )
			{
				WardOwner[i] = 0;
				--CurrentWardCount[client];
			}
			else
			{
				WardEffectAndDamage( client, i );
			}
		}
	}
}

public WardEffectAndDamage( owner, wardindex )
{
	new ownerteam = GetClientTeam( owner );
	new beamcolor[] = { 0, 0, 200, 255 };
	if( ownerteam == 2 )
	{
		beamcolor[0] = 255;
		beamcolor[1] = 0;
		beamcolor[2] = 0;
		beamcolor[3] = 255;
	}
	
	new Float:start_pos[3];
	new Float:end_pos[3];
	new Float:tempVec1[] = { 0.0, 0.0, WARDBELOW };
	new Float:tempVec2[] = { 0.0, 0.0, WARDABOVE };
	
	AddVectors( WardLocation[wardindex], tempVec1, start_pos );
	AddVectors( WardLocation[wardindex], tempVec2, end_pos );

	TE_SetupBeamPoints( start_pos, end_pos, BeamSprite, BeamSprite, 0, GetRandomInt( 30, 100 ), 0.17, 20.0, 20.0, 0, 0.0, { 10, 50, 255, 170 }, 0 );
	TE_SendToAll();
	
	TE_SetupBeamRingPoint( start_pos, float( WARDRADIUS * 2 ), 5.0, GravSprite2, GravSprite2, 0, 15, 1.0, 5.0, 1.0, { 255, 250, 70, 10 }, 10, FBEAM_ISACTIVE );
	TE_SendToAll();
	
	TE_SetupGlowSprite( end_pos, GravSprite2, 1.0, 1.0, 50 );
	TE_SendToAll();
	
	new Float:BeamXY[3];
	for( new x = 0; x < 3; x++ ) BeamXY[x] = start_pos[x];
	new Float:BeamZ = BeamXY[2];
	BeamXY[2] = 0.0;
	
	new Float:VictimPos[3];
	new Float:tempZ;
	for( new i = 1; i <= MaxClients; i++ )
	{
		if( ValidPlayer( i, true ) && GetClientTeam(i) != ownerteam )
		{
			GetClientAbsOrigin( i, VictimPos );
			tempZ = VictimPos[2];
			VictimPos[2] = 0.0;
			
			if( GetVectorDistance( BeamXY, VictimPos ) < WARDRADIUS )
			{
				if( tempZ > BeamZ + WARDBELOW && tempZ < BeamZ + WARDABOVE )
				{
					if( !W3HasImmunity( i, Immunity_Skills ) )
					{
						if( LastThunderClap[i] < GetGameTime() - 1 )
						{
							new DamageScreen[4];
							new Float:pos[3];
							
							GetClientAbsOrigin( i, pos );
							
							DamageScreen[0] = beamcolor[0];
							DamageScreen[1] = beamcolor[1];
							DamageScreen[2] = beamcolor[2];
							DamageScreen[3] = 50;
							
							W3FlashScreen( i, DamageScreen );
							
							War3_DealDamage( i, WARDDAMAGE, owner, DMG_ENERGYBEAM, "wards", _, W3DMGTYPE_MAGIC );
							
							IgniteEntity( i, 2.0 );
							
							pos[2] += 40;
							
							TE_SetupBeamPoints( end_pos, pos, GravSprite2, GravSprite2, 0, 0, 0.5, 3.0, 6.0, 0, 0.0, { 255, 255, 225, 255 }, 0 );
							TE_SendToAll();
							
							TE_SetupSmoke( pos, WardSprite, 100.0, 10 );
							TE_SendToAll();
							
							TE_SetupGlowSprite( pos, WardSprite, 1.0, 1.0, 255 );
							TE_SendToAll();
							
							PrintToChat( i, "\x05: \x03You have been hit by \x04Kayakujutsu\x03!" );
							
							EmitSoundToAll( FlySoundOut, i, SNDCHAN_WEAPON );
							LastThunderClap[i] = GetGameTime();
						}
					}
				}
			}
		}
	}
}

public OnUltimateCommand( client, race, bool:pressed )
{
	if( race == thisRaceID && pressed && ValidPlayer( client, true ) )
	{
		new ult_level = War3_GetSkillLevel( client, race, ULT_PORTAL );
		if( ult_level > 0 )		
		{
			if( War3_SkillNotInCooldown( client, thisRaceID, ULT_PORTAL, true ) ) 
			{
				ToggleTeleport( client );
				War3_CooldownMGR( client, 3.0, thisRaceID, ULT_PORTAL);
			}
		}
		else
		{
			PrintHintText( client, "Level Your Ultimate First" );
		}
	}
}

stock Teleport( client )
{
	if( bSavedPos[client] )
	{
		bSavedPos[client] = false;
		TeleportEntity( client, SavedPos[client], NULL_VECTOR, NULL_VECTOR );
		PrintToChat( client, "\x05: \x03You have Teleported to your saved location!" );
	}
}

stock SavePos( client )
{
	if ( !bSavedPos[client] )
	{
		bSavedPos[client] = true;
		GetClientAbsOrigin( client, SavedPos[client] );
		PrintToChat( client, "\x05: \x03You have created a Portal! Press +ultimate again to Telport to this location." );
	}
}

stock ToggleTeleport( client )
{
	if( bSavedPos[client] )
	{
		Teleport( client );
	}
	else
	{
		SavePos( client );
	}
}