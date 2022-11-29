/**
* File: War3Source_999_ScopeMaster.sp
* Description: Scope Master Race for War3Source
* Author(s): Remy Lebeau
*/

// War3Source stuff
#pragma semicolon 1
#include <sourcemod>
#include <smlib>
#include "W3SIncs/War3Source_Interface"

new thisRaceID;
new SKILL_INVIS, SKILL_REGEN, SKILL_WARDS, ULT_TP;

#define WEAPON_RESTRICT ""
#define WEAPON_GIVE ""

public Plugin:myinfo = 
{
    name = "War3Source Race - Scope Master",
    author = "Remy Lebeau",
    description = "Kablamo's private race for War3Source",
    version = "0.0.1",
    url = "http://sevensinsgaming.com"
};


new Float:g_fSpeed[] = { 1.0, 1.2, 1.3, 1.4, 1.5 };
new g_iHealth[]={0,25,50,75,100};
new Float:g_fDamageBoost[] = { 0.0, 0.25, 0.35, 0.5, 0.75 };



public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("Shadow Reaper [PRIVATE]","shadowreaper");
    
    SKILL_INVIS=War3_AddRaceSkill(thisRaceID,"Shadow Blend","Blend in the shadows",false,4);
    SKILL_REGEN=War3_AddRaceSkill(thisRaceID,"Shadows of regeneration","Feed on the shadows of ur victims",false,4);
    SKILL_WARDS=War3_AddRaceSkill(thisRaceID,"Shadow Wards","Stepping into the shadows can be costly (+ability)",false,4);
    ULT_TP=War3_AddRaceSkill(thisRaceID,"Shadow Warp","Jump through shadows (+ultimate)",true,4);
    
    W3SkillCooldownOnSpawn(thisRaceID,ULT_TELEPORT,15.0,_);
    
    War3_CreateRaceEnd(thisRaceID);
    
    War3_AddSkillBuff(thisRaceID, SKILL_SPEED, fMaxSpeed, g_fSpeed);
    War3_AddSkillBuff(thisRaceID, SKILL_HEALTH, iAdditionalMaxHealth, g_iHealth);
    War3_AddSkillBuff(thisRaceID, SKILL_DAMAGE, fDamageModifier, g_fDamageBoost);
}



public OnPluginStart()
{
    HookEvent("round_end",RoundOverEvent);
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
    War3_WeaponRestrictTo(client,thisRaceID,WEAPON_RESTRICT);
    CreateTimer( 1.0, GiveWep, client );

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


public OnAbilityCommand(client,ability,bool:pressed)
{
    if (War3_GetRace(client)==thisRaceID)
    {
        if(!Silenced(client) &&  ValidPlayer(client, true))
        {
            if(ability==0 && pressed)
            {
                if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_WEB,true))
                {
                    new skill_web=War3_GetSkillLevel(client,thisRaceID,SKILL_WEB);
                    if(skill_web>0)
                    {      
                    
                    }
                    else
                    {
                        PrintHintText(client, "Level |P|ull first");
                    }
                }
            }
        }
        else
        {
            PrintHintText(client,"Silenced: Can not cast");
        }
    }
}



public OnUltimateCommand( client, race, bool:pressed )
{
    if( race == thisRaceID && pressed && ValidPlayer( client,true ) && !Silenced( client ) )
    {
        new ult_level = War3_GetSkillLevel( client, race, ULT_MENU );
        if( ult_level > 0 )
        {
            if( War3_SkillNotInCooldown( client, thisRaceID, ULT_MENU, true ))
            {
                DoArmouryMenu(client);
                War3_CooldownMGR( client, g_fUltCooldown[ult_level], thisRaceID, ULT_MENU, _, _ );
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

    

public Action:GiveWep( Handle:timer, any:client )
{
    new race = War3_GetRace( client );
    if( ValidPlayer( client, true ) && race == thisRaceID )
    {
        Client_GiveWeapon(client, WEAPON_GIVE, true); 
    }
}