/**
* File: War3Source_Acolyte.sp
* Description: The Acolyte race for War3Source.
* Author(s): TeacherCreature 
*/
#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdkhooks>
#include <clients>

new thisRaceID;

public Plugin:myinfo = 
{
	name = "War3Source Race - Acolyte",
	author = "TeacherCreature",
	description = "Acolyte for War3Source.",
	version = "1.0.8",
	url = "http://warcraft-source.net/"
};

public OnPluginStart()
{
	HookEvent("round_start",RoundStartEvent);
}

new MoneyOffsetCS;
new BeamSprite,BeamSprite2,HaloSprite;


public OnMapStart()
{
	BeamSprite=PrecacheModel("Models/MANHACK/Blur01.vmt");
	CreateTimer(0.2,restore,_,TIMER_REPEAT);
	HookEvent("round_start",RoundStartEvent);
	MoneyOffsetCS=FindSendPropInfo("CCSPlayer","m_iAccount");
	BeamSprite2=PrecacheModel("materials/sprites/lgtning.vmt");
	HaloSprite=PrecacheModel("materials/sprites/halo01.vmt");
}

new SKILL_RESTORE, SKILL_UNSUMMON, ULT_SACRIFICE;

new HealAmt[7]={0,70,60,50,40,30,20};
new summ[]={0,250,300,350,400,450,500};
new bool:bRestore[66];
new bool:bShade[66];
new Float:cool[7]={30.0, 28.0, 26.0, 24.0, 22.0, 20.0, 18.0};
new healarr[7]={0, 28, 26, 24, 22, 20, 18};
new Float:Location[66][3];
new Float:Eyes[66][3];

public OnWar3PluginReady()
{
	thisRaceID=War3_CreateNewRace("Acolyte","acolyte");
	SKILL_RESTORE=War3_AddRaceSkill(thisRaceID,"Restore(ability)","Use resources to heal",false,6);
	SKILL_UNSUMMON=War3_AddRaceSkill(thisRaceID,"UnSummon(ability1)","Unsummon primary for resources",false,6);
	ULT_SACRIFICE=War3_AddRaceSkill(thisRaceID,"Sacrifice","Turns Acolyte into a shade",false,6);
	War3_CreateRaceEnd(thisRaceID);
}

stock GetMoney(player)
{
	return GetEntData(player,MoneyOffsetCS);
}

stock SetMoney(player,money)
{
	SetEntData(player,MoneyOffsetCS,money);
}

public RoundStartEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	for(new i=1;i<=MaxClients;i++)
	{
		if(ValidPlayer(i,true))
		{
			if(War3_GetRace(i)==thisRaceID)
			{
				SetMoney(i,2000);
				bShade[i]=false;
				bRestore[i]=false;
				War3_SetBuff(i,fInvisibilitySkill,thisRaceID,1.0);
				War3_SetBuff(i,bNoClipMode,thisRaceID,false);
			}
		}
	}
}

stock TE_SetupDynamicLight(const Float:vecOrigin[3], r,g,b,iExponent,Float:fRadius,Float:fTime,Float:fDecay)
{
	TE_Start("Dynamic Light");
	TE_WriteVector("m_vecOrigin",vecOrigin);
	TE_WriteNum("r",r);
	TE_WriteNum("g",g);
	TE_WriteNum("b",b);
	TE_WriteNum("exponent",iExponent);
	TE_WriteFloat("m_fRadius",fRadius);
	TE_WriteFloat("m_fTime",fTime);
	TE_WriteFloat("m_fDecay",fDecay);
}

public Action:restore(Handle:timer,any:client)
{
	if(thisRaceID>0)
	{
		for(new i=1;i<=MaxClients;i++)
		{
			if(ValidPlayer(i,true))
			{
				new rest=War3_GetSkillLevel(i,thisRaceID,SKILL_RESTORE);
				if(War3_GetRace(i)==thisRaceID && rest>0 && bRestore[i])
				{
					new money=GetMoney(i);
					if(money>HealAmt[rest])
					{
						SetMoney(i,money-HealAmt[rest]);
						SetEntityHealth(i,GetClientHealth(i)+1);
					}
				}
			}
		}
	}
}

public OnWar3EventSpawn(client)
{
	new race = War3_GetRace(client);
	if (race == thisRaceID)
	{
		bShade[client]=false;
		bRestore[client]=false;
		War3_SetBuff(client,fInvisibilitySkill,thisRaceID,1.0);
		War3_WeaponRestrictTo(client,thisRaceID,"");
		GivePlayerItem(client,"weapon_deagle");
	}
}

public OnRaceChanged(client, oldrace, newrace)
{
	if(newrace != thisRaceID)
	{
		War3_SetBuff(client,bNoClipMode,thisRaceID,false);
		War3_SetBuff(client,fInvisibilitySkill,thisRaceID,1.0);
		if(ValidPlayer(client,true))
			bShade[client]=false;
	}
	if(newrace == thisRaceID)
	{
		if(ValidPlayer(client,true))
		{
			bRestore[client]=false;
			War3_WeaponRestrictTo(client,thisRaceID,"");
			GivePlayerItem(client,"weapon_deagle");
		}
	}
}

