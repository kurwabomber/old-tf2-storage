/**
* File: War3Source_LavaSpawn.sp
* Description: Lava Spawn race of warcraft.
* Author: Lucky 
*/
 
#pragma semicolon 1
 
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdktools_functions>
#include <sdktools_tempents>
#include <sdktools_tempents_stocks>
#include <sdkhooks>

new thisRaceID;

//Lava Spawn
new SpawnHealth[]={0,10,20,30,40,50,60,70};

//Burning Aura
new AuraDam[]={0,1,2,3,4,5,6,7};
new BurnSprite;

//Burning Touch
new Float:BurnTime[]={0.0,0.5,1.0,1.5,2.0,2.5,3.0,3.5};

//Lava Shell



//Skills & Ultimate
new SKILL_SPAWN, SKILL_HEATH, SKILL_BURN, SKILL_SHELL;

public Plugin:myinfo = 
{
	name = "War3Source Race - Lava Spawn",
	author = "Lucky",
	description = "Lava Spawn race of warcraft",
	version = "1.0.1",
	url = ""
}

public OnPluginStart()
{
	CreateTimer(1.0,Aura,_,TIMER_REPEAT);	
	CreateTimer(1.0,Deminish,_,TIMER_REPEAT);
	CreateTimer(0.1,heataoe,_,TIMER_REPEAT);
}

public OnMapStart()
{
	BurnSprite=PrecacheModel("materials/sprites/fire1.vmt");
}

public OnWar3PluginReady()
{
	
		thisRaceID=War3_CreateNewRace("LavaSpawn", "lavaspw");
		SKILL_SPAWN=War3_AddRaceSkill(thisRaceID,"Lava Spawn (passive)", "Become a stronger Lava Spawn",false,7);
		SKILL_HEATH=War3_AddRaceSkill(thisRaceID,"Burning Aura (passive)","People close to you take damage",false,7);
		SKILL_BURN=War3_AddRaceSkill(thisRaceID,"Burning Touch (attack)","You will burn your enemies",false,7);
		SKILL_SHELL=War3_AddRaceSkill(thisRaceID,"Lava Shell (passive)","You become immune to slow",false,1);
		War3_CreateRaceEnd(thisRaceID);
	
}

public OnRaceChanged ( client,oldrace,newrace )
{
	if(newrace != thisRaceID){
		War3_WeaponRestrictTo(client,thisRaceID,"");
		W3ResetAllBuffRace(client,thisRaceID);
	}
	
	if(newrace == thisRaceID){
		War3_WeaponRestrictTo(client, thisRaceID,"weapon_knife");
		
		if(ValidPlayer(client,true)){
			GivePlayerItem(client, "weapon_knife");
		}
	}
	
}

public OnWar3EventSpawn(client)
{	
	if(War3_GetRace(client)==thisRaceID){
		War3_SetBuff(client,fMaxSpeed,thisRaceID,1.2);
		
		new skill_spawn=War3_GetSkillLevel(client,thisRaceID,SKILL_SPAWN);
		new skill_shell=War3_GetSkillLevel(client,thisRaceID,SKILL_SHELL);
		
		if(skill_spawn){
			War3_SetBuff(client, iAdditionalMaxHealth, thisRaceID, SpawnHealth[skill_spawn]);
			//War3_SetMaxHP(client,100+SpawnHealth[skill_spawn]);
			//SetEntityHealth(client,100+SpawnHealth[skill_spawn]);
		}
		
		if(skill_shell==1){
			War3_SetBuff(client,bSlowImmunity,thisRaceID,true);
		}
	}
}

public OnW3TakeDmgBullet(victim,attacker,Float:damage)
{
	if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim){
		new vteam=GetClientTeam(victim);
		new ateam=GetClientTeam(attacker);
		
		if(vteam!=ateam){
			new race_attacker=War3_GetRace(attacker);
			
			if(race_attacker==thisRaceID){
				new skill_burn=War3_GetSkillLevel(attacker,thisRaceID,SKILL_BURN);
			
				if(skill_burn){
					IgniteEntity(victim, BurnTime[skill_burn]);
				}
			}
		}
	}
}

public OnWar3EventDeath(victim,attacker)
{
	new race_attacker=War3_GetRace(attacker);
	if(race_attacker==thisRaceID){
		War3_HealToMaxHP(attacker,25);
	}
}

public Action:Deminish(Handle:timer,any:userid)
{
	for(new client=1;client<=MaxClients;client++){
		if(ValidPlayer(client,true)){
			if(War3_GetRace(client)==thisRaceID){
				War3_DecreaseHP(client,1);
			}
		}
	}
}

public Action:heataoe(Handle:timer,any:a){
	for(new i=0;i<=MaxClients;i++){
		if(ValidPlayer(i,true) &&War3_GetRace(i)==thisRaceID){
			new skill_heath=War3_GetSkillLevel(i,thisRaceID,SKILL_HEATH);
			if(skill_heath>0){
				new Float:positioni[3];
				War3_CachedPosition(i,positioni);
				TE_SetupGlowSprite(positioni,BurnSprite,0.4,1.9,255);
				TE_SendToAll();
			}
		}
	}
}

public Action:Aura(Handle:timer,any:userid)
{
	for(new client=1;client<=MaxClients;client++){
		if(ValidPlayer(client,true)){
			if(War3_GetRace(client)==thisRaceID){
				new skill_heath=War3_GetSkillLevel(client,thisRaceID,SKILL_HEATH);
				new ownerteam=GetClientTeam(client);
				new Float:targetPos[3];
				new Float:clientPos[3];
				GetClientAbsOrigin(client,clientPos);
				if(skill_heath>0){							
					for (new target=1;target<=MaxClients;target++){
						if(ValidPlayer(target,true)&& GetClientTeam(target)!=ownerteam){
							GetClientAbsOrigin(target,targetPos);
							if(GetVectorDistance(clientPos,targetPos)<200.0){
								if(!W3HasImmunity(target,Immunity_Skills)){
									War3_DealDamage(target,AuraDam[skill_heath],client,DMG_BULLET,"Burning Aura");
								}
							}
						}
					}
				}
			}
		}
	}
}

