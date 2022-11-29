#pragma semicolon 1
 
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdkhooks>

public Plugin:myinfo = 
{
	name = "War3Source Race - Hunter",
	author = "ABGar",
	description = "The Hunter race for War3Source.",
	version = "1.0",
	// Arrow's Private Race Request - www.sevensinsgaming.com/forum/index.php?/topic/5175-hunter-private/
}

new thisRaceID;

new SKILL_STEALTH, SKILL_MOBILITY, SKILL_IMMUNE, ULT_TRACK;

// SKILL_STEALTH
new Float:HunterInvis[]={1.0,0.0};
new HunterHealth[]={0,-99};

// SKILL_MOBILITY
new Float:HunterSpeed[]={1.0,1.1,1.2,1.3,1.4,1.5};
new Float:HunterGrav[]={1.0,0.9,0.8,0.7,0.6,0.5};

// SKILL_IMMUNE
new Float:HunterImmuneChance[]={0.0,0.6,0.7,0.8,0.9,1.0};

// ULT_TRACK
new GlowSprite, BeamSprite, HaloSprite;
new bMarked[MAXPLAYERSCUSTOM];
new bMarkedBy[MAXPLAYERSCUSTOM];
new bNotified[MAXPLAYERSCUSTOM];
new bBeaconed[MAXPLAYERSCUSTOM];
new bUsedMark[MAXPLAYERSCUSTOM];
new Float:MarkedDamage[]={1.0,1.2,1.3,1.4,1.5,1.6};
new Float:NonMarkedDamage[]={1.0,0.95,0.93,0.89,0.85,0.8};
new KillMarkedGold[]={0,1,1,2,2,3};

public OnWar3PluginReady()
{
	thisRaceID=War3_CreateNewRace("Hunter [PRIVATE]","thehunter");
	SKILL_STEALTH = War3_AddRaceSkill(thisRaceID,"Stealth","A Hunter cannot be seen (passive)",false,1);
	SKILL_MOBILITY = War3_AddRaceSkill(thisRaceID,"Mobility","A Hunter can hunt the fastest of prey (passive)",false,5);
	SKILL_IMMUNE = War3_AddRaceSkill(thisRaceID,"Immunity","The Hunter wears enchanted armour to protect him from magic {passive}",false,5);
	ULT_TRACK=War3_AddRaceSkill(thisRaceID,"Track","A Hunter always hunts for his favourite prey first (passive ultimate)",true,5);
	War3_CreateRaceEnd(thisRaceID);
	War3_AddSkillBuff(thisRaceID,SKILL_MOBILITY,fMaxSpeed,HunterSpeed);
	War3_AddSkillBuff(thisRaceID,SKILL_MOBILITY,fLowGravitySkill,HunterGrav);
	War3_AddSkillBuff(thisRaceID,SKILL_STEALTH,fInvisibilitySkill,HunterInvis);
	War3_AddSkillBuff(thisRaceID,SKILL_STEALTH,iAdditionalMaxHealth,HunterHealth);
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
	bUsedMark[client]=false;
	War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife");
	War3_SetBuff(client,bDoNotInvisWeapon,thisRaceID,true);
	
	new ImmuneLevel = War3_GetSkillLevel(client,thisRaceID,SKILL_IMMUNE);
	new TrackLevel = War3_GetSkillLevel(client,thisRaceID,ULT_TRACK);
	if(TrackLevel>0)
		CreateTimer(0.5,TrackStart,client);
	if(W3Chance(HunterImmuneChance[ImmuneLevel]))
	{
		War3_SetBuff(client,bImmunityUltimates,thisRaceID,true);
		War3_SetBuff(client,bImmunitySkills,thisRaceID,true);
		War3_SetBuff(client,bImmunityWards,thisRaceID,true);
		War3_SetBuff(client,bSlowImmunity,thisRaceID,true);
		PrintToChat(client,"\x04 %N \x03You are immune this round",client);
	}
	else
		PrintToChat(client,"\x04 %N \x03You are NOT immune this round",client);
}

public OnMapStart()
{
	GlowSprite=PrecacheModel("materials/effects/fluttercore.vmt");
	BeamSprite=PrecacheModel("materials/sprites/lgtning.vmt");
	HaloSprite=PrecacheModel("materials/sprites/halo01.vmt");
}

public OnPluginStart()
{
	HookEvent("round_end", OnRoundEnd);	
	CreateTimer(1.0, DoBeacon,_,TIMER_REPEAT);
}

