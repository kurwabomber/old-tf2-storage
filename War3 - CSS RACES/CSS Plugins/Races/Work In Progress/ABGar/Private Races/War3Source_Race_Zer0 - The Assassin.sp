#pragma semicolon 1
 
#include "W3SIncs/War3Source_Interface"
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <smlib>

public Plugin:myinfo = 
{
	name = "War3Source Race - Zer0, The Assassin",
	author = "ABGar",
	description = "The Zer0, The Assassin race for War3Source.",
	version = "1.0",
}

new thisRaceID;

new SKILL_UNFORSEEN, SKILL_VELOCITY, SKILL_COUNTER, ULT_DECEPTION;

// SKILL_UNFORSEEN
new Float:UnforseenHealthLimit[]={0.0,0.5,0.6,0.7,0.8};
new Float:UnforseenDamage[]={1.0,1.15,1.2,1.25,1.3};
new String:DamageSound[]={"npc/roller/mine/rmine_blades_out2.wav"};

// SKILL_VELOCITY
new Float:VelocityEvade[]={0.0,0.03,0.05,0.1,0.15};

// SKILL_COUNTER
new Float:CounterCD=10.0;
new Float:CounterInvis[]={1.0,0.5,0.4,0.3,0.2};
new Float:CounterSpeed[]={1.0,1.05,1.1,1.2,1.3};
new Float:CounterDuration[]={0.0,1.0,1.5,2.5,3.0};
new bool:bInCounter[MAXPLAYERSCUSTOM]={false, ...};
new String:InvisOn[]="npc/scanner/scanner_nearmiss1.wav";
new String:InvisOff[]="npc/scanner/scanner_nearmiss2.wav";

// ULT_DECEPTION
new Float:DeceptionDuration=6.0;
new Float:DeceptionCD=20.0;
new Float:DeceptionInvis[]={1.0,0.5,0.4,0.3,0.2};
new Float:DeceptionSpeed[]={1.0,1.2,1.3,1.4,1.5};
new bool:bInDeception[MAXPLAYERSCUSTOM]={false, ...};
new Handle:DeceptionTimer[MAXPLAYERSCUSTOM]={INVALID_HANDLE, ...};
new String:DeceptionSound[]="war3source/zer0.mp3";


public OnWar3PluginReady()
{
	thisRaceID=War3_CreateNewRace("Zer0, The Assassin [PRIVATE]","zer0");
	SKILL_UNFORSEEN = War3_AddRaceSkill(thisRaceID,"Unf0reseen","The stalker in the shadows (passive)\n Do massive damage against enemies with low health",false,4);
	SKILL_VELOCITY = War3_AddRaceSkill(thisRaceID,"Vel0city","A whisper among death (passive) \n Evasion",false,4);
	SKILL_COUNTER = War3_AddRaceSkill(thisRaceID,"C0unter Strike","Take your revenge (passive on hit) \n After being hit, become up to 80% invisible and up to 1.3 speed increase",false,4);
	ULT_DECEPTION=War3_AddRaceSkill(thisRaceID,"Decepti0n","Silence among the dead (+ultimate) \n Enter cloaked mode, gaining invisibility, speed and damage for 6 seconds, or until you get a kill",true,4);
	War3_CreateRaceEnd(thisRaceID);
	W3SkillCooldownOnSpawn(thisRaceID,ULT_DECEPTION,10.0,_);
	War3_AddSkillBuff(thisRaceID,SKILL_VELOCITY,fDodgeChance,VelocityEvade);
}

public OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart);
}

