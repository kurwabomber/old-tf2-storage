#pragma semicolon 1
 
#include "W3SIncs/War3Source_Interface"
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <smlib>

public Plugin:myinfo = 
{
	name = "War3Source Race - Sasuke",
	author = "ABGar",
	description = "The Sasuke race for War3Source.",
	version = "1.0",
	// Godzace's Private Race Request - https://www.sevensinsgaming.com/forum/index.php?/topic/5631-sasuke/
}

new thisRaceID;

new SKILL_BLINK, SKILL_SPEED, SKILL_DAMAGE, ULT_SHARINGAN;

// SKILL_BLINK
new ClientTracer;
new absincarray[]={0,4,-4,8,-8,12,-12,18,-18,22,-22,25,-25};
new bool:inteleportcheck[MAXPLAYERSCUSTOM];
new Float:emptypos[3];
new Float:oldpos[MAXPLAYERSCUSTOM][3];
new Float:teleportpos[MAXPLAYERSCUSTOM][3];
new Float:TeleDistance=400.0;
new Float:TeleCD[]={0.0,15.0,12.0,10.0,8.0};
new String:TeleSound[]="war3source/blinkarrival.mp3";

// SKILL_SPEED
new Float:FeetSpeed[]={1.0,1.1,1.25,1.3,1.35};

// SKILL_DAMAGE
new ChidoriDamage[]={0,10,20,30,40};
new gTrail[MAXPLAYERSCUSTOM] = {-1,...};
new iDamageCount[MAXPLAYERSCUSTOM]={0, ...};
new bool:bInDamageMode[MAXPLAYERSCUSTOM]={false, ...};
new Float:ChidoriCD[]={0.0,30.0,25.0,20.0,15.0};
new String:ChidoriSound[]="npc/roller/mine/rmine_blades_out2.wav";
new String:SpriteTrail[]="materials/sprites/bluelaser1.vmt";

// ULT_SHARINGAN
new SharinganDamage[]={0,5,10,15,20};
new Float:SharinganRange=500.0;
new Float:SharinganDuration=1.5;
new Float:SharinganCD[]={0.0,40.0,30.0,20.0,15.0};
new Float:targetPos[MAXPLAYERSCUSTOM][3];
new String:SharinganSound[]="plats/train_use1.wav";


public OnWar3PluginReady()
{
	thisRaceID=War3_CreateNewRace("Sasuke [PRIVATE]","sasuke");
	SKILL_BLINK = War3_AddRaceSkill(thisRaceID,"Taikutstu Blink","Short Range Teleport (+ability)",false,4);
	SKILL_SPEED = War3_AddRaceSkill(thisRaceID,"Light Feet","Incrased Speed (passive)",false,4);
	SKILL_DAMAGE = War3_AddRaceSkill(thisRaceID,"Chidori","Bonus damage on your next attack (+ability1)",false,4);
	ULT_SHARINGAN=War3_AddRaceSkill(thisRaceID,"Sharingan","Teleport an enemy out of the map (+ultimate)",true,4);
	War3_CreateRaceEnd(thisRaceID);
	War3_AddSkillBuff(thisRaceID,SKILL_SPEED,fMaxSpeed,FeetSpeed);
}

public OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart);
}

public OnMapStart()
{
	War3_PrecacheSound(TeleSound);
	War3_PrecacheSound(ChidoriSound);
	War3_PrecacheSound(SharinganSound);
	PrecacheModel(SpriteTrail);
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
    for (new i=1; i<MaxClients; i++)
    {
        if (ValidPlayer(i,true) && War3_GetRace(i)==thisRaceID)
        {
            InitPassiveSkills(i);
        }
    }
}

public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace != thisRaceID)
	{
		War3_WeaponRestrictTo(client,thisRaceID,"");
		W3ResetAllBuffRace(client,thisRaceID);
		CS_UpdateClientModel(client);
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
	if(ValidPlayer(client,true) && War3_GetRace(client)==thisRaceID)
	{
		InitPassiveSkills(client);
	}
}

