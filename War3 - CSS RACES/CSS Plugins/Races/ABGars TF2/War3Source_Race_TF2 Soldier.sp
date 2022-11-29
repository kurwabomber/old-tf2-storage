#pragma semicolon 1
 
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdkhooks>

public Plugin:myinfo = 
{
	name = "War3Source Race - TF2 Soldier",
	author = "ABGar",
	description = "The TF2 Soldier race for War3Source.",
	version = "1.0",
}

new thisRaceID;

new SKILL_LAUNCHER, SKILL_JUMP, SKILL_GARDENER, ULT_BUFF;

// SKILL_LAUNCHER
new g_iExplosionModel;
new LauncherDamage[]={0,4,6,8,10};
new Float:LauncherRadius[]={0.0,50.0,70.0,90.0,100.0};
new Float:LauncherAttackSpeed[]={1.0,0.9,0.8,0.75,0.7};
new String:LauncherSound[]={"weapons/ar2/ar2_altfire.wav"};

// SKILL_JUMP
new m_vecBaseVelocity;
new JumpExplodeDamage=30;
new Float:JumpExplodeRange=300.0;
new Float:JumpCD=15.0;
new Float:PushForce[]={0.0,0.4,0.6,0.75,1.0};
new bool:bInJump[MAXPLAYERSCUSTOM];
new String:JumpSound[]={"weapons/explode5.wav"};

// SKILL_GARDENER
new String:CritStrike[]={"npc/roller/mine/rmine_blades_out2.wav"};
new Float:GardenerDamage[]={1.0,1.3,1.6,1.9,2.1};

// ULT_BUFF
new Float:BuffRange[]={0.0,200.0,250.0,300.0,350.0};
new Float:BuffSpeed[]={1.0,1.05,1.1,1.15,1.2};
new Float:BuffHPRegen[]={0.0,1.0,2.0,3.0,4.0};


public OnWar3PluginReady()
{
	thisRaceID=War3_CreateNewRace("TF2 Soldier","tf2soldier");
	SKILL_LAUNCHER = War3_AddRaceSkill(thisRaceID,"Rocket launcher","Deagle shot explode on hit dealing AoE DMG (attack)",false,4);
	SKILL_JUMP = War3_AddRaceSkill(thisRaceID,"Rocket Jump","Shoot a rocket at your feet and blast yourself forwards (+ability)",false,4);
	SKILL_GARDENER = War3_AddRaceSkill(thisRaceID,"Market Gardener","Gain bonus DMG with knife when mid-air after a rocket jump (passive)",false,4);
	ULT_BUFF=War3_AddRaceSkill(thisRaceID,"Buff Banner","Nearby allys gain health regen and bonus movement speed (passive ultimate)",true,4);
	War3_CreateRaceEnd(thisRaceID);
	War3_AddSkillBuff(thisRaceID,SKILL_LAUNCHER,fAttackSpeed,LauncherAttackSpeed);
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
	War3_WeaponRestrictTo(client,thisRaceID,"weapon_deagle,weapon_knife");
	DropSecWeapon(client);
	GivePlayerItem(client,"weapon_deagle");
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

public OnPluginStart() 
{ 
	HookEvent("bullet_impact",BulletImpact);
	CreateTimer(1.0,Aura,_,TIMER_REPEAT);
} 

public OnMapStart()
{
	War3_PrecacheSound(CritStrike);
	War3_PrecacheSound(LauncherSound);
	War3_PrecacheSound(JumpSound);
	g_iExplosionModel = PrecacheModel("materials/effects/fire_cloud1.vmt");
	m_vecBaseVelocity = FindSendPropOffs("CBasePlayer","m_vecBaseVelocity");
}

/* *************************************** (SKILL_LAUNCHER) *************************************** */
public BulletImpact(Handle:event,const String:name[],bool:dontBroadcast)
{
	new Float:Origin[3];
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	Origin[0] = GetEventFloat(event,"x");
	Origin[1] = GetEventFloat(event,"y");
	Origin[2] = GetEventFloat(event,"z");
	if(War3_GetRace(client)==thisRaceID && ValidPlayer(client,true))
	{
		new LauncherLevel=War3_GetSkillLevel(client,thisRaceID,SKILL_LAUNCHER);
		if(LauncherLevel>0)
		{
			TE_SetupExplosion(Origin, g_iExplosionModel, 50.0, 10, TE_EXPLFLAG_NONE, 200, 255);
			TE_SendToAll();
			EmitSoundToAll(LauncherSound,client);
			for (new i=1;i<=MaxClients;i++)
			{
				if(ValidPlayer(i,true)&& GetClientTeam(i)!= GetClientTeam(client))
				{
					new Float:VictimPos[3];
					GetClientAbsOrigin(i,VictimPos);
					VictimPos[2]+=25.0;
					if(GetVectorDistance(Origin,VictimPos)<LauncherRadius[LauncherLevel])
					{
						if(SkillFilter(i))
						{
							War3_DealDamage(i,LauncherDamage[LauncherLevel],client,DMG_BLAST,"rocket launcher",_,W3DMGTYPE_MAGIC);
						}
					}
				}
			}
		}
	}
}
/* *************************************** (SKILL_JUMP) *************************************** */
public OnAbilityCommand(client,ability,bool:pressed)
{
	if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && ValidPlayer(client,true))
	{
		new JumpLevel=War3_GetSkillLevel(client,thisRaceID,SKILL_JUMP);
		if(JumpLevel>0)
		{
			if(SkillAvailable(client,thisRaceID,SKILL_JUMP,true,true,true))
			{
				War3_CooldownMGR(client,JumpCD,thisRaceID,SKILL_JUMP,true,true);
				TeleportPlayer(client);
			}
		}
		else
			PrintHintText(client,"Level your skill first");
	}
}