public OnMapStart()
{
	War3_PrecacheSound(DamageSound);
	War3_PrecacheSound(InvisOn);
	War3_PrecacheSound(InvisOff);
	War3_PrecacheSound(DeceptionSound);
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
    for (new i=1; i<MaxClients; i++)
    {
        if (ValidPlayer(i,true) && War3_GetRace(i)==thisRaceID)
        {
            InitPassiveSkills(i);
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

public OnSkillLevelChanged(client, race, skill, newskilllevel)
{
	
}

public InitPassiveSkills(client)
{
	War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife");
	bInCounter[client]=false;
	bInDeception[client]=false;
	if (DeceptionTimer[client] != INVALID_HANDLE)
	{
		KillTimer(DeceptionTimer[client]);
		DeceptionTimer[client] = INVALID_HANDLE;
	}
}

/* *************************************** (SKILL_UNFORSEEN) *************************************** */
public OnW3TakeDmgBulletPre(victim,attacker,Float:damage)
{
	if(ValidPlayer(victim) && ValidPlayer(attacker) && GetClientTeam(attacker)!=GetClientTeam(victim))
	{
		if(War3_GetRace(attacker)==thisRaceID)
		{
			if(bInDeception[attacker])
			{
				War3_DamageModPercent(2.0);
			}
			else
			{
				new UnforseenLevel = War3_GetSkillLevel(attacker,thisRaceID,SKILL_UNFORSEEN);
				if(UnforseenLevel>0)
				{
					if(GetClientHealth(victim)<War3_GetMaxHP(victim)*UnforseenHealthLimit[UnforseenLevel])
					{
						War3_DamageModPercent(UnforseenDamage[UnforseenLevel]);
						W3EmitSoundToAll(DamageSound,attacker);
						W3FlashScreen(attacker,RGBA_COLOR_RED);
					}
				}
			}
		}
/* *************************************** (SKILL_COUNTER) *************************************** */
		if(War3_GetRace(victim)==thisRaceID)
		{
			new CounterLevel = War3_GetSkillLevel(victim,thisRaceID,SKILL_COUNTER);
			if(CounterLevel>0)
			{
				if(War3_SkillNotInCooldown(victim,thisRaceID,SKILL_COUNTER,false) && !bInDeception[victim])
				{
					War3_CooldownMGR(victim,CounterCD,thisRaceID,SKILL_COUNTER,true,false);
					War3_SetBuff(victim,fInvisibilitySkill,thisRaceID,CounterInvis[CounterLevel]);
					War3_SetBuff(victim,fMaxSpeed,thisRaceID,CounterSpeed[CounterLevel]);
					CreateTimer(CounterDuration[CounterLevel],StopBuffs,victim);
					bInCounter[victim]=true;
					EmitSoundToAll(InvisOn,victim);
				}
			}
		}
	}
}

public Action:StopBuffs(Handle:timer,any:client)
{
	if(ValidPlayer(client) && War3_GetRace(client)==thisRaceID)
	{
		W3ResetBuffRace(client,fInvisibilitySkill,thisRaceID);
		W3ResetBuffRace(client,fMaxSpeed,thisRaceID);
		bInCounter[client]=false;
		bInDeception[client]=false;
		EmitSoundToAll(InvisOff,client);
	}
}
/* *************************************** (ULT_DECEPTION) *************************************** */
public OnUltimateCommand(client,race,bool:pressed)
{
	if(ValidPlayer(client,true) && race==thisRaceID && pressed)
	{
		new DeceptionLevel=War3_GetSkillLevel(client,thisRaceID,ULT_DECEPTION);
		if(DeceptionLevel>0)
		{
			if(SkillAvailable(client,thisRaceID,ULT_DECEPTION,true,true,true))
			{
				if(!bInCounter[client])
				{
					War3_CooldownMGR(client,DeceptionCD,thisRaceID,ULT_DECEPTION,true,false);
					War3_SetBuff(client,fInvisibilitySkill,thisRaceID,DeceptionInvis[DeceptionLevel]);
					War3_SetBuff(client,fMaxSpeed,thisRaceID,DeceptionSpeed[DeceptionLevel]);
					DeceptionTimer[client] = CreateTimer(DeceptionDuration,StopBuffs,client);
					bInDeception[client]=true;
					EmitSoundToAll(DeceptionSound,client);
				}
				else
					PrintHintText(client,"You can't access your ultimate while in C0unter Strike mode");
			}
		}
		else
			W3MsgUltNotLeveled(client);
	}
}

public OnWar3EventDeath(victim,attacker)
{
	if(GetClientTeam(attacker)!=GetClientTeam(victim))
	{
		if(War3_GetRace(attacker)==thisRaceID && bInDeception[attacker])
		{
			TriggerTimer(DeceptionTimer[attacker]); 
		}
	}
}