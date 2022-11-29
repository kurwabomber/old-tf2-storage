/**
* File: War3Source_Pistoleer.sp
* Description: The Pistoleer race for War3Source.
* Author(s): Invalid 
*/

#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

new thisRaceID;

new SKILL_GUNS,SKILL_SPEED,SKILL_CRITICAL,SKILL_BOUNTY,SKILL_CHWEAPON;
new Handle:ultCooldownCvar;

// Skill Data Arrays
new Float:RushSpeed[5]={1.00,1.05,1.10,1.20,1.30};
new Float:CritChance[5]={0.0,0.06,0.12,0.15,0.20};
new BountyCash[5]={0,50,200,800,1600};

public Plugin:myinfo = 
{
	name = "War3Source Race - Pistoleer",
	author = "Invalid",
	description = "The Pistoleer race for War3Source.",
	version = "1.0.0.1",
	url = "none"
};

public OnPluginStart()
{
	ultCooldownCvar=CreateConVar("war3_pistoleer_ult_cooldown","5.0","Cooldown for Exclusive Suppliers");
}

public OnWar3PluginReady()
{
	
		thisRaceID=War3_CreateNewRace("Pistoleer [SSG-DONATOR]","pistoleer");
		SKILL_GUNS=War3_AddRaceSkill(thisRaceID,"Gun Collector (passive)","Unlock better pistols",false,5);
		SKILL_SPEED=War3_AddRaceSkill(thisRaceID,"Rush of Battle (passive)","You move faster",false,4);
		SKILL_CRITICAL=War3_AddRaceSkill(thisRaceID,"Lucky Shot (attacker)","Chance to deal extra damage",false,4);
		SKILL_BOUNTY=War3_AddRaceSkill(thisRaceID,"Bounty Hunter (attacker)","Collect money from kills",false,4);
		SKILL_CHWEAPON=War3_AddRaceSkill(thisRaceID,"Exclusive Suppliers","Change weapons",true,1); 
		War3_CreateRaceEnd(thisRaceID);
	
}

public OnWar3EventSpawn(client)
{
	new race=War3_GetRace(client);
	if(race==thisRaceID)
	{
		InitPassiveSkills(client);
		War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife",1);
		DoPistolMenu(client);
	}
}

