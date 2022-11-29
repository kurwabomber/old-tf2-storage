/**
* File: War3Source_999_Yoshimitsu.sp
* Description: Yoshimitsu Race for War3Source
* Author(s): Remy Lebeau
*/

// War3Source stuff
#pragma semicolon 1
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"


new thisRaceID;
new SKILL_WINDMILL, SKILL_DAMAGE, SKILL_HARAKIRI, ULT_RESPAWN;

public Plugin:myinfo = 
{
	name = "War3Source Race - Yoshimitsu",
	author = "Remy Lebeau",
	description = "Yoshimitsu race for War3Source",
	version = "1.2.0",
	url = "http://sevensinsgaming.com"
};

new m_vecBaseVelocity, m_vecVelocity_0, m_vecVelocity_1;
new Float:ElectricGravity[5] = { 1.0, 0.92, 0.84, 0.76, 0.68 };
new Float:JumpMultiplier[5] = { 1.0, 3.1, 3.2, 3.3, 3.4 };
new Float:g_fDamageBonus = 0.2;

new Float:ult_cooldown=15.0;
new playerkills[MAXPLAYERS];

new g_iHarakiriHealth[] = { 20, 10, 0, -10, -20 };
new g_iHarakiriDamage[] = { 0, 20, 30, 40, 55 };

new Float:ult_delay[]={ 0.0 ,6.5 ,5.0 ,3.5 ,1.95 };

new bool:fireonce[MAXPLAYERS];

new BeamSprite, HaloSprite;

public OnWar3PluginReady()
{
	thisRaceID=War3_CreateNewRace("Yoshimitsu","yoshimitsu");
	
	SKILL_WINDMILL=War3_AddRaceSkill(thisRaceID,"Windmill","Use your mechanical arm to fly.",false,4);
	SKILL_DAMAGE=War3_AddRaceSkill(thisRaceID,"Soul Edge","Blood awakens the demon within (gain power per kill)",false,4);
	SKILL_HARAKIRI=War3_AddRaceSkill(thisRaceID,"Harakiri","Add your own blood to the sword for extra power",false,4);
	ULT_RESPAWN=War3_AddRaceSkill(thisRaceID,"Manji Ninjitsu","Teleport yourself back to spawn fully healed (+ultimate)",true,4);
	

	W3SkillCooldownOnSpawn( thisRaceID, ULT_RESPAWN, ult_cooldown, false);
	
	War3_CreateRaceEnd(thisRaceID);
}






public OnWar3EventPostHurt(victim, attacker, dmg)
{
        if(ValidPlayer(victim) && ValidPlayer(attacker) && victim != attacker)
        {
                
                	PrintToChat(attacker, "actual damage: |%d|",dmg);
                	PrintToChat(attacker, "war3damage damage: |%d|",War3_GetWar3DamageDealt());
					
					W3FlashScreen(victim, RGBA_COLOR_RED);
                
        }
}


/***************************************************************************
*
*
*				ABILITY / ULTI FUNCTIONS
*
*
***************************************************************************/




/***************************************************************************
*
*
*				EVENT CONTROL FUNCTIONS
*
*
***************************************************************************/






/***************************************************************************
*
*
*				HELPER FUNCTIONS / TIMERS
*
*
***************************************************************************/

