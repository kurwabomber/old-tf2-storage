#pragma semicolon 1
 
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdkhooks>

public Plugin:myinfo = 
{
	name = "War3Source Race - Tyrr Warrior",
	author = "ABGar",
	description = "The Tyrr Warrior race for War3Source.",
	version = "1.0",
	// ABGar / Campalot's Private Race - http://www.sevensinsgaming.com/forum/index.php?/topic/5450-tyrr-warrior
}

new thisRaceID;

new SKILL_GIANT, SKILL_CHARGE, SKILL_DAGGER, ULT_SYMPHONY;

// SKILL_GIANT
new Float:GiantCD=5.0;
new Float:GiantChance=0.5;
new Float:GiantStunDuration[]={0.0,0.5,1.0,1.5,2.0};
new String:GiantSound[]="war3source/shadowstrikebirth.wav";
new bool:bIsStunned[MAXPLAYERSCUSTOM];

// SKILL_CHARGE
new Float:ChargeCD=5.0;
new Float:ChargeChance=0.5;
new Float:PushForce[]={0.0,700.0,900.0,1200.0,1500.0};

// SKILL_DAGGER
new Float:DaggerDamage[]={1.0,1.2,1.4,1.6,1.8};
new String:DaggerSound[]={"npc/roller/mine/rmine_blades_out2.wav"};

// ULT_SYMPHONY
new Seconds;
new iPreHealth[MAXPLAYERSCUSTOM];
new bool:bInSymphony[MAXPLAYERSCUSTOM];
new Float:SymphonyCD[]={0.0,60.0,50.0,40.0,30.0};
new String:SymphonyOnSound[]="npc/scanner/scanner_nearmiss1.wav";
new String:SymphonyOffSound[]="npc/scanner/scanner_nearmiss2.wav";


public OnWar3PluginReady()
{
	thisRaceID=War3_CreateNewRace("Tyrr Warrior [PRIVATE]","tyrrwarrior");
	SKILL_GIANT = War3_AddRaceSkill(thisRaceID,"Giant Punch","Right Click stuns your enemy",false,4);
	SKILL_CHARGE = War3_AddRaceSkill(thisRaceID,"Momentum Charge","Left Click pushes your enemy away",false,4);
	SKILL_DAGGER = War3_AddRaceSkill(thisRaceID,"Dagger Mastery","While in Chaos Symphony, Tyrr's damage is increased",false,4);
	ULT_SYMPHONY=War3_AddRaceSkill(thisRaceID,"Chaos Symphony","When Tyrr activates this, he becomes 100% invisible, 1HP, 1.5 speed and lower gravity (+ultimate)\nHowever if Tyrr doesn't get a kill in 20 seconds, he dies.",true,4);
	War3_CreateRaceEnd(thisRaceID);
	W3SkillCooldownOnSpawn(thisRaceID,ULT_SYMPHONY,10.0,_);
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

public OnSkillLevelChanged(client, race, skill, newskilllevel)
{
	
}

public InitPassiveSkills(client)
{
	War3_WeaponRestrictTo(client, thisRaceID, "weapon_knife");
	War3_SetBuff(client,bDoNotInvisWeapon,thisRaceID,true);
	W3ResetBuffRace(client,fMaxSpeed,thisRaceID);
	W3ResetBuffRace(client,fInvisibilitySkill,thisRaceID);
	bInSymphony[client]=false;
}

public OnMapStart()
{
	War3_PrecacheSound(GiantSound);
	War3_PrecacheSound(DaggerSound);	
	War3_PrecacheSound(SymphonyOnSound);
	War3_PrecacheSound(SymphonyOffSound);
}

/* ****************************** (SKILL_GIANT / SKILL_CHARGE / SKILL_DAGGER) *************************** */
public OnW3TakeDmgBulletPre(victim,attacker,Float:damage)
{
	if(ValidPlayer(victim) && ValidPlayer(attacker) && GetClientTeam(attacker)!=GetClientTeam(victim))
	{
		if(War3_GetRace(victim)==thisRaceID)
		{
			new GiantLevel = War3_GetSkillLevel(attacker,thisRaceID,SKILL_GIANT);
			new ChargeLevel = War3_GetSkillLevel(attacker,thisRaceID,SKILL_CHARGE);
			new DaggerLevel = War3_GetSkillLevel(attacker,thisRaceID,SKILL_DAGGER);
			
			new String:weapon[32];
			GetClientWeapon(attacker,weapon,32);
			if(StrEqual(weapon,"weapon_knife"))
			{
				new buttons = GetClientButtons(attacker);
				if (buttons & IN_ATTACK) // Momentum Charge
				{
					if(ChargeLevel>0)
					{
						if(W3Chance(ChargeChance))
						{
							if(SkillAvailable(attacker,thisRaceID,SKILL_CHARGE,true,true,true))
							{
								War3_CooldownMGR(attacker,ChargeCD,thisRaceID,SKILL_CHARGE,true,true);
								new Float:startpos[3];		GetClientAbsOrigin(attacker,startpos);
								new Float:endpos[3];		GetClientAbsOrigin(victim,endpos);
								new Float:vector[3];		MakeVectorFromPoints(startpos, endpos, vector);
							   
								NormalizeVector(vector, vector);
								ScaleVector(vector, PushForce[ChargeLevel]);
								TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, vector);							
							}
						}
						else if(bInSymphony[attacker])
						{
							War3_DamageModPercent(DaggerDamage[DaggerLevel]);
							EmitSoundToAll(DaggerSound,victim);
							W3FlashScreen(victim,RGBA_COLOR_RED);
						}
					}
				}
				else if (buttons & IN_ATTACK2) // Giant Punch
				{
					if(GiantLevel>0)
					{
						if(W3Chance(GiantChance))
						{
							if(SkillAvailable(attacker,thisRaceID,SKILL_GIANT,true,true,true))
							{
								War3_CooldownMGR(attacker,GiantCD,thisRaceID,SKILL_GIANT,true,true);
								War3_SetBuff(victim,bBashed,thisRaceID,true);
								bIsStunned[victim]=true;
								CreateTimer(GiantStunDuration[GiantLevel],StopStun,victim);
								EmitSoundToAll(GiantSound,attacker);
							}
						}
						else if(bInSymphony[attacker])
						{
							War3_DamageModPercent(DaggerDamage[DaggerLevel]);
							EmitSoundToAll(DaggerSound,victim);
							W3FlashScreen(victim,RGBA_COLOR_RED);
						}
					}
				}
			}
		}
	}
}

