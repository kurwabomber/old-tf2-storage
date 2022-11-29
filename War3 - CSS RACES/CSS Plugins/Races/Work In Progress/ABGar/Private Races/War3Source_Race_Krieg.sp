#pragma semicolon 1
 
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdkhooks>

public Plugin:myinfo = 
{
	name = "War3Source Race - Krieg the Psycho",
	author = "ABGar",
	description = "The Krieg the Psycho race for War3Source.",
	version = "1.0",
	// Greed's Private Race Request -http://www.sevensinsgaming.com/forum/index.php?/topic/5331-krieg-the-psycho-private
}

new thisRaceID;

new SKILL_FIRE, SKILL_SOUL, SKILL_BLOOD, ULT_BEAST;

// SKILL_FIRE
new Float:FireChance[]={0.0,0.15,0.20,0.25,0.30};
new Float:FireTime[]={0.0,2.0,2.5,3.0,3.5};

// SKILL_SOUL
new SoulSelfDamage=25;
new Float:SoulCD[]={0.0,35.0,30.0,27.0,23.0};
new String:SummonSound[]="war3source/archmage/summon.wav";

// SKILL_BLOOD
new Float:StandardSpeed[]={1.0,1.1,1.2,1.2,1.2};
new Float:BloodSpeed[]={1.0,1.25,1.3,1.35,1.4};
new Float:BloodDuration=8.0;
new Float:BloodHPRegen=1.0;
new Float:BloodCD=20.0;
new bool:bInBlood[MAXPLAYERSCUSTOM];
new String:BloodSound[]="ambient/explosions/explode_7.wav";

// ULT_BEAST
new BeastExtraHealth=50;
new Float:BeastDamageIncrease=0.5;
new Float:BeastDamageReduce=0.5;
new Float:BeastCD[]={0.0,45.0,40.0,35.0,30.0};
new Float:BeastDuration[]={0.0,6.0,7.0,8.0,10.0};

new bool:bInBeast[MAXPLAYERSCUSTOM];
new String:BeastSound[]="war3source/scorpion/getoverhere.mp3";


public OnWar3PluginReady()
{
	thisRaceID=War3_CreateNewRace("Krieg the Psycho [PRIVATE]","krieg");
	SKILL_FIRE = War3_AddRaceSkill(thisRaceID,"Fire Starter","Chance to ignite enemies on attack (passive)",false,4);
	SKILL_SOUL = War3_AddRaceSkill(thisRaceID,"Redeem the Soul","Revive a teammate using your own blood (+ability)",false,4);
	SKILL_BLOOD = War3_AddRaceSkill(thisRaceID,"Blood Overdrive","Increase your speed and regain your health (+ability1)",false,4);
	ULT_BEAST=War3_AddRaceSkill(thisRaceID,"Release the Beast","Transform into a bad ass Psycho (+ultimate)",true,4);
	War3_CreateRaceEnd(thisRaceID);
	War3_AddSkillBuff(thisRaceID,SKILL_BLOOD,fMaxSpeed,StandardSpeed);
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
	War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife");
	bInBlood[client]=false;
	bInBeast[client]=false;
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", 0.85);
}

public OnMapStart()
{
	War3_PrecacheSound(SummonSound);
	War3_PrecacheSound(BeastSound);
	War3_PrecacheSound(BloodSound);
}

/* *************************************** (SKILL_FIRE) *************************************** */
public OnW3TakeDmgBullet(victim,attacker,Float:damage)
{
	if(ValidPlayer(victim, true) && ValidPlayer(attacker) && GetClientTeam(attacker)!=GetClientTeam(victim))
	{
		if(War3_GetRace(attacker)==thisRaceID)
		{
			new FireLevel = War3_GetSkillLevel(attacker,thisRaceID,SKILL_FIRE);
			if(FireLevel>0)
			{
				if(W3Chance(FireChance[FireLevel]) && SkillFilter(victim))
				{
					IgniteEntity(victim,FireTime[FireLevel]);
				}
			}
		}
	}
}

/* *************************************** (SKILL_SOUL) *************************************** */
public Action:Stop(Handle:timer,any:client)
{
	StopSound(client,SNDCHAN_AUTO,SummonSound);
}

