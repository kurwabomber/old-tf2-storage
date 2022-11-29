#pragma semicolon 1
 
#include "W3SIncs/War3Source_Interface"
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <smlib>

public Plugin:myinfo = 
{
	name = "War3Source Race - Allman Brothers Band",
	author = "ABGar",
	description = "The Allman Brothers Band race for War3Source.",
	version = "1.0",
	// Valencianista's Private Race Request - https://www.sevensinsgaming.com/forum/index.php?/topic/5574-the-allman-brothers-band-private/
}

new thisRaceID;

new SKILL_GUN, SKILL_INVIS, SKILL_TELEPORT, ULT_TURN;

// SKILL_GUN
new Float:PistolDamage[]={0.0,0.05,0.1,0.15,0.2};
new Float:RifleDamage[]={0.0,0.018,0.035,0.06,0.075};

// SKILL_INVIS
new Float:PistolInvis[]={0.0,0.85,0.7,0.55,0.4};
new Float:SMGInvis[]={0.0,0.88,0.76,0.63,0.5};
new Float:RifleInvis[]={0.0,0.9,0.8,0.7,0.6};

// SKILL_TELEPORT
new ClientTracer;
new absincarray[]={0,4,-4,8,-8,12,-12,18,-18,22,-22,25,-25};
new bool:inteleportcheck[MAXPLAYERSCUSTOM];
new Float:emptypos[3];
new Float:oldpos[MAXPLAYERSCUSTOM][3];
new Float:teleportpos[MAXPLAYERSCUSTOM][3];
new Float:TeleDistance[]={0.0,300.0,400.0,500.0,600.0};
new Float:TeleCD[]={0.0,40.0,32.0,25.0,20.0};
new String:TeleSound[]="war3source/blinkarrival.mp3";

new Float:StunRange[]={0.0,150.0,190.0,230.0,275.0};
new Float:StunDuration=1.5;
new bool:bIsStunned[MAXPLAYERSCUSTOM]={false, ...};

// ULT_TURN
new Float:TurnRange[]={0.0,150.0,200.0,250.0,300.0};

public OnWar3PluginReady()
{
	thisRaceID=War3_CreateNewRace("Allman Brothers Band [PRIVATE]","allman");
	SKILL_GUN = War3_AddRaceSkill(thisRaceID,"Ramblin’ Man","My father was a gambler down in Georgia. He wound up on the wrong end of a gun, and I was born in the back seat of a Greyhound bus, rollin' down highway forty-one. \n Spawn a random weapon (passive)",false,4);
	SKILL_INVIS = War3_AddRaceSkill(thisRaceID,"Melissa","Crossroads, will you ever let him go? Or will you hide the dead man's ghost? \n Invisibility (passive)",false,4);
	SKILL_TELEPORT = War3_AddRaceSkill(thisRaceID,"Blue Sky","Good old Sunday morning, bells are ringing everywhere. Going to Carolina, it won't be long and I'll be there. \n Stun enemies around you, and teleport away (+ability)",false,4);
	ULT_TURN=War3_AddRaceSkill(thisRaceID,"Come and Go Blues","Round 'n' 'round, 'round we go, Don't ask me why I stay here, I don't know. Well maybe I'm a fool to care, \nWithout your sweet love, baby I would be nowhere. Here I'll stay, locked in your web, Till that day I might find somebody else. \n Passively turn enemies around when they're near you (passive ultimate)",true,4);
	War3_CreateRaceEnd(thisRaceID);
	W3SkillCooldownOnSpawn(thisRaceID,SKILL_TELEPORT,10.0,_);
}

public OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart);
	CreateTimer(0.1,CalcVis,_,TIMER_REPEAT);
	CreateTimer(3.0,CalcRotate,_,TIMER_REPEAT);
}

public OnMapStart()
{
	War3_PrecacheSound(TeleSound);
}

