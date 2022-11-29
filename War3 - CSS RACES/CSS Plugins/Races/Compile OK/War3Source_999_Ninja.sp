/**
* File: War3Source_[Cereal] NINJA.sp
* Description: a race for War3Source.
* Author(s): Cereal Killer
*/

// War3Source stuff
#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdktools_functions>
#include <sdktools_tempents>
#include <sdktools_tempents_stocks>
#include <sdkhooks>

new thisRaceID;

new Float:SuperSpeed[7]={0.0,1.1,1.2,1.3,1.4,1.5,1.6}; 
new Float:InvisibilityAlpha[7]={1.0,0.75,0.65,0.60,0.55,0.50,0.40};
new Float:SkillLongJump[7]={0.0,2.0,2.5,3.0,4.5,5.0,5.5};
new Float:DodgeChance[7]={0.0,0.05,0.10,0.15,0.20,0.25,0.3};
new Float:VanishChance[7]={0.0,0.1,0.2,0.3,0.4,0.45,0.5};
new Handle:ultRangeCvar;
new g_offsCollisionGroup;
new m_vecVelocity_0, m_vecVelocity_1, m_vecBaseVelocity;
new Float:ASSASSINATION_cooldown[7]={40.0,35.0,30.0,25.0,20.0,15.0,10.0};
new String:ultimateSound[]="ambient/office/coinslot1.wav";

new SKILL_SPEED, SKILL_INVIS, SKILL_LONGJUMP, SKILL_DODGE, SKILL_VANISH, ULT_ASSASSINATION;

public Plugin:myinfo = 
{
	name = "War3Source Race - [Cereal] Ninja",
	author = "Cereal Killer",
	description = "The Ninja race for War3Source.",
	version = "1.0.0.2",
	url = "http://war3source.com"
};

public OnPluginStart()
{
	ultRangeCvar=CreateConVar("war3_assassination_range","99999","Range of assination ultimate");
	g_offsCollisionGroup = FindSendPropOffs("CBaseEntity", "m_CollisionGroup");
	m_vecVelocity_0 = FindSendPropOffs("CBasePlayer","m_vecVelocity[0]");
	m_vecVelocity_1 = FindSendPropOffs("CBasePlayer","m_vecVelocity[1]");
	m_vecBaseVelocity = FindSendPropOffs("CBasePlayer","m_vecBaseVelocity");
	HookEvent("player_jump",PlayerJumpEvent);
}

public OnWar3PluginReady()
{
	thisRaceID=War3_CreateNewRace("[Cereal] Ninja","ninja");
	SKILL_INVIS=War3_AddRaceSkill(thisRaceID,"Camo","blend in with the environment",false,6);
	SKILL_LONGJUMP=War3_AddRaceSkill(thisRaceID,"Long Jump","Jump farther",false,6);
	SKILL_DODGE=War3_AddRaceSkill(thisRaceID,"Dodge Bullets (DISABLED)","Evade Bullets",false,6);
	SKILL_VANISH=War3_AddRaceSkill(thisRaceID,"Vanish (DISABLED)","Vanish when shot",false,6);
	ULT_ASSASSINATION=War3_AddRaceSkill(thisRaceID,"Assassination","Get behind a random enemy",true,6);
	War3_CreateRaceEnd(thisRaceID);
}

public OnMapStart()
{
	War3_PrecacheSound(ultimateSound);
}
	
new Float:position[3];
public OnUltimateCommand(client,race,bool:pressed)
{
	new userid=GetClientUserId(client);
	if(race==thisRaceID && pressed && userid>1 && IsPlayerAlive(client) )
	{
		new ult_level=War3_GetSkillLevel(client,race,ULT_ASSASSINATION);
		if(ult_level>0)
		{	
			if(War3_SkillNotInCooldown(client,thisRaceID,ULT_ASSASSINATION,true))
			{
				new Float:posVec[3];
				GetClientAbsOrigin(client,posVec);
				new Float:otherVec[3];
				new Float:bestTargetDistance=240.0;
				new team = GetClientTeam(client);
				new bestTarget=0;		
				new Float:ultmaxdistance=GetConVarFloat(ultRangeCvar);
				for(new i=1;i<=MaxClients;i++)
				{
					if(ValidPlayer(i,true)&&GetClientTeam(i)!=team&&!W3HasImmunity(i,Immunity_Ultimates))
					{
						GetClientAbsOrigin(i,otherVec);
						new Float:dist=GetVectorDistance(posVec,otherVec);
						if(dist<bestTargetDistance&&dist<ultmaxdistance)
						{
							bestTarget=i;
							bestTargetDistance=GetVectorDistance(posVec,otherVec);
						}
					}
				}
				if(bestTarget==0)
				{
					W3MsgNoTargetFound(client,ultmaxdistance);
				}
				else
				{
					new damage=RoundFloat(float(War3_GetMaxHP(bestTarget))/2.0);
					if(damage>0)
					{
						War3_CachedPosition(bestTarget,Float:position);
						TeleportEntity(client,position,NULL_VECTOR,NULL_VECTOR);
						SetEntData(bestTarget, g_offsCollisionGroup, 2, 4, true);
						EmitSoundToAll(ultimateSound,client);
						CooldownUltimate(client);
					}
				}
			}
		}
		else
		{
			PrintHintText(client,"Level Your Ultimate First");
		}
	}
}

