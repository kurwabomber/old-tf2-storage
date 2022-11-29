#pragma semicolon 1
 
#include "W3SIncs/War3Source_Interface"
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <smlib>

public Plugin:myinfo = 
{
	name = "War3Source Race - Hunter Chicken",
	author = "ABGar",
	description = "The Hunter Chicken race for War3Source.",
	version = "1.0",
	// Elmondodara's Private Race Request - https://www.sevensinsgaming.com/forum/index.php?/topic/5576-private-hunter-chicken-race/
}

new thisRaceID;

new SKILL_GLIDE, SKILL_TALON, SKILL_CHASE, ULT_TRANSFORM;

// SKILL_GLIDE
new Float:GlideGravity[]={1.0,0.9,0.8,0.7,0.5};

// SKILL_TALON
new TalonDamage[]={0,15,30,45,60};
new Float:TalonChance[]={0.0,0.1,0.2,0.3,0.4};
new String:TalonSound[]={"npc/roller/mine/rmine_blades_out2.wav"};

// SKILL_CHASE
new Float:ChaseSpeed[]={1.0,1.1,1.2,1.3,1.4};

// ULT_TRANSFORM
new Float:TransformCD=20.0;
new Float:TransformDuration[]={0.0,1.0,2.0,3.0,4.0,5.0};
new String:ChickenSound[]={"war3source/chicken.wav"};
new String:ChickenModel[]="models/player/chicken/t/chicken-t.mdl";


public OnWar3PluginReady()
{
	thisRaceID=War3_CreateNewRace("Hunter Chicken [PRIVATE]","hunterchick");
	SKILL_GLIDE = War3_AddRaceSkill(thisRaceID,"Glide","Passive lower gravity",false,4);
	SKILL_TALON = War3_AddRaceSkill(thisRaceID,"Talon","Passive chance of bonus damage",false,4);
	SKILL_CHASE = War3_AddRaceSkill(thisRaceID,"Chase","Passive increased speed",false,4);
	ULT_TRANSFORM=War3_AddRaceSkill(thisRaceID,"Transform","Transform into THE chicken (+ultimate)",true,4);
	War3_CreateRaceEnd(thisRaceID);
	War3_AddSkillBuff(thisRaceID,SKILL_GLIDE,fLowGravitySkill,GlideGravity);
	War3_AddSkillBuff(thisRaceID,SKILL_CHASE,fMaxSpeed,ChaseSpeed);
}

public OnMapStart()
{
	War3_PrecacheSound(TalonSound);
	War3_PrecacheSound(ChickenSound);
	AddFileToDownloadsTable(ChickenModel);
	AddFileToDownloadsTable("models/player/chicken/t/chicken-t.sw.vtx");
	AddFileToDownloadsTable("models/player/chicken/t/chicken-t.vvd");
	AddFileToDownloadsTable("models/player/chicken/t/chicken-t.dx80.vtx");
	AddFileToDownloadsTable("models/player/chicken/t/chicken-t.dx90.vtx");
	AddFileToDownloadsTable("models/player/chicken/t/chicken-t.mdl");
	AddFileToDownloadsTable("models/player/chicken/t/chicken-t.phy");
	AddFileToDownloadsTable("materials/models/player/chicken/t/chicken2.vtf");
	AddFileToDownloadsTable("materials/models/player/chicken/t/chicken2.vmt");	
	PrecacheModel(ChickenModel);
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

public InitPassiveSkills(client)
{
	War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife");
}


/* *************************************** (SKILL_TALON) *************************************** */
public OnW3TakeDmgBullet(victim,attacker,Float:damage)
{
	if(ValidPlayer(victim) && ValidPlayer(attacker) && GetClientTeam(attacker)!=GetClientTeam(victim))
	{
		if(War3_GetRace(attacker)==thisRaceID)
		{
			new TalonLevel = War3_GetSkillLevel(attacker,thisRaceID,SKILL_TALON);
			if(TalonLevel>0)
			{
				if(W3Chance(TalonChance[TalonLevel]))
				{
					War3_DealDamage(victim,TalonDamage[TalonLevel],attacker,DMG_CRUSH,"talon",_,W3DMGTYPE_MAGIC);
					W3EmitSoundToAll(TalonSound,attacker);
					W3FlashScreen(attacker,RGBA_COLOR_RED);
				}
			}
		}
	}
}

/* *************************************** (ULT_TRANSFORM) *************************************** */
public OnUltimateCommand(client,race,bool:pressed)
{
	if(ValidPlayer(client,true) && race==thisRaceID && pressed)
	{
		new TransformLevel=War3_GetSkillLevel(client,thisRaceID,ULT_TRANSFORM);
		if(TransformLevel>0)
		{
			if(SkillAvailable(client,thisRaceID,ULT_TRANSFORM,true,true,true))
			{
				War3_CooldownMGR(client,TransformCD,thisRaceID,ULT_TRANSFORM,true,true);
				SetEntityModel(client,ChickenModel);
				CreateTimer(TransformDuration[TransformLevel],StopTalon,client);
				W3EmitSoundToAll(ChickenSound,client);
				
				new iWeapon = GetPlayerWeaponSlot(client, 2);
				if(IsValidEntity(iWeapon))
				{
					RemovePlayerItem(client, iWeapon);
					AcceptEntityInput(iWeapon, "kill");
				}
			}
		}
		else
			W3MsgUltNotLeveled(client);
	}
}

public Action:StopTalon(Handle:timer,any:client)
{
	if(ValidPlayer(client))
	{
		CS_UpdateClientModel(client);
		GivePlayerItem(client,"weapon_knife");
	}
}