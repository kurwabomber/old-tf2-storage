/**
* File: War3Source_Zeus.sp
* Description: The Zeus race for SourceCraft.
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
new Float:AbilityRadius[6] = { 0.0, 200.0, 220.0, 240.0, 260.0, 280.0 };
new Float:DamageReturnPercent[6] = { 0.0, 0.1, 0.2, 0.3, 0.4, 0.5 };
new Float:ZeusDamageChance[6] = { 0.0, 0.10, 0.15, 0.20, 0.25, 0.30 };
new Float:ZeusMirrorChance[6] = { 0.0, 0.10, 0.15, 0.20, 0.25, 0.30 };
new Float:UltDelay[6] = { 0.0, 9.0, 8.0, 7.0, 6.0, 5.0 };
new HaloSprite, BeamSprite;
new bool:bFlying[66];

new String:overloadzap[] = "war3source/cd/overloadzap.mp3";

new SKILL_DMG, SKILL_MIRROR, SKILL_LIGHT, ULT_FLY;

public Plugin:myinfo = 
{
    name = "War3Source Race - Zeus",
    author = "xDr.HaaaaaaaXx",
    description = "The Zeus race for War3Source.",
    version = "1.0.1",
    url = ""
};

public OnWar3PluginReady()
{
    thisRaceID = War3_CreateNewRace( "Zeus", "zeus" );
    
    SKILL_DMG = War3_AddRaceSkill( thisRaceID, "Lightning Bolt", "Shoot a bolt of lightning that jumps between enemies", false, 5 );
    SKILL_MIRROR = War3_AddRaceSkill( thisRaceID, "Lightning Armor", "Chance to reflect damage", false, 5 );
    SKILL_LIGHT = War3_AddRaceSkill( thisRaceID, "Lightning Aura", "Shock enemies in an area around you", false, 5 );
    ULT_FLY = War3_AddRaceSkill( thisRaceID, "Ride a Lightning Bolt", "Fly on a bolt of lightning", true, 5 );
    
    W3SkillCooldownOnSpawn( thisRaceID, ULT_FLY, 5.0, _ );
    
    War3_CreateRaceEnd( thisRaceID );
}

public OnMapStart()
{
    BeamSprite = War3_PrecacheBeamSprite();
    HaloSprite = War3_PrecacheHaloSprite();
    War3_AddCustomSound( overloadzap );
}

public OnPluginStart()
{
    CreateTimer( 1.0, CalcLightningWaves, _, TIMER_REPEAT );
}

public OnWar3EventSpawn( client )
{
    new race = War3_GetRace( client );
    if( race == thisRaceID )
    {
        bFlying[client] = false;

        War3_SetBuff( client, bFlyMode, thisRaceID, false );
        War3_SetBuff( client, fMaxSpeed, thisRaceID, 1.0 );
    }
}

public OnRaceChanged(client,oldrace,newrace)
{
    if( newrace != thisRaceID )
    {
        W3ResetAllBuffRace( client, thisRaceID );
    }
    else
    {
        if( IsPlayerAlive( client ) )
        {
            bFlying[client] = false;
        }
    }
}

public OnWar3EventDeath( victim, attacker )
{
    W3ResetAllBuffRace( victim, thisRaceID );
}

public Action:CalcLightningWaves( Handle:timer, any:userid )
{
    if( thisRaceID > 0 )
    {
        for( new i = 1; i <= MaxClients; i++ )
        {
            if( ValidPlayer( i, true ) )
            {
                if( War3_GetRace( i ) == thisRaceID )
                {
                    LightningWave( i );
                }
            }
        }
    }
}

public LightningWave( client )
{
    new skill = War3_GetSkillLevel( client, thisRaceID, SKILL_LIGHT );
    if( skill > 0 && !Hexed( client, false ) )
    {
        new Float:dist = AbilityRadius[skill];
        new ZeusTeam = GetClientTeam( client );
        new Float:ZeusPos[3];
        new Float:VictimPos[3];
        
        GetClientAbsOrigin( client, ZeusPos );
        
        ZeusPos[2] += 40.0;

        for( new i = 1; i <= MaxClients; i++ )
        {
            if( ValidPlayer( i, true ) && GetClientTeam( i ) != ZeusTeam && !W3HasImmunity( i, Immunity_Skills ) )
            {
                GetClientAbsOrigin( i, VictimPos );
                VictimPos[2] += 40.0;
                
                if( GetVectorDistance( ZeusPos, VictimPos ) <= dist )
                {
                    War3_DealDamage( i, 5, client, DMG_BULLET, "zeus_lightning" );
                
                    W3PrintSkillDmgHintConsole( i, client, War3_GetWar3DamageDealt(), SKILL_LIGHT );
                    
                    TE_SetupBeamPoints( ZeusPos, VictimPos, BeamSprite, HaloSprite, 0, 35, 0.5, 6.0, 5.0, 0, 1.0, { 255, 255, 255, 255 }, 20 );
                    TE_SendToAll();
                    
                    W3FlashScreen( i, { 255, 255, 255, 3 } );
                    War3_ShakeScreen( i, 1.0, 20.0, 20.0 );
                    
                    EmitSoundToAll( overloadzap, client );
                }
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
            new race_attacker = War3_GetRace( attacker );
            new race_victim = War3_GetRace( victim );
            new skill_level_mirror = War3_GetSkillLevel( victim, thisRaceID, SKILL_MIRROR );
            new skill_level_dmg = War3_GetSkillLevel( attacker, thisRaceID, SKILL_DMG );
        
            if( race_victim == thisRaceID && skill_level_mirror > 0 && IsPlayerAlive( attacker ) && !Hexed( victim, false ) && GetRandomFloat( 0.0, 1.0 ) <= ZeusMirrorChance[skill_level_mirror] )
            {                                                                                
                new damage_i = RoundToFloor( damage * DamageReturnPercent[skill_level_mirror] );
                if( damage_i > 0 && !W3HasImmunity(attacker, Immunity_Skills))
                {
                    if(damage_i > 40)
                    {
                        damage_i = 40;
                    }

                    War3_DealDamage( attacker, damage_i, victim, _, "zeus_lightning", _, W3DMGTYPE_PHYSICAL );
                    
                    W3PrintSkillDmgConsole( attacker, victim, War3_GetWar3DamageDealt(),SKILL_LIGHT);
                    
                    new Float:start_pos[3];
                    new Float:target_pos[3];
                
                    GetClientAbsOrigin( attacker, start_pos );
                    GetClientAbsOrigin( victim, target_pos );
                
                    start_pos[2] += 40;
                    target_pos[2] += 40;
                
                    TE_SetupBeamPoints( start_pos, target_pos, BeamSprite, HaloSprite, 0, 35, 0.5, 6.0, 5.0, 0, 1.0, { 255, 255, 255, 255 }, 20 );
                    TE_SendToAll();
                    
                    W3FlashScreen( attacker, RGBA_COLOR_RED );
                    W3FlashScreen( victim, { 255, 255, 255, 3 } );
                }
            }
            
            if( race_attacker == thisRaceID && skill_level_dmg > 0 && IsPlayerAlive( attacker ) && !Hexed( attacker, false ) && GetRandomFloat( 0.0, 1.0 ) <= ZeusDamageChance[skill_level_dmg] && !W3HasImmunity(victim, Immunity_Skills))
            {    
                War3_DealDamage( victim, RoundToFloor( damage / 3 ), attacker, DMG_BULLET, "zeus_lightning" );
                
                new Float:start_pos[3];
                new Float:target_pos[3];
                
                GetClientAbsOrigin( attacker, start_pos );
                GetClientAbsOrigin( victim, target_pos );
                
                start_pos[2] += 40;
                target_pos[2] += 40;
                
                TE_SetupBeamPoints( start_pos, target_pos, BeamSprite, HaloSprite, 0, 35, 0.5, 6.0, 5.0, 0, 1.0, { 255, 255, 255, 255 }, 20 );
                TE_SendToAll();
                
                W3FlashScreen( victim, RGBA_COLOR_RED );
            }
        }
    }
}

public OnUltimateCommand( client, race, bool:pressed )
{
    if( race == thisRaceID && pressed && ValidPlayer( client, true ) )
    {
        new ult_level = War3_GetSkillLevel( client, race, ULT_FLY );
        if( ult_level > 0 )        
        {
            if( War3_SkillNotInCooldown( client, thisRaceID, ULT_FLY, true ) ) 
            {
                if( !bFlying[client] )
                {
                    bFlying[client] = true;
                    
                    War3_SetBuff( client, bFlyMode, thisRaceID, true );
                    War3_SetBuff( client, fMaxSpeed, thisRaceID, 1.9 );
                    
                    PrintToChat( client, "\x05: \x03You ride a lightning bolt!" );
                    
                    CreateTimer( 5.0, StopFly, client );
                    
                    CreateTimer( 4.0, Land1, client );
                    CreateTimer( 3.0, Land2, client );
                    CreateTimer( 2.0, Land3, client );
                    
                    War3_CooldownMGR( client, ( 5.0 + UltDelay[ult_level] ), thisRaceID, ULT_FLY, _, false );
                }
            }
        }
        else
        {
            PrintHintText( client, "Level Your Ultimate First" );
        }
    }
}

public Action:StopFly( Handle:timer, any:client )
{
    bFlying[client] = false;
    if( ValidPlayer( client, true ) )
    {
        War3_SetBuff( client, bFlyMode, thisRaceID, false );
        War3_SetBuff( client, fMaxSpeed, thisRaceID, 1.0 );
    }
}

public Action:Land1( Handle:timer, any:client )
{
    if( ValidPlayer( client, true ) )
    {
        PrintToChat( client, "\x05: \x03You're going to land in \x041 \x03seconds!" );
    }
}

public Action:Land2( Handle:timer, any:client )
{
    if( ValidPlayer( client, true ) )
    {
        PrintToChat( client, "\x05: \x03You're going to land in \x042 \x03seconds!" );
    }
}

public Action:Land3( Handle:timer, any:client )
{
    if( ValidPlayer( client, true ) )
    {
        PrintToChat( client, "\x05: \x03You're going to land in \x043 \x03seconds!" );
    }
}