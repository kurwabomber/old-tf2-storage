#pragma semicolon 1
 
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdkhooks>

public Plugin:myinfo = 
{
	name = "War3Source Race - Realism",
	author = "ABGar",
	description = "The Realism race for War3Source.",
	version = "1.0",
	// SpentMind's Private Race Request - http://www.sevensinsgaming.com/forum/index.php?/topic/5548-realism-spentmind/#entry67300
}

new thisRaceID;

new SKILL_LEG, SKILL_ARM, SKILL_CHEST, ULT_HEAD;

new ChestBleedDamage[]={0,1,2,3,4};
new Float:LegChance[]={0.0,0.2,0.4,0.6,0.8};
new Float:LegSlowTime[]={0.0,0.5,1.0,1.5,2.0};
new Float:LegSlowSpeed=0.8;
new Float:ArmChance[]={0.0,0.2,0.4,0.6,0.8};
new Float:ChestChance[]={0.0,0.2,0.4,0.6,0.8};
new Float:XPGain[]={0.0,0.25,0.5,0.75,1.0};

new bool:bLeg[MAXPLAYERSCUSTOM]=false;
new bool:bArm[MAXPLAYERSCUSTOM]=false;
new bool:bChest[MAXPLAYERSCUSTOM]=false;
new bool:bHeadUsed[MAXPLAYERSCUSTOM]=false;
new bool:bActivated[MAXPLAYERSCUSTOM]=false;
new bool:bChanged[MAXPLAYERSCUSTOM]=false;
new bChangedBy[MAXPLAYERSCUSTOM]=-1;
new bChestBy[MAXPLAYERSCUSTOM]=-1;

new BeamSprite,HaloSprite;

public OnWar3PluginReady()
{
	thisRaceID=War3_CreateNewRace("Realism [PRIVATE]","realism");
	SKILL_LEG = War3_AddRaceSkill(thisRaceID,"Leg Shot","Leg Shots have a chance to slow the enemy on hit (passive)",false,4);
	SKILL_ARM = War3_AddRaceSkill(thisRaceID,"Arm Shot","Arm Shots have a chance to force weapon drop on the enemy (passive)",false,4);
	SKILL_CHEST = War3_AddRaceSkill(thisRaceID,"Chest Shot","Chest Shots have a chance to cause the enemy to bleed for 5 seconds (passive)",false,4);
	ULT_HEAD=War3_AddRaceSkill(thisRaceID,"Head Shot","Once activated, your next head shot will do 0 damage, but convert the enemy instantly to your team.  Any XP they gain, you also gain (+ultimate)",true,4);
	War3_CreateRaceEnd(thisRaceID);
}

public OnMapStart()
{
	BeamSprite=PrecacheModel("materials/sprites/lgtning.vmt");
	HaloSprite=PrecacheModel("materials/sprites/halo01.vmt");
}

public OnPluginStart()
{
	HookEvent("round_end", OnRoundEnd);	
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_TraceAttack, SDK_Forwarded_TraceAttack);
}

public OnClientDisconnect(client)
{
	SDKUnhook(client, SDKHook_TraceAttack, SDK_Forwarded_TraceAttack); 
}

public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace != thisRaceID)
	{
		War3_WeaponRestrictTo(client,thisRaceID,"");
		W3ResetAllBuffRace(client,thisRaceID);
		bHeadUsed[client]=false;
		bActivated[client]=false;
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
	bHeadUsed[client]=false;
	bActivated[client]=false;
	for (new i=1;i<=MaxClients;i++)
	{
		if(ValidPlayer(i))
		{
			bArm[i]=false;
			bLeg[i]=false;
			bChest[i]=false;
			bChanged[i]=false;
			bChestBy[i]=-1;
			bChangedBy[i]=-1;
		}
	}
}

