/*
* File: War3Source_Envy.sp
* Description: New race for Seven Sins Gaming use ONLY.
* Author(s): Corrupted
*/

#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdkhooks>
#include <sdktools>
#include <sdktools_functions>
#include <sdktools_tempents>
#include <sdktools_tempents_stocks>
#include <sdktools_sound>

new thisRaceID;

new Float:EnvyDamageMultiplier[5] = { 0.0, 0.04, 0.08, 0.12, 0.15 };
new Float:EnvySpeed[5] = { 1.0, 1.05, 1.10, 1.15, 1.2 };
new EnvyHealth[5] = { 0, 15, 30, 45, 60 };
new Float:TransformDuration[5] = { 0.0, 5.0, 10.0, 15.0, 20.0 };

new String:TransformSound[]="war3source/butcher/taunt_after.mp3";

new HaloSprite, BeamSprite;

new SKILL_HEALTH, SKILL_SPEED, SKILL_DAMAGE, ULT_TRANSFORM;

public Plugin:myinfo =
{
    name = "War3Source Race - Envy",
    author = "Corrupted",
    description = "Donator race for Seven Sins Gaming use ONLY.",
    version = "1.0.0.1",
    url = "www.sevensinsgaming.com",
};

public OnWar3PluginReady()
{
        thisRaceID=War3_CreateNewRace("Envy [SSG-DONATOR]","CorruptedEnvy");
        SKILL_HEALTH=War3_AddRaceSkill(thisRaceID,"Health boost (passive)","Gives you extra health.",false);
        SKILL_SPEED=War3_AddRaceSkill(thisRaceID,"Speed (passive)","Makes you run faster.",false);
        SKILL_DAMAGE=War3_AddRaceSkill(thisRaceID,"Damage Boost (passive)","You deal extra damage with guns and grenades.",false);
        ULT_TRANSFORM=War3_AddRaceSkill(thisRaceID,"Ultimate: Shapeshift","You appear to be on the opposite team.",false);
        War3_CreateRaceEnd(thisRaceID);
        W3SkillCooldownOnSpawn( thisRaceID, ULT_TRANSFORM, 10.0, _);
}

public OnMapStart()
{
    War3_AddCustomSound( TransformSound );
    HaloSprite = PrecacheModel( "materials/sprites/halo01.vmt" );
    BeamSprite = PrecacheModel( "materials/sprites/laser.vmt" );
}

public OnSkillLevelChanged(client,race,skill,newskilllevel )
{
    InitPassiveSkills(client);
}

public OnWar3EventSpawn(client)
{
    if(War3_GetRace(client)==thisRaceID)
    {
        InitPassiveSkills(client);
    }
}

public OnRaceChanged( client,oldrace,newrace )
{
    if( newrace != thisRaceID)
    {
        W3ResetAllBuffRace(client,thisRaceID );
    }
}

public InitPassiveSkills ( client )
{
    if( War3_GetRace( client ) == thisRaceID )
    {
        War3_SetBuff( client, fMaxSpeed, thisRaceID, EnvySpeed[War3_GetSkillLevel( client, thisRaceID, SKILL_SPEED )] );
        new skill_hp=War3_GetSkillLevel(client, thisRaceID, SKILL_HEALTH);
        if(skill_hp >0)
        {
            War3_SetBuff(client,iAdditionalMaxHealth,thisRaceID,EnvyHealth [skill_hp]);    
        }
    }
}

