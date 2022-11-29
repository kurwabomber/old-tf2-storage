/**
* File: War3Source_LuckyStrike.sp
* Description: The Lucky*Strike race for SourceCraft.
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
new Float:FreezeChance[5] = { 0.0, 0.2, 0.25, 0.30, 0.35 };
new Float:DamageMultiplier[5] = { 0.0, 0.0, 0.1, 0.2, 0.5 };
new Float:EvadeChance[5] = { 0.0, 0.04, 0.07, 0.09, 0.12 };
new Float:AntiultChanse[5] = { 0.0, 0.15, 0.25, 0.35, 0.45 };
new StealMoney[5] = { 0, 100, 200, 500, 600 };
new m_iAccount;

new SKILL_DMG, SKILL_EVADE, SKILL_STEAL, SKILL_ANTIULT, SKILL_FREEZE;

public Plugin:myinfo = 
{
    name = "War3Source Race - Lucky*Strike",
    author = "xDr.HaaaaaaaXx",
    description = "The Lucky*Strike race for War3Source.",
    version = "1.0.0.1",
    url = ""
};

public OnPluginStart()
{
    m_iAccount = FindSendPropInfo( "CCSPlayer", "m_iAccount" );
}

public OnWar3PluginReady()
{
    thisRaceID = War3_CreateNewRace( "Lucky*Strike", "luckstruck" );
    
    SKILL_DMG = War3_AddRaceSkill( thisRaceID, "Lucky Strike", "Do more damage", false );    
    SKILL_EVADE = War3_AddRaceSkill( thisRaceID, "Wild Card", "Chance of evading a shot", false );    
    SKILL_STEAL = War3_AddRaceSkill( thisRaceID, "Strike Lucky", "Strike enemy and Get Cash", false );
    SKILL_ANTIULT = War3_AddRaceSkill( thisRaceID, "Joker", "Disables enemy ultimates", false );
    SKILL_FREEZE = War3_AddRaceSkill( thisRaceID, "Freeze", "Freeze", false );
    
    War3_CreateRaceEnd( thisRaceID );
    
    War3_AddSkillBuff(thisRaceID, SKILL_EVADE, fDodgeChance, EvadeChance);
    
}

public InitPassiveSkills( client )
{
    new skill_level = War3_GetSkillLevel( client, thisRaceID, SKILL_ANTIULT );
    if( War3_GetRace( client ) == thisRaceID && GetRandomFloat( 0.0, 1.0 ) <= AntiultChanse[skill_level] )
    {
        War3_SetBuff( client, bImmunityUltimates, thisRaceID, true );
    }
}

public OnRaceChanged( client,oldrace,newrace )
{
    if( newrace == thisRaceID )
    {
        if( IsPlayerAlive( client ) )
        {
            InitPassiveSkills( client );
        }
    }
    else
    {
        W3ResetAllBuffRace( client, thisRaceID );
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
        if( War3_GetRace( attacker ) == thisRaceID && !W3HasImmunity( victim, Immunity_Skills ))
        {
            new skill_dmg = War3_GetSkillLevel( attacker, thisRaceID, SKILL_DMG );
            if( !Hexed( attacker, false ) && GetRandomFloat( 0.0, 1.0 ) <= 0.25 && skill_dmg > 0 )
            {
                War3_DealDamage( victim, RoundToFloor( damage * DamageMultiplier[skill_dmg] ), attacker, DMG_BULLET, "lucky_crit" );
                
                W3FlashScreen( victim, RGBA_COLOR_RED );
            }
            
            new skill_freeze = War3_GetSkillLevel( attacker, thisRaceID, SKILL_FREEZE );
            if( !Hexed( attacker, false ) && GetRandomFloat( 0.0, 1.0 ) <= FreezeChance[skill_freeze] && skill_freeze > 0 && War3_SkillNotInCooldown( attacker, thisRaceID, SKILL_FREEZE, false ) )
            {
                War3_CooldownMGR( attacker, 1.0, thisRaceID, SKILL_FREEZE, true, false );
            
                War3_SetBuff( victim, bStunned, thisRaceID, true );
                
                CreateTimer( 0.5, StopFreeze, victim );
                
                W3FlashScreen( victim, RGBA_COLOR_BLUE );
                
                PrintHintText( attacker, "Your enemy freezed!" );
            }
        }
    }
}

public Action:StopFreeze( Handle:timer, any:client )
{
    War3_SetBuff( client, bStunned, thisRaceID, false );
}

public OnW3TakeDmgBullet( victim, attacker, Float:damage )
{
    if( IS_PLAYER( victim ) && IS_PLAYER( attacker ) && victim > 0 && attacker > 0 && victim != attacker && IsPlayerAlive( victim ) && IsPlayerAlive( attacker ) )
    {
        new vteam = GetClientTeam( victim );
        new ateam = GetClientTeam( attacker );

        
        new race_attack = War3_GetRace( attacker );

        if( vteam != ateam )
        {
            new skill_steal = War3_GetSkillLevel( attacker, thisRaceID, SKILL_STEAL );
            if( race_attack == thisRaceID && skill_steal > 0 && !Hexed( attacker, false ) && !W3HasImmunity( attacker, Immunity_Skills ) )
            {
                if( GetRandomFloat( 0.0, 1.0 ) <= 0.30 )
                {
                    new stolen = StealMoney[skill_steal];

                    new dec_money = GetMoney( victim ) - stolen;
                    new inc_money = GetMoney( attacker ) + stolen;

                    if( dec_money < 0 ) dec_money = 0;
                    if( inc_money > 16000 ) inc_money = 16000;

                    SetMoney( victim, dec_money );
                    SetMoney( attacker, inc_money );

                    W3MsgStoleMoney( victim, attacker, StealMoney[skill_steal] );
                    W3FlashScreen( attacker, RGBA_COLOR_BLUE );
                }
            }
        }
    }
}

stock GetMoney( player )
{
    return GetEntData( player, m_iAccount );
}

stock SetMoney( player, money )
{
    SetEntData( player, m_iAccount, money );
}