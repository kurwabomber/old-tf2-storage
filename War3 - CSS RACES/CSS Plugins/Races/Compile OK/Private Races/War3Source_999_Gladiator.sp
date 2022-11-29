/**
* File: War3Source_999_Gladiator.sp
* Description: Gladiator Race for War3Source
* Author(s): Remy Lebeau
*/

// War3Source stuff
#pragma semicolon 1
#include <sourcemod>
#include <smlib>
#include "W3SIncs/War3Source_Interface"

new thisRaceID;
new SKILL_LEECH, SKILL_DMG, SKILL_SPEED, SKILL_EVADE;

#define WEAPON_RESTRICT ""
#define WEAPON_GIVE ""

public Plugin:myinfo = 
{
    name = "War3Source Race - Gladiator",
    author = "Remy Lebeau",
    description = "Arrow's private race for War3Source",
    version = "0.0.1",
    url = "http://sevensinsgaming.com"
};


new Float:g_fSpeed[] = { 1.0, 1.05, 1.1, 1.15, 1.20 };
new Float:g_fEvadeChance[5]={0.0,0.05,0.1,0.13,0.15};
new Float:g_fBonusDamage[5]={0.0,0.05,0.10,0.15,0.20};
new Float:g_fVampirePercent[5]={0.0,0.05,0.1,0.15,0.20};

public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("Gladiator [PRIVATE]","gladiator");
    
    SKILL_LEECH=War3_AddRaceSkill(thisRaceID,"Leech","Heal yourself but leeching off enemies",false,4);
    SKILL_DMG=War3_AddRaceSkill(thisRaceID,"Explosives","Use explosive ammunition",false,4);
    SKILL_SPEED=War3_AddRaceSkill(thisRaceID,"Agility","Move with the wind",false,4);
    SKILL_EVADE=War3_AddRaceSkill(thisRaceID,"Camouflage","Disguise your self",false,4);

    
    War3_CreateRaceEnd(thisRaceID);
    
    War3_AddSkillBuff(thisRaceID, SKILL_SPEED, fMaxSpeed, g_fSpeed);
    War3_AddSkillBuff(thisRaceID, SKILL_EVADE, fDodgeChance, g_fEvadeChance);
    War3_AddSkillBuff(thisRaceID, SKILL_DMG, fDamageModifier, g_fBonusDamage);
    War3_AddSkillBuff(thisRaceID, SKILL_LEECH, fVampirePercent, g_fVampirePercent);
    
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


public OnRaceChanged( client,oldrace,newrace )
{
    if( newrace == thisRaceID && ValidPlayer( client, true ))
    {
      
    }
    else
    {
        W3ResetAllBuffRace( client, thisRaceID );
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
