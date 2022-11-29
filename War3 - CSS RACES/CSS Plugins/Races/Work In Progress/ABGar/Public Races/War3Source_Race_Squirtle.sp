#pragma semicolon 1
 
#include "W3SIncs/War3Source_Interface"
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <smlib>

public Plugin:myinfo = 
{
	name = "War3Source Race - Squirtle",
	author = "ABGar",
	description = "The Squirtle race for War3Source.",
	version = "1.0",
}

new thisRaceID;

new SKILL_WITHDRAW, SKILL_DANCE, SKILL_PULSE, ULT_PUMP;

// SKILL_WITHDRAW
new Float:WithdrawDamageReduce[]={1.0,0.9,0.85,0.8,0.75};

// SKILL_DANCE
new bool:bMoving[MAXPLAYERSCUSTOM];
new bool:bInWater[MAXPLAYERSCUSTOM];
new Float:CanInvisTime[MAXPLAYERSCUSTOM];
new Float:WaterInvis[]={1.0,0.7,0.5,0.3,0.1};
new Float:StillInvis[]={1.0,0.8,0.65,0.5,0.4};
new Float:MoveInvis[]={1.0,0.9,0.8,0.7,0.6};

// SKILL_PULSE
new BeamSprite,HaloSprite;
new bool:bPulseActive[MAXPLAYERSCUSTOM]={false, ...};
new Float:PulseLocation[MAXPLAYERSCUSTOM][3];
new Float:UnSlowTime[MAXPLAYERSCUSTOM];
new Float:PulseCD=30.0;
new Float:PulseRange=300.0;
new Float:PulseDuration[]={0.0,8.0,10.0,12.0,15.0};
new Float:PulseSlow[]={1.0,0.95,0.9,0.85,0.8};
new String:WaterSound[]="ambient/water/water_run1.wav";

// ULT_PUMP
new PumpDamage=10;
new Float:PumpCD=20.0;
new Float:PumpSlow=0.85;
new Float:PushForce[]={0.0,700.0,900.0,1200.0,1500.0};
new Float:PumpDistance[]={0.0,500.0,700.0,900.0,1200.0};
new Float:PumpDuration[]={0.0,0.5,1.0,1.5,2.0};
new Float:PumpSoundDuration[]={0.0,2.0,4.0,6.0,8.0};
new bool:bPumped[MAXPLAYERSCUSTOM]={false, ...};
new String:PumpSound[]="weapons/mortar/mortar_explode2.wav";
new String:PumpWaterSound[]="ambient/levels/canals/water_rivulet_loop2.wav";

public OnWar3PluginReady()
{
	thisRaceID=War3_CreateNewRace("Squirtle","squirtle");
	SKILL_WITHDRAW = War3_AddRaceSkill(thisRaceID,"Withdraw","Squirtle’s shell protects from most attacks (passive) \n Damage reduction",false,4);
	SKILL_DANCE = War3_AddRaceSkill(thisRaceID,"Rain Dance","Summon rain to disguise your movements (passive) \n Invisibility that increases when standing still, and even more so when standing in water",false,4);
	SKILL_PULSE = War3_AddRaceSkill(thisRaceID,"Water Pulse","Soak the ground to bog down enemies (ability) \n create a puddle that slows enemies while in it, and for 2 seconds afterwards",false,4);
	ULT_PUMP=War3_AddRaceSkill(thisRaceID,"Hydro Pump","Blast your enemy with a strong pulse of water (+ultimate) \n Knockback and slow down your enemies",true,4);
	War3_CreateRaceEnd(thisRaceID);
	W3SkillCooldownOnSpawn(thisRaceID,ULT_PUMP,10.0,_);
}

public OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart);
	CreateTimer(0.1,CalcVis,_,TIMER_REPEAT);
}

public OnMapStart()
{
	BeamSprite=PrecacheModel("materials/sprites/lgtning.vmt");
	HaloSprite=PrecacheModel("materials/sprites/halo01.vmt");
	War3_PrecacheSound(WaterSound);
	War3_PrecacheSound(PumpSound);
	War3_PrecacheSound(PumpWaterSound);
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i=1; i<MaxClients; i++)
	{
		if (ValidPlayer(i))
		{
			bPumped[i]=false;
			bPulseActive[i]=false;
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
		bPulseActive[client]=false;
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
	War3_WeaponRestrictTo(client,thisRaceID,"weapon_m4a1,weapon_ak47,weapon_tmp,weapon_p228,weapon_knife");
	RemovePrimary(client);
	CreateTimer(0.2,GiveWep,client);
	bPulseActive[client]=false;
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
		GivePlayerItem(client,"weapon_tmp");
		if(!Client_HasWeapon(client,"weapon_p228"))
			GivePlayerItem(client,"weapon_p228");
	}
}

