/**
* File: War3Source_999_Fighunter.sp
* Description: Fighunter Race for War3Source
* Author(s): Remy Lebeau
*/

// War3Source stuff
#pragma semicolon 1
#include <sourcemod>
#include <smlib>
#include "W3SIncs/War3Source_Interface"

new thisRaceID;
new SKILL_LONGJUMP, SKILL_GRAVITY, SKILL_DRUG, ULT_SLOW;

#define WEAPON_RESTRICT "weapon_knife,weapon_mp5navy"
#define WEAPON_GIVE "weapon_mp5navy"

public Plugin:myinfo = 
{
    name = "War3Source Race - Fighunter",
    author = "Remy Lebeau",
    description = "Skoll's private race for War3Source",
    version = "1.0",
    url = "http://sevensinsgaming.com"
};


// GRAVITY
new Float:g_fGrav[] = { 1.0, 0.85, 0.7, 0.6, 0.5 };

// LONGJUMP
new Float:SkillLongJump[]={0.0,3.0,4.5,5.0,5.5};
new m_vecVelocity_0, m_vecVelocity_1, m_vecBaseVelocity;

// DRUG
new Float:g_fDrugChance[] = {0.0, 0.1, 0.25, 0.35, 0.5 };
new Float:g_fDrugTime = 3.0;
new Float:g_fFireSpeed[] = { 1.0, 0.9, 0.8, 0.75, 0.7 };

//ULTIMATE
new Float:g_fSlow[] = { 1.0, 0.66, 0.5, 0.33, 0.01 };
new Float:g_fSlowTime = 3.0;

public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("The Fighunter [PRIVATE]","fighunter");
    
    SKILL_LONGJUMP=War3_AddRaceSkill(thisRaceID,"Homeward Bound","Player jumps forward in an arc.",false,4);
    SKILL_GRAVITY=War3_AddRaceSkill(thisRaceID,"Earth Repulsion","Anti-gravity.",false,4);
    SKILL_DRUG=War3_AddRaceSkill(thisRaceID,"Drunk-Fu","You fire drunk bullets (drugs enemy, fires slower)",false,4);
    ULT_SLOW=War3_AddRaceSkill(thisRaceID,"Fig Blade","Cuts through the very fabric of time (slows enemy on knife hit)",true,4);
    
    
    War3_CreateRaceEnd(thisRaceID);
    
    War3_AddSkillBuff(thisRaceID, SKILL_GRAVITY, fLowGravitySkill, g_fGrav);
    War3_AddSkillBuff(thisRaceID, SKILL_DRUG, fAttackSpeed, g_fFireSpeed);

    
}



public OnPluginStart()
{
    m_vecVelocity_0 = FindSendPropOffs("CBasePlayer","m_vecVelocity[0]");
    m_vecVelocity_1 = FindSendPropOffs("CBasePlayer","m_vecVelocity[1]");
    m_vecBaseVelocity = FindSendPropOffs("CBasePlayer","m_vecBaseVelocity");
    HookEvent("player_jump",PlayerJumpEvent);
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
    
    

}


public OnRaceChanged( client,oldrace,newrace )
{
    if( newrace == thisRaceID && ValidPlayer( client, true ))
    {
        War3_WeaponRestrictTo(client,thisRaceID,WEAPON_RESTRICT);
        CreateTimer( 1.0, GiveWep, client );
        InitPassiveSkills( client );
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
        War3_WeaponRestrictTo(client,thisRaceID,WEAPON_RESTRICT);
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
            new skill_level = War3_GetSkillLevel( attacker, thisRaceID, SKILL_DRUG );
            if( !Hexed( attacker, false ) && skill_level > 0 && GetRandomFloat( 0.0, 1.0 ) <= g_fDrugChance[skill_level] && !W3HasImmunity( victim, Immunity_Skills  ) )
            {
                ServerCommand( "sm_drug #%d 1", GetClientUserId( victim ) );
                PrintHintText(attacker,"You drugged your enemy");
                CreateTimer( g_fDrugTime, StopDrug, victim );
                W3FlashScreen( victim, RGBA_COLOR_BLUE );
            }
                        
            
            new ult_level = War3_GetSkillLevel( attacker, thisRaceID, ULT_SLOW );
            new String:wpnstr[32];
            GetClientWeapon( attacker, wpnstr, 32 );
            if( StrEqual( wpnstr, "weapon_knife" ) )
            {
                War3_SetBuff( victim, fSlow, thisRaceID, g_fSlow[ult_level]);
                PrintHintText(attacker,"You slowed your enemy");
                CreateTimer( g_fSlowTime, StopSlow, victim );
                W3FlashScreen( attacker, RGBA_COLOR_BLUE );
                W3FlashScreen( victim, RGBA_COLOR_BLUE );
            }
        }
    }
}



public PlayerJumpEvent(Handle:event,const String:name[],bool:dontBroadcast)
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
            velocity[0] *= SkillLongJump[skill_long]*0.25;
            velocity[1] *= SkillLongJump[skill_long]*0.25;
            SetEntDataVector( client, m_vecBaseVelocity, velocity, true );
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
        GivePlayerItem( client, WEAPON_GIVE );
    }
}


                    
public Action:StopDrug( Handle:timer, any:client )
{
    if( ValidPlayer( client ) )
    {
        ServerCommand( "sm_drug #%d 0", GetClientUserId( client ) );
    }
}

            
public Action:StopSlow( Handle:timer, any:client )
{
    if( ValidPlayer( client ) )
    {
        W3ResetAllBuffRace( client, thisRaceID );
    }
}