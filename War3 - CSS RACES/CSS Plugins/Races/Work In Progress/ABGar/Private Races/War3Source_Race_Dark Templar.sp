#pragma semicolon 1
 
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdkhooks>

public Plugin:myinfo = 
{
	name = "War3Source Race - Dark Templar",
	author = "ABGar",
	description = "The Dark Templar race for War3Source.",
	version = "1.0",
	// Kanon's Private Race Request - http://www.sevensinsgaming.com/forum/index.php?/topic/5265-dark-templar-private/?hl=%2Bdark+%2Btemplar
}

new thisRaceID;

new SKILL_CLOAK, SKILL_BLADE, SKILL_SPEED, ULT_FURY;

// SKILL_CLOAK
new Float:RunInvis[]={1.0,0.9,0.8,0.7,0.6};
new bool:bRunning[MAXPLAYERS];
new bool:bWalking[MAXPLAYERS];
new Float:CanInvisTime[MAXPLAYERS];

// SKILL_BLADE
new Float:BladeDamage[]={0.0,0.3,0.45,0.6,0.75};

// SKILL_SPEED
new Float:RunSpeed[]={1.0,1.1,1.2,1.3,1.4};

// ULT_FURY
new HaloSprite, Ult_BeamSprite1, Ult_BeamSprite2;
new BestTarget[MAXPLAYERSCUSTOM];
new Handle:g_hFuryTimer[MAXPLAYERSCUSTOM];
new Handle:g_hFurySwapBack[MAXPLAYERSCUSTOM];
new Float:ClientPos[MAXPLAYERSCUSTOM][3];
new Float:TargetPos[MAXPLAYERSCUSTOM][3];
new Float:SwapBackTime[]={0.0,10.0,9.0,8.0,7.0};
new String:FurySound[]="ambient/atmosphere/cave_hit5.wav";
new String:FurySound2[]="npc/antlion/distract1.wav";


public OnWar3PluginReady()
{
	thisRaceID=War3_CreateNewRace("Dark Templar [PRIVATE]","darktemplar");
	SKILL_CLOAK = War3_AddRaceSkill(thisRaceID,"Permanent Cloaking","Reduces invisibility while running, even more when walking.  \nCompletely invis when standing still (passive)",false,4);
	SKILL_BLADE = War3_AddRaceSkill(thisRaceID,"Warp Blade","Extra damage on every attack, depending on your invisibility level (attack)",false,4);
	SKILL_SPEED = War3_AddRaceSkill(thisRaceID,"Speed","Extra speed (passive)",false,4);
	ULT_FURY=War3_AddRaceSkill(thisRaceID,"Shadow Fury","Swap location with an enemy, then after 7,6,5,4 seconds, you go back to your original place (+ultimate)",false,4);
	War3_CreateRaceEnd(thisRaceID);
	War3_AddSkillBuff(thisRaceID,SKILL_SPEED,fMaxSpeed,RunSpeed);
	War3_AddSkillBuff(thisRaceID,SKILL_CLOAK,fInvisibilitySkill,RunInvis);
	W3SkillCooldownOnSpawn(thisRaceID,ULT_FURY,10.0,_);
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
	War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife");
}

public OnPluginStart()
{
	CreateTimer(0.1,CalcVis,_,TIMER_REPEAT);
}

public OnMapStart()
{
	HaloSprite = PrecacheModel("materials/sprites/halo01.vmt");
	Ult_BeamSprite1 = PrecacheModel("materials/effects/ar2_altfire1.vmt");
	Ult_BeamSprite2 = PrecacheModel("models/alyx/pupil_r.vmt");
	War3_PrecacheSound(FurySound);
	War3_PrecacheSound(FurySound2);
}


/* ********************************** (SKILL_CLOAK / SKILL_BLADE) ********************************** */
public Action:CalcVis(Handle:timer,any:userid)
{
	for(new i=1;i<MaxClients;i++)
	{
		if(ValidPlayer(i) && War3_GetRace(i)==thisRaceID)
		{
			new CloakLevel = War3_GetSkillLevel(i,thisRaceID,SKILL_CLOAK);
			new BladeLevel = War3_GetSkillLevel(i,thisRaceID,SKILL_BLADE);
			if(CloakLevel>0)
			{
				if(bRunning[i])
				{
					War3_SetBuff(i,fInvisibilitySkill,thisRaceID,RunInvis[CloakLevel]);
					War3_SetBuff(i,fDamageModifier,thisRaceID,BladeDamage[BladeLevel]);
					CanInvisTime[i]=GetGameTime() + 2.0;
				}
				else if(bWalking[i])
				{
					War3_SetBuff(i,fDamageModifier,thisRaceID,(BladeDamage[BladeLevel]/2));
					CanInvisTime[i]=GetGameTime() + 2.0;
					new Float:CurrentInvis=W3GetBuffMinFloat(i,fInvisibilitySkill);
					if(CurrentInvis>0.25)
						War3_SetBuff(i,fInvisibilitySkill,thisRaceID,(CurrentInvis-0.01));
					else
						War3_SetBuff(i,fInvisibilitySkill,thisRaceID,0.25);					
				}
				else
				{
					if(CanInvisTime[i]<GetGameTime())
					{
						War3_SetBuff(i,fInvisibilitySkill,thisRaceID,0.00);
						War3_SetBuff(i,fDamageModifier,thisRaceID,0.0);
					}
				}
			}
		}
	}
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(ValidPlayer(client)&&War3_GetRace(client)==thisRaceID)
	{
		bRunning[client]=(buttons & (IN_FORWARD | IN_BACK | IN_MOVELEFT | IN_MOVERIGHT)) &&  (!(buttons & IN_SPEED | buttons & IN_DUCK))?true:false;
		bWalking[client]=(buttons & (IN_FORWARD | IN_BACK | IN_MOVELEFT | IN_MOVERIGHT)) && (buttons & IN_SPEED | buttons & IN_DUCK)?true:false;
	}
	return Plugin_Continue;
}

