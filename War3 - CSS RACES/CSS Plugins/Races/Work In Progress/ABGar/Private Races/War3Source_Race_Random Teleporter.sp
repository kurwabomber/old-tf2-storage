#pragma semicolon 1
 
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdkhooks>

public Plugin:myinfo = 
{
	name = "War3Source Race - Random Teleporter",
	author = "ABGar",
	description = "The Random Teleporter race for War3Source.",
	version = "1.0",
	// ABGar / Campalot's Private Race - http://www.sevensinsgaming.com/forum/index.php?/topic/5449-random-teleporter
}

new thisRaceID;

new SKILL_MOVEMENT, SKILL_FIRE, SKILL_MASTERY, ULT_TIMEBOMB;

// SKILL_MOVEMENT
new Float:RunFast[]={1.0,1.1,1.2,1.3,1.4};

// SKILL_FIRE
new Float:FireInvis[]={1.00,0.85,0.7,0.55,0.4};
new Float:FireWalkRange[]={0.0,150.0,180.0,220.0,250.0};

// SKILL_MASTERY
new Float:DamageModifier=2.0;
new Float:MasteryChance[]={0.0,0.2,0.3,0.4,0.5};
new String:MasterySound[]={"npc/roller/mine/rmine_blades_out2.wav"};

// ULT_TIMEBOMB
new g_iExplosionModel,g_iSmokeModel,ClientTracer;
new ExplodeDamage=40;
new ExplodeSelfDmg=10;
new absincarray[]={0,4,-4,8,-8,12,-12,18,-18,22,-22,25,-25};
new bool:inteleportcheck[MAXPLAYERS];
new Handle:ExplodeTimer; 
new Float:emptypos[3];
new Float:position[3];
new Float:oldpos[MAXPLAYERS][3];
new Float:teleportpos[MAXPLAYERS][3];
new Float:TimeBombRadius=150.0;
new Float:TeleCD[]={0.0,20.0,15.0,10.0,5.0};
new Float:TeleDistance[]={0.0,700.0,800.0,900.0,1000.0};
new String:TeleportSound[]="war3source/blinkarrival.mp3";
new String:ExplodeSound[]="weapons/explode5.wav";


public OnWar3PluginReady()
{
	thisRaceID=War3_CreateNewRace("Random Teleporter [PRIVATE]","ranteleporter");
	SKILL_MOVEMENT = War3_AddRaceSkill(thisRaceID,"Superior Movement","Teleporter's speed increases (passive)",false,4);
	SKILL_FIRE = War3_AddRaceSkill(thisRaceID,"Fire Walk","You run around partially invisible, but on fire, damaging enemies around you (passive)",false,4);
	SKILL_MASTERY = War3_AddRaceSkill(thisRaceID,"Superior Dual Dagger Mastery","You have a chance for double damage on an attack (passive)",false,4);
	ULT_TIMEBOMB=War3_AddRaceSkill(thisRaceID,"Time Bomb","Randomly teleport and blow up... damaging yourself and any nearby enemies (+ultimate) \nTeleport to an enemy if one's within range, or teleport straight in front",true,4);
	War3_CreateRaceEnd(thisRaceID);
	W3SkillCooldownOnSpawn(thisRaceID,ULT_TIMEBOMB,15.0,_);
	War3_AddSkillBuff(thisRaceID, SKILL_MOVEMENT, fMaxSpeed, RunFast);
	War3_AddSkillBuff(thisRaceID, SKILL_FIRE, fInvisibilitySkill, FireInvis);
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

public OnSkillLevelChanged(client, race, skill, newskilllevel)
{
	
}

public InitPassiveSkills(client)
{
	War3_WeaponRestrictTo(client, thisRaceID, "weapon_knife"); 
	CreateTimer(1.0,FireWalk,client);
}

public OnPluginStart()
{
	CreateTimer(1.0,Immolation,_,TIMER_REPEAT);
}

public OnClientPutInServer(client) 
{ 
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage); 
} 

public OnMapStart()
{
	g_iExplosionModel = PrecacheModel("materials/effects/fire_cloud1.vmt");
	g_iSmokeModel = PrecacheModel("materials/effects/fire_cloud2.vmt");
	War3_PrecacheSound(MasterySound);	
	War3_PrecacheSound(TeleportSound);
	War3_PrecacheSound(ExplodeSound);
}