public Action:SDK_Forwarded_TraceAttack(victim, &attacker, &inflictor, &Float:damage, &damagetype, &ammotype, hitbox, hitgroup)
{
	if(ValidPlayer(attacker,true) && War3_GetRace(attacker)==thisRaceID)
	{
		new LegLevel = War3_GetSkillLevel(attacker,thisRaceID,SKILL_LEG);
		new ArmLevel = War3_GetSkillLevel(attacker,thisRaceID,SKILL_ARM);
		new ChestLevel = War3_GetSkillLevel(attacker,thisRaceID,SKILL_CHEST);
		new HeadLevel = War3_GetSkillLevel(attacker,thisRaceID,ULT_HEAD);
		
		if(hitgroup>1)
		{
			if(!bArm[victim] && !bLeg[victim] && !bChest[victim] && SkillFilter(victim))
			{
				if((hitgroup==7 || hitgroup==6) && LegLevel>0)  // Leg Shot
				{
					if(W3Chance(LegChance[LegLevel]))
					{
						bLeg[victim]=true;
						CreateTimer(LegSlowTime[LegLevel],StopSlow,victim);
						War3_SetBuff(victim,fSlow,thisRaceID,LegSlowSpeed);
						CPrintToChat(attacker,"{red} LEG SHOT... Slowed for %i seconds",RoundToZero(LegSlowTime[LegLevel]));
						CPrintToChat(victim,"{red} LEG SHOT... Slowed for %i seconds",RoundToZero(LegSlowTime[LegLevel]));
						CreateTimer(5.0,StopHit,victim);
					}
				}
				else if((hitgroup==5 || hitgroup == 4) && ArmLevel>0)  // Arm Shot
				{
					if(W3Chance(ArmChance[ArmLevel]))
					{
						FakeClientCommand(victim,"drop");
						bArm[victim]=true;
						CPrintToChat(attacker,"{red} ARM SHOT... They've dropped their weapon");
						CPrintToChat(victim,"{red} ARM SHOT... You've dropped your weapon");
						CreateTimer(5.0,StopHit,victim);
					}
				}
				else if((hitgroup==3 || hitgroup == 2) && ChestLevel>0)  // Chest Shot
				{
					if(W3Chance(ChestChance[ChestLevel]))
					{
						bChest[victim]=true;
						bChestBy[victim]=attacker;
						War3_DealDamage(victim,ChestBleedDamage[ChestLevel],attacker,DMG_CRUSH,"bleeding chest",_,W3DMGTYPE_MAGIC);
						CreateTimer(1.0,Bleed,victim);
						CPrintToChat(attacker,"{red} CHEST SHOT... Making them bleed for 5 seconds");
						CPrintToChat(victim,"{red} CHEST SHOT... Bleeding for 5 seconds");
						CreateTimer(5.0,StopHit,victim);
					}
				}
			}
		}
		
		else if(hitgroup==1 && HeadLevel>0 && UltFilter(victim) && !bHeadUsed[attacker] && bActivated[attacker])  // Head Shot
		{
			new PlayersAliveOnTeam;
			for(new i=1;i<MaxClients;i++)
			{
				if(ValidPlayer(i,true) && GetClientTeam(i)!=GetClientTeam(attacker))
					PlayersAliveOnTeam++;
			}
			if(PlayersAliveOnTeam>1)
			{
				damage=0.0;
				CPrintToChat(attacker,"{red} HEAD SHOT... Converted to your team");
				CPrintToChat(victim,"{red} HEAD SHOT... You've been converted to the other team");
				bHeadUsed[attacker]=true;
				bActivated[attacker]=false;
				new TargetTeam=GetClientTeam(victim);
				W3FlashScreen(attacker,{120,0,255,50});
				W3FlashScreen(victim,{120,0,255,50});
				if(TargetTeam==TEAM_CT)
				{
					bChanged[victim]=true;
					bChangedBy[victim]=attacker;
					CS_SwitchTeam(victim, TEAM_T);
				}
				if(TargetTeam==TEAM_T)
				{
					bChanged[victim]=true;
					bChangedBy[victim]=attacker;
					CS_SwitchTeam(victim, TEAM_CT);
				}
				
				new Float:pos[3];			GetClientAbsOrigin(attacker,pos);		pos[2]+=15;
				new Float:tarpos[3];		GetClientAbsOrigin(victim,tarpos);		tarpos[2]+=15;
				
				TE_SetupBeamPoints(pos,tarpos,BeamSprite,HaloSprite,0,1,1.0,10.0,5.0,0,1.0,{120,84,120,255},50);
				TE_SendToAll();	
				TE_SetupBeamRingPoint(tarpos, 1.0, 250.0, BeamSprite, BeamSprite, 0, 5, 1.0, 50.0, 1.0, {120,0,120,255}, 50, 0);
				TE_SendToAll();
				tarpos[2]+=15;
				TE_SetupBeamRingPoint(tarpos, 250.0, 1.0, BeamSprite, BeamSprite, 0, 5, 1.0, 50.0, 1.0, {120,0,120,255}, 50, 0);
				TE_SendToAll();
				tarpos[2]+=15;
				TE_SetupBeamRingPoint(tarpos, 1.0, 125.0, BeamSprite, BeamSprite, 0, 5, 1.0, 50.0, 1.0, {120,0,120,255}, 50, 0);
				TE_SendToAll();
				tarpos[2]+=15;
				TE_SetupBeamRingPoint(tarpos, 125.0, 1.0, BeamSprite, BeamSprite, 0, 5, 1.0, 50.0, 1.0, {120,0,120,255}, 50, 0);
				TE_SendToAll();
			}
			else
				PrintHintText(attacker,"There is only one player on that team - cannot be converted to your team");
		}
	}
}

