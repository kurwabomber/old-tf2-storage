#pragma semicolon 1
 
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdkhooks>
#include <smlib>

public Plugin:myinfo = 
{
	name = "War3Source Race - Diablo2 Sorceress",
	author = "ABGar",
	description = "The Diablo2 Sorceress race for War3Source.",
	version = "1.0",
}

new thisRaceID;

new SKILL_ARMOUR, SKILL_THUNDER, SKILL_METEOR, ULT_TELEPORT;

// SKILL_ARMOUR
new BeamSprite,HaloSprite,LaseSprite; 
new Float:ArmourSlowSpeed=0.7;
new Float:ArmourReturnPercentDmg=20.0;
new Float:ArmourSlowDuration[]={0.0,1.0,1.5,2.0,2.5};
new Float:ArmourChance[]={0.0,0.25,0.5,0.75,1.0};
new Float:ChillChance[]={0.0,0.05,0.1,0.15,0.2};
new String:ChillSound[]="war3source/d2sorceress/chilltouch.wav";

// SKILL_THUNDER
new iStormCycles;
new StormDamageAmount[]={0,4,6,8,10};
new Float:ThunderCD=30.0;
new Float:StormLoc[MAXPLAYERS][3];
new Float:StormRange=300.0;
new String:LightningSound[]="war3source/cd/overloadzap.mp3";
new String:ThunderLoopSound[]="war3source/d2sorceress/thunderloop.wav";

// SKILL_METEOR
new ExploModel,SmokeModel;
new Float:MeteorAimRange=700.0;
new Float:MeteorImpactDelay=4.0;
new Float:MeteorLocation[MAXPLAYERSCUSTOM][3];
new Float:MeteorDamage[]={0.0,60.0,80.0,100.0,120.0};
new Float:MeteorRadius[]={0.0,150.0,190.0,240.0,300.0};
new Float:MeteorCD[]={0.0,60.0,55.0,50.0,45.0};
new String:MeteorLaunchSound[]="war3source/d2sorceress/meteorlaunch.wav";
new String:MeteorImpactSound[]="war3source/d2sorceress/meteorimpact.wav";

// ULT_TELEPORT
new ClientTracer;
new absincarray[]={0,4,-4,8,-8,12,-12,18,-18,22,-22,25,-25};
new bool:inteleportcheck[MAXPLAYERS];
new Float:emptypos[3];
new Float:oldpos[MAXPLAYERS][3];
new Float:teleportpos[MAXPLAYERS][3];
new Float:TeleDistance[]={0.0,400.0,600.0,800.0,1000.0};
new Float:TeleCD[]={0.0,50.0,40.0,35.0,30.0};
new String:TeleSound[]="war3source/d2sorceress/teleport.wav";

public OnWar3PluginReady()
{
	thisRaceID=War3_CreateNewRace("Diablo2 Sorceress","d2sorceress");
	SKILL_ARMOUR = War3_AddRaceSkill(thisRaceID,"Chilling Armour","A sorceress learned in this art can manifest the fear of her foes into an impenterable armour, that will freeze enemies to their core (passive) \n Spawn with 100 armour, and have a chance to return cold damage and slow enemies",false,4);
	SKILL_THUNDER = War3_AddRaceSkill(thisRaceID,"Thunderstorm","A Sorceress learned in this skill may manifest a tempest of dark storm clouds that follow her wherever she travels. (+ability)\n Spawn an area of smoke that will shock nearby enemies",false,4);
	SKILL_METEOR = War3_AddRaceSkill(thisRaceID,"Meteor","Reaching out to the heavens, the Sorceress calls down a falling star to strike her adversaries (+ability1) \n Mark a spot on the ground that will send a meteor to damaeg enemies after 4 seconds",false,4);
	ULT_TELEPORT=War3_AddRaceSkill(thisRaceID,"Teleport","A Sorceress trained in this arcane skill has the ability to traverse the Ether, instantly rematerializing in another location (+ultimate) \n Teleport up to 1000 units in distance",true,4);
	War3_CreateRaceEnd(thisRaceID);
	W3SkillCooldownOnSpawn(thisRaceID,SKILL_THUNDER,10.0,_);
	W3SkillCooldownOnSpawn(thisRaceID,SKILL_METEOR,10.0,_);
	W3SkillCooldownOnSpawn(thisRaceID,ULT_TELEPORT,10.0,_);
}

public OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart);
	HookEvent("smokegrenade_detonate", smokegrenade_detonate);
}

