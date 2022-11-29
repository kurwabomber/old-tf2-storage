/**
* File: War3Source_Boy_Scout.sp
* Description: The Boy Scout race for SourceCraft.
* Author(s): xDr.HaaaaaaaXx
* Updated for 1.2.4.0 (09/10/2012) - Remy Lebeau
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
new Float:ScoutChance[6] = { 0.0, 0.60, 0.70, 0.80, 0.90, 1.0 };
new Float:ScoutSpeed[6] = { 0.0, 1.1, 1.15, 1.2, 1.25, 1.3 };
new Float:SniperInvis[6] = { 1.0, 0.75, 0.70, 0.65, 0.60, 0.55 };
new Float:DamageChanse[6] = { 0.0, 0.28, 0.44, 0.60, 0.69, 0.73 };
new HP[6] = { 0, 13, 16, 19, 22, 25 };
new HaloSprite, GlowSprite;
new bsmaximumHP = 150 ; // buff amount, 100 + bsmaximumHP
new Damage;

new SKILL_SNIPER, SKILL_SPEED, SKILL_INVIS, SKILL_DMG, ULT_AID;

public Plugin:myinfo = 
{
    name = "War3Source Race - Boy Scout",
    author = "xDr.HaaaaaaaXx",
    description = "The Boy Scout race for War3Source.",
    version = "1.0.0.2",
    url = ""
};

public OnMapStart()
{
    HaloSprite = PrecacheModel( "materials/sprites/halo01.vmt" );
    GlowSprite = PrecacheModel( "materials/sprites/purpleglow1.vmt" );
}

public OnWar3PluginReady()
{
    thisRaceID = War3_CreateNewRace( "Boy Scout", "boyscout" );
    
    SKILL_SNIPER = War3_AddRaceSkill( thisRaceID, "Supplies", "Gives you a scout with a 90 shot clip.", false, 5 );
    SKILL_SPEED = War3_AddRaceSkill( thisRaceID, "Travel Lightly", "You travel very quickly!", false, 5 );
    SKILL_INVIS = War3_AddRaceSkill( thisRaceID, "Camouflage", "You blend in easily with your surroundings.", false, 5 );
    SKILL_DMG = War3_AddRaceSkill( thisRaceID, "Precision", "You know the most deadly places for a bullet to strike.", false, 5 );
    ULT_AID = War3_AddRaceSkill( thisRaceID, "First Aid", "You are able to heal yourself occasionaly.", true, 5 );
    
    W3SkillCooldownOnSpawn( thisRaceID, ULT_AID, 5.0, _);
    
    War3_CreateRaceEnd( thisRaceID );
    
    War3_AddSkillBuff(thisRaceID, SKILL_SPEED, fMaxSpeed, ScoutSpeed);
    War3_AddSkillBuff(thisRaceID, SKILL_INVIS, fInvisibilitySkill, SniperInvis);
}

public InitPassiveSkills( client )
{
    if( War3_GetRace( client ) == thisRaceID )
    {            
        War3_WeaponRestrictTo( client, thisRaceID, "weapon_knife,weapon_scout" );
        War3_SetBuff(client, iAdditionalMaxHealthNoHPChange, thisRaceID, bsmaximumHP);
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
    new race = War3_GetRace( client );
    if( race == thisRaceID )
    {
        InitPassiveSkills( client );
        if( War3_GetSkillLevel( client, thisRaceID, SKILL_SNIPER ) > 0 && GetRandomFloat( 0.0, 1.0 ) <= ScoutChance[War3_GetSkillLevel( client, thisRaceID, SKILL_SNIPER )] )
        {
            GivePlayerItem( client, "weapon_scout" );
        }
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
            new skill_damage = War3_GetSkillLevel( attacker, thisRaceID, SKILL_DMG );
            Damage = GetRandomInt( (skill_damage * 5), (20 + (skill_damage * 10)) );


            if( !Hexed( attacker, false ) && skill_damage > 0 && !W3HasImmunity( victim, Immunity_Skills ) && GetRandomFloat( 0.0, 1.0 ) < DamageChanse[skill_damage] )
            {
                new Float:start_pos[3];
                new Float:target_pos[3];
                
                GetClientAbsOrigin( attacker, start_pos );
                GetClientAbsOrigin( victim, target_pos );
                
                start_pos[2] += 40;
                target_pos[2] += 40;
                
                TE_SetupBeamPoints( start_pos, target_pos, HaloSprite, HaloSprite, 0, 0, 1.0, 5.0, 5.0, 0, 0.0, { 200, 20, 20, 255 }, 40 );
                TE_SendToAll();

                War3_DealDamage( victim, Damage, attacker, DMG_BULLET, "boyscout_crit" );
                W3PrintSkillDmgHintConsole( victim, attacker, War3_GetWar3DamageDealt(), SKILL_DMG );
                W3FlashScreen( victim, RGBA_COLOR_RED );
            }
        }
    }
}

public OnUltimateCommand( client, race, bool:pressed )
{
    if( race == thisRaceID && pressed && IsPlayerAlive( client ) && !Silenced( client ) )
    {
        new ult_level = War3_GetSkillLevel( client, race, ULT_AID );
        if( ult_level > 0 )
        {
            if( War3_SkillNotInCooldown( client, thisRaceID, ULT_AID, true ) )
            {
                //War3_HealToBuffHP( client, HP[ult_level] );
                War3_HealToMaxHP(client, HP[ult_level]);
                //War3HealToHP(client, HP[ult_level], bsmaximumHP[0]+100);
                new Float:pos[3];
                
                GetClientAbsOrigin( client, pos );
                
                pos[2] += 50;
                
                TE_SetupBeamFollow( client, GlowSprite, HaloSprite, 1.0, 2.0, 0.5, 0, {255, 50, 50, 255});
                TE_SendToAll();
                TE_SetupGlowSprite( pos, GlowSprite, 4.0, 2.0, 255 );
                TE_SendToAll();
                
                War3_CooldownMGR( client, 15.0, thisRaceID, ULT_AID);
            }
        }
        else
        {
            W3MsgUltNotLeveled( client );
        }
    }
}