/* *************************************** (ULT_FURY) *************************************** */
public OnUltimateCommand(client,race,bool:pressed)
{
	if(ValidPlayer(client,true) && race==thisRaceID && pressed)
	{
		new FuryLevel=War3_GetSkillLevel(client,thisRaceID,ULT_FURY);
		if(FuryLevel>0)
		{
			if(SkillAvailable(client,thisRaceID,ULT_FURY,true,true,true))
			{
				Trade(client);
				War3_CooldownMGR(client,35.0,thisRaceID,ULT_FURY);
			}
		}
		else
			W3MsgUltNotLeveled(client);
	}
}


stock Trade(client)
{
	new iEnemyTeam = (GetClientTeam(client)==TEAM_T) ? TEAM_CT : TEAM_T;
	BestTarget[client] = W3GetRandomPlayer(iEnemyTeam,true,Immunity_Ultimates);
	
	if(BestTarget[client]==0)
		W3MsgNoTargetFound(client);
	else
	{
		new FuryLevel=War3_GetSkillLevel(client,thisRaceID,ULT_FURY);
		GetClientAbsOrigin(BestTarget[client],TargetPos[client]);
		GetClientAbsOrigin(client,ClientPos[client]);
		EmitSoundToAll(FurySound,client);
		EmitSoundToAll(FurySound, BestTarget[client]);
		PrintToChat(client,"\x05: \x03You will trade places with \x04%N \x03in three seconds!",BestTarget[client]);

		g_hFuryTimer[client] = CreateTimer(3.0,TradeDelay,client);
		g_hFurySwapBack[client] = CreateTimer(SwapBackTime[FuryLevel],SwapBack,client);

		new Float:BeamPos[3];
		BeamPos[0] = ClientPos[client][0];
		BeamPos[1] = ClientPos[client][1];
		BeamPos[2] = ClientPos[client][2] + 40.0;

		TE_SetupBeamRingPoint( BeamPos, 950.0, 190.0, Ult_BeamSprite1, HaloSprite, 0, 0, 3.0, 150.0, 0.0, { 115, 115, 100, 200 }, 1, FBEAM_ISACTIVE );
		TE_SendToAll();
		TE_SetupBeamRingPoint( BeamPos, 950.0, 190.0, Ult_BeamSprite2, HaloSprite, 0, 0, 3.0, 150.0, 0.0, { 115, 115, 100, 200 }, 1, FBEAM_ISACTIVE );
		TE_SendToAll();
	}
}


public Action:TradeDelay( Handle:timer, any:client )
{
	new FuryLevel=War3_GetSkillLevel(client,thisRaceID,ULT_FURY);
	if(g_hFuryTimer[client]!= INVALID_HANDLE)
		g_hFuryTimer[client] = INVALID_HANDLE;
	if(ValidPlayer(client,true) && ValidPlayer(BestTarget[client],true))
	{
		TeleportEntity(BestTarget[client],ClientPos[client],NULL_VECTOR,NULL_VECTOR);
		TeleportEntity(client,TargetPos[client],NULL_VECTOR,NULL_VECTOR);
		new seconds=(RoundToZero(SwapBackTime[FuryLevel])-3);
		PrintHintText(client,"You will teleport back in %i seconds",seconds);
	}
}

public Action:SwapBack( Handle:timer, any:client )
{
    if(g_hFurySwapBack[client]!= INVALID_HANDLE)
        g_hFurySwapBack[client] = INVALID_HANDLE;
    if(ValidPlayer(client,true))
    {
		EmitSoundToAll(FurySound2,client);
		TeleportEntity(client,ClientPos[client],NULL_VECTOR,NULL_VECTOR);
    }
}


public RoundOverEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	for(new i=1;i<=MaxClients;i++)
	{
		if(ValidPlayer(i) && (War3_GetRace(i)==thisRaceID))
		{
			if(g_hFuryTimer[i]!= INVALID_HANDLE)
			{
				KillTimer(g_hFuryTimer[i]);
				g_hFuryTimer[i] = INVALID_HANDLE;
			}
			if(g_hFurySwapBack[i]!= INVALID_HANDLE)
			{
				KillTimer(g_hFurySwapBack[i]);
				g_hFurySwapBack[i] = INVALID_HANDLE;
			}
		}
	}
}

public RoundStartEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	for(new i=1;i<=MaxClients;i++)
	{
		if(ValidPlayer(i) && (War3_GetRace(i)==thisRaceID))
		{
			if(g_hFuryTimer[i]!= INVALID_HANDLE)
			{
				KillTimer(g_hFuryTimer[i]);
				g_hFuryTimer[i] = INVALID_HANDLE;
			}
			if(g_hFurySwapBack[i]!= INVALID_HANDLE)
			{
				KillTimer(g_hFurySwapBack[i]);
				g_hFurySwapBack[i] = INVALID_HANDLE;
			}
		}
	}
}