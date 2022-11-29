#pragma semicolon 1
 
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdkhooks>

public Plugin:myinfo = 
{
	name = "War3Source Race - Freddy Krueger",
	author = "ABGar (edited by Kibbles)",
	description = "The Freddy Krueger race for War3Source.",
	version = "1.0",
    url = "http://sevensinsgaming.com"
}

new thisRaceID;

new SKILL_FINGER, SKILL_CLOAK, SKILL_STEPS, ULT_NIGHTMARE;

// PASSIVES
new Float:CloakInvis[]={1.0,0.95,0.9,0.8,0.7,0.6};
//new Float:FingerDamage[]={0.0,1.15,1.3,1.45,1.6,1.75};
new Float:FingerDamage[]={0.0,1.25,1.4,1.55,1.7,1.85};//+10% to account for DamageModPercent method applying damage after armour damage reduction, this keeps 1-hit kills at max
new Float:FingerChance=0.5;
new Float:StepsSpeed[]={1.0,1.1,1.15,1.2,1.3,1.4};

new bool:bMoving[MAXPLAYERS];
new Float:CanInvisTime[MAXPLAYERS];
new bool:bTeleported[MAXPLAYERS];
new Float:NightmareCD=60.0;


// SOUNDS
new String:NightmareSound[]="war3source/freddy/freddyult.mp3";
new String:KillSound[]="war3source/freddy/freddykill.mp3";
new String:SpawnSound[]="war3source/freddy/freddyspawn.mp3";
new String:ultimateSound[]="ambient/office/coinslot1.wav";


public OnWar3PluginReady()
{
	thisRaceID=War3_CreateNewRace("Freddy Krueger [PRIVATE]","freddy");
	SKILL_FINGER = War3_AddRaceSkill(thisRaceID,"Get Fingered","Freddy's fingers are big, nasty and ready to play (passive)",false,5);
	SKILL_CLOAK = War3_AddRaceSkill(thisRaceID,"Nightmare Cloak","Freddy can fade out of sight (passive)",false,5);
	SKILL_STEPS = War3_AddRaceSkill(thisRaceID,"Quick Steps","It's Freddy's dream world... and he's fast (passive)",false,5);
	ULT_NIGHTMARE=War3_AddRaceSkill(thisRaceID,"Nightmares","Freddy's coming for you (+ultimate)",true,1);
	War3_CreateRaceEnd(thisRaceID);
	War3_AddSkillBuff(thisRaceID,SKILL_CLOAK,fInvisibilitySkill,CloakInvis);
	War3_AddSkillBuff(thisRaceID,SKILL_STEPS,fMaxSpeed,StepsSpeed);
	W3SkillCooldownOnSpawn(thisRaceID,ULT_NIGHTMARE,20.0,_);
}

public OnMapStart()
{
	AddFileToDownloadsTable("sound/war3source/freddy/freddyult.mp3");
	AddFileToDownloadsTable("sound/war3source/freddy/freddykill.mp3");
	AddFileToDownloadsTable("sound/war3source/freddy/freddyspawn.mp3");
	War3_PrecacheSound(NightmareSound);
	War3_PrecacheSound(KillSound);
	War3_PrecacheSound(SpawnSound);
    War3_PrecacheSound(ultimateSound);
}

public OnPluginStart()
{
	CreateTimer(0.1,CalcVis,_,TIMER_REPEAT);
}

public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace != thisRaceID)
	{
		War3_WeaponRestrictTo(client,thisRaceID,"");
		W3ResetAllBuffRace(client,thisRaceID);
        bMoving[client]=false;//account for instant race changes
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
	War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife");
    bMoving[client]=false;//account for instant race changes
    bTeleported[client]=false;
    War3_SetBuff(client,bDisarm,thisRaceID,false);
	EmitSoundToAll(SpawnSound,client,_,_,_,0.5);
}