public InitPassiveSkills(client)
{
	War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife");
	iDamageCount[client]=0;
	bInDamageMode[client]=false;
	RemoveTrail(client);
}

/* *************************************** (SKILL_BLINK) *************************************** */
public Action:checkTeleport(Handle:h,any:client)
{
	inteleportcheck[client]=false;
	new Float:pos[3];		GetClientAbsOrigin(client,pos);
	
	if(GetVectorDistance(teleportpos[client],pos)<0.001)
	{
		TeleportEntity(client,oldpos[client],NULL_VECTOR,NULL_VECTOR);
		War3_CooldownReset(client,thisRaceID,SKILL_BLINK);
	}
}

bool:TeleportPlayerView(client,Float:distance,War3Immunity:check_immunity=Immunity_Ultimates)
{
	if(client>0)
	{
		if(IsPlayerAlive(client))
		{
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
			
			if(enemyImmunityInRange(client,endpos,check_immunity))
			{
				W3MsgEnemyHasImmunity(client);
				return false;
			}
			
			distance=GetVectorDistance(startpos,endpos);
			if(distance<50.0)
			{
				PrintHintText(client,"Distance too short.");
				return false;
			}
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
				PrintHintText(client,"No Empty Location");
				return false;
			}
			TeleportEntity(client,emptypos,NULL_VECTOR,NULL_VECTOR);
			
			EmitSoundToAll(TeleSound,client);
			
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

public bool:enemyImmunityInRange(client,Float:playerVec[3],War3Immunity:check_immunity)
{
	for(new i=1;i<=MaxClients;i++)
	{
		if(ValidPlayer(i,true) && GetClientTeam(i)!=GetClientTeam(client) && W3HasImmunity(i,check_immunity))
		{
			new Float:otherVec[3];		GetClientAbsOrigin(i,otherVec);
			if(GetVectorDistance(playerVec,otherVec)<300)
				return true;
		}
	}
	return false;
}  

public OnAbilityCommand(client,ability,bool:pressed)
{
	if(ValidPlayer(client,true) && War3_GetRace(client)==thisRaceID && pressed)
	{
		if(ability==0)
		{
			new TeleportLevel=War3_GetSkillLevel(client,thisRaceID,SKILL_BLINK);
			if(TeleportLevel>0)
			{			
				if(SkillAvailable(client,thisRaceID,SKILL_BLINK,true,true,true))
				{
					if(TeleportPlayerView(client,TeleDistance,Immunity_Skills))
					{	
						War3_CooldownMGR(client,TeleCD[TeleportLevel],thisRaceID,SKILL_BLINK,_,_);
					}
				}
			}	
			else
				PrintHintText(client,"Level your Taikutstu Blink first");
		}
/* *************************************** (SKILL_DAMAGE) *************************************** */		
		if(ability==1)
		{
			new DamageLevel=War3_GetSkillLevel(client,thisRaceID,SKILL_DAMAGE);
			if(DamageLevel>0)
			{
				if(iDamageCount[client]<3)
				{
					if(!bInDamageMode[client])
					{
						if(SkillAvailable(client,thisRaceID,SKILL_DAMAGE,true,true,true))
						{
							bInDamageMode[client]=true;
							iDamageCount[client]++;
							PrintHintText(client,"Chidori is now active...");
							CreateTrail(client);
						}
					}
					else
						PrintHintText(client,"You Chidori is already active");
				}
				else
					PrintHintText(client,"You have already used your Chidori three times this round");
			}
			else
				PrintHintText(client,"Level your Chidori first");
		}
	}
}

public OnW3TakeDmgBullet(victim,attacker,Float:damage)
{
	if(ValidPlayer(victim) && ValidPlayer(attacker) && GetClientTeam(attacker)!=GetClientTeam(victim))
	{
		if(War3_GetRace(attacker)==thisRaceID && bInDamageMode[attacker])
		{
			new DamageLevel=War3_GetSkillLevel(attacker,thisRaceID,SKILL_DAMAGE);
			if(DamageLevel>0)
			{
				War3_CooldownMGR(attacker,ChidoriCD[DamageLevel],thisRaceID,SKILL_DAMAGE,true,true);
				War3_DealDamage(victim,ChidoriDamage[DamageLevel],attacker,DMG_CRUSH,"chidori",_,W3DMGTYPE_MAGIC);
				W3EmitSoundToAll(ChidoriSound,attacker);
				W3FlashScreen(attacker,RGBA_COLOR_RED);
				bInDamageMode[attacker]=false;
				RemoveTrail(attacker);
			}
		}
	}
}

public CreateTrail(client)
{
	gTrail[client] = CreateEntityByName("env_spritetrail");
	if (IsValidEntity(gTrail[client])) 
	{
		new String:strClientName[MAX_NAME_LENGTH];
		GetClientName(client, strClientName, sizeof(strClientName));
		
		DispatchKeyValue(client, "targetname", strClientName);
		DispatchKeyValue(gTrail[client], "parentname", strClientName);
		DispatchKeyValue(gTrail[client], "lifetime", "1.0");
		DispatchKeyValue(gTrail[client], "endwidth", "30.0");
		DispatchKeyValue(gTrail[client], "startwidth", "70.0");
		DispatchKeyValue(gTrail[client], "spritename", SpriteTrail);
		DispatchKeyValue(gTrail[client], "renderamt", "255");
		DispatchKeyValue(gTrail[client], "rendercolor", "0 128 255");
		DispatchKeyValue(gTrail[client], "rendermode", "5");
		
		DispatchSpawn(gTrail[client]);
		
		new Float:Client_Origin[3];
		GetClientAbsOrigin(client, Client_Origin);
		Client_Origin[2]+=40.0;
		TeleportEntity(gTrail[client], Client_Origin, NULL_VECTOR, NULL_VECTOR);
		
		SetVariantString(strClientName);
		AcceptEntityInput(gTrail[client], "SetParent");
	}
}

public RemoveTrail(client)
{
	if (gTrail[client] != -1) 
	{
		RemoveEdict(gTrail[client]);
		gTrail[client] = -1;
	} 
}

public OnWar3EventDeath(victim,attacker)
{
	if(War3_GetRace(victim)==thisRaceID)
		RemoveTrail(victim);
}

/* *************************************** (ULT_SHARINGAN) *************************************** */
public OnUltimateCommand(client,race,bool:pressed)
{
	if(ValidPlayer(client,true) && race==thisRaceID && pressed)
	{
		new SharinganLevel=War3_GetSkillLevel(client,thisRaceID,ULT_SHARINGAN);
		if(SharinganLevel>0)
		{
			if(SkillAvailable(client,thisRaceID,ULT_SHARINGAN,true,true,true))
			{
				new target = War3_GetTargetInViewCone(client,SharinganRange,false,23.0);  // the 'false' indicates whether to include friendlies
				if(target>0 && UltFilter(target))
				{
					War3_CooldownMGR(client,SharinganCD[SharinganLevel],thisRaceID,ULT_SHARINGAN,true,true);
					new Float:tempPos[3]={0.0,0.0,900.0};
					GetClientAbsOrigin(target,targetPos[target]);
					
					TeleportEntity(target,tempPos,NULL_VECTOR,NULL_VECTOR);
					War3_SetBuff(target,bNoMoveMode,thisRaceID,true);
					War3_DealDamage(target,SharinganDamage[SharinganLevel],client,DMG_CRUSH,"sharingan",_,W3DMGTYPE_MAGIC);
					CreateTimer(SharinganDuration,StopSharingan,target);
					W3EmitSoundToAll(SharinganSound,client);
				}
			}
		}
		else
			W3MsgUltNotLeveled(client);
	}
}

public Action:StopSharingan(Handle:timer,any:client)
{
	if(ValidPlayer(client,true))
	{
		TeleportEntity(client,targetPos[client],NULL_VECTOR,NULL_VECTOR);
		War3_SetBuff(client,bNoMoveMode,thisRaceID,false);
	}
}

