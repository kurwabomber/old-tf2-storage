#pragma semicolon 1
 
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdkhooks>

public Plugin:myinfo = 
{
	name = "War3Source Race - Mad Eye Larkin",
	author = "ABGar",
	description = "The Mad Eye Larkin race for War3Source.",
	version = "1.0",
	// Ragnar's Private Race Request - www.sevensinsgaming.com/forum/index.php?/topic/5227-mad-eye-larkin-priv-race/
}

new thisRaceID;

new SKILL_CAMO, SKILL_SNEAKY, SKILL_HOTSHOT, ULT_TELEPORT;

// PASSIVES
new Float:CamoInvis[]={1.0,0.8,0.75,0.6,0.4};
new Float:SneakySpeed[]={1.0,1.1,1.2,1.3,1.4};
new Float:HotshotDamage[]={0.0,0.1,0.2,0.3,0.4};

// ULT_TELEPORT
new Float:TeleRD[]={0.0,800.0,825.0,850.0,875.0,900.0,925.0,950.0,975.0,1000.0};
new bool:inteleportcheck[MAXPLAYERS];
new ClientTracer;
new Float:emptypos[3];
new Float:oldpos[MAXPLAYERS][3];
new Float:teleportpos[MAXPLAYERS][3];
new absincarray[]={0,4,-4,8,-8,12,-12,18,-18,22,-22,25,-25};
new String:teleport_sound[]="war3source/archmage/teleport.wav";


public OnWar3PluginReady()
{
	thisRaceID=War3_CreateNewRace("Mad Eye Larkin [PRIVATE]","madeyelarkin");
	SKILL_CAMO = War3_AddRaceSkill(thisRaceID,"Camo Cloak","Stealth training makes Larks a sneaky target (passive)",false,4);
	SKILL_SNEAKY = War3_AddRaceSkill(thisRaceID,"Sneaky","Complete sneak training makes Larks very fast (passive)",false,4);
	SKILL_HOTSHOT = War3_AddRaceSkill(thisRaceID,"Hotshot","Larks is always carrying hotshot clips in his gun (passive)",false,4);
	ULT_TELEPORT=War3_AddRaceSkill(thisRaceID,"Ghost","Larks is so sneaky he can completely disappear (+ultimate)",false,4);
	War3_CreateRaceEnd(thisRaceID);
	War3_AddSkillBuff(thisRaceID, SKILL_CAMO, fInvisibilitySkill, CamoInvis);
	War3_AddSkillBuff(thisRaceID, SKILL_SNEAKY, fMaxSpeed, SneakySpeed);
	War3_AddSkillBuff(thisRaceID, SKILL_HOTSHOT, fDamageModifier, HotshotDamage);
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
	War3_WeaponRestrictTo(client, thisRaceID, "weapon_scout,weapon_knife");
	GivePlayerItem(client,"weapon_scout");
}

public OnMapStart()
{
	War3_PrecacheSound(teleport_sound);
}

/* *************************************** (ULT_TELEPORT) *************************************** */
public OnUltimateCommand(client,race,bool:pressed)
{
	if(race==thisRaceID && pressed && ValidPlayer(client,true))
	{
		if(SkillAvailable(client,thisRaceID,ULT_TELEPORT,true,true,true))
		{
			new ult_teleport=War3_GetSkillLevel(client,thisRaceID,ULT_TELEPORT);
			if(ult_teleport>0)
				TeleportPlayerView(client,TeleRD[ult_teleport]);
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
			
			if(enemyImmunityInRange(client,endpos))
			{
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

public Action:checkTeleport(Handle:h,any:client)
{
	inteleportcheck[client]=false;
	new Float:pos[3];	
	GetClientAbsOrigin(client,pos);
	
	if(GetVectorDistance(teleportpos[client],pos)<0.001)
	{
		TeleportEntity(client,oldpos[client],NULL_VECTOR,NULL_VECTOR);
	}
	else
	{	
		War3_CooldownMGR(client,20.0,thisRaceID,ULT_TELEPORT,_,_);
	}
}
public bool:AimTargetFilter(entity,mask)
{
	return !(entity==ClientTracer);
}

public bool:getEmptyLocationHull(client,Float:originalpos[3])
{
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
	if(entityhit == data )
	{
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

	for(new i=1;i<=MaxClients;i++)
	{
		if(ValidPlayer(i,true)&&GetClientTeam(i)!=team&&W3HasImmunity(i,Immunity_Ultimates))
		{
			GetClientAbsOrigin(i,otherVec);
			if(GetVectorDistance(playerVec,otherVec)<300){
				return true;
			}
		}
	}
	return false;
}      

