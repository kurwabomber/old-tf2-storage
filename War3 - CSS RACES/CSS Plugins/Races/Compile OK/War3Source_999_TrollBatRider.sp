/**
 * File: War3Source_TrollBatRider.sp
 * Description: The Troll Bat Rider race for War3Source.
 * Author(s): [Oddity]TeacherCreature
 */

#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <cstrike>

new thisRaceID;
new SKILL_REGEN, SKILL_ARCANITE, SKILL_LIQUIDFIRE, ULT_CONCOCTION;

// Race Model
new String:g_szRaceModelT[PLATFORM_MAX_PATH] = "models/player/techknow/demon/demon.mdl";
new String:g_szRaceModelCT[PLATFORM_MAX_PATH] = "models/player/techknow/demon/demon_ct.mdl";
new Handle:g_hCvarCustomModel = INVALID_HANDLE;
new bool:g_bCustomModel = false;

// Skill 1
new Float:RegenAmountArr[9] = {0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 5.5, 6.0, 6.5};

// Skill 2
new Float:ArcaniteDamagePercent[9] = {1.0, 1.10, 1.15, 1.2, 1.25, 1.3, 1.35, 1.4, 1.45};
new Float:ArcaniteChance[9] = {0.0, 0.48, 0.5, 0.56, 0.6, 0.64, 0.7, 0.74, 0.8};

// Skill 3
new Float:LiquidFireArr[9] = {1.0, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0, 6.0};

// Ultimate
new Handle:g_hCvarUltCooldown = INVALID_HANDLE;
new Handle:g_hCvarFlyingType = INVALID_HANDLE;
new Float:g_fUltCooldown = 0.0;
new bool:g_bFlyingType = true;
new bool:g_bFlying[MAXPLAYERS + 1];





public Plugin:myinfo = {
	name = "War3Source Race - Troll Bat Rider",
	author = "[Oddity]TeacherCreature & Frenzzy",
	description = "The Troll Bat Rider race for War3Source",
	version = "2.0.2",
	url = "www.war3source.com"
};

public OnMapStart()
{
	if (g_bCustomModel && FileExists(g_szRaceModelT) && FileExists(g_szRaceModelCT))
	{
		AddFileToDownloadsTable(g_szRaceModelT);
		AddFileToDownloadsTable(g_szRaceModelCT);
		AddFileToDownloadsTable("materials/models/player/techknow/demon/demon.vmt");
		AddFileToDownloadsTable("materials/models/player/techknow/demon/demon.vtf");
		AddFileToDownloadsTable("materials/models/player/techknow/demon/demon_ct.vmt");
		AddFileToDownloadsTable("materials/models/player/techknow/demon/demon_ct.vtf");
		AddFileToDownloadsTable("materials/models/player/techknow/demon/demon_n.vtf");
		AddFileToDownloadsTable("materials/models/player/techknow/demon/eyes.vmt");
		AddFileToDownloadsTable("materials/models/player/techknow/demon/eyes.vtf");
		AddFileToDownloadsTable("materials/models/player/techknow/demon/w-h.vmt");
		AddFileToDownloadsTable("materials/models/player/techknow/demon/w-h.vtf");
		AddFileToDownloadsTable("materials/models/player/techknow/demon/w-h_ct.vmt");
		AddFileToDownloadsTable("materials/models/player/techknow/demon/w-h_ct.vtf");
		AddFileToDownloadsTable("materials/models/player/techknow/demon/w-h_n.vtf");
		AddFileToDownloadsTable("models/player/techknow/demon/demon.dx80.vtx");
		AddFileToDownloadsTable("models/player/techknow/demon/demon.dx90.vtx");
		AddFileToDownloadsTable("models/player/techknow/demon/demon.phy");
		AddFileToDownloadsTable("models/player/techknow/demon/demon.sw.vtx");
		AddFileToDownloadsTable("models/player/techknow/demon/demon.vvd");
		AddFileToDownloadsTable("models/player/techknow/demon/demon_ct.dx80.vtx");
		AddFileToDownloadsTable("models/player/techknow/demon/demon_ct.dx90.vtx");
		AddFileToDownloadsTable("models/player/techknow/demon/demon_ct.phy");
		AddFileToDownloadsTable("models/player/techknow/demon/demon_ct.sw.vtx");
		AddFileToDownloadsTable("models/player/techknow/demon/demon_ct.vvd");
		PrecacheModel(g_szRaceModelT, true);
		PrecacheModel(g_szRaceModelCT, true);
	}
}

