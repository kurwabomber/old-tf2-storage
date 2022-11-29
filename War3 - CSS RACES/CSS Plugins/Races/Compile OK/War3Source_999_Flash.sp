/**
* File: War3Source_999_Flash.sp
* Description: Flash Race for War3Source
* Author(s): Remy Lebeau
*/

// War3Source stuff
#pragma semicolon 1
#include <sourcemod>
#include <smlib>
#include "W3SIncs/War3Source_Interface"

new thisRaceID;
new SKILL_SPEED, SKILL_EVASION, SKILL_BOOM;



public Plugin:myinfo = 
{
    name = "War3Source Race - Flash",
    author = "Remy Lebeau",
    description = "Flash race for War3Source",
    version = "0.0.1",
    url = "http://sevensinsgaming.com"
};


new Float:g_fSpeed = 2.0;
new Float:g_fEvasion = 0.15;
new GravForce = 2;
new m_vecBaseVelocity;
new Float:g_fBoomRadius=650.0;
new ExplosionModel;


public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("Flash [REWARD]","flash");
   
    SKILL_SPEED=War3_AddRaceSkill(thisRaceID,"Flash","SPEED!",false,10);
    SKILL_EVASION=War3_AddRaceSkill(thisRaceID,"Vibrate","EVASION!",false,10);
    SKILL_BOOM=War3_AddRaceSkill(thisRaceID,"Talk really fast","SONIC BOOM!(+ability)",false,10);
    
    War3_CreateRaceEnd(thisRaceID);

    
}



public OnPluginStart()
{
    m_vecBaseVelocity = FindSendPropOffs( "CBasePlayer", "m_vecBaseVelocity" );
}



public OnMapStart()
{
    ExplosionModel = PrecacheModel( "materials/sprites/zerogxplode.vmt", false );
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
    War3_SetBuff( client, fMaxSpeed, thisRaceID, g_fSpeed  );
    War3_SetBuff(client,bSlowImmunity,thisRaceID,true);
    
    War3_SetBuff( client, fDodgeChance, thisRaceID, g_fEvasion  );


}


public OnRaceChanged( client,oldrace,newrace )
{
    if( newrace == thisRaceID && ValidPlayer( client, true ))
    {
        War3_WeaponRestrictTo( client,thisRaceID, "weapon_knife,weapon_fiveseven");
        InitPassiveSkills( client );
        
        CreateTimer( 1.0, giveWeapon, client );
    }
    else
    {
        if(SKILL_SPEED || SKILL_EVASION) // purely to remove compiler warnings... 
        {}
        else
        {}
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
        War3_WeaponRestrictTo( client,thisRaceID, "weapon_knife,weapon_fiveseven");
        CreateTimer( 1.0, giveWeapon, client );
    }
}






/***************************************************************************
*
*
*                ABILITY / ULTI FUNCTIONS
*
*
***************************************************************************/


public OnAbilityCommand(client,ability,bool:pressed)
{
    if(War3_GetRace(client)==thisRaceID && pressed && ValidPlayer(client,true) && ability==0)
    {
        new skill_level = War3_GetSkillLevel( client, thisRaceID,SKILL_BOOM );
        if(!Silenced(client) && War3_SkillNotInCooldown(client,thisRaceID,SKILL_BOOM,true))
        {
            if(skill_level > 0)
            {
                new Float:pos1[3];
                GetClientAbsOrigin( client, pos1 );
                
                TE_SetupExplosion( pos1, ExplosionModel, 150.0, 5, TE_EXPLFLAG_NOFIREBALLSMOKE, RoundToFloor( g_fBoomRadius ), 160);
                TE_SendToAll();
                
                for(new i=1;i<=MaxClients;i++)
                {
                    if(ValidPlayer(i,true) && GetClientTeam( i ) != GetClientTeam( client))
                    {

                        new Float:pos2[3];

                        GetClientAbsOrigin( i, pos2 );
                        pos2[2]+=30.0;
                        new Float:victimdistance=GetVectorDistance(pos1,pos2);
                        if(victimdistance<g_fBoomRadius)
                        {
                            new Float:velocity[3];

                            MakeVectorFromPoints(pos1, pos2, velocity);
                            NormalizeVector(velocity, velocity);
                            ScaleVector(velocity, 100.0 * GravForce);
                            velocity[2] += 300.0;

                            SetEntDataVector( i, m_vecBaseVelocity, velocity, true );
                        }
                    }
                
                }

                War3_CooldownMGR(client,20.0,thisRaceID,SKILL_BOOM,_,_);

            }
                
            else
            {
                PrintHintText(client, "Level Sonic Boom first");
            }
        }
        
    }

}





/***************************************************************************
*
*
*                EVENT CONTROL FUNCTIONS
*
*
***************************************************************************/




/***************************************************************************
*
*
*                HELPER FUNCTIONS / TIMERS
*
*
***************************************************************************/
public Action:giveWeapon(Handle:timer,any:client)
{
    if (ValidPlayer(client, true) && !Client_HasWeapon(client, "weapon_fiveseven"))
    {
        GivePlayerItem( client, "weapon_fiveseven");
    }
}
