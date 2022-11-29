#pragma semicolon 1
 
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdkhooks>
#include "W3SIncs/haaaxfunctions"

public Plugin:myinfo = 
{
	name = "War3Source Race - Santa Claus",
	author = "ABGar",
	description = "The Santa Claus race for War3Source.",
	version = "1.0",
	// Insert's Private Race Request - http://www.sevensinsgaming.com/forum/index.php?/topic/5215-santa-claus/
}

new thisRaceID;

new SKILL_FLY, SKILL_PAD, SKILL_PRES, ULT_ELF;

new String:SantaModel[]="models/player/techknow/santa/santa.mdl";

// SKILL_FLY
new bool:bIsFlying[MAXPLAYERS];

// SKILL_PAD
new PadHealth[]={0,10,20,30,40,50};

// SKILL_PRES
new Float:PresTime[]={0.0,10.0,9.0,8.0,7.0,6.0};

// ULT_ELF
new Float:ElfCD[]={0.0,80.0,75.0,70.0,65.0,5.0};
new bool:bSummoned[MAXPLAYERS];
new PlayerOldRace[MAXPLAYERS];
new g_SupportCount[MAXPLAYERS];

public OnWar3PluginReady()
{
	thisRaceID=War3_CreateNewRace("Santa Claus [PRIVATE]","santaclaus");
	SKILL_FLY = War3_AddRaceSkill(thisRaceID,"Hop on your sleigh","Fly (+ability)",false,1);
	SKILL_PAD = War3_AddRaceSkill(thisRaceID,"Padded clothing","Bonus Health (passive)",false,5);
	SKILL_PRES = War3_AddRaceSkill(thisRaceID,"Presents","Spawn grenades (passive)",false,5);
	ULT_ELF=War3_AddRaceSkill(thisRaceID,"Santa's Little Helpers","Respawn 2 team mates as Elves (+ultimate)",false,5);
	War3_CreateRaceEnd(thisRaceID);
	War3_AddSkillBuff(thisRaceID,SKILL_PAD,iAdditionalMaxHealth,PadHealth);
}


public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace != thisRaceID)
	{
		bIsFlying[client]=false;
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
	CreateTimer(1.0,GiveNade,client);
	bIsFlying[client]=false;
	SetEntityModel(client, SantaModel);
}

public OnMapStart()
{
	AddFileToDownloadsTable(SantaModel);
	AddFileToDownloadsTable("materials/models/player/techknow/santa/santa.vmt");
	AddFileToDownloadsTable("materials/models/player/techknow/santa/santa.vtf");
	AddFileToDownloadsTable("materials/models/player/techknow/santa/santa_n.vtf");
	AddFileToDownloadsTable("models/player/techknow/santa/santa.dx80.vtx");
	AddFileToDownloadsTable("models/player/techknow/santa/santa.dx90.vtx");
	AddFileToDownloadsTable("models/player/techknow/santa/santa.mdl");
	AddFileToDownloadsTable("models/player/techknow/santa/santa.phy");
	AddFileToDownloadsTable("models/player/techknow/santa/santa.sw.vtx");
	AddFileToDownloadsTable("models/player/techknow/santa/santa.vvd");
	PrecacheModel(SantaModel);
}

public OnPluginStart()
{
    HookEvent("round_end",RoundOverEvent);
}

/* *************************************** (SKILL_FLY) *************************************** */
public OnAbilityCommand(client,ability,bool:pressed)
{
	if(War3_GetRace(client)==thisRaceID && pressed && ValidPlayer(client,true))
	{
		if(!Silenced(client) && War3_SkillNotInCooldown(client,thisRaceID,SKILL_FLY,true ))
		{
			new fly_level=War3_GetSkillLevel(client,thisRaceID,SKILL_FLY);
			if (fly_level>0)
				ToggleFly (client, fly_level);
			else
				PrintHintText(client, "Learn to Fly first");
		}
	}
}

stock ToggleFly(client, fly_level)
{
	if (War3_SkillNotInCooldown(client,thisRaceID,SKILL_FLY,true))
	{
		if (bIsFlying[client])
			StopFly(client);
		else
			StartFly(client);
	}
}