public OnAbilityCommand(client,ability,bool:pressed)
{
	if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && IsPlayerAlive(client))
	{
		new skill=War3_GetSkillLevel(client,thisRaceID,SKILL_RESTORE);
		if(skill>0)
		{
			if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_RESTORE,true))
			{
				if(!Silenced(client))
				{
					if(!bRestore[client])
					{
						bRestore[client]=true;
						new Float:iVec[3];
						GetClientAbsOrigin(client, Float:iVec);
						iVec[2]+=15;
						TE_SetupBeamRingPoint(iVec,1.0,999.0,BeamSprite2,HaloSprite,0,15,0.3,150.0,2.0,{255,255,0,255},0,0);
						TE_SendToAll();
						TE_SetupBeamRingPoint(iVec,999.0,1.0,BeamSprite2,HaloSprite,0,15,0.5,150.0,2.0,{0,255,0,255},0,0);
						TE_SendToAll(0.3);
						War3_CooldownMGR(client,1.0,thisRaceID,SKILL_RESTORE);
					}
					else
					{
						bRestore[client]=false;
						War3_CooldownMGR(client,10.0,thisRaceID,SKILL_RESTORE);
					}
				}		
				else
				{
					PrintHintText(client,"Silenced: Can not cast");
				}
			}
			
		}
	}
	if(War3_GetRace(client)==thisRaceID && ability==1 && pressed && IsPlayerAlive(client))
	{
		new level=War3_GetSkillLevel(client,thisRaceID,SKILL_UNSUMMON);
		if(level>0)
		{
			if(!Silenced(client))
			{
				if(GetPlayerWeaponSlot(client, 0)>0)
				{
					War3_CooldownMGR(client,1.0,thisRaceID,SKILL_UNSUMMON);
					RemovePlayerItem(client, GetPlayerWeaponSlot(client, 0));
					new wmoney=GetMoney(client);
					SetMoney(client,wmoney+summ[level]);
					PrintHintText(client,"Weapon unsummoned");						
				}
			}		
			else
			{
				PrintHintText(client,"Silenced: Can not cast");
			}
		}
	}
}

public Action:UnShade(Handle:timer,any:client)
{
	if(ValidPlayer(client) && bShade[client]==true)
	{
		new ult_level=War3_GetSkillLevel(client,thisRaceID,ULT_SACRIFICE);
		bShade[client]=false;
		War3_SetBuff(client,fInvisibilitySkill,thisRaceID,1.0);
		War3_SetBuff(client,bNoClipMode,thisRaceID,false);
		War3_CooldownMGR(client,cool[ult_level],thisRaceID,ULT_SACRIFICE);
		War3_WeaponRestrictTo(client,thisRaceID,"");
		if(IsPlayerAlive(client))
		{
			TeleportEntity(client,Location[client],Eyes[client],NULL_VECTOR);
			GivePlayerItem(client, "weapon_deagle");
		}
	}
}

public OnUltimateCommand(client,race,bool:pressed)
{
	if(race==thisRaceID && pressed && ValidPlayer(client,true))
	{
		new ult_level=War3_GetSkillLevel(client,race,ULT_SACRIFICE);
		if(ult_level>0)		
		{
			if(War3_SkillNotInCooldown(client,thisRaceID,ULT_SACRIFICE,false)) 
			{
				if(!Silenced(client))
				{
					{
						new hpcheck=GetClientHealth(client);
						if(hpcheck>healarr[ult_level])
						{						
							W3FlashScreen(client,{40,40,40,220},6.0,1.0,FFADE_OUT);
							War3_WeaponRestrictTo(client,thisRaceID,"weapon_smokegrenade");
							War3_CooldownMGR(client,10.0,thisRaceID,ULT_SACRIFICE);
							War3_DealDamage(client,healarr[ult_level],client,DMG_BULLET,"Sacrifice");
							War3_SetBuff(client,bNoClipMode,thisRaceID,true);
							GetClientEyeAngles(client,Eyes[client]);
							GetClientAbsOrigin(client,Location[client]);
							for(new target=1;target<=MaxClients;target++)
							{
								if(ValidPlayer(target,true))
								{
									new team = GetClientTeam(target);
									new cteam = GetClientTeam(client);
									if(team != cteam)
									{
										new Float:pos[3];
										GetClientAbsOrigin(target,pos);
										TE_SetupDynamicLight(pos,255,2,2,500,80.0,0.5,9.5);
										TE_SendToClient(client, 0.1); 
										TE_SetupBubbles(pos, pos,BeamSprite,900.0, 25, 900.0);
										TE_SendToClient(client, 0.1); 
									}
								}
							}
							bShade[client]=true;
							War3_SetBuff(client,fInvisibilitySkill,thisRaceID,0.0);
							CreateTimer(5.0,UnShade,client);
						}
						else
						{
							PrintHintText(client,"You are too weak");
						}
					}
				}
				else
				{
					PrintHintText(client,"Silenced: Can not cast");
				}
			}
			
		}
		else
		{
			PrintHintText(client,"Level Your Ultimate First");
		}
	}
}
