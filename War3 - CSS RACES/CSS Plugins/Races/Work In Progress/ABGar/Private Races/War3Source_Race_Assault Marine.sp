#pragma semicolon 1
 
#include "W3SIncs/War3Source_Interface"
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <smlib>

public Plugin:myinfo = 
{
	name = "War3Source Race - Assault Marine",
	author = "ABGar",
	description = "The Assault Marine race for War3Source.",
	version = "1.0",
	// Axe603's Private Race Request - https://www.sevensinsgaming.com/forum/index.php?/topic/5514-assault-marine-private/
}

new thisRaceID;

new SKILL_JUMP, SKILL_CHAIN, SKILL_ARMOUR, ULT_DASH;

// SKILL_JUMP
new Float:JumpGravity[]={0.0,0.8,0.7,0.6,0.5};

// SKILL_CHAIN
new Float:ChainDamage[]={0.0,0.2,0.3,0.4,0.5};

// SKILL_ARMOUR
new Float:ArmourDamageReduce[]={1.0,0.95,0.9,0.85,0.8};

// ULT_DASH
new m_vecBaseVelocity;
new Float:DashCD=5.0;
new Float:PushForce[]={0.0,0.2,0.35,0.50,0.75};
new String:DashSound[]="weapons/physcannon/superphys_launch1.wav";


public OnWar3PluginReady()
{
	thisRaceID=War3_CreateNewRace("Assault Marine [PRIVATE]","assaultmarine");
	SKILL_JUMP = War3_AddRaceSkill(thisRaceID,"Jump Packs","Using jump packs, you soar through the sky (passive) \n Decreased gravity",false,4);
	SKILL_CHAIN = War3_AddRaceSkill(thisRaceID,"Chainsword","You are equipped with a chainsword (passive knife) \n Increase knife damage",false,4);
	SKILL_ARMOUR = War3_AddRaceSkill(thisRaceID,"Power Armour","Ceramite stops bullets in their tracks (passive) \n Damage taken is reduced",false,4);
	ULT_DASH=War3_AddRaceSkill(thisRaceID,"Power Dash","You dash forwards using your jump pack (+ultimate)",true,4);
	War3_CreateRaceEnd(thisRaceID);
	War3_AddSkillBuff(thisRaceID,SKILL_JUMP,fLowGravitySkill,JumpGravity);
	War3_AddSkillBuff(thisRaceID,SKILL_CHAIN,fDamageModifier,ChainDamage);
}

public OnPluginStart()
{
	m_vecBaseVelocity = FindSendPropOffs("CBasePlayer","m_vecBaseVelocity");
}

public OnMapStart()
{
	War3_PrecacheSound(DashSound);
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

/* *************************************** (SKILL_ARMOUR) *************************************** */
public OnW3TakeDmgBulletPre(victim,attacker,Float:damage)
{
	if(ValidPlayer(victim) && ValidPlayer(attacker) && GetClientTeam(attacker)!=GetClientTeam(victim))
	{
		if(War3_GetRace(victim)==thisRaceID)
		{
			new ArmourLevel = War3_GetSkillLevel(victim,thisRaceID,SKILL_ARMOUR);
			if(ArmourLevel>0)
			{
				War3_DamageModPercent(ArmourDamageReduce[ArmourLevel]);
			}
		}
	}
}

/* *************************************** (ULT_DASH) *************************************** */
public OnUltimateCommand(client,race,bool:pressed)
{
	if(ValidPlayer(client,true) && race==thisRaceID && pressed)
	{
		new DashLevel=War3_GetSkillLevel(client,thisRaceID,ULT_DASH);
		if(DashLevel>0)
		{
			if(SkillAvailable(client,thisRaceID,ULT_DASH,true,true,true))
			{
				War3_CooldownMGR(client,DashCD,thisRaceID,ULT_DASH,true,false);
				TeleportPlayer(client);
				W3EmitSoundToAll(DashSound,client);
			}
		}
		else
			W3MsgUltNotLeveled(client);
	}
}


stock TeleportPlayer( client )
{
	if(ValidPlayer(client,true) && War3_GetRace(client)==thisRaceID)
	{
		new DashLevel=War3_GetSkillLevel(client,thisRaceID,ULT_DASH);
		new Float:startpos[3];		GetClientAbsOrigin(client,startpos);
		new Float:endpos[3];		War3_GetAimEndPoint(client,endpos);
		new Float:localvector[3];
		new Float:velocity[3];
		
		localvector[0] = endpos[0] - startpos[0];
		localvector[1] = endpos[1] - startpos[1];
		localvector[2] = endpos[2] - startpos[2];
		
		velocity[0] = localvector[0] * PushForce[DashLevel];
		velocity[1] = localvector[1] * PushForce[DashLevel];
		velocity[2] = localvector[2] * PushForce[DashLevel];
		
		SetEntDataVector(client,m_vecBaseVelocity,velocity,true);
	}
}
