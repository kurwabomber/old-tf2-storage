#pragma semicolon 1
 
#include "W3SIncs/War3Source_Interface"
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <smlib>

public Plugin:myinfo = 
{
	name = "War3Source Race - Diablo2 Necromancer",
	author = "ABGar",
	description = "The Diablo2 Necromancer race for War3Source.",
	version = "1.0",
}

new thisRaceID;

new SKILL_AMROUR, SKILL_TAP, SKILL_POISON, ULT_GOLEM;

#define WEAPON_RESTRICT "weapon_knife,weapon_usp,weapon_glock,weapon_p228,weapon_deagle,weapon_fiveseven,weapon_elite"

// SKILL_AMROUR
new AddArmourAmount=10;
new MaxArmour[]={100,120,140,160,180};
new String:ArmourGainSound[]="war3source/d2necromancer/bonekill.wav";

// SKILL_TAP
new Float:TapVampire[]={0.0,0.1,0.15,0.2,0.25};

// SKILL_POISON
new ExplosionModel;
new PoisonDamage=2;
new PoisonCounter=8;
new iPoisonCounter[MAXPLAYERSCUSTOM]={0, ...};
new bPoisonedBy[MAXPLAYERSCUSTOM]={-1, ...};
new PoisonExplodeDamage[]={0,5,10,15,20};
new Float:PoisonRange[]={0.0,100.0,135.0,170.0,205.0};
new Float:PosionChance[]={0.0,0.1,0.15,0.2,0.99};
new String:PoisonSound[]="war3source/d2necromancer/poisonexplode.wav";

// ULT_GOLEM
new BeamSprite,HaloSprite;
new bool:bChanged[MAXPLAYERSCUSTOM]={false, ...};
new Float:GolemCD=20.0;
new Float:GolemDamage[]={0.0,0.25,0.2,0.15,0.1};
new String:GolemSound[]="war3source/d2necromancer/golem.wav";



public OnWar3PluginReady()
{
	thisRaceID=War3_CreateNewRace("Diablo2 Necromancer","d2necro");
	SKILL_AMROUR = War3_AddRaceSkill(thisRaceID,"Bone Armour","This spell summons a barrier created from the bones of fallen warriors (passive) \n Raise max armour to 120/140/160/180. Gain 10 armour when any player dies.",false,4);
	SKILL_TAP = War3_AddRaceSkill(thisRaceID,"Life Tap","The Necromancer is able to reach into the wellspring of mortality and siphon off its essence, consuming it to replace his own (passive) \n Leech health 10/15/20/25%",false,4);
	SKILL_POISON = War3_AddRaceSkill(thisRaceID,"Poison Explosion","This spell permits the Necromancer to accelerate the decomposition of a corpse to an alarming degree (on kill) \n 10/15/20/25% chance to explode an enemy killed, damaging all nearby and poisoning them 2hp per second for 8 seconds.",false,4);
	ULT_GOLEM=War3_AddRaceSkill(thisRaceID,"Blood Golem","Utilizing a small quantity of his own blood, the Necromancer is able to give life to a creature neither living nor dead, yet formed of human tissue (+ultimate) \n Sacrifice 25/20/15/10% hp to revive any deceased player to your team for the duration of the round",true,4);
	War3_CreateRaceEnd(thisRaceID);
	War3_AddSkillBuff(thisRaceID,SKILL_TAP,fVampirePercent,TapVampire);
}

public OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);	
}