stock TeleportPlayer(client)
{
	if(client>0 && ValidPlayer(client,true))
	{
		new JumpLevel = War3_GetSkillLevel(client,thisRaceID,SKILL_JUMP);
		War3_SetBuff(client,fLowGravitySkill,thisRaceID,0.6);
		bInJump[client]=true;
		new Float:startpos[3];
		new Float:endpos[3];
		new Float:localvector[3];
		new Float:velocity[3];
		
		GetClientAbsOrigin(client,startpos);
		War3_GetAimEndPoint(client,endpos);
		
		TE_SetupExplosion(startpos, g_iExplosionModel, 50.0, 10, TE_EXPLFLAG_NONE, 200, 255);
		TE_SendToAll();
		TE_SetupSmoke(startpos, g_iExplosionModel, 25.0, 2);
		TE_SendToAll();
		EmitSoundToAll(JumpSound,client);
		for (new i=1;i<=MaxClients;i++)
		{
			if(ValidPlayer(i,true)&& GetClientTeam(i)!= GetClientTeam(client))
			{
				new Float:VictimPos[3];
				GetClientAbsOrigin(i,VictimPos);
				VictimPos[2]+=25.0;
				if(GetVectorDistance(startpos,VictimPos)<JumpExplodeRange)
				{
					if(SkillFilter(i))
					{
						War3_DealDamage(i,JumpExplodeDamage,client,DMG_BLAST,"rocket jump",_,W3DMGTYPE_MAGIC);
					}
				}
			}
		}
		
		localvector[0] = endpos[0] - startpos[0];
		localvector[1] = endpos[1] - startpos[1];
		localvector[2] = endpos[2] - startpos[2];
		
		velocity[0] = localvector[0] * PushForce[JumpLevel];
		velocity[1] = localvector[1] * PushForce[JumpLevel];
		velocity[2] = localvector[2] * PushForce[JumpLevel];
		
		SetEntDataVector(client,m_vecBaseVelocity,velocity,true);
	}
}

public OnGameFrame() 
{
	for (new i = 1; i <= MaxClients; i++) 
	{
		if (War3_GetRace(i)==thisRaceID && ValidPlayer(i,true))
		{
			if(GetEntityFlags(i) & FL_ONGROUND)
			{
				W3ResetBuffRace(i,fLowGravitySkill,thisRaceID);
				bInJump[i]=false;
			}
		}
	}
}

/* *************************************** (SKILL_GARDENER) *************************************** */
public OnW3TakeDmgBulletPre(victim,attacker,Float:damage)
{
	if(ValidPlayer(victim) && ValidPlayer(attacker) && GetClientTeam(attacker)!=GetClientTeam(victim))
	{
		if(War3_GetRace(attacker)==thisRaceID)
		{
			new GardenerLevel = War3_GetSkillLevel(attacker,thisRaceID,SKILL_GARDENER);
			if(GardenerLevel>0 && bInJump[attacker])
			{
				War3_DamageModPercent(GardenerDamage[GardenerLevel]);
				EmitSoundToAll(CritStrike,attacker);
				W3FlashScreen(attacker,RGBA_COLOR_RED);
			}
		}
	}
}
/* *************************************** (ULT_BUFF) *************************************** */
public Action:Aura(Handle:timer,any:userid)
{
	for(new client=1;client<=MaxClients;client++)
	{
		if(ValidPlayer(client,true))
		{
			if(War3_GetRace(client)==thisRaceID)
			{
				new BuffLevel=War3_GetSkillLevel(client,thisRaceID,ULT_BUFF);
				new Float:allyPos[3];
				new Float:clientPos[3];
				GetClientAbsOrigin(client,clientPos);
				if(BuffLevel>0)
				{
					for (new ally=1;ally<=MaxClients;ally++)
					{
						if(ValidPlayer(ally,true)&& GetClientTeam(ally)==GetClientTeam(client))
						{
							GetClientAbsOrigin(ally,allyPos);
							if(GetVectorDistance(clientPos,allyPos)<=BuffRange[BuffLevel])
							{
								War3_SetBuff(ally,fMaxSpeed,thisRaceID,BuffSpeed[BuffLevel]);
								War3_SetBuff(ally,fHPRegen,thisRaceID,BuffHPRegen[BuffLevel]);
							}
							else
							{
								W3ResetAllBuffRace(ally,thisRaceID);
							}
						}
					}
				}
			}
		}
	}
}
