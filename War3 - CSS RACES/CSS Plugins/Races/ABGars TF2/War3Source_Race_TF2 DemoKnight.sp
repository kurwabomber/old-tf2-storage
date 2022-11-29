#pragma semicolon 1
 
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdkhooks>
#include <smlib>

public Plugin:myinfo = 
{
	name = "War3Source Race - TF2 DemoKnight",
	author = "ABGar",
	description = "The TF2 DemoKnight race for War3Source.",
	version = "1.0",
}

new thisRaceID;

new SKILL_CURSE, SKILL_CHARGE, SKILL_SCREEN, ULT_VEST;

// SKILL_CURSE
new KillCount[MAXPLAYERSCUSTOM];
new Float:SpeedMultiplier[]={0.0,0.0125,0.015,0.0175,0.02};
new HealthMultiplier[]={0,1,2,3,4};

// SKILL_CHARGE
new Float:ChargeDuration=3.0;
new Float:ChargeCD[]={0.0,30.0,27.0,24.0,21.0,18.0};
new Float:ChargeSpeed[]={0.0,0.4,0.6,0.8,1.0};
new String:ChargeSound[]="ambient/explosions/explode_7.wav";

// SKILL_SCREEN
new Float:ScreenKnifeDamage[]={1.0,1.1,1.2,1.3,1.4};
new Float:ScreenOtherDamage[]={1.0,0.95,0.9,0.85,0.8};

// ULT_VEST
new VestNadeCount[]={0,3,4,5,6};
new Float:NadeDistance=150.0;

public OnWar3PluginReady()
{
	thisRaceID=War3_CreateNewRace("TF2 DemoKnight","tf2knight");
	SKILL_CURSE = War3_AddRaceSkill(thisRaceID,"Eyelanders curse","The more heads you take the stronger you become (passive)",false,4);
	SKILL_CHARGE = War3_AddRaceSkill(thisRaceID,"Demo charge","Charge forwards (+ability)",false,4);
	SKILL_SCREEN = War3_AddRaceSkill(thisRaceID,"Splendid screen","Take less bullet damage but take and deal more knife damage (passive)",false,4);
	ULT_VEST=War3_AddRaceSkill(thisRaceID,"Grenade vest","On death drop grenades (passive ultimate)",true,4);
	War3_CreateRaceEnd(thisRaceID);
	W3SkillCooldownOnSpawn(thisRaceID,SKILL_CHARGE,10.0,_);
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
	AddSpeedBuff(client);
	AddHealthBuff(client);
}

public OnMapStart()
{
	War3_PrecacheSound(ChargeSound);
	for(new client=1;client<=MaxClients;client++)
	{
		KillCount[client]=0;
	}
}

public AddSpeedBuff(client)
{
	new CurseLevel=War3_GetSkillLevel(client,thisRaceID,SKILL_CURSE);
	if(CurseLevel>0)
	{
		new Float:SpeedBuff=1+(SpeedMultiplier[CurseLevel]*KillCount[client]);
		War3_SetBuff(client,fMaxSpeed,thisRaceID,SpeedBuff);
	}
}

public AddHealthBuff(client)
{
	new CurseLevel=War3_GetSkillLevel(client,thisRaceID,SKILL_CURSE);
	if(CurseLevel>0)
	{
		new HealthBuff=HealthMultiplier[CurseLevel]*KillCount[client];
		War3_SetBuff(client,iAdditionalMaxHealth,thisRaceID,HealthBuff);
	}
}


/* *************************************** (SKILL_CHARGE) *************************************** */
public OnAbilityCommand(client,ability,bool:pressed)
{
	if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && ValidPlayer(client,true))
	{
		new ChargeLevel=War3_GetSkillLevel(client,thisRaceID,SKILL_CHARGE);
		if(ChargeLevel>0)
		{
			if(SkillAvailable(client,thisRaceID,SKILL_CHARGE,true,true,true))
			{
				War3_CooldownMGR(client,ChargeCD[ChargeLevel],thisRaceID,SKILL_CHARGE,true,true);
				new Float:CurrentSpeed=W3GetBuffMaxFloat(client,fMaxSpeed)+W3GetBuffMaxFloat(client,fMaxSpeed2);
				War3_SetBuff(client,fMaxSpeed,thisRaceID,CurrentSpeed+ChargeSpeed[ChargeLevel]);
				CreateTimer(ChargeDuration,StopSpeed,client);
				EmitSoundToAll(ChargeSound,client);
			}
		}
		else
			PrintHintText(client,"Level your skill first");
	}
}

public Action:StopSpeed(Handle:timer,any:client)
{
	if(ValidPlayer(client))
	{
		AddSpeedBuff(client);
	}
}

