/**
* File: War3Source_888_Remy.sp
* Description: Remys test race.
* Author(s): Remy Lebeau
*/
 
#pragma semicolon 1
 
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdkhooks>

new thisRaceID;

public Plugin:myinfo = 
{
	name = "War3Source Race - Remy",
	author = "Remy Lebeau",
	description = "A race Remy uses to test individual parameters for War3Source.",
	version = "0.0.0.1 (Testing iAdditionalMaxHealthNoHPChange)",
	url = "http://sevensinsgaming.com/"
};

new SKILL_HEALINGWAVE, SKILL_MAXHPHEAL, SKILL_MAXHPNOHEAL, SKILL_RESET, SKILL_HPTO1;

//skill 1
new Float:HealingWaveAmountArr[]={0.0,1.0,2.0,3.0,150.0};
new Float:HealingWaveDistance=500.0;
new AuraID;
new bsmaximumHP = 500;



public OnWar3PluginReady()
{

		thisRaceID=War3_CreateNewRace("Remys Test Race", "remy");
		SKILL_HEALINGWAVE=War3_AddRaceSkill(thisRaceID,"HealingWave","Heals all around you (watch the bump at max level!)", false, 4); 
		SKILL_MAXHPHEAL=War3_AddRaceSkill(thisRaceID,"MaxHpHeal","Sets the players max HP using iAdditionalMaxHealth (+ability)", false, 1); 
		SKILL_MAXHPNOHEAL=War3_AddRaceSkill(thisRaceID,"MaxHpNoHeal","Sets the players max HP using iAdditionalMaxHealthNoHPChange (+ability1)", false, 1);
		SKILL_HPTO1=War3_AddRaceSkill(thisRaceID,"HpTo1","Sets the players max HP to 1 using iAdditionalMaxHealth -99 (+ability2)", false, 1);
		SKILL_RESET=War3_AddRaceSkill(thisRaceID,"ResetSkills","Resets all buffs on the player", true, 1);
		War3_CreateRaceEnd(thisRaceID);
		AuraID=W3RegisterAura("remy_healwave",HealingWaveDistance);
}

public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace==thisRaceID)
	{
		new String:SteamID[64];
		GetClientAuthString( client, SteamID, 64 );
		if( !StrEqual( "STEAM_0:1:343653", SteamID ) )
		{
				CreateTimer( 0.5, ForceChangeRace, client );
		}
		else
		{
			new level=War3_GetSkillLevel(client,thisRaceID,SKILL_HEALINGWAVE);
			W3SetAuraFromPlayer(AuraID,client,level>0?true:false,level);
		}
	}

	else
	{
		//PrintToServer("deactivate aura");
		W3SetAuraFromPlayer(AuraID,client,false);
		W3ResetAllBuffRace( client, thisRaceID );
	}
}

public Action:ForceChangeRace( Handle:timer, any:client )
{
	War3_SetRace( client, War3_GetRaceIDByShortname( "Access Denied" ) );
	PrintHintText( client, "Race is restricted to Remy" );
}



public OnSkillLevelChanged(client,race,skill,newskilllevel)
{
	
	if(race==thisRaceID && War3_GetRace(client)==thisRaceID)
	{
		if(skill==SKILL_HEALINGWAVE) //1
		{
			W3SetAuraFromPlayer(AuraID,client,newskilllevel>0?true:false,newskilllevel);
		}
	}
}

public OnW3PlayerAuraStateChanged(client,aura,bool:inAura,level)
{
	if(aura==AuraID)
	{
		War3_SetBuff(client,fHPRegen,thisRaceID,inAura?HealingWaveAmountArr[level]:0.0);
	}
}

public OnWar3EventSpawn(client){
	if(War3_GetRace(client)==thisRaceID)
	{
		War3_SetBuff(client,iAdditionalMaxHealthNoHPChange,thisRaceID,100);
		PrintHintText( client, "Spawning.  iAdditionalMaxHealthNoHPChange is %d.  It has set your maxHP to: |%d|", iAdditionalMaxHealthNoHPChange, War3_GetMaxHP( client ) );
	}
}
/*
public OnAbilityCommand(client,ability,bool:pressed)
{
	if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && IsPlayerAlive(client) && !Silenced( client ))
	{
		War3_SetBuff(client,iAdditionalMaxHealth,thisRaceID,bsmaximumHP);	
		PrintHintText( client, "You have pressed ability |%d| (HEAL).  It has set your maxHP to: |%d|", ability, War3_GetMaxHP( client ) );
		
	}
	if(War3_GetRace(client)==thisRaceID && ability==1 && pressed && IsPlayerAlive(client) && !Silenced( client ))
	{
		War3_SetBuff(client,iAdditionalMaxHealthNoHPChange,thisRaceID,bsmaximumHP);	
		PrintHintText( client, "You have pressed ability |%d| (NOHEAL).  It has set your maxHP to: |%d|", ability, War3_GetMaxHP( client ) );
	}
	if(War3_GetRace(client)==thisRaceID && ability==2 && pressed && IsPlayerAlive(client) && !Silenced( client ))
	{
		War3_SetBuff(client,iAdditionalMaxHealth,thisRaceID, -99);	
		PrintHintText( client, "You have pressed ability |%d|.  It has set your maxHP to: |%d|", ability, War3_GetMaxHP( client ) );
	}
	
}	

public OnUltimateCommand(client,race,bool:pressed)
{
	new userid=GetClientUserId(client);
	if(race==thisRaceID && pressed && userid>1 && IsPlayerAlive(client) && !Silenced( client ))
	{
		W3ResetAllBuffRace( client, thisRaceID );
		PrintHintText( client, "You have pressed ultimate.  It has reset all buffs. Your maxHP is: |%d|", War3_GetMaxHP( client ) );
	}
}

*/