public OnMapStart()
{
	AddFileToDownloadsTable("sound/war3source/d2necromancer/bonekill.wav");
	AddFileToDownloadsTable("sound/war3source/d2necromancer/poisonexplode.wav");
	AddFileToDownloadsTable("sound/war3source/d2necromancer/golem.wav");
	War3_PrecacheSound(ArmourGainSound);
	War3_PrecacheSound(PoisonSound);
	War3_PrecacheSound(GolemSound);
	ExplosionModel=PrecacheModel("materials/sprites/zerogxplode.vmt");
	BeamSprite=War3_PrecacheBeamSprite();
	HaloSprite=War3_PrecacheHaloSprite();
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
    for (new i=1; i<MaxClients; i++)
    {
        if (ValidPlayer(i,true))
		{
			iPoisonCounter[i]=0;
			bChanged[i]=false;
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

public InitPassiveSkills(client)
{
	War3_WeaponRestrictTo(client,thisRaceID,WEAPON_RESTRICT);
}

/* *************************************** (ULT_GOLEM) *************************************** */
public OnWar3EventDeath(victim,attacker)
{
	if(bChanged[victim])
	{
		new target_team=GetClientTeam(victim);
		if(target_team==TEAM_T)
		{
			bChanged[victim]=false;
			CS_SwitchTeam(victim, TEAM_CT);
		}
		else
		{
			bChanged[victim]=false;
			CS_SwitchTeam(victim, TEAM_T);
		}
	}
/* *************************************** (SKILL_AMROUR) *************************************** */
	if(GetClientTeam(attacker)!=GetClientTeam(victim))
	{
		iPoisonCounter[victim]=0;
		for(new client=1;client<=MaxClients;client++)
		{
			if(ValidPlayer(client,true) && War3_GetRace(client)==thisRaceID)
			{
				new ArmourLevel=War3_GetSkillLevel(client,thisRaceID,SKILL_AMROUR);
				if(ArmourLevel>0)
				{
					EmitSoundToAll(ArmourGainSound,client);
					new CurArmour=Client_GetArmor(client);
					if(CurArmour+AddArmourAmount>MaxArmour[ArmourLevel])
						Client_SetArmor(client,MaxArmour[ArmourLevel]);
					else
						Client_SetArmor(client,CurArmour+AddArmourAmount);
				}
			}
		}
/* *************************************** (SKILL_POISON) *************************************** */
		if(War3_GetRace(attacker)==thisRaceID && !Silenced(attacker))
		{
			new PoisonLevel=War3_GetSkillLevel(attacker,thisRaceID,SKILL_POISON);
			if(PoisonLevel>0)
			{
				if(SkillFilter(victim) && W3Chance(PosionChance[PoisonLevel]))
				{
					new Float:SuicideLocation[3];	War3_CachedPosition(victim,SuicideLocation);
					TE_SetupExplosion(SuicideLocation,ExplosionModel,10.0,1,0,100,160);
					TE_SendToAll();
					SuicideLocation[2]+=30.0;
					TE_SetupBeamRingPoint(SuicideLocation,1.0,PoisonRange[PoisonLevel],BeamSprite,HaloSprite,0,5,1.0,20.0,1.0,{0,255,0,255},100,0);
					TE_SendToAll();
					SuicideLocation[2]-=30.0;
					EmitSoundToAll(PoisonSound,attacker);
					for(new i=1;i<=MaxClients;i++)
					{
						if(ValidPlayer(i,true) && GetClientTeam(i)==GetClientTeam(victim) && SkillFilter(i))
						{
							new Float:iPos[3];		GetClientAbsOrigin(i,iPos);
							if(GetVectorDistance(SuicideLocation,iPos)<=PoisonRange[PoisonLevel])
							{
								War3_DealDamage(i,PoisonExplodeDamage[PoisonLevel],attacker,_,"poison explosion",W3DMGORIGIN_ULTIMATE,W3DMGTYPE_PHYSICAL);    
								W3FlashScreen(i,RGBA_COLOR_GREEN);
								
								EmitSoundToAll(PoisonSound,i);
								bPoisonedBy[i]=attacker;
								iPoisonCounter[i]=1;
								CreateTimer(1.0,PoisonLoop,i);
							}
						}
					}
				}
			}
		}
	}
}

public Action:PoisonLoop(Handle:timer,any:client)
{
	if(ValidPlayer(client,true) && iPoisonCounter[client]>0 && iPoisonCounter[client]<=PoisonCounter && SkillFilter(client))
	{
		new attacker=bPoisonedBy[client];
		War3_DealDamage(client,PoisonDamage,attacker,_,"poison explosion",W3DMGORIGIN_ULTIMATE,W3DMGTYPE_PHYSICAL);    
		W3FlashScreen(client,RGBA_COLOR_GREEN);
		iPoisonCounter[client]++;
		CreateTimer(1.0,PoisonLoop,client);
	}
}

/* *************************************** (ULT_GOLEM) *************************************** */
public OnUltimateCommand(client,race,bool:pressed)
{
	if(ValidPlayer(client,true) && race==thisRaceID && pressed)
	{
		new GolemLevel=War3_GetSkillLevel(client,thisRaceID,ULT_GOLEM);
		if(GolemLevel>0)
		{
			if(SkillAvailable(client,thisRaceID,ULT_GOLEM,true,true,true))
			{
				new targets[MAXPLAYERS];
				new foundtargets;
				for(new ally=1;ally<=MaxClients;ally++)
				{
					if(ValidPlayer(ally) && !IsPlayerAlive(ally) && GetClientTeam(ally)==GetClientTeam(client))
					{
						targets[foundtargets]=ally;
						foundtargets++;
					}
				}
				if(foundtargets>0)
				{
					new allytarget = targets[GetRandomInt(0,foundtargets)-1];
					if(allytarget>0)
					{
						RevivePlayer(client,allytarget);
					}
				}
				else
				{
					for(new enemy=1;enemy<=MaxClients;enemy++)
					{
						if(ValidPlayer(enemy) && !IsPlayerAlive(enemy) && GetClientTeam(enemy)!=GetClientTeam(client))
						{
							targets[foundtargets]=enemy;
							foundtargets++;
						}
					}
					if(foundtargets>0)
					{
						new enemytarget = targets[GetRandomInt(0,foundtargets)-1];
						if(enemytarget>0)
							RevivePlayer(client,enemytarget);
					}
					else
						W3MsgNoTargetFound(client);
				}
			}
		}
		else
			W3MsgUltNotLeveled(client);
	}
}

public RevivePlayer(client,target)
{
	new GolemLevel=War3_GetSkillLevel(client,thisRaceID,ULT_GOLEM);
	War3_CooldownMGR(client,GolemCD,thisRaceID,ULT_GOLEM,true,true);
	EmitSoundToAll(GolemSound,client);
	new clientHealth=GetClientHealth(client);
	new clientDamage=RoundFloat(clientHealth*GolemDamage[GolemLevel]);
	if(GetClientTeam(target)==TEAM_CT)
	{
		bChanged[target]=true;
		CS_SwitchTeam(target, TEAM_T);
	}
	if(GetClientTeam(target)==TEAM_T)
	{
		bChanged[target]=true;
		CS_SwitchTeam(target, TEAM_CT);
	}
	War3_DealDamage(client,clientDamage,client,DMG_CRUSH,"blood golem sacrifice",_,W3DMGTYPE_MAGIC);
	new Float:clientPos[3];		GetClientAbsOrigin(client,clientPos);
	new Float:clientAng[3];		GetClientEyeAngles(client,clientAng);
	War3_SpawnPlayer(target);
	TeleportEntity(target,clientPos,clientAng,NULL_VECTOR);
}

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	for(new i=1;i<=MaxClients;i++)
	{
		if(ValidPlayer(i,true))
		{
			if(bChanged[i])
			{
				if(GetClientTeam(i)==TEAM_T)
				{
					bChanged[i]=false;
					CS_SwitchTeam(i, TEAM_CT);
				}
				else
				{
					bChanged[i]=false;
					CS_SwitchTeam(i, TEAM_T);
				}
			}
		}
	}
}