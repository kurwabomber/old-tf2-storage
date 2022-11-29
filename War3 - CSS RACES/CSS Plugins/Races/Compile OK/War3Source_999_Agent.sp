/**
* File: War3Source_Agent.sp
* Description: The Agent race for SourceCraft.
* Author(s): xDr.HaaaaaaaXx
*/

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdktools_stocks>
#include <sdktools_functions>

#include "W3SIncs/War3Source_Interface"

// War3Source stuff
new thisRaceID, SKILL_SPEED, SKILL_VISIB, SKILL_MOLE, ULT_AWP;

new Float:DamageMultiplier[5] = { 0.0, 0.16, 0.19, 0.21, 0.24 };
new Float:MoleChance[5] = { 0.0, 0.04, 0.07, 0.11, 0.15 };
new Float:AgentSpeed[5] = { 1.0, 1.15, 1.20, 1.25, 1.32 };
new Float:UltDuration[5] = { 0.0, 10.0, 15.0, 20.0, 25.0 };

new String:sOldModel[MAXPLAYERS][256];
new String:wep[MAXPLAYERS][64];

new String:Spawn[] = "doors/heavy_metal_stop1.wav";

new OriginOffset;

new HaloSprite, BeamSprite;

public Plugin:myinfo = 
{
	name = "War3Source Race - Agent",
	author = "xDr.HaaaaaaaXx & Revan",
	description = "The Agent race for War3Source.",
	version = "1.0.0.1",
	url = ""
};

public OnPluginStart()
{
	OriginOffset = FindSendPropOffs( "CBaseEntity", "m_vecOrigin" );
}

public OnMapStart()
{
	HaloSprite = PrecacheModel( "materials/sprites/halo01.vmt" );
	BeamSprite = PrecacheModel( "sprites/tp_beam001.vmt" );
	War3_PrecacheSound( Spawn );
}

public OnWar3PluginReady()
{
	thisRaceID = War3_CreateNewRace( "Agent", "agent" );
	
	SKILL_SPEED = War3_AddRaceSkill( thisRaceID, "High Speed", "You become a lot faster(32% if maxed)", false, 4 );	
	SKILL_VISIB = War3_AddRaceSkill( thisRaceID, "Shades of Visibility", "Invisible players become visible upon hit!", false, 4 );	
	SKILL_MOLE = War3_AddRaceSkill( thisRaceID, "Double Agent", "Disguise yourself as an enemy Spy!", false, 4 );
	ULT_AWP = War3_AddRaceSkill( thisRaceID, "Ultimate Artillery", "Exchange your current weapon for an AK-47 for 10-25 seconds!", true, 4 );

	War3_CreateRaceEnd( thisRaceID );
}

public InitPassiveSkills( client )
{
	if( War3_GetRace( client ) == thisRaceID )
	{
		War3_SetBuff( client, fMaxSpeed, thisRaceID, AgentSpeed[War3_GetSkillLevel( client, thisRaceID, SKILL_SPEED )] );
	}
}

