#pragma semicolon 1
 
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdkhooks>

public Plugin:myinfo = 
{
	name = "War3Source Race - Laser Troll",
	author = "ABGar",
	description = "The Laser Troll race for War3Source.",
	version = "1.0",
	// ABGar / Campalot's Private Race - www.sevensinsgaming.com/forum/index.php?/topic/5448-laser-troll
}

new thisRaceID;

new SKILL_LASER, SKILL_CAMO, SKILL_FEDUP, ULT_TELE;

// SKILL_LASER
new HaloSprite, BeamSprite;
new LaserDamage=10;
new Float:LaserCD=5.0;
new Float:LaserRange=600.0;
new Float:DrugDuration[]={0.0,2.0,3.0,4.0,5.0};
new Float:StunDuration[]={0.0,0.5,1.0,1.5,2.0};
new bool:bLasered[MAXPLAYERSCUSTOM];
new String:LaserSound[]= "buttons/button10.wav";

// SKILL_CAMO
new bool:InInvis[MAXPLAYERSCUSTOM];
new Float:CamoCD[]={0.0,30.0,25.0,20.0,15.0};
new String:InvisOnSound[]= "npc/scanner/scanner_nearmiss1.wav";
new String:InvisOffSound[]= "npc/scanner/scanner_nearmiss2.wav";

// SKILL_FEDUP
new Skydome;
new FedupHeal=50;
new Float:FedupCD=10.0;
new Float:FedupChance[]={0.0,0.25,0.35,0.5,0.7};



// ULT_TELE
new ClientTracer;
new absincarray[]={0,4,-4,8,-8,12,-12,18,-18,22,-22,25,-25};
new bool:inteleportcheck[MAXPLAYERS];
new Float:emptypos[3];
new Float:oldpos[MAXPLAYERS][3];
new Float:teleportpos[MAXPLAYERS][3];
new Float:TeleDistance[]={0.0,700.0,800.0,900.0,1000.0};
new Float:TeleCD[]={0.0,50.0,40.0,30.0,5.0};
new String:TeleSound[]="war3source/blinkarrival.mp3";


public OnWar3PluginReady()
{
	thisRaceID=War3_CreateNewRace("Laser Troll [PRIVATE]","lasertroll");
	SKILL_LASER = War3_AddRaceSkill(thisRaceID,"Laser Gun"," From the shadows, you shoot lasers at your enemy having a 50% to stun or drug. (+ability)\nCan only be used while in Camouflage mode",false,4);
	SKILL_CAMO = War3_AddRaceSkill(thisRaceID,"Camouflage","Camouflage yourself from the enemy so you can use your laser (+ability1)",false,4);
	SKILL_FEDUP = War3_AddRaceSkill(thisRaceID,"Fed Up","Chance to gain 50HP when you kill someone (passive)",false,4);
	ULT_TELE=War3_AddRaceSkill(thisRaceID,"Teleport","Teleport in front of you (+ultimate)",true,4);
	War3_CreateRaceEnd(thisRaceID);
}


public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace != thisRaceID)
	{
		War3_WeaponRestrictTo(client,thisRaceID,"");
		W3ResetAllBuffRace(client,thisRaceID);
	}
	else
	{
		if (ValidPlayer(client,true))
        {
			InitPassiveSkills(client);
		}
	}
}

public OnWar3EventSpawn(client)
{
	if(War3_GetRace(client)==thisRaceID)
	{
		InitPassiveSkills(client);
	}
}

public InitPassiveSkills(client)
{
	War3_WeaponRestrictTo(client, thisRaceID, "weapon_knife");
	InInvis[client]=false;
	War3_SetBuff(client,fMaxSpeed,thisRaceID,1.2);
	War3_SetBuff(client,bDisarm,thisRaceID,false);
	War3_SetBuff(client,bNoMoveMode,thisRaceID,false);
}

public OnMapStart()
{
	Skydome=PrecacheModel("models/props_combine/portalskydome.mdl");
	BeamSprite=PrecacheModel("materials/sprites/lgtning.vmt");
	HaloSprite=PrecacheModel("materials/sprites/halo01.vmt");
	War3_PrecacheSound(InvisOnSound);
	War3_PrecacheSound(InvisOffSound);
	War3_PrecacheSound(LaserSound);
	War3_PrecacheSound(TeleSound);
}

/* *************************************** (SKILL_CAMO) *************************************** */
public EndInvis(client)
{
	InInvis[client]=false;
	War3_SetBuff(client,fInvisibilitySkill,thisRaceID,1.0);
	War3_SetBuff(client,bDisarm,thisRaceID,false);
	War3_SetBuff(client,bNoMoveMode,thisRaceID,false);
	EmitSoundToAll(InvisOffSound,client);
}

