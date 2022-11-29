#pragma semicolon 1
 
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdkhooks>
#include <smlib>

public Plugin:myinfo = 
{
	name = "War3Source Race - WindRunner",
	author = "ABGar",
	description = "The WindRunner race for War3Source.",
	version = "1.0",
	// Godzace's Private Race Request - http://www.sevensinsgaming.com/forum/index.php?/topic/5469-windrunner
}

new thisRaceID;

new SKILL_SHACKLE, SKILL_POWER, SKILL_WIND, ULT_FOCUS;

// SKILL_SHACKLE
new GlowSprite;
new bool:bToStun[MAXPLAYERSCUSTOM];
new iStunNumber=0;
new Float:Output;
new Float:StunRange=500.0;
new Float:ShackleCD[]={0.0,30.0,25.0,20.0,2.0};
new Float:ShackleDurationSingle[]={0.0,0.5,0.8,1.0,1.2};
new Float:ShackleDurationMulti[]={0.0,0.7,1.0,1.5,2.0};
new String:ShackleSound[]="npc/roller/code2.wav";

// SKILL_POWER
new Float:PowerCD[]={0.0,40.0,30.0,35.0,25.0};
new String:PowerSound[]="war3source/particle_suck1.wav";

// SKILL_WIND
new bool:bInWind[MAXPLAYERSCUSTOM];
new Float:WindSpeed[]={1.0,1.1,1.2,1.3,1.4};
new Float:WindEvade[]={0.0,0.2,0.3,0.4,0.6};
new Float:WindCD[]={0.0,30.0,25.0,20.0,15.0};
new Float:WindDuration[]={0.0,3.0,4.0,5.0,6.0};
new String:WindSound[]="war3source/avernus/shield_on.mp3";

// ULT_FOCUS
new bool:bInFocus[MAXPLAYERSCUSTOM];
new Handle:hFocusTimer[MAXPLAYERSCUSTOM]={INVALID_HANDLE, ...};
new Float:FocusDuration[]={0.0,5.0,7.0,8.0,10.0};
new Float:FocusCD[]={0.0,40.0,35.0,30.0,20.0};
new Float:FocusAttackSpeed[]={1.0,1.1,1.2,1.25,1.3};
new String:FocusSound[]="war3source/item_healthpotion.mp3";



public OnWar3PluginReady()
{
	thisRaceID=War3_CreateNewRace("WindRunner [PRIVATE]","windrunner");
	SKILL_SHACKLE = War3_AddRaceSkill(thisRaceID,"Shackleshot","Shackles the target to an another enemy directly behind it, or directly to the ground (passive)",false,4);
	SKILL_POWER = War3_AddRaceSkill(thisRaceID,"Powershot","Windrunner charges her bow to release a powerful shot (+ability)",false,4);
	SKILL_WIND = War3_AddRaceSkill(thisRaceID,"Windrun","Increases movement speed, and adds evasion from physical attacks for a short period (+ability1)",false,4);
	ULT_FOCUS=War3_AddRaceSkill(thisRaceID,"Focus Fire","Windrunner channels the wind to gain faster attack speed (+ultimate)",true,4);
	War3_CreateRaceEnd(thisRaceID);
	W3SkillCooldownOnSpawn(thisRaceID,ULT_FOCUS,10.0,_);
	W3SkillCooldownOnSpawn(thisRaceID,SKILL_SHACKLE,10.0,_);
}

public OnPluginStart()
{
	HookEvent("weapon_fire",Event_WeaponFire);
}

public OnMapStart()
{
	War3_PrecacheSound(ShackleSound);
	War3_PrecacheSound(PowerSound);
	War3_PrecacheSound(WindSound);
	War3_PrecacheSound(FocusSound);
	GlowSprite=PrecacheModel("sprites/yelflare1.vmt");
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
	CreateTimer(0.5,GiveMainWeps,client);
	W3ResetAllBuffRace(client,thisRaceID);
	War3_SetBuff(client,bDisarm,thisRaceID,false);
	bInWind[client]=false;
	bInFocus[client]=false;
	CreateTimer(0.5,GiveMainWeps,client);
	if (hFocusTimer[client] != INVALID_HANDLE)
    {
        KillTimer(hFocusTimer[client]);
        hFocusTimer[client] = INVALID_HANDLE;
    }
}

public Action:GiveMainWeps(Handle:timer,any:client)
{
	if(War3_GetRace(client)==thisRaceID && ValidPlayer(client,true))
	{
		War3_WeaponRestrictTo(client,thisRaceID,"weapon_m4a1,weapon_deagle,weapon_knife");
		if(Client_HasWeapon(client,"weapon_awp"))
		{
			new iWeapon = GetPlayerWeaponSlot(client, 0);  
			if(IsValidEntity(iWeapon))
			{
				RemovePlayerItem(client, iWeapon);
				AcceptEntityInput(iWeapon, "kill");
			}
		}
		
		if(!Client_HasWeapon(client, "weapon_m4a1"))
			GivePlayerItem(client,"weapon_m4a1");
		if(!Client_HasWeapon(client, "weapon_deagle"))
			GivePlayerItem(client,"weapon_deagle");
	}
}


