/**
* File: War3source_Panda_PrivateRace
* Description: My first race.
* Author(s): Panda Dodger.
*/

#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdkhooks>
#include <sdktools>
#include <sdktools_functions>
#include <sdktools_tempents>
#include <sdktools_tempents_stocks>
#include <sdktools_sound>

new thisRaceID;
new SKILL_LOL, SKILL_FLASH;

new Float:DamageMultiplier[5] = { 1.0, 1.05, 1.075, 1.08, 1.10 };
new Float:FlashSpeed[5] = { 1.0, 1.05, 1.075, 1.10, 1.25 };

new HaloSprite, BeamSprite;

public Plugin:myinfo =
{
   name = "panda",
   author = "Panda Dodger",
   description = "A retard that is on fire.",
   version = "0.1",
   url = "www.sevensinsgaming.com",
};

public OnMapStart()
{
	HaloSprite = PrecacheModel( "materials/sprites/halo01.vmt" );
	BeamSprite = PrecacheModel( "materials/sprites/laser.vmt" );
}

public OnWar3PluginReady()
{
	thisRaceID=War3_CreateNewRace("Panda_alpha_test","panda");
	SKILL_LOL=War3_AddRaceSkill(thisRaceID,"LOL", "Makes you do 5-10% more damage.", false);
	SKILL_FLASH=War3_AddRaceSkill(thisRaceID,"FLASH", "Makes you run faster.", false);
	War3_CreateRaceEnd(thisRaceID);
}

public OnSkillLevelChanged(client,race,skill,newskilllevel)
{
	InitPassiveSkills(client);
}
public InitPassiveSkills(client){
	if(War3_GetRace(client)==thisRaceID)
	{
		new skilllevel_FlashSpeed=War3_GetSkillLevel(client,thisRaceID,SKILL_FLASH);
		new Float:speed=FlashSpeed[skilllevel_FlashSpeed];
		War3_SetBuff(client,fMaxSpeed,thisRaceID,speed);
		
		new skilllevel_DamageMultiplier=War3_GetSkillLevel(client,thisRaceID,SKILL_FLASH);
		new Float:percent=DamageMultiplier[skilllevel_DamageMultiplier];
		War3_SetBuff(client,fDamageModifier,thisRaceID,percent);
	}
}

public OnWar3EventPostHurt( victim, attacker, damage )
{
	{	
		new Float:attacker_pos[3];
		new Float:victim_pos[3];
		
		GetClientAbsOrigin( attacker, attacker_pos );
		GetClientAbsOrigin( victim, victim_pos );
		
		attacker_pos[2] += 40;
		victim_pos[2] += 40;
		
		TE_SetupBeamPoints( attacker_pos, victim_pos, BeamSprite, HaloSprite, 0, 0, 1.0, 5.0, 5.0, 0, 0.0, { 0, 0, 255, 255 }, 0 );
		TE_SendToAll();
	}
}