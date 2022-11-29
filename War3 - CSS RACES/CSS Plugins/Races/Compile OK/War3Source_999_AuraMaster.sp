/**
* File: War3Source_Aura_Master.sp
* Description: The Aura Master race for SourceCraft.
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
new Float:AuraSpeed[5] = { 1.0, 1.1, 1.15, 1.2, 1.25 };
new Float:AuraGravity[5] = { 1.0, 0.6, 0.52, 0.44, 0.36 };
new Float:AuraPushChance[5] = { 0.0, 0.15, 0.20, 0.25, 0.30 };
new Float:VampirePercent[] = {0.0, 0.05, 0.10, 0.15, 0.20};
new m_vecBaseVelocity;


new SKILL_SPEED, SKILL_LOWGRAV, SKILL_PUSH, SKILL_LEECH;

public Plugin:myinfo = 
{
    name = "War3Source Race - Aura Master",
    author = "xDr.HaaaaaaaXx",
    description = "The Aura Master race for War3Source.",
    version = "1.0.0.1",
    url = ""
};

public OnMapStart()
{

}

public OnPluginStart()
{
    m_vecBaseVelocity = FindSendPropOffs( "CBasePlayer", "m_vecBaseVelocity" );
}

public OnWar3PluginReady()
{
    thisRaceID = War3_CreateNewRace( "Aura Master", "auramaster" );
    
    SKILL_SPEED = War3_AddRaceSkill( thisRaceID, "Unholy Aura", "Speed", false );    
    SKILL_LOWGRAV = War3_AddRaceSkill( thisRaceID, "Gravity Aura", "Allows you jump higher.", false );    
    SKILL_PUSH = War3_AddRaceSkill( thisRaceID, "Excellence Aura", "Push your enemy", false );
    SKILL_LEECH = War3_AddRaceSkill( thisRaceID, "Ancient Aura", "Leeched enemy healt.", false );
    
    War3_CreateRaceEnd( thisRaceID );
    
    War3_AddSkillBuff(thisRaceID, SKILL_LEECH, fVampirePercent, VampirePercent);
}

public InitPassiveSkills( client )
{
    if( War3_GetRace( client ) == thisRaceID )
    {
        War3_SetBuff( client, fMaxSpeed, thisRaceID, AuraSpeed[War3_GetSkillLevel( client, thisRaceID, SKILL_SPEED )] );
        War3_SetBuff( client, fLowGravitySkill, thisRaceID, AuraGravity[War3_GetSkillLevel( client, thisRaceID, SKILL_LOWGRAV )] );
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
            new skill_push = War3_GetSkillLevel( attacker, thisRaceID, SKILL_PUSH );
            if( !Hexed( attacker, false ) && War3_SkillNotInCooldown(attacker,thisRaceID,SKILL_PUSH,false) && !W3HasImmunity( victim, Immunity_Skills ) && GetRandomFloat( 0.0, 1.0 ) <= AuraPushChance[skill_push] )
            {
                War3_CooldownMGR(attacker, 2.0, thisRaceID,SKILL_PUSH, _, false);
                
                new Float:velocity[3];
                
                velocity[2] += 300.0;
                
                SetEntDataVector( victim, m_vecBaseVelocity, velocity, true );
                
                W3FlashScreen( victim, RGBA_COLOR_RED );
            }
        }
    }
}