public OnMapStart()
{
	AddFileToDownloadsTable("sound/war3source/d2sorceress/chilltouch.wav");
	AddFileToDownloadsTable("sound/war3source/d2sorceress/thunderloop.wav");
	AddFileToDownloadsTable("sound/war3source/d2sorceress/meteorlaunch.wav");
	AddFileToDownloadsTable("sound/war3source/d2sorceress/meteorimpact.wav");
	AddFileToDownloadsTable("sound/war3source/d2sorceress/teleport.wav");
	War3_PrecacheSound(ChillSound);
	War3_PrecacheSound(LightningSound);
	War3_PrecacheSound(ThunderLoopSound);
	War3_PrecacheSound(MeteorLaunchSound);
	War3_PrecacheSound(MeteorImpactSound);
	War3_PrecacheSound(TeleSound);
	BeamSprite=PrecacheModel("materials/sprites/lgtning.vmt");
	HaloSprite=PrecacheModel("materials/sprites/halo01.vmt");
	LaseSprite=PrecacheModel("materials/sprites/laser.vmt");
	ExploModel=PrecacheModel("materials/effects/fire_cloud1.vmt");
	SmokeModel=PrecacheModel("materials/effects/fire_cloud2.vmt");
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
	War3_WeaponRestrictTo(client,thisRaceID,"weapon_scout,weapon_usp,weapon_knife");
	CreateTimer(0.5,GiveWep,client);
	CheckArmour(client);
}

public Action:GiveWep(Handle:timer,any:client)
{
	if(ValidPlayer(client,true) && War3_GetRace(client)==thisRaceID)
	{
		if(!Client_HasWeapon(client,"weapon_scout"))
			GivePlayerItem(client,"weapon_scout");
		if(!Client_HasWeapon(client,"weapon_usp"))
			GivePlayerItem(client,"weapon_usp");
	}
}
/* *************************************** (SKILL_ARMOUR) *************************************** */
public CheckArmour(client)
{
	if(ValidPlayer(client,true) && War3_GetRace(client)==thisRaceID)
	{
		new ArmourLevel=War3_GetSkillLevel(client,thisRaceID,SKILL_ARMOUR);
		if(ArmourLevel>0)
		{
			if(W3Chance(ArmourChance[ArmourLevel]))
				GivePlayerItem(client,"item_assaultsuit");
		}
	}
}

public OnW3TakeDmgBullet(victim,attacker,Float:damage)
{
	if(ValidPlayer(victim) && ValidPlayer(attacker) && GetClientTeam(attacker)!=GetClientTeam(victim))
	{
		if(War3_GetRace(victim)==thisRaceID)
		{
			new ArmourLevel = War3_GetSkillLevel(victim,thisRaceID,SKILL_ARMOUR);
			if(ArmourLevel>0 && SkillFilter(attacker))
			{
				if(W3Chance(ChillChance[ArmourLevel]))
				{
					new iDamage=RoundToFloor(damage*ArmourReturnPercentDmg);
					if(iDamage>40)	iDamage=40;
					War3_DealDamage(attacker,iDamage,victim,DMG_CRUSH,"chilling armour",_,W3DMGTYPE_MAGIC);
					War3_SetBuff(attacker,fSlow,thisRaceID,ArmourSlowSpeed);
					CreateTimer(ArmourSlowDuration[ArmourLevel],StopSlow,attacker);
					new Float:victimPos[3];		GetClientAbsOrigin(victim,victimPos);		victimPos[2]+=40.0;
					new Float:attackerPos[3];	GetClientAbsOrigin(attacker,attackerPos);	attackerPos[2]+=40.0;
					TE_SetupBeamPoints(victimPos,attackerPos,BeamSprite,HaloSprite,0,35,1.0,20.0,20.0,0,1.0,{134,178,236,255},20);
					TE_SendToAll();
					EmitSoundToAll(ChillSound,attacker);
					EmitSoundToAll(ChillSound,victim);
				}
			}
		}
	}
}

