/**
* File: War3Source_DemonHunter.sp
* Description: The Demon Hunter race for War3Source.
* Author(s): Cereal Killer + Anthony Iacono 
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
	name = "War3Source Race - Demon Hunter",
	author = "Cereal Killer",
	description = "Demon Hunter for War3Source.",
	version = "1.0.6.4",
	url = "http://warcraft-source.net/"
};
new SKILL_MANABURN, SKILL_IMMOLATION, SKILL_EVADE, ULT_META;
new Float:EvadeChance[6]={0.0,0.05,0.10,0.15,0.20,0.25};
new ManaMoney[6]={0,400,800,1200,1600,2000};
new Isimmolation[MAXPLAYERS];
new Ismeta[MAXPLAYERS];
new firedamage[6]={0,1,1,2,3,4};
new BurnSprite, g_iExplosionModel;
new metamaxhp[6]={0,150,200,250,300,350};
new oldhealth[MAXPLAYERS];
public OnPluginStart(){
	CreateTimer(1.0,selfburnloop,_,TIMER_REPEAT);
	CreateTimer(0.1,heataoe,_,TIMER_REPEAT);
}
public OnMapStart(){
	BurnSprite=PrecacheModel("materials/sprites/fire1.vmt");
	g_iExplosionModel = PrecacheModel("materials/effects/fire_cloud1.vmt");
}
public OnWar3EventSpawn(client){
	Isimmolation[client]=0;
	Ismeta[client]=0;
	War3_SetBuff(client,fMaxSpeed,thisRaceID,1.0);
}
public OnWar3PluginReady(){
	
		thisRaceID=War3_CreateNewRace("Demon Hunter","dhunter");
		SKILL_MANABURN=War3_AddRaceSkill(thisRaceID,"Mana Burn","Burns enemy's mana. When mana is drained it does 3x the damage",false,5);
		SKILL_IMMOLATION=War3_AddRaceSkill(thisRaceID,"Immolation(+ability)","Set the demon hunter on fire and cause AoE damage(+ability)",false,5);
		SKILL_EVADE=War3_AddRaceSkill(thisRaceID,"Evasion","Chance of evading a shot",false,5);
		ULT_META=War3_AddRaceSkill(thisRaceID,"Metamorphosis(+ultimate)","Transform into a powerfull demon(+ultimate)",true,5);
		War3_CreateRaceEnd(thisRaceID);
	
}
public OnRaceChanged(client, oldrace, newrace){
	if (newrace != thisRaceID)
	{
	W3ResetAllBuffRace( client, thisRaceID );
	}
}
public OnW3TakeDmgBulletPre(victim,attacker,Float:damage){
	if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim)
	{
		new vteam=GetClientTeam(victim);
		new ateam=GetClientTeam(attacker);
		if(vteam!=ateam)
		{
			new race_attacker=War3_GetRace(attacker);
			new race_victim=War3_GetRace(victim);
			new skill_level_evasion=War3_GetSkillLevel(victim,thisRaceID,SKILL_EVADE);
			if(race_victim==thisRaceID && skill_level_evasion>0 ) 
			{
				if(GetRandomFloat(0.0,1.0)<=EvadeChance[skill_level_evasion] && !W3HasImmunity(attacker,Immunity_Skills))
				{
					War3_DamageModPercent(0.0);
				}
			}
			new skill_level_mana=War3_GetSkillLevel(victim,thisRaceID,SKILL_MANABURN);
			if(race_attacker==thisRaceID && skill_level_mana>0 ) 
			{
				if(!W3HasImmunity(victim,Immunity_Skills))
				{
					if(GetCSMoney(victim)>0){
						if(GetCSMoney(victim)>ManaMoney[skill_level_mana]){
							SetCSMoney(victim, GetCSMoney(victim)-ManaMoney[skill_level_mana]);
							SetCSMoney(attacker, GetCSMoney(attacker)+ManaMoney[skill_level_mana]);
						}
						else {
						SetCSMoney(victim,0);
						}
					}
					if (GetCSMoney(victim)==0){
						War3_DamageModPercent(3.0);
						new Float:position[3];
						new Float:positionclient[3];
						GetClientAbsOrigin(victim,position);
						GetClientAbsOrigin(attacker,positionclient);
						position[2]+=35;
						positionclient[2]+=35;
						TE_SetupBeamPoints(position, positionclient,BurnSprite, g_iExplosionModel , 0, 8, 0.5, 10.0, 10.0, 10, 20.0, {255,0,255,255}, 70); 
						TE_SendToAll();

					}
					else {
						SetCSMoney(victim,0);
					}
				}
			}
		}
	}
}
public OnAbilityCommand(client,ability,bool:pressed){
	if (ability==0){
		if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && IsPlayerAlive(client)){
			new skill_level=War3_GetSkillLevel(client,thisRaceID,SKILL_IMMOLATION);
			if(skill_level>0){
				if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_IMMOLATION,false)){
					War3_CooldownMGR(client,1.0,thisRaceID,SKILL_IMMOLATION,_,_ );
					if(Isimmolation[client]==0){
						Isimmolation[client]=1;
						PrintHintText(client, "Immolation: ON.");
					}
					else {
						Isimmolation[client]=0;
						PrintHintText(client, "Immolation: OFF.");
					}
				}
			}
		}
	}
}
public Action:selfburnloop(Handle:timer,any:a){
	for(new i=0;i<=MaxClients;i++){
		if(ValidPlayer(i,true) &&War3_GetRace(i)==thisRaceID){
			new skill_level=War3_GetSkillLevel(i,thisRaceID,SKILL_IMMOLATION);
			if(skill_level>0){
				if(Isimmolation[i]==1){
					IgniteEntity(i,1.5);
					SetCSMoney(i, GetCSMoney(i)+200);
				}
			}
		}
	}
}
public Action:heataoe(Handle:timer,any:a){
	for(new i=0;i<=MaxClients;i++){
		if(ValidPlayer(i,true) &&War3_GetRace(i)==thisRaceID){
			new skill_level=War3_GetSkillLevel(i,thisRaceID,SKILL_IMMOLATION);
			if(skill_level>0){
				for(new x=0;x<=MaxClients;x++){
					if(ValidPlayer(x,true)&&x!=i){
						new iteam=GetClientTeam(i);
						new xteam=GetClientTeam(x);
						if(iteam!=xteam){
							new Float:positioni[3];
							War3_CachedPosition(i,positioni);
							new Float:positionx[3];
							War3_CachedPosition(x,positionx);
							if(Isimmolation[i]==1){
								positioni[2]+=5;
								TE_SetupBeamRingPoint(positioni, 350.0, 350.0, BurnSprite, g_iExplosionModel,0,15,0.2,5.0,3.0,{255,200,200,255},10,0);
								TE_SendToAll();
								if(!W3HasImmunity(i,Immunity_Skills)){
									if(GetVectorDistance(positioni,positionx)<225){
										IgniteEntity(x,2.0);
										War3_DealDamage(x,firedamage[skill_level],i,DMG_BURN,"fire",_,W3DMGTYPE_MAGIC);
									}
								}
							}
						}
					}
				}
			}
			if(Ismeta[i]==1){
				if(GetCSMoney(i)>200){
					SetCSMoney(i,GetCSMoney(i)-100);
				}
				else {
				Ismeta[i]=0;
				War3_SetBuff( i, iAdditionalMaxHealth, thisRaceID, 100);
				
				War3_SetBuff(i,fMaxSpeed,thisRaceID,1.0);
				PrintHintText(i, "Metamorphosis is over.");
				}
			}
		}
	}
}
public OnUltimateCommand(client,race,bool:pressed){
	if(race==thisRaceID && IsPlayerAlive(client) && pressed){
		new skill_level=War3_GetSkillLevel(client,race,ULT_META);
		if(skill_level>0){
			if(!Silenced(client)){
				if(War3_SkillNotInCooldown(client,thisRaceID,ULT_META,false)){
					War3_CooldownMGR(client,20.0,thisRaceID,ULT_META,_,_ );	
					if(GetCSMoney(client)>2000){
						if(Ismeta[client]==0){
							oldhealth[client]=GetClientHealth(client);
							Ismeta[client]=1;
							War3_SetBuff( client, iAdditionalMaxHealth, thisRaceID, metamaxhp[skill_level]);
							War3_SetBuff(client,fMaxSpeed,thisRaceID,2.0);
							PrintHintText(client, "METAMORPHOSIS: <ACTIVATED>.");
						}
						else {
							PrintHintText(client, "Wait until Metamorphosis is over.");
						}
					}
					else {
						PrintHintText(client, "Not enough Mana");
					}
				}
			}
		}
	}
}