#pragma semicolon 1
 
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdkhooks>

public Plugin:myinfo = 
{
	name = "War3Source Race - Othell Rogue",
	author = "ABGar",
	description = "The Othell Rogue race for War3Source.",
	version = "1.0",
	// ABGar / Campalot's Private Race - http://www.sevensinsgaming.com/forum/index.php?/topic/5451-othell-rogue
}

new thisRaceID;

new SKILL_CLONE, SKILL_BLOOD, SKILL_SCORP, ULT_DISARM;

// SKILL_CLONE
new CloneSprite, CloneSprite2, g_iExplosionModel, g_iSmokeModel;
new Float:CloneRange=200.0;
new Float:CloneExplodeTime=4.0;
new Float:CloneDamageCentre=100.0;
new Float:ClonePos[MAXPLAYERSCUSTOM][3];
new Float:CloneCD[]={0.0,50.0,40.0,30.0,20.0};
new String:ExplodeSound[]="weapons/explode5.wav";

// SKILL_BLOOD
new PoisonDamage=5;
new Float:BloodCD=5.0;
new Float:PoisonDuration=4.0;
new Float:BloodChance[]={0.0,0.6,0.7,0.8,0.9};
new bool:bPoisoned[MAXPLAYERSCUSTOM];

// SKILL_SCORP
new Float:ScorpCD=5.0;
new Float:ScorpChance[]={0.0,0.2,0.3,0.4,0.6};

// ULT_DISARM
new BeamSprite,HaloSprite;
new Float:DisarmTime[]={0.0,1.0,1.5,2.0,3.0};
new Float:DisarmCD[]={0.0,40.0,35.0,30.0,20.0};
new Float:DisarmRange[]={0.0,300.0,350.0,400.0,500.0};
new String:DisarmSound[]="war3source/entanglingrootsdecay1.wav";


public OnWar3PluginReady()
{
	thisRaceID=War3_CreateNewRace("Othell Rogue [PRIVATE]","othellrogue");
	SKILL_CLONE = War3_AddRaceSkill(thisRaceID,"Clone Attack","Summon a clone that explodes after 4 seconds (+ability)",false,4);
	SKILL_BLOOD = War3_AddRaceSkill(thisRaceID,"Blood Stab","A chance to poison and drug your enemies with your knife (passive)",false,4);
	SKILL_SCORP = War3_AddRaceSkill(thisRaceID,"Scorpion Poison","A chance to inflict poison and critical damage with your AK47 (passive)",false,4);
	ULT_DISARM=War3_AddRaceSkill(thisRaceID,"Lightning Disarm","Root nearby enemies in place (+ultimate) (+ultimate)",true,4);
	War3_CreateRaceEnd(thisRaceID);
	W3SkillCooldownOnSpawn(thisRaceID,SKILL_CLONE,10.0,_);
	W3SkillCooldownOnSpawn(thisRaceID,ULT_DISARM,10.0,_);
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
	War3_WeaponRestrictTo(client,thisRaceID,"weapon_ak47,weapon_knife");
	GivePlayerItem(client,"weapon_ak47");
}


public OnMapStart()
{
	BeamSprite=PrecacheModel("materials/sprites/lgtning.vmt");
	HaloSprite=PrecacheModel("materials/sprites/halo01.vmt");
	CloneSprite=PrecacheModel("models/player/t_leet.mdl");
	CloneSprite2=PrecacheModel("models/player/ct_urban.mdl");
	g_iExplosionModel = PrecacheModel("materials/effects/fire_cloud1.vmt");
	g_iSmokeModel = PrecacheModel("materials/effects/fire_cloud2.vmt");
	War3_PrecacheSound(ExplodeSound);
	War3_PrecacheSound(DisarmSound);
}

public OnPluginStart()
{
	CreateTimer(1.0,Poison,_,TIMER_REPEAT);
}

