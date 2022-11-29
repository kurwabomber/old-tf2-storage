/**
* File: War3Source_Archer.sp
* Description: The Night Elf Archer for War3Source.
* Author(s): TeacherCreature
*/

#pragma semicolon 1
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdkhooks>

public Plugin:myinfo = 
{
	name = "War3Source Race - Archer",
	author = "[Oddity]TeacherCreature",
	description = "The Night Elf Archer for War3Source.",
	version = "1.0.9.1",
	url = "http://warcraft-source.net/"
}

new thisRaceID;

//Shadowmeld
new Float:Shadow[]={1.0, 0.6, 0.58, 0.55, 0.52, 0.49, 0.46, 0.43, 0.4};

//Elune's Grace
//new Float:DmgRed[]={1.0, 0.86, 0.83, 0.80, 0.77, 0.74, 0.71, 0.68, 0.65};

//Improved Bow
new Float:ChanceArr[]={0.0, 0.1, 0.12 ,0.14, 0.16, 0.18, 0.2, 0.22, 0.25};
new hasImprovedBow[MAXPLAYERS+1];

//Marksmanship
new Float:ScoutDmgArr[]={0.0, 0.45, 0.5, 0.55, 0.6, 0.65, 0.7, 0.75, 0.8};
new Float:AutoDmgArr[]={0.0, 0.2, 0.23, 0.26, 0.29, 0.32, 0.35, 0.38, 0.4};

//Hide
new Float:Duration[]={1.0, 2.0, 2.2, 2.4, 2.6, 2.8, 3.0, 3.2, 3.5};

//SKILLS and ULTIMATE
new SHADOWMELD, IMPROVEDBOW, MARKSMANSHIP, HIDE;
//new ELUNE;

public OnWar3PluginReady()
{
	thisRaceID=War3_CreateNewRace("Archer","archer");
	SHADOWMELD=War3_AddRaceSkill(thisRaceID,"Shadowmeld (Passive)","Invisibility",false,8);
//	ELUNE=War3_AddRaceSkill(thisRaceID,"Elune's Grace (Victim)","Reduced Damage",false,8);
	IMPROVEDBOW=War3_AddRaceSkill(thisRaceID,"Improved Bow (Passive)","Improved weapon",false,8);
	MARKSMANSHIP=War3_AddRaceSkill(thisRaceID,"Marksmanship (Attacker)","Improved Damage",false,8);
	HIDE=War3_AddRaceSkill(thisRaceID,"Hide","100% invisibility",true,8);		
	War3_CreateRaceEnd(thisRaceID);
}

public OnMapChanged()
{
	for (new i=0; i<=MAXPLAYERS; i++)
	{
		hasImprovedBow[i] = false;
	}
}

public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace!=thisRaceID){
		War3_WeaponRestrictTo(client,thisRaceID,"");
		War3_SetBuff(client,fInvisibilitySkill,thisRaceID,1.0);
	}
	if(newrace==thisRaceID){
		War3_WeaponRestrictTo(client,thisRaceID,"weapon_scout,weapon_smokegrenade");
		if(ValidPlayer(client,true)){
			InitPassive(client);
		}
	}
}

public OnWar3EventSpawn(client)
{
	if (War3_GetRace(client)==thisRaceID&&ValidPlayer(client,true)){
		InitPassive(client);
	}
}

public Action:smoke(Handle:timer,any:client)
{
	if(ValidPlayer(client,true)){
		GivePlayerItem(client, "weapon_smokegrenade");
	}
}

public Action:sg550(Handle:timer,any:client)
{
	if(ValidPlayer(client,true)){
		GivePlayerItem(client, "weapon_sg550");
		hasImprovedBow[client] = true;
		CreateTimer(1.0,smoke,client);
	}
}

public Action:scout(Handle:timer,any:client)
{
	if(ValidPlayer(client,true)){
		GivePlayerItem(client, "weapon_scout");
		CreateTimer(1.0,smoke,client);
	}
}