public OnPluginStart()
{
	LoadTranslations("w3s.race.tbr.phrases");
	
	//HookEvent("weapon_fire", Event_WeaponFire);
	
	g_hCvarUltCooldown = CreateConVar("war3_tbr_flying_cooldown", "0.0", "Cooldown for Flying");
	g_hCvarFlyingType = CreateConVar("war3_tbr_flying_type", "0", "Enable/Disable hold key for Flying");
	g_hCvarCustomModel = CreateConVar("war3_tbr_custom_model", "0", "Enable/Disable custom model");
	
	
	HookConVarChange(g_hCvarUltCooldown, OnConVarChange);
	HookConVarChange(g_hCvarFlyingType, OnConVarChange);
	HookConVarChange(g_hCvarCustomModel, OnConVarChange);
	
	

}

public OnWar3PluginReady()
{
	thisRaceID       = War3_CreateNewRaceT("tbr");
	SKILL_REGEN      = War3_AddRaceSkillT(thisRaceID, "Regenerate", false, 8);
	SKILL_ARCANITE   = War3_AddRaceSkillT(thisRaceID, "Arcanite", false, 8);
	SKILL_LIQUIDFIRE = War3_AddRaceSkillT(thisRaceID, "LiquidFire", false, 8);
	ULT_CONCOCTION   = War3_AddRaceSkillT(thisRaceID, "BatRider", true, 1); 
	War3_CreateRaceEnd(thisRaceID);
}

public InitPassiveSkills( client )
{
	if( War3_GetRace( client ) == thisRaceID && ValidPlayer(client, true))
	{	
		new Float:regenbonus = RegenAmountArr[War3_GetSkillLevel( client, thisRaceID, SKILL_REGEN )];
		War3_SetBuff( client, fHPRegen, thisRaceID, regenbonus );
		War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife,weapon_c4,weapon_hegrenade");
		GivePlayerItem(client, "weapon_hegrenade");
	}
}

public OnRaceChanged(client,oldrace,newrace)
{
	if (newrace != thisRaceID)
	{
		g_bFlying[client] = false;
		W3ResetAllBuffRace( client, thisRaceID );
		War3_SetBuff(client, bFlyMode, thisRaceID, false);
		War3_WeaponRestrictTo(client, thisRaceID, "");
		
	}
	else
	{
		InitPassiveSkills(client);
		g_bFlying[client] = false;
		War3_SetBuff(client, bFlyMode, thisRaceID, false);
		
		if (IsPlayerAlive(client))
		{
			if (g_bCustomModel)
			{
				if (IsModelPrecached(g_szRaceModelT) && GetClientTeam(client) == CS_TEAM_T)
					SetEntityModel(client, g_szRaceModelT);
				else if (IsModelPrecached(g_szRaceModelCT) && GetClientTeam(client) == CS_TEAM_CT)
					SetEntityModel(client, g_szRaceModelCT);
			}
			
		}
	}
}

public OnWar3EventSpawn(client)
{
	ExtinguishEntity(client);
	if (War3_GetRace(client) == thisRaceID)
	{
		InitPassiveSkills(client);
		g_bFlying[client] = false;
		War3_SetBuff(client, bFlyMode, thisRaceID, false);
		
		if (g_bCustomModel)
		{
			if (IsModelPrecached(g_szRaceModelT) && GetClientTeam(client) == CS_TEAM_T)
				SetEntityModel(client, g_szRaceModelT);
			else if (IsModelPrecached(g_szRaceModelCT) && GetClientTeam(client) == CS_TEAM_CT)
				SetEntityModel(client, g_szRaceModelCT);
		}
		
	}
}

