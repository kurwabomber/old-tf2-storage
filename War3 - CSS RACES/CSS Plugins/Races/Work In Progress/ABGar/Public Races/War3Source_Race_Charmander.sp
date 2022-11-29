#pragma semicolon 1
 
#include "W3SIncs/War3Source_Interface"
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <smlib>

public Plugin:myinfo = 
{
	name = "War3Source Race - Charmander",
	author = "ABGar",
	description = "The Charmander race for War3Source.",
	version = "1.0",
}

new thisRaceID;

new SKILL_RAGE, SKILL_CLAW, SKILL_WARD, ULT_FLAME;

// SKILL_RAGE
new Float:RageSpeed[]={1.0,1.07,1.13,1.17,1.23};
new Float:RageFireSpeed[]={1.0,1.11,1.22,1.33,1.44};

// SKILL_CLAW
new Float:ClawDamage[]={1.0,1.05,1.1,1.15,1.2};

// SKILL_WARD
new BeamSprite,HaloSprite;
new wardnumber;
new WardDamage[]={0,2,3,4,5};
new TotalWardsAllowed[]={0,1,2,3,4};
new WardOwner[MAXPLAYERSCUSTOM][5];
new Float:WardRange=100.0;
new Float:WardPos[5][3];
new bool:bIgnited[MAXPLAYERSCUSTOM]={false, ...};

// ULT_FLAME
new Counter;
new FlameDamage[]={0,20,30,40,50};
new Float:EndPos[40][3];
new Float:FlameRange=100.0;
new Float:FlameIgniteTime[]={0.0,2.0,3.0,4.0,5.0};
new Float:FlameCD[]={0.0,40.0,35.0,30.0,25.0};
new bool:bFlamed[MAXPLAYERSCUSTOM]={false, ...};
new String:FlameSound[]="war3source/brewmaster/breath.wav";


public OnWar3PluginReady()
{
	thisRaceID=War3_CreateNewRace("Charmander","charmander");
	SKILL_RAGE = War3_AddRaceSkill(thisRaceID,"Dragon Rage","Dragons are an extremely quick unstoppable force (passive) \n Faster movement speed.",false,4);
	SKILL_CLAW = War3_AddRaceSkill(thisRaceID,"Metal Claw","Charmander's claws allow greater damage (passive) \n Bonus damage",false,4);
	SKILL_WARD = War3_AddRaceSkill(thisRaceID,"Fire Spin","Create a wall of fire to block the path (+ability) \n Create a Fire Ward at your location, that will damage and ignite nearby enemies",false,4);
	ULT_FLAME=War3_AddRaceSkill(thisRaceID,"Flamethrower","Expel flames to burn your opponents (+ultimate)",true,4);
	War3_CreateRaceEnd(thisRaceID);
	W3SkillCooldownOnSpawn(thisRaceID,SKILL_WARD,10.0,_);
	W3SkillCooldownOnSpawn(thisRaceID,ULT_FLAME,10.0,_);
}

public OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	CreateTimer(0.2,CalcWards,_,TIMER_REPEAT);
}

