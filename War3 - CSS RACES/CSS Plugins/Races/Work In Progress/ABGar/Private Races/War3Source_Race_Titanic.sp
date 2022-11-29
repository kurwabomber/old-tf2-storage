#pragma semicolon 1
 
#include "W3SIncs/War3Source_Interface"
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <smlib>

public Plugin:myinfo = 
{
	name = "War3Source Race - Titanic",
	author = "ABGar",
	description = "The Titanic race for War3Source.",
	version = "1.0",
	// Glacier's Private Race Request - https://www.sevensinsgaming.com/forum/index.php?/topic/5171-titanic-race-private/
}

new thisRaceID;

new SKILL_HULL, SKILL_RESCUE, SKILL_STEAM, ULT_RAM;

// SKILL_HULL
new HullHealth[]={0,15,30,40,50};

// SKILL_RESCUE
new Float:RescueHP[]={0.0,0.5,1.0,1.5,2.0};
new Float:RescueSpeedHP=5.0;

// SKILL_STEAM
new Float:SteamSpeed[]={1.0,1.05,1.1,1.15,1.2};

// ULT_RAM
new Float:PushForce=1000.0;
new Float:RamCD[]={0.0,8.0,10.0,11.0,12.0};
new RamDamage[]={0,5,10,15,20};
new String:RamSound[]="npc/combine_gunship/gunship_moan.wav";



public OnWar3PluginReady()
{
	thisRaceID=War3_CreateNewRace("Titanic [PRIVATE]","titanic");
	SKILL_HULL = War3_AddRaceSkill(thisRaceID,"Steel Hull","Extra Health (passive)",false,4);
	SKILL_RESCUE = War3_AddRaceSkill(thisRaceID,"Rescue","Passive HP regen which increases if affected by slows (passve)",false,4);
	SKILL_STEAM = War3_AddRaceSkill(thisRaceID,"Steam Powered","Passive Speed Increase (passive)",false,4);
	ULT_RAM=War3_AddRaceSkill(thisRaceID,"Ram","Pushes a player a short distance, dealing damage (+ultimate)",true,4);
	War3_CreateRaceEnd(thisRaceID);
	W3SkillCooldownOnSpawn(thisRaceID,ULT_RAM,10.0,_);
	War3_AddSkillBuff(thisRaceID,SKILL_HULL,iAdditionalMaxHealth,HullHealth);
	War3_AddSkillBuff(thisRaceID,SKILL_STEAM,fMaxSpeed,SteamSpeed);
}

public OnPluginStart()
{
	CreateTimer(0.1,SpeedTimer,_,TIMER_REPEAT);
}

public OnMapStart()
{
	War3_PrecacheSound(RamSound);
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

}

/* *************************************** (SKILL_RESCUE) *************************************** */
public Action:SpeedTimer(Handle:timer,any:userid)
{
	for(new client=1;client<=MaxClients;client++)
	{
		if(ValidPlayer(client,true) && War3_GetRace(client)==thisRaceID)
		{
			new RescueLevel=War3_GetSkillLevel(client,thisRaceID,SKILL_RESCUE);
			new SpeedLevel=War3_GetSkillLevel(client,thisRaceID,SKILL_STEAM);
			
			if(RescueLevel>0)
			{
				if(W3GetBuffMaxFloat(client,fMaxSpeed)+W3GetBuffMaxFloat(client,fMaxSpeed2)<SteamSpeed[SpeedLevel])
					War3_SetBuff(client,fHPRegen,thisRaceID,RescueSpeedHP);
				else
					War3_SetBuff(client,fHPRegen,thisRaceID,RescueHP[RescueLevel]);
			}
			
			for(new x=1;x<=MaxClients;x++)
			{
				if(ValidPlayer(x,true) && GetClientTeam(client)!=GetClientTeam(x) && GetPlayerDistance(client,x)<30.0)
				{
					ForcePlayerSuicide(client);
					War3_ChatMessage(client,"{red}The TITANIC has struck the Iceberg...");
				}
			}
		}
	}
}

/* *************************************** (ULT_RAM) *************************************** */
public OnUltimateCommand(client,race,bool:pressed)
{
	if(ValidPlayer(client,true) && race==thisRaceID && pressed)
	{
		new RamLevel=War3_GetSkillLevel(client,thisRaceID,ULT_RAM);
		if(RamLevel>0)
		{
			if(SkillAvailable(client,thisRaceID,ULT_RAM,true,true,true))
			{
				new target = War3_GetTargetInViewCone(client,300.0,false,23.0);
				if(target>0)
				{
					War3_CooldownMGR(client,RamCD[RamLevel],thisRaceID,ULT_RAM,_,_);
					
					new Float:clientPos[3];			GetClientAbsOrigin(client,clientPos);
					new Float:targetPos[3];			GetClientAbsOrigin(target,targetPos);
					new Float:vector[3];
				   
					GetClientAbsOrigin(client,clientPos);
					GetClientAbsOrigin(target,targetPos);
					MakeVectorFromPoints(clientPos,targetPos,vector);
					NormalizeVector(vector,vector);
					ScaleVector(vector,PushForce);
					TeleportEntity(target,NULL_VECTOR,NULL_VECTOR,vector);
					
					W3EmitSoundToAll(RamSound,client);
					
					War3_DealDamage(target,RamDamage[RamLevel],client,DMG_CRUSH,"ram",_,W3DMGTYPE_MAGIC);
					War3_DealDamage(client,RamDamage[RamLevel],client,DMG_CRUSH,"ram",_,W3DMGTYPE_MAGIC);
				}
			}
		}
		else
			W3MsgUltNotLeveled(client);
	}
}

