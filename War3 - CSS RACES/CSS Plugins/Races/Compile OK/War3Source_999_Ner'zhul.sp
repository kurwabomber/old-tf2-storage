/**
* File: War3Source_Ner'zhul.sp
* Description: The Ner'zhul race for SourceCraft. Race from Warcraft III Collection(http://www.fpsbanana.com/scripts/5804)
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
#include "W3SIncs/haaaxfunctions"



// War3Source stuff
new thisRaceID, SKILL_SPAWN, SKILL_ATTACK, SKILL_VICTIM, SKILL_ULT;

// Chance/Data Arrays
// skill 1
new AWPAmmo[5] = { 10, 20, 30, 40, 50 };
new m_iClip1;

// skill 2
new FlatFlameSprite, SmokeSprite, LightningSprite, GlowSprite, TPBeamSprite, ScannerSprite, WaterDropSprite, BlueLightSprite;
new String:GlockSound[] = "ambient/machines/wall_move5.wav";
new Float:AttackChance[5] = { 0.0, 0.18, 0.22, 0.28, 0.33 };
new String:P228Sound[] = "weapons/hegrenade/explode3.wav";
new String:DeagleSound[] = "weapons/explode3.wav";
new m_vecBaseVelocity;

// skill 3
new String:VictimSound[] = "weapons/physcannon/energy_sing_flyby2.wav";
new Float:VictimChance[5] = { 0.0, 0.10, 0.15, 0.20, 0.25 };

// skill 4
new String:UltSound1[] = "weapons/physcannon/physcannon_pickup.wav";
new String:UltSound2[] = "weapons/physcannon/energy_bounce1.wav";
new GravForce[6] = { 0, 1, 2, 3, 4, 5 };

public Plugin:myinfo = 
{
	name = "War3Source Race - Ner'zhul",
	author = "xDr.HaaaaaaaXx",
	description = "The Ner'zhul race for War3Source. Race from Warcraft III Collection(http://www.fpsbanana.com/scripts/5804)",
	version = "1.0.0.2",
	url = ""
};

public OnPluginStart()
{
	m_vecBaseVelocity = FindSendPropOffs( "CBasePlayer", "m_vecBaseVelocity" );
	m_iClip1 = FindSendPropOffs( "CBaseCombatWeapon", "m_iClip1" );
}

public OnMapStart()
{
	War3_PrecacheSound( UltSound1 );
	War3_PrecacheSound( UltSound2 );
	War3_PrecacheSound( GlockSound );
	War3_PrecacheSound( DeagleSound );
	FlatFlameSprite = PrecacheModel( "sprites/flatflame.vmt" );
	SmokeSprite = PrecacheModel( "sprites/smoke.vmt" );
	LightningSprite = PrecacheModel( "sprites/lgtning.vmt" );
	GlowSprite = PrecacheModel( "sprites/glow.vmt" );
	TPBeamSprite = PrecacheModel( "sprites/tp_beam001.vmt" );
	ScannerSprite = PrecacheModel( "sprites/scanner.vmt" );
	WaterDropSprite = PrecacheModel( "sprites/water_drop.vmt" );
	BlueLightSprite = PrecacheModel( "sprites/bluelight1.vmt" );
}

public OnWar3PluginReady()
{
	thisRaceID = War3_CreateNewRace( "Ner'zhul", "nerzhul" );
	
	SKILL_SPAWN = War3_AddRaceSkill( thisRaceID, "Teacher of Gul'dan", "Spawn ultimate powerful weapon", false, 4 );
	SKILL_ATTACK = War3_AddRaceSkill( thisRaceID, "Leader of Shadowmoon", "Powerful pistols", false, 4 );
	SKILL_VICTIM = War3_AddRaceSkill( thisRaceID, "In service of Burning Legion", "Fade to the Shadows when attacked", false, 4 );
	SKILL_ULT = War3_AddRaceSkill( thisRaceID, "Will of Lich King", "Pull enemies towards to you", true, 4 );
	
	W3SkillCooldownOnSpawn( thisRaceID, SKILL_ULT, 15.0);
	
	War3_CreateRaceEnd( thisRaceID );
}

public InitPassiveSkills( client )
{
	if( War3_GetRace( client ) == thisRaceID && War3_GetSkillLevel( client, thisRaceID, SKILL_SPAWN ) > 0 )
	{
		CreateTimer( 1.0, SetWepAmmo, client );
	}
}

public OnRaceChanged ( client,oldrace,newrace )
{
	if( newrace != thisRaceID )
	{
		War3_WeaponRestrictTo( client, thisRaceID, "" );
		War3_SetBuff( client, fMaxSpeed, thisRaceID, 1.0 );
		War3_SetBuff( client, fLowGravitySkill, thisRaceID, 1.0 );
		W3ResetAllBuffRace( client, thisRaceID );
	}
	else
	{
		War3_WeaponRestrictTo( client, thisRaceID, "weapon_knife,weapon_awp,weapon_deagle,weapon_usp,weapon_glock,weapon_fiveseven,weapon_p228,weapon_elite" );
		if( IsPlayerAlive( client ) )
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
		GivePlayerItem( client, "weapon_awp" );
		InitPassiveSkills( client );
		War3_SetBuff(client, fInvisibilitySkill, thisRaceID, 1.0);
	}
}

public Action:SetWepAmmo( Handle:timer, any:client )
{
	if( ValidPlayer( client, true ) )
	{
		new String:weapon[32];
		GetClientWeapon( client, weapon, 32 );
		if( StrEqual( weapon, "weapon_awp" ) )
		{
			new wep_ent = W3GetCurrentWeaponEnt( client );
			SetEntData( wep_ent, m_iClip1, AWPAmmo[War3_GetSkillLevel( client, thisRaceID, SKILL_SPAWN )], 4 );
		}
	}
}

public OnWar3EventPostHurt(victim, attacker, Float:damage, const String:weapon[32], bool:isWarcraft)
{
	if( W3GetDamageIsBullet() && ValidPlayer( victim, true ) && ValidPlayer( attacker, true ) && GetClientTeam( victim ) != GetClientTeam( attacker ) )
	{
		if( War3_GetRace( attacker ) == thisRaceID )
		{
			new skill_level = War3_GetSkillLevel( attacker, thisRaceID, SKILL_ATTACK );
			if( !Hexed( attacker, false ) && GetRandomFloat( 0.0, 1.0 ) <= AttackChance[skill_level] )
			{
				new damage2 = RoundToFloor(damage);
				new String:strwep[32];
				GetClientWeapon( attacker, strwep, 32 );
				if( StrEqual( strwep, "weapon_usp" ) )
					AttackUSP( victim, attacker, damage2 );
					
				if( StrEqual( strwep, "weapon_elite" ) )
					AttackELITE( victim, attacker, damage2 );
					
				if( StrEqual( strwep, "weapon_fiveseven" ) )
					AttackFIVESEVEN( victim, attacker, damage2 );
					
				if( StrEqual( strwep, "weapon_glock" ) )
					AttackGLOCK( victim, attacker, damage2 );
					
				if( StrEqual( strwep, "weapon_deagle" ) )
					AttackDEAGLE( victim, attacker, damage2 );
					
				if( StrEqual( strwep, "weapon_p228" ) )
					AttackP228( victim, attacker, damage2 );
			}
		}
		if( War3_GetRace( victim ) == thisRaceID )
		{
			new skill_level = War3_GetSkillLevel( victim, thisRaceID, SKILL_VICTIM );
			if( !Hexed( attacker, false ) && GetRandomFloat( 0.0, 1.0 ) <= VictimChance[skill_level] )
			{
				EmitSoundToAll( VictimSound, victim );
				War3_SetBuff( victim, fInvisibilitySkill, thisRaceID, 0.0 );
				TE_SetupBeamFollow( victim, TPBeamSprite, TPBeamSprite, 2.0, 10.0, 20.0, 5, { 100, 155, 255, 255 } );
				TE_SendToAll();
				CreateTimer( 0.4, InvisOff1, victim );
				CreateTimer( 0.5, InvisOff2, victim );
				CreateTimer( 0.6, InvisOff3, victim );
				CreateTimer( 0.7, InvisOff4, victim );
				CreateTimer( 0.8, InvisOff5, victim );
				CreateTimer( 0.9, InvisOff6, victim );
				CreateTimer( 1.0, InvisOff7, victim );
				CreateTimer( 1.1, InvisOff8, victim );
				CreateTimer( 1.2, InvisOff9, victim );
				CreateTimer( 1.3, InvisOff10, victim );
				CreateTimer( 1.4, InvisOff11, victim );
				CreateTimer( 1.5, InvisOff12, victim );
			}
		}
	}
}

public Action:AttackUSP( victim, attacker, damage )
{
	new Float:victim_pos[3];
	new Float:attacker_pos[3];
	
	GetClientAbsOrigin( victim, victim_pos );
	GetClientAbsOrigin( attacker, attacker_pos );
	
	TE_SetupBeamRingPoint( victim_pos, 20.0, 500.0, LightningSprite, LightningSprite, 0, 0, 3.0, 100.0, 0.0, { 255, 105, 155, 255 }, 50, FBEAM_ISACTIVE );
	TE_SendToAll();
	
	victim_pos[2] += 20;
	attacker_pos[2] += 20;
	
	TE_SetupBeamPoints( victim_pos, attacker_pos, GlowSprite, GlowSprite, 0, 0, 0.5, 20.0, 20.0, 0, 0.0, { 200, 0, 255, 255 }, 0 );
	TE_SendToAll();
	
	War3_SetBuff( victim, bBashed, thisRaceID, true );
	
	CreateTimer( 2.0, StopFreeze, victim );
	
	PrintToChat( attacker, "\x04USP: \x03Athena's Spear" );
}

public Action:StopFreeze( Handle:timer, any:client )
{
	if( ValidPlayer( client, false ) )
	{
		War3_SetBuff( client, bBashed, thisRaceID, false );
	}
}

public Action:AttackELITE( victim, attacker, damage )
{
	War3_DealDamage( victim, 10, attacker, DMG_BULLET, "elite_crit" );
	W3PrintSkillDmgHintConsole( victim, attacker, War3_GetWar3DamageDealt(), SKILL_ATTACK );
	
	PrintToChat( attacker, "\x04ELITE: \x03Nebula's Messier" );
	
	new Float:victim_pos[3];
	new Float:attacker_pos[3];
	
	GetClientAbsOrigin( victim, victim_pos );
	GetClientAbsOrigin( attacker, attacker_pos );
	
	TE_SetupBeamRingPoint( victim_pos, 20.0, 60.0, SmokeSprite, SmokeSprite, 0, 0, 3.0, 400.0, 0.0,{ 10, 10, 10, 255 }, 0, FBEAM_ISACTIVE );
	TE_SendToAll();
	
	TE_SetupBeamPoints( victim_pos, attacker_pos, LightningSprite, LightningSprite, 0, 0, 2.0, 30.0, 20.0, 0, 0.0, { 77, 77, 77, 255 }, 0 );
	TE_SendToAll();
	
	victim_pos[2] += 20;
	attacker_pos[2] += 20;
	
	TE_SetupBeamPoints( victim_pos, attacker_pos, GlowSprite, GlowSprite, 0, 0, 2.0, 10.0, 15.0, 0, 0.0, { 123, 123, 123, 255 }, 0 );
	TE_SendToAll();
}

public Action:AttackFIVESEVEN( victim, attacker, damage )
{
	new Float:attacker_pos[3];
	new Float:victim_pos[3];
	
	GetClientAbsOrigin( attacker, attacker_pos );
	GetClientAbsOrigin( victim, victim_pos );
	
	TeleportEntity( victim, attacker_pos, NULL_VECTOR, NULL_VECTOR );
	
	SetAim( attacker, victim, -5.0 );
	
	PrintToChat( attacker, "\x04FIVESEVEN: \x03Scorpion's Bloody Speare" );
	
	victim_pos[2] += 20;
	attacker_pos[2] += 20;
	
	TE_SetupBeamPoints( victim_pos, attacker_pos, TPBeamSprite, TPBeamSprite, 0, 0, 1.0, 2.0, 5.0, 0, 0.0, { 255, 151, 67, 255 }, 0 );
	TE_SendToAll();
}

public Action:AttackGLOCK( victim, attacker, damage )
{
	new Float:attacker_pos[3];
	new Float:victim_pos[3];
	
	GetClientAbsOrigin( attacker, attacker_pos );
	GetClientAbsOrigin( victim, victim_pos );
	
	War3_DealDamage( victim, 10, attacker, DMG_BULLET, "glock_crit" );
	W3PrintSkillDmgHintConsole( victim, attacker, War3_GetWar3DamageDealt(), SKILL_ATTACK );
	
	EmitSoundToAll( GlockSound, victim );
	
	PrintToChat( attacker, "\x04GLOCK: \x03Void's Shadow" );
	
	TE_SetupBeamRingPoint( victim_pos, 50.0, 350.0, ScannerSprite, ScannerSprite, 0, 0, 2.0, 90.0, 0.0, { 155, 155, 155, 155 }, 2, FBEAM_ISACTIVE );
	TE_SendToAll();
	
	victim_pos[2] += 20;
	attacker_pos[2] += 20;
	
	TE_SetupBeamPoints( victim_pos, attacker_pos, WaterDropSprite, WaterDropSprite, 0, 0, 1.0, 1.0, 3.0, 0, 0.0, { 150, 150, 150, 255 }, 0 );
	TE_SendToAll();
}

public Action:AttackDEAGLE( victim, attacker, damage )
{
	new Float:attacker_pos[3];
	new Float:victim_pos[3];
	new Float:velocity[3];
	
	GetClientAbsOrigin( attacker, attacker_pos );
	GetClientAbsOrigin( victim, victim_pos );
	
	velocity[0] += 0;
	velocity[1] += 0;
	velocity[2] += 300.0;
	
	SetEntDataVector( victim, m_vecBaseVelocity, velocity, true );
	
	War3_ShakeScreen( victim );
	
	EmitSoundToAll( DeagleSound, victim );
	
	attacker_pos[2] += 60;
	victim_pos[2] += 30;
	
	TE_SetupBeamPoints( attacker_pos, victim_pos, BlueLightSprite, BlueLightSprite, 0, 0, 3.0, 3.0, 6.0, 0, 0.0, { 185, 110, 205, 255 }, 0 );
	TE_SendToAll();
	
	attacker_pos[2] += 61;
	victim_pos[2] += 31;
	
	TE_SetupBeamPoints( attacker_pos, victim_pos, BlueLightSprite, BlueLightSprite, 0, 0, 3.0, 3.0, 6.0, 0, 0.0, { 185, 110, 205, 255 }, 0 );
	TE_SendToAll();
	
	attacker_pos[2] += 60;
	victim_pos[2] += 30;
	
	TE_SetupBeamPoints( attacker_pos, victim_pos, BlueLightSprite, BlueLightSprite, 0, 0, 3.0, 3.0, 6.0, 0, 0.0, { 185, 110, 205, 255 }, 0 );
	TE_SendToAll();
	
	PrintToChat( attacker, "\x04DEAGLE" );
}

public Action:AttackP228( victim, attacker, damage )
{
	EmitSoundToAll( P228Sound, victim );
	
	War3_HealToBuffHP( attacker, RoundToFloor( damage * 0.25 ) );
	
	PrintToChat( attacker, "\x04P228: \x03Genocide" );
	
	new Float:attacker_pos[3];
	new Float:victim_pos[3];
	
	GetClientAbsOrigin( attacker, attacker_pos );
	GetClientAbsOrigin( victim, victim_pos );
	
	TE_SetupBeamRingPoint( victim_pos, 20.0, 500.0, FlatFlameSprite, FlatFlameSprite, 0, 0, 2.0, 60.0, 0.8, { 255, 0, 0, 255 }, 1, FBEAM_ISACTIVE );
	TE_SendToAll();
	
	attacker_pos[2] += 20;
	victim_pos[2] += 20;
	
	TE_SetupBeamPoints( attacker_pos, victim_pos, LightningSprite, LightningSprite, 0, 0, 2.0, 40.0, 40.0, 0, 0.0, { 255, 0, 0, 255 }, 0 );
	TE_SendToAll();
	
	TE_SetupBeamPoints( attacker_pos, victim_pos, LightningSprite, LightningSprite, 0, 0, 2.0, 20.0, 20.0, 0, 0.0, { 255, 255, 255, 255 }, 0 );
	TE_SendToAll();
}

public Action:InvisOff1( Handle:timer, any:client )
{
	if( ValidPlayer( client, true ) )
	{
		War3_SetBuff( client, fInvisibilitySkill, thisRaceID, 0.04 );
	}
}

public Action:InvisOff2( Handle:timer, any:client )
{
	if( ValidPlayer( client, true ) )
	{
		War3_SetBuff( client, fInvisibilitySkill, thisRaceID, 0.09 );
	}
}

public Action:InvisOff3( Handle:timer, any:client )
{
	if( ValidPlayer( client, true ) )
	{
		War3_SetBuff( client, fInvisibilitySkill, thisRaceID, 0.13 );
	}
}

public Action:InvisOff4( Handle:timer, any:client )
{
	if( ValidPlayer( client, true ) )
	{
		War3_SetBuff( client, fInvisibilitySkill, thisRaceID, 0.23 );
	}
}

public Action:InvisOff5( Handle:timer, any:client )
{
	if( ValidPlayer( client, true ) )
	{
		War3_SetBuff( client, fInvisibilitySkill, thisRaceID, 0.31 );
	}
}

public Action:InvisOff6( Handle:timer, any:client )
{
	if( ValidPlayer( client, true ) )
	{
		War3_SetBuff( client, fInvisibilitySkill, thisRaceID, 0.45 );
	}
}

public Action:InvisOff7( Handle:timer, any:client )
{
	if( ValidPlayer( client, true ) )
	{
		War3_SetBuff( client, fInvisibilitySkill, thisRaceID, 0.52 );
	}
}

public Action:InvisOff8( Handle:timer, any:client )
{
	if( ValidPlayer( client, true ) )
	{
		War3_SetBuff( client, fInvisibilitySkill, thisRaceID, 0.64 );
	}
}

public Action:InvisOff9( Handle:timer, any:client )
{
	if( ValidPlayer( client, true ) )
	{
		War3_SetBuff( client, fInvisibilitySkill, thisRaceID, 0.72 );
	}
}

public Action:InvisOff10( Handle:timer, any:client )
{
	if( ValidPlayer( client, true ) )
	{
		War3_SetBuff( client, fInvisibilitySkill, thisRaceID, 0.78 );
	}
}

public Action:InvisOff11( Handle:timer, any:client )
{
	if( ValidPlayer( client, true ) )
	{
		War3_SetBuff( client, fInvisibilitySkill, thisRaceID, 0.88 );
	}
}

public Action:InvisOff12( Handle:timer, any:client )
{
	if( ValidPlayer( client, true ) )
	{
		War3_SetBuff( client, fInvisibilitySkill, thisRaceID, 1.0 );
	}
}

public OnWar3EventDeath( client )
{
	War3_SetBuff( client, bFlyMode, thisRaceID, false );
}

public OnUltimateCommand( client, race, bool:pressed )
{
	if( race == thisRaceID && pressed && IsPlayerAlive( client ) && !Silenced( client ) )
	{
		new ult_level = War3_GetSkillLevel( client, race, SKILL_ULT );
		if( ult_level > 0 )
		{
			if( War3_SkillNotInCooldown( client, thisRaceID, SKILL_ULT, true ) )
			{
				Push( client );
			}
		}
		else
		{
			W3MsgUltNotLeveled( client );
		}
	}
}

Action:Push( client )
{
	new ult_level = War3_GetSkillLevel( client, thisRaceID, SKILL_ULT );
	new target;
	
	if( GetClientTeam( client ) == TEAM_T )
		target = War3_GetRandomPlayer(client, "#ct", true, true );
	if( GetClientTeam( client ) == TEAM_CT )
		target = War3_GetRandomPlayer(client, "#t", true, true );
	
	if( target == 0 )
	{
		PrintHintText( client, "No Target Found" );
	}
	else
	{
		new Float:pos1[3];
		new Float:pos2[3];
		
		GetClientAbsOrigin( client, pos1 );
		GetClientAbsOrigin( target, pos2 );
		
		new Float:localvector[3];
		
		localvector[0] = pos1[0] - pos2[0];
		localvector[1] = pos1[1] - pos2[1];
		localvector[2] = pos1[2] - pos2[2];

		new Float:velocity1[3];
		new Float:velocity2[3];
		
		velocity1[0] += 0;
		velocity1[1] += 0;
		velocity1[2] += 300;
		
		velocity2[0] = localvector[0] * ( 100 * GravForce[ult_level] );
		velocity2[1] = localvector[1] * ( 100 * GravForce[ult_level] );
		velocity2[2] = localvector[2] * ( 100 * GravForce[ult_level] );
		
		SetEntDataVector( target, m_vecBaseVelocity, velocity1, true );
		SetEntDataVector( target, m_vecBaseVelocity, velocity2, true );
		
		EmitSoundToAll( UltSound1, client );
		EmitSoundToAll( UltSound1, target );
		
		EmitSoundToAll( UltSound2, client );
		EmitSoundToAll( UltSound2, target );
		
		War3_SetBuff( target, bFlyMode, thisRaceID, true );
		War3_DealDamage( target, 1, client, DMG_BULLET, "element_crit" );
		CreateTimer( 5.0, StopFly, target );
		
		new String:NameAttacker[64];
		GetClientName( client, NameAttacker, 64 );
		
		new String:NameVictim[64];
		GetClientName( target, NameVictim, 64 );
		
		PrintToChat( client, ": You have pulled %s closer to you", NameVictim );
		PrintToChat( target, ": You have been pulled torward %s", NameAttacker );
		
		War3_CooldownMGR( client, 20.0, thisRaceID, SKILL_ULT);
	}
}

public Action:StopFly( Handle:timer, any:client )
{
	if( ValidPlayer( client, true ) )
	{
		War3_SetBuff( client, bFlyMode, thisRaceID, false );
	}
}