stock StartFly(client)
{
	if (!bIsFlying[client])
	{
		if (War3_SkillNotInCooldown(client,thisRaceID,SKILL_FLY,true))
		{
			bIsFlying[client]=true;
			War3_SetBuff(client,bFlyMode,thisRaceID,true);
			War3_SetBuff(client,fMaxSpeed,thisRaceID,1.5);
			PrintHintText(client,"Get on your sleigh, fat man...");
		}
	}
}

stock StopFly(client)
{
	if (bIsFlying[client])
	{
		bIsFlying[client]=false;
		War3_SetBuff(client,bFlyMode,thisRaceID,false);
		W3ResetBuffRace(client,fMaxSpeed,thisRaceID);
		PrintHintText(client,"Off your sleigh");
		War3_CooldownMGR(client,10.0,thisRaceID,SKILL_FLY,_,_);
	}
}

/* *************************************** (SKILL_PRES) *************************************** */
public Action:GiveNade(Handle:timer,any:userid)
{
	for(new client=1;client<=MaxClients;client++)
	{
		if(ValidPlayer(client,true) && War3_GetRace(client)==thisRaceID)
		{
			new pres_level=War3_GetSkillLevel(client,thisRaceID,SKILL_PRES);
			if(pres_level>0)
			{
				CreateTimer(PresTime[pres_level],GiveNade,client);
				new iOffset = FindSendPropInfo("CCSPlayer", "m_iAmmo");
				if (GetEntData(client, iOffset + 44) == 0)
				{		
					GivePlayerItem(client, "weapon_hegrenade");
					PrintHintText(client,"Santa's present");
				}
			}
		}
	}
}
/* *************************************** (ULT_ELF) *************************************** */
public OnUltimateCommand(client,race,bool:pressed)
{
	if(ValidPlayer(client,true) && race==thisRaceID && pressed)
	{
		new elf_level=War3_GetSkillLevel(client,thisRaceID,ULT_ELF);
		if(elf_level>0)
		{
			if(War3_SkillNotInCooldown(client,thisRaceID,ULT_ELF,true))
			{
				if(!Silenced(client))
				{
					CallElf(client);
					War3_CooldownMGR(client,ElfCD[elf_level],thisRaceID,ULT_ELF,_,_);
				}
			}
		}
		else
			W3MsgUltNotLeveled(client);
	}
}				


stock CallElf(client)
{
	new bestTarget;
	if( GetClientTeam( client ) == TEAM_T )
		bestTarget = War3_GetRandomPlayer(client, "#t");
	if( GetClientTeam( client ) == TEAM_CT )
		bestTarget = War3_GetRandomPlayer(client, "#ct");

	if( bestTarget==0 )
		PrintHintText(client,"All of your elves are busy...");
	else
	{
		new Float:ang[3];
		new Float:pos[3];
		GetClientEyeAngles(client,ang);
		GetClientAbsOrigin(client,pos);
		new elfrace=War3_GetRaceIDByShortname("santaelf");
		if (elfrace==0)
			PrintToChat(client, "WE CAN'T FIND ANY ELF RACE");
		else
		{
			PlayerOldRace[bestTarget]=War3_GetRace(bestTarget);
			W3SetPlayerProp(bestTarget,RaceChosenTime,GetGameTime());
			W3SetPlayerProp(bestTarget,RaceSetByAdmin,true);
			War3_SetRace(bestTarget,elfrace);              
			bSummoned[bestTarget]=true;    
			War3_SpawnPlayer(bestTarget);
			TeleportEntity(bestTarget,pos,ang,NULL_VECTOR);
			PrintCenterText(bestTarget, "Your elves are here to help");
		}
	}
	g_SupportCount[client]++;

	if(g_SupportCount[client] < 2)
		CallElf(client);
	else
		g_SupportCount[client] = 0;
}

public OnWar3EventDeath(victim,attacker)
{
	if(bSummoned[victim])
		War3_SetRace(victim,PlayerOldRace[victim]);   
}

public RoundOverEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    for(new i=1;i<=MaxClients;i++)
    {
        if(ValidPlayer(i))
        {
            if(bSummoned[i])
            {
                bSummoned[i] = false;
                War3_SetRace(i,PlayerOldRace[i]);   
            }
        }
    }
}













