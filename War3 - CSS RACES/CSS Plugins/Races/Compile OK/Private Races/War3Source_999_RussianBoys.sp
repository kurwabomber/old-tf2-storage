/**
* File: War3Source_999_RussianBoys.sp
* Description: Russian Boys Race for War3Source
* Author(s): Remy Lebeau
*/

// War3Source stuff
#pragma semicolon 1
#include <sourcemod>
#include <smlib>
#include "W3SIncs/War3Source_Interface"

new thisRaceID;
new SKILL_ARMOUR, SKILL_WEP, SKILL_HEALTH, ULT_GUN;

#define WEAPON_RESTRICT "weapon_knife,weapon_deagle,weapon_ak47"
#define WEAPON_GIVE "weapon_deagle"

public Plugin:myinfo = 
{
    name = "War3Source Race - Russian Boys",
    author = "Remy Lebeau",
    description = "Sir Campalot's private race for War3Source",
    version = "0.0.1",
    url = "http://sevensinsgaming.com"
};


new Float:g_fDmgLevel[] = { 0.0, 0.95, 0.9, 0.85, 0.8 };
new Float:g_fDamageBoost[] = { 0.0, 0.025, 0.05, 0.075, 0.1 };
new g_iHealth[]={0,10,20,30,40};


new Float:g_fSpeed[] = { 1.0, 1.15, 1.2, 1.25, 1.3 };





public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("Russian Boys [PRIVATE]","russianboys");
    
    SKILL_ARMOUR=War3_AddRaceSkill(thisRaceID,"Russian Roids","Deal extra damage",false,4);
    SKILL_WEP=War3_AddRaceSkill(thisRaceID,"Vodka Rampage","So drunk cannot feel damage",false,4);
    SKILL_HEALTH=War3_AddRaceSkill(thisRaceID,"Russian beast","Spawn with extra health ",false,4);
    ULT_GUN=War3_AddRaceSkill(thisRaceID,"Angry Russian","Spawns a temporary super AK47 (+ultimate)",true,4);
    
    W3SkillCooldownOnSpawn(thisRaceID,ULT_GUN,10.0,_);
    
    War3_CreateRaceEnd(thisRaceID);
    
    War3_AddSkillBuff(thisRaceID, SKILL_WEP, fDamageModifier, g_fDamageBoost);
    War3_AddSkillBuff(thisRaceID, SKILL_HEALTH, iAdditionalMaxHealth, g_iHealth);
    
    
    
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





/***************************************************************************
*
*
*                ABILITY / ULTI FUNCTIONS
*
*
***************************************************************************/




public OnUltimateCommand( client, race, bool:pressed )
{
    if( race == thisRaceID && pressed && ValidPlayer( client,true ) && !Silenced( client ) )
    {
        new ult_level = War3_GetSkillLevel( client, race, ULT_GUN );
        if( ult_level > 0 )
        {
            if( War3_SkillNotInCooldown( client, thisRaceID, ULT_GUN, true ))
            {
                GivePlayerItem(client, "weapon_ak47");
                War3_SetBuff( client, fMaxSpeed, thisRaceID, g_fSpeed[ult_level] );  
                War3_SetBuff( client, fAttackSpeed, thisRaceID, g_fSpeed[ult_level] );                
                CreateTimer( 30.0, StopStim, client );
                War3_CooldownMGR( client, 600.0, thisRaceID, ULT_GUN, _, _ );
                W3FlashScreen( client, RGBA_COLOR_RED );
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


public OnW3TakeDmgAllPre(victim,attacker,Float:damage)
{
    if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim){
        new vteam=GetClientTeam(victim);
        new ateam=GetClientTeam(attacker);
        
        if(vteam!=ateam)
        {
            //new race_attacker=War3_GetRace(attacker);
            new race_victim=War3_GetRace(victim);
            if(race_victim==thisRaceID )
            {
                new skill_armour = War3_GetSkillLevel(victim, thisRaceID, SKILL_ARMOUR);
                if (skill_armour>0)
                {
                    War3_DamageModPercent(g_fDmgLevel[skill_armour]);
                    new Float:amount = (1-g_fDmgLevel[skill_armour]) * 100; 
                    PrintToConsole(attacker, "Damage Reduced by |%.2f| (percent) against Russian Boys", amount);
                    PrintToConsole(victim, "Damage Reduced by |%.2f| (percent) by Russian Boys", amount);
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


public Action:StopStim( Handle:timer, any:client )
{
	new race = War3_GetRace( client );
	if( ValidPlayer( client, true ) && race == thisRaceID )
	{
		War3_SetBuff( client, fMaxSpeed, thisRaceID, 1.0 );
		War3_SetBuff( client, fAttackSpeed, thisRaceID, 1.0 );
	}
}
    

public Action:GiveWep( Handle:timer, any:client )
{
    new race = War3_GetRace( client );
    if( ValidPlayer( client, true ) && race == thisRaceID )
    {
        GivePlayerItem(client, WEAPON_GIVE); 
    }
}