/* *************************************** (SKILL_FIRE) *************************************** */
public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if(War3_GetRace(victim)==thisRaceID)
	{
		new String:Classname[16];
		GetEdictClassname(inflictor, Classname, sizeof(Classname));
		if (StrEqual(Classname, "env_fire", false))
			return Plugin_Handled;
		else
			return Plugin_Continue;
	}
	else
		return Plugin_Continue;
}

public Action:FireWalk(Handle:timer,any:client)
{
	if(War3_GetRace(client)==thisRaceID && IsPlayerAlive(client))
    {
		new fire_level = War3_GetSkillLevel(client,thisRaceID,SKILL_FIRE);
		if(fire_level>0)
		{
			new Float:pos[3];
			GetClientAbsOrigin(client,pos);
			new fire = CreateEntityByName("env_fire");
			SetEntPropEnt(fire, Prop_Send, "m_hOwnerEntity", client);
			DispatchKeyValue(fire, "firesize", "50");
			DispatchKeyValue(fire, "health", "5");
			DispatchKeyValue(fire, "firetype", "Normal");
			DispatchKeyValue(fire, "damagescale", "0.0");
			DispatchKeyValue(fire, "spawnflags", "256");
			SetVariantString("WaterSurfaceExplosion");
			AcceptEntityInput(fire, "DispatchEffect"); 
			DispatchSpawn(fire);
			TeleportEntity(fire, pos, NULL_VECTOR, NULL_VECTOR);
			AcceptEntityInput(fire, "StartFire");
			SetVariantString("!activator");
			AcceptEntityInput(fire, "SetParent", client);
			DispatchKeyValue(fire, "extinguish", "5.0");
			CreateTimer(5.0,FireWalk,client);
			
		}
		else
			CreateTimer(5.0,FireWalk,client);
	}
}

public Action:Immolation(Handle:timer,any:userid)
{
	for(new client=1;client<=MaxClients;client++)
	{
		if(ValidPlayer(client,true) && War3_GetRace(client)==thisRaceID)
		{
			new FireLevel=War3_GetSkillLevel(client,thisRaceID,SKILL_FIRE);
			new Float:clientPos[3];		GetClientAbsOrigin(client,clientPos);
			new Float:enemyPos[3];
		
			if(FireLevel>0)
			{
				for (new enemy=1;enemy<=MaxClients;enemy++)
				{
					if(ValidPlayer(enemy,true) && GetClientTeam(enemy)!=GetClientTeam(client) && SkillFilter(enemy))
					{
						GetClientAbsOrigin(enemy,enemyPos);
						if(GetVectorDistance(clientPos,enemyPos)<=FireWalkRange[FireLevel])
							IgniteEntity(enemy,0.2);
						else
							ExtinguishEntity(enemy);
					}
				}
			}
		}
	}
}

/* *************************************** (SKILL_MASTERY) *************************************** */
public OnW3TakeDmgBulletPre(victim,attacker,Float:damage)
{
	if(ValidPlayer(victim) && ValidPlayer(attacker) && GetClientTeam(attacker)!=GetClientTeam(victim))
	{
		if(War3_GetRace(attacker)==thisRaceID)
		{
			new MasteryLevel = War3_GetSkillLevel(attacker,thisRaceID,SKILL_MASTERY);
			if(MasteryLevel>0)
			{
				if(W3Chance(MasteryChance[MasteryLevel]))
				{
					War3_DamageModPercent(DamageModifier);
					EmitSoundToAll(MasterySound,victim);
					W3FlashScreen(victim,RGBA_COLOR_RED);
				}
			}
		}
	}
}