public Action:StopSlow(Handle:timer,any:client)
{
	if(ValidPlayer(client,true))
	{
		W3ResetBuffRace(client,fSlow,thisRaceID);
	}
}
/* *************************************** (SKILL_THUNDER) *************************************** */
public smokegrenade_detonate(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(War3_GetRace(client)==thisRaceID)
	{
		new ThunderLevel=War3_GetSkillLevel(client,thisRaceID,SKILL_THUNDER);
		if(ThunderLevel>0)
		{
			EmitSoundToAll(ThunderLoopSound,client);
			iStormCycles=0;
			new Float:a[3], Float:b[3];
			a[0] = GetEventFloat(event, "x");
			a[1] = GetEventFloat(event, "y");
			a[2] = GetEventFloat(event, "z");
			StormLoc[client][0]=a[0];
			StormLoc[client][1]=a[1];
			StormLoc[client][2]=a[2]+30.0;
			
			new checkok = 0;
			new ent = -1;
			while((ent = FindEntityByClassname(ent, "env_particlesmokegrenade")) != -1)
			{
				GetEntPropVector(ent, Prop_Send, "m_vecOrigin", b);
				if(a[0] == b[0] && a[1] == b[1] && a[2] == b[2])
				{		
					checkok = 1;
					break;
				}
			}
			
			if (checkok == 1)
			{
				new iEntity = CreateEntityByName("light_dynamic");
				if (iEntity != -1)
				{
					new iRef = EntIndexToEntRef(iEntity);
					decl String:sBuffer[64];
					//DispatchKeyValue(iEntity, "_light", "0 255 0");
					DispatchKeyValue(iEntity, "_light", "83 101 125");
					Format(sBuffer, sizeof(sBuffer), "smokelight_%d", iEntity);
					DispatchKeyValue(iEntity,"targetname", sBuffer);
					Format(sBuffer, sizeof(sBuffer), "%f %f %f", a[0], a[1], a[2]);
					DispatchKeyValue(iEntity, "origin", sBuffer);
					DispatchKeyValue(iEntity, "iEntity", "-90 0 0");
					DispatchKeyValue(iEntity, "pitch","-90");
					DispatchKeyValue(iEntity, "distance","256");
					DispatchKeyValue(iEntity, "spotlight_radius","96");
					DispatchKeyValue(iEntity, "brightness","3");
					DispatchKeyValue(iEntity, "style","6");
					DispatchKeyValue(iEntity, "spawnflags","1");
					DispatchSpawn(iEntity);
					AcceptEntityInput(iEntity, "DisableShadow");
					AcceptEntityInput(iEntity, "TurnOn");
					CreateTimer(0.5,StormDamage,client);
					CreateTimer(17.0,DeleteLight,iRef,TIMER_FLAG_NO_MAPCHANGE);
					CreateTimer(17.0,StopThunderSound,client);
					War3_WeaponRestrictTo(client,thisRaceID,"weapon_scout,weapon_usp,weapon_knife");
				}
			}
		}
	}
}

public Action:StormDamage(Handle:timer,any:client)
{
	if(ValidPlayer(client,true) && War3_GetRace(client)==thisRaceID && iStormCycles<=11)
	{
		iStormCycles++;
		new StormLevel=War3_GetSkillLevel(client,thisRaceID,SKILL_THUNDER);
		for (new enemy=1;enemy<=MaxClients;enemy++)
		{
			if(ValidPlayer(enemy,true) && GetClientTeam(enemy)!=GetClientTeam(client) && SkillFilter(enemy))
			{
				new Float:enemyPos[3];	GetClientAbsOrigin(enemy,enemyPos);		enemyPos[2]+=30.0;
				if(GetVectorDistance(enemyPos,StormLoc[client])<=StormRange)
				{
					War3_DealDamage(enemy,StormDamageAmount[StormLevel],client,DMG_CRUSH,"thunderstorm",_,W3DMGTYPE_MAGIC);
					TE_SetupBeamPoints(StormLoc[client],enemyPos,BeamSprite,HaloSprite,0,35,0.5,6.0,5.0,0,1.0,{255,255,255,255},20);
					TE_SendToAll();
					EmitSoundToAll(LightningSound,enemy);
				}
			}
		}
		CreateTimer(1.5,StormDamage,client);
	}
}

public Action:DeleteLight(Handle:timer, any:iRef)
{
	new entity= EntRefToEntIndex(iRef);
	if (entity != INVALID_ENT_REFERENCE)
	{
		if (IsValidEdict(entity)) AcceptEntityInput(entity, "kill");
	}
}

public Action:StopThunderSound(Handle:timer,any:client)
{
	StopSound(client,SNDCHAN_AUTO,ThunderLoopSound);
}

public Action:DropNade(Handle:timer,any:client)
{
	War3_WeaponRestrictTo(client,thisRaceID,"weapon_scout,weapon_usp,weapon_knife");
}

