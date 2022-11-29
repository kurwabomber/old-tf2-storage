
/**
 * 
 * Description:   FlyingMachine from WoW
 * Author(s): [Oddity]TeacherCreature
 */
 
#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdktools_functions>
#include <sdktools_tempents>
#include <sdktools_tempents_stocks>

public Plugin:myinfo = 
{
	name = "War3Source Race - Flying Machine",
	author = "[Oddity]TeacherCreature",
	description = "The Flying Machine race for War3Source.",
	version = "1.6.1",
	url = "warcraft-source.net"
}

new thisRaceID;
new m_vecVelocity_0, m_vecVelocity_1,m_vecVelocity_2, m_vecBaseVelocity; //offsets

new BeamSprite2;
new BeamSprite,HaloSprite,BurnSprite; 

//Mithril Plating
new Float:MithRed[]={1.0,0.99,0.98,0.97,0.96,0.95,0.94,0.93,0.92,0.91,0.90};

//Bombs
new String:missilesnd[]="weapons/mortar/mortar_explode2.wav";
new Float:MissileMaxDistance[]={0.00,1000.0,2000.0,3000.0,4000.0,5000.0,6000.0,7000.0,8000.0,9000.0,9999.0};

//Flack cannon
new flak[]={0,5,6,7,8,9,10,11,12,13,14};

//Turbo charge
new Float:cooldown[]={0.0,10.0,9.0,8.0,7.0,6.0,5.0,4.0,3.0,2.0,1.0};

//SKILLS and ULTIMATE
new SKILL_MITHRIL, SKILL_BOMBS, SKILL_FLAK, ULT_TURBO;

public OnPluginStart()
{
	m_vecVelocity_0 = FindSendPropOffs("CBasePlayer","m_vecVelocity[0]");
	m_vecVelocity_1 = FindSendPropOffs("CBasePlayer","m_vecVelocity[1]");
	m_vecVelocity_2 = FindSendPropOffs("CBasePlayer","m_vecVelocity[2]");
	m_vecBaseVelocity = FindSendPropOffs("CBasePlayer","m_vecBaseVelocity");
	HookEvent("weapon_fire", WeaponFire);
}

public OnWar3PluginReady()
{
	
		thisRaceID=War3_CreateNewRace("Flying Machine","flymac");
		SKILL_MITHRIL=War3_AddRaceSkill(thisRaceID,"Mithril Plating(passive)","Armor Plating protects you",false,10);
		SKILL_BOMBS=War3_AddRaceSkill(thisRaceID,"Bombs(ability)","Fire off two missiles",false,10);
		SKILL_FLAK=War3_AddRaceSkill(thisRaceID,"Flak Cannon(attacker)","AOE damaging canon",false,10);
		ULT_TURBO=War3_AddRaceSkill(thisRaceID,"Turbo Charge","Boost the flying machine in the direction your traveling",true,10); 
		War3_CreateRaceEnd(thisRaceID);
	
}


public OnMapStart()
{
	BeamSprite2=PrecacheModel("sprites/tp_beam001.vmt");
	War3_PrecacheSound(missilesnd);
	BeamSprite=PrecacheModel("materials/sprites/lgtning.vmt");
	HaloSprite=PrecacheModel("materials/sprites/halo01.vmt");
	BurnSprite=PrecacheModel("materials/sprites/fire1.vmt");
}

public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace!=thisRaceID){
		War3_SetBuff(client,bFlyMode,thisRaceID,false);
		War3_WeaponRestrictTo(client,thisRaceID,"");
		War3_SetBuff(client,bInvisWeaponOverride,thisRaceID,false);
	}
	if(newrace==thisRaceID){
		War3_WeaponRestrictTo(client,thisRaceID,"weapon_m249");
		if(ValidPlayer(client,true)){
			if(GetClientTeam(client)==3){
			SetEntityModel(client, "models/player/techknow/apache/apache-ct.mdl");
			}
			if(GetClientTeam(client)==2){
				SetEntityModel(client, "models/player/techknow/apache/apache-t.mdl");
			}
			War3_SetBuff(client,bFlyMode,thisRaceID,true);
			GivePlayerItem(client,"weapon_m249");
			War3_SetBuff(client,bInvisWeaponOverride,thisRaceID,true);
			War3_SetBuff(client,iInvisWeaponOverrideAmount,thisRaceID,0);
		}
	}
}

