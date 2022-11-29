#pragma semicolon 1
 
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdkhooks>

public Plugin:myinfo = 
{
	name = "War3Source Race - Akame",
	author = "ABGar (edited by Kibbles)",
	description = "The Akame race for War3Source.",
	version = "1.0",
    url = "http://sevensinsgaming.com"
}

new thisRaceID;

new SKILL_MURASAME, SKILL_MACH, SKILL_REFLEXES, ULT_ELIMINATE;

// SKILL_MURASAME
new bool:bPoisoned[MAXPLAYERSCUSTOM];
new bPoisonedBy[MAXPLAYERSCUSTOM];
new MurasameDamage[]={0,2,3,4,5};
new Float:MurasameChance[]={0.0,0.2,0.3,0.4,0.5};
new Float:MurasameCD[]={0.0,25.0,20.0,15.0,10.0};
new String:MurasameSound[]="npc/roller/mine/rmine_blades_out2.wav";

// SKILL_MACH
new Float:MachSpeed[]={1.0,1.1,1.2,1.3,1.4};

// SKILL_REFLEXES
new Float:ReflexEvade[]={0.0,0.05,0.1,0.15,0.2};

// ULT_ELIMINATE
new Float:EliminateCooldown[]={0.0,35.0,30.0,25.0,20.0};
new Float:EliminateRange[]={0.0,600.0,700.0,850.0,1000.0};
new GlowSpriteCT, GlowSpriteT;
new String:EliminateSound[]="ambient/office/coinslot1.wav";



public OnWar3PluginReady()
{
	thisRaceID=War3_CreateNewRace("Akame [PRIVATE]","akame");
	SKILL_MURASAME = War3_AddRaceSkill(thisRaceID,"Murasame","A katana coated in deadly poison that can kill within seconds (attack)",false,4);
	SKILL_MACH = War3_AddRaceSkill(thisRaceID,"Mach","Akame travels faster than sound (passive)",false,4);
	SKILL_REFLEXES = War3_AddRaceSkill(thisRaceID,"Reflexes","Being able to dodge and counter-attack, with deadly results (passive)",false,4);
	ULT_ELIMINATE=War3_AddRaceSkill(thisRaceID,"Eliminate","Teleport and leave original image behind (+ultimate)",true,4);
	War3_CreateRaceEnd(thisRaceID);
	War3_AddSkillBuff(thisRaceID,SKILL_MACH,fMaxSpeed,MachSpeed);
	War3_AddSkillBuff(thisRaceID,SKILL_REFLEXES,fDodgeChance,ReflexEvade);
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
	bPoisoned[client]=false;//Just in case the timers bug out!
	if(War3_GetRace(client)==thisRaceID)
	{
		InitPassiveSkills(client);
	}
}
public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i=0; i<MaxClients; i++)
	{
		if (ValidPlayer(i, true))
		{
			bPoisoned[i]=false;//Cancel poison on round start
			if (War3_GetRace(i)==thisRaceID)
			{
				InitPassiveSkills(i);//Not totally necessary for this race, but still a nice practice to have.
			}
		}
	}
}

public InitPassiveSkills(client)
{
	War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife");
}

public OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart);
}

public OnMapStart()
{
	War3_PrecacheSound(MurasameSound);
	War3_PrecacheSound(EliminateSound);
	GlowSpriteT=PrecacheModel("models/player/t_leet.mdl");
	GlowSpriteCT=PrecacheModel("models/player/ct_urban.mdl");
}

/* *************************************** (SKILL_MURASAME) *************************************** */
public OnW3TakeDmgBulletPre(victim,attacker,Float:damage)
{
	if(ValidPlayer(victim, true) && ValidPlayer(attacker) && GetClientTeam(attacker)!=GetClientTeam(victim))
	{
		if(War3_GetRace(attacker)==thisRaceID)
		{
			new MurasameLevel = War3_GetSkillLevel(attacker,thisRaceID,SKILL_MURASAME);
			if(MurasameLevel>0)
			{
				if(SkillAvailable(attacker,thisRaceID,SKILL_MURASAME,true,true,true))
				{
					if(W3Chance(MurasameChance[MurasameLevel]))
					{
						War3_CooldownMGR(attacker,MurasameCD[MurasameLevel],thisRaceID,SKILL_MURASAME,true,true);
						bPoisoned[victim]=true;
						bPoisonedBy[victim]=attacker;
						CreateTimer(1.0,MurasameDamageTime,victim);
						CreateTimer(9.1,StopMurasame,victim);
						W3EmitSoundToAll(MurasameSound,attacker);
						PrintToChat(victim,"\x04You have been poisoned by \x03%N \x04for 8 seconds",attacker);
					}
				}
			}
		}
	}
}

public Action:MurasameDamageTime(Handle:timer,any:client)
{
	if(ValidPlayer(client,true) && bPoisoned[client])
	{
		new MurasameLevel = War3_GetSkillLevel(bPoisonedBy[client],thisRaceID,SKILL_MURASAME);
		War3_DealDamage(client,MurasameDamage[MurasameLevel],bPoisonedBy[client],DMG_CRUSH,"murasame",_,W3DMGTYPE_MAGIC);
		CreateTimer(1.0,MurasameDamageTime,client);
	}
}

public Action:StopMurasame(Handle:timer,any:client)
{
	if(ValidPlayer(client) && bPoisoned[client])
	{
		bPoisoned[client]=false;
		PrintToChat(client,"\x04The poison has worn off...");
	}
}

/* *************************************** (ULT_ELIMINATE) *************************************** */
public OnUltimateCommand(client,race,bool:pressed)
{
	if(ValidPlayer(client,true) && race==thisRaceID && pressed)
	{
		new EliminateLevel=War3_GetSkillLevel(client,thisRaceID,ULT_ELIMINATE);
		if(EliminateLevel>0)
		{
			if(SkillAvailable(client,thisRaceID,ULT_ELIMINATE,true,true,true))
			{
				new target = War3_GetTargetInViewCone(client,EliminateRange[EliminateLevel],false,23.0);
				if(target>0 && !IsUltImmune(target))
				{
					War3_CooldownMGR(client,EliminateCooldown[EliminateLevel],thisRaceID,ULT_ELIMINATE,true,true);
					
					new Float:ClientPos[3], Float:TargetPos[3];
					GetClientAbsOrigin(client,ClientPos);
					GetClientAbsOrigin(target,TargetPos);
					
					W3EmitSoundToAll(EliminateSound,client);
					TeleportEntity(client,TargetPos,NULL_VECTOR,NULL_VECTOR);
					if(GetClientTeam(client)==TEAM_T)
					{
						TE_SetupGlowSprite(ClientPos,GlowSpriteT,3.0,1.0,250);
						TE_SendToAll();
					}
					else
					{
						TE_SetupGlowSprite(ClientPos,GlowSpriteCT,3.0,1.0,250);
						TE_SendToAll();
					}
					
				}
				else
					W3MsgNoTargetFound(client);
			}
		}
		else
			W3MsgUltNotLeveled(client);
	}
}
