/*
* War3Source Race - Skills Tester
* 
* File: War3Source_999_SkillsTester.sp
* Description: The Skills Tester race for War3Source. (USAGE: TESTS ONLY !!!)
* Author: M.A.C.A.B.R.A 
*/
#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/fakenpc"
#include "W3SIncs/War3Source_Interface"
#include <cstrike>

public Plugin:myinfo = 
{
	name = "War3Source Race - Skills Tester",
	author = "M.A.C.A.B.R.A",
	description = "The Skills Tester race for War3Source. (USAGE: TESTS ONLY !!!)",
	version = "0.2.0 ",
	url = "http://strefagier.com.pl/",
};

new thisRaceID;
new SKILL_HP, SKILL_PASSIVES, SKILL_ABILITY, SKILL_INVIS, ULT_ULTI;
new bool:InvisToggle[MAXPLAYERS];

public OnPluginStart()
{
	
	
	RegConsoleCmd("invisme",War3Source_InvisToggle,"Toggle between 100% and 0% visibility.");
	RegConsoleCmd("say invisme",War3Source_InvisToggle,"Toggle between 100% and 0% visibility.");
	RegConsoleCmd("say_team invisme",War3Source_InvisToggle,"Toggle between 100% and 0% visibility.");
	
}

public Action:War3Source_InvisToggle(client, args)
{
	
	if(War3_GetRace(client)==thisRaceID && ValidPlayer(client, true))
	{
		if(War3_GetSkillLevel(client,thisRaceID,SKILL_INVIS)>0)
		{
			if (InvisToggle[client] == false)
			{
				InvisToggle[client] = true;
				PrintToChat(client, "You go invisible.  Use your power wisely!");
				War3_SetBuff(client,bDoNotInvisWeapon,thisRaceID,false);
				War3_SetBuff( client, fInvisibilitySkill, thisRaceID, 0.0  );
				
			}
			else 
			{
				InvisToggle[client] = false;
				PrintToChat(client, "You become visible once more.");
				War3_SetBuff(client,bDoNotInvisWeapon,thisRaceID,true);
				War3_SetBuff( client, fInvisibilitySkill, thisRaceID, 1.0  );
				
			}
		}
	}
	return Plugin_Handled;
}


/* *********************** OnWar3PluginReady *********************** */
public OnWar3PluginReady(){
	thisRaceID=War3_CreateNewRace("Skills Tester [REMY TEST RACE]","skillstester");
	
	SKILL_HP=War3_AddRaceSkill(thisRaceID,"Indestructible","Can't stop me.",false,2);
	SKILL_PASSIVES=War3_AddRaceSkill(thisRaceID,"Passive Skills","Get anywhere - fast.",false,2);
	SKILL_INVIS=War3_AddRaceSkill(thisRaceID,"Inivisbility Toggle","Move like a ghost.",false,2);
	SKILL_ABILITY=War3_AddRaceSkill(thisRaceID,"Abilities Spam","Activates your targets abilities (+ability0/1/2/3)",false,2);
	ULT_ULTI=War3_AddRaceSkill(thisRaceID,"Ultimate Spam","Activates your targets ultimates (+ultimate)",true,1);

	War3_CreateRaceEnd(thisRaceID);
}

/* *********************** OnWar3EventSpawn *********************** */
public OnWar3EventSpawn(client)
{
	new race = War3_GetRace( client );
	if( race == thisRaceID )
	{	
		if(War3_GetSkillLevel(client,thisRaceID,SKILL_PASSIVES)>0)
		{
			War3_SetBuff(client,fLowGravitySkill,thisRaceID,0.5);
			War3_SetBuff(client,fMaxSpeed,thisRaceID,2.0);
		}
		if(War3_GetSkillLevel(client,thisRaceID,SKILL_HP)>0)
		{
			War3_SetBuff(client,iAdditionalMaxHealth,thisRaceID, 100000);
		
		}
	}
}

