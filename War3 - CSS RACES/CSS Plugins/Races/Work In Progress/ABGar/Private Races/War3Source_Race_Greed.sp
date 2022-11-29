#pragma semicolon 1
 
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdkhooks>

public Plugin:myinfo = 
{
	name = "War3Source Race - Greed",
	author = "ABGar",
	description = "The Greed race for War3Source.",
	version = "1.0",
	// Greed's Private Race Request - www.sevensinsgaming.com/forum/index.php?/topic/5132-greed-private/ 
}

new thisRaceID;

new SKILL_FLASH, SKILL_BLINK, SKILL_SPEED, ULT_OVERLOAD;

// SKILL_BLINK
new ClientTracer;
new Float:BlinkRange=300.0;
new Float:teleCD[]={0.0,15.0,13.0,11.0,9.0,7.0};
new Float:emptypos[3];
new Float:oldpos[MAXPLAYERS][3];
new Float:teleportpos[MAXPLAYERS][3];
new bool:inteleportcheck[MAXPLAYERS];
new absincarray[]={0,4,-4,8,-8,12,-12,18,-18,22,-22,25,-25};
new String:teleport_sound[]="war3source/blinkarrival.wav";

// SKILL_SPEED
new Float:GreedSpeed[]={1.0,1.05,1.1,1.15,1.2,1.25};

// ULT_OVERLOAD
new BeamSprite,HaloSprite; 
new OverloadZapsRemaining[MAXPLAYERSCUSTOM];
new OverloadDamagePerHit[]={0,3,6,8,9,10};
new TotalOverloadZaps[]={0,24,28,32,48,60}; // 4 zaps per second
new Float:OverloadCD[]={0.0,56.0,52.0,48.0,47.0,40.0}; // CD + Duration
new String:overload1[]="war3source/cd/overload2.mp3";
new String:overloadzap[]="war3source/cd/overloadzap.mp3";
new String:overloadstate[]="war3source/cd/ultstate.mp3";

new Float:UltimateRange=350.0;

public OnWar3PluginReady()
{
	thisRaceID=War3_CreateNewRace("Greed [Private]","greed");
	SKILL_FLASH = War3_AddRaceSkill(thisRaceID,"Flash","Flash in and out of view (passive)",false,1);
	SKILL_BLINK = War3_AddRaceSkill(thisRaceID,"Blink","Small range teleport (+ability)",false,5);
	SKILL_SPEED = War3_AddRaceSkill(thisRaceID,"Speed","Extra speed (passive)",false,5);
	ULT_OVERLOAD=War3_AddRaceSkill(thisRaceID,"Overload","Shocks the lowest hp enemy around you per second while you gain damage per hit (+ultimate)",false,5);
	War3_CreateRaceEnd(thisRaceID);
	War3_AddSkillBuff(thisRaceID,SKILL_SPEED,fMaxSpeed,GreedSpeed);
	W3SkillCooldownOnSpawn(thisRaceID,ULT_OVERLOAD,15.0,_);
}

public OnMapStart()
{
	War3_PrecacheSound(teleport_sound);
	War3_PrecacheSound(overload1);
	War3_PrecacheSound(overloadzap);
	War3_PrecacheSound(overloadstate);
	BeamSprite=War3_PrecacheBeamSprite();
	HaloSprite=War3_PrecacheHaloSprite();
}

public OnRaceChanged(client,oldrace,newrace)
{
	if( newrace != thisRaceID )
	{
		War3_WeaponRestrictTo(client, thisRaceID, "");
		W3ResetAllBuffRace( client, thisRaceID );
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
		new skill_level=War3_GetSkillLevel(client,thisRaceID,SKILL_FLASH);
		if(skill_level>0)
		{
			InitPassiveSkills(client);
		}
	}
}

public OnSkillLevelChanged( client, race, skill, newskilllevel )
{
	InitPassiveSkills(client);
}

public InitPassiveSkills(client)
{
	OverloadZapsRemaining[client]=0;
	War3_WeaponRestrictTo(client, thisRaceID, "weapon_knife,weapon_hegrenade,weapon_smokegrenade,weapon_flashbang");
	new FlashLevel=War3_GetSkillLevel(client,thisRaceID,SKILL_FLASH);
	if(FlashLevel>0)
		SetEntityRenderFx( client, RENDERFX_FLICKER_FAST );
}