/* *************************************** (SKILL_WITHDRAW) *************************************** */
public OnW3TakeDmgBulletPre(victim,attacker,Float:damage)
{
	if(ValidPlayer(victim) && ValidPlayer(attacker) && GetClientTeam(attacker)!=GetClientTeam(victim))
	{
		if(War3_GetRace(victim)==thisRaceID)
		{
			new WithdrawLevel = War3_GetSkillLevel(victim,thisRaceID,SKILL_WITHDRAW);
			if(WithdrawLevel>0)
			{
				War3_DamageModPercent(WithdrawDamageReduce[WithdrawLevel]);
			}
		}

		if(War3_GetRace(attacker)==thisRaceID && War3_GetRace(victim)==War3_GetRaceIDByShortname("charmander"))
		{
			War3_DamageModPercent(1.1);
		}
	}
}

/* *************************************** (SKILL_DANCE) *************************************** */
public Action:CalcVis(Handle:timer,any:userid)
{
	for(new i=1;i<MaxClients;i++)
	{
		if(ValidPlayer(i) && War3_GetRace(i)==thisRaceID)
		{
			new DanceLevel = War3_GetSkillLevel(i,thisRaceID,SKILL_DANCE);
			if(DanceLevel>0)
			{
				if(bInWater[i])
				{
					War3_SetBuff(i,fInvisibilitySkill,thisRaceID,WaterInvis[DanceLevel]);
					CanInvisTime[i]=GetGameTime() + 2.0;
				}
				else if(bMoving[i])
				{
					War3_SetBuff(i,fInvisibilitySkill,thisRaceID,MoveInvis[DanceLevel]);
					CanInvisTime[i]=GetGameTime() + 2.0;
				}
				else
				{
					if(CanInvisTime[i]<GetGameTime())
					{
						War3_SetBuff(i,fInvisibilitySkill,thisRaceID,StillInvis[DanceLevel]);
					}
				}
			}
		}
	}
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(ValidPlayer(client)&&War3_GetRace(client)==thisRaceID)
	{
		bMoving[client]=(buttons & (IN_FORWARD | IN_BACK | IN_MOVELEFT | IN_MOVERIGHT))?true:false;
		bInWater[client]=(GetEntityFlags(client) & FL_INWATER)?true:false;	

/* *************************************** (SKILL_PULSE) *************************************** */
		new PulseLevel=War3_GetSkillLevel(client,thisRaceID,SKILL_PULSE);
		if(PulseLevel>0)
		{
			for (new enemy=1;enemy<=MaxClients;enemy++)
			{
				if(ValidPlayer(enemy,true) && GetClientTeam(enemy)!=GetClientTeam(client) && SkillFilter(enemy) && !bPumped[enemy])
				{
					if(bPulseActive[client])
					{
						new Float:enemyPos[3];		GetClientAbsOrigin(enemy,enemyPos);
						if(GetVectorDistance(enemyPos,PulseLocation[client])<=PulseRange)
						{
							War3_SetBuff(enemy,fSlow,thisRaceID,PulseSlow[PulseLevel]);
							W3SetPlayerColor(enemy,thisRaceID,0,0,255,255);
							UnSlowTime[enemy]=GetGameTime() + 2.0;
						}
						else if(UnSlowTime[enemy]<GetGameTime())
						{
							W3ResetBuffRace(enemy,fSlow,thisRaceID);
							W3ResetPlayerColor(enemy,thisRaceID);
						}
					}
					else if(UnSlowTime[enemy]<GetGameTime())
					{
						W3ResetBuffRace(enemy,fSlow,thisRaceID);
						W3ResetPlayerColor(enemy,thisRaceID);
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

public OnAbilityCommand(client,ability,bool:pressed)
{
	if(ValidPlayer(client,true) && War3_GetRace(client)==thisRaceID && pressed)
	{
		if(ability==0)
		{
			new PulseLevel=War3_GetSkillLevel(client,thisRaceID,SKILL_PULSE);
			if(PulseLevel>0)
			{
				if(SkillAvailable(client,thisRaceID,SKILL_PULSE,true,true,true))
				{			
					War3_CooldownMGR(client,PulseCD,thisRaceID,SKILL_PULSE,true,true);
					War3_GetAimTraceMaxLen(client,PulseLocation[client],400.0);
					new Float:direction[3];	    direction[0] = 89.0;
					TR_TraceRay(PulseLocation[client],direction,MASK_PLAYERSOLID_BRUSHONLY, RayType_Infinite);
					if(TR_DidHit(INVALID_HANDLE))
					{
						TR_GetEndPosition(PulseLocation[client], INVALID_HANDLE);
					}
					PulseLocation[client][2]+=5.0;
					
					new Float:Radius1=10.0, Float:Radius2=20.0;
					
					for (new x=0;x<=30;x++)
					{
						TE_SetupBeamRingPoint(PulseLocation[client],Radius1,Radius2,BeamSprite,HaloSprite,0,15,PulseDuration[PulseLevel],20.0,3.0,{42,232,232,255},10,0);
						TE_SendToAll();
						Radius1+=10.0;
						Radius2+=10.0;
					}
					CreateTimer(PulseDuration[PulseLevel],StopPulse,client);
					bPulseActive[client]=true;			
					EmitAmbientSound(WaterSound,PulseLocation[client]);
				}
			}
			else
				PrintHintText(client,"Level your skill first");
		}
	}
}

public Action:StopPulse(Handle:timer,any:client)
{
	if(ValidPlayer(client))
	{
		bPulseActive[client]=false;
		EmitAmbientSound(WaterSound,PulseLocation[client],_,_,SND_STOPLOOPING);
	}
}

/* *************************************** (ULT_PUMP) *************************************** */
public OnUltimateCommand(client,race,bool:pressed)
{
	if(ValidPlayer(client,true) && race==thisRaceID && pressed)
	{
		new PumpLevel=War3_GetSkillLevel(client,thisRaceID,ULT_PUMP);
		if(PumpLevel>0)
		{
			if(SkillAvailable(client,thisRaceID,ULT_PUMP,true,true,true))
			{			
				new Float:origin[3];		GetClientAbsOrigin(client,origin);		origin[2]+=40;
				new Float:targetpos[3];		War3_GetAimTraceMaxLen(client,targetpos,PumpDistance[PumpLevel]);

				origin[1]+=20;
				TE_SetupBeamPoints(origin,targetpos,BeamSprite,BeamSprite,0,5,0.5,10.0,12.0,2,2.0,{42,232,232,255},70);  
				TE_SendToAll();
				origin[1]-=40;
				TE_SetupBeamPoints(origin,targetpos,BeamSprite,BeamSprite,0,5,0.5,10.0,12.0,2,2.0,{42,232,232,255},70);  
				TE_SendToAll();
				
				EmitSoundToAll(PumpSound,client);

				new target = War3_GetTargetInViewCone(client,PumpDistance[PumpLevel],false,5.0);
				if(target>0 && UltFilter(target))
				{
					War3_CooldownMGR(client,PumpCD,thisRaceID,ULT_PUMP,true,true);
					W3FlashScreen(target,RGBA_COLOR_BLUE,0.3,0.4,FFADE_OUT);
					W3SetPlayerColor(target,thisRaceID,0,0,255,_,GLOW_SKILL);
					
					new Float:startpos[3];			GetClientAbsOrigin(client,startpos);
					new Float:endpos[3];			GetClientAbsOrigin(target,endpos);
					new Float:vector[3];

					MakeVectorFromPoints(startpos, endpos, vector);
					NormalizeVector(vector, vector);
					ScaleVector(vector, PushForce[PumpLevel]);
					TeleportEntity(target, NULL_VECTOR, NULL_VECTOR, vector);
					
					War3_SetBuff(target,fSlow,thisRaceID,PumpSlow);
					bPumped[target]=true;
					CreateTimer(PumpDuration[PumpLevel],StopPump,target);
					War3_DealDamage(target,PumpDamage,client,DMG_CRUSH,"hydro pump",_,W3DMGTYPE_MAGIC);
					W3EmitSoundToAll(PumpWaterSound,target);
					CreateTimer(PumpSoundDuration[PumpLevel],StopPumpSound,target);
				}
				else
					War3_CooldownMGR(client,2.0,thisRaceID,ULT_PUMP,true,true);
			}
		}
		else
			W3MsgUltNotLeveled(client);
	}
}

public Action:StopPump(Handle:timer,any:client)
{
	if(ValidPlayer(client))
	{
		bPumped[client]=false;
		W3ResetBuffRace(client,fSlow,thisRaceID);
		W3ResetPlayerColor(client,thisRaceID);
	}
}

public Action:StopPumpSound(Handle:timer,any:client)
{
	if(ValidPlayer(client))
	{
		StopSound(client,SNDCHAN_AUTO,PumpWaterSound);
	}
}