public OnMapStart()
{
	BeamSprite=PrecacheModel("materials/sprites/lgtning.vmt");
	HaloSprite=PrecacheModel("materials/sprites/halo01.vmt");
	War3_PrecacheSound(FlameSound);
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i=1; i<MaxClients; i++)
	{
		if (ValidPlayer(i))
		{
			bIgnited[i]=false;
			bFlamed[i]=false;
		}
	}
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i=0; i<MaxClients; i++)
	{
		if (ValidPlayer(i))
		{
			bIgnited[i]=false;
			bFlamed[i]=false;
			if(War3_GetRace(i)==thisRaceID)
			{
				RemoveWards(i);
			}
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
	War3_WeaponRestrictTo(client,thisRaceID,"weapon_m4a1,weapon_ak47,weapon_mp5navy,weapon_usp,weapon_knife");
	RemovePrimary(client);
	CreateTimer(0.2,GiveWep,client);
	RemoveWards(client);
}

public RemovePrimary(client)
{
	new iWeapon = GetPlayerWeaponSlot(client, 0);  
	if(IsValidEntity(iWeapon))
	{
		RemovePlayerItem(client, iWeapon);
		AcceptEntityInput(iWeapon, "kill");
	}
}

public Action:GiveWep(Handle:timer,any:client)
{
	if(ValidPlayer(client,true) && War3_GetRace(client)==thisRaceID)
	{
		GivePlayerItem(client,"weapon_mp5navy");
		if(!Client_HasWeapon(client,"weapon_usp"))
			GivePlayerItem(client,"weapon_usp");
	}
}

/* *************************************** (SKILL_CLAW) *************************************** */
public OnW3TakeDmgBulletPre(victim,attacker,Float:damage)
{
	if(ValidPlayer(victim) && ValidPlayer(attacker) && GetClientTeam(attacker)!=GetClientTeam(victim))
	{
		if(War3_GetRace(attacker)==thisRaceID)
		{
			new ClawLevel = War3_GetSkillLevel(victim,thisRaceID,SKILL_CLAW);
			if(War3_GetRace(victim)==War3_GetRaceIDByShortname("bulbasaur"))
			{
				War3_DamageModPercent(1.1*ClawDamage[ClawLevel]);
			}
			
			if(ClawLevel>0)
			{
				War3_DamageModPercent(ClawDamage[ClawLevel]);
			}
		}
	}
}

/* *************************************** (SKILL_WARD) *************************************** */
public OnAbilityCommand(client,ability,bool:pressed)
{
	if(ValidPlayer(client,true) && War3_GetRace(client)==thisRaceID && pressed)
	{
		if(ability==0)
		{
			new WardLevel=War3_GetSkillLevel(client,thisRaceID,SKILL_WARD);
			if(WardLevel>0)
			{
				if(SkillAvailable(client,thisRaceID,SKILL_WARD,true,true,true))
				{
					if(wardnumber < TotalWardsAllowed[WardLevel])
					{
						CreateFlameWard(client,TotalWardsAllowed[WardLevel]);
						bIgnited[client]=true;
						CreateTimer(3.0,StopIgnite,client);
					}
					else
						PrintToChat(client,"You have already placed your maximum amount of firewards");
				}
			}
			else
				PrintHintText(client,"Level your skill first");
		}
	}
}

public CreateFlameWard(client,totalwardcount)
{
	new particle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(particle))
	{
		wardnumber++;
		GetClientAbsOrigin(client,WardPos[wardnumber]);
		
		decl String:Name[32];
		Format(Name,sizeof(Name),"Flame_Ward_%i_%i",client,wardnumber);
		
		TeleportEntity(particle,WardPos[wardnumber],NULL_VECTOR,NULL_VECTOR);
		DispatchKeyValue(particle,"targetname",Name);
		DispatchKeyValue(particle,"effect_name","env_fire_large");
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle,"start");
		WardOwner[client][wardnumber]=particle;
		PrintToChat(client,"Flame Ward %i of %i created",wardnumber,totalwardcount);
	}
	else
	{
		PrintToChat(client,"Unable to plant a ward.  Something went wrong");
		War3_LogError("Charmander: Failed to create FlameWard");
	}
}

public Action:CalcWards(Handle:timer,any:userid)
{
	for (new client=0; client<=MaxClients; client++)
	{
		if(ValidPlayer(client,true) && War3_GetRace(client)==thisRaceID)
		{	
			new WardLevel=War3_GetSkillLevel(client,thisRaceID,SKILL_WARD);
			new RageLevel=War3_GetSkillLevel(client,thisRaceID,SKILL_RAGE);
			{
				if(bIgnited[client])
					War3_SetBuff(client,fMaxSpeed,thisRaceID,RageFireSpeed[RageLevel]);
				else
					War3_SetBuff(client,fMaxSpeed,thisRaceID,RageSpeed[RageLevel]);
			}
			
			for (new w=1; w<=wardnumber; w++)
			{
				TE_SetupBeamRingPoint(WardPos[w],10.0,WardRange,BeamSprite,HaloSprite,0,10,0.6,10.0,0.5,{255,75,75,255},10,0);
				TE_SendToAll();
				
				for (new i=0; i<=MaxClients; i++)
				{
					if(ValidPlayer(i,true) && GetClientTeam(i)!=GetClientTeam(client) && !W3HasImmunity(i,Immunity_Wards) || i==client)
					{
						new Float:iPos[3];		GetClientAbsOrigin(i,iPos);
						if(GetVectorDistance(iPos,WardPos[w])<=WardRange)
						{
							if(!bIgnited[i])
							{
								IgniteEntity(i,2.0);
								bIgnited[i]=true;
								CreateTimer(2.0,StopIgnite,i);
							}	
							if(i!=client)
								War3_DealDamage(i,WardDamage[WardLevel],client,DMG_CRUSH,"flame ward");
						}
					}
				}
			}
		}
	}
}

public Action:StopIgnite(Handle:timer,any:client)
{
	if(ValidPlayer(client))
	{
		bIgnited[client]=false;
	}
}

public OnWar3EventDeath(victim,attacker)
{
	if(War3_GetRace(victim)==thisRaceID)
	{
		RemoveWards(victim);
	}
}

public RemoveWards(client)
{
	for (new w=1; w<=wardnumber; w++)
	{ 
		new thisWard = WardOwner[client][w];

		new String:classN[64];
		GetEdictClassname(thisWard, classN, sizeof(classN));
		if (StrEqual(classN, "info_particle_system", false))
		{
			RemoveEdict(thisWard);
			
		}
	}
	wardnumber=0;
}