public Event_WeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(War3_GetRace(client)==thisRaceID)
	{
		new PowerLevel=War3_GetSkillLevel(client,thisRaceID,SKILL_POWER);
		new String:weapon[32]; 
		GetClientWeapon(client,weapon,32);
		if(StrEqual(weapon,"weapon_awp"))
		{
			War3_CooldownMGR(client,PowerCD[PowerLevel],thisRaceID,SKILL_POWER,true,true);
			CreateTimer(1.0,GiveMainWeps,client);
		}
    }
}

/* *************************************** (SKILL_SHACKLE) *************************************** */
stock Float:GetAngleBetweenVector(client, enemy)
{
	decl Float:vec[3];					GetClientAbsOrigin(client, vec);
	decl Float:targetPos[3];			GetClientAbsOrigin(enemy, targetPos);
	decl Float:fwd[3];
	decl Float:SavedEntityAngle[3];		GetClientAbsAngles(client,SavedEntityAngle);

	GetAngleVectors(SavedEntityAngle, fwd, NULL_VECTOR, NULL_VECTOR);
	vec[0] = targetPos[0] - vec[0];
	vec[1] = targetPos[1] - vec[1];
	vec[2] = 0.0;
	fwd[2] = 0.0;
	NormalizeVector(fwd, fwd);
	ScaleVector(vec, 1/SquareRoot(vec[0]*vec[0]+vec[1]*vec[1]+vec[2]*vec[2]));
	Output = ArcCosine(vec[0]*fwd[0]+vec[1]*fwd[1]+vec[2]*fwd[2]);
	return;
} 

public Action:EndBashed(Handle:timer,any:client)
{
	if(ValidPlayer(client))
		War3_SetBuff(client,bBashed,thisRaceID,false);
}

public OnAbilityCommand(client,ability,bool:pressed)
{
	if(ValidPlayer(client,true) && War3_GetRace(client)==thisRaceID && pressed)
	{
		if(ability==0)
		{
			new ShackleLevel=War3_GetSkillLevel(client,thisRaceID,SKILL_SHACKLE);
			if(ShackleLevel>0)
			{
				if(SkillAvailable(client,thisRaceID,SKILL_SHACKLE,true,true,true))
				{
					new target = War3_GetTargetInViewCone(client,StunRange,false,23.0);
					if(target>0 && SkillFilter(target))
					{
						War3_CooldownMGR(client,ShackleCD[ShackleLevel],thisRaceID,SKILL_SHACKLE,true,true);
						bToStun[target]=true;
						iStunNumber=1;
						new Float:ClientPos[3];			GetClientAbsOrigin(client,ClientPos);
						new Float:TargetPos[3];			GetClientAbsOrigin(target,TargetPos);
						new Float:MyAngle;
						new Float:EnemyAngle;
						GetAngleBetweenVector(client,target);
						MyAngle = RadToDeg(Output);
						
						for(new enemy=1;enemy<=MaxClients;enemy++)
						{
							if(ValidPlayer(enemy,true) && GetClientTeam(enemy)== GetClientTeam(target) && SkillFilter(enemy) && enemy!=target)
							{
								new Float:EnemyPos[3];			GetClientAbsOrigin(enemy,EnemyPos);
								if(GetVectorDistance(EnemyPos,TargetPos)<=100.0)
								{
									GetAngleBetweenVector(client,enemy);
									EnemyAngle = RadToDeg(Output);
									if(((MyAngle+2.0) >= EnemyAngle) && ((MyAngle-2.0) <= EnemyAngle))
									{
										bToStun[enemy]=true;
										iStunNumber++;
									}
								}
							}
						}
						
						if(iStunNumber>1)
						{
							for(new enemy=1;enemy<=MaxClients;enemy++)
							{
								if(ValidPlayer(enemy,true) && GetClientTeam(enemy) != GetClientTeam(client) && SkillFilter(enemy) && bToStun[enemy])
								{
									new Float:FinalPos[3];			GetClientAbsOrigin(enemy,FinalPos);
									FinalPos[2]+=30.0;
									War3_SetBuff(enemy,bBashed,thisRaceID,true);
									CreateTimer(ShackleDurationMulti[ShackleLevel],EndBashed,enemy);
									
									TE_SetupGlowSprite(FinalPos,GlowSprite,ShackleDurationMulti[ShackleLevel],3.0,200);
									TE_SendToClient(client);
									EmitSoundToAll(ShackleSound,client);
									CPrintToChat(client,"{red}%N is stunned for {green}%f seconds",enemy,ShackleDurationMulti[ShackleLevel]);
									bToStun[enemy]=false;
								}
							}
						}
						if(iStunNumber==1)
						{
							for(new enemy=1;enemy<=MaxClients;enemy++)
							{
								if(ValidPlayer(enemy,true) && GetClientTeam(enemy) != GetClientTeam(client) && SkillFilter(enemy) && bToStun[enemy])
								{
									new Float:FinalPos[3];			GetClientAbsOrigin(target,FinalPos);
									FinalPos[2]+=30.0;
									War3_SetBuff(target,bBashed,thisRaceID,true);
									CreateTimer(ShackleDurationSingle[ShackleLevel],EndBashed,target);
									
									TE_SetupGlowSprite(FinalPos,GlowSprite,ShackleDurationSingle[ShackleLevel],3.0,200);
									TE_SendToClient(client);
									EmitSoundToAll(ShackleSound,client);
									CPrintToChat(client,"{red}%N is stunned for {green}%f seconds",enemy,ShackleDurationSingle[ShackleLevel]);
									bToStun[enemy]=false;
								}
							}
						}
					}
					else
						W3MsgNoTargetFound(client);
				}
			}
			else
				PrintHintText (client,"Level your skill first");
		}	
/* *************************************** (SKILL_POWER) *************************************** */
		if(ability==1)
		{
			new PowerLevel=War3_GetSkillLevel(client,thisRaceID,SKILL_POWER);
			if(PowerLevel>0)
			{
				if(SkillAvailable(client,thisRaceID,SKILL_POWER,true,true,true))
				{
					new iWeapon = GetPlayerWeaponSlot(client, 0);  
					if(IsValidEntity(iWeapon))
					{
						RemovePlayerItem(client, iWeapon);
						AcceptEntityInput(iWeapon, "kill");
					}
					War3_WeaponRestrictTo(client,thisRaceID,"weapon_awp,weapon_deagle,weapon_knife");
					GivePlayerItem(client,"weapon_awp");
					EmitSoundToAll(PowerSound,client);
				}
			}
			else
				PrintHintText(client,"Level your skill first");
		}
/* *************************************** (SKILL_WIND) *************************************** */
		if(ability==2)
		{
			new WindLevel=War3_GetSkillLevel(client,thisRaceID,SKILL_WIND);
			if(WindLevel>0)
			{
				if(SkillAvailable(client,thisRaceID,SKILL_WIND,true,true,true))
				{
					War3_CooldownMGR(client,(WindCD[WindLevel]+WindDuration[WindLevel]),thisRaceID,SKILL_WIND,true,true);
					EmitSoundToAll(WindSound,client);
					War3_SetBuff(client,fMaxSpeed,thisRaceID,WindSpeed[WindLevel]);
					War3_SetBuff(client,fDodgeChance,thisRaceID,WindEvade[WindLevel]);
					War3_SetBuff(client,bDisarm,thisRaceID,true);
					bInWind[client]=true;
					CreateTimer(WindDuration[WindLevel],StopWind,client);
					new seconds = RoundToFloor(WindDuration[WindLevel]);
					CPrintToChat(client, "{red} You run on the wind for {green}%i seconds",seconds);
				}
			}
		}
	}
}