public OnAbilityCommand(client,ability,bool:pressed)
{
	if(ValidPlayer(client,true) && War3_GetRace(client)==thisRaceID && pressed)
	{
		if(ability==0)
		{
			new ThunderLevel=War3_GetSkillLevel(client,thisRaceID,SKILL_THUNDER);
			if(ThunderLevel>0)
			{
				if(SkillAvailable(client,thisRaceID,SKILL_THUNDER,true,true,true))
				{
					War3_CooldownMGR(client,ThunderCD,thisRaceID,SKILL_THUNDER,true,true);
					War3_WeaponRestrictTo(client, thisRaceID, "weapon_smokegrenade,weapon_scout,weapon_usp,weapon_knife");
					GivePlayerItem(client,"weapon_smokegrenade");
					FakeClientCommand(client,"use weapon_smokegrenade");
					CreateTimer(10.0,DropNade,client);
				}
			}
			else
				PrintHintText(client,"Level your skill first");
		}
/* *************************************** (SKILL_METEOR) *************************************** */
		if(ability==1)
		{
			new MeteorLevel=War3_GetSkillLevel(client,thisRaceID,SKILL_METEOR);
			if(MeteorLevel>0)
			{
				if(SkillAvailable(client,thisRaceID,SKILL_METEOR,true,true,true))
				{
					War3_CooldownMGR(client,MeteorCD[MeteorLevel],thisRaceID,SKILL_METEOR,true,true);
					EmitSoundToAll(MeteorLaunchSound,client);
					War3_GetAimTraceMaxLen(client,MeteorLocation[client],MeteorAimRange);
					new Float:direction[3];	    direction[0] = 89.0;
					TR_TraceRay(MeteorLocation[client],direction,MASK_PLAYERSOLID_BRUSHONLY, RayType_Infinite);
					if(TR_DidHit(INVALID_HANDLE))
					{
						TR_GetEndPosition(MeteorLocation[client], INVALID_HANDLE);
					}
					new Float:TopOfBeam[3];
					TopOfBeam[0]=MeteorLocation[client][0];
					TopOfBeam[1]=MeteorLocation[client][1];
					TopOfBeam[2]=MeteorLocation[client][2]+500.0;
					TE_SetupBeamPoints(TopOfBeam,MeteorLocation[client],LaseSprite,HaloSprite,0,8,MeteorImpactDelay,30.0,30.0,5,0.0,{255,215,0,125},70);
					TE_SendToAll();	
					CreateTimer(MeteorImpactDelay,MeteorImpact,client);
				}
			}
			else
				PrintHintText(client,"Level your skill first");
		}
	}
}

public Action:MeteorImpact(Handle:timer,any:client)
{
	if(ValidPlayer(client,true) && War3_GetRace(client)==thisRaceID)
	{
		new MeteorLevel=War3_GetSkillLevel(client,thisRaceID,SKILL_METEOR);
		EmitSoundToAll(MeteorImpactSound,client);
		TE_SetupExplosion(MeteorLocation[client],ExploModel,20.0,10,TE_EXPLFLAG_NONE,300,355);
		TE_SendToAll();
		TE_SetupSmoke(MeteorLocation[client],SmokeModel,100.0,2);
		TE_SendToAll();
		for (new i=1;i<=MaxClients;i++)
		{
			if(ValidPlayer(i,true) && GetClientTeam(i)!=GetClientTeam(client) && SkillFilter(i))
			{
				new Float:VictimPos[3];		GetClientAbsOrigin(i,VictimPos);
				new Float:Distance=GetVectorDistance(MeteorLocation[client],VictimPos);
				new Float:Radius = MeteorRadius[MeteorLevel];
				if(Distance<=Radius)
				{
					new Float:Factor=(Radius-Distance)/Radius;
					new DamageAmt=RoundFloat(MeteorDamage[MeteorLevel]*Factor);
					War3_DealDamage(i,DamageAmt,client,DMG_BLAST,"meteor",_,W3DMGTYPE_MAGIC);
					War3_ShakeScreen(i,2.0*Factor,250.0*Factor,30.0);
					W3FlashScreen(i,RGBA_COLOR_RED);
				}
			}
		}
	}
}
	
/* *************************************** (ULT_TELEPORT) *************************************** */
public OnUltimateCommand(client,race,bool:pressed)
{
	if(race==thisRaceID && pressed && ValidPlayer(client,true))
	{
		if(SkillAvailable(client,thisRaceID,ULT_TELEPORT,true,true,true))
		{
			new TeleportLevel=War3_GetSkillLevel(client,thisRaceID,ULT_TELEPORT);
			if(TeleportLevel>0)
				TeleportPlayerView(client,TeleDistance[TeleportLevel]);
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
			new TeleLevel=War3_GetSkillLevel(client,thisRaceID,ULT_TELEPORT);
			War3_CooldownMGR(client,TeleCD[TeleLevel],thisRaceID,ULT_TELEPORT,_,_);
			
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
				War3_CooldownReset(client,thisRaceID,ULT_TELEPORT);
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
				War3_CooldownReset(client,thisRaceID,ULT_TELEPORT);
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
		War3_CooldownReset(client,thisRaceID,ULT_TELEPORT);
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
