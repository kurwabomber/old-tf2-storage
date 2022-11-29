#pragma semicolon 1
 
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include "W3SIncs/RemyFunctions"
#include <sdktools>
#include <sdkhooks>

public Plugin:myinfo = 
{
	name = "War3Source Race - TF2 Spy",
	author = "ABGar",
	description = "The TF2 Spy race for War3Source.",
	version = "1.0",
}

new thisRaceID;

new SKILL_DISGUISE, SKILL_BACKSTAB, SKILL_LETRANGER, ULT_INVIS;

// SKILL_DISGUISE
new Float:DisguiseChance[]={0.0,0.25,0.5,0.75,1.0};

// SKILL_BACKSTAB
new Float:BackstabDamage[]={1.0,1.5,1.7,1.9,2.1};

// SKILL_LETRANGER
new Float:LetrangerDamage[]={1.0,0.7,0.5,0.3,0.2};
new Float:LetrangerCDChange[]={0.0,1.0,2.0,3.0,4.0};


// ULT_INVIS
new Float:InvisDuration[]={0.0,8.0,10.0,12.0,14.0};
new Float:InvisCD=20.0;
new bool:InInvis[MAXPLAYERSCUSTOM];
new Handle:InvisEndTimer[MAXPLAYERSCUSTOM];
new String:InvisOn[]="npc/scanner/scanner_nearmiss1.wav";
new String:InvisOff[]="npc/scanner/scanner_nearmiss2.wav";


public OnWar3PluginReady()
{
	thisRaceID=War3_CreateNewRace("TF2 Spy","tf2spy");
	SKILL_DISGUISE = War3_AddRaceSkill(thisRaceID,"Disguise kit","Chance on spawn to look like your opponents",false,4);
	SKILL_BACKSTAB = War3_AddRaceSkill(thisRaceID,"Backstab","Stabs deal extra damage",false,4);
	SKILL_LETRANGER = War3_AddRaceSkill(thisRaceID,"L’etranger","Less DMG but shooting an opponent lowers the cool-down on your ultimate",false,4);
	ULT_INVIS=War3_AddRaceSkill(thisRaceID,"Invis watch","Becomes invisible for a short time, but you can't shoot while invisible (+ultimate)",true,4);
	War3_CreateRaceEnd(thisRaceID);
	W3SkillCooldownOnSpawn(thisRaceID,ULT_INVIS,10.0,_);
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
	War3_WeaponRestrictTo(client,thisRaceID,"weapon_usp,weapon_knife");
	GivePlayerItem(client,"weapon_usp");
	CheckModel(client);
}

public OnMapStart()
{
	War3_PrecacheSound(InvisOn);
	War3_PrecacheSound(InvisOff);
}

/* *************************************** (SKILL_DISGUISE) *************************************** */
public CheckModel(client)
{
	new DisguiseLevel = War3_GetSkillLevel(client,thisRaceID,SKILL_DISGUISE);
	if(DisguiseLevel>0)
	{
		if(W3Chance(DisguiseChance[DisguiseLevel]))
		{
			War3_ChangeModel(client,true);
			PrintToChat(client,"\x04[SPY] \x03You look like the enemy...");
		}
	}
}

/* *************************************** (SKILL_BACKSTAB) *************************************** */
public OnW3TakeDmgBulletPre(victim,attacker,Float:damage)
{
	if(ValidPlayer(victim) && ValidPlayer(attacker) && GetClientTeam(attacker)!=GetClientTeam(victim))
	{
		if(War3_GetRace(attacker)==thisRaceID)
		{
			new LetrangerLevel = War3_GetSkillLevel(attacker,thisRaceID,SKILL_LETRANGER);
			new BackstabLevel = War3_GetSkillLevel(attacker,thisRaceID,SKILL_BACKSTAB);
			if(BackstabLevel>0)
			{
				new String:weapon[32]; 
				GetClientWeapon(attacker,weapon,32);
				if(StrEqual(weapon,"weapon_knife"))
				{
					War3_DamageModPercent(BackstabDamage[BackstabLevel]);	
				}
/* *************************************** (SKILL_LETRANGER) *************************************** */
				else
				{
					War3_DamageModPercent(LetrangerDamage[LetrangerLevel]);
					if(SkillAvailable(attacker,thisRaceID,SKILL_LETRANGER,false,false,false))
					{
						new iCurrentCD = War3_CooldownRemaining(attacker,thisRaceID,ULT_INVIS);
						War3_CooldownReset(attacker,thisRaceID,ULT_INVIS);
						War3_CooldownMGR(attacker,(iCurrentCD-LetrangerCDChange[LetrangerLevel]),thisRaceID,ULT_INVIS,true,true);
						War3_CooldownMGR(attacker,1.0,thisRaceID,SKILL_LETRANGER,true,false);
						PrintHintText(attacker,"Invis Watch Cooldown lowered by %i seconds",LetrangerLevel);
					}
				}
			}
		}
	}
}

/* *************************************** (ULT_INVIS) *************************************** */
public Action:EndInvis(Handle:timer,any:client)
{
	W3ResetBuffRace(client,fInvisibilitySkill,thisRaceID);
	War3_SetBuff(client,bDisarm,thisRaceID,false);
	EmitSoundToAll(InvisOff,client);
	InInvis[client]=false;
}

public OnUltimateCommand(client,race,bool:pressed)
{
	if(ValidPlayer(client,true) && race==thisRaceID && pressed)
	{
		new InvisLevel = War3_GetSkillLevel(client,thisRaceID,ULT_INVIS);
		if(InvisLevel>0)	
		{
			if(InInvis[client])
				TriggerTimer(InvisEndTimer[client]);
				
			else if(SkillAvailable(client,thisRaceID,ULT_INVIS,true,true,true))
			{
				EmitSoundToAll(InvisOn,client);
				War3_SetBuff(client,fInvisibilitySkill,thisRaceID,0.0);
				War3_SetBuff(client,bDisarm,thisRaceID,true);
				InvisEndTimer[client]=CreateTimer(InvisDuration[InvisLevel],EndInvis,client);
				InInvis[client]=true;
				War3_CooldownMGR(client,InvisCD,thisRaceID,ULT_INVIS, _, _);
			}
		}
		else
			W3MsgUltNotLeveled(client);
	}
}