/* *************************************** (SKILL_SCREEN) *************************************** */
public OnW3TakeDmgBulletPre(victim,attacker,Float:damage)
{
	if(ValidPlayer(victim, true) && ValidPlayer(attacker) && GetClientTeam(attacker)!=GetClientTeam(victim))
	{
		if(War3_GetRace(victim)==thisRaceID)
		{
			new ScreenLevel = War3_GetSkillLevel(victim,thisRaceID,SKILL_SCREEN);
			if(ScreenLevel>0)
			{
				new String:weapon[32]; 
				GetClientWeapon(victim,weapon,32);
				if(StrEqual(weapon,"weapon_knife"))
					War3_DamageModPercent(ScreenKnifeDamage[ScreenLevel]);
				else
					War3_DamageModPercent(ScreenOtherDamage[ScreenLevel]);
			}
		}
		else if(War3_GetRace(attacker)==thisRaceID)
		{
			new ScreenLevel = War3_GetSkillLevel(attacker,thisRaceID,SKILL_SCREEN);
			if(ScreenLevel>0)
			{
				War3_DamageModPercent(ScreenKnifeDamage[ScreenLevel]);
			}
		}
	}
}

/* *************************************** (SKILL_CURSE) *************************************** */
public OnWar3EventDeath(victim,attacker)
{
	if(GetClientTeam(attacker)!=GetClientTeam(victim))
	{
		if(War3_GetRace(attacker)==thisRaceID && !Silenced(attacker))
		{
			new CurseLevel=War3_GetSkillLevel(attacker,thisRaceID,SKILL_CURSE);
			if(CurseLevel>0)
			{
				KillCount[attacker]++;
			}
		}
/* *************************************** (ULT_VEST) *************************************** */
		if(War3_GetRace(victim)==thisRaceID && UltFilter(attacker))
		{
			new VestLevel=War3_GetSkillLevel(victim,thisRaceID,ULT_VEST);
			if(VestLevel>0)
			{
				CalcNades(victim);
			}
		}
	}
}

public CalcNades(client)
{
	if(ValidPlayer(client))
	{
		new VestLevel=War3_GetSkillLevel(client,thisRaceID,ULT_VEST);
		new vertices=VestNadeCount[VestLevel];
		new Float:clientpos[3];
		new Float:pos[vertices][3];
		clientpos[2]+=20.0;
		
		GetClientAbsOrigin(client,clientpos);
		FindCircumferencePoints(pos, vertices, clientpos, NadeDistance);
		for (int i = 0; i < vertices; i++)
		{
			dropGrenade(client, pos[i], 80.0);
		}
	}
}

public FindCircumferencePoints(float[][3] out, int vertices, float origin[3], float radius)
{
	for (int i = 0; i < vertices; i++)
	{
		out[i][0] = Sine(float(i) / vertices * 6.28) * radius + origin[0];
		out[i][1] = Cosine(float(i) / vertices * 6.28) * radius + origin[1];
		out[i][2] = origin[2]+20.0;
	}
} 

public dropGrenade(any:client, Float:pos[3], Float:damage)
{
    new grenadeEnt = CreateEntityByName("hegrenade_projectile");
    
    if (IsValidEntity(grenadeEnt))
    {
        SetEntPropEnt(grenadeEnt, Prop_Send, "m_hOwnerEntity", client);
        SetEntPropEnt(grenadeEnt, Prop_Send, "m_hThrower", client);
        SetEntProp(grenadeEnt, Prop_Send, "m_iTeamNum", GetClientTeam(client));
        
        SetEntPropFloat(grenadeEnt, Prop_Send, "m_flDamage", damage);
        SetEntPropFloat(grenadeEnt, Prop_Send, "m_DmgRadius", 350.0);
        SetEntPropFloat(grenadeEnt, Prop_Send, "m_flElasticity", 0.0);
        
        SetEntProp(grenadeEnt, Prop_Send, "m_CollisionGroup", 2);
        
        DispatchSpawn(grenadeEnt);
        TeleportEntity(grenadeEnt, pos, NULL_VECTOR, NULL_VECTOR);
        
        SetEntProp(grenadeEnt, Prop_Data, "m_nNextThinkTick", -1);
        
        CreateTimer(1.0,detonateGrenade,grenadeEnt);
    }
}

public Action:detonateGrenade(Handle:timer, any:grenadeEnt)
{
    if (IsValidEntity(grenadeEnt))
    {
        SetEntProp(grenadeEnt, Prop_Send, "m_CollisionGroup", 5);
        SetEntProp(grenadeEnt, Prop_Data, "m_takedamage", 2);
        SetEntProp(grenadeEnt, Prop_Data, "m_iHealth", 1);
        SetEntProp(grenadeEnt, Prop_Data, "m_nNextThinkTick", 1);
        Entity_Hurt(grenadeEnt, 1, grenadeEnt);
    }
}

public OnW3TakeDmgAllPre(victim, attacker, Float:damage)
{
    if (victim == attacker && War3_GetRace(victim) == thisRaceID && ValidPlayer(victim, true))
    {
        War3_DamageModPercent(0.0);
    }
}

