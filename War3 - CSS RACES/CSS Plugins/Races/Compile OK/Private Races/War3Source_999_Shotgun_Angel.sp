/**
* File: War3Source_999_Shotgun_Angel.sp
* Description: Shotgun Angel - Leftclickkill's Private Race for War3Source
* Author(s): Remy Lebeau
*/

// War3Source stuff
#pragma semicolon 1
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
    name = "War3Source Race - Shotgun Angel",
    author = "Remy Lebeau",
    description = "Leftclickkill's custom race for War3Source",
    version = "1.2",
    url = "http://sevensinsgaming.com"
};


new thisRaceID;
new SKILL_AURA, SKILL_BENEFITS, SKILL_RAGE, ULT_WARRIOR;
new Handle:timer_handle[MAXPLAYERS+1];

// SKILL_AURA VARIABLES
new Float:HealingWaveDistance=500.0;
new Float:g_fHealingWaveAmountArr[]={0.0,2.0,3.0,4.0,5.0};
new AuraID;

// SKILL_BENEFITS VARIABLES
new Float:g_fSpeedBoost[] = { 1.0, 1.20, 1.30, 1.40, 1.50 };


// SKILL_RAGE VARIABLES
new Float:g_fRageDuration[] = {0.0, 5.0, 7.5, 10.0, 12.5};

// ULT_WARRIOR VARIABLES
new Float:SuicideBomberRadius[5] = {0.0, 250.0, 300.0, 350.0, 400.0}; 
new Float:SuicideBomberDamage[5] = {0.0, 266.0, 300.0, 333.0, 366.0};


public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("Shotgun Angel [PRIVATE]","shotgun_angel");
    
    SKILL_AURA=War3_AddRaceSkill(thisRaceID,"Angel Aura","Heal yourself and nearby allies (passive)",false,4);
    SKILL_BENEFITS=War3_AddRaceSkill(thisRaceID,"Angel Wings","Move faster (passive)",false,4);
    SKILL_RAGE=War3_AddRaceSkill(thisRaceID,"Angel Rage","Double damage! (+ability)",false,4);
    ULT_WARRIOR=War3_AddRaceSkill(thisRaceID,"The Sacrifice","Destroy yourself for the sake of your team! (+ultimate)",true,4);
    
    W3SkillCooldownOnSpawn(thisRaceID,ULT_WARRIOR,15.0,_);
    W3SkillCooldownOnSpawn(thisRaceID,SKILL_RAGE,10.0,_);
    
    War3_CreateRaceEnd(thisRaceID);
    
    AuraID=W3RegisterAura("shotgun_angel_healwave",HealingWaveDistance);
}

public OnPluginStart()
{
	HookEvent("round_end",RoundOverEvent);
}


/***************************************************************************
*
*
*                PLAYER CONTROL FUNCTIONS
*
*
***************************************************************************/


InitPassiveSkills( client )
{
    new level_aura=War3_GetSkillLevel(client,thisRaceID,SKILL_AURA);
    new level_benefits=War3_GetSkillLevel(client,thisRaceID,SKILL_BENEFITS);
    
    W3SetAuraFromPlayer(AuraID,client,level_aura>0?true:false,level_aura);
    War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife,weapon_fiveseven,weapon_m3");
    
    War3_SetBuff( client, fMaxSpeed, thisRaceID, g_fSpeedBoost[level_benefits] );
    
    War3_SetBuff( client, fHPRegen, thisRaceID, g_fHealingWaveAmountArr[level_aura]  );

}


public OnRaceChanged( client,oldrace,newrace )
{
    if( newrace == thisRaceID && ValidPlayer( client, true ))
    {    
        
        InitPassiveSkills(client);
    }
    else
    {
        W3ResetAllBuffRace( client, thisRaceID );
        War3_WeaponRestrictTo(client,thisRaceID,"");
        
        //PrintToServer("deactivate aura");
        W3SetAuraFromPlayer(AuraID,client,false);
    }
}

public OnSkillLevelChanged(client,race,skill,newskilllevel)
{
    
    if(race==thisRaceID && War3_GetRace(client)==thisRaceID)
    {
        if(skill==SKILL_AURA)
        {
            W3SetAuraFromPlayer(AuraID,client,newskilllevel>0?true:false,newskilllevel);
        }
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




/***************************************************************************
*
*
*                ABILITY / ULTI FUNCTIONS
*
*
***************************************************************************/

public OnAbilityCommand(client,ability,bool:pressed)
{
    if(War3_GetRace(client)==thisRaceID && pressed && ValidPlayer(client,true) && ability==0 )
    {
        new skill_level=War3_GetSkillLevel(client,thisRaceID,SKILL_RAGE);
        if(skill_level>0&&War3_SkillNotInCooldown(client,thisRaceID,SKILL_RAGE,true))
        {
                War3_SetBuff( client, fDamageModifier, thisRaceID, 1.0 );
                War3_SetBuff( client, iGlowRed, thisRaceID, true  );  
                PrintToChat(client, "Your RAGE causes 2x damage!");
                W3FlashScreen( client, RGBA_COLOR_RED, 0.1 , 0.5, FFADE_OUT);              
                
                timer_handle[client] = CreateTimer( g_fRageDuration[skill_level], StopRage, client );
                new Float:temptimer = 30.0 + g_fRageDuration[skill_level];
                War3_CooldownMGR(client,temptimer,thisRaceID,SKILL_RAGE,_,_);
        }
    }
}           



public OnUltimateCommand(client,race,bool:pressed)
{
    if( race == thisRaceID && pressed  && ValidPlayer(client,true) && !Silenced(client))
    {
        new ult_level = War3_GetSkillLevel( client, thisRaceID, ULT_WARRIOR );
        if(ult_level>0)
        {
                if(War3_SkillNotInCooldown(client,thisRaceID, ULT_WARRIOR,true))
                {

                    decl Float:fClientPos[3];
                    GetClientAbsOrigin(client, fClientPos);
        
                    War3_SuicideBomber(client, fClientPos, SuicideBomberDamage[ult_level], ULT_WARRIOR, SuicideBomberRadius[ult_level]);
                    ForcePlayerSuicide(client);
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
        GivePlayerItem( client, "weapon_fiveseven" );
        GivePlayerItem( client, "weapon_m3" );
    }
}

public Action:StopRage( Handle:timer, any:client )
{
    new race = War3_GetRace( client );
    if( ValidPlayer( client ) && race == thisRaceID )
    {
        W3FlashScreen( client, RGBA_COLOR_GREEN, 0.1 , 0.5, FFADE_OUT);              
        War3_SetBuff( client, fDamageModifier, thisRaceID, 0.0 );
        War3_SetBuff( client, iGlowRed, thisRaceID, false  );  
        PrintToChat(client, "You COOL down, back to normal damage.");
        timer_handle[client] = INVALID_HANDLE;
    }
}


public OnW3PlayerAuraStateChanged(client,aura,bool:inAura,level)
{
    if(aura==AuraID)
    {
        War3_SetBuff(client,fHPRegen,thisRaceID,inAura?g_fHealingWaveAmountArr[level]:0.0);
    }
}


public RoundOverEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    for (new i = 1; i <= MaxClients; i++)
    {
        if(ValidPlayer(i) && timer_handle[i] != INVALID_HANDLE)
        {
            KillTimer(timer_handle[i]);
            timer_handle[i] = INVALID_HANDLE;
        }
    }
}