/* *************************************** (SKILL_CLONE) *************************************** */
public OnAbilityCommand(client,ability,bool:pressed)
{
	if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && ValidPlayer(client,true))
	{
		new CloneLevel=War3_GetSkillLevel(client,thisRaceID,SKILL_CLONE);
		if(CloneLevel>0)
		{
			if(SkillAvailable(client,thisRaceID,SKILL_CLONE,true,true,true))
			{
				War3_CooldownMGR(client,CloneCD[CloneLevel],thisRaceID,SKILL_CLONE,true,true);
				GetClientAbsOrigin(client,ClonePos[client]);
				if(GetClientTeam(client)==TEAM_T)
				{
					TE_SetupGlowSprite(ClonePos[client],CloneSprite,4.0,1.0,250);
					TE_SendToAll();
				}
				else if(GetClientTeam(client)==TEAM_CT)
				{
					TE_SetupGlowSprite(ClonePos[client],CloneSprite2,4.0,1.0,250);
					TE_SendToAll();
				}
				CreateTimer(CloneExplodeTime,ExplodeClone,client);
			}
		}
		else
			PrintHintText(client,"Level your skill first");
	}
}

public Action:ExplodeClone(Handle:t,any:client)
{
	if(ValidPlayer(client) && War3_GetRace(client)==thisRaceID)
	{
		new Float:EnemyPos[3];
		TE_SetupExplosion(ClonePos[client], g_iExplosionModel, 20.0, 10, TE_EXPLFLAG_NONE, 150, 125);
		TE_SendToAll();
		TE_SetupSmoke(ClonePos[client], g_iExplosionModel, 100.0, 2);
		TE_SendToAll();
		TE_SetupSmoke(ClonePos[client], g_iSmokeModel, 100.0, 2);
		TE_SendToAll();
		EmitSoundToAll(ExplodeSound,client);
		
		for(new enemy=1;enemy<=MaxClients;++enemy)
		{
			if(ValidPlayer(enemy,true) && GetClientTeam(client)!=GetClientTeam(enemy) && SkillFilter(enemy))
			{
				GetClientAbsOrigin(enemy,EnemyPos);
				new Float:Distance=GetVectorDistance(ClonePos[client],EnemyPos);
				if(Distance<=(CloneRange))
				{
					new Float:DmgFactor=(CloneRange-Distance)/CloneRange;
					new DamageAmount=RoundFloat(CloneDamageCentre*DmgFactor);
					War3_DealDamage(enemy,DamageAmount,client,DMG_BLAST,"clone bomb");
					W3FlashScreen(enemy,RGBA_COLOR_RED);
				}
			}
		}
	}
}

/* *************************************** (SKILL_BLOOD / SKILL_SCORP) *************************************** */
public OnW3TakeDmgBullet(victim,attacker,Float:damage)
{
	if(ValidPlayer(victim) && ValidPlayer(attacker) && GetClientTeam(attacker)!=GetClientTeam(victim))
	{
		if(War3_GetRace(attacker)==thisRaceID)
		{
			new BloodLevel = War3_GetSkillLevel(attacker,thisRaceID,SKILL_BLOOD);
			new ScorpLevel = War3_GetSkillLevel(attacker,thisRaceID,SKILL_SCORP);
			new String:weapon[32]; 
			GetClientWeapon(attacker,weapon,32);
			if(StrEqual(weapon,"weapon_knife"))
			{
				if(BloodLevel>0)
				{
					if(SkillAvailable(attacker,thisRaceID,SKILL_BLOOD,true,true,true))
					{
						if(W3Chance(BloodChance[BloodLevel]))
						{
							War3_CooldownMGR(attacker,BloodCD,thisRaceID,SKILL_BLOOD,true,true);
							ClientCommand(victim, "r_screenoverlay effects/tp_eyefx/tp_eyefx.vmt");
							bPoisoned[victim]=true;
							CreateTimer(2.0,StopDrug,victim);
							CreateTimer(PoisonDuration,StopPoison,victim);
						}
					}
				}
			}
			else if(StrEqual(weapon,"weapon_ak47"))
			{
				if(ScorpLevel>0)
				{
					if(SkillAvailable(attacker,thisRaceID,SKILL_SCORP,true,true,true))
					{
						if(W3Chance(ScorpChance[ScorpLevel]))
						{
							War3_CooldownMGR(attacker,ScorpCD,thisRaceID,SKILL_SCORP,true,true);
							bPoisoned[victim]=true;
							CreateTimer(PoisonDuration,StopPoison,victim);
						}
					}
				}
			}
		}
	}
}

