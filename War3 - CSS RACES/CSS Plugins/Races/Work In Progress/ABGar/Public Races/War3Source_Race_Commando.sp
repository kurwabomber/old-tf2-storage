#pragma semicolon 1
 
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdkhooks>
#include <smlib>

public Plugin:myinfo = 
{
	name = "War3Source Race - Commando",
	author = "ABGar",
	description = "The Commando race for War3Source.",
	version = "1.0",
}

new thisRaceID;

new SKILL_FIGHT, SKILL_SILENT, SKILL_STEALTH, ULT_PT;


// SKILL_FIGHT
new Clip1Offset;
new FightAmmo[]={30,30,25,20,15};
new FightHeal[]={0,1,2,3,4};
new CurrentClipAmount[MAXPLAYERSCUSTOM];
new NewClipAmount[MAXPLAYERSCUSTOM];
new CurrentAmmo[MAXPLAYERSCUSTOM];
new bool:g_bFired[MAXPLAYERSCUSTOM];
new bool:g_bHit[MAXPLAYERSCUSTOM];

// SKILL_SILENT
new Float:SilentDamage[]={1.0,1.2,1.25,1.3,1.35};

// SKILL_STEALTH
new bool:bRunning[MAXPLAYERSCUSTOM];
new Float:CanInvisTime[MAXPLAYERSCUSTOM];
new Float:StealthInvis[]={1.0,0.8,0.7,0.6,0.5};

// ULT_PT
new bool:bInPT[MAXPLAYERSCUSTOM];
new Float:PTDuration=5.0;
new Float:PTCoolDown=25.0;
new Float:PTSpeed[]={1.0,1.35,1.4,1.45,1.5};
new String:PTSound[]="ambient/explosions/explode_7.wav";


public OnWar3PluginReady()
{
	thisRaceID=War3_CreateNewRace("Commando","commando");
	SKILL_FIGHT = War3_AddRaceSkill(thisRaceID,"Stay in the Fight","Every bullet that misses Gains Health when enemies are in your view (passive)",false,4);
	SKILL_SILENT = War3_AddRaceSkill(thisRaceID,"Silent Attack","Take your time and get extra damage when using your silenced USP (passive)",false,4);
	SKILL_STEALTH = War3_AddRaceSkill(thisRaceID,"Stealth","Invisibility based on your movement speed (passive)",false,4);
	ULT_PT=War3_AddRaceSkill(thisRaceID,"P.T","Speed Boost for 5 seconds (+ultimate)",true,4);
	War3_CreateRaceEnd(thisRaceID);
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
	War3_WeaponRestrictTo(client,thisRaceID,"weapon_m4a1,weapon_usp,weapon_knife");
	DropPrimWeapon(client);
	DropSecWeapon(client);
	GivePlayerItem(client,"weapon_m4a1");
	GivePlayerItem(client,"weapon_usp");
	GivePlayerItem(client,"item_assaultsuit");
	RunHook(client);
	bInPT[client]=false;
	W3ResetBuffRace(client,fMaxSpeed,thisRaceID);
	CreateTimer(0.1,FirstAmmo,client);
}

public OnPluginStart()
{
	HookEvent("weapon_fire",Event_WeaponFire);
	HookEvent("player_hurt",Event_PlayerHurt);
	CreateTimer(0.1,CalcVis,_,TIMER_REPEAT);
	Clip1Offset = FindSendPropOffs("CBaseCombatWeapon","m_iClip1");
}

public OnMapStart()
{	
	War3_PrecacheSound(PTSound);
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

public Action:CS_OnBuyCommand(client, const String:weapon[])
{
	if (War3_GetRace(client)==thisRaceID)
	{
		if (StrEqual(weapon, "vest") || StrEqual(weapon, "vesthelm"))
			return Plugin_Handled;	
	}
	return Plugin_Continue;
}

/* *************************************** (SKILL_FIGHT) *************************************** */
public RunHook(client)
{
	new weapon=GetPlayerWeaponSlot(client, 0);
	if(IsValidEntity(weapon))
	{
		SDKHook(weapon, SDKHook_Reload, Hook_WeaponReload);
	}
}

public Action:Hook_WeaponReload(weapon)
{
    new owner=GetEntPropEnt(weapon, Prop_Send, "m_hOwnerEntity");
    if(War3_GetRace(owner) == thisRaceID)
	{
		new FightLevel = War3_GetSkillLevel(owner,thisRaceID,SKILL_FIGHT);
		if(FightLevel>0)
		{
			new String:wep[32]; 
			GetClientWeapon(owner, wep, 32);
			if(StrEqual(wep,"weapon_m4a1"))
			{
				new weapontype = GetPlayerWeaponSlot(owner, 0);
				new ammoType = GetEntProp(weapontype, Prop_Send, "m_iPrimaryAmmoType");
				new wep_ent = W3GetCurrentWeaponEnt(owner);
				
				CurrentClipAmount[owner]=GetEntData(wep_ent,Clip1Offset,4);
				NewClipAmount[owner]=FightAmmo[FightLevel];
				CurrentAmmo[owner]=GetEntProp(owner,Prop_Send,"m_iAmmo",_,ammoType);
				if(CurrentAmmo[owner]!=0)
					CreateTimer(3.2,SetNewAmmo,owner);
			}
		}
	}
}

public Action:SetNewAmmo(Handle:timer,any:client)
{
	if(War3_GetRace(client)==thisRaceID && ValidPlayer(client,true))
	{
		new NewSpareAmmo = CurrentAmmo[client] - (NewClipAmount[client]-CurrentClipAmount[client]);
		
		if(NewSpareAmmo<1)
		{
			NewClipAmount[client]=CurrentClipAmount[client]+CurrentAmmo[client];
			NewSpareAmmo=0;
		}
		Client_SetWeaponAmmo(client,"weapon_m4a1",NewSpareAmmo,0,(NewClipAmount[client]),0);
	}
}

public Action:FirstAmmo(Handle:timer,any:client)
{
	if(War3_GetRace(client)==thisRaceID && IsPlayerAlive(client))
	{
		new FightLevel = War3_GetSkillLevel(client,thisRaceID,SKILL_FIGHT);
		if(FightLevel > 0)
		{
			new Clip = FightAmmo[FightLevel];
			Client_SetWeaponAmmo(client,"weapon_m4a1",-1,-1,Clip,-1);
		}
	}
}

public Event_WeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(War3_GetRace(client)==thisRaceID)
	{
		new String:weapon[32]; 
		GetClientWeapon(client,weapon,32);
		if(StrEqual(weapon,"weapon_m4a1") || StrEqual(weapon,"weapon_usp"))
			g_bFired[client] = true;
    }
}

public Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "attacker"));
	if(War3_GetRace(client)==thisRaceID)
	{
		g_bHit[client] = true;
	}
}

public OnGameFrame()
{
    for(new client=1; client<=MaxClients; client++)
    {
		if(ValidPlayer(client,true) && War3_GetRace(client)==thisRaceID)
		{
			if(g_bFired[client])
			{
				if(!g_bHit[client])
					DoHeal(client);
			}
			g_bFired[client] = false;
			g_bHit[client] = false;
		}
    }
}

public DoHeal(client)
{
	if(War3_GetRace(client)==thisRaceID && ValidPlayer(client,true))
	{
		new FightLevel = War3_GetSkillLevel(client,thisRaceID,SKILL_FIGHT);
		if(FightLevel>0)
		{
			new target = War3_GetTargetInViewCone(client,2000.0,false,25.0);
			if(target>0)
			{
				War3_HealToMaxHP(client,FightHeal[FightLevel]);
			}
		}
	}
}

/* *************************************** (SKILL_SILENT) *************************************** */
public OnW3TakeDmgBulletPre(victim,attacker,Float:damage)
{
	if(ValidPlayer(victim) && ValidPlayer(attacker) && GetClientTeam(attacker)!=GetClientTeam(victim))
	{
		if(War3_GetRace(attacker)==thisRaceID)
		{
			new SilentLevel = War3_GetSkillLevel(attacker,thisRaceID,SKILL_SILENT);
			if(SilentLevel>0)
			{
				new String:weapon[32]; 
				GetClientWeapon(attacker,weapon,32);
				if(StrEqual(weapon,"weapon_usp"))
				{
					War3_DamageModPercent(SilentDamage[SilentLevel]);
					W3FlashScreen(victim,RGBA_COLOR_RED);
					W3FlashScreen(attacker,RGBA_COLOR_RED);
				}
			}
		}
	}
}

/* *************************************** (SKILL_STEALTH) *************************************** */
public Action:CalcVis(Handle:timer,any:userid)
{
	for(new i=1;i<MaxClients;i++)
	{
		if(ValidPlayer(i) && War3_GetRace(i)==thisRaceID)
		{
			new StealthLevel = War3_GetSkillLevel(i,thisRaceID,SKILL_STEALTH);
			if(StealthLevel>0)
			{
				if(!bInPT[i])
				{
					if(bRunning[i])
					{
						W3ResetBuffRace(i,fInvisibilitySkill,thisRaceID);
						CanInvisTime[i]=GetGameTime() + 1.0;
					}
					else
					{
						if(CanInvisTime[i]<GetGameTime())
						{
							War3_SetBuff(i,fInvisibilitySkill,thisRaceID,StealthInvis[StealthLevel]);
							CanInvisTime[i]=GetGameTime() + 1.0;
						}
					}
				}
			}
		}
	}
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(ValidPlayer(client) && War3_GetRace(client)==thisRaceID)
	{
		bRunning[client]=(buttons & (IN_FORWARD | IN_BACK | IN_MOVELEFT | IN_MOVERIGHT)) &&  (!(buttons & IN_SPEED | buttons & IN_DUCK))?true:false;
	}
	return Plugin_Continue;
}

/* *************************************** (ULT_PT) *************************************** */
public Action:StopSpeed( Handle:timer, any:client )
{
	if(ValidPlayer(client) && bInPT[client])
	{
        bInPT[client]=false;
        W3ResetBuffRace(client,fMaxSpeed,thisRaceID);
	}
}

public OnUltimateCommand(client,race,bool:pressed)
{
	if(ValidPlayer(client,true) && race==thisRaceID && pressed)
	{
		new PTLevel = War3_GetSkillLevel(client,thisRaceID,ULT_PT);
		if(PTLevel>0)
		{
			if(SkillAvailable(client,thisRaceID,ULT_PT,true,true,true))
			{
				War3_CooldownMGR(client,PTCoolDown,thisRaceID,ULT_PT, _, _);
				War3_SetBuff(client,fMaxSpeed,thisRaceID,PTSpeed[PTLevel]);
				W3ResetBuffRace(client,fInvisibilitySkill,thisRaceID);				
				bInPT[client]=true;
				CreateTimer(PTDuration,StopSpeed,client);
				EmitSoundToAll(PTSound,client);
			}
		}
		else
			W3MsgUltNotLeveled(client);
	}
}
