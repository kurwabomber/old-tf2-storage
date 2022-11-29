/**
* File: War3Source_Banshee.sp
* Description: The Banshee race for War3Source.
* Author(s): Cereal Killer, Lucky
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
public Plugin:myinfo = 
{
	name = "War3Source Race - Banshee",
	author = "Cereal Killer and Lucky",
	description = "Banshee for War3Source.",
	version = "1.0.6.4",
	url = "http://warcraft-source.net/"
};
new CURSE, AMS, TRAINING, POSSESS;

//Training
new TRA_regen[6]={0,2,2,3,3,4};
new maxhp1[6]={0,10,20,30,40,50};
//Anti Magic Shell
new bool:bAMSREADY[MAXPLAYERS];
new Float:AMScooldown[6]={0.0,18.0,15.0,12.0,10.0,9.0};
//Curse
new bool:bCursed[MAXPLAYERS];
new Float:CurseChance[6]={0.0,0.55,0.60,0.65,0.70,0.75};
new bool:bisCursed[MAXPLAYERS];
//Possession
new bool:bPossessed[MAXPLAYERS];
new bool:bPossess[MAXPLAYERS];
new PossessDamage[6]={0,5,6,7,8,10};
new bPossessDamage[MAXPLAYERS];
new bool:bPossession[MAXPLAYERS][MAXPLAYERS];
new PossessedBy[MAXPLAYERS];
new String:NewModel[MAXPLAYERS][256];

new ShieldSprite;
new BeamSprite,HaloSprite;
new String:AMS_sound[]="banshee/AMS.wav";
new String:curse_sound[]="banshee/Curse.wav";
new String:possess_sound[]="banshee/Possession.wav";

public OnPluginStart()
{
		CreateTimer(3.0,CalcRegenWaves,_,TIMER_REPEAT);
		CreateTimer(1.0,PossessLoop,_,TIMER_REPEAT);
}

public OnMapStart()
{
	ShieldSprite=PrecacheModel("sprites/strider_blackball.vmt");
	BeamSprite=PrecacheModel("materials/sprites/lgtning.vmt");
	HaloSprite=PrecacheModel("materials/sprites/halo01.vmt");
	War3_PrecacheSound(AMS_sound);
	War3_PrecacheSound(curse_sound);
	War3_PrecacheSound(possess_sound);
}

public OnWar3PluginReady()
{
	
		thisRaceID=War3_CreateNewRace("[ALPHA]Banshee","banshee");
		CURSE=War3_AddRaceSkill(thisRaceID,"Curse","Curse the victim, making him miss 33% of his shots and cannot use skills",false,5);
		AMS=War3_AddRaceSkill(thisRaceID,"Anti Magic Shell","Next Bullet does 0 damage (Passive and has cooldown)",false,5);
		TRAINING=War3_AddRaceSkill(thisRaceID,"Banshee Training","Raise max HP and HP regen.",false,5);
		POSSESS=War3_AddRaceSkill(thisRaceID,"Possession (Ultimate)","possesses your target and deals damage over time but you take more damage",true,5);
		War3_CreateRaceEnd(thisRaceID);
	
}
public Action:CalcRegenWaves(Handle:timer,any:userid)
{
	if(thisRaceID>0){
		for(new i=1;i<=MaxClients;i++){
			if(ValidPlayer(i,true)){
				if(War3_GetRace(i)==thisRaceID){
					Regen(i); //check leves later
				}
				
			}
			
		}
		
	}
	
}

public Regen(client)
{
	new skill = War3_GetSkillLevel(client,thisRaceID,TRAINING);
	
	if(skill>0){
		if(ValidPlayer(client,true)){
			War3_HealToMaxHP(client,TRA_regen[skill]);
		}
		
	}
	
}

public OnWar3EventSpawn(client)
{
	for(new x=1;x<=MaxClients;x++)
		bPossession[client][x]=false;
	
	bPossessed[client]=false;
	bisCursed[client]=false;
	bCursed[client]=false;
	if(War3_GetRace(client)==thisRaceID){
		if(ValidPlayer(client,true)){
			bPossess[client]=false;
			setbuffs(client);
		}
		
	}
	
}

public OnRaceChanged(client, oldrace, newrace)
{
	if(newrace != thisRaceID){
		W3ResetAllBuffRace( client, thisRaceID );
	}
	
	if(newrace == thisRaceID){
		if(ValidPlayer(client,true)){
			setbuffs(client);
		}
		
	}
	
}

public setbuffs(client)
{
	if(War3_GetRace(client)==thisRaceID){
		new skill=War3_GetSkillLevel(client,thisRaceID,TRAINING);
		War3_SetBuff( client, iAdditionalMaxHealthNoHPChange, thisRaceID, War3_GetMaxHP(client)+maxhp1[skill]);
		bAMSREADY[client]=true;
	}
	
}


public OnW3TakeDmgBulletPre(victim,attacker,Float:damage)
{
	if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0){
		new vteam=GetClientTeam(victim);
		new ateam=GetClientTeam(attacker);
		
		if(vteam!=ateam){
			new race_attacker=War3_GetRace(attacker);
			new race_victim=War3_GetRace(victim);
			new skill_level=War3_GetSkillLevel(victim,thisRaceID,AMS);
			
			if(race_victim==thisRaceID && skill_level>0 ){
				if(bAMSREADY[victim]==true){
					War3_DamageModPercent(0.0);
					PrintCenterText(victim,"Anti Magic Shell Block his Attack");
					PrintCenterText(attacker,"Anti Magic Shell Block your Attack");
					bAMSREADY[victim]=false;
					CreateTimer(AMScooldown[skill_level], AMSreset, victim);
					
					new Float:pos[3];
					GetClientAbsOrigin(victim,pos);
					pos[2]+=35;
					TE_SetupGlowSprite(pos, ShieldSprite, 0.1, 1.0, 130);
					TE_SendToAll(); 
					
					EmitSoundToAll(AMS_sound,attacker);
					EmitSoundToAll(AMS_sound,victim);
				}
				
			}
			
			if(race_victim==thisRaceID && bPossess[victim]){
				War3_DamageModPercent(1.66);
			}
			
			new skill_curse=War3_GetSkillLevel(attacker,thisRaceID,CURSE);
			new Float:chance_mod=W3ChanceModifier(attacker);
			
			if(race_attacker==thisRaceID && skill_curse>0 && !Silenced(attacker)){
				if(GetRandomFloat(0.0,1.0)<=CurseChance[skill_curse]*chance_mod && !W3HasImmunity(victim,Immunity_Skills) && !bisCursed[victim]){
					bisCursed[victim]=true;
					bCursed[victim]=true;
					War3_SetBuff(victim,bHexed,thisRaceID,true);
					PrintHintText(victim,"You've been cursed");
					PrintHintText(attacker,"You've cursed your enemy");
					CreateTimer(5.0, Curse, victim);
					
					new Float:pos[3]; 
					GetClientAbsOrigin(attacker,pos);
					pos[2]+=30;
					new Float:targpos[3];
					GetClientAbsOrigin(victim,targpos);
					targpos[2]+=30;
					TE_SetupBeamPoints(pos, targpos, HaloSprite, HaloSprite, 0, 8, 0.8, 2.0, 10.0, 10, 10.0, {125,0,255,100}, 70); 
					TE_SendToAll();
					
					EmitSoundToAll(curse_sound,attacker);
					EmitSoundToAll(curse_sound,victim);
				}
				
			}
			
			if(bCursed[attacker]){
				if(GetRandomFloat(0.0,1.0)<=0.33*chance_mod){
					PrintHintText(attacker,"You've missed");
					War3_DamageModPercent(0.0);
				}
				
			}
			
		}
		
	}
	
}

public Action:AMSreset(Handle:timer,any:client)
{
	if(ValidPlayer(client,true)==true){
		bAMSREADY[client]=false;
		PrintHintText(client,"Anti Magic Shell Ready!");
	}
	
}

public Action:Curse(Handle:timer,any:client)
{
	if(ValidPlayer(client,true)==true){
		bisCursed[client]=false;
		bCursed[client]=false;
		War3_SetBuff(client,bHexed,thisRaceID,false);
	}
	
}

public OnUltimateCommand(client,race,bool:pressed)
{
	if(race==thisRaceID && pressed && ValidPlayer(client)){
		new skill_training=War3_GetSkillLevel(client,thisRaceID,TRAINING);
		new ult_possess=War3_GetSkillLevel(client,thisRaceID,POSSESS);
		
		if(ult_possess>0){
			if(skill_training>0){
				if(!Silenced(client)){
					if(War3_SkillNotInCooldown(client,thisRaceID,POSSESS,true)){
						new target = War3_GetTargetInViewCone(client,350.0,false,8.0);
						
						if(target>0){
							War3_SetBuff(target,bStunned,thisRaceID,true);
							War3_SetBuff(client,bStunned,thisRaceID,true);
							bPossessed[target]=true;
							bPossess[client]=true;
							bPossession[client][target]=true;
							PossessedBy[target]=client;
							bPossessDamage[target]=PossessDamage[ult_possess];
							
							new Float:pos[3]; 
							GetClientAbsOrigin(client,pos);
							pos[2]+=15;
							new Float:tarpos[3]; 
							GetClientAbsOrigin(target,tarpos);
							tarpos[2]+=15;
							TE_SetupBeamRingPoint(pos, 1.0, 350.0, BeamSprite, HaloSprite, 0, 5, 1.0, 50.0, 1.0, {84,84,84,255}, 50, 0);
							TE_SendToAll();
							TE_SetupBeamRingPoint(tarpos, 1.0, 350.0, BeamSprite, HaloSprite, 0, 5, 1.0, 50.0, 1.0, {84,84,84,255}, 50, 0);
							TE_SendToAll();
							
							EmitSoundToAll(possess_sound,target);
							EmitSoundToAll(possess_sound,client);
						}
						else
						{
							PrintHintText(client,"No target close by"); 
						}
						
					}
					
				}
				else
				{
					PrintHintText(client,"Silenced: Can Not Cast"); 
				}
				
			}
			else
			{
				PrintHintText(client,"Level your Banshee Training first");
			}
			
		}
		else
		{
			PrintHintText(client,"Level Your Ultimate First");
		}	
		
	}
	
}

public Action:PossessLoop(Handle:timer,any:userid)
{
	for(new i=1;i<=MaxClients;i++){
		if(ValidPlayer(i,true)){
			if(War3_GetRace(i)==thisRaceID){
				for(new x=1;x<=MaxClients;x++){
					if(ValidPlayer(x,true)&&bPossession[i][x]){
						War3_DealDamage(x,bPossessDamage[x],i,DMG_BULLET,"Possession");
					}
					
				}
				
			}
			
		}
		
	}
	
}

public OnWar3EventDeath(victim,attacker)
{
	new race_victim=War3_GetRace(victim);
	new race_attacker=War3_GetRace(attacker);
	
	if(race_victim==thisRaceID){
		War3_SetBuff(victim,bStunned,thisRaceID,false);
		bPossess[victim]=false;
		for(new x=1;x<=MaxClients;x++){
			if(ValidPlayer(x,true)&&bPossession[victim][x]){
				bPossession[victim][x]=false;
				War3_SetBuff(x,bStunned,thisRaceID,false);
				bPossessed[x]=false;
			}
			
		}
		
	}
	
	if(bPossessed[victim]&&race_attacker==thisRaceID&&bPossession[attacker][victim]){
		GetClientModel(victim, NewModel[attacker], 256);
		SetEntityModel(attacker, NewModel[attacker]);
		War3_SetBuff(attacker,bStunned,thisRaceID,false);
		bPossess[attacker]=false;
		bPossession[attacker][victim]=false;
		War3_SetBuff(victim,bStunned,thisRaceID,false);
		bPossessed[victim]=false;
		War3_CooldownMGR(attacker,60.0,thisRaceID,POSSESS,_,_ );
	}
	else
	{
		if(bPossessed[victim]){
			new banshee=PossessedBy[victim];
			War3_SetBuff(banshee,bStunned,thisRaceID,false);
			bPossess[banshee]=false;
			bPossession[banshee][victim]=false;
			War3_SetBuff(victim,bStunned,thisRaceID,false);
			bPossessed[victim]=false;
			War3_CooldownMGR(banshee,60.0,thisRaceID,POSSESS,_,_ );
		}
		
	}
	
}