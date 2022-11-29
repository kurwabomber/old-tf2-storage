/**
* File: War3Source_999_Horsemen_War.sp
* Description: War Race for War3Source
* Author(s): Remy Lebeau
*/

// War3Source stuff
#pragma semicolon 1
#include <sourcemod>
#include <smlib>

#include "W3SIncs/War3Source_Interface"
#include "W3SIncs/haaaxfunctions.inc"

new thisRaceID;
new SKILL1, SKILL2, SKILL3, SKILL4;

#define WEAPON_RESTRICT "weapon_knife,weapon_elite"
#define WEAPON_GIVE "weapon_elite"

public Plugin:myinfo = 
{
    name = "War3Source Race - War [HORSEMEN]",
    author = "Remy Lebeau",
    description = "War race for War3Source",
    version = "0.0.1",
    url = "http://sevensinsgaming.com"
};


new Float:g_fSpeed[] = { 1.0, 1.2, 1.25, 1.3, 1.35 };
new Float:g_fDamage[] = { 0.0, 0.05, 0.075, 0.1, 0.15 };

new Float:g_fRespawnChanceArr[]={0.0,0.2,0.3,0.4,0.5};


new Float:g_fSpeedLevel[] = { 1.0, 0.9, 0.85, 0.8, 0.75 };
new Float:AuraDistance=400.0;
new Float:AuraDam[]={0.0,0.5,1.0,1.5,2.0};


new g_iTarget[MAXPLAYERS];

public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("War - Red Horseman","horseman_war");
    
    SKILL1=War3_AddRaceSkill(thisRaceID,"War's Weapon","War carries a red sword.",false,4);
    SKILL2=War3_AddRaceSkill(thisRaceID,"War's Speed","War's horse - Well... Red Mustang!",false,4);
    SKILL3=War3_AddRaceSkill(thisRaceID,"War's Manipulation","Manipulates enemies to defect (respawns team mates on kill).",false,4);
    SKILL4=War3_AddRaceSkill(thisRaceID,"War's Presence","Everyone starts to feel a burning sensation.",true,4);

    
    War3_CreateRaceEnd(thisRaceID);

    
    War3_AddAuraSkillBuff(thisRaceID, SKILL4, fSlow, g_fSpeedLevel, 
                            "presence_slow", AuraDistance, 
                            true);
    
    War3_AddAuraSkillBuff(thisRaceID, SKILL4, fHPDecay, AuraDam, 
                            "presence_decay", AuraDistance, 
                            true);
    
    War3_AddSkillBuff(thisRaceID, SKILL1, fDamageModifier, g_fDamage);      
    War3_AddSkillBuff(thisRaceID, SKILL2, fMaxSpeed, g_fSpeed);
  
}



public OnPluginStart()
{
}



public OnMapStart()
{
    //BurnSprite=PrecacheModel("materials/sprites/fire1.vmt");
    //BeamSprite=PrecacheModel("materials/sprites/lgtning.vmt");
    //HaloSprite=PrecacheModel("materials/sprites/halo01.vmt");
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
    War3_WeaponRestrictTo(client,thisRaceID,WEAPON_RESTRICT);
    CreateTimer( 1.0, GiveWep, client );

}


public OnRaceChanged( client,oldrace,newrace )
{
    if( newrace == thisRaceID )
    {
        if(ValidPlayer( client, true))
        {
            InitPassiveSkills( client );
        }
        
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
        InitPassiveSkills( client );
    }
}




/***************************************************************************
*
*
*               MANIPULATION
*
*
***************************************************************************/


public OnWar3EventDeath(victim,attacker)
{
    new race = War3_GetRace( attacker );
    
    if( race == thisRaceID && ValidPlayer( attacker, true )&& ValidPlayer(victim) && attacker != victim)
    {
        new skill_level = War3_GetSkillLevel(attacker,thisRaceID,SKILL3);
        if(skill_level>0 && GetRandomFloat(0.0,1.0)<=g_fRespawnChanceArr[skill_level]&&!Silenced(attacker))
        {
            new target;
            if( GetClientTeam( attacker ) == TEAM_T )
                target = War3_GetRandomPlayer( attacker, "#t" );
            if( GetClientTeam( attacker ) == TEAM_CT )
                target = War3_GetRandomPlayer( attacker, "#ct" );
            if( target == 0 )
            {
                PrintHintText( attacker, "No dead teammates to revive." );
            }
            else
            {
                g_iTarget[target] = victim;    
                CreateTimer(4.0,DoRevival,GetClientUserId(target));
                PrintHintText(target, "You have been summoned to join WAR's army. \nRespawning in 4 seconds");
                PrintHintText(attacker, "You have recruited another army members. \nRespawning in 4 seconds");
                
            }
        }
    }
}

public Action:DoRevival(Handle:timer,any:userid)
{
    new target=GetClientOfUserId(userid);
    
    new Float:VecPos[3];
    new Float:Angles[3];
    War3_CachedAngle(g_iTarget[target],Angles);
    War3_CachedPosition(g_iTarget[target],VecPos);
    War3_SpawnPlayer(target); 
    TeleportEntity(target, VecPos, Angles, NULL_VECTOR);

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
        GivePlayerItem( client, WEAPON_GIVE );
    }
}