public Action:StopStun(Handle:timer,any:client)
{
	if(ValidPlayer(client) && bIsStunned[client])
	{
		War3_SetBuff(client,bBashed,thisRaceID,false);
		bIsStunned[client]=false;
	}
}

/* *************************************** (ULT_SYMPHONY) *************************************** */
public OnUltimateCommand(client,race,bool:pressed)
{
	if(ValidPlayer(client,true) && race==thisRaceID && pressed)
	{
		new SymphonyLevel=War3_GetSkillLevel(client,thisRaceID,ULT_SYMPHONY);
		if(SymphonyLevel>0)
		{
			if(!bInSymphony[client])
			{
				if(SkillAvailable(client,thisRaceID,ULT_SYMPHONY,true,true,true))
				{
					War3_SetBuff(client,fMaxSpeed,thisRaceID,1.4);
					War3_SetBuff(client,fInvisibilitySkill,thisRaceID,0.00);
					iPreHealth[client]=GetClientHealth(client);
					SetEntityHealth(client,1);
					Seconds=19;
					bInSymphony[client]=true;
					EmitSoundToAll(SymphonyOnSound,client);
					
					CreateTimer(1.0,SymphonyTimer,client);
					CPrintToChat(client, "{blue} Chaos Symphony activated");
				}
			}
			else
				CPrintToChat(client, "{blue} You've already activated Chaos Symphony");
		}
		else
			W3MsgUltNotLeveled(client);
	}
}

public Action:SymphonyTimer(Handle:timer,any:client) 
{ 
	if(ValidPlayer(client,true) && bInSymphony[client])
    {
		if(Seconds>0)
		{
			W3Hint(client,HINT_LOWEST,1.0,"You have %i seconds left to get a kill...",Seconds);
			Seconds--; 
			CreateTimer(1.0,SymphonyTimer,client);
		}
		else
		{	
			CPrintToChat(client, "{red} Chaos Symphony failed");
			bInSymphony[client]=false;
			ForcePlayerSuicide(client);
		}
	}
}

public Action:StopSymphony(Handle:timer,any:client) 
{ 
	if(ValidPlayer(client,true))
	{
		W3ResetBuffRace(client,fMaxSpeed,thisRaceID);
		W3ResetBuffRace(client,fInvisibilitySkill,thisRaceID);
		SetEntityHealth(client,iPreHealth[client]);
		EmitSoundToAll(SymphonyOnSound,client);
	}
}

public OnWar3EventDeath(victim,attacker)
{
	if(War3_GetRace(attacker)==thisRaceID)
	{
		if(bInSymphony[attacker])
		{
			new SymphonyLevel=War3_GetSkillLevel(attacker,thisRaceID,ULT_SYMPHONY);
			bInSymphony[attacker]=false;
			CPrintToChat(attacker, "{green} Chaos Symphony succeeded");
			if(Seconds>5)
			{
				CreateTimer(5.0,StopSymphony,attacker);
				War3_CooldownMGR(attacker,SymphonyCD[SymphonyLevel]+5.0,thisRaceID,ULT_SYMPHONY,true,true);
			}
			else
			{
				new Float:SecRemaining = float(Seconds);
				CreateTimer(SecRemaining,StopSymphony,attacker);
				War3_CooldownMGR(attacker,SymphonyCD[SymphonyLevel]+SecRemaining,thisRaceID,ULT_SYMPHONY,true,true);
			}
		}
	}
}