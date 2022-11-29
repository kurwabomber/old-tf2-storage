/**
* File: War3Source_surf_Health.sp
* Description: Race for war3surf
* Author(s): Remy Lebeau
*/

// War3Source stuff
#pragma semicolon 1
#include <sourcemod>
#include <smlib>
#include "W3SIncs/War3Source_Interface"

new thisRaceID;
new SKILL1, SKILL2, SKILL3, ULT;

#define WEAPON_RESTRICT "weapon_knife,weapon_deagle"
#define WEAPON_GIVE "weapon_deagle"

public Plugin:myinfo = 
{
    name = "War3Source Race - Hulk",
    author = "Remy Lebeau",
    description = "Health race for War3Surf",
    version = "1.0",
    url = "http://sevensinsgaming.com"
};

new g_iHealth[]={0,25,50,75,100,125};




public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("The Hulk [SURF]","surf_health");
    
    SKILL1=War3_AddRaceSkill(thisRaceID,"Health","Health",false,5);
    SKILL2=War3_AddRaceSkill(thisRaceID,"Pointless","Just here to make up levels...",false,5);
    SKILL3=War3_AddRaceSkill(thisRaceID,"Pointless2","Just here to make up levels...",false,5);
    ULT=War3_AddRaceSkill(thisRaceID,"Pointless3","Just here to make up levels...",true,5);
    
    War3_CreateRaceEnd(thisRaceID);
    

    War3_AddSkillBuff(thisRaceID, SKILL1, iAdditionalMaxHealth, g_iHealth);

    
}



public OnPluginStart()
{

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
