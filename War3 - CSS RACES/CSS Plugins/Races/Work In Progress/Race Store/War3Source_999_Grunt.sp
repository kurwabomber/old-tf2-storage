/**
* File: War3Source_Grunt.sp
* Description: The Grunt race for War3Source.
* Author(s): Cereal Killer 
*/

#pragma semicolon 1
 
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdktools_functions>
#include <sdktools_tempents>
#include <sdktools_tempents_stocks>
#include <sdkhooks>

public Plugin:myinfo = 
{
	name = "War3Source Race - Grunt",
	author = "Cereal Killer",
	description = "Grunt for War3Source.",
	version = "1.0.7.3",
	url = "http://warcraft-source.net/"
}

new thisRaceID;

//Pillage
new Float:Pillagechance[]={0.0,0.6,0.9,0.6,0.9,1.0};

//Berserker Health
new BerserkerHP[]={0,40,50,60,70,80};
new BerserkerARMOR[]={0,50,60,80,90,100};

//Berserker Strength
new Float:bstdamage[]={0.0,1.05,1.1,1.15,1.2,1.25};

//Arcanite Enchancement
new Float:arcenhdistance[]={0.0,200.0,250.0,300.0,350.0,400.0};
new Float:arcenhdamage[]={0.0,1.05,1.1,1.15,1.20,1.25};

//SKILLS and ULTIMATE
new PILLAGE, BHP, BST, ARCENH;

public OnWar3LoadRaceOrItemOrdered2(num)
{
	if(num==192){
		thisRaceID=War3_CreateNewRace("Grunt","grunt");
		PILLAGE=War3_AddRaceSkill(thisRaceID,"Pillage (Attack)","Steal Gold",false,5);
		BHP=War3_AddRaceSkill(thisRaceID,"Berserker Health (Passive)","More health",false,5);
		BST=War3_AddRaceSkill(thisRaceID,"Berserker Strength (Attack)","More damage",false,5);
		ARCENH=War3_AddRaceSkill(thisRaceID,"Arcanite enhancement (Passive)","Alies close by do more damage",true,5);
		War3_CreateRaceEnd(thisRaceID);
	}
}

public OnWar3EventSpawn(client)
{
	if(War3_GetRace(client)==thisRaceID&&ValidPlayer(client,true)){
		War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife,weapon_fiveseven");
		GivePlayerItem(client,"weapon_fiveseven");
		HPbonus(client);
	}
}

public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace != thisRaceID)
	{
		War3_WeaponRestrictTo(client,thisRaceID,"");
	}
	if(newrace == thisRaceID)
	{
		War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife,weapon_fiveseven");
		if(ValidPlayer(client,true))
		{
			GivePlayerItem(client,"weapon_fiveseven");
			HPbonus(client);
		}
	}
}

public OnW3TakeDmgBulletPre(victim,attacker,Float:damage)
{
	if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim){
		new vteam=GetClientTeam(victim);
		new ateam=GetClientTeam(attacker);
		if(vteam!=ateam){
			new race_attacker=War3_GetRace(attacker);
			new skill_level=War3_GetSkillLevel(attacker,thisRaceID,BST);
			new level=War3_GetSkillLevel(attacker,thisRaceID,PILLAGE);
			if(race_attacker==thisRaceID){
				if(!Hexed(attacker)){
					if(skill_level>0){
						if(!W3HasImmunity(victim,Immunity_Skills)){
							War3_DamageModPercent(bstdamage[skill_level]);
						}
					}
					if(level>0){
						if(!W3HasImmunity(victim,Immunity_Skills)){
							if(GetRandomFloat(0.0,1.0)<=Pillagechance[level]){
								new gold=War3_GetGold(victim);
								if(gold>0){
									War3_SetGold(victim,War3_GetGold(victim)-1);
									War3_SetGold(attacker,War3_GetGold(attacker)+1);
									PrintHintText(victim,"Grunt stole some gold");
									PrintHintText(attacker,"Steal Gold");
								}
								else
								{
									PrintHintText(attacker,"They have no gold.");
								}
							}
						}
					}
				}
			}

			for(new i=0;i<=MaxClients;i++){
				if(ValidPlayer(i,true)&&War3_GetRace(i)==thisRaceID){
					new iteam=GetClientTeam(i);
					if(iteam==ateam){
						if(i!=attacker){
							new skilllevel=War3_GetSkillLevel(i,thisRaceID,ARCENH);
							if(skilllevel>0){
								if(!W3HasImmunity(victim,Immunity_Skills)){
									new Float:ipos[3];
									new Float:attpos[3];
									GetClientAbsOrigin(i,ipos);
									GetClientAbsOrigin(attacker, attpos);
									if(GetVectorDistance(ipos,attpos)<arcenhdistance[skilllevel]){
										War3_DamageModPercent(arcenhdamage[skilllevel]);
									}
								}
							}
						}
					}
				}
			}
		}
	}
}

public HPbonus(client)
{
	if(War3_GetRace(client)==thisRaceID){
		new skill_level=War3_GetSkillLevel(client,thisRaceID,BHP);
		if(skill_level>0){
			new hpadd=BerserkerHP[skill_level];
			SetEntityHealth(client,GetClientHealth(client)+hpadd);
			War3_SetMaxHP(client,War3_GetMaxHP(client)+hpadd);
			new armoradd=BerserkerARMOR[skill_level];
			War3_SetCSArmor(client,armoradd);
		}
	}
}