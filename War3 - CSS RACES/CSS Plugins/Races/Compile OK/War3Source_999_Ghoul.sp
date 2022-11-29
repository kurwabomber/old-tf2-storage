/**
* File: War3Source_Ghoul.sp
* Description: The Ghoul race for War3Source.
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
	name = "War3Source Race - Ghoul",
	author = "Cereal Killer",
	description = "Ghoul for War3Source.",
	version = "1.0.6.4",
	url = "http://warcraft-source.net/"
}

new thisRaceID;

new BeamSprite,HaloSprite;

//Cannibalize
new String:Nom[]="war3source/nomnom.mp3";
new Float:corpselocation[3][MAXPLAYERS][20];
new dietimes[MAXPLAYERS];
new cannibal[]={0,16,17,18,19,20};
new corpsehealth[MAXPLAYERS][20];
new bool:corpsedied[MAXPLAYERS][20];

//Frenzy
new Float:attspeed[]={1.0,1.6,1.65,1.7,1.75,1.8};
new Float:movespeed[]={1.0,1.42,1.44,1.46,1.48,1.5};

//Unholy Strength
new Float:unhsdamage[6]={1.0,1.3,1.35,1.4,1.45,1.5};

//Unholy Armor
new unholyarmor[]={50,60,70,80,90,100};

//SKILLS and ULTIMATE
new CANN, FREN, UNHS, UNHA;

public OnPluginStart()
{
    CreateTimer(0.5,nomnomnom,_,TIMER_REPEAT);
    HookEvent("round_start",EventRoundStart);
}

public OnMapStart()
{
	War3_AddCustomSound(Nom);
	BeamSprite=PrecacheModel("materials/sprites/lgtning.vmt");
	HaloSprite=PrecacheModel("materials/sprites/halo01.vmt");
}

public OnWar3PluginReady()
{
	
		thisRaceID=War3_CreateNewRace("Ghoul","ghoul");
		CANN=War3_AddRaceSkill(thisRaceID,"Cannibalize (Dead)","Regain your health eating fresh corpses",false,5);
		FREN=War3_AddRaceSkill(thisRaceID,"Frenzy (Passive)","More mouvement speed and attack speed",false,5);
		UNHS=War3_AddRaceSkill(thisRaceID,"Unholy Strength (Attack)","More damage",false,5);
		UNHA=War3_AddRaceSkill(thisRaceID,"Unholy Armor (Passive)","Raise you max HP",true,5);
		War3_CreateRaceEnd(thisRaceID);
	
}

public OnWar3EventSpawn(client)
{
	if(War3_GetRace(client)==thisRaceID){
		War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife");
		if(ValidPlayer(client,true)){
			GivePlayerItem(client,"weapon_knife");
			setbuffs(client);
		}
	}
}

public EventRoundStart(Handle:event,const String:name[],bool:dontBroadcast)
{
	resetcorpses();
}

public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace!=thisRaceID){
		War3_WeaponRestrictTo(client,thisRaceID,"");
		W3ResetAllBuffRace( client, thisRaceID );
	}
	if(newrace==thisRaceID){
		War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife");
		if(ValidPlayer(client,true)){
			GivePlayerItem(client,"weapon_knife");
			setbuffs(client);
		}
	}
}

public resetcorpses()
{
	for(new client=0;client<=MaxClients;client++){
		for(new deaths=0;deaths<=19;deaths++){
			corpselocation[0][client][deaths]=0.0;
			corpselocation[1][client][deaths]=0.0;
			corpselocation[2][client][deaths]=0.0;
			dietimes[client]=0;
			corpsehealth[client][deaths]=0;
			corpsedied[client][deaths]=false;
		}
	}
}

public setbuffs(client)
{
	if(War3_GetRace(client)==thisRaceID){
		new skill_level1=War3_GetSkillLevel(client,thisRaceID,UNHA);
		new skill_level2=War3_GetSkillLevel(client,thisRaceID,FREN);
		War3_SetBuff( client, iAdditionalMaxHealthNoHPChange, thisRaceID, unholyarmor[skill_level1]);
		if(skill_level2>0){
			War3_SetBuff(client,fAttackSpeed,thisRaceID,attspeed[skill_level2]);
			War3_SetBuff(client,fMaxSpeed,thisRaceID,movespeed[skill_level2]);
		}
	}
}


public OnW3TakeDmgAllPre(victim,attacker,Float:damage)
{
	if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0){
		new vteam=GetClientTeam(victim);
		new ateam=GetClientTeam(attacker);
		if(vteam!=ateam){
			new race_attacker=War3_GetRace(attacker);
			if(race_attacker==thisRaceID){
				if(!Hexed(attacker)){
					new skill_level=War3_GetSkillLevel(attacker,thisRaceID,UNHS);
					if(skill_level>0){
						War3_DamageModPercent(unhsdamage[skill_level]);
					}
				}
			}
		}
	}
}

public OnWar3EventDeath(victim,attacker)
{
	new deaths=dietimes[victim];
	dietimes[victim]++;
	corpsedied[victim][deaths]=true;
	corpsehealth[victim][deaths]=60;
	new Float:pos[3];
	War3_CachedPosition(victim,pos);
	corpselocation[0][victim][deaths]=pos[0];
	corpselocation[1][victim][deaths]=pos[1];
	corpselocation[2][victim][deaths]=pos[2];
	for(new client=0;client<=MaxClients;client++){
		if(War3_GetRace(client)==thisRaceID&&ValidPlayer(client,true)){
			TE_SetupBeamRingPoint(pos,25.0,75.0,BeamSprite,HaloSprite,0,15,6.0,20.0,3.0,{100,100,150,255},20,0);
			TE_SendToClient(client);
		}
	}
}

public Action:nomnomnom(Handle:timer)
{
	for(new client=0;client<=MaxClients;client++){
		if(War3_GetRace(client)==thisRaceID&&ValidPlayer(client,true)){
			new skill_level=War3_GetSkillLevel(client,thisRaceID,CANN);
			if(skill_level>0){
				for(new corpse=0;corpse<=MaxClients;corpse++){
					for(new deaths=0;deaths<=19;deaths++){
						if(corpsedied[corpse][deaths]==true){
							new Float:corpsepos[3];
							new Float:clientpos[3];
							GetClientAbsOrigin(client,clientpos);
							corpsepos[0]=corpselocation[0][corpse][deaths];
							corpsepos[1]=corpselocation[1][corpse][deaths];
							corpsepos[2]=corpselocation[2][corpse][deaths];
							
							if(GetVectorDistance(clientpos,corpsepos)<50){
								if(corpsehealth[corpse][deaths]>=0){
									EmitSoundToAll(Nom,client);
									W3FlashScreen(client,{155,0,0,40},0.1);
									corpsehealth[corpse][deaths]-=5;
									new addhp1=cannibal[skill_level];
									War3_HealToMaxHP(client,addhp1);
								}
							}
							else
							{
								corpsehealth[corpse][deaths]-=5;
							}
						}
					}
				}
			}
		}
	}
}