/* *************************************** (ULT_FLAME) *************************************** */
public OnUltimateCommand(client,race,bool:pressed)
{
	if(ValidPlayer(client,true) && race==thisRaceID && pressed)
	{
		new FlameLevel=War3_GetSkillLevel(client,thisRaceID,ULT_FLAME);
		if(FlameLevel>0)
		{
			if(SkillAvailable(client,thisRaceID,ULT_FLAME,true,true,true))
			{
				War3_CooldownMGR(client,FlameCD[FlameLevel],thisRaceID,ULT_FLAME,true,true);
				
				W3EmitSoundToAll(FlameSound,client);
				new Float:angle[3];				GetClientEyeAngles(client,angle);
				new Float:startpos[3];			GetClientAbsOrigin(client,startpos);	startpos[2]+=20.0;
				new Float:endpos[3];
				new Float:MainDirection[3];		
				new Float:VertexGap=10.0;		
				GetAngleVectors(angle, MainDirection, NULL_VECTOR, NULL_VECTOR);
				ScaleVector(MainDirection, VertexGap);
				AddVectors(startpos, MainDirection, endpos);
				
				for (new x=0;x<40;x++)
				{
					EndPos[x][0]=endpos[0];
					EndPos[x][1]=endpos[1];
					EndPos[x][2]=endpos[2];
					AddVectors(endpos, MainDirection, endpos);
				}
				
				Counter=1;
				CreateFlameThrower(client,EndPos[Counter]);
				Counter++;
				CreateFlameThrower(client,EndPos[Counter]);
				Counter++;
				CreateFlameThrower(client,EndPos[Counter]);
				Counter++;
				CreateFlameThrower(client,EndPos[Counter]);
			
				new Float:FireTimeDelay=0.1;
				for (new y=1;y<10;y++)
				{
					CreateTimer(FireTimeDelay,FireTimer,client);
					FireTimeDelay+=0.1;
				}
			}
		}
		else
			W3MsgUltNotLeveled(client);
	}
}

public Action:FireTimer(Handle:timer,any:client)
{
	CreateFlameThrower(client,EndPos[Counter]);
	Counter++;
	CreateFlameThrower(client,EndPos[Counter]);
	Counter++;
	CreateFlameThrower(client,EndPos[Counter]);
	Counter++;
	CreateFlameThrower(client,EndPos[Counter]);
	Counter++;
}

public CreateFlameThrower(client,Float:FirePos[3])
{
	new FlameLevel=War3_GetSkillLevel(client,thisRaceID,ULT_FLAME);
	new fire = CreateEntityByName("env_fire");
	if(IsValidEdict(fire) && IsClientInGame(client))
	{
		decl String:Name[32];
		Format(Name, sizeof(Name), "flamethrower_%i", client);
		
		DispatchKeyValueFloat(fire, "damagescale", 0.0);
		DispatchKeyValueFloat(fire, "ignitionpoint", 0.0);
		DispatchKeyValue(fire, "Name", Name);
		DispatchKeyValue(fire, "fireattack", "0");
		DispatchKeyValue(fire, "firetype", "Natural");
		DispatchKeyValue(fire, "firesize", "50");
		DispatchKeyValue(fire, "flags", "12");
		DispatchSpawn(fire);
		ActivateEntity(fire);
		AcceptEntityInput(fire, "StartFire");
		TeleportEntity(fire, FirePos, NULL_VECTOR, NULL_VECTOR);
		CreateTimer(0.2, RemoveFire, fire);
		
		for (new i=1;i<=MaxClients;i++)
		{
			if(ValidPlayer(i,true) && GetClientTeam(client)!=GetClientTeam(i) && UltFilter(i))
			{
				new Float:iPos[3];	GetClientAbsOrigin(i,iPos);
				
				if(GetVectorDistance(FirePos,iPos)<=FlameRange)
				{
					if(!bFlamed[i])
					{
						IgniteEntity(i,FlameIgniteTime[FlameLevel]);
						bFlamed[i]=true;
						CreateTimer(FlameIgniteTime[FlameLevel],StopFlamed,i);
						War3_DealDamage(i,FlameDamage[FlameLevel],client,DMG_CRUSH,"flame thrower",_,W3DMGTYPE_MAGIC);
					}
				}
			}
		}
	}
}

public Action:StopFlamed(Handle:timer,any:client)
{
	if(ValidPlayer(client))
	{
		bFlamed[client]=false;
	}
}

public Action:RemoveFire(Handle:timer, any:fire)
{
	if(IsValidEdict(fire))
	{
		AcceptEntityInput(fire, "Kill");
	}
}
