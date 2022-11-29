#pragma semicolon 1
 
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdkhooks>
#include <smlib>

public Plugin:myinfo = 
{
	name = "War3Source Race - Jackal and Shakedown",
	author = "ABGar",
	description = "The Jackal and Shakedown races for War3Source - can be swapped between",
	version = "1.0",
	// ABGar / Campalot's Private Race - http://www.sevensinsgaming.com/forum/index.php?/topic/5446-jackal-shakedown
}

new jackalRaceID, shakeRaceID;

new SKILL_JACKAL1, SKILL_JACKAL2, SKILL_JACKAL3, ULT_SHAKEDOWN;
new SKILL_SHAKE1, SKILL_SHAKE2, SKILL_SHAKE3, ULT_JACKAL;


new Float:WindWalkSpeed[]={1.0,1.05,1.1,1.15,1.2,1.3};
new Float:WindWalkInvis[]={1.0,0.7,0.6,0.5,0.4,0.3};
new Float:FeastVamp[]={0.0,0.1,0.15,0.2,0.25,0.3};
new Float:ShakeRange[]={0.0,200.0,250.0,300.0,400.0,500.0};
new Float:BuryChance[]={0.0,0.1,0.2,0.3,0.4,0.5};
new Float:HeadShotChance=0.4;
new BuryDamage=20;
new HeadShotDamage[]={0,5,8,12,15,20};

new String:CritHit[]="npc/roller/mine/rmine_blades_out2.wav";



public OnWar3PluginReady()
{
	jackalRaceID=War3_CreateNewRace("Jackal [PRIVATE]","jackal");
	SKILL_JACKAL1 = War3_AddRaceSkill(jackalRaceID,"Head shot","Jackal increases his accuracy, giving a chance to deal extra damage and mini-stun (attack)",false,5);
	SKILL_JACKAL2 = War3_AddRaceSkill(jackalRaceID,"Shadow Walk","Jackal moves faster (passive)",false,5);
	SKILL_JACKAL3 = War3_AddRaceSkill(jackalRaceID,"Feast","Jackal regenerates a portion of the attacked enemy's current HP (passive)",false,5);
	ULT_SHAKEDOWN=War3_AddRaceSkill(jackalRaceID,"Shakedown","Jackal becomes Shakedown (+ultimate)",true,1);
	W3SkillCooldownOnSpawn(jackalRaceID,ULT_SHAKEDOWN,10.0,_);
	War3_AddSkillBuff(jackalRaceID,SKILL_JACKAL2,fMaxSpeed,WindWalkSpeed);
	War3_AddSkillBuff(jackalRaceID,SKILL_JACKAL3,fVampirePercent,FeastVamp);
	War3_CreateRaceEnd(jackalRaceID);
	
	shakeRaceID=War3_CreateNewRace("Shakedown [PRIVATE]","shakedown");
	SKILL_SHAKE1 = War3_AddRaceSkill(shakeRaceID,"Wind Walk","Shakedown becomes invisible and is able to run faster after his foe (passive)",false,5);
	SKILL_SHAKE2 = War3_AddRaceSkill(shakeRaceID,"Shakedown ","Every 10 seconds all the enemies around Shakedown have their crosshair shaken (passive)",false,5);
	SKILL_SHAKE3 = War3_AddRaceSkill(shakeRaceID,"Bury","Shakedown's knife has a chance to burrow his enemy half way into the ground.",false,5);
	ULT_JACKAL=War3_AddRaceSkill(shakeRaceID,"Jackal","Shakedown becomes Jackal (+ultimate)",true,1);
	W3SkillCooldownOnSpawn(shakeRaceID,ULT_JACKAL,10.0,_);
	War3_AddSkillBuff(shakeRaceID,SKILL_SHAKE1,fMaxSpeed,WindWalkSpeed);
	War3_AddSkillBuff(shakeRaceID,SKILL_SHAKE1,fInvisibilitySkill,WindWalkInvis);
	War3_CreateRaceEnd(shakeRaceID);
}