public Action:StopWind(Handle:timer,any:client)
{
	if(ValidPlayer(client,true) && War3_GetRace(client)==thisRaceID && bInWind[client])
	{
		W3ResetBuffRace(client,fMaxSpeed,thisRaceID);
		W3ResetBuffRace(client,fDodgeChance,thisRaceID);
		CreateTimer(1.0,StopDisarm,client);
		bInWind[client]=false;
		CPrintToChat(client, "{red} Windrun is over");
	}
}

public Action:StopDisarm(Handle:timer,any:client)
{
	if(ValidPlayer(client,true) && War3_GetRace(client)==thisRaceID)
	{
		War3_SetBuff(client,bDisarm,thisRaceID,false);
	}
}

/* *************************************** (ULT_FOCUS) *************************************** */
public OnUltimateCommand(client,race,bool:pressed)
{
	if(ValidPlayer(client,true) && race==thisRaceID && pressed)
	{
		new FocusLevel=War3_GetSkillLevel(client,thisRaceID,ULT_FOCUS);
		if(FocusLevel>0)
		{
			if(bInFocus[client])
			{
				TriggerTimer(hFocusTimer[client]);
			}
			else
			{
				if(SkillAvailable(client,thisRaceID,ULT_FOCUS,true,true,true))
				{
					War3_CooldownMGR(client,(FocusDuration[FocusLevel]+FocusCD[FocusLevel]),thisRaceID,ULT_FOCUS,true,true);
					bInFocus[client]=true;
					hFocusTimer[client]=CreateTimer(FocusDuration[FocusLevel],EndFocus,client);
					War3_SetBuff(client,fAttackSpeed,thisRaceID,FocusAttackSpeed[FocusLevel]);
					new seconds = RoundToZero(FocusDuration[FocusLevel]);
					CPrintToChat(client, "{red} Harnessing your focus for {green}%i seconds",seconds);
					EmitSoundToAll(FocusSound,client);
				}
			}
		}
		else
			W3MsgUltNotLeveled(client);
	}
}

public Action:EndFocus(Handle:timer,any:client)
{
	if(ValidPlayer(client,true) && War3_GetRace(client)==thisRaceID && bInFocus[client])
	{
		bInFocus[client]=false;
		W3ResetBuffRace(client,fAttackSpeed,thisRaceID);
	}
}























