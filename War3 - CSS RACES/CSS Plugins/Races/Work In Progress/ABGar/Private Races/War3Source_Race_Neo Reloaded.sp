#pragma semicolon 1
 
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdkhooks>

public Plugin:myinfo = 
{
	name = "War3Source Race - Neo Reloaded",
	author = "ABGar",
	description = "The Neo Reloaded race for War3Source.",
	version = "1.0",
	// Kanon's Private Race Request - http://www.sevensinsgaming.com/forum/index.php?/topic/4442-neo-reloaded-private
}

new thisRaceID;

new SKILL_PHYSICS, SKILL_AGENTS, SKILL_MOTION, ULT_CODE;

// SKILL_PHYSICS
new m_vecVelocity_0, m_vecVelocity_1, m_vecBaseVelocity;
new Float:SkillLongJump[]={0.0,1.5,2.0,2.5,3.0};
new Float:NeoGrav[] = {1.0,0.92,0.84,0.76,0.68};

// SKILL_AGENTS
new BeamSprite,HaloSprite;
new Float:AgentRange[]={0.0,200.0,300.0,400.0,500.0};

// SKILL_MOTION
new Float:MotionDur[]={0.0,1.0,2.0,3.0,4.0};
new Float:MotionSlow[]={0.0,0.9,0.8,0.7,0.6};
new Float:MotionRange[]={0.0,200.0,300.0,400.0,500.0};
new bSlowed[MAXPLAYERS];

// ULT_CODE
new Float:CodeChance[]={0.0,0.1,0.15,0.2,0.25};
new bCodeUsed[MAXPLAYERS];
new bCoded[MAXPLAYERS];
new CodeKilled[MAXPLAYERS];
new bCodeOwner[MAXPLAYERS];


public OnWar3PluginReady()
{
	thisRaceID=War3_CreateNewRace("Neo Reloaded [PRIVATE]","neoreloaded");
	SKILL_PHYSICS = War3_AddRaceSkill(thisRaceID,"Broken Physics","In the Matrix, Neo can break the laws of physics (passive)",false,4);
	SKILL_AGENTS = War3_AddRaceSkill(thisRaceID,"Detection","Neo can detect any agents in the Matrix (passive)",false,4);
	SKILL_MOTION = War3_AddRaceSkill(thisRaceID,"Slow Motion","Neo goes in slow motion mode (+ability)",false,4);
	ULT_CODE=War3_AddRaceSkill(thisRaceID,"Altered Code","Neo will leap into your body, altering your code until destroyed (passive ultimate)",false,4);
	War3_CreateRaceEnd(thisRaceID);
	War3_AddSkillBuff(thisRaceID, SKILL_PHYSICS, fLowGravitySkill, NeoGrav);
}


public OnRaceChanged(client,oldrace,newrace)
{
	if( newrace != thisRaceID )
	{
		War3_WeaponRestrictTo(client, thisRaceID, "");
		W3ResetAllBuffRace( client, thisRaceID );
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

public OnMapStart()
{
	BeamSprite=PrecacheModel("materials/sprites/lgtning.vmt");
	HaloSprite=PrecacheModel("materials/sprites/halo01.vmt");
}

public InitPassiveSkills(client)
{
	bCoded[client]=false;
	bSlowed[client]=false;
}

/* *************************************** (SKILL_PHYSICS) *************************************** */
public PlayerJumpEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	new client=GetClientOfUserId(GetEventInt(event,"userid"));
	if(War3_GetRace(client)==thisRaceID)
	{
		new skilllevel=War3_GetSkillLevel(client,thisRaceID,SKILL_PHYSICS);
		if(skilllevel>0)
		{
			new Float:velocity[3]={0.0,0.0,0.0};
			velocity[0]= GetEntDataFloat(client,m_vecVelocity_0);
			velocity[1]= GetEntDataFloat(client,m_vecVelocity_1);
			velocity[0]*=SkillLongJump[skilllevel]*0.25;
			velocity[1]*=SkillLongJump[skilllevel]*0.25;
			SetEntDataVector(client,m_vecBaseVelocity,velocity,true);
		}
	}
}

public OnPluginStart()
{
	HookEvent("player_jump",PlayerJumpEvent);
	HookEvent("round_start", Event_RoundStart);
	m_vecVelocity_0 = FindSendPropOffs("CBasePlayer","m_vecVelocity[0]");
	m_vecVelocity_1 = FindSendPropOffs("CBasePlayer","m_vecVelocity[1]");
	m_vecBaseVelocity = FindSendPropOffs("CBasePlayer","m_vecBaseVelocity");
/* *************************************** (SKILL_AGENTS) *************************************** */
	CreateTimer(0.1,Aura,_,TIMER_REPEAT);
}

public Action:Aura(Handle:timer,any:userid)
{
	for(new client=1;client<=MaxClients;client++)
	{
		if(ValidPlayer(client,true))
		{
			if(War3_GetRace(client)==thisRaceID)
			{
				new AgentLevel=War3_GetSkillLevel(client,thisRaceID,SKILL_AGENTS);

				if(AgentLevel>0)
				{
					new Float:iPos[3];
					new Float:clientPos[3];
					GetClientAbsOrigin(client,clientPos);
					for (new i=1;i<=MaxClients;i++)
					{
						if(ValidPlayer(i,true))
						{
							GetClientAbsOrigin(i,iPos);
							if(GetVectorDistance(clientPos,iPos)<=AgentRange[AgentLevel] && i != client)
							{
								if(GetClientTeam(i)==3)
								{
									iPos[2]+=15.0;
									TE_SetupBeamRingPoint(iPos,45.0,44.0,BeamSprite,HaloSprite,0,15,0.1,1.0,0.0,{0,0,255,255},10,0);
									TE_SendToClient(client);
								}
								else if(GetClientTeam(i)==2)
								{
									iPos[2]+=15.0;
									TE_SetupBeamRingPoint(iPos,45.0,44.0,BeamSprite,HaloSprite,0,15,0.1,1.0,0.0,{255,0,0,255},10,0);
									TE_SendToClient(client);
								}
							}
						}
					}
				}
			}
		}
	}
}

/* *************************************** (SKILL_MOTION) *************************************** */
public OnAbilityCommand(client,ability,bool:pressed)
{
    if(War3_GetRace(client)==thisRaceID &&  pressed && IsPlayerAlive(client))
    {
        new MotionLevel = War3_GetSkillLevel(client,thisRaceID,SKILL_MOTION);
        if(MotionLevel > 0)
        {
			if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_MOTION,true))
			{
				PrintHintText(client,"You go into slow motion mode");
				CreateTimer(MotionDur[MotionLevel],EndMotion,client);
				War3_SetBuff(client,fSlow,thisRaceID,MotionSlow[MotionLevel]);
				War3_SetBuff(client,fAttackSpeed,thisRaceID,MotionSlow[MotionLevel]);
				War3_CooldownMGR(client,(MotionDur[MotionLevel]+30.0),thisRaceID,SKILL_MOTION,_,_);
				bSlowed[client]=true;
				new Float:clientPos[3];
				new Float:iPos[3];
				new ownerteam=GetClientTeam(client);
				GetClientAbsOrigin(client,clientPos);
				
				for (new i=1;i<=MaxClients;i++)
				{
					if(ValidPlayer(i,true)&&GetClientTeam(i)!=ownerteam && !W3HasImmunity(i,Immunity_Skills))
					{
						GetClientAbsOrigin(i,iPos);
						if(GetVectorDistance(clientPos,iPos)<=MotionRange[MotionLevel])
						{
							War3_SetBuff(i,fSlow,thisRaceID,MotionSlow[MotionLevel]);
							War3_SetBuff(i,fAttackSpeed,thisRaceID,MotionSlow[MotionLevel]);
							bSlowed[i]=true;
						}
					}
				}
			}
		}
		else
			PrintHintText(client,"Level your Slow Motion first");
	}
}