public Action:UnfreezePlayer(Handle:timer,any:victim)
{
	War3_SetBuff(victim,bBashed,thisRaceID,false);
}

public OnAbilityCommand(client,ability,bool:pressed)
{
	if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && IsPlayerAlive(client)){
		if(!Silenced(client)){
			new skill_level=War3_GetSkillLevel(client,thisRaceID,SKILL_BOMBS);
			if(skill_level>0){
				if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_BOMBS,true)){
					new Float:origin[3];
					new Float:targetpos[3];
					War3_GetAimEndPoint(client,targetpos);
					GetClientAbsOrigin(client,origin);
					origin[2]+=30;
					origin[1]+=20;
					TE_SetupBeamPoints(origin, targetpos, BeamSprite2, BeamSprite2, 0, 5, 1.0, 4.0, 5.0, 2, 2.0, {255,128,35,255}, 70);  
					TE_SendToAll();
					origin[1]-=40;
					TE_SetupBeamPoints(origin, targetpos, BeamSprite2, BeamSprite2, 0, 5, 1.0, 4.0, 5.0, 2, 2.0, {255,128,35,255}, 70);  
					TE_SendToAll();
					EmitSoundToAll(missilesnd,client);
					War3_CooldownMGR(client,3.0,thisRaceID,SKILL_BOMBS,_,_);
					new target = War3_GetTargetInViewCone(client,MissileMaxDistance[skill_level],false,7.0);
					if(target>0 && !W3HasImmunity(target,Immunity_Skills)){
						War3_DealDamage(target,20,client,_,"Bombs",W3DMGORIGIN_SKILL,W3DMGTYPE_TRUEDMG);
						IgniteEntity(target,3.0);
						War3_SetBuff(target,bBashed,thisRaceID,true);
						W3FlashScreen(target,RGBA_COLOR_RED, 0.3, 0.4, FFADE_OUT);
						CreateTimer(1.5,UnfreezePlayer,target);	
					}
				}
			}
			else
			{
				PrintHintText(client, "Level your bombs first");
			}
		}
		else
		{
			PrintHintText(client, "Silenced!");
		}
	}
}
		
public OnWar3EventSpawn(client)
{
	if(War3_GetRace(client)==thisRaceID){
		War3_SetBuff(client,bFlyMode,thisRaceID,true);
		GivePlayerItem(client,"weapon_m249");
		War3_SetBuff(client,bInvisWeaponOverride,thisRaceID,true);
		War3_SetBuff(client,iInvisWeaponOverrideAmount,thisRaceID,0);
		if(GetClientTeam(client)==3){
			SetEntityModel(client, "models/player/techknow/apache/apache-ct.mdl");
		}
		if(GetClientTeam(client)==2){
			SetEntityModel(client, "models/player/techknow/apache/apache-t.mdl");
		}
	}
}

public OnW3TakeDmgBulletPre(victim,attacker,Float:damage)
{
	if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim){
		new vteam=GetClientTeam(victim);
		new ateam=GetClientTeam(attacker);
		if(vteam!=ateam){
			new race_victim=War3_GetRace(victim);
			new skill_mithril=War3_GetSkillLevel(victim,thisRaceID,SKILL_MITHRIL);

			if(race_victim==thisRaceID) {
				if(skill_mithril>0){
					War3_DamageModPercent(MithRed[skill_mithril]);
					PrintToConsole(attacker, "Damage Reduced by Flying Machine");
					PrintToConsole(victim, "Damage Reduced by Flying Machine");
				}
			}
		}
	}
}

