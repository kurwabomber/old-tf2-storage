#pragma semicolon 1
 
#include "W3SIncs/War3Source_Interface"
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <smlib>

public Plugin:myinfo = 
{
	name = "War3Source Race - Vampiric Child",
	author = "ABGar",
	description = "The Vampiric Child race for War3Source.",
	version = "1.0",
	//DinoLord's Private Race Request - https://www.sevensinsgaming.com/forum/index.php?/topic/5467-vampiric-child/
}

new thisRaceID;

new SKILL_VAMPIRE, SKILL_KID, SKILL_COFFIN, ULT_TELE;

// SKILL_VAMPIRE
new VampAdditionalHealth=100;
new Float:VampSteal[]={0.0,0.15,0.2,0.25,0.3};

// SKILL_KID
new Float:VampSpeed[]={1.0,1.1,1.2,1.3,1.4};

// SKILL_COFFIN
new Float:CoffinDelay=1.0;
new Float:CoffinRegen[]={0.0,10.0,12.0,13.0,15.0};
new Float:CoffinCD[]={0.0,25.0,20.0,15.0,15.0};
new bool:bInCoffin[MAXPLAYERSCUSTOM]={false, ...};
new String:CoffinOffSound[]="doors/wood_move1.wav";
new String:CoffinOnSound[]="doors/wood_stop1.wav";

// ULT_TELE
new ClientTracer;
new absincarray[]={0,4,-4,8,-8,12,-12,18,-18,22,-22,25,-25};
new bool:inteleportcheck[MAXPLAYERS];
new Float:emptypos[3];
new Float:oldpos[MAXPLAYERS][3];
new Float:teleportpos[MAXPLAYERS][3];
new Float:TeleDistance=300.0;
new Float:TeleCD[]={0.0,11.0,8.0,6.0,4.0};
new String:TeleSound[]="war3source/blinkarrival.mp3";

new Float:VampDamDecrease[]={1.0,0.9,0.85,0.8,0.7};
new Float:VampDamIncrease[]={1.0,1.1,1.15,1.2,1.3};

public OnWar3PluginReady()
{
	thisRaceID=War3_CreateNewRace("Vampiric Child [PRIVATE]","vampchild");
	SKILL_VAMPIRE = War3_AddRaceSkill(thisRaceID,"I am a Vampire","I suck your blood (passive vampire)",false,4);
	SKILL_KID = War3_AddRaceSkill(thisRaceID,"I am a kid","I'm hypo (passive speed)",false,4);
	SKILL_COFFIN = War3_AddRaceSkill(thisRaceID,"Coffin","Hide in the coffin to regenerate (+ability)",false,4);
	ULT_TELE=War3_AddRaceSkill(thisRaceID,"I am psychic","I can teleport (+ultimate)",true,4);
	War3_CreateRaceEnd(thisRaceID);
	W3SkillCooldownOnSpawn(thisRaceID,ULT_TELE,15.0,_);
	War3_AddSkillBuff(thisRaceID,SKILL_VAMPIRE,fVampirePercent,VampSteal);
	War3_AddSkillBuff(thisRaceID,SKILL_KID,fMaxSpeed,VampSpeed);
}

public OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart);
}

public OnMapStart()
{
	War3_PrecacheSound(CoffinOnSound);
	War3_PrecacheSound(CoffinOffSound);
	War3_PrecacheSound(TeleSound);
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
		bInCoffin[client]=false;
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
	if(ValidPlayer(client,true) && War3_GetRace(client)==thisRaceID)
	{
		InitPassiveSkills(client);
	}
}

public InitPassiveSkills(client)
{
	bInCoffin[client]=false;
	War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife");
	War3_SetBuff(client,iAdditionalMaxHealthNoHPChange,thisRaceID,VampAdditionalHealth);
	War3_SetBuff(client,bStunned,thisRaceID,false);
	W3ResetBuffRace(client,fHPRegen,thisRaceID);
	W3ResetPlayerColor(client,thisRaceID);
}

/* *************************************** (SKILL_COFFIN) *************************************** */
public OnAbilityCommand(client,ability,bool:pressed)
{
	if(ValidPlayer(client,true) && War3_GetRace(client)==thisRaceID && pressed)
	{
		if(ability==0)
		{
			new CoffinLevel=War3_GetSkillLevel(client,thisRaceID,SKILL_COFFIN);
			if(CoffinLevel>0)
			{
				if(bInCoffin[client])
				{
					War3_CooldownMGR(client,CoffinCD[CoffinLevel],thisRaceID,SKILL_COFFIN,true,true);
					W3ResetBuffRace(client,fHPRegen,thisRaceID);
					CreateTimer(CoffinDelay,StopCoffin,client);
					bInCoffin[client]=false;
					W3EmitSoundToAll(CoffinOffSound,client);
				}
				else 
				{
					if(SkillAvailable(client,thisRaceID,SKILL_COFFIN,true,true,true))
					{
						W3FlashScreen(client,{0,0,0,255},_,_,FFADE_STAYOUT);
						W3SetPlayerColor(client,thisRaceID,0,0,0,255); 
						War3_SetBuff(client,bStunned,thisRaceID,true);
						War3_SetBuff(client,fHPRegen,thisRaceID,CoffinRegen[CoffinLevel]);
						bInCoffin[client]=true;
						W3EmitSoundToAll(CoffinOnSound,client);
					}
				}
			}
			else
				PrintHintText(client,"Level your skill first");
		}
	}
}

public Action:StopCoffin(Handle:timer,any:client)
{
	if(ValidPlayer(client,true))
	{
		W3FlashScreen(client,{0,0,0,0}, _,_,(FFADE_IN|FFADE_PURGE));
		War3_SetBuff(client,bStunned,thisRaceID,false);
		W3ResetPlayerColor(client,thisRaceID);
	}
}

public OnWar3EventDeath(victim,attacker)
{
	W3FlashScreen(victim,{0,0,0,0}, _,_,(FFADE_IN|FFADE_PURGE));
	W3ResetPlayerColor(victim,thisRaceID);
	bInCoffin[victim]=false;
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
				if(TeleportPlayerView(client,TeleDistance,Immunity_Ultimates))
				{	
					War3_CooldownMGR(client,TeleCD[TeleportLevel],thisRaceID,ULT_TELE,_,_);
				}
			}
			else
				W3MsgUltNotLeveled(client);
		}	
	}
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

public OnW3TakeDmgBulletPre(victim,attacker,Float:damage)
{
	if(ValidPlayer(victim) && ValidPlayer(attacker) && GetClientTeam(attacker)!=GetClientTeam(victim))
	{
		if(War3_GetRace(victim)==thisRaceID)
		{
			new UltLevel = War3_GetSkillLevel(victim,thisRaceID,ULT_TELE);
			if(UltLevel>0)
			{
				new String:weapon[32]; 
				GetClientWeapon(attacker,weapon,32);
				if(StrEqual(weapon,"weapon_knife") || StrEqual(weapon,"weapon_m3"))
				{
					War3_DamageModPercent(VampDamIncrease[UltLevel]);
				}
				else
				{
					War3_DamageModPercent(VampDamDecrease[UltLevel]);
				}
			}
		}
	}
}