/* *************************************** (ULT_TIMEBOMB) *************************************** */
public OnUltimateCommand(client,race,bool:pressed)
{
	if(ValidPlayer(client,true) && race==thisRaceID && pressed)
	{
		new TimebombLevel=War3_GetSkillLevel(client,thisRaceID,ULT_TIMEBOMB);
		if(TimebombLevel>0)
		{
			if(SkillAvailable(client,thisRaceID,ULT_TIMEBOMB,true,true,true))
			{
				new Float:ClientPos[3];		GetClientAbsOrigin(client,ClientPos);
				new Float:TargetPos[3];
				new Float:bestTargetDistance=TeleDistance[TimebombLevel]; 
				new bestTarget=0;
				
				for(new i=1;i<=MaxClients;i++)
				{
					if(ValidPlayer(i,true) && GetClientTeam(i)!=GetClientTeam(client) && UltFilter(client))
					{
						GetClientAbsOrigin(i,TargetPos);
						new Float:dist=GetVectorDistance(ClientPos,TargetPos);
						if(dist<bestTargetDistance && dist<TeleDistance[TimebombLevel])
						{
							bestTarget=i;
							bestTargetDistance=GetVectorDistance(ClientPos,TargetPos);
						}
					}
				}
				
				if(bestTarget==0)
					TeleportPlayerView(client,TeleDistance[TimebombLevel]);
					
				else
				{
					War3_CachedPosition(bestTarget, position);
					TeleportEntity(client,position,NULL_VECTOR,NULL_VECTOR);
					EmitSoundToAll(TeleportSound,client);
					War3_CooldownMGR(client,TeleCD[TimebombLevel],thisRaceID,ULT_TIMEBOMB,_,_);
					War3_SetBuff(client,bStunned,thisRaceID,true);
					CreateTimer(1.0,Explode,client);
				}
			}
		}
		else
			W3MsgUltNotLeveled(client);
	}
}

bool:TeleportPlayerView(client,Float:distance)
{
	if(client>0)
	{
		if(IsPlayerAlive(client))
		{
			new TeleLevel=War3_GetSkillLevel(client,thisRaceID,ULT_TIMEBOMB);
			War3_CooldownMGR(client,TeleCD[TeleLevel],thisRaceID,ULT_TIMEBOMB,_,_);
			
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
				War3_CooldownReset(client,thisRaceID,ULT_TIMEBOMB);
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
				War3_CooldownReset(client,thisRaceID,ULT_TIMEBOMB);
				return false;
			}
			TeleportEntity(client,emptypos,NULL_VECTOR,NULL_VECTOR);
			War3_SetBuff(client,bStunned,thisRaceID,true);
			ExplodeTimer = CreateTimer(1.0,Explode,client);
			
			EmitSoundToAll(TeleportSound,client);
			
			teleportpos[client][0]=emptypos[0];
			teleportpos[client][1]=emptypos[1];
			teleportpos[client][2]=emptypos[2];
			
			inteleportcheck[client]=true;
			CreateTimer(0.1,checkTeleport,client);			
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
		War3_CooldownReset(client,thisRaceID,ULT_TIMEBOMB);
		War3_SetBuff(client,bStunned,thisRaceID,false);
		KillTimer(ExplodeTimer);
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

public Action:Explode(Handle:timer,any:client)
{
	if(ValidPlayer(client,true) && War3_GetRace(client)==thisRaceID)
	{
		EmitSoundToAll(ExplodeSound,client);
		
		new Float:clientpos[3];		GetClientAbsOrigin(client, clientpos);
		new Float:enemypos[3];
		
		TE_SetupExplosion(clientpos, g_iExplosionModel, 20.0, 10, TE_EXPLFLAG_NONE, 200, 125);
		TE_SendToAll();
		TE_SetupSmoke(clientpos, g_iExplosionModel, 70.0, 2);
		TE_SendToAll();
		TE_SetupSmoke(clientpos, g_iSmokeModel, 70.0, 2);
		TE_SendToAll();

		War3_DealDamage(client,ExplodeSelfDmg,client,DMG_CRUSH,"time bomb",_,W3DMGTYPE_MAGIC);
		War3_SetBuff(client,bStunned,thisRaceID,false);
		
		for(new enemy=1;enemy<=MaxClients;++enemy)
		{
			if(ValidPlayer(enemy,true) && GetClientTeam(enemy)!=GetClientTeam(client) && UltFilter(enemy))
			{
				GetClientAbsOrigin(enemy, enemypos);
				new Float:Distance=GetVectorDistance(enemypos,clientpos);
				if(Distance<=TimeBombRadius)
				{
					new Float:factor=(TimeBombRadius-Distance)/TimeBombRadius;
					new damage=RoundFloat(ExplodeDamage*factor);
					War3_DealDamage(enemy,damage,client,_,"time bomb",W3DMGORIGIN_ULTIMATE,W3DMGTYPE_PHYSICAL);    
				
					War3_ShakeScreen(enemy,2.0*factor,100.0*factor,20.0);
					W3FlashScreen(enemy,RGBA_COLOR_RED);
				}
			}
		}
	}
}
