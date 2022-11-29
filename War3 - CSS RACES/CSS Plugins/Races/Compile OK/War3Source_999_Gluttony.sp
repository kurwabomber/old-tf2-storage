/**
* File: War3Source_Gluttony.sp
* Description: New knife race for Seven Sins Gaming use ONLY.
* Author(s): Corrupted
*/

#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdkhooks>
#include <sdktools>
#include <sdktools_functions>
#include <sdktools_tempents>
#include <sdktools_tempents_stocks>
#include <sdktools_sound>

new thisRaceID;

new RegenAmountArr[]={0,1,2,3,4};

new String:AttackSound[]="war3source/nomnom.mp3";

new SKILL_SPEED, SKILL_INVIS, SKILL_REGEN, ULT_KNIFE;

new Float:GluttonSpeed[5] = { 1.0, 1.1, 1.2, 1.3, 1.4 };
new Float:GluttonInvis[5] = { 1.0, 0.8, 0.6, 0.4, 0.2 };
new Float:FireChance[5] = { 0.0, 0.25, 0.5, 0.75, 1.0 };
new Float:FreezeChance[5] = { 0.0, 0.25, 0.5, 0.75, 1.0 };
new Float:FreezeDuration[5] = { 0.0, 0.5, 1.0, 1.5, 2.0 };
new Float:QuakeChance[5] = { 0.0, 0.25, 0.5, 0.75, 1.0 };

public Plugin:myinfo =
{
	name = "War3Source Race - Gluttony",
	author = "Corrupted",
	description = "Knifing starter race for Seven Sins Gaming use ONLY.",
	version = "1.0.0.1",
	url = "www.sevensinsgaming.com",
};


public OnPluginStart()
{
	CreateTimer(1.0,CalculateRegen,_,TIMER_REPEAT);
}

public OnWar3PluginReady()
{
		thisRaceID=War3_CreateNewRace("Gluttony [SSG-DONATOR]","gluttony");
		SKILL_SPEED=War3_AddRaceSkill(thisRaceID,"Speed (passive)","Makes you run faster",false);
		SKILL_INVIS=War3_AddRaceSkill(thisRaceID,"Invisiblity (passive)","Makes you harder to see",false);
		SKILL_REGEN=War3_AddRaceSkill(thisRaceID,"Regeneration (passive)","You heal over time",false);
		ULT_KNIFE=War3_AddRaceSkill(thisRaceID,"Element Knife","Freeze, Burn or Shake your enemies",false); 
		War3_CreateRaceEnd(thisRaceID);
}

public OnMapStart()
{
	War3_AddCustomSound( AttackSound );
}

public OnRaceChanged( client, oldrace, newrace )
{
	if( newrace != thisRaceID )
	{
		War3_WeaponRestrictTo(client,thisRaceID,"" );
		W3ResetAllBuffRace(client,thisRaceID );
	}
	else
	{
		War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife");
		InitPassiveSkills(client);
	}
}

public InitPassiveSkills( client )
{
	if( War3_GetRace( client ) == thisRaceID )
	{			
		War3_SetBuff( client, fMaxSpeed, thisRaceID, GluttonSpeed[War3_GetSkillLevel( client, thisRaceID, SKILL_SPEED )] );
		War3_SetBuff( client, fInvisibilitySkill, thisRaceID, GluttonInvis[War3_GetSkillLevel( client, thisRaceID, SKILL_INVIS )] );
	}
}

public OnSkillLevelChanged( client, race, skill, newskilllevel )
{
	InitPassiveSkills( client );
}

public Action:CalculateRegen(Handle:timer,any:userid)
{
	if(thisRaceID>0)
	{
		for(new i=1;i<=MaxClients;i++)
		{
			if(ValidPlayer(i,true))
			{
				if(War3_GetRace(i)==thisRaceID)
				{
					Regen(i);
				}
			}
		}
	}
}

public Regen(client)
{
	new skill = War3_GetSkillLevel(client,thisRaceID,SKILL_REGEN);
	if(skill>0)
	{
		new Float:dist = 1.0;
		new RegenTeam = GetClientTeam(client);
		new Float:RegenPos[3];
		GetClientAbsOrigin(client,RegenPos);
		new Float:VecPos[3];

		for(new i=1;i<=MaxClients;i++)
		{
			if(ValidPlayer(i,true)&&GetClientTeam(i)==RegenTeam)
			{
				GetClientAbsOrigin(i,VecPos);
				if(GetVectorDistance(RegenPos,VecPos)<=dist)
				{
					War3_HealToMaxHP(i,RegenAmountArr[skill]);
				}
			}
		}
	}
}

public OnWar3EventDeath( victim, attacker )
{
	War3_SetBuff( victim, bNoMoveMode, thisRaceID, false );
}

public OnWar3EventPostHurt(victim, attacker, Float:damage, const String:weapon[32], bool:isWarcraft)
{
	if( ValidPlayer( victim, true ) && ValidPlayer( attacker, true ) && IsPlayerAlive( victim ) && GetClientTeam( victim ) != GetClientTeam( attacker ) )
	{
		if( War3_GetRace( attacker ) == thisRaceID )
		{
			EmitSoundToAll(AttackSound,attacker);
			new ult_level = War3_GetSkillLevel( attacker, thisRaceID, ULT_KNIFE );
			if (ult_level > 0)
			{
				new DICE = (GetRandomInt(1,3));
				if (DICE == 1)
				{
					if( !Hexed( attacker, false ) && GetRandomFloat( 0.0, 1.0 ) <= FireChance[ult_level] )
					{
						if( !W3HasImmunity( victim, Immunity_Skills ) )
						{
							IgniteEntity( victim, 2.5 );
						}
					}
				}
				if (DICE == 2)
				{
					if( !Hexed( attacker, false ) && GetRandomFloat( 0.0, 1.0 ) <= QuakeChance[ult_level] )
					{
						War3_ShakeScreen(victim,2.0,50.0,40.0);
					}
				}
				if (DICE == 3)
				{
					if( !Hexed ( attacker, false) && GetRandomFloat( 0.0, 1.0 ) <= FreezeChance[ult_level] )
					{
						if( !W3HasImmunity( victim, Immunity_Skills ) )
						{
							War3_SetBuff( victim, bNoMoveMode, thisRaceID, true );
												
							CreateTimer( FreezeDuration[ult_level], StopFreeze, victim );
						}
					}
				}
			}
		}
	}
}

public Action:StopFreeze( Handle:timer, any:client )
{
	if( ValidPlayer( client, true ) )
	{
		War3_SetBuff( client, bNoMoveMode, thisRaceID, false );
	}
}