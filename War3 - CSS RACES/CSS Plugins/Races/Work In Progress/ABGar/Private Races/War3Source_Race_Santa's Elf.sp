#pragma semicolon 1
 
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdkhooks>

public Plugin:myinfo = 
{
	name = "War3Source Race - Santa's Elf",
	author = "ABGar",
	description = "The Santa's Elf race for War3Source.",
	version = "1.0",
	// Insert's Private Race Request - http://www.sevensinsgaming.com/forum/index.php?/topic/5215-santa-claus/
}

new thisRaceID;

new SKILL_SPEED, SKILL_SIZE;

// PASSIVES
new Float:ElfSpeed[]={1.0,1.05,1.1,1.15,1.2};
new Float:ElfDamage[]={1.0,0.9,0.85,0.8,0.75};


public OnWar3PluginReady()
{
	thisRaceID=War3_CreateNewRace("Santa's Elf","santaelf");
	SKILL_SPEED = War3_AddRaceSkill(thisRaceID,"Fast Worker","Bonus speed",false,4);
	SKILL_SIZE = War3_AddRaceSkill(thisRaceID,"I'm an elf","Decreased size and damage",false,4);
	War3_CreateRaceEnd(thisRaceID);
	War3_AddSkillBuff(thisRaceID, SKILL_SPEED, fMaxSpeed, ElfSpeed);
	War3_AddSkillBuff(thisRaceID, SKILL_SIZE, fDamageModifier, ElfDamage);
}


public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace != thisRaceID)
	{
		War3_WeaponRestrictTo(client,thisRaceID,"");
		W3ResetAllBuffRace(client,thisRaceID);
		SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.0);
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
	War3_WeaponRestrictTo(client, thisRaceID, "weapon_deagle");
	DropSecWeapon(client);
	GivePlayerItem(client,"weapon_deagle");
	SmallSize(client);
	
}

public OnSkillLevelChanged(client,race,skill,newskilllevel)
{
    if (ValidPlayer(client,true) && race==thisRaceID)
        SmallSize(client);
}

public SmallSize(client)
{
    new SizeLevel = War3_GetSkillLevel(client,thisRaceID,SKILL_SIZE);
    if(SizeLevel>0)
    {  
        SetEntPropFloat(client, Prop_Send, "m_flModelScale", ElfDamage[SizeLevel]);
    }
}

public DropSecWeapon(client)
{
	new iWeapon = GetPlayerWeaponSlot(client, 1);  
	if(IsValidEntity(iWeapon))
	{
		RemovePlayerItem(client, iWeapon);
		AcceptEntityInput(iWeapon, "kill");
	}
}