public Event_RoundStart(Handle:event,const String:name[],bool:dontBroadcast)
{
	for(new i=1;i<MaxClients;i++)
	{
		if(ValidPlayer(i,true))
		{
			bIsStunned[i]=false;
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
	if(ValidPlayer(client,true) && War3_GetRace(client)==thisRaceID)
	{
		InitPassiveSkills(client);
	}
}

public InitPassiveSkills(client)
{
	War3_SetBuff(client,bDisarm,thisRaceID,false);
	
	if(War3_GetSkillLevel(client,thisRaceID,SKILL_GUN)>0)
		GiveWeapon(client);
	
}

/* *************************************** (SKILL_GUN) *************************************** */
public GiveWeapon(client)
{
	if(ValidPlayer(client,true) && War3_GetRace(client)==thisRaceID)
	{
		new GunLevel = War3_GetSkillLevel(client,thisRaceID,SKILL_GUN);
		DropWeapons(client);
		new GunInt = GetRandomInt(1,5);
		if(GunInt==1)
		{
			GivePlayerItem(client,"weapon_deagle");
			GivePlayerItem(client,"weapon_knife");
			War3_WeaponRestrictTo(client,thisRaceID,"weapon_deagle,weapon_knife");
			War3_SetBuff(client,fDamageModifier,thisRaceID,PistolDamage[GunLevel]);
		}
		else if(GunInt==2)
		{
			GivePlayerItem(client,"weapon_usp");
			GivePlayerItem(client,"weapon_knife");
			War3_WeaponRestrictTo(client,thisRaceID,"weapon_usp,weapon_knife");
			War3_SetBuff(client,fDamageModifier,thisRaceID,PistolDamage[GunLevel]);
		}
		else if(GunInt==3)
		{
			GivePlayerItem(client,"weapon_mp5navy");
			GivePlayerItem(client,"weapon_p228");
			GivePlayerItem(client,"weapon_knife");
			War3_WeaponRestrictTo(client,thisRaceID,"weapon_mp5navy,weapon_p228,weapon_knife");
			War3_SetBuff(client,fDamageModifier,thisRaceID,RifleDamage[GunLevel]);
		}
		else if(GunInt==4)
		{
			GivePlayerItem(client,"weapon_m4a1");
			GivePlayerItem(client,"weapon_p228");
			GivePlayerItem(client,"weapon_knife");
			War3_WeaponRestrictTo(client,thisRaceID,"weapon_m4a1,weapon_p228,weapon_knife");
			War3_SetBuff(client,fDamageModifier,thisRaceID,RifleDamage[GunLevel]);
		}
		else if(GunInt==5)
		{
			GivePlayerItem(client,"weapon_ak47");
			GivePlayerItem(client,"weapon_p228");
			GivePlayerItem(client,"weapon_knife");
			War3_WeaponRestrictTo(client,thisRaceID,"weapon_ak47,weapon_p228,weapon_knife");
			War3_SetBuff(client,fDamageModifier,thisRaceID,RifleDamage[GunLevel]);
		}
	}
}

public DropWeapons(client)
{
	for (new slot=0;slot<=3;slot++)
	{
		new iWeapon=GetPlayerWeaponSlot(client,slot);
		if(IsValidEntity(iWeapon))
		{
			RemovePlayerItem(client, iWeapon);
			AcceptEntityInput(iWeapon, "kill");
		}
	}
}

/* *************************************** (SKILL_INVIS) *************************************** */
public Action:CalcVis(Handle:timer,any:userid)
{
	for(new i=0;i<MaxClients;i++)
	{
		if(ValidPlayer(i) && War3_GetRace(i)==thisRaceID)
		{
			new InvisLevel = War3_GetSkillLevel(i,thisRaceID,SKILL_INVIS);
			if(InvisLevel>0)
			{
				new String:weapon[32]; 
				GetClientWeapon(i,weapon,32);
				if(StrEqual(weapon,"weapon_knife") || StrEqual(weapon,"weapon_usp") || StrEqual(weapon,"weapon_p228"))
					War3_SetBuff(i,fInvisibilitySkill,thisRaceID,PistolInvis[InvisLevel]);
				else if(StrEqual(weapon,"weapon_mp5navy"))
					War3_SetBuff(i,fInvisibilitySkill,thisRaceID,SMGInvis[InvisLevel]);
				else if(StrEqual(weapon,"weapon_ak47")  || StrEqual(weapon,"weapon_usp"))
					War3_SetBuff(i,fInvisibilitySkill,thisRaceID,RifleInvis[InvisLevel]);
			}
		}
	}
}

/* *************************************** (SKILL_TELEPORT) *************************************** */
public OnAbilityCommand(client,ability,bool:pressed)
{
	if(ValidPlayer(client,true) && War3_GetRace(client)==thisRaceID && pressed)
	{
		if(ability==0)
		{
			new TeleportLevel=War3_GetSkillLevel(client,thisRaceID,SKILL_TELEPORT);
			if(TeleportLevel>0)
			{
				if(SkillAvailable(client,thisRaceID,SKILL_TELEPORT,true,true,true))
				{
					new Float:clientPos[3];		GetClientAbsOrigin(client,clientPos);
					if(TeleportPlayerView(client,TeleDistance[TeleportLevel],Immunity_Skills))
					{	
						War3_SetBuff(client,bDisarm,thisRaceID,true);
						CreateTimer(1.0,CanShoot,client);
						War3_CooldownMGR(client,TeleCD[TeleportLevel],thisRaceID,SKILL_TELEPORT,_,_);
						
						for (new enemy=1;enemy<=MaxClients;enemy++)
						{
							if(ValidPlayer(enemy,true) && GetClientTeam(enemy)!=GetClientTeam(client) && SkillFilter(enemy))
							{
								new Float:enemyPos[3];		GetClientAbsOrigin(enemy,enemyPos);
								if(GetVectorDistance(clientPos,enemyPos)<=StunRange[TeleportLevel])
								{
									CreateTimer(0.2,StartStun,enemy);
									bIsStunned[enemy]=true;
								}
							}
						}
					}
				}
			}
			else
				PrintHintText(client,"Level your skill first");
		}
	}
}

public Action:CanShoot(Handle:timer,any:client)
{
	if(ValidPlayer(client))
	{
		War3_SetBuff(client,bDisarm,thisRaceID,false);
	}
}

public Action:StartStun(Handle:timer,any:client)
{
	if(ValidPlayer(client,true) && bIsStunned[client])
	{
		// EMIT SOUND HERE FOR THE SONG
		War3_SetBuff(client,bDisarm,thisRaceID,true);
		W3SetPlayerColor(client,thisRaceID,0,255,0,255);
		CreateTimer(StunDuration,StopStun,client);
	}
}

public Action:StopStun(Handle:timer,any:client)
{
	if(ValidPlayer(client) && bIsStunned[client])
	{
		War3_SetBuff(client,bDisarm,thisRaceID,true);
		W3ResetPlayerColor(client,thisRaceID);
		bIsStunned[client]=false;
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

public Action:checkTeleport(Handle:h,any:client)
{
	inteleportcheck[client]=false;
	new Float:pos[3];		GetClientAbsOrigin(client,pos);
	
	if(GetVectorDistance(teleportpos[client],pos)<0.001)
	{
		TeleportEntity(client,oldpos[client],NULL_VECTOR,NULL_VECTOR);
		War3_CooldownReset(client,thisRaceID,SKILL_TELEPORT);
		for (new i=1;i<=MaxClients;i++)
		{
			if(ValidPlayer(i))
			{
				War3_SetBuff(i,bDisarm,thisRaceID,false);
				bIsStunned[i]=false;
			}
		}
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

/* *************************************** (ULT_TURN) *************************************** */
public Action:CalcRotate(Handle:timer,any:userid)
{
	for(new client=0;client<MaxClients;client++)
	{
		if(ValidPlayer(client) && War3_GetRace(client)==thisRaceID)
		{
			new TurnLevel = War3_GetSkillLevel(client,thisRaceID,ULT_TURN);
			if(TurnLevel>0)
			{
				new Float:clientPos[3];			GetClientAbsOrigin(client,clientPos);
				
				for (new enemy=1;enemy<=MaxClients;enemy++)
				{
					if(ValidPlayer(enemy,true) && GetClientTeam(enemy)!=GetClientTeam(client) && UltFilter(enemy))
					{
						new Float:enemyPos[3];		GetClientAbsOrigin(enemy,enemyPos);
						new Float:enemyAng[3];		GetClientEyeAngles(enemy,enemyAng);
						if(GetVectorDistance(clientPos,enemyPos)<=TurnRange[TurnLevel])
						{
							enemyAng[1]+=180.0;
							TeleportEntity(enemy,NULL_VECTOR,enemyAng,NULL_VECTOR);
							CPrintToChat(enemy,"{green}[%N] {red}Round and Round, and Round we go....",client);
						}
					}
				}
			}
		}
	}
}















