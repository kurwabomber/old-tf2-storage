/**
* File: War3Source_999_TestRace.sp
* Description: Test Race
* Author(s): Remy Lebeau
*/

#pragma semicolon 1
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

new thisRaceID;
new SKILL_TEST1;


public Plugin:myinfo = 
{
    name = "War3Source Race - Test Race",
    author = "Remy Lebeau",
    description = "Test Race for War3Source",
    version = "0.0.1",
    url = "http://sevensinsgaming.com"
};


new Float:g_fSpeedBonus[] = {1.0, 1.4, 1.5, 1.6, 1.7};



public OnWar3PluginReady()
{
    thisRaceID=War3_CreateNewRace("Test Race","testrace");
    
    SKILL_TEST1=War3_AddRaceSkill(thisRaceID,"Speed","Significantly increase speed.",false,4);
    
    War3_CreateRaceEnd(thisRaceID);
    
    War3_AddSkillBuff(thisRaceID, SKILL_TEST1, fMaxSpeed, g_fSpeedBonus);
}


