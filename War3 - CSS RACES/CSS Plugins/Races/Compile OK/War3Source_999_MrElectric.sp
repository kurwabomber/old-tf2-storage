/**
* File: War3Source_Mr_Electric.sp
* Description: The Spider Man race for SourceCraft.
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
new thisRaceID;

// Chance/Data Arrays
new Float:ElectricGravity[5] = { 1.0, 0.92, 0.84, 0.76, 0.68 };
new Float:ShockChance[5] = { 0.0, 0.21, 0.25, 0.29, 0.33 };
new Float:BounceChance[5] = { 0.0, 0.15, 0.22, 0.38, 0.47 };
new Float:BounceDuration[5] = { 0.0, 0.1, 0.15, 0.2, 0.25 };
new Float:BounceMultiplier[5] = { 0.0, 1000.0, 1500.0, 2000.0, 2500.0 };
new Float:BounceCooldown = 2.5;
new Float:JumpMultiplier[5] = { 1.0, 1.5, 2.0, 2.5, 3.0 };
new StrikeDamage = 10;
new Float:StrikeCooldown[5] = { 0.0, 25.0, 22.0, 19.0, 16.0 };
new m_vecBaseVelocity, m_vecVelocity_0, m_vecVelocity_1;
new HaloSprite, BeamSprite, AttackSprite1, AttackSprite2, VictimSprite;

new SKILL_ATTACK, SKILL_LONGJUMP, SKILL_BOUNCY, ULT_STRIKE;

public Plugin:myinfo = 
{
    name = "War3Source Race - Mr Electric",
    author = "xDr.HaaaaaaaXx",
    description = "The Mr Electric race for War3Source.",
    version = "1.0.0.1",
    url = ""
};

public OnMapStart()
{
    HaloSprite = PrecacheModel( "materials/sprites/halo01.vmt" );
    BeamSprite = PrecacheModel( "materials/sprites/lgtning.vmt" );
    AttackSprite1 = PrecacheModel( "materials/effects/strider_pinch_dudv_dx60.vmt" );
    AttackSprite2 = PrecacheModel( "models/props_lab/airlock_laser.vmt" );
    VictimSprite = PrecacheModel( "materials/sprites/crosshairs.vmt" );
}

public OnPluginStart()
{
    m_vecBaseVelocity = FindSendPropOffs( "CBasePlayer", "m_vecBaseVelocity" );
    m_vecVelocity_0 = FindSendPropOffs( "CBasePlayer", "m_vecVelocity[0]" );
    m_vecVelocity_1 = FindSendPropOffs( "CBasePlayer", "m_vecVelocity[1]" );
    HookEvent( "player_jump", PlayerJumpEvent );
}

public OnWar3PluginReady()
{
    thisRaceID = War3_CreateNewRace( "Mr Electric", "electric" );
    
    SKILL_ATTACK = War3_AddRaceSkill( thisRaceID, "Shocker", "Electric Blast into Enemies", false );    
    SKILL_LONGJUMP = War3_AddRaceSkill( thisRaceID, "Electricity Bounce", "Move at the speed of Electricity", false );    
    SKILL_BOUNCY = War3_AddRaceSkill( thisRaceID, "Unstable Electric Armor", "Electric Armor sends you bouncing", false );
    ULT_STRIKE = War3_AddRaceSkill( thisRaceID, "Lightning Strike", "Lightning is the ultimate form of Natural Electricty", true );
    
    W3SkillCooldownOnSpawn( thisRaceID, ULT_STRIKE, 5.0, _);
    
    War3_CreateRaceEnd( thisRaceID );
}

public InitPassiveSkills( client )
{
    if( War3_GetRace( client ) == thisRaceID )
    {
        War3_SetBuff( client, fLowGravitySkill, thisRaceID, ElectricGravity[War3_GetSkillLevel( client, thisRaceID, SKILL_LONGJUMP )] );
        War3_SetBuff( client, iAdditionalMaxHealthNoHPChange, thisRaceID, 100);
        SetEntityRenderFx( client, RENDERFX_FLICKER_FAST );
    }
}

public OnRaceChanged( client, oldrace, newrace )
{
    if( newrace != thisRaceID )
    {
        W3ResetAllBuffRace( client, thisRaceID );
    }
    else
    {    
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
        InitPassiveSkills( client );
    }
}

public OnWar3EventDeath( victim, attacker )
{
    W3ResetAllBuffRace( victim, thisRaceID );
}

public OnWar3EventPostHurt(victim, attacker, Float:damage, const String:weapon[32], bool:isWarcraft)
{
    if( W3GetDamageIsBullet() && ValidPlayer( victim, true ) && ValidPlayer( attacker, true ) && GetClientTeam( victim ) != GetClientTeam( attacker ) )
    {
        if( War3_GetRace( attacker ) == thisRaceID )
        {
            new skill_level = War3_GetSkillLevel( attacker, thisRaceID, SKILL_ATTACK );
            if( skill_level > 0 && !Hexed( attacker, false ) && GetRandomFloat( 0.0, 1.0 ) <= ShockChance[skill_level] && !W3HasImmunity( victim, Immunity_Skills ))
            {
                new Float:velocity[3];
                
                velocity[0] += 0;
                velocity[1] += 0;
                velocity[2] += 300.0;
                
                SetEntDataVector( victim, m_vecBaseVelocity, velocity, true );
                
                War3_ShakeScreen( victim, 3.0, 50.0, 40.0 );
                
                W3FlashScreen( victim, RGBA_COLOR_RED );
                
                new Float:start_pos[3];
                new Float:target_pos[3];
                
                GetClientAbsOrigin( attacker, start_pos );
                GetClientAbsOrigin( victim, target_pos );
                
                start_pos[2] += 20;
                target_pos[2] += 20;
                
                TE_SetupBeamPoints( start_pos, target_pos, AttackSprite1, HaloSprite, 0, 0, 1.0, 10.0, 5.0, 0, 0.0, { 255, 255, 255, 255 }, 0 );
                TE_SendToAll();
                
                TE_SetupBeamPoints( start_pos, target_pos, AttackSprite2, HaloSprite, 0, 0, 1.0, 15.0, 25.0, 0, 0.0, { 255, 255, 255, 255 }, 0 );
                TE_SendToAll( 2.0 );
            }
        }
    }
}

public PlayerJumpEvent( Handle:event, const String:name[], bool:dontBroadcast )
{
    new client = GetClientOfUserId( GetEventInt( event, "userid" ) );
    new race = War3_GetRace( client );
    if( race == thisRaceID )
    {
        new skill_long = War3_GetSkillLevel( client, race, SKILL_LONGJUMP );
        if( skill_long > 0 )
        {
            new Float:velocity[3] = { 0.0, 0.0, 0.0 };
            velocity[0] = GetEntDataFloat( client, m_vecVelocity_0 );
            velocity[1] = GetEntDataFloat( client, m_vecVelocity_1 );
            velocity[0] *= JumpMultiplier[skill_long] * 0.25;
            velocity[1] *= JumpMultiplier[skill_long] * 0.25;
            SetEntDataVector( client, m_vecBaseVelocity, velocity, true );
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
            new skill_bouncy = War3_GetSkillLevel( victim, thisRaceID, SKILL_BOUNCY );
            if( race_victim == thisRaceID && skill_bouncy > 0 && !Hexed( victim, false )&& War3_SkillNotInCooldown( victim, thisRaceID, SKILL_BOUNCY, true ) ) 
            {
                if( GetRandomFloat( 0.0, 1.0 ) <= BounceChance[skill_bouncy] && !W3HasImmunity( attacker, Immunity_Skills ) )
                {
                    new Float:pos1[3];
                    new Float:pos2[3];
                    new Float:localvector[3];
                    new Float:velocity1[3];
                    new Float:velocity2[3];
                    
                    GetClientAbsOrigin( attacker, pos1 );
                    GetClientAbsOrigin( victim, pos2 );
                    
                    localvector[0] = pos1[0] - pos2[0];
                    localvector[1] = pos1[1] - pos2[1];
                    localvector[2] = pos1[2] - pos2[2];
                    
                    velocity1[0] += 0;
                    velocity1[1] += 0;
                    velocity1[2] += 300;
                    
                    velocity2[0] = localvector[0];
                    velocity2[1] = localvector[1];
                    NormalizeVector( velocity2, velocity2 );
                    ScaleVector( velocity2, BounceMultiplier[skill_bouncy] );
                    
                    SetEntDataVector( victim, m_vecBaseVelocity, velocity1, true );
                    SetEntDataVector( victim, m_vecBaseVelocity, velocity2, true );
                    
                    War3_SetBuff( victim, fInvisibilitySkill, thisRaceID, 0.0 );
                    War3_SetBuff( victim, bDoNotInvisWeapon, thisRaceID, true);

                    CreateTimer( BounceDuration[skill_bouncy], InvisStop, victim );
                    
                    new Float:pos[3];
                
                    GetClientAbsOrigin( victim, pos );
                
                    pos[2] += 40;
                
                    TE_SetupBeamRingPoint( pos, 40.0, 90.0, VictimSprite, HaloSprite, 0, 0, 0.5, 50.0, 0.0, { 155, 115, 100, 200 }, 1, FBEAM_ISACTIVE );
                    TE_SendToAll();
                    
                    War3_CooldownMGR( victim, BounceCooldown, thisRaceID, SKILL_BOUNCY, _, false );
                }
            }
        }
    }
}

public Action:InvisStop( Handle:timer, any:client )
{
    if( ValidPlayer( client, true ) )
    {
        War3_SetBuff( client, fInvisibilitySkill, thisRaceID, 1.0 );
    }
}

public OnUltimateCommand( client, race, bool:pressed )
{
    if( race == thisRaceID && pressed && IsPlayerAlive( client ) && !Silenced( client ) )
    {
        new ult_level = War3_GetSkillLevel( client, race, ULT_STRIKE );
        if( ult_level > 0 )
        {
            if( War3_SkillNotInCooldown( client, thisRaceID, ULT_STRIKE, true ) )
            {
                Strike( client );
            }
        }
        else
        {
            W3MsgUltNotLeveled( client );
        }
    }
}

stock Strike( client )
{
    new ult_level = War3_GetSkillLevel( client, thisRaceID, ULT_STRIKE );
    new bestTarget;
    
    if( GetClientTeam( client ) == TEAM_T )
        bestTarget = War3_GetRandomPlayer(client, "#ct", true, true );
    if( GetClientTeam( client ) == TEAM_CT )
        bestTarget = War3_GetRandomPlayer(client, "#t", true, true );

    if( bestTarget == 0 )
    {
        PrintHintText( client, "No Target Found" );
    }
    else
    {
        War3_DealDamage( bestTarget, StrikeDamage, client, DMG_BULLET, "electric_strike" );
        War3_HealToMaxHP( client, StrikeDamage );
        
        W3PrintSkillDmgHintConsole( bestTarget, client, War3_GetWar3DamageDealt(), ult_level );
        W3FlashScreen( bestTarget, RGBA_COLOR_RED );
        
        War3_CooldownMGR( client, StrikeCooldown[ult_level], thisRaceID, ULT_STRIKE, _, _ );
        
        new Float:pos[3];
        
        GetClientAbsOrigin( client, pos );
        
        pos[2] += 40;
        
        TE_SetupBeamRingPoint( pos, 20.0, 50.0, BeamSprite, HaloSprite, 0, 0, 3.0, 60.0, 0.0, { 155, 115, 100, 200 }, 1, FBEAM_ISACTIVE );
        TE_SendToAll();
    }
}