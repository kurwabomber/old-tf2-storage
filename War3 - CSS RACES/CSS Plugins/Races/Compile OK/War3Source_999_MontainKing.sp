/**
* File: War3Source_MontainKing.sp
* Description: The Montain King race for War3Source.
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

new Float:DmgChance[6]={0.0,0.1,0.15,0.2,0.25,0.33};
new Float:BashChance[6]={0.0,0.5,0.1,0.12,0.15,0.18};
new bool:bIsBashed[MAXPLAYERS];
new Float:avatarcooldown[6]={0.0,50.0,45.0,40.0,35.0,30.0};
new avatarhp[6]={100,120,140,160,180,200};
new tclapdist[6]={0,110,120,130,140,150};
new tclapdamage[6]={0,6,8,10,12,14};
new stormdamage[6]={0,10,13,16,19,24};
new Float:stormbashtime[6]={0.0,0.8,1.0,1.2,1.4,1.6};
new BeamSprite,HaloSprite;

public Plugin:myinfo = 
{
	name = "War3Source Race - Montain King",
	author = "Cereal Killer",
	description = "Montain King for War3Source.",
	version = "1.0.6.4",
	url = "http://warcraft-source.net/"
};
new SKILL_STORM, SKILL_TCLAP, SKILL_BASH, ULT_AVATAR;

public OnPluginStart()
{
	CreateTimer(0.1,overheal,_,TIMER_REPEAT);
}

public OnMapStart(){
	BeamSprite=PrecacheModel("materials/sprites/lgtning.vmt");
	HaloSprite=PrecacheModel("materials/sprites/halo01.vmt");
}

public OnWar3EventSpawn(client){
	bIsBashed[client]=false;
	War3_SetBuff(client,bBashed,thisRaceID,false);
	War3_SetBuff(client,bImmunitySkills,thisRaceID,false);
	if (War3_GetRace(client) == thisRaceID){
		War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife");
		GivePlayerItem(client, "weapon_knife");
	}
}
public OnRaceChanged(client, oldrace, newrace)
{
	if(newrace != thisRaceID){
		War3_WeaponRestrictTo(client,thisRaceID,"");
		W3ResetAllBuffRace(client,thisRaceID);
	}
	if(newrace == thisRaceID)
	{
		War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife");
		if(ValidPlayer(client,true))
		{
			GivePlayerItem(client, "weapon_knife");
		}
	}
}

public OnWar3PluginReady()
{
	thisRaceID=War3_CreateNewRace("Montain King","mking");
	SKILL_STORM=War3_AddRaceSkill(thisRaceID,"Storm Bolt (+ability)","Trows a hammer after the enemy (+ability)",false,5);
	SKILL_TCLAP=War3_AddRaceSkill(thisRaceID,"Thunder Clap (+ability1)","Slams the ground with his hammer, aoe damage + slow(+ability)",false,5);
	SKILL_BASH=War3_AddRaceSkill(thisRaceID,"Bash (Passive)","Chance that his attack will do more damage and stun the enemy",false,5);
	ULT_AVATAR=War3_AddRaceSkill(thisRaceID,"Avatar (+ultimate)","More Speed, More Health, More Damage but for a limited time (+ultimate)",true,5);
	War3_CreateRaceEnd(thisRaceID);
}

public OnW3TakeDmgBulletPre(victim,attacker,Float:damage){
	if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim)
	{
		new vteam=GetClientTeam(victim);
		new ateam=GetClientTeam(attacker);
		if(vteam!=ateam)
		{
			new race_attacker=War3_GetRace(attacker);
			new skill_level=War3_GetSkillLevel(victim,thisRaceID,SKILL_BASH);
			if(race_attacker==thisRaceID && skill_level>0 ) 
			{
				if(GetRandomFloat(0.0,1.0)<=DmgChance[skill_level] && !W3HasImmunity(attacker,Immunity_Skills))
				{
					War3_DamageModPercent(1.5);
				}
				if(GetRandomFloat(0.0,1.0)<=BashChance[skill_level] &&!bIsBashed[victim] && !W3HasImmunity(attacker,Immunity_Skills))
				{
					War3_SetBuff(victim,bBashed,thisRaceID,true);
					bIsBashed[victim]=true;
					CreateTimer(1.0, Unbash, victim);
				}
			}
		}
	}
}

public Action:Unbash(Handle:timer,any:victim)
{
	War3_SetBuff(victim,bBashed,thisRaceID,false);
	bIsBashed[victim]=false;
}

public OnUltimateCommand(client,race,bool:pressed)
{
	if(race==thisRaceID && IsPlayerAlive(client) && pressed)
	{
		new skill_level=War3_GetSkillLevel(client,race,ULT_AVATAR);
		if(skill_level>0)
		{
			if(!Silenced(client))
			{
				if(War3_SkillNotInCooldown(client,thisRaceID,ULT_AVATAR))
				{
					War3_CooldownMGR(client,avatarcooldown[skill_level],thisRaceID,ULT_AVATAR);	
                    new hp = avatarhp[skill_level] + W3GetBuffSumInt(client,iAdditionalMaxHealth);
					SetEntityHealth(client, hp);
					War3_SetBuff(client,bImmunitySkills,thisRaceID,true);
				}
			}
		}
	}				
}

public OnAbilityCommand(client,ability,bool:pressed){
	if (ability==0)
	{
		if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && IsPlayerAlive(client))
		{
			new skill_level=War3_GetSkillLevel(client,thisRaceID,SKILL_STORM);
			if(skill_level>0)
			{
				if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_STORM,false))
				{
					new target = War3_GetTargetInViewCone(client,600.0,false,6.0);
					if(target>0 && !W3HasImmunity( target, Immunity_Skills ))
					{
						PrintHintText(client,"Storm Bolt!");
						War3_DealDamage(target,stormdamage[skill_level],client,DMG_CRUSH,"storm bolt",_,W3DMGTYPE_MAGIC);
						War3_SetBuff(target,bBashed,thisRaceID,true);
						CreateTimer(stormbashtime[skill_level], Unbash, target);
						new Float:iPosition[3];
						new Float:clientPosition[3];
						GetClientAbsOrigin(client, clientPosition);
						GetClientAbsOrigin(target, iPosition);
						iPosition[2]+=35;
						clientPosition[2]+=35;
						TE_SetupBeamPoints(iPosition,clientPosition,BeamSprite,HaloSprite,0,35,0.5,6.0,5.0,0,1.0,{155,000,255,255},20);
						TE_SendToAll();
						War3_CooldownMGR(client,9.0,thisRaceID,SKILL_STORM);
					}
					else 
					{
						PrintHintText(client,"NO VALID TARGETS WITHIN 60 FEET");
						new Float:iPosition[3];
						new Float:clientPosition[3];
						GetClientAbsOrigin(client, clientPosition);
						War3_GetAimEndPoint(client,iPosition);
						clientPosition[2]+=35;
						TE_SetupBeamPoints(iPosition,clientPosition,BeamSprite,HaloSprite,0,35,0.5,6.0,5.0,0,1.0,{255,000,000,255},20);
						TE_SendToAll();
					}
				}
			}
		}
	}
	if (ability==1){
		if(War3_GetRace(client)==thisRaceID && ability==1 && pressed && IsPlayerAlive(client)){
			new skill_level=War3_GetSkillLevel(client,thisRaceID,SKILL_TCLAP);
			if(skill_level>0){
				if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_TCLAP,false)){
					War3_CooldownMGR(client,6.0,thisRaceID,SKILL_TCLAP);
					new Float:position111[3];
					GetClientAbsOrigin(client, position111);
					position111[2]+=10;
					TE_SetupBeamRingPoint(position111,0.0,tclapdist[skill_level]*2.0,BeamSprite,HaloSprite,0,15,0.3,20.0,3.0,{100,100,150,255},20,0);
					TE_SendToAll();
					for(new i=0;i<=MaxClients;i++){
						if(ValidPlayer(i,true)&&i!=client){
							new clientteam=GetClientTeam(client);
							new iteam=GetClientTeam(i);
							if(iteam!=clientteam){
								new Float:iPosition[3];
								new Float:clientPosition[3];
								GetClientAbsOrigin(i, iPosition);
								GetClientAbsOrigin(client, clientPosition);
								if(!W3HasImmunity(i,Immunity_Skills)){
									if(GetVectorDistance(iPosition,clientPosition)<tclapdist[skill_level]){
										War3_DealDamage(i,tclapdamage[skill_level],client,DMG_CRUSH,"thunder clap",_,W3DMGTYPE_MAGIC);
										War3_SetBuff(i,fMaxSpeed,thisRaceID,0.5);
										CreateTimer(3.0,tclapslow,i);
										War3_WeaponRestrictTo(i,thisRaceID,"weapon_knife");
										CreateTimer(1.0,regainweapons,i);
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
public Action:tclapslow(Handle:timer,any:i){
	War3_SetBuff(i,fMaxSpeed,thisRaceID,1.0);
}
public Action:regainweapons(Handle:timer,any:i){
	War3_WeaponRestrictTo(i,thisRaceID,"");
}
public Action:overheal(Handle:timer,any:a){
	for(new i=0;i<=MaxClients;i++){
		if(ValidPlayer(i,true) &&War3_GetRace(i)==thisRaceID){
			new skill_level=War3_GetSkillLevel(i,thisRaceID,ULT_AVATAR);
			if(skill_level>0){
                new hp = 100 + W3GetBuffSumInt(i,iAdditionalMaxHealth);
				if(GetClientHealth(i)>hp){
					SetEntityHealth(i, GetClientHealth(i)-1);
				}
				else {
					War3_SetBuff(i,bImmunitySkills,thisRaceID,false);
				}
			}
		}
	} 
}