public OnAbilityCommand(client,ability,bool:pressed)
{
    if(War3_GetRace(client)==thisRaceID &&  pressed && IsPlayerAlive(client))
    {
		if(ability==1)
		{
			new CamoLevel=War3_GetSkillLevel(client,thisRaceID,SKILL_CAMO);
			if(CamoLevel>0)
			{
				if(InInvis[client])
					EndInvis(client);
			
				else if(SkillAvailable(client,thisRaceID,SKILL_CAMO,true,true,true))
				{
					War3_SetBuff(client,fInvisibilitySkill,thisRaceID,0.00);
					War3_SetBuff(client,bDisarm,thisRaceID,true);
					War3_SetBuff(client,bNoMoveMode,thisRaceID,true);
					InInvis[client]=true;
					War3_CooldownMGR(client,CamoCD[CamoLevel],thisRaceID,SKILL_CAMO, _, _);
					EmitSoundToAll(InvisOnSound,client);
				}
			}   
		}
/* *************************************** (SKILL_LASER) *************************************** */
		else if(ability==0)
		{
			new LaserLevel = War3_GetSkillLevel(client,thisRaceID,SKILL_LASER);
			if(LaserLevel > 0)
			{
				if(SkillAvailable(client,thisRaceID,SKILL_LASER,true,true,true))
				{
					if(InInvis[client])
					{
						new target = War3_GetTargetInViewCone(client,LaserRange,false,20.0);
						if(target>0 && SkillFilter(target))
						{
							new Float:clientPos[3];		GetClientAbsOrigin(client, clientPos);		clientPos[2]+=35;
							new Float:targetPos[3];		GetClientAbsOrigin(target, targetPos);		targetPos[2]+=35;
							
							War3_CooldownMGR(client,LaserCD,thisRaceID,SKILL_LASER,_,_);
							EmitSoundToAll(LaserSound,client);
							bLasered[target]=true;
							
							if(W3Chance(0.5))
							{
								W3FlashScreen(client,RGBA_COLOR_GREEN);
								TE_SetupBeamPoints(targetPos,clientPos,BeamSprite,HaloSprite,0,35,0.5,6.0,5.0,0,1.0,{0,255,0,255},20);
								TE_SendToAll();
								War3_SetBuff(target,bBashed,thisRaceID,true);
								War3_DealDamage(target,LaserDamage,client,DMG_BULLET,"laser");
								CreateTimer(StunDuration[LaserLevel],EndLaserStun,target);
								PrintHintText(client,"Laser Stun");
								PrintHintText(target,"Stunned by Laser");
							}
							else
							{
								W3FlashScreen(client,RGBA_COLOR_RED);
								TE_SetupBeamPoints(targetPos,clientPos,BeamSprite,HaloSprite,0,35,0.5,6.0,5.0,0,1.0,{255,0,0,255},20);
								TE_SendToAll();
								ClientCommand(target, "r_screenoverlay effects/tp_eyefx/tp_eyefx.vmt");
								War3_DealDamage(target,LaserDamage,client,DMG_BULLET,"laser");
								CreateTimer(DrugDuration[LaserLevel],EndLaserDrug,target);
								PrintHintText(client,"Laser Drug");
								PrintHintText(target,"Drugged by Laser");
							}
						}
						else
							W3MsgNoTargetFound(client);
					}
					else
						PrintHintText(client,"You must be in Camouflage mode to use your lasers");
				}
			}
			else
				PrintHintText(client,"Level your Laser Gun first");
		}
	}
}

public Action:EndLaserStun(Handle:timer,any:client)
{
	if(ValidPlayer(client) && bLasered[client])
	{
		W3ResetAllBuffRace(client,thisRaceID);
	}
}

public Action:EndLaserDrug(Handle:timer,any:client)
{
	if(ValidPlayer(client) && bLasered[client])
	{
		ClientCommand(client, "r_screenoverlay 0");
	}
}

/* *************************************** (SKILL_FEDUP) *************************************** */
public OnWar3EventDeath(victim,attacker)
{
	if(GetClientTeam(attacker)!=GetClientTeam(victim))
	{
		if(War3_GetRace(attacker)==thisRaceID && !Silenced(attacker))
		{
			new FedupLevel=War3_GetSkillLevel(attacker,thisRaceID,SKILL_FEDUP);
			if(FedupLevel>0)
			{
				if(SkillAvailable(attacker,thisRaceID,SKILL_FEDUP,true,true))
				{
					if(W3Chance(FedupChance[FedupLevel]))
					{
						War3_HealToMaxHP(attacker,FedupHeal);
						W3FlashScreen(attacker,RGBA_COLOR_RED,1.2);
						new Float:fVec[3] = {0.0,0.0,900.0};
						TE_SetupGlowSprite(fVec,Skydome,5.0,1.0,255);
						TE_SendToAll();
						CreateTesla(victim,1.0,3.0,10.0,60.0,3.0,4.0,600.0,"160","200","255 25 25","ambient/atmosphere/city_skypass1.wav","sprites/tp_beam001.vmt",true);
						PrintHintText(attacker,"You gained health from your kill");
						War3_CooldownMGR(attacker,FedupCD,thisRaceID,SKILL_FEDUP,true,true);
					}
				}
			}
		}
	}
}

