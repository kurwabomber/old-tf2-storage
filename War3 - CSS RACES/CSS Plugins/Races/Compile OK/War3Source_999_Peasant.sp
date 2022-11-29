/**
* File: War3Source_Peasant.sp
* Description: The Peasant race for War3Source.
* Author(s): TeacherCreature 
*/
#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdkhooks>
#include <clients>
#include <smlib>

new thisRaceID;
// Effects
new BeamSprite,HaloSprite;

public Plugin:myinfo = 
{
	name = "War3Source Race - Peasant",
	author = "TeacherCreature",
	description = "Peasant for War3Source.",
	version = "1.0.7",
	url = "http://warcraft-source.net/"
};

public OnPluginStart()
{
	HookEvent("round_start",RoundStartEvent);
}

new MoneyOffsetCS;

public OnMapStart()
{
	CreateTimer(3.0,repair,_,TIMER_REPEAT);
	HookEvent("round_start",RoundStartEvent);
	HookEvent("round_end",RoundEndEvent);
	MoneyOffsetCS=FindSendPropInfo("CCSPlayer","m_iAccount");
	BeamSprite=PrecacheModel("materials/sprites/laser.vmt");
	HaloSprite=PrecacheModel("materials/sprites/halo01.vmt");	
}

new SKILL_REPAIR, SKILL_GATHER, ULT_MILITIA;

new HealArr[]={0,1,2,3,4,5,6};
new Float:GatherArr[]={0.0,0.1,0.2,0.3,0.4,0.5,0.6};
new bool:bMilitia[66];
new Float:cool[]={0.0, 20.0, 18.0, 16.0, 14.0, 12.0, 10.0};

public OnWar3PluginReady()
{
	thisRaceID=War3_CreateNewRace("Peasant","peasant");
	SKILL_REPAIR=War3_AddRaceSkill(thisRaceID,"Repair(auto-cast)","Use money to heal",false,6);
	SKILL_GATHER=War3_AddRaceSkill(thisRaceID,"Gather(attack)","Steal money from the enemy",false,6);
	ULT_MILITIA=War3_AddRaceSkill(thisRaceID,"Call to Arms","Train as Militia",false,6);
	War3_CreateRaceEnd(thisRaceID);
}

public RoundStartEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	for(new i=1;i<=MaxClients;i++)	
	{
		if(ValidPlayer(i))
		{
			bMilitia[i]=false;
		}
	}
}

public RoundEndEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	for(new i=1;i<=MaxClients;i++)
	{
		if(ValidPlayer(i)&&War3_GetRace(i)==thisRaceID)
		{
			War3_WeaponRestrictTo(i,thisRaceID,"weapon_p228");
		}
	}
}

public OnWar3EventSpawn(client)
{
	new race = War3_GetRace(client);
	if (race == thisRaceID)
	{
		War3_SetBuff( client, iAdditionalMaxHealthNoHPChange, thisRaceID, 50);
		bMilitia[client]=false;
		War3_WeaponRestrictTo(client,thisRaceID,"weapon_p228");
		GivePlayerItem(client, "weapon_p228");
	}
}

public OnRaceChanged(client, oldrace, newrace)
{
	if(newrace == thisRaceID)
	{
		if(ValidPlayer(client,true))
		{
			War3_SetBuff( client, iAdditionalMaxHealthNoHPChange, thisRaceID, 150);	
			War3_WeaponRestrictTo(client,thisRaceID,"weapon_p228");
			GivePlayerItem(client, "weapon_p228");
		}
	}
	else
	{
		bMilitia[client]=false;
		War3_WeaponRestrictTo(client,thisRaceID,"");
		W3ResetAllBuffRace( client, thisRaceID );
	}
}

stock GetMoney(player)
{
	return GetEntData(player,MoneyOffsetCS);
}

stock SetMoney(player,money)
{
	SetEntData(player,MoneyOffsetCS,money);
}

public Action:repair(Handle:timer,any:client)
{
	if(thisRaceID>0)
	{
		for(new i=1;i<=MaxClients;i++)
		{
			if(ValidPlayer(i,true))
			{
				new reap=War3_GetSkillLevel(i,thisRaceID,SKILL_REPAIR);
				if(War3_GetRace(i)==thisRaceID && reap>0)
				{
					new money=GetMoney(i);
					new hpcheck = GetClientHealth(i);
					if(money>100 && hpcheck < 150)
					{
						SetMoney(i,money-100);
						War3_HealToMaxHP(i,HealArr[reap]);
					}
				}
			}
		}
	}
}