public Action:EndMotion(Handle:timer,any:client)
{
	if(ValidPlayer(client)&&War3_GetRace(client)==thisRaceID)
	{
		PrintHintText(client,"Slow Motion is finished");
		for (new i=1;i<=MaxClients;i++)
		{
			if(bSlowed[i])
			{
				W3ResetBuffRace(i,fSlow,thisRaceID);
				W3ResetBuffRace(i,fAttackSpeed,thisRaceID);
				bSlowed[i]=false;
			}
		}
	}		
}

/* *************************************** (ULT_CODE) *************************************** */
public OnWar3EventDeath(victim,attacker)
{
	if(bCoded[attacker] || bCoded[victim])
	{
		if(bCoded[attacker])
		{
			bCoded[attacker]=false;
			PrintHintText(attacker,"You stopped Neo from altering your code");
		}
		else if(bCoded[victim])
		{
			bCoded[victim]=false;
			new NeoSpawn = bCodeOwner[victim];
			if(ValidPlayer(NeoSpawn) && War3_GetRace(NeoSpawn)==thisRaceID && !IsPlayerAlive(NeoSpawn))
			{
				War3_ChatMessage(NeoSpawn , "You altered the code of your killer.  Prepare to respawn");
				CodeKilled[NeoSpawn]=victim;
				CreateTimer(1.0,RespawnPlayer,NeoSpawn);
			}
		}
	}
	else
	{
		if(War3_GetRace(victim)==thisRaceID)
		{
			new CodeLevel = War3_GetSkillLevel(victim,thisRaceID,ULT_CODE);
			if(CodeLevel > 0 && !bCodeUsed[victim] && GetClientTeam(attacker)!=GetClientTeam(victim) && victim!=attacker && !bCoded[attacker])
			{
				if(!W3HasImmunity(attacker,Immunity_Ultimates))
				{
					if(W3Chance(CodeChance[CodeLevel]))
					{
						bCodeUsed[victim]=true;
						bCodeOwner[attacker]=victim;
						bCoded[attacker]=true;
						PrintHintText(attacker,"Neo is altering your code.  Kill someone to save yourself");
						
						CreateTimer(1.0,CodeLoop,attacker);
						War3_ChatMessage(victim , "You're altering the code of your killer");
					}
				}
			}
		}
	}
}

public Action:CodeLoop(Handle:timer, any:attacker)
{
	new Neo=bCodeOwner[attacker];
	if(ValidPlayer(attacker) && bCoded[attacker])
	{
		War3_DealDamage(attacker,4,Neo,DMG_CRUSH,"altered code",_,W3DMGTYPE_MAGIC);
		CreateTimer(1.0,CodeLoop,attacker);
	}
}


public Action:RespawnPlayer(Handle:timer,any:client)
{
	if(client>0 && !IsPlayerAlive(client) && ValidPlayer(CodeKilled[client]))
	{
		new Float:pos[3];
		new Float:ang[3];
		War3_CachedAngle(CodeKilled[client],ang);
		War3_CachedPosition(CodeKilled[client],pos);
		War3_SpawnPlayer(client);
		TeleportEntity(client,pos,ang,NULL_VECTOR);
	}
}

public Event_RoundStart( Handle:event, const String:name[], bool:dontBroadcast )
{
	for (new i=1;i<=MaxClients;i++)
	{
		if(ValidPlayer(i))
		{
			bCodeUsed[i]=false;
			bCoded[i]=false;
		}
	}
}