public OnPluginStart()
{
	CreateTimer(10.0,ShakeAura,_,TIMER_REPEAT);
}

public OnMapStart()
{
    War3_PrecacheSound(CritHit);
}


public OnRaceChanged(client,oldrace,newrace)
{
	if((newrace == jackalRaceID || newrace == shakeRaceID) && ValidPlayer(client,true))
	{
		InitPassiveSkills(client);
	}
	else
	{
		War3_WeaponRestrictTo(client,jackalRaceID,"");
		W3ResetAllBuffRace(client,jackalRaceID);
		War3_WeaponRestrictTo(client,shakeRaceID,"");
		W3ResetAllBuffRace(client,shakeRaceID);
	}
}

public OnWar3EventSpawn(client)
{
	if(War3_GetRace(client) == jackalRaceID || War3_GetRace(client) == shakeRaceID)
	{
		InitPassiveSkills(client);
	}
}

public InitPassiveSkills(client)
{
	if(War3_GetRace(client)==jackalRaceID)
	{
		War3_WeaponRestrictTo(client,jackalRaceID,"weapon_usp,weapon_knife");
		if (!Client_HasWeapon(client, "weapon_usp"))
		{
			GivePlayerItem(client,"weapon_usp");
		}
	}
	else if (War3_GetRace(client)==shakeRaceID)
	{
		War3_WeaponRestrictTo(client,jackalRaceID,"weapon_knife");
		FakeClientCommand(client,"use weapon_knife");
		DropSecWeapon(client);
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




public OnW3TakeDmgBullet(victim,attacker,Float:damage)
{
	if(ValidPlayer(victim) && ValidPlayer(attacker) && GetClientTeam(attacker)!=GetClientTeam(victim))
	{
		if(War3_GetRace(attacker)==jackalRaceID)
		{
			new HeadShotLevel = War3_GetSkillLevel(attacker,jackalRaceID,SKILL_JACKAL1);
			if(HeadShotLevel>0)
			{
				if(W3Chance(HeadShotChance))
				{
					War3_DealDamage(victim,HeadShotDamage[HeadShotLevel],attacker,DMG_CRUSH,"head shot",_,W3DMGTYPE_MAGIC);
					W3FlashScreen(victim,RGBA_COLOR_RED);
					W3FlashScreen(attacker,RGBA_COLOR_RED);
					War3_SetBuff(victim,bBashed,jackalRaceID,true);
					CreateTimer(0.5,StopSun,victim);
					EmitSoundToAll(CritHit,attacker);
					EmitSoundToAll(CritHit,victim);
				}
			}
		}
		if(War3_GetRace(attacker)==shakeRaceID)
		{
			new BuryLevel = War3_GetSkillLevel(attacker,shakeRaceID,SKILL_SHAKE3);
			if(BuryLevel>0 && SkillAvailable(attacker,shakeRaceID,SKILL_SHAKE3,false,true,true))
			{
				if(W3Chance(BuryChance[BuryLevel]))
				{
					War3_CooldownMGR(attacker,3.0,shakeRaceID,SKILL_SHAKE3,true,false);
					new Float:attacker_pos[3];		GetClientAbsOrigin(attacker,attacker_pos);
					new Float:victim_pos[3];		GetClientAbsOrigin(victim,victim_pos);
					victim_pos[2] -= 40;

					TeleportEntity(victim,victim_pos,NULL_VECTOR,NULL_VECTOR);
					War3_DealDamage(victim,BuryDamage,attacker,DMG_CRUSH,"buy",_,W3DMGTYPE_MAGIC);
					CreateTimer(2.0,Unbury,victim);
				}
			}
		}
	}
}

public Action:Unbury(Handle:timer,any:client)
{
	if(ValidPlayer(client,true))
	{
		new Float:victim_pos[3];	GetClientAbsOrigin(client,victim_pos);
		victim_pos[2] += 40;

		TeleportEntity(client,victim_pos,NULL_VECTOR,NULL_VECTOR);
	}
}

public Action:StopSun(Handle:timer,any:client)
{
	if(ValidPlayer(client))
	{
		War3_SetBuff(client,bBashed,jackalRaceID,false);
	}
}


public Action:ShakeAura(Handle:timer,any:userid)
{
	for(new client=1;client<=MaxClients;client++)
	{
		if(ValidPlayer(client,true) && War3_GetRace(client)==shakeRaceID)
		{
			new ShakeLevel=War3_GetSkillLevel(client,shakeRaceID,SKILL_SHAKE2);
			if(ShakeLevel>0)
			{
				new Float:clientPos[3];		GetClientAbsOrigin(client,clientPos);
				new Float:targetPos[3];
				
				for (new target=1;target<=MaxClients;target++)
				{
					if(ValidPlayer(target,true)&& GetClientTeam(target)!=GetClientTeam(client) && SkillFilter(target))
					{
						GetClientAbsOrigin(target,targetPos);
						if(GetVectorDistance(clientPos,targetPos)<=ShakeRange[ShakeLevel])
						{
							War3_ShakeScreen(target,2.0,80.0,60.0);
						}
					}
				}
			}
		}
	}
}




public OnUltimateCommand(client,race,bool:pressed)
{
	if(race==jackalRaceID && pressed && IsPlayerAlive(client) && !Silenced(client))
	{	
		new UltLevel=War3_GetSkillLevel(client,jackalRaceID,ULT_SHAKEDOWN);
		if(UltLevel>0)
		{
			if(War3_SkillNotInCooldown(client,jackalRaceID,ULT_SHAKEDOWN,true))
			{
				War3_CooldownMGR(client,10.0,jackalRaceID,ULT_SHAKEDOWN,false,true);
				CreateTimer(2.0,ChangeRace,client);
				PrintCenterText(client,"Becoming Shakedown in 2 seconds");
			}
		}
		else
			W3MsgUltNotLeveled(client);
	}
	else if(race==shakeRaceID && pressed && IsPlayerAlive(client) && !Silenced(client))
	{
		new UltLevel=War3_GetSkillLevel(client,shakeRaceID,ULT_JACKAL);
		if(UltLevel>0)
		{
			if(War3_SkillNotInCooldown(client,shakeRaceID,ULT_JACKAL,true))
			{
				War3_CooldownMGR(client,10.0,shakeRaceID,ULT_JACKAL,false,true);
				CreateTimer(2.0,ChangeRace,client);
				PrintCenterText(client,"Becoming Jackal in 2 seconds");
			}
		}
		else
			W3MsgUltNotLeveled(client);
	}
}


public Action:ChangeRace(Handle:t,any:client)
{
	if(ValidPlayer(client,true) && (War3_GetRace(client)==jackalRaceID || War3_GetRace(client)==shakeRaceID))
	{
		W3FlashScreen(client,RGBA_COLOR_BLUE);
		War3_ShakeScreen(client);
		PrintHintText(client, "You've changed");
		if(War3_GetRace(client)==jackalRaceID)
		{
			W3SetPlayerProp(client,RaceChosenTime,GetGameTime());
			W3SetPlayerProp(client,RaceSetByAdmin,true);
			War3_SetRace(client,shakeRaceID);
			War3_CooldownMGR(client,10.0,shakeRaceID,ULT_JACKAL,false,true);
		}
		else
		{
			W3SetPlayerProp(client,RaceChosenTime,GetGameTime());
			W3SetPlayerProp(client,RaceSetByAdmin,true);
			War3_SetRace(client,jackalRaceID);
			War3_CooldownMGR(client,10.0,jackalRaceID,ULT_SHAKEDOWN,false,true);
		}
	}
}




