public Action:Bleed(Handle:timer,any:client)
{
	if(ValidPlayer(client,true) && bChest[client])
	{
		new attacker = bChestBy[client];
		new ChestLevel = War3_GetSkillLevel(attacker,thisRaceID,SKILL_CHEST);
		War3_DealDamage(client,ChestBleedDamage[ChestLevel],attacker,DMG_CRUSH,"bleeding chest",_,W3DMGTYPE_MAGIC);
		CreateTimer(1.0,Bleed,client);
	}
}

public Action:StopSlow(Handle:timer,any:client)
{
	if(ValidPlayer(client) && bLeg[client])
	{
		W3ResetBuffRace(client,fSlow,thisRaceID);
	}
}
	
public Action:StopHit(Handle:timer,any:client)
{
	if(ValidPlayer(client))
	{
		bArm[client]=false;
		bLeg[client]=false;
		bChest[client]=false;
		bChestBy[client]=-1;
	}
}

/* *************************************** (Skill1) *************************************** */
public OnUltimateCommand(client,race,bool:pressed)
{
	if(ValidPlayer(client,true) && race==thisRaceID && pressed)
	{
		new HeadLevel=War3_GetSkillLevel(client,thisRaceID,ULT_HEAD);
		if(HeadLevel>0 && !bHeadUsed[client])
		{
			if(bActivated[client])
				PrintToChat(client,"You've already activated your next headshot");
			else
			{
				bActivated[client]=true;
				CPrintToChat(client,"{red} HeadShot Activated");
			}
		}
		else
			PrintToChat(client,"You've already used your headshot this round");
	}
}

public Action:OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	for(new i=1;i<=MaxClients;i++)
	if(ValidPlayer(i,true))
	{
		if(bChanged[i])
		{
			new target_team=GetClientTeam(i);
			if(target_team==TEAM_T)
			{
				bChanged[i]=false;
				bChangedBy[i]=-1;
				CS_SwitchTeam(i, TEAM_CT);
			}
			else
			{
				bChanged[i]=false;
				bChangedBy[i]=-1;
				CS_SwitchTeam(i, TEAM_T);
			}
		}
	}
}

public OnWar3EventDeath(victim,attacker)
{
	if(bChanged[victim])
	{
		new target_team=GetClientTeam(victim);
		if(target_team==TEAM_T)
		{
			bChanged[victim]=false;
			bChangedBy[victim]=-1;
			CS_SwitchTeam(victim, TEAM_CT);
		}
		else
		{
			bChanged[victim]=false;
			bChangedBy[victim]=-1;
			CS_SwitchTeam(victim, TEAM_T);
		}
	}
}

public OnWar3Event(W3EVENT:event,client)
{
	if(event==OnPostGiveXPGold && ValidPlayer(bChangedBy[client], true))
	{
		new HeadLevel=War3_GetSkillLevel(bChangedBy[client],thisRaceID,ULT_HEAD);
		if (W3GetVar(EventArg1) == XPAwardByKill)
		{
			new xp = W3GetVar(EventArg2);
			new givexp = RoundToZero(xp*XPGain[HeadLevel]);		
			W3GiveXPGold(bChangedBy[client], XPAwardByKill, givexp, 1, "your HeadShot victim's kill....");
		}
	}
}