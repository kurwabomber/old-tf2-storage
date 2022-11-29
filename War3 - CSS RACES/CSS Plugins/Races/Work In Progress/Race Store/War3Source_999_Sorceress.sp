/**
* File: War3Source_Sorceress.sp
* Description: Sorceress.
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

new String:invisibility[]="war3source/sorceress/invisibility.wav";
new String:polymorph[]="war3source/sorceress/polymorph.wav";
new String:slow[]="war3source/sorceress/slow.wav";


//Slow
new Float:SlowTime[6]={0.0,5.0,4.0,3.0,2.0,1.0};
new bool:bIsSlow[MAXPLAYERS];
//Training
//Invisibility
new Float:InvisTime[6]={0.0,5.0,6.0,7.0,8.0,9.0};
new bool:bIsVisible[MAXPLAYERS];
//Polymorph
new String:OldModel[MAXPLAYERS][256];
//new String:NewModel[MAXPLAYERS][256];
new bool:bIsPoly[MAXPLAYERS];
new Float:PolymorphTime[6]={0.0,2.0,3.0,4.0,5.0,6.0};

//Skills & Ultimate
new SKILL_SLOW, SKILL_TRAINING, SKILL_INVISIBILITY, ULT_POLYMORPH;
 
public Plugin:myinfo = 
{
	name = "War3Source Race - Sorceress",
	author = "Lucky",
	description = "Sorceress",
	version = "1.0.9.0",
	url = "http://warcraft-source.net"
}

public OnMapStart()
{
War3_PrecacheSound(polymorph);
War3_PrecacheSound(slow);
War3_PrecacheSound(invisibility);
}

public OnPluginStart()
{
	HookEvent("weapon_fire", WeaponFire);
}

public OnWar3PluginReady()
{
	
		thisRaceID=War3_CreateNewRace("Sorceress", "sorc");
		SKILL_SLOW=War3_AddRaceSkill(thisRaceID,"Slow(autocast)", "Slow down your enemies",false,5);
		SKILL_TRAINING=War3_AddRaceSkill(thisRaceID,"Sorceress Training(passive)","Makes the sorceress more powerful",false,5);
		SKILL_INVISIBILITY=War3_AddRaceSkill(thisRaceID,"Invisibility(ability)","You become invisible for short time",false,5);
		ULT_POLYMORPH=War3_AddRaceSkill(thisRaceID,"Polymorph","Morph your victim into a helpless critter",true,5);
		War3_CreateRaceEnd(thisRaceID);
	
}

public OnRaceChanged ( client, oldrace, newrace)
{
	if(newrace != thisRaceID){
		War3_WeaponRestrictTo(client,thisRaceID,"");
		W3ResetAllBuffRace(client,thisRaceID);
	}
	if(newrace == thisRaceID){
		War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife,weapon_famas");
		if(ValidPlayer(client,true)){
			GivePlayerItem(client, "weapon_famas");
		}
	}
}

public OnWar3EventSpawn(client)
{	
	bIsPoly[client]=false;
	bIsSlow[client]=false;
	if(War3_GetRace(client)==thisRaceID){
		GivePlayerItem(client, "weapon_famas");
		War3_SetBuff(client,bDisarm,thisRaceID,false);
		bIsVisible[client]=true;
		Buffs(client);
	}
}

public Buffs(client)
{
	new skill=War3_GetSkillLevel(client,thisRaceID,SKILL_TRAINING);
	if(skill==1)
	{
		PrintHintText(client, "You train in Polymorph!");	
	}
	if(skill==2)
	{
		War3_SetBuff(client,fAttackSpeed,thisRaceID,1.2);
		PrintHintText(client, "You train to level 2!");
	}
	if(skill==3)
	{
		War3_SetBuff(client,fAttackSpeed,thisRaceID,1.2);
		War3_SetBuff(client,fLowGravitySkill,thisRaceID,0.5);
		PrintHintText(client, "You train to level 3!");
	}
	if(skill==4)
	{
		War3_SetBuff(client,fAttackSpeed,thisRaceID,1.2);
		War3_SetBuff(client,fLowGravitySkill,thisRaceID,0.5);
		War3_SetBuff(client,fMaxSpeed,thisRaceID,1.2);
		PrintHintText(client, "You train to level 4!");
	}
	if(skill==5)
	{
		War3_SetBuff(client,fAttackSpeed,thisRaceID,1.2);
		War3_SetBuff(client,fLowGravitySkill,thisRaceID,0.5);
		War3_SetBuff(client,fMaxSpeed,thisRaceID,1.2);
		War3_SetBuff(client,bImmunityUltimates,thisRaceID,true);
		PrintHintText(client, "You master your training!");
	}
}

public Action:WeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid=GetEventInt(event,"userid");
	new index=GetClientOfUserId(userid);
	if(index>0)
	{
		if(War3_GetRace(index)==thisRaceID&&!bIsVisible[index])
		{
			War3_SetBuff(index,bDisarm,thisRaceID,false);
			War3_SetBuff(index,fInvisibilitySkill,thisRaceID,1.0);
			War3_SetBuff(index,fMaxSpeed,thisRaceID,1.0);
			PrintHintText(index, "You're not invisible anymore!");
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
				new skill1=War3_GetSkillLevel(attacker,thisRaceID,SKILL_SLOW);
				
				if(skill1>0&&!W3HasImmunity(victim,Immunity_Skills)){
					if(War3_SkillNotInCooldown(attacker,thisRaceID,SKILL_SLOW,true)){
						if (!bIsSlow[victim]){
							PrintHintText(victim, "You've been slowed");
							EmitSoundToAll(slow,attacker);
							EmitSoundToAll(slow,victim);
							
							War3_SetBuff(victim,fSlow,thisRaceID,0.6);
							War3_SetBuff(victim,fAttackSpeed,thisRaceID,0.75);
							bIsSlow[victim]=true;
							//Start timer to undo slowdown
							CreateTimer(1.0,Slow,victim);
							War3_CooldownMGR(attacker,SlowTime[skill1],thisRaceID,SKILL_SLOW,_,_);
						}
					}	
				}
				
			}
			if(bIsPoly[victim]){
				War3_DamageModPercent(0.20);
			}
			
		}
		
	}
	
}

public Action:Visible(Handle:timer,any:client)
{
	if (ValidPlayer(client,true)){
		War3_SetBuff(client,bDisarm,thisRaceID,false);
		War3_SetBuff(client,fInvisibilitySkill,thisRaceID,1.0);
		War3_SetBuff(client,fMaxSpeed,thisRaceID,1.0);
		PrintHintText(client, "You're not invisible anymore!");
	}
}

public Action:Slow(Handle:timer,any:victim)
{
	if (ValidPlayer(victim,true)){
		bIsSlow[victim]=false;
		War3_SetBuff(victim,fMaxSpeed,thisRaceID,1.0);
		War3_SetBuff(victim,fAttackSpeed,thisRaceID,1.0);
	}
}

public OnAbilityCommand(client,ability,bool:pressed)
{
	if(!Silenced(client)){
		if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && IsPlayerAlive(client)){
			if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_INVISIBILITY,true)){
				new skill3=War3_GetSkillLevel(client,thisRaceID,SKILL_INVISIBILITY);
					
				if(skill3>0){		
					PrintHintText(client, "You're now invisible");
					EmitSoundToAll(invisibility,client);
					War3_CooldownMGR(client,20.0,thisRaceID,SKILL_INVISIBILITY,_,_);
					CreateTimer(InvisTime[skill3], Visible, client);
					War3_SetBuff(client,bDisarm,thisRaceID,true);
					War3_SetBuff(client,fInvisibilitySkill,thisRaceID,0.0);
					War3_SetBuff(client,fMaxSpeed,thisRaceID,1.4);
					bIsVisible[client]=false;
				}
				else
				{
					PrintHintText(client, "Level your Invisibility first");
				}
				
			}
			
		}
		
	}
	else
	{
		PrintHintText(client,"Silenced: Can not cast");
	}
	
}

public OnUltimateCommand(client,race,bool:pressed)
{
	if(race==thisRaceID && pressed && ValidPlayer(client)){
		new ult_polymorph=War3_GetSkillLevel(client,thisRaceID,ULT_POLYMORPH);
		new skill_training=War3_GetSkillLevel(client,thisRaceID,SKILL_TRAINING);
		
		if(ult_polymorph>0){
			if(skill_training>0){
				if(!Silenced(client)){
					if(War3_SkillNotInCooldown(client,thisRaceID,ULT_POLYMORPH,true)){ 
						new target = War3_GetTargetInViewCone(client,500.0,false,8.0);
						
						if(target>0){
							new victimTeam=GetClientTeam(target);
							new playersAliveSameTeam;
							for(new i=1;i<=MaxClients;i++){
								if(i!=target&&ValidPlayer(i,true)&&GetClientTeam(i)==victimTeam){
									playersAliveSameTeam++;
								}
							}
							if(playersAliveSameTeam>0){
								if(!bIsVisible[client]){
									CreateTimer(0.1, Visible, client);
								}
								GetClientModel(target, OldModel[target], 256);
								SetEntityModel(target, "models/player/slow/sam_and_max/max/slow_v2.mdl");
							
								War3_SetBuff(target,bDisarm,thisRaceID,true);
								War3_SetBuff(target,bSilenced,thisRaceID,true);
							
								EmitSoundToAll(polymorph,target);
								EmitSoundToAll(polymorph,client);
								
								CreateTimer(PolymorphTime[ult_polymorph], Undo, target);
								War3_CooldownMGR(client,60.0,thisRaceID,ULT_POLYMORPH,_,_);
							}
							else
							{
								PrintHintText(client, "Target is last person alive");
							}
						}
						else
						{
							PrintHintText(client,"No target close by"); 
						}
						
						
					}
				
				}
				else
				{
					PrintHintText(client, "Silenced can not cast");
				}
			}
			else
			{
				PrintHintText(client, "Level your training more");
			}
		}
		else
		{
			PrintHintText(client, "Level your ultimate first");
		}
		
	}
	
}

public Action:Undo(Handle:timer,any:client)
{
	if (ValidPlayer(client,true)){
		War3_SetBuff(client,bDisarm,thisRaceID,false);
		War3_SetBuff(client,bSilenced,thisRaceID,false);
		PrintHintText(client, "You're not invisible anymore!");
		SetEntityModel(client, OldModel[client]);
	}
	
}