public OnWar3EventPostHurt(victim, attacker, Float:damage, const String:weapon[32], bool:isWarcraft)
{
    if( W3GetDamageIsBullet() && ValidPlayer( victim, true ) && ValidPlayer( attacker, true ) && GetClientTeam( victim ) != GetClientTeam( attacker ) )
    {
        if( War3_GetRace( attacker ) == thisRaceID && !W3HasImmunity( victim, Immunity_Skills ))
        {
            new skill_damage = War3_GetSkillLevel( attacker, thisRaceID, SKILL_DAMAGE );
            if( !Hexed( attacker, true ) && skill_damage > 0 )
            {
                new String:wpnstr[32];
                GetClientWeapon( attacker, wpnstr, 32 );
                if( !StrEqual( wpnstr, "weapon_hegrenade" ) && !StrEqual( wpnstr, "weapon_knife" ) )
                {
                    War3_DealDamage( victim, RoundToFloor( damage * EnvyDamageMultiplier[skill_damage] ), attacker, DMG_BULLET, "envy_damage" );                    
                }
                new DICE = (GetRandomInt(1,3));
                if (DICE == 1)
                {
                new Float:StartPos[3];
                new Float:EndPos[3];
        
                GetClientAbsOrigin( victim, StartPos );
        
                GetClientAbsOrigin( victim, EndPos );
                
                EndPos[0] += GetRandomFloat( -100.0, 100.0 );
                EndPos[1] += GetRandomFloat( -100.0, 100.0 );
                EndPos[2] += GetRandomFloat( -100.0, 100.0 );

                TE_SetupBeamPoints( StartPos, EndPos, BeamSprite, HaloSprite, 0, 1, 10.0, 20.0, 2.0, 0, 0.0, { 255, 11, 15, 255 }, 1 );
                TE_SendToAll();
                
                GetClientAbsOrigin( victim, EndPos );
                
                EndPos[0] += GetRandomFloat( -100.0, 100.0 );
                EndPos[1] += GetRandomFloat( -100.0, 100.0 );
                EndPos[2] += GetRandomFloat( -100.0, 100.0 );
                
                TE_SetupBeamPoints( StartPos, EndPos, BeamSprite, HaloSprite, 0, 1, 10.0, 20.0, 2.0, 0, 0.0, { 255, 11, 15, 255 }, 1 );
                TE_SendToAll();
                
                GetClientAbsOrigin( victim, EndPos );
                
                EndPos[0] += GetRandomFloat( -100.0, 100.0 );
                EndPos[1] += GetRandomFloat( -100.0, 100.0 );
                EndPos[2] += GetRandomFloat( -100.0, 100.0 );
                
                TE_SetupBeamPoints( StartPos, EndPos, BeamSprite, HaloSprite, 0, 1, 10.0, 20.0, 2.0, 0, 0.0, { 255, 11, 15, 255 }, 1 );
                TE_SendToAll();
                }
                if (DICE == 2)
                {
                new Float:StartPos[3];
                new Float:EndPos[3];
                
                GetClientAbsOrigin( victim, StartPos );
                
                GetClientAbsOrigin( victim, EndPos );
                
                EndPos[0] += GetRandomFloat( -100.0, 100.0 );
                EndPos[1] += GetRandomFloat( -100.0, 100.0 );
                EndPos[2] += GetRandomFloat( -100.0, 100.0 );

                TE_SetupBeamPoints( StartPos, EndPos, BeamSprite, HaloSprite, 0, 1, 10.0, 20.0, 2.0, 0, 0.0, { 11, 255, 15, 255 }, 1 );
                TE_SendToAll();
                
                GetClientAbsOrigin( victim, EndPos );
                
                EndPos[0] += GetRandomFloat( -100.0, 100.0 );
                EndPos[1] += GetRandomFloat( -100.0, 100.0 );
                EndPos[2] += GetRandomFloat( -100.0, 100.0 );
                
                TE_SetupBeamPoints( StartPos, EndPos, BeamSprite, HaloSprite, 0, 1, 10.0, 20.0, 2.0, 0, 0.0, { 11, 255, 15, 255 }, 1 );
                TE_SendToAll();
            
                GetClientAbsOrigin( victim, EndPos );
        
                EndPos[0] += GetRandomFloat( -100.0, 100.0 );
                EndPos[1] += GetRandomFloat( -100.0, 100.0 );
                EndPos[2] += GetRandomFloat( -100.0, 100.0 );
                
                TE_SetupBeamPoints( StartPos, EndPos, BeamSprite, HaloSprite, 0, 1, 10.0, 20.0, 2.0, 0, 0.0, { 11, 255, 15, 255 }, 1 );
                TE_SendToAll();
                }
                if (DICE == 3)
                {
                new Float:StartPos[3];
                new Float:EndPos[3];
                
                GetClientAbsOrigin( victim, StartPos );
                
                GetClientAbsOrigin( victim, EndPos );
                
                EndPos[0] += GetRandomFloat( -100.0, 100.0 );
                EndPos[1] += GetRandomFloat( -100.0, 100.0 );
                EndPos[2] += GetRandomFloat( -100.0, 100.0 );

                TE_SetupBeamPoints( StartPos, EndPos, BeamSprite, HaloSprite, 0, 1, 10.0, 20.0, 2.0, 0, 0.0, { 11, 15, 255, 255 }, 1 );
                TE_SendToAll();
                
                GetClientAbsOrigin( victim, EndPos );
                
                EndPos[0] += GetRandomFloat( -100.0, 100.0 );
                EndPos[1] += GetRandomFloat( -100.0, 100.0 );
                EndPos[2] += GetRandomFloat( -100.0, 100.0 );
                
                TE_SetupBeamPoints( StartPos, EndPos, BeamSprite, HaloSprite, 0, 1, 10.0, 20.0, 2.0, 0, 0.0, { 11, 15, 255, 255 }, 1 );
                TE_SendToAll();
                
                GetClientAbsOrigin( victim, EndPos );
            
                EndPos[0] += GetRandomFloat( -100.0, 100.0 );
                EndPos[1] += GetRandomFloat( -100.0, 100.0 );
                EndPos[2] += GetRandomFloat( -100.0, 100.0 );
                
                TE_SetupBeamPoints( StartPos, EndPos, BeamSprite, HaloSprite, 0, 1, 10.0, 20.0, 2.0, 0, 0.0, { 11, 15, 255, 255 }, 1 );
                TE_SendToAll();
                }
            }    
        }
    }
}

public OnUltimateCommand( client, race, bool:pressed )
{
    if( race == thisRaceID && pressed && IsPlayerAlive( client ) && !Silenced( client ) )
    {
        new ult_level = War3_GetSkillLevel( client, race, ULT_TRANSFORM );
        if( ult_level > 0 )
        {
            if( War3_SkillNotInCooldown( client, thisRaceID, ULT_TRANSFORM, true ) )
            {
                if( GetClientTeam( client ) == TEAM_T )
                {
                    SetEntityModel( client, "models/player/ct_urban.mdl" );
                }
                if( GetClientTeam( client ) == TEAM_CT )
                {
                    SetEntityModel( client, "models/player/t_leet.mdl" );
                }
                PrintHintText( client, "You have transformed in to the enemy" );
                CreateTimer( TransformDuration[ult_level], StopTransform, client );
                War3_CooldownMGR( client, TransformDuration[ult_level] + TransformDuration[ult_level], thisRaceID, ULT_TRANSFORM );
            }
        }
        else
        {
            PrintHintText( client, "Level your ultimate first, noob!" );
        }
    }
}

public Action:StopTransform ( Handle:timer, any:client )
{
    if (ValidPlayer(client, true))
    {
        if( GetClientTeam( client ) == TEAM_T )
        {
			SetEntityModel( client, "models/player/t_leet.mdl" );
        }
        if( GetClientTeam( client ) == TEAM_CT )
        {
            SetEntityModel( client, "models/player/ct_urban.mdl" );
        }
        PrintHintText( client, "You transform back to your normal form" );
    }    
}