public OnAbilityCommand(client,ability,bool:pressed)
{
	if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && ValidPlayer(client,true))
	{
		new SoulLevel=War3_GetSkillLevel(client,thisRaceID,SKILL_SOUL);
		if(SoulLevel>0)
		{
			if(SkillAvailable(client,thisRaceID,SKILL_SOUL,true,true,true))
			{
				if(GetClientHealth(client)>SoulSelfDamage)
				{
					new Float:MyPos[3];
					War3_CachedPosition(client,MyPos);
					new targets[MAXPLAYERS];
					new foundtargets;
					for(new ally=1;ally<=MaxClients;ally++)
					{
						if(ValidPlayer(ally) && GetClientTeam(ally)==GetClientTeam(client) && !IsPlayerAlive(ally))
						{
							targets[foundtargets]=ally;
							foundtargets++;
						}
					}
					new target;
					if(foundtargets>0)
					{
						target=targets[GetRandomInt(0, foundtargets-1)];
						if(target>0)
						{
							War3_CooldownMGR(client,SoulCD[SoulLevel],thisRaceID,SKILL_SOUL,_,_);
							War3_DealDamage(client,SoulSelfDamage,client,DMG_CRUSH,"redeem the soul",_,W3DMGTYPE_MAGIC);
							new Float:ang[3];
							new Float:pos[3];
							War3_SpawnPlayer(target);
							GetClientEyeAngles(client,ang);
							GetClientAbsOrigin(client,pos);
							TeleportEntity(target,pos,ang,NULL_VECTOR);
							EmitSoundToAll(SummonSound,client);
							CreateTimer(3.0, Stop, client);
						}
					}
					else
						PrintHintText(client,"There are no allies to summon");
				}
				else
					PrintHintText(client,"You don't have enough health - cannot summon");
			}
		}
		else
			PrintHintText(client,"Level your skill first");
	}
/* *************************************** (SKILL_BLOOD) *************************************** */
	if(War3_GetRace(client)==thisRaceID && ability==1 && pressed && ValidPlayer(client,true))
	{
		new BloodLevel=War3_GetSkillLevel(client,thisRaceID,SKILL_BLOOD);
		if(BloodLevel>0)
		{
			if(SkillAvailable(client,thisRaceID,SKILL_BLOOD,true,true,true))
			{
				War3_CooldownMGR(client,(BloodCD+BloodDuration),thisRaceID,SKILL_BLOOD,true,true);
				War3_SetBuff(client,fMaxSpeed,thisRaceID,BloodSpeed[BloodLevel]);
				War3_SetBuff(client,fHPRegen,thisRaceID,BloodHPRegen);
				CreateTimer(BloodDuration,StopBlood,client);
				bInBlood[client]=true;
				EmitSoundToAll(BloodSound,client);
			}
		}
		else
			PrintHintText(client,"Level your skill first");
	}
}

public Action:StopBlood(Handle:timer,any:client)
{
	if(ValidPlayer(client) && bInBlood[client])
	{
		new BloodLevel=War3_GetSkillLevel(client,thisRaceID,SKILL_BLOOD);
		W3ResetBuffRace(client,fHPRegen,thisRaceID);
		bInBlood[client]=false;
		War3_SetBuff(client,fMaxSpeed,thisRaceID,StandardSpeed[BloodLevel]);
		PrintHintText(client,"Blood Mode has ended");
	}
}

/* *************************************** (ULT_BEAST) *************************************** */
public OnUltimateCommand(client,race,bool:pressed)
{
	if(ValidPlayer(client,true) && race==thisRaceID && pressed)
	{
		new BeastLevel=War3_GetSkillLevel(client,thisRaceID,ULT_BEAST);
		if(BeastLevel>0)
		{
			if(SkillAvailable(client,thisRaceID,ULT_BEAST,true,true,true))
			{
				War3_CooldownMGR(client,BeastCD[BeastLevel],thisRaceID,ULT_BEAST,true,true);
				War3_SetBuff(client,fDamageModifier,thisRaceID,BeastDamageIncrease);
				War3_SetBuff(client,iAdditionalMaxHealth,thisRaceID,BeastExtraHealth);
				SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.2);
				EmitSoundToAll(BeastSound,client);
				bInBeast[client]=true;
				CreateTimer(BeastDuration[BeastLevel],StopBeast,client);
			}
		}
		else
			W3MsgUltNotLeveled(client);
	}
}

public Action:StopBeast(Handle:timer,any:client)
{
	if(ValidPlayer(client) && bInBeast[client])
	{
		bInBeast[client]=false;
		War3_SetBuff(client,fDamageModifier,thisRaceID,0.0);
		War3_SetBuff(client,iAdditionalMaxHealth,thisRaceID,0);
		SetEntPropFloat(client, Prop_Send, "m_flModelScale", 0.85);
		PrintHintText(client,"Beast Mode has ended");
	}
}

public OnW3TakeDmgBulletPre(victim,attacker,Float:damage)
{
	if(ValidPlayer(victim, true) && ValidPlayer(attacker) && GetClientTeam(attacker)!=GetClientTeam(victim))
	{
		if(War3_GetRace(victim)==thisRaceID && bInBeast[victim])
		{
			War3_DamageModPercent(BeastDamageReduce);
		}
	}
}