public InitPassive(client)
{
	if(War3_GetRace(client)==thisRaceID){
	
		new skill=War3_GetSkillLevel(client,thisRaceID,IMPROVEDBOW);
		hasImprovedBow[client] = false;
		
		if(GetRandomFloat(0.0,1.0)<ChanceArr[skill]){
			War3_WeaponRestrictTo(client,thisRaceID,"weapon_sg550,weapon_smokegrenade");
			CreateTimer(1.0,sg550,client);
		}
		else
		{
			War3_WeaponRestrictTo(client,thisRaceID,"weapon_scout,weapon_smokegrenade");
			CreateTimer(1.0,scout,client);
		}
		new skill_level=War3_GetSkillLevel(client,thisRaceID,SHADOWMELD);
		
		War3_SetBuff(client,fInvisibilitySkill,thisRaceID,Shadow[skill_level]);
	}
}

public OnW3TakeDmgBullet(victim,attacker,Float:damage)
{
	if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim){
		new vteam=GetClientTeam(victim);
		new ateam=GetClientTeam(attacker);
		if(vteam!=ateam){
			new race_attacker=War3_GetRace(attacker);
			new mlevel=War3_GetSkillLevel(attacker,thisRaceID,MARKSMANSHIP);
			if(race_attacker==thisRaceID){
				if(!Hexed(attacker)){
					if(mlevel>0){
						new Float:modifier = ScoutDmgArr[mlevel];
						if (hasImprovedBow[attacker])
						{
							modifier = AutoDmgArr[mlevel];
						}
						War3_DealDamage( victim, RoundToFloor( damage * modifier ), attacker, DMG_BULLET, "Marksmanship" );
					}
				}
			}
		}
	}
}
/*
public OnW3TakeDmgBulletPre(victim,attacker,Float:damage)
{
	if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim)
	{
		new vteam=GetClientTeam(victim);
		new ateam=GetClientTeam(attacker);
		if(vteam!=ateam)
		{
			new race_victim=War3_GetRace(victim);
			new elevel=War3_GetSkillLevel(victim,thisRaceID,ELUNE);
			if(race_victim==thisRaceID){
				if(elevel>0){
					War3_DamageModPercent(DmgRed[elevel]);
					PrintToConsole(attacker, "Damage Reduced against Archer");
					PrintToConsole(victim, "Damage Reduced by Archer");
				}
			}

		}
	}

}
*/



public OnUltimateCommand(client,race,bool:pressed)
{
	if(race==thisRaceID && pressed && IsPlayerAlive(client)){
		if(!Silenced(client)){
			new ult_level=War3_GetSkillLevel(client,thisRaceID,HIDE);
			if(ult_level>0){
				if(War3_SkillNotInCooldown(client,thisRaceID,HIDE,true)){
					War3_SetBuff(client,fInvisibilitySkill,thisRaceID,0.0);
					War3_SetBuff(client,bInvisWeaponOverride,thisRaceID,true);
					War3_SetBuff(client,iInvisWeaponOverrideAmount,thisRaceID,128);
					War3_CooldownMGR(client,30.0,thisRaceID,HIDE);
					CreateTimer(Duration[ult_level],unhide,client);
					PrintHintText(client,"You hide in the shadows");
				}
			}
			else
			{
				PrintHintText(client,"Level Your Ultimate First");
			}
		}
		else
		{
			PrintHintText(client,"Silenced!");
		}
	}
}

public Action:unhide(Handle:timer,any:client)
{
	if(ValidPlayer(client,true)){
		new skill=War3_GetSkillLevel(client,thisRaceID,SHADOWMELD);
		War3_SetBuff(client,fInvisibilitySkill,thisRaceID,Shadow[skill]);
		War3_SetBuff(client,bInvisWeaponOverride,thisRaceID,false);
		PrintHintText(client,"you are no longer hidden");
	}
}