public OnW3TakeDmgBullet(victim,attacker,Float:damage)
{
	if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim)
	{
		new vteam=GetClientTeam(victim);
		new ateam=GetClientTeam(attacker);
		if(vteam!=ateam)
		{
			new race_attacker=War3_GetRace(attacker);
			new skill=War3_GetSkillLevel(attacker,thisRaceID,SKILL_GATHER);
			if(race_attacker==thisRaceID && skill>0)
			{
				if(GetRandomFloat(0.0,1.0) < GatherArr[skill] && !W3HasImmunity(victim,Immunity_Skills))
				{
					new vmoney=GetMoney(victim);
					new amoney=GetMoney(attacker);
					if(vmoney > 100)
					{
						SetMoney(victim,vmoney-100);
						SetMoney(attacker,amoney+100);
						new Float:effect_vec[3];
						GetClientAbsOrigin(victim,effect_vec);
						new Float:effect_vec2[3];
						GetClientAbsOrigin(attacker,effect_vec2);
						effect_vec[2]+=15.0;
						effect_vec2[2]+=15.0;
						TE_SetupBeamRingPoint(effect_vec,1.0,400.0,BeamSprite,HaloSprite,0,15,0.3,10.0,0.0,{225,225,0,255},10,0);
						TE_SendToAll();
						TE_SetupBeamRingPoint(effect_vec2,400.0,1.0,BeamSprite,HaloSprite,0,15,0.3,5.0,4.0,{225,225,0,255},10,0);
						TE_SendToAll(0.3);
						effect_vec[2]+=15.0;
						effect_vec2[2]+=15.0;
						TE_SetupBeamRingPoint(effect_vec,1.0,400.0,BeamSprite,HaloSprite,0,15,0.3,5.0,0.0,{225,225,0,255},10,0);
						TE_SendToAll();
						TE_SetupBeamRingPoint(effect_vec2,400.0,1.0,BeamSprite,HaloSprite,0,15,0.3,5.0,4.0,{225,225,0,255},10,0);
						TE_SendToAll(0.3);
						effect_vec[2]+=15.0;
						effect_vec2[2]+=15.0;
						TE_SetupBeamRingPoint(effect_vec,1.0,400.0,BeamSprite,HaloSprite,0,15,0.3,5.0,0.0,{225,225,0,255},10,0);
						TE_SendToAll();
						TE_SetupBeamRingPoint(effect_vec2,400.0,1.0,BeamSprite,HaloSprite,0,15,0.3,5.0,4.0,{225,225,0,255},10,0);
						TE_SendToAll(0.3);
					}
				}
			}
		}
	}
}

public OnUltimateCommand(client,race,bool:pressed)
{
	if(race==thisRaceID && pressed && ValidPlayer(client,true))
	{
		new ult_level=War3_GetSkillLevel(client,race,ULT_MILITIA);
		if(ult_level>0)		
		{
			if(War3_SkillNotInCooldown(client,thisRaceID,ULT_MILITIA,false)) 
			{
				if(!Silenced(client))
				{
					if(!bMilitia[client])
					{
						bMilitia[client]=true;
						War3_WeaponRestrictTo(client,thisRaceID,"weapon_tmp");
						GivePlayerItem(client, "weapon_tmp");
						new Float:effect_vec[3];
						GetClientAbsOrigin(client,effect_vec);
						new Float:effect_vec2[3];
						GetClientAbsOrigin(client,effect_vec2);
						effect_vec[2]+=9999;
						effect_vec2[2]-=50;
						TE_SetupBeamPoints(effect_vec,effect_vec2,BeamSprite,HaloSprite,0,0,1.0,500.0,500.0,0,0.1,{153,0,153,255},0);
						TE_SendToAll();
						CreateTimer(8.0,regular,client);
						
					}	
					War3_CooldownMGR(client,cool[ult_level],thisRaceID,ULT_MILITIA);
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

public Action:regular(Handle:timer,any:client)
{
	if(ValidPlayer(client,true))
	{
		bMilitia[client]=false;
        new primweapon = Client_GetWeaponBySlot(client, 0);  
        if (primweapon > -1)
        {
            new String:temp[128];
            GetEntityClassname(primweapon, temp, sizeof(temp));
            Client_RemoveWeapon(client, temp);
        }
		new Float:effect_vec3[3];
		GetClientAbsOrigin(client,effect_vec3);
		new Float:effect_vec4[3];
		GetClientAbsOrigin(client,effect_vec4);
		effect_vec3[2]+=9999;
		effect_vec4[2]-=50;
		TE_SetupBeamPoints(effect_vec3,effect_vec4,BeamSprite,HaloSprite,0,0,1.0,500.0,500.0,0,0.1,{153,0,153,255},10);
		TE_SendToAll();
		War3_WeaponRestrictTo(client,thisRaceID,"weapon_p228");
		GivePlayerItem(client, "weapon_p228");
	}
}