#pragma semicolon 1
 
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdkhooks>
#include <smlib>

public Plugin:myinfo = 
{
	name = "War3Source Race - Mechromancer",
	author = "ABGar",
	description = "The Mechromancer race for War3Source.",
	version = "1.0",
	// Greed's Private Race Request - http://www.sevensinsgaming.com/forum/index.php?/topic/5335-mechomancer-private/
}

new thisRaceID;

new SKILL_ANARCHY, SKILL_COOKING, SKILL_POTENT, ULT_CLAPTRAP;

// SKILL_ANARCHY
Clip1Offset;
new CurrentStack[MAXPLAYERSCUSTOM];
new Float:StackBonus=0.15;

// SKILL_COOKING
new Float:CookingRegen[]={0.0,1.0,2.0,3.0,4.0,5.0};

// SKILL_POTENT
new PotentHealth[]={0,10,20,30,40,50};

// ULT_CLAPTRAP
new Float:SummonCD[]={0.0,40.0,37.0,35.0,32.0,30.0};
new String:SummonSound[]="war3source/archmage/summon.wav";



public OnWar3PluginReady()
{
	thisRaceID=War3_CreateNewRace("Mechromancer [PRIVATE]","mechromancer");
	SKILL_ANARCHY = War3_AddRaceSkill(thisRaceID,"Anarchy","Unlimited Clips",false,1);
	SKILL_COOKING = War3_AddRaceSkill(thisRaceID,"Cooking up Trouble","While your gun's magazine is full, you regenerate health {passive}",false,5);
	SKILL_POTENT = War3_AddRaceSkill(thisRaceID,"Potent as a Pony","Increase your maximum health (passive)",false,5);
	ULT_CLAPTRAP=War3_AddRaceSkill(thisRaceID,"Summon Claptrap","Summon a dead ally at your location (+ultimate)",true,5);
	War3_CreateRaceEnd(thisRaceID);
	War3_AddSkillBuff(thisRaceID,SKILL_POTENT,iAdditionalMaxHealth,PotentHealth);
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

public OnSkillLevelChanged(client, race, skill, newskilllevel)
{
	
}

public InitPassiveSkills(client)
{
	CurrentStack[client]=0;
	DropSecWeapon(client);
	War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife,weapon_deagle");
	GivePlayerItem(client,"weapon_deagle");
	RunHook(client);
	new AnarchyLevel = War3_GetSkillLevel(client,thisRaceID,SKILL_ANARCHY);
	if(AnarchyLevel>0)
		CreateTimer(0.5,SetNewAmmo,client);
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
	CreateTimer(1.0, HPTimer,_,TIMER_REPEAT);
	HookEvent("weapon_reload",ManualReload);
	HookEvent("weapon_fire", Event_WeaponFire);
	Clip1Offset = FindSendPropOffs( "CBaseCombatWeapon", "m_iClip1" );
}

public OnMapStart()
{
	War3_PrecacheSound(SummonSound);
}

/* *************************************** (SKILL_ANARCHY) *************************************** */
public RunHook(client)
{
	new weapon=GetPlayerWeaponSlot(client, 1);
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
		new AnarchyLevel = War3_GetSkillLevel(owner,thisRaceID,SKILL_ANARCHY);
		if(AnarchyLevel>0)
		{
			new String:deagwep[32]; 
			GetClientWeapon(owner, deagwep, 32);
			if(StrEqual(deagwep,"weapon_deagle"))
				CreateTimer(2.2,SetNewAmmo,owner);
		}
	}
}

public Action:SetNewAmmo(Handle:timer,any:client)
{
	if(War3_GetRace(client)==thisRaceID && IsPlayerAlive(client))
	{
		Client_SetWeaponAmmo(client,"weapon_deagle",50,-1,5,-1);
	}
}

public ManualReload(Handle:event,const String:name[],bool:dontBroadcast)
{
	for(new client=1;client<=MaxClients;client++)
	{
		if(War3_GetRace(client) == thisRaceID && ValidPlayer(client,true))
		{
			CurrentStack[client]=0;
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
		if(StrEqual(weapon,"weapon_deagle"))
		{
			new wep_ent = W3GetCurrentWeaponEnt(client);
			new CurrentClipAmount=GetEntData(wep_ent,Clip1Offset,4);
			if(CurrentClipAmount==1 && CurrentStack[client]<3)
			{
				CurrentStack[client]++;
			}
		}
    }
}


/* *************************************** (SKILL_COOKING) *************************************** */
public Action:HPTimer(Handle:timer)
{
	for(new i=1;i<=MaxClients;i++)
	{
		if(ValidPlayer(i,true) && War3_GetRace(i)==thisRaceID)
		{
			new CookingLevel = War3_GetSkillLevel(i,thisRaceID,SKILL_COOKING);
			new wep_ent = W3GetCurrentWeaponEnt(i);
			new CurrentClipAmount=GetEntData(wep_ent,Clip1Offset,4);
			if(CurrentClipAmount==5)
				War3_SetBuff(i,fHPRegen,thisRaceID,CookingRegen[CookingLevel]);
			else
				W3ResetBuffRace(i,fHPRegen,thisRaceID);
			War3_SetBuff(i,fDamageModifier,thisRaceID,(StackBonus*CurrentStack[i]));
		}
	}
}

/* *************************************** (ULT_CLAPTRAP) *************************************** */
public OnUltimateCommand(client,race,bool:pressed)
{
	if(ValidPlayer(client,true) && race==thisRaceID && pressed)
	{
		new ClaptrapLevel=War3_GetSkillLevel(client,thisRaceID,ULT_CLAPTRAP);
		if(ClaptrapLevel>0)
		{
			if(SkillAvailable(client,thisRaceID,ULT_CLAPTRAP,true,true,true))
			{
				new Float:MyPos[3];
				War3_CachedPosition(client,MyPos);
				new targets[MAXPLAYERS];
				new foundtargets;
				for(new ally=1;ally<=MaxClients;ally++)
				{
					if(ValidPlayer(ally) && GetClientTeam(ally)==GetClientTeam(client) && !IsPlayerAlive(ally))
					{
						targets[foundtargets]=ally;
						foundtargets++;
					}
				}
				new target;
				if(foundtargets>0)
				{
					target=targets[GetRandomInt(0, foundtargets-1)];
					if(target>0)
					{
						War3_CooldownMGR(client,SummonCD[ClaptrapLevel],thisRaceID,ULT_CLAPTRAP,_,_);
						new Float:ang[3];
						new Float:pos[3];
						War3_SpawnPlayer(target);
						GetClientEyeAngles(client,ang);
						GetClientAbsOrigin(client,pos);
						TeleportEntity(target,pos,ang,NULL_VECTOR);
						EmitSoundToAll(SummonSound,client);
						CreateTimer(3.0, Stop, client);
					}
				}
				else
					PrintHintText(client,"There are no Claptraps to summon");
			}
		}
		else
			W3MsgUltNotLeveled(client);
	}
}

public Action:Stop(Handle:timer,any:client)
{
	StopSound(client,SNDCHAN_AUTO,SummonSound);
}