/* *************************************** (ULT_TRACK) *************************************** */
public OnGameFrame()
{
	for(new i=1;i<=MaxClients;i++)
	{
		if(ValidPlayer(i,true) && bMarked[i])
		{
			new Float:MarkedPos[3];
			new Float:HunterPos[3];
			new Marker=bMarkedBy[i];
			GetClientAbsOrigin(i,MarkedPos);
			GetClientAbsOrigin(Marker,HunterPos);
			MarkedPos[2] += 10;
			
			TE_SetupGlowSprite(MarkedPos,GlowSprite,0.1,0.6,80);
			TE_SendToClient(Marker);
			if(!bNotified[i] && GetVectorDistance(MarkedPos,HunterPos)<=700.0)
			{
				bNotified[i]=true;
				PrintToChat(i,"WATCH OUT!!!! The Hunter is coming for you");
				CreateTimer(10.0,ReNotify,i);
				// EMIT SOUND HERE
			}
			if(GetVectorDistance(MarkedPos,HunterPos)<=500.0)
				bBeaconed[Marker]=true;
			else
				bBeaconed[Marker]=false;
		}
	}
}

public Action:ReNotify(Handle:timer, any:client)
{
	if(ValidPlayer(client) && bNotified[client])
	{
		bNotified[client]=false;
	}
}

public Action:OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	for(new i=1;i<=MaxClients;i++)
	{
		if(ValidPlayer(i) && bMarked[i])
		{
			bMarked[i]=false;
		}
	}
}

public Action:TrackStart(Handle:timer, any:client)
{
	if(!bUsedMark[client])
	{
		new iEnemyTeam = (GetClientTeam(client)==TEAM_T) ? TEAM_CT : TEAM_T;
		new MarkedPlayer = W3GetRandomPlayer(iEnemyTeam,true,Immunity_Ultimates);
		if(ValidPlayer(MarkedPlayer,true))
		{
			bMarked[MarkedPlayer]=true;
			bMarkedBy[MarkedPlayer]=client;
			bMarkedBy[client]=MarkedPlayer;
			PrintToChat(MarkedPlayer,"You have been marked by %N, watch out",client);
			PrintToChat(client,"You have marked %N - Let's go hunting",MarkedPlayer);
			bUsedMark[client]=true;
		}
		else
			CreateTimer(1.0,TrackStart,client);
	}
}

public OnW3TakeDmgBulletPre(victim,attacker,Float:damage)
{
	if(ValidPlayer(victim) && ValidPlayer(attacker) && GetClientTeam(attacker)!=GetClientTeam(victim))
	{
		if(War3_GetRace(attacker)==thisRaceID)
		{
			new TrackLevel = War3_GetSkillLevel(attacker,thisRaceID,ULT_TRACK);
			if(TrackLevel>0)
			{
				if(bMarked[victim])
				{
					new TeamInRange=0;
					for(new i=1;i<=MaxClients;i++)
					{
						if(ValidPlayer(i,true) && GetClientTeam(i)!=GetClientTeam(attacker) && i!=victim)
						{
							new Float:TeamPos[3], Float:VictimPos[3];
							GetClientAbsOrigin(i,TeamPos);
							GetClientAbsOrigin(victim,VictimPos);
							if(GetVectorDistance(TeamPos,VictimPos)<=500.0)
								TeamInRange++;
						}
					}
					if(TeamInRange>0)
						War3_DamageModPercent(MarkedDamage[TrackLevel]+0.5);
					else
						War3_DamageModPercent(MarkedDamage[TrackLevel]);
				}
				else
					War3_DamageModPercent(NonMarkedDamage[TrackLevel]);
			}
		}
	}
}

public OnWar3EventDeath(victim,attacker)
{
	if(GetClientTeam(attacker)!=GetClientTeam(victim))
	{
		if(War3_GetRace(attacker)==thisRaceID)
		{
			new TrackLevel = War3_GetSkillLevel(attacker,thisRaceID,ULT_TRACK);
			if(TrackLevel>0 && bMarked[victim])
			{
				War3_AddCurrency(attacker, KillMarkedGold[TrackLevel]);
				PrintToChat(attacker,"You got your mark.  You receved %i extra gold",KillMarkedGold[TrackLevel]);
				CreateTimer(1.0,TrackStart,attacker);	
				bUsedMark[attacker]=false;
			}
		}
	}
}

public Action:DoBeacon(Handle:timer)
{
	for(new i=1;i<=MaxClients;i++)
	{
		if(ValidPlayer(i,true) && bBeaconed[i])
		{
			new Float:iPos[3];
			GetClientAbsOrigin(i,iPos);
			iPos[2] += 10;
			TE_SetupBeamRingPoint(iPos, 10.0, 100.0, BeamSprite, HaloSprite, 0, 15, 0.5, 5.0, 0.0, {255,75,75,255}, 10, 0);
			TE_SendToClient(bMarkedBy[i]);
			TE_SetupBeamRingPoint(iPos, 10.0, 100.0, BeamSprite, HaloSprite, 0, 15, 0.5, 5.0, 0.0, {255,75,75,255}, 10, 0);
			TE_SendToClient(i);
		}
	}
}
















