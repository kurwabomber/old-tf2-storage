#pragma semicolon 1
 
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdkhooks>

public Plugin:myinfo = 
{
	name = "War3Source Race - TF2 Scout",
	author = "ABGar",
	description = "The TF2 Scout race for War3Source.",
	version = "1.0",
}

new thisRaceID;

new SKILL_SCOUT, SKILL_WINGER, SKILL_SAND, ULT_BONK;

// SKILL_SCOUT
new Float:ScoutSpeed[]={1.0,1.05,1.1,1.15,1.2};
new ScoutHealth[]={0,-5,-10,-15,-20};

// SKILL_WINGER
new Float:ScoutGrav[]={1.0,0.9,0.8,0.7,0.6};
new g_fLastButtons[MAXPLAYERS+1];
new g_fLastFlags[MAXPLAYERS+1];
new g_iJumps[MAXPLAYERS+1];
new g_iJumpMax = 1;

// SKILL_SAND
new BeamSprite,HaloSprite;
new Float:SandRange=500.0;
new Float:SandCD=20.0;
new Float:SandDuration[]={0.0,0.5,1.0,1.5,2.0};

// ULT_BONK
new BlueSprite;
new bool:bInBonk[MAXPLAYERSCUSTOM];
new Float:BonkDelay=2.0;
new Float:BonkSpeed[]={1.0,1.4,1.5,1.6,1.7};
new Float:BonkDuration[]={0.0,3.0,5.0,7.0,8.0};
new Float:BonkCD[]={0.0,30.0,25.0,20.0,15.0};

new String:BonkSound[]="ambient/explosions/explode_7.wav";
new String:BonkEndSound[]="ambient/levels/prison/radio_random7.wav";

public OnWar3PluginReady()
{
	thisRaceID=War3_CreateNewRace("TF2 Scout","tf2scout");
	SKILL_SCOUT = War3_AddRaceSkill(thisRaceID,"The scout","Lowers max health but gains bonus movement speed (passive)",false,4);
	SKILL_WINGER = War3_AddRaceSkill(thisRaceID,"The winger","Scout gains a second jump and lower gravity (passive)",false,4);
	SKILL_SAND = War3_AddRaceSkill(thisRaceID,"The sand man","Scout launches a ball at his opponent and stuns them (+ability)",false,4);
	ULT_BONK=War3_AddRaceSkill(thisRaceID,"Bonk atomic punch","After a 2s stun, Scout gains bonus movement speed and invulnerability (+ultimate)",true,4);
	War3_CreateRaceEnd(thisRaceID);
	W3SkillCooldownOnSpawn(thisRaceID,SKILL_SAND,15.0,_);
	War3_AddSkillBuff(thisRaceID,SKILL_SCOUT,fMaxSpeed,ScoutSpeed);
	War3_AddSkillBuff(thisRaceID,SKILL_SCOUT,iAdditionalMaxHealth,ScoutHealth);
	War3_AddSkillBuff(thisRaceID,SKILL_WINGER,fLowGravitySkill,ScoutGrav);
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
	bInBonk[client]=false;
	DropSecWeapon(client);
	War3_WeaponRestrictTo(client,thisRaceID,"weapon_m3,weapon_knife");
	GivePlayerItem(client,"weapon_m3");
	W3ResetPlayerColor(client, thisRaceID);
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
	BeamSprite=PrecacheModel("materials/sprites/lgtning.vmt");
	HaloSprite=PrecacheModel("materials/sprites/halo01.vmt");
	BlueSprite=PrecacheModel("materials/sprites/physcannon_bluecore2b.vmt");
	War3_PrecacheSound(BonkSound);
	War3_PrecacheSound(BonkEndSound);
}
/* *************************************** (SKILL_WINGER) *************************************** */
public OnGameFrame() 
{
	for (new i = 1; i <= MaxClients; i++) 
	{
		if (War3_GetRace(i)==thisRaceID && ValidPlayer(i,true))
		{
			new WingerLevel = War3_GetSkillLevel(i,thisRaceID,SKILL_WINGER);
			if(WingerLevel > 0)
				DoubleJump(i);
		}
	}
}

stock DoubleJump(const any:client) 
{
	if (g_fLastFlags[client] & FL_ONGROUND)
	{
		if(!(GetEntityFlags(client) & FL_ONGROUND) && !(g_fLastButtons[client] & IN_JUMP) && GetClientButtons(client) & IN_JUMP)
			g_iJumps[client]++;
	}

	else if(GetEntityFlags(client) & FL_ONGROUND)  // STANDING ON THE GROUND - HAS NOT JUMPED
		g_iJumps[client] = 0;

	else if(!(g_fLastButtons[client] & IN_JUMP) && GetClientButtons(client) & IN_JUMP) // IN THE AIR - CALL JUMP AGAIN
		ReJump(client);
		
	g_fLastFlags[client]	= GetEntityFlags(client);
	g_fLastButtons[client]	= GetClientButtons(client);
}