// Opens pistol menu
public DoPistolMenu(client)
{
	new Handle:pistolMenu=CreateMenu(War3Source_PistolMenu_Selected);
	SetMenuExitButton(pistolMenu,false);
	SetMenuPagination(pistolMenu,MENU_NO_PAGINATION);
	SetMenuTitle(pistolMenu,"== Pistol Menu ==");
	
	new gunlevel = War3_GetSkillLevel(client,thisRaceID,SKILL_GUNS);
	
	AddMenuItem(pistolMenu,"weapon_glock","Glock");
	AddMenuItem(pistolMenu,"weapon_usp","Usp",(gunlevel>0)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	AddMenuItem(pistolMenu,"weapon_p228","P228",(gunlevel>1)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	AddMenuItem(pistolMenu,"weapon_fiveseven","Fiveseven",(gunlevel>2)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	AddMenuItem(pistolMenu,"weapon_deagle","Deagle",(gunlevel>3)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	AddMenuItem(pistolMenu,"weapon_elite","Duel Elites",(gunlevel>4)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	DisplayMenu(pistolMenu,client,MENU_TIME_FOREVER);
}

// Pistol menu functionality
public War3Source_PistolMenu_Selected(Handle:menu,MenuAction:action,client,selection)
{
	if(action==MenuAction_Select)
	{
		if(ValidPlayer(client) && War3_GetRace(client)==thisRaceID)
		{
			decl String:newRestrict[64];
			decl String:weaponName[32];
			decl String:SelectionDispText[256];
			new SelectionStyle;
			
			GetMenuItem(menu,selection,weaponName,sizeof(weaponName),SelectionStyle,SelectionDispText,sizeof(SelectionDispText));
			Format(newRestrict,64,"weapon_knife,%s",weaponName);
			
			War3_WeaponRestrictTo(client,thisRaceID,newRestrict,2);
			GivePlayerItem(client,weaponName);
		}
	}
	if(action==MenuAction_Cancel)
	{
		if(ValidPlayer(client) && War3_GetRace(client)==thisRaceID)
		{
			War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife,weapon_glock",2);
			GivePlayerItem(client,"weapon_glock");
		}
	}
	if(action==MenuAction_End)
	{
		CloseHandle(menu);
	}
}

// Do bounty collection on player death
public OnWar3EventDeath(victim,attacker)
{
	if( War3_GetRace( attacker ) == thisRaceID )
	{
		if ( ValidPlayer( victim, true ) && ValidPlayer( attacker, true ) && GetClientTeam( victim ) != GetClientTeam( attacker ) )
		{
			new level = War3_GetSkillLevel(attacker,thisRaceID,SKILL_BOUNTY);
			if (level>0)
			{
				new money=GetCSMoney(attacker);
				money += BountyCash[level];
				SetCSMoney(attacker,money);
				W3FlashScreen(attacker,RGBA_COLOR_GREEN);
				War3_ChatMessage(attacker,"Collected a $%d bounty",BountyCash[level]);
			}
		}
	}
}

// Do critical hit calculation for lucky shot
public OnW3TakeDmgBullet(victim,attacker,Float:damage)
{
	if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim)
	{
		// Not going to allow critical hit on team attacks for now
		new vteam=GetClientTeam(victim);
		new ateam=GetClientTeam(attacker);
		if(vteam!=ateam)
		{
			new race_attacker=War3_GetRace(attacker);
			new skill_attacker=War3_GetSkillLevel(attacker,race_attacker,SKILL_CRITICAL);
			if(race_attacker==thisRaceID && skill_attacker>0 && !Hexed(attacker,false))
			{
				// Will not factor in skill immunity
				if (GetRandomFloat(0.0,1.0)<=CritChance[skill_attacker])
				{
					if (War3_DealDamage(victim,30,attacker,DMG_BULLET,"luckyshot",W3DMGORIGIN_SKILL,W3DMGTYPE_PHYSICAL))
					{
						W3PrintSkillDmgHintConsole(victim,attacker,30, SKILL_CRITICAL );
						W3FlashScreen(victim,RGBA_COLOR_RED);
					}
				}
			}
		}
	}
}

public OnSkillLevelChanged(client,race,skill,newskilllevel)
{
	InitPassiveSkills(client);
}

public InitPassiveSkills(client)
{
	if(War3_GetRace(client)==thisRaceID)
	{
		new skilllevel_rush=War3_GetSkillLevel(client,thisRaceID,SKILL_SPEED);
		new Float:speed=RushSpeed[skilllevel_rush];
		War3_SetBuff(client,fMaxSpeed,thisRaceID,speed);
	}
}

public OnRaceChanged ( client,oldrace,newrace )
{
	if(newrace!=thisRaceID)
	{
		War3_WeaponRestrictTo(client,thisRaceID,"");
		War3_SetBuff(client,fMaxSpeed,thisRaceID,1.0);
	}
	else
	{
		if (IsPlayerAlive(client))
		{
			InitPassiveSkills(client);
			War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife",1);
			DoPistolMenu(client);
		}
	}
}

public OnUltimateCommand(client,race,bool:pressed)
{
	if(race==thisRaceID && pressed && IsPlayerAlive(client))
	{
		new skill=War3_GetSkillLevel(client,race,SKILL_CHWEAPON);
		if(skill&&War3_SkillNotInCooldown(client,thisRaceID,SKILL_CHWEAPON,true))
		{
			DoPistolMenu(client);
			new Float:cooldown=GetConVarFloat(ultCooldownCvar);
			War3_CooldownMGR(client,cooldown,thisRaceID,SKILL_CHWEAPON);
		}
	}
}