public OnRaceChanged( client, oldrace, newrace )
{
	if( newrace != thisRaceID )
	{
		War3_SetBuff( client, fMaxSpeed, thisRaceID, 1.0 );
	}
	else
	{
		if( IsPlayerAlive( client ) )
		{
			InitPassiveSkills( client );
			GivePlayerItem( client, "weapon_m4a1" );
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
		new skill_level = War3_GetSkillLevel( client, thisRaceID, SKILL_MOLE );
		if( GetRandomFloat( 0.0, 1.0 ) <= MoleChance[skill_level])
		{
			StartMole( client );
		}
		EmitSoundToAll( Spawn, client );
		GivePlayerItem( client, "weapon_m4a1" );

		new Float:client_pos[3];			
		GetClientAbsOrigin( client, client_pos );
		TE_SetupBeamRingPoint(client_pos,10.0,60.0,BeamSprite,HaloSprite,0,45,3.0,15.0,0.0,{255,255,255,255},1,0);
		TE_SendToAll();
		TE_SetupGlowSprite(client_pos, HaloSprite, 1.5, 1.0, 255);
		TE_SendToAll();
	}
}

public OnWar3EventPostHurt(victim, attacker, Float:damage, const String:weapon[32], bool:isWarcraft)
{
	if( W3GetDamageIsBullet() && ValidPlayer( victim, true ) && ValidPlayer( attacker, true ) && GetClientTeam( victim ) != GetClientTeam( attacker ) )
	{
		if( War3_GetRace( attacker ) == thisRaceID )
		{
			new skill_dmg = War3_GetSkillLevel( attacker, thisRaceID, SKILL_VISIB );
			if( !Hexed( attacker, false ) && skill_dmg > 0 && GetRandomFloat( 0.0, 1.0 ) <= 0.15 )
			{
				new String:wpnstr[32];
				GetClientWeapon( attacker, wpnstr, 32 );
				if( !StrEqual( wpnstr, "wep_knife" ) )
				{
					War3_DealDamage( victim, RoundToFloor( damage * DamageMultiplier[skill_dmg] ), attacker, DMG_BULLET, "agent_crit" );
					W3ResetBuffRace( victim, fInvisibilitySkill, War3_GetRace( victim ) );
				
					W3PrintSkillDmgHintConsole( victim, attacker, War3_GetWar3DamageDealt(), SKILL_VISIB );
					
					W3FlashScreen( victim, RGBA_COLOR_RED );
					
					new Float:victim_pos[3];
					new Float:attacker_pos[3];
					
					GetClientAbsOrigin( victim, victim_pos );
					GetClientAbsOrigin( attacker, attacker_pos );
					
					victim_pos[2] += 40;
					attacker_pos[2] += 40;
					
					TE_SetupBeamPoints( attacker_pos, victim_pos, BeamSprite, HaloSprite, 0, 0, 3.0, 6.0, 12.0, 0, 0.0, { 155, 155, 155, 255 }, 0 );
					TE_SendToAll();
					attacker_pos[2]+=5.0;
					victim_pos[2]+=5.0;
					TE_SetupBeamPoints( attacker_pos, victim_pos, HaloSprite, HaloSprite, 0, 0, 2.0, 5.0, 6.0, 0, 0.0, { 180, 180, 180, 235 }, 0 );
					TE_SendToAll();
				}
			}
		}
	}
}

public OnUltimateCommand(client,race,bool:pressed)
{
	if( race == thisRaceID && pressed && ValidPlayer( client, true ) )
	{
		new ult_level = War3_GetSkillLevel( client, race, ULT_AWP );
		if( ult_level > 0 )
		{
			if( War3_SkillNotInCooldown( client, thisRaceID, ULT_AWP, true ) )
			{
				RingEffectPlayer(client);
				GetClientWeapon( client, wep[client], 64 );
				RemovePlayerItem( client, W3GetCurrentWeaponEnt( client ) );
				GivePlayerItem( client, "weapon_ak47" );
				CreateTimer( UltDuration[ult_level], GiveWeapon, client );
				War3_CooldownMGR( client, UltDuration[ult_level] + 5.0, thisRaceID, ULT_AWP, _, true );
			}
		}
		else
		{
			PrintHintText( client, "Level Your Ultimate First" );
		}
	}
}

public Action:GiveWeapon( Handle:timer, any:client )
{
	if(ValidPlayer(client,true))
	{
		//let's check if he's wearing the AK, and not something else..
		RingEffectPlayer(client);
		new String:AKweapon[64];
		GetClientWeapon(client,AKweapon,64);
		if(StrEqual(AKweapon, "weapon_ak47",false))
		{
			RemovePlayerItem( client, W3GetCurrentWeaponEnt( client ) );
			GivePlayerItem( client, wep[client] );
		}
		else
		{
			//not wearing the AK? well, then let's just re-call the timer until he IS wearing it, then strip it off of him :d
			CreateTimer(1.0,GiveWeapon,client);
		}
	}
}

public RingEffectPlayer(client)
{
	new Float:client_pos[3];			
	GetClientAbsOrigin( client, client_pos );
	TE_SetupBeamRingPoint(client_pos,82.0,28.0,HaloSprite,HaloSprite,0,20,3.0,5.0,12.0,{255,255,255,255},0,0);
	TE_SendToAll();
	TE_SetupBeamRingPoint(client_pos,72.0,5.0,HaloSprite,HaloSprite,0,40,3.0,1.0,2.0,{255,150,150,255},5,0);
	TE_SendToAll(0.35);
}

public StartMole( client )
{
	new Float:mole_time = 5.0;
	W3MsgMoleIn( client, mole_time );
	CreateTimer( 0.2 + mole_time, DoMole, client );
}

public Action:DoMole( Handle:timer, any:client )
{
	if( ValidPlayer( client, true ) )
	{
		new team = GetClientTeam( client );
		new searchteam = ( team == 2 )?3:2;
		
		new Float:emptyspawnlist[100][3];
		new availablelocs = 0;
		
		new Float:playerloc[3];
		new Float:spawnloc[3];
		new ent = -1;
		while( ( ent = FindEntityByClassname( ent, ( searchteam == 2 )?"info_player_terrorist":"info_player_counterterrorist" ) ) != -1 )
		{
			if( !IsValidEdict( ent ) ) continue;
			GetEntDataVector( ent, OriginOffset, spawnloc );
			
			new bool:is_conflict = false;
			for( new i = 1; i <= MaxClients; i++ )
			{
				if( ValidPlayer( i, true ) )
				{
					GetClientAbsOrigin( i, playerloc );
					if( GetVectorDistance( spawnloc, playerloc ) < 60.0 )
					{
						is_conflict = true;
						break;
					}				
				}
			}
			if( !is_conflict )
			{
				emptyspawnlist[availablelocs][0] = spawnloc[0];
				emptyspawnlist[availablelocs][1] = spawnloc[1];
				emptyspawnlist[availablelocs][2] = spawnloc[2];
				availablelocs++;
			}
		}
		if( availablelocs == 0 )
		{
			//War3_ChatMessage( client, "%T", "No suitable location found, can not mole!", client );
			PrintToChat(client,"\x04No suitable location found, can not mole!");
			return;
		}
		GetClientModel( client, sOldModel[client], 256 );
		SetEntityModel( client, ( searchteam == 2 )?"models/player/t_leet.mdl":"models/player/ct_urban.mdl" );
		TeleportEntity( client, emptyspawnlist[GetRandomInt( 0, availablelocs - 1 )], NULL_VECTOR, NULL_VECTOR );
		W3MsgMoled( client );
		War3_ShakeScreen( client, 3.0, 30.0, 16.0 );
	}
	return;
}
