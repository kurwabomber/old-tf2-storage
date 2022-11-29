/**
* File: War3Source_999_Joker.sp
* Description: AGENTkrispy's Private Race for War3Source
* Author(s): Remy Lebeau
*/

// War3Source stuff
#pragma semicolon 1
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

new thisRaceID;
new SKILL_DAMAGE, SKILL_PUSH, SKILL_SPEED, SKILL_EVASION;
new HaloSprite, BeamSprite;



public Plugin:myinfo = 
{
    name = "War3Source Race - The Joker",
    author = "Remy Lebeau",
    description = "AGENTkrispy's private race for War3Source",
    version = "1.1",
    url = "http://sevensinsgaming.com"
};

public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("The Joker [PRIVATE]","joker");
    
    SKILL_DAMAGE=War3_AddRaceSkill(thisRaceID,"Card Tricks","Extra damage",false,4);
    SKILL_PUSH=War3_AddRaceSkill(thisRaceID,"Jack in the Box","Chance to knock people into the air",false,4);
    SKILL_EVASION=War3_AddRaceSkill(thisRaceID,"Illusion","People keep shooting at places you're not (evasion)",false,4);
    SKILL_SPEED=War3_AddRaceSkill(thisRaceID,"Nimble Feet","Increased movement speed",false,4);
    
        
    War3_CreateRaceEnd(thisRaceID);
}


new Float:g_fEvade[]={0.0,0.10,0.15,0.20,0.25};
new Float:g_fSpeed[] = { 1.0, 1.1, 1.2, 1.3, 1.4};
new Float:g_fDamageMultiplier[] = { 0.0, 0.1, 0.15, 0.20, 0.25 };
new Float:AuraPushChance[] = { 0.0, 0.15, 0.20, 0.25, 0.25 };
new m_vecBaseVelocity;


public OnPluginStart()
{
    m_vecBaseVelocity = FindSendPropOffs( "CBasePlayer", "m_vecBaseVelocity" );
}


public OnMapStart()
{
    HaloSprite = PrecacheModel( "materials/sprites/halo01.vmt" );
    BeamSprite = PrecacheModel( "materials/sprites/laser.vmt" );
}

/***************************************************************************
*
*
*                PLAYER CONTROL FUNCTIONS
*
*
***************************************************************************/


public InitPassiveSkills( client )
{
    new skill_speed = War3_GetSkillLevel( client, thisRaceID, SKILL_SPEED );
    War3_SetBuff( client, fMaxSpeed, thisRaceID, g_fSpeed[skill_speed]  );

    new skill_evade = War3_GetSkillLevel( client, thisRaceID, SKILL_EVASION );
    War3_SetBuff( client, fDodgeChance, thisRaceID, g_fEvade[skill_evade] );
    War3_SetBuff( client, bDodgeMode, thisRaceID, 0 ) ;
    
    War3_WeaponRestrictTo(client,thisRaceID,"weapon_tmp,weapon_deagle,weapon_knife,weapon_c4,weapon_hegrenade");

}


public OnRaceChanged( client,oldrace,newrace )
{
    if( newrace == thisRaceID && ValidPlayer( client, true ))
    {
        InitPassiveSkills(client);
        CreateTimer( 1.0, GiveWep, client );
    }
    else
    {
        W3ResetAllBuffRace( client, thisRaceID );
        War3_WeaponRestrictTo(client,thisRaceID,"");
    }
}

public OnWar3EventSpawn( client )
{
    new race = War3_GetRace( client );
    if( race == thisRaceID && ValidPlayer( client, true ))
    {
        W3ResetAllBuffRace( client, thisRaceID );
        InitPassiveSkills(client);
        
        CreateTimer( 1.0, GiveWep, client );
    }
}

public OnSkillLevelChanged(client,race,skill,newskilllevel )
{
    if( race == thisRaceID && ValidPlayer( client, true ))
    {
        InitPassiveSkills(client);
    }    
}



/***************************************************************************
*
*
*                ABILITY / ULTI FUNCTIONS
*
*
***************************************************************************/






/***************************************************************************
*
*
*                EVENT CONTROL FUNCTIONS
*
*
***************************************************************************/

public OnWar3EventPostHurt(victim, attacker, Float:damage, const String:weapon[32], bool:isWarcraft)
{
    if( W3GetDamageIsBullet() && ValidPlayer( victim, true ) && ValidPlayer( attacker, true ) && GetClientTeam( victim ) != GetClientTeam( attacker ) )
    {
        if( War3_GetRace( attacker ) == thisRaceID )
        {
        
            new skill_push = War3_GetSkillLevel( attacker, thisRaceID, SKILL_PUSH );
            if( !Hexed( attacker, true ) && GetRandomFloat( 0.01, 1.0 ) <= AuraPushChance[skill_push] && !W3HasImmunity( victim, Immunity_Skills ) )
            {
                new Float:velocity[3];
                
                velocity[2] += 600.0;
                
                SetEntDataVector( victim, m_vecBaseVelocity, velocity, true );
                
                W3FlashScreen( victim, RGBA_COLOR_RED );
            }
            
            new skill_damage = War3_GetSkillLevel( attacker, thisRaceID, SKILL_DAMAGE );
            if( !Hexed( attacker, true ) && skill_damage > 0 && !W3HasImmunity( victim, Immunity_Skills ))
            {
                War3_DealDamage( victim, RoundToFloor( damage * g_fDamageMultiplier[skill_damage] ), attacker, DMG_BULLET, "joker_damage" );                    

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








/***************************************************************************
*
*
*                HELPER FUNCTIONS / TIMERS
*
*
***************************************************************************/
    
public Action:GiveWep( Handle:timer, any:client )
{
    new race = War3_GetRace( client );
    if( ValidPlayer( client, true ) && race == thisRaceID )
    {
        GivePlayerItem( client, "weapon_tmp" );
        GivePlayerItem( client, "weapon_deagle" );
    }
}