/* *************************************** (SKILL_CLOAK) *************************************** */
public Action:CalcVis(Handle:timer)
{
	for(new i=1;i<=MaxClients;i++)//use proper range, 1 to MaxClients
	{
		if(ValidPlayer(i, true) && War3_GetRace(i)==thisRaceID)//check if they're alive
		{
			new CloakLevel = War3_GetSkillLevel(i,thisRaceID,SKILL_CLOAK);//no need to check cloak level early. If they de-level the skill it makes them visible because of the zeroth level value in the array
            if(CloakLevel>0 && CanInvisTime[i]<GetGameTime())
            {
                War3_SetBuff(i,fInvisibilitySkill,thisRaceID,0.1);
            }
            else
            {
                War3_SetBuff(i,fInvisibilitySkill,thisRaceID,CloakInvis[CloakLevel]);
            }
            if(CloakLevel>0 && bMoving[i])//(bMoving[i] || bTeleported[i]))
            {
                CanInvisTime[i]=GetGameTime() + 1.0;
            }
		}
	}
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(ValidPlayer(client,true)&&War3_GetRace(client)==thisRaceID)//check if they're alive
	{
		bMoving[client]=(buttons & (IN_FORWARD | IN_BACK | IN_MOVELEFT | IN_MOVERIGHT | IN_JUMP))?true:false;
	}
	return Plugin_Continue;
}


/* *************************************** (SKILL_FINGER) *************************************** */
public OnW3TakeDmgBulletPre(victim,attacker,Float:damage)
{
	if(ValidPlayer(victim) && ValidPlayer(attacker) && GetClientTeam(attacker)!=GetClientTeam(victim))
	{
		if(War3_GetRace(attacker)==thisRaceID)
		{
			if(!Hexed(attacker, true))
			{
				new FingerLevel = War3_GetSkillLevel(attacker,thisRaceID,SKILL_FINGER);
				if(FingerLevel>0 && W3Chance(FingerChance))
				{
                    War3_DamageModPercent(FingerDamage[FingerLevel]);
				}
			}
		}
	}
}


/* *************************************** (ULT_NIGHTMARE) *************************************** */
public OnUltimateCommand(client,race,bool:pressed)
{
	if(ValidPlayer(client,true) && race==thisRaceID && pressed)
	{
		new level=War3_GetSkillLevel(client,thisRaceID,ULT_NIGHTMARE);
		if(level>0)
		{
			if(SkillAvailable(client,thisRaceID,ULT_NIGHTMARE,true,true,true))
			{
				new ClientTeam = GetClientTeam(client);
				new iEnemyTeam = (ClientTeam == TEAM_T) ? TEAM_CT : TEAM_T;
				new target = W3GetRandomPlayer(iEnemyTeam,true,Immunity_Ultimates);
				if(target > 0)
				{
					War3_CooldownMGR(client,NightmareCD,thisRaceID,ULT_NIGHTMARE,true,true);
					new Float:EnemyPos[3];
					GetClientAbsOrigin(target,EnemyPos);
                    War3_SetBuff(client,bDisarm,thisRaceID,true);
					CreateTimer(0.5,StopDisarm,client);
					TeleportEntity(client, EnemyPos, NULL_VECTOR, NULL_VECTOR);
                    EmitSoundToAll(ultimateSound,client);
					EmitSoundToAll(NightmareSound,client,_,_,_,0.5);
					bTeleported[client]=true;
                    CreateTimer(2.0,EndTeleport,client);
				}
				else
					W3MsgNoTargetFound(client);
			}
		}
		else
			W3MsgUltNotLeveled(client);
	}
}

public Action:StopDisarm(Handle:timer,any:client)
{
	if(ValidPlayer(client))
	{
		War3_SetBuff(client,bDisarm,thisRaceID,false);
	}
}

public Action:EndTeleport(Handle:timer,any:client)
{
    if(ValidPlayer(client) && bTeleported[client])
    {
        bTeleported[client] = false;
    }
}

public OnWar3EventDeath(victim,attacker)
{
	if(GetClientTeam(attacker)!=GetClientTeam(victim))
	{
		if(War3_GetRace(attacker)==thisRaceID)
		{
			EmitSoundToAll(KillSound,attacker,_,_,_,0.5);
		}
	}
}