public OnW3TakeDmgAllPre(victim,attacker,Float:damage)
{
	if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim){
		new vteam=GetClientTeam(victim);
		new ateam=GetClientTeam(attacker);
		if(vteam!=ateam){
			new race_victim=War3_GetRace(victim);
			if(race_victim==thisRaceID){
				War3_ShakeScreen(victim,0.5,30.0,20.0);
			}
		}
	}
}

public Action:WeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid=GetEventInt(event,"userid");
	new index=GetClientOfUserId(userid);
	if(IsPlayerAlive(index)){
		if(War3_GetRace(index)==thisRaceID){
			new Float:pos[3];
			GetClientAbsOrigin(index,pos);
			pos[2]+=30;
			new target = War3_GetTargetInViewCone(index,9999.0,false,5.0);
			if(target>0){
				new Float:targpos[3];
				GetClientAbsOrigin(target,targpos);
				targpos[1]-=40;
				TE_SetupBeamPoints(pos, targpos, BeamSprite, HaloSprite, 0, 8, 0.5, 10.0, 10.0, 10, 10.0, {50,50,50,255}, 70); 
				TE_SendToAll();
				targpos[1]+=80;
				TE_SetupBeamPoints(pos, targpos, BeamSprite, HaloSprite, 0, 8, 0.5, 10.0, 10.0, 10, 10.0, {50,50,50,255}, 70); 
				TE_SendToAll();
				new flak_level=War3_GetSkillLevel(index,thisRaceID,SKILL_FLAK);
				War3_DealDamage(target,flak[flak_level],index,_,"Bombs",W3DMGORIGIN_SKILL,W3DMGTYPE_TRUEDMG);
				targpos[1]-=40;
				targpos[2]+=50;
				TE_SetupGlowSprite(targpos,BurnSprite,0.5,0.2,255);
				TE_SendToAll();
			}
			else
			{
				new Float:targpos[3];
				War3_GetAimEndPoint(index,targpos);
				targpos[1]+=40;
				TE_SetupBeamPoints(pos, targpos, BeamSprite, HaloSprite, 0, 8, 0.5, 10.0, 10.0, 10, 10.0, {50,50,50,255}, 70); 
				TE_SendToAll();
				targpos[2]+=50;
				TE_SetupGlowSprite(targpos,BurnSprite,0.5,0.2,255);
				TE_SendToAll();
				targpos[2]-=50;
				targpos[1]-=80;
				TE_SetupBeamPoints(pos, targpos, BeamSprite, HaloSprite, 0, 8, 0.5, 10.0, 10.0, 10, 10.0, {50,50,50,255}, 70); 
				TE_SendToAll();
				targpos[2]+=50;
				TE_SetupGlowSprite(targpos,BurnSprite,0.5,0.2,255);
				TE_SendToAll();
			}
		}
	}
}

public OnUltimateCommand(client,race,bool:pressed)
{
	if(ValidPlayer(client,true)&&pressed && race==thisRaceID){
		if(!Silenced(client)){
			new skill=War3_GetSkillLevel(client,thisRaceID,ULT_TURBO);
			if(skill>0){
				if(War3_SkillNotInCooldown(client,thisRaceID,ULT_TURBO,true)){
					new Float:velocity[3]={0.0,0.0,0.0};
					velocity[0]= GetEntDataFloat(client,m_vecVelocity_0);
					velocity[1]= GetEntDataFloat(client,m_vecVelocity_1);
					velocity[2]= GetEntDataFloat(client,m_vecVelocity_2);
					velocity[0]*=float(skill)*0.25;
					velocity[1]*=float(skill)*0.25;
					velocity[2]*=float(skill)*0.25;
					
					SetEntDataVector(client,m_vecBaseVelocity,velocity,true);
					War3_CooldownMGR(client,cooldown[skill],thisRaceID,ULT_TURBO,_,false);
				}
			}
			else
			{
				PrintHintText(client, "Level Turbo Charge first");
			}
		}
		else
		{
			PrintHintText(client, "Silenced!");
		}
	}
}