/* *********************** OnRaceChanged *********************** */
public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace!=thisRaceID)
	{

		W3ResetAllBuffRace(client, thisRaceID);
	}
	
}


public Action:forceChangeRace( Handle:timer, any:client )
{
	War3_SetRace( client, War3_GetRaceIDByShortname( "undead" ) );
	PrintHintText( client, "Race is restricted to Race Developers." );
}


/* *************************************** Abilities Spammer *************************************** */
/* *********************** OnAbilityCommand *********************** */
public OnAbilityCommand(client,ability,bool:pressed)
{
	if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && IsPlayerAlive(client))
	{
		if(War3_GetSkillLevel(client,thisRaceID,SKILL_ABILITY)>0)
		{
			if(!Silenced(client))
			{
				new target=War3_GetTargetInViewCone(client,99999.9,true);
				if(ValidPlayer(target,true))
				{
					FakeClientCommandEx( target, "+ability" );
					FakeClientCommandEx( target, "+jump" );
				}
				else
				{
					PrintHintText(client, "No Target Found");
				}
			}
		}
		else
		{
			PrintHintText(client, "Level your Abilities Spam first");
		}
	}
	if(War3_GetRace(client)==thisRaceID && ability==1 && pressed && IsPlayerAlive(client))
	{
		if(War3_GetSkillLevel(client,thisRaceID,SKILL_ABILITY)>0)
		{
			if(!Silenced(client))
			{
				new target=War3_GetTargetInViewCone(client,99999.9,true);
				if(ValidPlayer(target,true))
				{
					FakeClientCommand( target, "+ability1" );
					FakeClientCommandEx( target, "+jump" );
				}
				else
				{
					PrintHintText(client, "No Target Found");
				}
			}
		}
		else
		{
			PrintHintText(client, "Level your Abilities Spam first");
		}
	}
	if(War3_GetRace(client)==thisRaceID && ability==2 && pressed && IsPlayerAlive(client))
	{
		if(War3_GetSkillLevel(client,thisRaceID,SKILL_ABILITY)>0)
		{
			if(!Silenced(client))
			{
				new target=War3_GetTargetInViewCone(client,99999.9,true);
				if(ValidPlayer(target,true))
				{
					FakeClientCommand( target, "+ability2" );
					FakeClientCommandEx( target, "+jump" );
				}
				else
				{
					PrintHintText(client, "No Target Found");
				}
			}
		}
		else
		{
			PrintHintText(client, "Level your Abilities Spam first");
		}
	}
	if(War3_GetRace(client)==thisRaceID && ability==3 && pressed && IsPlayerAlive(client))
	{
		if(War3_GetSkillLevel(client,thisRaceID,SKILL_ABILITY)>0)
		{
			if(!Silenced(client))
			{
				new target=War3_GetTargetInViewCone(client,99999.9,true);
				if(ValidPlayer(target,true))
				{
					FakeClientCommand( target, "+ability3" );
					FakeClientCommandEx( target, "+jump" );
				}
				else
				{
					PrintHintText(client, "No Target Found");
				}
			}
		}
		else
		{
			PrintHintText(client, "Level your Abilities Spam first");
		}
	}
}


/* *************************************** Ultimate Spam *************************************** */
/* *********************** OnUltimateCommand *********************** */
public OnUltimateCommand(client,race,bool:pressed)
{
	if(race==thisRaceID && pressed && ValidPlayer(client,true))
	{
		new skill_ult = War3_GetSkillLevel(client,thisRaceID,ULT_ULTI);
		if(skill_ult > 0)
		{
		
				new target=War3_GetTargetInViewCone(client,99999.9,true);
				if(ValidPlayer(target,true))
				{
					FakeClientCommand( target, "+ultimate" );
					FakeClientCommandEx( target, "+jump" );
				}
				else
				{
					PrintHintText(client, "No Target Found");
				}
			
		}
		else
		{
			PrintHintText(client, "Level your Ultimate Spam first");
		}
	}
}