public Action:StopDrug(Handle:timer,any:client)
{
	if(ValidPlayer(client) && bPoisoned[client])
	{
		ClientCommand(client, "r_screenoverlay 0");
	}
}

public Action:StopPoison(Handle:timer,any:client)
{
	if(ValidPlayer(client) && bPoisoned[client])
	{
		bPoisoned[client]=false;
	}
}

public Action:Poison(Handle:timer,any:userid)
{
	for(new client=1;client<=MaxClients;client++)
	{
		if(ValidPlayer(client,true) && War3_GetRace(client)==thisRaceID)
		{
			for (new enemy=1;enemy<=MaxClients;enemy++)
			{
				if(ValidPlayer(enemy) && War3_GetRace(client)!=War3_GetRace(enemy) && SkillFilter(client))
				{
					if(bPoisoned[enemy])
					{
						War3_DealDamage(enemy,PoisonDamage,client,DMG_POISON,"poison");
						W3FlashScreen(enemy,RGBA_COLOR_GREEN);
					}
				}
			}
		}
	}
}

/* *************************************** (ULT_DISARM) *************************************** */

public OnUltimateCommand(client,race,bool:pressed)
{
    if(War3_GetRace(client)==thisRaceID && pressed && ValidPlayer(client,true))
    {
        new DisarmLevel=War3_GetSkillLevel(client,thisRaceID,ULT_DISARM);
        if(DisarmLevel>0)
        {
			if(SkillAvailable(client,thisRaceID,ULT_DISARM,true,true,true))
			{
				for(new enemy=1;enemy<=MaxClients;enemy++)
				{
					War3_CooldownMGR(client,DisarmCD[DisarmLevel],thisRaceID,ULT_DISARM,_,_);
					
					new Float:MyPos[3];			
					new Float:EnemyPos[3];
					if(ValidPlayer(enemy,true) && GetClientTeam(enemy)!=GetClientTeam(client) && UltFilter(enemy))
					{
						GetClientAbsOrigin(client,MyPos);
						GetClientAbsOrigin(enemy,EnemyPos);
						if(GetVectorDistance(MyPos,EnemyPos)<=DisarmRange[DisarmLevel])
						{
							War3_SetBuff(enemy,bBashed,thisRaceID,true);
							CreateTimer(DisarmTime[DisarmLevel],StopDisarm,enemy);
							EnemyPos[2]+=15.0;
							TE_SetupBeamRingPoint(EnemyPos,45.0,44.0,BeamSprite,HaloSprite,0,15,DisarmTime[DisarmLevel],5.0,50.0,{0,255,0,255},0,0);
							TE_SendToAll();
							EnemyPos[2]+=15.0;
							TE_SetupBeamRingPoint(EnemyPos,45.0,44.0,BeamSprite,HaloSprite,0,15,DisarmTime[DisarmLevel],5.0,50.0,{0,255,0,255},0,0);
							TE_SendToAll();
							EnemyPos[2]+=15.0;
							TE_SetupBeamRingPoint(EnemyPos,45.0,44.0,BeamSprite,HaloSprite,0,15,DisarmTime[DisarmLevel],5.0,50.0,{0,255,0,255},0,0);
							TE_SendToAll();
							EmitSoundToAll(DisarmSound,enemy);
						}
					}
				}
			}
		}
		else
			W3MsgUltNotLeveled(client);
	}
}			

public Action:StopDisarm(Handle:timer,any:client)
{
	if(ValidPlayer(client))
	{
		War3_SetBuff(client,bBashed,thisRaceID,false);
	}
}