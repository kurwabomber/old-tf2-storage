/**
* File: War3Source_Vagabond.sp
* Description: The Vagabond race for SourceCraft.
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
new thisRaceID, SKILL_SPEED, SKILL_SCOUT, SKILL_LOWGRAV, ULT_INVIS_TELE;

// Chance/Data Arrays
new col1[4], col2[4], col3[4], col4[4], col5[4], col6[4], col7[4], col8[4], col9[4];
new Float:VagabondGravity[5] = { 1.0, 0.6, 0.52, 0.44, 0.35 };
new Float:VagabondSpeed[5] = { 1.0, 1.1, 1.2, 1.3, 1.35 };
new Float:DamageChanse[5] = { 0.0, 0.28, 0.44, 0.60, 0.70 };
new Float:PushForce[5] = { 0.0, 0.4, 0.7, 1.0, 1.3 };
new Float:UltMaxDuration[5] = { 0.0, 10.0, 11.66, 13.33, 15.0 };
new Float:UltDelay[5] = { 0.0, 15.0, 15.0, 15.0, 15.0 };
new Float:LaserDuration = 15.0;
new ClientLaserCount[MAXPLAYERS+1] = {0, ...};
new MaxLasers = 2;
new bool:bIsInvisible[MAXPLAYERS+1] = {false, ...};
new bool:bIsJumping[MAXPLAYERS+1] = {false, ...};
new Float:fUltBlockRadius = 300.0;

// Sounds
new String:UltOutstr[] = "weapons/physcannon/physcannon_claws_close.wav";
new String:UltInstr[] = "weapons/physcannon/physcannon_claws_open.wav";
new String:spawnsound[] = "ambient/atmosphere/cave_hit2.wav";

// Other
new HaloSprite, BeamSprite, SteamSprite;
new m_vecBaseVelocity;

public Plugin:myinfo = 
{
	name = "War3Source Race - Vagabond",
	author = "xDr.HaaaaaaaXx",
	description = "The Vagabond race for War3Source.",
	version = "1.0.0.1",
	url = ""
};

public OnPluginStart()
{
	m_vecBaseVelocity = FindSendPropOffs( "CBasePlayer", "m_vecBaseVelocity" );
	col1[3] = 255;
	col2[3] = 255;
	col3[3] = 255;
	col4[3] = 255;
	col5[3] = 255;
	col6[3] = 255;
	col7[3] = 255;
	col8[3] = 255;
	col9[3] = 255;
}

public OnMapStart()
{
	HaloSprite = PrecacheModel( "materials/sprites/halo01.vmt" );
	BeamSprite = PrecacheModel( "materials/sprites/laser.vmt" );
	SteamSprite = PrecacheModel( "sprites/steam1.vmt" );
	War3_PrecacheSound( UltInstr );
	War3_PrecacheSound( UltOutstr );
	War3_PrecacheSound( spawnsound );
}

public OnWar3PluginReady()
{
	thisRaceID = War3_CreateNewRace( "Vagabond", "vagabond" );
	
	SKILL_SPEED = War3_AddRaceSkill( thisRaceID, "Adrinaline", "Speed", false );	
	SKILL_SCOUT = War3_AddRaceSkill( thisRaceID, "Scout", "Extra Damage", false );	
	SKILL_LOWGRAV = War3_AddRaceSkill( thisRaceID, "Levitation", "Levitation", false );
	ULT_INVIS_TELE = War3_AddRaceSkill( thisRaceID, "Complete Invisibility", "Teleport and Become Completly invisible when not moving(can't move)", true );
	
	W3SkillCooldownOnSpawn( thisRaceID, ULT_INVIS_TELE, 5.0, _);
	
	War3_CreateRaceEnd( thisRaceID );
}

public InitPassiveSkills( client )
{
	if( War3_GetRace( client ) == thisRaceID )
	{
		ClientLaserCount[client] = 0;
		bIsInvisible[client] = false;
		bIsJumping[client] = false;
		War3_SetBuff( client, fMaxSpeed, thisRaceID, VagabondSpeed[War3_GetSkillLevel( client, thisRaceID, SKILL_SPEED )] );
		War3_SetBuff( client, fLowGravitySkill, thisRaceID, VagabondGravity[War3_GetSkillLevel( client, thisRaceID, SKILL_LOWGRAV )] );
		War3_WeaponRestrictTo( client, thisRaceID, "weapon_knife,weapon_scout" );
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
		War3_WeaponRestrictTo( client, thisRaceID, "weapon_knife,weapon_scout" );
		if( IsPlayerAlive( client ) )
		{
			GivePlayerItem( client, "weapon_scout" );
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
	StopInvis( client );
	new race = War3_GetRace( client );
	if( race == thisRaceID )
	{
		GivePlayerItem( client, "weapon_scout" );
		InitPassiveSkills( client );
		EmitSoundToAll( spawnsound, client );
	}
}

public OnWar3EventDeath( victim, attacker )
{
	W3ResetAllBuffRace( victim, thisRaceID );
}

public OnW3TakeDmgBullet(victim, attacker, Float:damage )
{
	if( ValidPlayer( victim, true ) && ValidPlayer( attacker, true ) && GetClientTeam( victim ) != GetClientTeam( attacker ) )
	{
		if( War3_GetRace( attacker ) == thisRaceID )
		{
			new String:wpnstr[32];
			GetClientWeapon( attacker, wpnstr, 32 );
			new ult_level = War3_GetSkillLevel( attacker, thisRaceID, ULT_INVIS_TELE );
			if ( !Hexed( attacker, false ) && ult_level > 0 && bIsInvisible[attacker] && ClientLaserCount[attacker] < MaxLasers)
			{
				if( StrEqual( wpnstr, "weapon_scout" ) )
				{
					col1[0] = GetRandomInt( 0, 255 );
					col1[1] = GetRandomInt( 0, 255 );
					col1[2] = GetRandomInt( 0, 255 );
	
					col2[0] = GetRandomInt( 0, 255 );
					col2[1] = GetRandomInt( 0, 255 );
					col2[2] = GetRandomInt( 0, 255 );
	
					col3[0] = GetRandomInt( 0, 255 );
					col3[1] = GetRandomInt( 0, 255 );
					col3[2] = GetRandomInt( 0, 255 );
	
					col4[0] = GetRandomInt( 0, 255 );
					col4[1] = GetRandomInt( 0, 255 );
					col4[2] = GetRandomInt( 0, 255 );
	
					col5[0] = GetRandomInt( 0, 255 );
					col5[1] = GetRandomInt( 0, 255 );
					col5[2] = GetRandomInt( 0, 255 );
	
					col6[0] = GetRandomInt( 0, 255 );
					col6[1] = GetRandomInt( 0, 255 );
					col6[2] = GetRandomInt( 0, 255 );
	
					col7[0] = GetRandomInt( 0, 255 );
					col7[1] = GetRandomInt( 0, 255 );
					col7[2] = GetRandomInt( 0, 255 );
	
					col8[0] = GetRandomInt( 0, 255 );
					col8[1] = GetRandomInt( 0, 255 );
					col8[2] = GetRandomInt( 0, 255 );
	
					col9[0] = GetRandomInt( 0, 255 );
					col9[1] = GetRandomInt( 0, 255 );
					col9[2] = GetRandomInt( 0, 255 );
					
					new Float:start_pos[3];
					new Float:target_pos[3];
					
					GetClientAbsOrigin( attacker, start_pos );
					GetClientAbsOrigin( victim, target_pos );
					
					target_pos[2] += 40;
					
					// 1
					start_pos[0] += GetRandomFloat( -500.0, 500.0 );
					start_pos[1] += GetRandomFloat( -500.0, 500.0 );
					start_pos[2] += 40;
					
					TE_SetupBeamPoints( start_pos, target_pos, BeamSprite, HaloSprite, 0, 0, LaserDuration, 10.0, 10.0, 0, 0.0, col1, 40 );
					TE_SendToAll();
					
					// 2
					GetClientAbsOrigin( attacker, start_pos );
					
					start_pos[0] += GetRandomFloat( -500.0, 500.0 );
					start_pos[1] += GetRandomFloat( -500.0, 500.0 );
					start_pos[2] += 40;

					TE_SetupBeamPoints( start_pos, target_pos, BeamSprite, HaloSprite, 0, 0, LaserDuration, 10.0, 10.0, 0, 0.0, col2, 40 );
					TE_SendToAll();
					
					// 3
					GetClientAbsOrigin( attacker, start_pos );
					
					start_pos[0] += GetRandomFloat( -500.0, 500.0 );
					start_pos[1] += GetRandomFloat( -500.0, 500.0 );
					start_pos[2] += 40;

					TE_SetupBeamPoints( start_pos, target_pos, BeamSprite, HaloSprite, 0, 0, LaserDuration, 10.0, 10.0, 0, 0.0, col3, 40 );
					TE_SendToAll();
					
					// 4
					GetClientAbsOrigin( attacker, start_pos );
					
					start_pos[0] += GetRandomFloat( -500.0, 500.0 );
					start_pos[1] += GetRandomFloat( -500.0, 500.0 );
					start_pos[2] += 40;

					TE_SetupBeamPoints( start_pos, target_pos, BeamSprite, HaloSprite, 0, 0, LaserDuration, 10.0, 10.0, 0, 0.0, col4, 40 );
					TE_SendToAll();
					
					// 5
					GetClientAbsOrigin( attacker, start_pos );
					
					start_pos[0] += GetRandomFloat( -500.0, 500.0 );
					start_pos[1] += GetRandomFloat( -500.0, 500.0 );
					start_pos[2] += 40;

					TE_SetupBeamPoints( start_pos, target_pos, BeamSprite, HaloSprite, 0, 0, LaserDuration, 10.0, 10.0, 0, 0.0, col5, 40 );
					TE_SendToAll();
					
					// 6
					GetClientAbsOrigin( attacker, start_pos );
					
					start_pos[0] += GetRandomFloat( -500.0, 500.0 );
					start_pos[1] += GetRandomFloat( -500.0, 500.0 );
					start_pos[2] += 40;

					TE_SetupBeamPoints( start_pos, target_pos, BeamSprite, HaloSprite, 0, 0, LaserDuration, 10.0, 10.0, 0, 0.0, col6, 40 );
					TE_SendToAll();
					
					// 7
					GetClientAbsOrigin( attacker, start_pos );
					
					start_pos[0] += GetRandomFloat( -500.0, 500.0 );
					start_pos[1] += GetRandomFloat( -500.0, 500.0 );
					start_pos[2] += 40;

					TE_SetupBeamPoints( start_pos, target_pos, BeamSprite, HaloSprite, 0, 0, LaserDuration, 10.0, 10.0, 0, 0.0, col7, 40 );
					TE_SendToAll();
					
					// 8
					GetClientAbsOrigin( attacker, start_pos );
					
					start_pos[0] += GetRandomFloat( -500.0, 500.0 );
					start_pos[1] += GetRandomFloat( -500.0, 500.0 );
					start_pos[2] += 40;

					TE_SetupBeamPoints( start_pos, target_pos, BeamSprite, HaloSprite, 0, 0, LaserDuration, 10.0, 10.0, 0, 0.0, col8, 40 );
					TE_SendToAll();
					
					// 9
					GetClientAbsOrigin( attacker, start_pos );
					
					start_pos[2] += 40;
					target_pos[2] += 5;

					TE_SetupBeamPoints( start_pos, target_pos, BeamSprite, HaloSprite, 0, 0, LaserDuration, 10.0, 10.0, 0, 0.0, col9, 40 );
					TE_SendToAll();
					
					
					ClientLaserCount[attacker]++;
					CreateTimer( LaserDuration, DecrementLaserCount, attacker );
				}
			}
		}
	}
}

public OnWar3EventPostHurt(victim, attacker, Float:damage, const String:weapon[32], bool:isWarcraft)
{
	if( W3GetDamageIsBullet() && ValidPlayer( victim, true ) && ValidPlayer( attacker, true ) && GetClientTeam( victim ) != GetClientTeam( attacker ) )
	{
		if( War3_GetRace( attacker ) == thisRaceID )
		{
			new String:wpnstr[32];
			GetClientWeapon( attacker, wpnstr, 32 );
			
			new skill_level = War3_GetSkillLevel( attacker, thisRaceID, SKILL_SCOUT );
			if( !Hexed( attacker, false ) && GetRandomFloat( 0.0, 1.0 ) <= DamageChanse[skill_level] )
			{
				if( !W3HasImmunity( victim, Immunity_Skills ) )
				{
					if( StrEqual( wpnstr, "weapon_scout" ) )
					{
						War3_DealDamage( victim, RoundToFloor(damage/2.0), attacker, DMG_BULLET, "vagabond_crit" );
						W3FlashScreen( victim, RGBA_COLOR_RED );
						
						if (!bIsInvisible[attacker])
						{
							new Float:start_pos[3];
							new Float:target_pos[3];
						
							GetClientAbsOrigin( attacker, start_pos );
							GetClientAbsOrigin( victim, target_pos );
						
							TE_SetupBeamPoints( start_pos, target_pos, BeamSprite, HaloSprite, 0, 0, 1.0, 3.0, 6.0, 0, 0.0, { 100, 255, 55, 255 }, 0 );
							TE_SendToAll();
						}

						W3PrintSkillDmgHintConsole( victim, attacker, War3_GetWar3DamageDealt(), SKILL_SCOUT );
					}
				}
			}
		}
	}
}

public OnUltimateCommand( client, race, bool:pressed )
{
	new userid = GetClientUserId( client );
	if( race == thisRaceID && pressed && userid > 1 && IsPlayerAlive( client ) && !Silenced( client ) && !bIsJumping[client] )
	{
		new ult_level = War3_GetSkillLevel( client, race, ULT_INVIS_TELE );
		if( ult_level > 0 )
		{
			if( War3_SkillNotInCooldown( client, thisRaceID, ULT_INVIS_TELE, true ) )
			{
                new Float:clientPos[3];
                GetClientAbsOrigin(client, clientPos);
                new bool:ultBlocked = false;
                
				if( !bIsInvisible[client] )
				{
                    for (new i=1; i<=MaxClients; i++)
                    {
                        if (i!=client && ValidPlayer(i, true) && GetClientTeam(i)!=GetClientTeam(client))
                        {
                            new Float:iPos[3];
                            GetClientAbsOrigin(i, iPos);
                            if (GetVectorDistance(clientPos, iPos)<=fUltBlockRadius && IsUltImmune(i))
                            {
                                ultBlocked = true;
                                W3MsgUltimateBlocked(client);
                                break;
                            }
                        }
                    }
                    if (!ultBlocked)
                    {
                        ToggleInvisibility( client );
                        TeleportPlayer( client );
                        War3_CooldownMGR( client, 0.5, thisRaceID, ULT_INVIS_TELE);
                    }
				}
				else
				{
					ToggleInvisibility( client );
					War3_CooldownMGR( client, UltDelay[ult_level], thisRaceID, ULT_INVIS_TELE);
				}
				
                if (!ultBlocked)
                {
                    clientPos[2] += 50;
                    
                    TE_SetupGlowSprite( clientPos, SteamSprite, 1.0, 2.5, 130 );
                    TE_SendToAll();
                }
			}
		}
		else
		{
			W3MsgUltNotLeveled( client );
		}
	}
}

stock StopInvis( client )
{
	if( bIsInvisible[client] )
	{
		bIsInvisible[client] = false;
		ClientLaserCount[client] = 0;
		War3_SetBuff( client, bNoMoveMode, thisRaceID, false );
		War3_SetBuff( client, fInvisibilitySkill, thisRaceID, 1.0 );
		EmitSoundToAll( UltOutstr, client );
	}
}

stock StartInvis( client )
{
	if ( !bIsInvisible[client] )
	{
		bIsInvisible[client] = true;
		bIsJumping[client] = true;
		ClientLaserCount[client] = 0;
		CreateTimer( 1.0, StartStop, client );
		War3_SetBuff( client, fInvisibilitySkill, thisRaceID, 0.0 );
		EmitSoundToAll( UltInstr, client );
		new ult_skill = War3_GetSkillLevel( client, thisRaceID, ULT_INVIS_TELE );
		CreateTimer( UltMaxDuration[ult_skill], StopInvisDelayed, client );
		PrintHintText(client, "You will stop being invis in %i seconds.", RoundToFloor(UltMaxDuration[ult_skill]));
	}
}

public Action:StopInvisDelayed( Handle:timer, any:client )
{
	if ( ValidPlayer( client, true ) && bIsInvisible[client] )
	{
		StopInvis( client );
		new ult_level = War3_GetSkillLevel( client, thisRaceID, ULT_INVIS_TELE );
		War3_CooldownMGR( client, UltDelay[ult_level], thisRaceID, ULT_INVIS_TELE);
	}
}

public Action:StartStop( Handle:timer, any:client )
{
	if( ValidPlayer( client, true ) )
	{
		War3_SetBuff( client, bNoMoveMode, thisRaceID, true );
		bIsJumping[client] = false;
	}
}

public Action:DecrementLaserCount( Handle:timer, any:client )
{
	if ( ValidPlayer( client, true ) )
	{
		if (ClientLaserCount[client] > 0)
		{
			ClientLaserCount[client]--;
		}
	}
}

stock ToggleInvisibility( client )
{
	if( bIsInvisible[client] )
	{
		StopInvis( client );
	}
	else
	{
		StartInvis( client );
	}
}

stock TeleportPlayer( client )
{
	if( client > 0 && IsPlayerAlive( client ) )
	{
		new ult_level = War3_GetSkillLevel( client, thisRaceID, ULT_INVIS_TELE );
		new Float:startpos[3];
		new Float:endpos[3];
		new Float:localvector[3];
		new Float:velocity[3];
		
		GetClientAbsOrigin( client, startpos );
		War3_GetAimEndPoint( client, endpos );
		
		localvector[0] = endpos[0] - startpos[0];
		localvector[1] = endpos[1] - startpos[1];
		localvector[2] = endpos[2] - startpos[2];
		
		velocity[0] = localvector[0] * PushForce[ult_level];
		velocity[1] = localvector[1] * PushForce[ult_level];
		velocity[2] = localvector[2] * PushForce[ult_level];
		
		SetEntDataVector( client, m_vecBaseVelocity, velocity, true );
	}
}