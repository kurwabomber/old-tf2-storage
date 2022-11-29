/**
* File: War3Source_Archmage.sp
* Description: Archmage race of warcraft.
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

//Blizzard
new Float:BlizTime[]={0.0,5.0,6.0,7.0,8.0,9.0,10.0,11.0,12.0,13.0};
new Float:BlizzardLocation[MAXPLAYERS][3];
new Float:IceLocation[MAXPLAYERS][3];
new String:blizzard_sound[]="war3source/archmage/blizzard.wav";
new String:blizzardloop_sound[]="war3source/archmage/blizzardloop.wav";
new BlizzardCLIENT[MAXPLAYERS];
new Float:BlizzardTimer[MAXPLAYERS];
new BeamSprite;

//Summon Water Elemental
new Float:SummonCD[]={0.0,40.0,39.0,37.0,36.0,34.0,33.0,32.0,31.0,30.0};
new String:summon_sound[]="war3source/archmage/summon.wav";

//Brilliance Aura
new HealAmount[]={0,1,1,1,2,2,2,3,3,3};
new Float:HealRD[]={0.0,100.0,125.0,150.0,175.0,200.0,225.0,250.0,275.0,300.0};

//Mass Teleport
new Float:TeleRD[]={0.0,800.0,825.0,850.0,875.0,900.0,925.0,950.0,975.0,1000.0};
new bool:inteleportcheck[MAXPLAYERS];
new ClientTracer;
new Float:emptypos[3];
new Float:oldpos[MAXPLAYERS][3];
new Float:teleportpos[MAXPLAYERS][3];
new absincarray[]={0,4,-4,8,-8,12,-12,18,-18,22,-22,25,-25};
new String:teleport_sound[]="war3source/archmage/teleport.wav";

new HaloSprite;

//Skills & Ultimate
new SKILL_BLIZZARD, SKILL_SUMMON, SKILL_AURA, ULT_TELEPORT;

public Plugin:myinfo = 
{
	name = "War3Source Race - Archmage",
	author = "Lucky",
	description = "Archmage race of warcraft",
	version = "1.0.1",
	url = ""
}

public OnPluginStart()
{
	CreateTimer(1.0,Blizzard,_,TIMER_REPEAT);
	CreateTimer(1.0,Aura,_,TIMER_REPEAT);	
}

public OnMapStart()
{
	War3_AddCustomSound(summon_sound);
	War3_AddCustomSound(teleport_sound);
	War3_AddCustomSound(blizzard_sound);
	War3_AddCustomSound(blizzardloop_sound);
	BeamSprite=PrecacheModel("materials/sprites/lgtning.vmt");
	HaloSprite=PrecacheModel("materials/sprites/halo01.vmt");
}

public OnWar3PluginReady()
{
	
		thisRaceID=War3_CreateNewRace("Archmage", "archmage");
		SKILL_BLIZZARD=War3_AddRaceSkill(thisRaceID,"Blizzard (Ability)", "Unleash an icestorm",false,9);
		SKILL_SUMMON=War3_AddRaceSkill(thisRaceID,"Summon Elemental (Ability1)","Raise a dead ally",false,9);
		SKILL_AURA=War3_AddRaceSkill(thisRaceID,"Brilliance Aura (Passive)","Heal your allies",false,9);
		ULT_TELEPORT=War3_AddRaceSkill(thisRaceID,"Know when to retreat","Teleport (+Ultimate)",true,9);
		War3_CreateRaceEnd(thisRaceID);
	
}

public OnRaceChanged(client, oldrace, newrace)
{
	if(newrace != thisRaceID){
		War3_WeaponRestrictTo(client,thisRaceID,"");
		W3ResetAllBuffRace(client,thisRaceID);
	}
	
	if(newrace == thisRaceID){
		War3_SetBuff(client,fMaxSpeed,thisRaceID,1.2);
	}
	
}

public OnWar3EventSpawn(client)
{	
	if(War3_GetRace(client)==thisRaceID){
		War3_SetBuff(client,fMaxSpeed,thisRaceID,1.2);
		BlizzardTimer[client]=0.0;
	}
	
}

public OnWar3EventDeath(victim,attacker)
{
	new race_victim=War3_GetRace(victim);
	if(race_victim==thisRaceID){
		BlizzardTimer[victim]=0.0;
	}
}

public OnAbilityCommand(client,ability,bool:pressed)
{
	if(!Silenced(client)){
		new skill_blizzard=War3_GetSkillLevel(client,thisRaceID,SKILL_BLIZZARD);
		new skill_summon=War3_GetSkillLevel(client,thisRaceID,SKILL_SUMMON);
		
		if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && IsPlayerAlive(client)){
			if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_BLIZZARD,true)){
				if(skill_blizzard>0){
					War3_CooldownMGR(client,15.0,thisRaceID,SKILL_BLIZZARD);
					EmitSoundToAll(blizzardloop_sound,client);
					BlizzardCLIENT[client]=client;
					BlizzardTimer[client]=BlizTime[skill_blizzard];
					new Float:clientpos[3];
					GetClientAbsOrigin(client,clientpos);
					clientpos[0]+=50.0;
					clientpos[1]+=50.0;
					clientpos[2]+=999.0;
					IceLocation[client][0]=clientpos[0];
					IceLocation[client][1]=clientpos[1];
					IceLocation[client][2]=clientpos[2];
					new target = War3_GetTargetInViewCone(client,1000.0,false,20.0);
					
					if(target>0){
						GetClientAbsOrigin(target,BlizzardLocation[client]);	
					}
					else
					{
						War3_GetAimTraceMaxLen(client,BlizzardLocation[client],1000.0);
					}
					
					new Float:ranPos1[3];
					new Float:ranPos2[3];
					new Float:ranPos3[3];
					new Float:ranPos4[3];
					ranPos1[1]=GetRandomFloat((BlizzardLocation[client][1]-150.0),(BlizzardLocation[client][1]+150.0));
					ranPos1[0]=GetRandomFloat((BlizzardLocation[client][0]-150.0),(BlizzardLocation[client][0]+150.0));
					ranPos1[2]=BlizzardLocation[client][2];
					TE_SetupBeamPoints(ranPos1,IceLocation[client],HaloSprite,BeamSprite,0,1,1.0,10.0,5.0,0,1.0,{0,0,255,255},50);
					TE_SendToAll();
					TE_SetupBeamRingPoint(ranPos1, 0.0, 75.0, BeamSprite, BeamSprite, 0, 5, 1.0, 50.0, 1.0, {0,0,255,255}, 50, 0);
					TE_SendToAll();
					ranPos2[1]=GetRandomFloat((BlizzardLocation[client][1]-150.0),(BlizzardLocation[client][1]+150.0));
					ranPos2[0]=GetRandomFloat((BlizzardLocation[client][0]-150.0),(BlizzardLocation[client][0]+150.0));
					ranPos2[2]=BlizzardLocation[client][2];
					TE_SetupBeamPoints(ranPos2,IceLocation[client],HaloSprite,BeamSprite,0,1,1.0,10.0,5.0,0,1.0,{0,0,255,255},50);
					TE_SendToAll();
					TE_SetupBeamRingPoint(ranPos2, 0.0, 75.0, BeamSprite, BeamSprite, 0, 5, 1.0, 50.0, 1.0, {0,0,255,255}, 50, 0);
					TE_SendToAll();
					ranPos3[1]=GetRandomFloat((BlizzardLocation[client][1]-150.0),(BlizzardLocation[client][1]+150.0));
					ranPos3[0]=GetRandomFloat((BlizzardLocation[client][0]-150.0),(BlizzardLocation[client][0]+150.0));
					ranPos3[2]=BlizzardLocation[client][2];
					TE_SetupBeamPoints(ranPos3,IceLocation[client],HaloSprite,BeamSprite,0,1,1.0,10.0,5.0,0,1.0,{0,0,255,255},50);
					TE_SendToAll();
					TE_SetupBeamRingPoint(ranPos3, 0.0, 75.0, BeamSprite, BeamSprite, 0, 5, 1.0, 50.0, 1.0, {0,0,255,255}, 50, 0);
					TE_SendToAll();
					ranPos4[1]=GetRandomFloat((BlizzardLocation[client][1]-150.0),(BlizzardLocation[client][1]+150.0));
					ranPos4[0]=GetRandomFloat((BlizzardLocation[client][0]-150.0),(BlizzardLocation[client][0]+150.0));
					ranPos4[2]=BlizzardLocation[client][2];
					TE_SetupBeamPoints(ranPos4,IceLocation[client],HaloSprite,BeamSprite,0,1,1.0,10.0,5.0,0,1.0,{0,0,255,255},50);
					TE_SendToAll();	
					TE_SetupBeamRingPoint(ranPos4, 0.0, 75.0, BeamSprite, BeamSprite, 0, 5, 1.0, 50.0, 1.0, {0,0,255,255}, 50, 0);
					TE_SendToAll();
				}
				else
				{
					PrintHintText(client, "Level Blizzard first");
				}	
			}
		}
		
		if(War3_GetRace(client)==thisRaceID && ability==1 && pressed && IsPlayerAlive(client)){
			if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_SUMMON,true)){
				if(skill_summon>0){
					new Float:position111[3];
					War3_CachedPosition(client,position111);
					position111[2]+=5.0;
					new targets[MAXPLAYERS];
					new foundtargets;
					for(new ally=1;ally<=MaxClients;ally++){
						if(ValidPlayer(ally)){
							new ally_team=GetClientTeam(ally);
							new client_team=GetClientTeam(client);
							if(War3_GetRace(ally)!=thisRaceID && !IsPlayerAlive(ally) && ally_team==client_team){
								targets[foundtargets]=ally;
								foundtargets++;
							}
						}
					}
					new target;
					if(foundtargets>0){
						target=targets[GetRandomInt(0, foundtargets-1)];
						if(target>0){
							War3_CooldownMGR(client,SummonCD[skill_summon],thisRaceID,SKILL_SUMMON);
							new Float:ang[3];
							new Float:pos[3];
							War3_SpawnPlayer(target);
							GetClientEyeAngles(client,ang);
							GetClientAbsOrigin(client,pos);
							TeleportEntity(target,pos,ang,NULL_VECTOR);
							CreateTimer(3.0,normal,target);
							CreateTimer(3.0,normal,client);
							EmitSoundToAll(summon_sound,client);
							CreateTimer(3.0, Stop, client);
						}
					}
					else
					{
						PrintHintText(client,"There are no allies you can rez");
					}
				}
				else
				{
					PrintHintText(client, "Level your Summon first");
				}
			}
		}
		
	}
	else
	{
		PrintHintText(client,"Silenced: Can not cast");
	}
	
}

public Action:Stop(Handle:timer,any:client)
{
	StopSound(client,SNDCHAN_AUTO,summon_sound);
}

public Action:normal(Handle:timer,any:client)
{
	if(ValidPlayer(client,true))
	{
		new Float:end_dist=50.0;
		new Float:end_pos[3];
		GetClientAbsOrigin(client,end_pos);
		for(new i=1;i<=MaxClients;i++)
		{
			if(ValidPlayer(i,true)&&i!=client)
			{
				new Float:pos[3];
				GetClientAbsOrigin(i,pos);
				new Float:dist=GetVectorDistance(end_pos,pos);
				if(dist<=end_dist)
				{
					CreateTimer(1.0,normal,client);
					break;
				}
			}
		}
	}
}

public Action:Blizzard(Handle:timer,any:userid)
{
	for(new x=1;x<=MaxClients;x++){
		if(ValidPlayer(x,true)){
			if(War3_GetRace(x)==thisRaceID){
				new client=BlizzardCLIENT[x];
				new Float:victimPos[3];
				if(BlizzardLocation[client][0]==0.0&&BlizzardLocation[client][1]==0.0&&BlizzardLocation[client][2]==0.0){
				}
				else 
				{
					if(BlizzardTimer[client]>1.0){
						BlizzardTimer[client]--;
						new ownerteam=GetClientTeam(client);
						
						new Float:ranPos1[3];
						new Float:ranPos2[3];
						new Float:ranPos3[3];
						new Float:ranPos4[3];
						ranPos1[1]=GetRandomFloat((BlizzardLocation[client][1]-150.0),(BlizzardLocation[client][1]+150.0));
						ranPos1[0]=GetRandomFloat((BlizzardLocation[client][0]-150.0),(BlizzardLocation[client][0]+150.0));
						ranPos1[2]=BlizzardLocation[client][2];
						TE_SetupBeamPoints(ranPos1,IceLocation[client],HaloSprite,BeamSprite,0,1,1.0,10.0,5.0,0,1.0,{0,0,255,255},50);
						TE_SendToAll();	
						TE_SetupBeamRingPoint(ranPos1, 0.0, 75.0, BeamSprite, BeamSprite, 0, 5, 1.0, 50.0, 1.0, {0,0,255,255}, 50, 0);
						TE_SendToAll();
						ranPos2[1]=GetRandomFloat((BlizzardLocation[client][1]-150.0),(BlizzardLocation[client][1]+150.0));
						ranPos2[0]=GetRandomFloat((BlizzardLocation[client][0]-150.0),(BlizzardLocation[client][0]+150.0));
						ranPos2[2]=BlizzardLocation[client][2];
						TE_SetupBeamPoints(ranPos2,IceLocation[client],HaloSprite,BeamSprite,0,1,1.0,10.0,5.0,0,1.0,{0,0,255,255},50);
						TE_SendToAll();	
						TE_SetupBeamRingPoint(ranPos2, 0.0, 75.0, BeamSprite, BeamSprite, 0, 5, 1.0, 50.0, 1.0, {0,0,255,255}, 50, 0);
						TE_SendToAll();
						ranPos3[1]=GetRandomFloat((BlizzardLocation[client][1]-150.0),(BlizzardLocation[client][1]+150.0));
						ranPos3[0]=GetRandomFloat((BlizzardLocation[client][0]-150.0),(BlizzardLocation[client][0]+150.0));
						ranPos3[2]=BlizzardLocation[client][2];
						TE_SetupBeamPoints(ranPos3,IceLocation[client],HaloSprite,BeamSprite,0,1,1.0,10.0,5.0,0,1.0,{0,0,255,255},50);
						TE_SendToAll();	
						TE_SetupBeamRingPoint(ranPos3, 0.0, 75.0, BeamSprite, BeamSprite, 0, 5, 1.0, 50.0, 1.0, {0,0,255,255}, 50, 0);
						TE_SendToAll();
						ranPos4[1]=GetRandomFloat((BlizzardLocation[client][1]-150.0),(BlizzardLocation[client][1]+150.0));
						ranPos4[0]=GetRandomFloat((BlizzardLocation[client][0]-150.0),(BlizzardLocation[client][0]+150.0));
						ranPos4[2]=BlizzardLocation[client][2];
						TE_SetupBeamPoints(ranPos4,IceLocation[client],HaloSprite,BeamSprite,0,1,1.0,10.0,5.0,0,1.0,{0,0,255,255},50);
						TE_SendToAll();	
						TE_SetupBeamRingPoint(ranPos4, 0.0, 75.0, BeamSprite, BeamSprite, 0, 5, 1.0, 50.0, 1.0, {0,0,255,255}, 50, 0);
						TE_SendToAll();
						
						for (new i=1;i<=MaxClients;i++){
							if(ValidPlayer(i,true)&& GetClientTeam(i)!=ownerteam){
								GetClientAbsOrigin(i,victimPos);
								if(GetVectorDistance(BlizzardLocation[client],victimPos)<300.0){
									if(!W3HasImmunity(i,Immunity_Skills)){
										W3FlashScreen(i,{0,0,255,50});
										War3_DealDamage(i,4,client,DMG_BULLET,"Blizzard");
										War3_SetBuff(i,fSlow,thisRaceID,0.8);
										CreateTimer(0.9,slow,i);
										
										TE_SetupBeamPoints(IceLocation[client],victimPos,BeamSprite,BeamSprite,0,1,1.0,10.0,5.0,0,1.0,{0,0,255,255},50);
										TE_SendToAll();	
										TE_SetupBeamRingPoint(victimPos, 0.0, 75.0, BeamSprite, BeamSprite, 0, 5, 1.0, 50.0, 1.0, {0,0,255,255}, 50, 0);
										TE_SendToAll();
										
										EmitSoundToAll(blizzard_sound,i);
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

public Action:slow(Handle:timer,any:victim)
{
	War3_SetBuff(victim,fSlow,thisRaceID,1.0);
}

public Action:Aura(Handle:timer,any:userid)
{
	for(new client=1;client<=MaxClients;client++){
		if(ValidPlayer(client,true)){
			if(War3_GetRace(client)==thisRaceID){
				new skill_aura=War3_GetSkillLevel(client,thisRaceID,SKILL_AURA);
				new ownerteam=GetClientTeam(client);
				new Float:allyPos[3];
				new Float:clientPos[3];
				GetClientAbsOrigin(client,clientPos);
				if(skill_aura>0){
					War3_HealToMaxHP(client,2);
					for (new ally=1;ally<=MaxClients;ally++){
						if(ValidPlayer(ally,true)&& GetClientTeam(ally)==ownerteam&&ally!=client){
							GetClientAbsOrigin(ally,allyPos);
							if(GetVectorDistance(clientPos,allyPos)<HealRD[skill_aura]){
								War3_HealToMaxHP(ally,HealAmount[skill_aura]);
							}
						}
					}
				}
			}
		}
	}
}

public OnUltimateCommand(client,race,bool:pressed)
{
	if(race==thisRaceID && pressed && ValidPlayer(client,true)){
		if(!Silenced(client)){
			if(War3_SkillNotInCooldown(client,thisRaceID,ULT_TELEPORT,true)){
				new ult_teleport=War3_GetSkillLevel(client,thisRaceID,ULT_TELEPORT);
				if(ult_teleport>0){
					TeleportPlayerView(client,TeleRD[ult_teleport]);
				}
				else
				{
					PrintHintText(client, "Level your Teleport first");
				}
			}
		}	
		else
		{
			PrintHintText(client, "You are silenced!");
		}
	}
}

bool:TeleportPlayerView(client,Float:distance)
{
	if(client>0){
		if(IsPlayerAlive(client)){
			new Float:angle[3];
			GetClientEyeAngles(client,angle);
			new Float:endpos[3];
			new Float:startpos[3];
			GetClientEyePosition(client,startpos);
			new Float:dir[3];
			GetAngleVectors(angle, dir, NULL_VECTOR, NULL_VECTOR);
			ScaleVector(dir, distance);
			AddVectors(startpos, dir, endpos);
			GetClientAbsOrigin(client,oldpos[client]);
			ClientTracer=client;
			TR_TraceRayFilter(startpos,endpos,MASK_ALL,RayType_EndPoint,AimTargetFilter);
			TR_GetEndPosition(endpos);			
			
			if(enemyImmunityInRange(client,endpos)){
				W3MsgEnemyHasImmunity(client);
				return false;
			}
			distance=GetVectorDistance(startpos,endpos);
			GetAngleVectors(angle, dir, NULL_VECTOR, NULL_VECTOR);
			ScaleVector(dir, distance-33.0);
			AddVectors(startpos,dir,endpos);
			emptypos[0]=0.0;
			emptypos[1]=0.0;
			emptypos[2]=0.0;
			endpos[2]-=30.0;
			getEmptyLocationHull(client,endpos);
			if(GetVectorLength(emptypos)<1.0){
				//new String:buffer[100];
				//Format(buffer, sizeof(buffer), "%T", "NoEmptyLocation", client);
				PrintHintText(client, "No Empty Location");
				return false;
			}
			TeleportEntity(client,emptypos,NULL_VECTOR,NULL_VECTOR);
			EmitSoundToAll(teleport_sound,client);	
			teleportpos[client][0]=emptypos[0];
			teleportpos[client][1]=emptypos[1];
			teleportpos[client][2]=emptypos[2];
			inteleportcheck[client]=true;
			CreateTimer(0.14,checkTeleport,client);			
			return true;
		}
	}
	return false;
}

public Action:checkTeleport(Handle:h,any:client){
	inteleportcheck[client]=false;
	new Float:pos[3];	
	GetClientAbsOrigin(client,pos);
	
	if(GetVectorDistance(teleportpos[client],pos)<0.001){
		TeleportEntity(client,oldpos[client],NULL_VECTOR,NULL_VECTOR);
	}
	else
	{	
		War3_CooldownMGR(client,20.0,thisRaceID,ULT_TELEPORT);
	}
}
public bool:AimTargetFilter(entity,mask)
{
	return !(entity==ClientTracer);
}

public bool:getEmptyLocationHull(client,Float:originalpos[3]){
	new Float:mins[3];
	new Float:maxs[3];
	GetClientMins(client,mins);
	GetClientMaxs(client,maxs);
	new absincarraysize=sizeof(absincarray);
	new limit=5000;
	for(new x=0;x<absincarraysize;x++){
		if(limit>0){
			for(new y=0;y<=x;y++){
				if(limit>0){
					for(new z=0;z<=y;z++){
						new Float:pos[3]={0.0,0.0,0.0};
						AddVectors(pos,originalpos,pos);
						pos[0]+=float(absincarray[x]);
						pos[1]+=float(absincarray[y]);
						pos[2]+=float(absincarray[z]);
						
						TR_TraceHullFilter(pos,pos,mins,maxs,MASK_SOLID,CanHitThis,client);
						if(TR_DidHit(_)){
						}
						else
						{
							AddVectors(emptypos,pos,emptypos);
							limit=-1;
							break;
						}
					
						if(limit--<0){
							break;
						}
					}
					
					if(limit--<0){
						break;
					}
				}
			}
			
			if(limit--<0){
				break;
			}
			
		}
		
	}

} 

public bool:CanHitThis(entityhit, mask, any:data)
{
	if(entityhit == data ){
		return false;
	}
	if(ValidPlayer(entityhit)&&ValidPlayer(data)&&War3_GetGame()==Game_TF&&GetClientTeam(entityhit)==GetClientTeam(data)){
		return false;
	}
	return true;
}


public bool:enemyImmunityInRange(client,Float:playerVec[3])
{
	new Float:otherVec[3];
	new team = GetClientTeam(client);

	for(new i=1;i<=MaxClients;i++){
		if(ValidPlayer(i,true)&&GetClientTeam(i)!=team&&W3HasImmunity(i,Immunity_Ultimates)){
			GetClientAbsOrigin(i,otherVec);
			if(GetVectorDistance(playerVec,otherVec)<300){
				return true;
			}
		}
	}
	return false;
}             