public CooldownUltimate(client)
{
	new skilllevel_assassination=War3_GetSkillLevel(client,thisRaceID,ULT_ASSASSINATION);
	War3_CooldownMGR(client,ASSASSINATION_cooldown[skilllevel_assassination],thisRaceID,ULT_ASSASSINATION);
}

public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace!=thisRaceID)
	{
		War3_SetBuff(client,fInvisibilitySkill,thisRaceID,1.0); 
		War3_SetBuff(client,fMaxSpeed,thisRaceID,1.0);
		War3_WeaponRestrictTo(client,thisRaceID,"");
		W3ResetAllBuffRace(client,thisRaceID);
	}
	else
	{
		ActivateSkills(client);
		War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife");
		if(ValidPlayer(client,true))
		{
			GivePlayerItem(client, "weapon_knife");		
		}
	}
}

public ActivateSkills(client)
{
	if(War3_GetRace(client)==thisRaceID)
	{		
		
		new skilllevel_unholy=War3_GetSkillLevel(client,thisRaceID,SKILL_SPEED);
		if(skilllevel_unholy)
		{
			new Float:speed=SuperSpeed[skilllevel_unholy];
			War3_SetBuff(client,fMaxSpeed,thisRaceID,speed);
		}
		new skilllevel=War3_GetSkillLevel(client,thisRaceID,SKILL_INVIS);
		new Float:alpha=(War3_GetGame()==Game_CS)?InvisibilityAlpha[skilllevel]:InvisibilityAlpha[skilllevel];
		War3_SetBuff(client,fInvisibilitySkill,thisRaceID,alpha);
		SetEntData(client, g_offsCollisionGroup, 2, 4, true);
	}
}

public OnSkillLevelChanged(client,race,skill,newskilllevel)
{
	if(race==thisRaceID&&skill==0&&newskilllevel>=0&&War3_GetRace(client)==thisRaceID)
	{
		new Float:alpha=(War3_GetGame()==Game_CS)?InvisibilityAlpha[newskilllevel]:InvisibilityAlpha[newskilllevel];
		if(newskilllevel>0 && IsPlayerAlive(client))
		War3_SetBuff(client,fInvisibilitySkill,thisRaceID,alpha);
	}
	if(War3_GetRace(client)==thisRaceID)
	{
		ActivateSkills(client);
	}
}

public OnW3EnemyTakeDmgBulletPre(victim,attacker,Float:damage)
{
	
	/*if(War3_GetRace(victim)==thisRaceID)
	{
		new skill_level_dodge=War3_GetSkillLevel(victim,thisRaceID,SKILL_DODGE);
		if (skill_level_dodge>0 ) 
		{
			if(GetRandomFloat(0.0,1.0)<=DodgeChance[skill_level_dodge] && !W3HasImmunity(attacker,Immunity_Skills) && War3_SkillNotInCooldown(victim,thisRaceID,SKILL_DODGE,false))
			{
                War3_CooldownMGR(victim,5.0,thisRaceID,SKILL_DODGE,true,false);
				W3FlashScreen(victim,RGBA_COLOR_BLUE);		
				War3_DamageModPercent(0.0);
                W3MsgEvaded(victim,attacker);
			}
		}
		
		new skill_level_vanish=War3_GetSkillLevel(victim,thisRaceID,SKILL_VANISH);
		if(GetRandomFloat(0.0,1.0)<=VanishChance[skill_level_vanish] && !W3HasImmunity(attacker,Immunity_Skills) && War3_SkillNotInCooldown(victim,thisRaceID,SKILL_VANISH,false))
		{
            War3_CooldownMGR(victim,5.0,thisRaceID,SKILL_VANISH,true,false);
			PrintHintText(victim,"You disapear in the shadows...");
			War3_SetBuff(victim,fInvisibilitySkill,thisRaceID,0.0);
			CreateTimer(1.5,Invis1,victim);
		}
	}*/
	
}

public Action:Invis1(Handle:timer,any:victim)
{
	if(War3_GetRace(victim)==thisRaceID)
	{
		new skilllevel=War3_GetSkillLevel(victim,thisRaceID,SKILL_INVIS);
		new Float:alpha=InvisibilityAlpha[skilllevel];
		War3_SetBuff(victim,fInvisibilitySkill,thisRaceID,alpha);
	}
}



public OnWar3EventSpawn(client)
{
	SetEntityMoveType(client,MOVETYPE_WALK);
	new race=War3_GetRace(client);
	if(race==thisRaceID)
	{
		ActivateSkills(client);
	}
	if (War3_GetRace(client) == thisRaceID)
	{
		War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife");
		GivePlayerItem(client, "weapon_knife");
	}
}


public PlayerJumpEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	new client = GetClientOfUserId( GetEventInt( event, "userid" ) );
	new race = War3_GetRace( client );
	if( race == thisRaceID )
	{
		new skill_long = War3_GetSkillLevel( client, race, SKILL_LONGJUMP );
		if( skill_long > 0 )
		{
			new Float:velocity[3] = { 0.0, 0.0, 0.0 };
			velocity[0] = GetEntDataFloat( client, m_vecVelocity_0 );
			velocity[1] = GetEntDataFloat( client, m_vecVelocity_1 );
			velocity[0] *= SkillLongJump[skill_long]*0.25;
			velocity[1] *= SkillLongJump[skill_long]*0.25;
			SetEntDataVector( client, m_vecBaseVelocity, velocity, true );
		}
	}
}