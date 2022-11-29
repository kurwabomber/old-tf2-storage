/**
* File: War3Source_999_Shojo.sp
* Description: Shojo Race for War3Source
* Author(s): Remy Lebeau
*/

// War3Source stuff
#pragma semicolon 1
#include <sourcemod>
#include <smlib>
#include "W3SIncs/War3Source_Interface"

new thisRaceID;
new SKILL_INVIS, SKILL_SPEED, SKILL_FOOTSTEPS, ULT_DRUNK;

public Plugin:myinfo = 
{
    name = "War3Source Race - Shojo",
    author = "Remy Lebeau",
    description = "Shojo race for War3Source",
    version = "1.0",
    url = "http://sevensinsgaming.com"
};

new Float:g_fSpeed[] = { 1.0, 1.2, 1.3, 1.35, 1.4 };
new Float:g_fInvis[] = { 1.0, 0.5, 0.4, 0.3, 0.2 };
new Float:g_fUltTime[] = {0.0, 2.5, 3.0, 3.5, 4.0};
new bool:g_bDrunkOn[MAXPLAYERS];
new bool:g_bPlayerDrunk[MAXPLAYERS];
new Float:g_fUltRadius = 250.0;
new bool:footsteps[MAXPLAYERS];

public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("Shojo [PRIVATE]","shojo");
    
    SKILL_INVIS=War3_AddRaceSkill(thisRaceID,"Dat Ghost Feeling","You're 'dead' born with it (invis)",false,4);
    SKILL_SPEED=War3_AddRaceSkill(thisRaceID,"You're a spirit","Drunken spirit speed yo self.",false,4);
    SKILL_FOOTSTEPS=War3_AddRaceSkill(thisRaceID,"You're a ghost","Who can hear you?",false,1);
    ULT_DRUNK=War3_AddRaceSkill(thisRaceID,"Shojo's true form","Show yourself 100% while your enemies get some booze (+ultimate)",true,4);
    
    War3_CreateRaceEnd(thisRaceID);
    
    War3_AddSkillBuff(thisRaceID, SKILL_SPEED, fMaxSpeed, g_fSpeed);
    War3_AddSkillBuff(thisRaceID, SKILL_INVIS, fInvisibilitySkill, g_fInvis);
    
}



public OnPluginStart()
{
    HookEvent("round_end",RoundOverEvent);

    CreateTimer( 0.2, CalcDrunk, _, TIMER_REPEAT );

}



public OnMapStart()
{

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
    War3_WeaponRestrictTo( client,thisRaceID, "weapon_knife");
    
    if(War3_GetLevel(client, thisRaceID)>6)
    {
        War3_SetBuff(client,bDisarm,thisRaceID,true);
    }
    
    
    g_bDrunkOn[client] = false;

    new skill_footsteps = War3_GetSkillLevel( client, thisRaceID, SKILL_FOOTSTEPS );
    if (skill_footsteps > 0)
    {    
        footsteps[client] = true; 
    }
    else
    {
        footsteps[client] = false; 
    }
}


public OnRaceChanged( client,oldrace,newrace )
{
    if( newrace == thisRaceID && ValidPlayer( client, true ))
    {
        InitPassiveSkills( client );
    }
    else
    {
        W3ResetAllBuffRace( client, thisRaceID );
        War3_WeaponRestrictTo(client,thisRaceID,"");
        footsteps[client] = false; 
    }
}

public OnWar3EventSpawn( client )
{
    if (ValidPlayer( client, true ))
    {
        new race = War3_GetRace( client );
        if( race == thisRaceID )
        {
            InitPassiveSkills( client );
        }
        else
        {
            g_bPlayerDrunk[client] = false;
        }
    }
}





/***************************************************************************
*
*
*                ABILITY / ULTI FUNCTIONS
*
*
***************************************************************************/



public OnUltimateCommand(client,race,bool:pressed)
{
    if( race == thisRaceID && pressed  && ValidPlayer(client,true) && !Silenced(client))
    {
        new ult_level = War3_GetSkillLevel( client, thisRaceID, ULT_DRUNK );
        if(ult_level>0)
        {
                if(War3_SkillNotInCooldown(client,thisRaceID, ULT_DRUNK,true))
                {
                        
                    War3_SetBuff(client,fInvisibilitySkill,thisRaceID,1.0);
                    War3_SetBuff(client,bDisarm,thisRaceID,false);
                    g_bDrunkOn[client] = true;
                    
                    CreateTimer( g_fUltTime[ult_level], DrunkOff, client);
                    
                    War3_CooldownMGR(client,g_fUltTime[ult_level],thisRaceID,ULT_DRUNK);
                }
        }
        else
        {
            PrintHintText(client, "Level your Ultimate first");
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

public Action:CalcDrunk (Handle:timer, any:userid )
{
    if( thisRaceID > 0 )
    {
        for( new i = 1; i <= MaxClients; i++ )
        {
            if( ValidPlayer( i, true ) )
            {
                if( War3_GetRace( i ) == thisRaceID && g_bDrunkOn[i] == true)
                {
                    DrunkWave( i );
                }
            }
        }
    }
}


public DrunkWave( client )
{
    new skill = War3_GetSkillLevel( client, thisRaceID, ULT_DRUNK );
    if( skill > 0 && !Hexed( client, false ) )
    {
        new Float:dist = g_fUltRadius;
        new ShojoTeam = GetClientTeam( client );
        new Float:ShojoPos[3];
        new Float:VictimPos[3];
        
        GetClientAbsOrigin( client, ShojoPos );
        
        ShojoPos[2] += 40.0;

        for( new i = 1; i <= MaxClients; i++ )
        {
            if( ValidPlayer( i, true ) && GetClientTeam( i ) != ShojoTeam && !W3HasImmunity( i, Immunity_Ultimates ) )
            {
                GetClientAbsOrigin( i, VictimPos );
                VictimPos[2] += 40.0;
                
                if( GetVectorDistance( ShojoPos, VictimPos ) <= dist && !g_bPlayerDrunk[i] )
                {
                
                    g_bPlayerDrunk[i] = true;
                    ServerCommand( "sm_drug #%d 1", GetClientUserId( i ) );
                    
                    PrintHintText(i,"Shojo is giving our booze!");
                    
                    CreateTimer( g_fUltTime[skill], VictimDrunkOff, i );

                    War3_ShakeScreen( i, 1.0, 50.0, 40.0 );
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

public RoundOverEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    for(new i=1;i<=MaxClients;i++)
    {
        if(ValidPlayer(i) && (War3_GetRace( i ) == thisRaceID) )
        {
            W3ResetAllBuffRace( i, thisRaceID );
        }
    }
}

public Action:DrunkOff( Handle:timer, any:client )
{
    new invis_level = War3_GetSkillLevel( client, thisRaceID, SKILL_INVIS );
    War3_SetBuff(client,fInvisibilitySkill,thisRaceID,g_fInvis[invis_level]);
    War3_SetBuff(client,bDisarm,thisRaceID,true);
    g_bDrunkOn[client] = false;
}


public Action:VictimDrunkOff( Handle:timer, any:i )
{
    if(ValidPlayer(i))
    {
        ServerCommand( "sm_drug #%d 0", GetClientUserId( i ) );
        g_bPlayerDrunk[i] = false;
    }
}


public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
    if(ValidPlayer (client, true))
    {
        if(buttons & (IN_FORWARD | IN_BACK | IN_MOVELEFT | IN_MOVERIGHT | IN_JUMP) && footsteps[client] == true)
        {
            SetEntProp(client, Prop_Send, "m_fFlags", 4);
        }
    }
    return Plugin_Continue;
}