stock ReJump(const any:client) 
{
	if ( 1 <= g_iJumps[client] <= g_iJumpMax) 
	{
		g_iJumps[client]++;
		new Float:JumpVelocity[3];
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", JumpVelocity);
		
		JumpVelocity[2] = 300.0;
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, JumpVelocity);
	}
}

/* *************************************** (SKILL_SAND) *************************************** */
public OnAbilityCommand(client,ability,bool:pressed)
{
	if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && ValidPlayer(client,true))
	{
		new SandLevel=War3_GetSkillLevel(client,thisRaceID,SKILL_SAND);
		if(SandLevel>0)
		{
			if(SkillAvailable(client,thisRaceID,SKILL_SAND,true,true,true))
			{
				new target = War3_GetTargetInViewCone(client,SandRange,false,23.0);
				if(target>0 && SkillFilter(target))
				{
					War3_CooldownMGR(client,SandCD,thisRaceID,SKILL_SAND,true,true);
					War3_SetBuff(target,bStunned,thisRaceID,true);
					CreateTimer(SandDuration[SandLevel],StopStun,target);
					
					new Float:targetPos[3], Float:clientPos[3];
					GetClientAbsOrigin(client, clientPos);
					GetClientAbsOrigin(target, targetPos);
					targetPos[2]+=35;
					clientPos[2]+=35;
					TE_SetupBeamPoints(targetPos,clientPos,BeamSprite,HaloSprite,0,35,0.5,6.0,5.0,0,1.0,{155,000,255,255},20);
					TE_SendToAll();
				}
				else
					W3MsgNoTargetFound(client);
			}
		}
		else
			PrintHintText(client,"Level your skill first");
	}
}

public Action:StopStun(Handle:timer,any:client)
{
	War3_SetBuff(client,bStunned,thisRaceID,false);
}

/* *************************************** (ULT_BONK) *************************************** */
public OnUltimateCommand(client,race,bool:pressed)
{
	if(ValidPlayer(client,true) && race==thisRaceID && pressed)
	{
		new BonkLevel=War3_GetSkillLevel(client,thisRaceID,ULT_BONK);
		if(BonkLevel>0)
		{
			if(SkillAvailable(client,thisRaceID,ULT_BONK,true,true,true))
			{
				War3_CooldownMGR(client,(BonkCD[BonkLevel]+BonkDuration[BonkLevel]+BonkDelay),thisRaceID,ULT_BONK,true,true);
				War3_SetBuff(client,bStunned,thisRaceID,true);
				CreateTimer(BonkDelay,StartBonk,client);
				new Float:clientPos[3];
				clientPos[2]+=35;
				GetClientAbsOrigin(client,clientPos);
				TE_SetupGlowSprite(clientPos, BlueSprite, 2.0, 1.0, 255);
				TE_SendToAll();
			}
		}
		else
			W3MsgUltNotLeveled(client);
	}
}


public Action:StartBonk(Handle:timer,any:client)
{
	if(ValidPlayer(client))
	{
		new BonkLevel=War3_GetSkillLevel(client,thisRaceID,ULT_BONK);
		bInBonk[client]=true;
		W3SetPlayerColor(client,thisRaceID,10,10,255,_,GLOW_ULTIMATE)
		War3_SetBuff(client,bStunned,thisRaceID,false);
		War3_SetBuff(client,fMaxSpeed,thisRaceID,BonkSpeed[BonkLevel]);
		CreateTimer(BonkDuration[BonkLevel],StopBonk,client);
		EmitSoundToAll(BonkSound,client);
	}
}

public Action:StopBonk(Handle:timer,any:client)
{
	if(ValidPlayer(client))
	{
		new ScoutLevel=War3_GetSkillLevel(client,thisRaceID,SKILL_SCOUT);
		War3_SetBuff(client,fMaxSpeed,thisRaceID,ScoutSpeed[ScoutLevel]);
		bInBonk[client]=false;
		W3ResetPlayerColor(client, thisRaceID);
		PrintHintText(client,"You're no longer invulnerable");
		EmitSoundToAll(BonkEndSound,client);
	}
}

public OnW3TakeDmgBulletPre(victim,attacker,Float:damage)
{
	if(ValidPlayer(victim, true) && ValidPlayer(attacker) && GetClientTeam(attacker)!=GetClientTeam(victim))
	{
		if(War3_GetRace(victim)==thisRaceID)
		{
			if(bInBonk[victim] && UltFilter(attacker))
				War3_DamageModPercent(0.0);
		}
	}
}
