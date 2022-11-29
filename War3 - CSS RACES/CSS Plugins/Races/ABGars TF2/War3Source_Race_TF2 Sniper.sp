#pragma semicolon 1
 
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdkhooks>

public Plugin:myinfo = 
{
	name = "War3Source Race - TF2 Sniper",
	author = "ABGar",
	description = "The TF2 Sniper race for War3Source.",
	version = "1.0",
}

new thisRaceID;

new SKILL_SYDNEY, SKILL_COZY, SKILL_BUSHWAKA, ULT_MATE;

// SKILL_SYDNEY
new GlowSprite;
new bool:bMarked[MAXPLAYERSCUSTOM];
new Float:SydneyChance[]={0.0,0.3,0.4,0.5,0.6};
new Float:SydneyDamage[]={1.0,1.2,1.3,1.4,1.5};
new Float:SydneyCoolDown=5.0;
new String:SydneySound[]="war3source/beggar/laugh.mp3";

// SKILL_COZY
new Float:CozyRegen[]={0.0,1.0,2.0,3.0,4.0};
new CozyHealth[]={0,10,15,20,25};

// SKILL_BUSHWAKA
new Float:BushwakaDamage[]={1.0,1.5,1.6,1.7,1.8};

// ULT_MATE
new Float:MateCD[]={0.0,40.0,30.0,25.0,20.0};
new Float:MateDuration[]={0.0,6.0,8.0,10.0,12.0};
new String:MateSound[]="war3source/butcher/taunt_after.mp3";




public OnWar3PluginReady()
{
	thisRaceID=War3_CreateNewRace("TF2 Sniper","tf2sniper");
	SKILL_SYDNEY = War3_AddRaceSkill(thisRaceID,"Sydney Sleeper","On hit, opponent is covered in piss – Marks target and takes bonus damage on next hit",false,4);
	SKILL_COZY = War3_AddRaceSkill(thisRaceID,"Cozy camper","Health regen and more health",false,4);
	SKILL_BUSHWAKA = War3_AddRaceSkill(thisRaceID,"The Bushwaka","Bonus knife damage to marked players",false,4);
	ULT_MATE=War3_AddRaceSkill(thisRaceID,"Piss off mate","Pulls out his SMG for a short amount of time (+ultimate)",true,4);
	War3_CreateRaceEnd(thisRaceID);
	W3SkillCooldownOnSpawn(thisRaceID,ULT_MATE,10.0,_);
	War3_AddSkillBuff(thisRaceID,SKILL_COZY,iAdditionalMaxHealth,CozyHealth);
	War3_AddSkillBuff(thisRaceID,SKILL_COZY,fHPRegen,CozyRegen);
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
	DropSecWeapon(client);
	War3_WeaponRestrictTo(client,thisRaceID,"weapon_scout,weapon_knife");
	GivePlayerItem(client,"weapon_scout");
}

public DropPrimWeapon(client)
{
	new iWeapon = GetPlayerWeaponSlot(client, 0);  
	if(IsValidEntity(iWeapon))
	{
		RemovePlayerItem(client, iWeapon);
		AcceptEntityInput(iWeapon, "kill");
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

public OnMapStart()
{
	GlowSprite=PrecacheModel("effects/redflare.vmt");
	PrecacheSound(SydneySound);
	PrecacheSound(MateSound);
}

/* *************************************** (SKILL_SYDNEY) *************************************** */
/* *************************************** (SKILL_BUSHWAKA) *************************************** */

public OnGameFrame()
{
	for(new client=1;client<=MaxClients;client++)
	{
		if(ValidPlayer(client,true) && War3_GetRace(client)==thisRaceID)
		{
			for(new i=1;i<=MaxClients;i++)
			{
				if(ValidPlayer(i,true) && bMarked[i])
				{
					new Float:iPos[3];
					GetClientAbsOrigin(i,iPos);
					iPos[2]+=20;
					TE_SetupGlowSprite(iPos,GlowSprite,0.1,1.2,80);
					TE_SendToClient(client);
				}
			}
		}
	}
}


public OnW3TakeDmgBulletPre(victim,attacker,Float:damage)
{
	if(ValidPlayer(victim, true) && ValidPlayer(attacker) && GetClientTeam(attacker)!=GetClientTeam(victim))
	{
		if(War3_GetRace(attacker)==thisRaceID)
		{
			new String:weapon[32]; 
			GetClientWeapon(attacker,weapon,32);
			new SydneyLevel = War3_GetSkillLevel(attacker,thisRaceID,SKILL_SYDNEY);
			new BushwakaLevel = War3_GetSkillLevel(attacker,thisRaceID,SKILL_BUSHWAKA);
			
			if(bMarked[victim])
			{
				bMarked[victim]=false;

				if(StrEqual(weapon,"weapon_knife"))
					War3_DamageModPercent(BushwakaDamage[BushwakaLevel]);
				else
					War3_DamageModPercent(SydneyDamage[SydneyLevel]);
			}
			else
			{
				if(SkillAvailable(attacker,thisRaceID,SKILL_SYDNEY,true,true,true) && StrEqual(weapon,"weapon_scout"))
				{
					if(W3Chance(SydneyChance[SydneyLevel]))
					{
						bMarked[victim]=true;
						PrintHintText(attacker,"You covered him in piss...");
						War3_CooldownMGR(attacker,SydneyCoolDown,thisRaceID,SKILL_SYDNEY,true,true);
						W3EmitSoundToAll(SydneySound,attacker);
					}
				}
			}
		}
	}
}

/* *************************************** (ULT_MATE) *************************************** */
public OnUltimateCommand(client,race,bool:pressed)
{
	if(ValidPlayer(client,true) && race==thisRaceID && pressed)
	{
		new MateLevel=War3_GetSkillLevel(client,thisRaceID,ULT_MATE);
		if(MateLevel>0)
		{
			if(SkillAvailable(client,thisRaceID,ULT_MATE,true,true,true))
			{
				War3_CooldownMGR(client,(MateCD[MateLevel]+MateDuration[MateLevel]),thisRaceID,ULT_MATE,true,true);
				CreateTimer(MateDuration[MateLevel],EndMate,client);
				DropPrimWeapon(client);
				War3_WeaponRestrictTo(client,thisRaceID,"weapon_ump45,weapon_knife");
				GivePlayerItem(client,"weapon_ump45");
				W3EmitSoundToAll(MateSound,client);
			}
		}
		else
			W3MsgUltNotLeveled(client);
	}
}


public Action:EndMate(Handle:timer,any:client)
{
	if(ValidPlayer(client,true))
	{
		DropPrimWeapon(client);
		War3_WeaponRestrictTo(client,thisRaceID,"weapon_scout,weapon_knife");
		GivePlayerItem(client,"weapon_scout");
	}
}