/**
* File: War3Source_999_Tony.sp
* Description: Blue Tooth Tony Race for War3Source
* Author(s): Remy Lebeau
*/

// War3Source stuff
#pragma semicolon 1
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

new thisRaceID;
new SKILL_SPEED, SKILL_BASH, SKILL_HEALTH, ULT_INVIS;



public Plugin:myinfo = 
{
    name = "War3Source Race - Blue Tooth Tony",
    author = "Remy Lebeau",
    description = "Avenga's private race for War3Source",
    version = "1.1",
    url = "http://sevensinsgaming.com"
};




new Float:g_fSpeed[] = {1.0, 1.06, 1.12, 1.18, 1.24, 1.3};
new Float:g_fUltDuration[6] = { 0.0, 0.5, 1.0, 1.5, 2.0, 2.5 };
new Float:g_fUltCooldown[6] = { 0.0, 25.0, 24.0, 23.0, 22.0, 20.0 };
new g_iHealth[6] = {0, 10, 20, 30, 40, 50};
//new Float:g_fFrostDuration[] = {0.0, 0.5, 1.0, 1.5, 2.0, 2.5};
new Float:g_fBashChance[5]={0.0,0.10,0.15,0.25,0.30};



public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("Blue Tooth Tony [PRIVATE]","tony");
    
    SKILL_SPEED=War3_AddRaceSkill(thisRaceID,"Avi, Pull your socks up","Increased speed",false,5);
    SKILL_BASH=War3_AddRaceSkill(thisRaceID,"Righteous infliction of retribution manifested by an appropriate agent","Slow down enemies on hit",false,5);
    SKILL_HEALTH=War3_AddRaceSkill(thisRaceID,"Muhammad 'I'm hard' Bruce Lee","Increased health",false,5);
    ULT_INVIS=War3_AddRaceSkill(thisRaceID,"16 Pigs","It's what it takes to make a body vanish in one sitting (+ultimate)",true,5);
    
    W3SkillCooldownOnSpawn(thisRaceID,ULT_INVIS,10.0,_);
    
    War3_CreateRaceEnd(thisRaceID);
    
    War3_AddSkillBuff(thisRaceID, SKILL_HEALTH, iAdditionalMaxHealth, g_iHealth);
    War3_AddSkillBuff(thisRaceID, SKILL_SPEED, fMaxSpeed, g_fSpeed);
    War3_AddSkillBuff(thisRaceID, SKILL_BASH, fBashChance, g_fBashChance);
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


public OnRaceChanged( client,oldrace,newrace )
{
    if( newrace == thisRaceID && ValidPlayer( client, true ))
    {
        War3_WeaponRestrictTo( client,thisRaceID, "weapon_knife,weapon_deagle");
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
        War3_WeaponRestrictTo( client,thisRaceID, "weapon_knife,weapon_deagle");
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



public OnUltimateCommand(client,race,bool:pressed)
{
    if( race == thisRaceID && pressed  && ValidPlayer(client,true) && !Silenced(client))
    {
        new ult_invis = War3_GetSkillLevel( client, thisRaceID, ULT_INVIS );
        if(ult_invis>0)
        {
                if(War3_SkillNotInCooldown(client,thisRaceID, ULT_INVIS,true)) //not in the 0.2 second delay when we check stuck via moving
                {
                    PrintHintText(client,"Disappear!");
                    W3FlashScreen(client,RGBA_COLOR_BLUE,1.0);
                    
                    War3_SetBuff( client, fInvisibilitySkill, thisRaceID, 0.0  );
                    War3_SetBuff( client, bDoNotInvisWeapon, thisRaceID, true);
                    CreateTimer(g_fUltDuration[ult_invis],RemoveInvis,client);
                
                    War3_CooldownMGR( client, g_fUltCooldown[ult_invis], thisRaceID, ULT_INVIS);
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
        GivePlayerItem( client, "weapon_deagle" );
        
    }
}

public Action:RemoveInvis(Handle:t,any:client)
{
    if(ValidPlayer(client))
    {
        War3_SetBuff( client, fInvisibilitySkill, thisRaceID, 1.0  );
        War3_SetBuff( client, bDoNotInvisWeapon, thisRaceID,false);
        PrintHintText(client,"Reappear.");
        W3FlashScreen(client,RGBA_COLOR_GREEN, 1.0);
    }
}