/* *************************************** (ULT_TELE) *************************************** */
public OnUltimateCommand(client,race,bool:pressed)
{
	if(race==thisRaceID && pressed && ValidPlayer(client,true))
	{
		if(SkillAvailable(client,thisRaceID,ULT_TELE,true,true,true))
		{
			new TeleportLevel=War3_GetSkillLevel(client,thisRaceID,ULT_TELE);
			if(TeleportLevel>0)
			{
				if(InInvis[client])
					PrintHintText(client,"You can't teleport while in Camouflage mode");
				else
					TeleportPlayerView(client,TeleDistance[TeleportLevel]);
			}
			else
				W3MsgUltNotLeveled(client);
		}	
	}
}

bool:TeleportPlayerView(client,Float:distance)
{
	if(client>0)
	{
		if(IsPlayerAlive(client))
		{
			new TeleLevel=War3_GetSkillLevel(client,thisRaceID,ULT_TELE);
			War3_CooldownMGR(client,TeleCD[TeleLevel],thisRaceID,ULT_TELE,_,_);
			
			new Float:angle[3];			GetClientEyeAngles(client,angle);
			new Float:startpos[3];		GetClientEyePosition(client,startpos);
			new Float:endpos[3];
			new Float:dir[3];
			
			GetAngleVectors(angle, dir, NULL_VECTOR, NULL_VECTOR);
			ScaleVector(dir, distance);
			AddVectors(startpos, dir, endpos);
			GetClientAbsOrigin(client,oldpos[client]);
			
			ClientTracer=client;
			TR_TraceRayFilter(startpos,endpos,MASK_ALL,RayType_EndPoint,AimTargetFilter);
			TR_GetEndPosition(endpos);			
			
			if(enemyImmunityInRange(client,endpos))
			{
				War3_CooldownReset(client,thisRaceID,ULT_TELE);
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
			
			if(GetVectorLength(emptypos)<1.0)
			{
				new String:buffer[100];
				Format(buffer, sizeof(buffer), "", "NoEmptyLocation", client);
				PrintHintText(client,buffer);
				War3_CooldownReset(client,thisRaceID,ULT_TELE);
				return false;
			}
			TeleportEntity(client,emptypos,NULL_VECTOR,NULL_VECTOR);
			
			EmitSoundToAll(TeleSound,client);
			
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

public Action:checkTeleport(Handle:h,any:client)
{
	inteleportcheck[client]=false;
	new Float:pos[3];		GetClientAbsOrigin(client,pos);
	
	if(GetVectorDistance(teleportpos[client],pos)<0.001)
	{
		TeleportEntity(client,oldpos[client],NULL_VECTOR,NULL_VECTOR);
		War3_CooldownReset(client,thisRaceID,ULT_TELE);
	}
	else
	{	
		
	}
}
public bool:AimTargetFilter(entity,mask)
{
	return !(entity==ClientTracer);
}

public bool:getEmptyLocationHull(client,Float:originalpos[3])
{
	new Float:mins[3];		GetClientMins(client,mins);
	new Float:maxs[3];		GetClientMaxs(client,maxs);
	
	new absincarraysize=sizeof(absincarray);
	new limit=5000;
	for(new x=0;x<absincarraysize;x++)
	{
		if(limit>0)
		{
			for(new y=0;y<=x;y++)
			{
				if(limit>0)
				{
					for(new z=0;z<=y;z++)
					{
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
	if(entityhit == data )
		return false;

	if(ValidPlayer(entityhit) && ValidPlayer(data) && War3_GetGame()==Game_TF && GetClientTeam(entityhit)==GetClientTeam(data))
		return false;

	return true;
}


public bool:enemyImmunityInRange(client,Float:playerVec[3])
{
	for(new i=1;i<=MaxClients;i++)
	{
		if(ValidPlayer(i,true) && GetClientTeam(i)!=GetClientTeam(client) && W3HasImmunity(i,Immunity_Ultimates))
		{
			new Float:otherVec[3];		GetClientAbsOrigin(i,otherVec);
			if(GetVectorDistance(playerVec,otherVec)<300)
				return true;
		}
	}
	return false;
}  
