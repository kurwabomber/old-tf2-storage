#pragma semicolon 1
 
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdkhooks>

public Plugin:myinfo = 
{
	name = "War3Source Race - Roy Jones",
	author = "ABGar",
	description = "The Roy Jones race for War3Source.",
	version = "1.0",
	// ABGar / Campalot's Private Race - http://www.sevensinsgaming.com/forum/index.php?/topic/5447-roy-jones/
}

new thisRaceID;

new SKILL_SEARING, SKILL_WINDWALK, SKILL_BOOTS, ULT_ANGEL;

// SKILL_SEARING
new Float:SearChance[]={0.0,0.20,0.30,0.40,0.50};
new Float:SearDamage[]={1.0,1.1,1.2,1.3,1.4};
new String:SearSound[]={"npc/roller/mine/rmine_blades_out2.wav"};

// SKILL_WINDWALK
new Float:WindInvis[]={1.00,0.80,0.65,0.50,0.30};
new Float:WindSpeed[]={1.0,1.05,1.1,1.2,1.3};

// SKILL_BOOTS
new Float:BootDamage[]={1.0,0.7,0.55,0.4,0.2};

// ULT_ANGEL
new bool:bIsFlying[MAXPLAYERSCUSTOM];
new Float:AngelCD[]={0.0,15.0,10.0,8.0,5.0};



public OnWar3PluginReady()
{
	thisRaceID=War3_CreateNewRace("Roy Jones [PRIVATE]","royjones");
	SKILL_SEARING = War3_AddRaceSkill(thisRaceID,"Searing Arrows","Adds fire arrows to your knife dealing damage to the enemy (passive)",false,4);
	SKILL_WINDWALK = War3_AddRaceSkill(thisRaceID,"Wind Walk","You're partially invisible and move faster (passive)",false,4);	
	SKILL_BOOTS=War3_AddRaceSkill(thisRaceID,"Wing Boots","You take less fall damage (passive)",false,4);
	ULT_ANGEL = War3_AddRaceSkill(thisRaceID,"Angel of Death","You can fly like an angel (+ability)",true,4);
	War3_CreateRaceEnd(thisRaceID);
	War3_AddSkillBuff(thisRaceID, SKILL_WINDWALK, fMaxSpeed, WindSpeed);
	War3_AddSkillBuff(thisRaceID, SKILL_WINDWALK, fInvisibilitySkill, WindInvis);
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
	War3_WeaponRestrictTo(client, thisRaceID, "weapon_knife");
	bIsFlying[client]=false;
	War3_SetBuff(client,bFlyMode,thisRaceID,false);
	W3ResetBuffRace(client,fMaxSpeed,thisRaceID);
}

public OnClientPutInServer(client) 
{ 
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage); 
} 

public OnMapStart()
{
	War3_PrecacheSound(SearSound);	
}

/* *************************************** (SKILL_SEARING) *************************************** */
public OnW3TakeDmgBulletPre(victim,attacker,Float:damage)
{
	if(ValidPlayer(victim) && ValidPlayer(attacker) && GetClientTeam(attacker)!=GetClientTeam(victim))
	{
		if(War3_GetRace(attacker)==thisRaceID)
		{
			new SearingLevel = War3_GetSkillLevel(attacker,thisRaceID,SKILL_SEARING);
			if(SearingLevel>0 && SkillFilter(victim))
			{
				if(W3Chance(SearChance[SearingLevel]))
				{
					War3_DamageModPercent(SearDamage[SearingLevel]);
					CreateFire(victim,"55","5","3","normal","16",0.0,2.0);
					EmitSoundToAll(SearSound,victim);
					W3FlashScreen(attacker,RGBA_COLOR_RED);
				}
			}
		}
	}
}

/* *************************************** (SKILL_BOOTS) *************************************** */
public Action:OnTakeDamage(client, &attacker, &inflictor, &Float:damage, &damagetype) 
{ 
	if(War3_GetRace(client)==thisRaceID)
	{
		if (damagetype & DMG_FALL) 
		{
			new BootLevel = War3_GetSkillLevel(client,thisRaceID,SKILL_BOOTS);
			if(BootLevel > 0)
			{
				damage *= BootDamage[BootLevel];
				return Plugin_Changed; 
			}
		}
	}
	return Plugin_Continue; 
}

/* *************************************** (ULT_ANGEL) *************************************** */
public OnUltimateCommand(client,race,bool:pressed)
{
	if(ValidPlayer(client,true) && race==thisRaceID && pressed)
	{
		new AngelLevel=War3_GetSkillLevel(client,thisRaceID,ULT_ANGEL);
		if(AngelLevel>0)
		{
			if (bIsFlying[client])
				StopFly(client);
			else
			{
				if(SkillAvailable(client,thisRaceID,ULT_ANGEL,true,true,true))
				{
					StartFly(client);
				}
			}
		}
		else
			W3MsgUltNotLeveled(client);
	}
}

stock StartFly(client)
{
	if (!bIsFlying[client])
	{
		bIsFlying[client]=true;
		War3_SetBuff(client,bFlyMode,thisRaceID,true);
		War3_SetBuff(client,fMaxSpeed,thisRaceID,1.5);
	}
}

stock StopFly(client)
{
	if (bIsFlying[client])
	{
		new AngelLevel = War3_GetSkillLevel(client,thisRaceID,ULT_ANGEL);
		bIsFlying[client]=false;
		War3_SetBuff(client,bFlyMode,thisRaceID,false);
		W3ResetBuffRace(client,fMaxSpeed,thisRaceID);
		War3_CooldownMGR(client,AngelCD[AngelLevel],thisRaceID,ULT_ANGEL);
	}
}