public OnWeaponFired(client)
{	
	if (War3_GetRace(client) == thisRaceID)
	{
		new String:weapon[128];//weapon Char Array
		GetClientWeapon(client, weapon, 128);
		if(StrEqual(weapon,"weapon_hegrenade"))
		{
			CreateTimer(1.0, UseGrenade, client);
			PrintHintText(client, "Have another nade.");
		}
	}
}

public Action:UseGrenade(Handle:timer, any:client)
{
	if (ValidPlayer(client, true))
	{
		if (War3_GetRace(client) == thisRaceID)
		{
//			PrintToChat (client, "blah");
			GivePlayerItem(client, "weapon_hegrenade");
			FakeClientCommand(client, "use weapon_hegrenade");
			
		}
	}
}


public OnW3TakeDmgAllPre(victim, attacker, Float:damage)
{
	if (ValidPlayer(victim) && ValidPlayer(attacker) && GetClientTeam(victim) != GetClientTeam(attacker))
	{
		if (War3_GetRace(attacker) == thisRaceID && !W3HasImmunity(victim, Immunity_Skills))
		{
			new arcanite = War3_GetSkillLevel(attacker, thisRaceID, SKILL_ARCANITE);
			new liquidfire = War3_GetSkillLevel(attacker, thisRaceID, SKILL_LIQUIDFIRE);
			if (arcanite > 0 && War3_Chance(ArcaniteChance[arcanite]))
			{
				War3_DamageModPercent(ArcaniteDamagePercent[arcanite]);
				PrintToConsole(attacker, "You did %d extra damage with Arcanite", RoundToFloor(damage * ArcaniteDamagePercent[arcanite] - damage));
				W3FlashScreen(victim, RGBA_COLOR_RED);
			}
			if (liquidfire > 0 && War3_Chance(0.5))
			{
				IgniteEntity(victim, LiquidFireArr[liquidfire]);
				PrintToConsole(attacker, "Liquid Fire burns your enemy");
				W3FlashScreen(victim, RGBA_COLOR_RED);
			}
		}
	}
}

public OnWar3EventDeath(victim, attacker)
{
	ExtinguishEntity(victim);
}

public OnUltimateCommand(client, race, bool:pressed)
{
	if (race == thisRaceID && IsPlayerAlive(client))
	{
		if (pressed)
		{
			if (War3_GetSkillLevel(client, thisRaceID, ULT_CONCOCTION) > 0)
			{
				if (War3_SkillNotInCooldown(client, thisRaceID, ULT_CONCOCTION, false))
				{
					if (!Silenced(client))
					{
						if (g_bFlyingType)
						{
							g_bFlying[client] = true;
							War3_SetBuff(client, bFlyMode, thisRaceID, true);
						}
						else
						{
							if (g_bFlying[client])
							{
								g_bFlying[client] = false;
								War3_SetBuff(client, bFlyMode, thisRaceID, false);
								PrintHintText(client, "Get on your bat and fly!");
							}
							else
							{
								g_bFlying[client] = true;
								War3_SetBuff(client, bFlyMode, thisRaceID, true);
								PrintHintText(client, "Get off you bat and stop flying!");
							}
							War3_CooldownMGR(client, g_fUltCooldown, thisRaceID, ULT_CONCOCTION, _, false);
						}
					}
				}
			}
			else
			{
				W3MsgUltNotLeveled(client);
			}
		}
		else if (g_bFlyingType)
		{
			if (g_bFlying[client])
			{
				g_bFlying[client] = false;
				War3_SetBuff(client, bFlyMode, thisRaceID, false);
				War3_CooldownMGR(client, g_fUltCooldown, thisRaceID, ULT_CONCOCTION, _, false);
			}
		}
	}
}

public OnConVarChange(Handle:convar_hndl, const String:oldValue[], const String:newValue[])
{
	GetConVars();
}

public OnConfigsExecuted()
{
	GetConVars();
}

public GetConVars()
{
	g_fUltCooldown = GetConVarFloat(g_hCvarUltCooldown);
	g_bFlyingType = GetConVarBool(g_hCvarFlyingType);
	g_bCustomModel = GetConVarBool(g_hCvarCustomModel);
	
}
