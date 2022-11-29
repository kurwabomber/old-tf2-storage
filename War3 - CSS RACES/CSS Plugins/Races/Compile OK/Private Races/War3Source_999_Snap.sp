/**
* File: War3Source_999_Snap.sp
* Description: Snap Race for War3Source
* Author(s): Remy Lebeau
*/

// War3Source stuff
#pragma semicolon 1
#include <sourcemod>
#include <smlib>
#include "W3SIncs/War3Source_Interface"

new thisRaceID;
new SKILL_SPEED, SKILL_INVIS, SKILL_LEECH, ULT_WEB;



public Plugin:myinfo = 
{
    name = "War3Source Race - Snap",
    author = "Remy Lebeau",
    description = "Snap's private race for War3Source",
    version = "0.9.1",
    url = "http://sevensinsgaming.com"
};


new Float:g_fSpeed[] = { 1.0, 1.16, 1.20, 1.3, 1.4 };
new Float:g_fVampirePercent[] = {0.0, 0.1, 0.2, 0.30, 0.4};
new Float:g_fInvis[] = { 1.0, 0.8, 0.7, 0.6, 0.5 };


//ULTIMATE
new Float:g_fUltCooldown = 4.0;
new String:ult_sound[] = "weapons/physcannon/physcannon_claws_open.wav";
new m_vecBaseVelocity;
new Float:PushForce[5] = { 0.0, 0.7, 1.1, 1.3, 1.7 };


public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("Snap [PRIVATE]","snap");
    
    SKILL_SPEED=War3_AddRaceSkill(thisRaceID,"Chickenlegs","Run around like a chook with it's head cut off.",false,4);
    SKILL_INVIS=War3_AddRaceSkill(thisRaceID,"2Spooky5Me","Invisibility",false,4);
    SKILL_LEECH=War3_AddRaceSkill(thisRaceID,"Bloodthirsty","Heath leech",false,4);
    ULT_WEB=War3_AddRaceSkill(thisRaceID,"Lunge","Fling yourself invisibly at your enemy (+ultimate)",true,4);
    

    
    War3_CreateRaceEnd(thisRaceID);
    
    War3_AddSkillBuff(thisRaceID, SKILL_SPEED, fMaxSpeed, g_fSpeed);
    War3_AddSkillBuff(thisRaceID, SKILL_INVIS, fInvisibilitySkill, g_fInvis);
    War3_AddSkillBuff(thisRaceID, SKILL_LEECH, fVampirePercent, g_fVampirePercent);
}



public OnPluginStart()
{
}



public OnMapStart()
{
    War3_PrecacheSound( ult_sound );
    m_vecBaseVelocity = FindSendPropOffs( "CBasePlayer", "m_vecBaseVelocity" );
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
    
    

}


public OnRaceChanged( client,oldrace,newrace )
{
    if( newrace == thisRaceID && ValidPlayer( client, true ))
    {
        War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife");
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
        War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife");

    }
}




/***************************************************************************
*
*
*                ABILITY / ULTI FUNCTIONS
*
*
***************************************************************************/

public OnUltimateCommand( client, race, bool:pressed )
{
    if( race == thisRaceID && pressed && IsPlayerAlive( client ) && !Silenced( client ) )
    {
        new ult_level = War3_GetSkillLevel( client, race, ULT_WEB );
        if( ult_level > 0 )
        {
            if( War3_SkillNotInCooldown( client, thisRaceID, ULT_WEB, true ) )
            {
                TeleportPlayer( client );
                EmitSoundToAll( ult_sound, client );
                War3_CooldownMGR( client, g_fUltCooldown, thisRaceID, ULT_WEB );
            }
        }
        else
        {
            W3MsgUltNotLeveled( client );
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

stock TeleportPlayer( client )
{
    if( client > 0 && IsPlayerAlive( client ) )
    {
        new ult_level = War3_GetSkillLevel( client, thisRaceID, ULT_WEB );
        new Float:startpos[3];
        new Float:endpos[3];
        new Float:localvector[3];
        new Float:velocity[3];
        
        GetClientAbsOrigin( client, startpos );
        War3_GetAimTraceMaxLen(client, endpos, 2500.0);
        
        localvector[0] = endpos[0] - startpos[0];
        localvector[1] = endpos[1] - startpos[1];
        localvector[2] = endpos[2] - startpos[2];
        
        velocity[0] = localvector[0] * PushForce[ult_level];
        velocity[1] = localvector[1] * PushForce[ult_level];
        velocity[2] = localvector[2] * PushForce[ult_level];
        
        SetEntDataVector( client, m_vecBaseVelocity, velocity, true );
        War3_SetBuff(client,fInvisibilitySkill,thisRaceID,0.0);
        CreateTimer(1.0,RemoveInvis,client);

    }
}




public Action:RemoveInvis(Handle:t,any:client)
{
    if(ValidPlayer(client,true))
    {
        new skill_level=War3_GetSkillLevel(client,thisRaceID,SKILL_INVIS);
        War3_SetBuff(client,fInvisibilitySkill,thisRaceID,g_fInvis[skill_level]);

    }
}
