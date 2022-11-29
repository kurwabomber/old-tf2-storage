/**
* File: War3Source_999_Nutron.sp
* Description: Jimmy Nutron - Goldlion161's private Race for War3Source
* Author(s): Remy Lebeau
*/

// War3Source stuff
#pragma semicolon 1
#include <sourcemod>
#include <smlib>
#include "W3SIncs/War3Source_Interface"

new thisRaceID;
new SKILL_DAMAGE, SKILL_HEALTH, SKILL_SPEED, ULT_IGNITE;


public Plugin:myinfo = 
{
    name = "War3Source Race - Jimmy Nutron",
    author = "Remy Lebeau",
    description = "Goldlion161's private race for War3Source",
    version = "1.0.1",
    url = "http://sevensinsgaming.com"
};


new Float:g_fSpeed[] = { 1.0, 1.1, 1.15, 1.2, 1.25 };
new Float:g_fDamage[] = { 0.0, 0.05, 0.10, 0.15, 0.20 };
new g_iHealth[]={0,10,20,30,50};
new Float:g_fUltCooldown[] = {0.0, 30.0, 25.0, 20.0, 15.0};
new Float:g_fUltDuration = 5.0;
new Float:g_fIgniteDuration[] = {0.0, 1.0, 2.0, 3.0, 5.0};
new bool:g_bUltToggle[MAXPLAYERS];

public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("Jimmy Nutron [PRIVATE]","nutron");
    
    SKILL_DAMAGE=War3_AddRaceSkill(thisRaceID,"Aggresive Pizza","The pizza is very aggresive, damage increase",false,4);
    SKILL_HEALTH=War3_AddRaceSkill(thisRaceID,"Father&Son Bonding","The father&son bond increases your health",false,4);
    SKILL_SPEED=War3_AddRaceSkill(thisRaceID,"Your mum is dead","Jimmy is filled with rage, runs faster",false,4);
    ULT_IGNITE=War3_AddRaceSkill(thisRaceID,"Nutron brain (+ultimate)","On activation for 5 seconds your shots will light your enemies on fire.\n But things can go bad and you light yourself on fire.",true,4);
    
    War3_CreateRaceEnd(thisRaceID);
    
    War3_AddSkillBuff(thisRaceID, SKILL_SPEED, fMaxSpeed, g_fSpeed);
    War3_AddSkillBuff(thisRaceID, SKILL_HEALTH, iAdditionalMaxHealth, g_iHealth);
    War3_AddSkillBuff(thisRaceID, SKILL_DAMAGE, fDamageModifier, g_fDamage);
    
}



public OnPluginStart()
{
    HookEvent("bullet_impact", BulletImpact);
    HookEvent("weapon_fire", WeaponFire);
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
    g_bUltToggle[client] = false;

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
*                ABILITY / ULTI FUNCTIONS
*
*
***************************************************************************/



public OnUltimateCommand(client,race,bool:pressed)
{
    if( race == thisRaceID && pressed  && ValidPlayer(client,true) && !Silenced(client))
    {
        new skill_level = War3_GetSkillLevel( client, thisRaceID, ULT_IGNITE );
        if(skill_level>0)
        {
                if(War3_SkillNotInCooldown(client,thisRaceID, ULT_IGNITE,true)) 
                {
                    g_bUltToggle[client] = true;
                    PrintHintText(client,"LOADED Fire rounds");
                    CreateTimer(g_fUltDuration, UltStop, GetClientUserId(client));
                    War3_CooldownMGR(client,g_fUltCooldown[skill_level],thisRaceID,ULT_IGNITE,true,_);
                }
        }
        else
        {
            PrintHintText(client, "Level your Ultimate first");
        }
    }
}


public Action:UltStop(Handle:timer,any:user)
{
    new client = GetClientOfUserId(user);
    if(ValidPlayer(client,true))
    {
        g_bUltToggle[client] = false;
        PrintHintText(client,"UNLOADED Fire rounds");
    }
}


/***************************************************************************
*
*
*                EVENT CONTROL FUNCTIONS
*
*
***************************************************************************/


public BulletImpact(Handle:event,const String:name[],bool:dontBroadcast)
{
    new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
    if( War3_GetRace( attacker ) ==  thisRaceID && g_bUltToggle[attacker] == true && ValidPlayer(attacker,true))
    {
        new Float:iVec[ 3 ];
        iVec[0] = GetEventFloat( event, "x" );
        iVec[1] = GetEventFloat( event, "y" );
        iVec[2] = GetEventFloat( event, "z" );
        new Float:dir[3]={0.0,0.0,0.0};
        iVec[2]+=50.0;
        TE_SetupSparks(iVec, dir, 500, 50);
        TE_SendToAll();
    }
}

public WeaponFire(Handle:event,const String:name[],bool:dontBroadcast)
{
    new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
    if(ValidPlayer(attacker, true))
    {
        if( War3_GetRace( attacker ) ==  thisRaceID && g_bUltToggle[attacker])
        {
            if(GetRandomFloat(0.0,1.0) < 0.05)
            {
                W3FlashScreen(attacker,RGBA_COLOR_RED);
                War3_ShakeScreen(attacker);
                new skill_level = War3_GetSkillLevel( attacker, thisRaceID, ULT_IGNITE );
                IgniteEntity(attacker, g_fIgniteDuration[skill_level]);

            }
        }
    }
}

public OnWar3EventPostHurt(victim, attacker, Float:damage, const String:weapon[32], bool:isWarcraft)
{
    if( W3GetDamageIsBullet() && ValidPlayer( victim, true ) && ValidPlayer( attacker, true ) && GetClientTeam( victim ) != GetClientTeam( attacker ) )
    {
        if( War3_GetRace( attacker ) == thisRaceID && g_bUltToggle[attacker] == true)
        {
            if( !W3HasImmunity( victim, Immunity_Ultimates ) && GetRandomFloat(0.0,1.0) < 0.8)
            {
                W3FlashScreen(attacker,RGBA_COLOR_RED);
                War3_ShakeScreen(attacker);
                new skill_level = War3_GetSkillLevel( attacker, thisRaceID, ULT_IGNITE );
                IgniteEntity(victim, g_fIgniteDuration[skill_level]);
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