/* *************************************** (SKILL_BLINK) *************************************** */
public OnAbilityCommand(client,ability,bool:pressed)
{
	if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && ValidPlayer(client,true))
	{
		if(SkillAvailable(client,thisRaceID,SKILL_BLINK,true,true,true))
		{
			new ult_teleport=War3_GetSkillLevel(client,thisRaceID,SKILL_BLINK);
			if(ult_teleport>0)
				TeleportPlayerView(client,BlinkRange);
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
			new BlinkLevel=War3_GetSkillLevel(client,thisRaceID,SKILL_BLINK);
			
			War3_CooldownMGR(client,teleCD[BlinkLevel],thisRaceID,SKILL_BLINK,_,_);
			new Float:angle[3];					GetClientEyeAngles(client,angle);
			new Float:startpos[3];				GetClientEyePosition(client,startpos);
			new Float:dir[3];					GetAngleVectors(angle, dir, NULL_VECTOR, NULL_VECTOR);
			new Float:endpos[3];
			
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
						if(!TR_DidHit(_))
						{
							AddVectors(emptypos,pos,emptypos);
							limit=-1;
							break;
						}
					
						if(limit--<0)
							break;
					}
					
					if(limit--<0)
						break;
				}
			}
			if(limit--<0)
				break;
		}	
	}
} 

public bool:CanHitThis(entityhit, mask, any:data)
{
	if(entityhit == data )
	{
		return false;
	}
	if(ValidPlayer(entityhit)&&ValidPlayer(data)&&War3_GetGame()==Game_TF&&GetClientTeam(entityhit)==GetClientTeam(data))
	{
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
			if(GetVectorDistance(playerVec,otherVec)<300)
			{
				return true;
			}
		}
	}
	return false;
}  

/* *************************************** (ULT_OVERLOAD) *************************************** */
public OnUltimateCommand(client,race,bool:pressed)
{
	if(race==thisRaceID && pressed && ValidPlayer(client,true))
	{
		new OverloadLevel=War3_GetSkillLevel(client,thisRaceID,ULT_OVERLOAD);
		if(OverloadLevel>0)
		{
			if(SkillAvailable(client,thisRaceID,ULT_OVERLOAD,true,true,true))
			{
				War3_CooldownMGR(client,OverloadCD[OverloadLevel],thisRaceID,ULT_OVERLOAD,_,_);
				OverloadZapsRemaining[client]=TotalOverloadZaps[OverloadLevel];
				CreateTimer(0.25,UltimateLoop,client);
				
				EmitSoundToAll(overload1,client);               
				EmitSoundToAll(overloadstate,client);
				CreateTimer(3.7,UltStateSound,client);
			}
			
		}
		else
			W3MsgUltNotLeveled(client);
	}
}

public Action:UltStateSound(Handle:t,any:client)
{
	if(ValidPlayer(client,true) && OverloadZapsRemaining[client]>0)
	{
		EmitSoundToAll(overloadstate,client);
		CreateTimer(3.7,UltStateSound,client);
	}
}

public Action:UltimateLoop(Handle:timer,any:client)
{
	if(ValidPlayer(client,true) && OverloadZapsRemaining[client]>0)
	{
		new OverloadLevel=War3_GetSkillLevel(client,thisRaceID,ULT_OVERLOAD);
		OverloadZapsRemaining[client]--;
		new Float:pos[3];					GetClientEyePosition(client,pos);
		new Float:otherpos[3];
		new lowesthp=99999;
		new besttarget=0;

		for(new i=1;i<=MaxClients;i++)
		{
			if(ValidPlayer(i,true))
			{
				if(GetClientTeam(i)!=GetClientTeam(client) && UltFilter(i))
				{
					GetClientAbsOrigin(i,otherpos);
					if(GetVectorDistance(pos,otherpos)<UltimateRange)
					{
						new Float:distanceVec[3];		SubtractVectors(otherpos,pos,distanceVec);
						new Float:angles[3];			GetVectorAngles(distanceVec,angles);
						
						TR_TraceRayFilter(pos, angles, MASK_PLAYERSOLID, RayType_Infinite, CanHitThis,client);
						new ent;
						if(TR_DidHit(_))
							ent=TR_GetEntityIndex(_);
						
						if(ent==i && GetClientHealth(i)<lowesthp)
						{
							besttarget=i;
							lowesthp=GetClientHealth(i);
						}
					}
				}
			}
		}
		if(besttarget>0)
		{
			pos[2]-=15.0;
			GetClientEyePosition(besttarget,otherpos); 
			otherpos[2]-=20.0;
			TE_SetupBeamPoints(pos,otherpos,BeamSprite,HaloSprite,0,35,0.15,6.0,5.0,0,1.0,{255,000,255,255},20);
			TE_SendToAll();
			War3_DealDamage(besttarget,OverloadDamagePerHit[OverloadLevel],client,_,"overload");
			EmitSoundToAll(overloadzap,client);
			EmitSoundToAll(overloadzap,besttarget);
			
		}
		CreateTimer(0.25,UltimateLoop,client);
	}
	else
		OverloadZapsRemaining[client]=0;
}


































