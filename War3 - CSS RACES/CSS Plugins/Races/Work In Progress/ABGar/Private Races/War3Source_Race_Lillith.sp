#pragma semicolon 1
 
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdkhooks>

public Plugin:myinfo = 
{
	name = "War3Source Race - Lillith",
	author = "ABGar",
	description = "The Lillith race for War3Source.",
	version = "1.0",
	// Greed's Private Race Request - http://www.sevensinsgaming.com/forum/index.php?/topic/5320-lilith-private
}

new thisRaceID;

new SKILL_ENFORCER, SKILL_HITRUN, SKILL_INTUITION, ULT_PHASE;

// SKILL_ENFORCER
new bool:bMenuUsed[MAXPLAYERSCUSTOM];

// SKILL_HITRUN
new Float:HitDamage[]={0.0,0.05,0.08,0.12,0.15};

// SKILL_INTUITION
new Float:IntuitionSpeed[]={1.0,1.05,1.1,1.2,1.3};

// ULT_PHASE
new ExplosionModel;
new Float:PhaseRadius=200.0;
new Float:PhaseDamage=20.0;
new Float:InvisDuration[]={0.0,2.0,3.0,4.0,5.0};
new Float:InvisCD=20.0;
new bool:InInvis[MAXPLAYERSCUSTOM];
new Handle:InvisEndTimer[MAXPLAYERSCUSTOM];
new String:InvisOn[]="npc/scanner/scanner_nearmiss1.wav";
new String:InvisOff[]="npc/scanner/scanner_nearmiss2.wav";


public OnWar3PluginReady()
{
	thisRaceID=War3_CreateNewRace("Lillith [PRIVATE]","lillith");
	SKILL_ENFORCER = War3_AddRaceSkill(thisRaceID,"Enforcer","Spawn a menu to select a Pistol (+ability)",false,4);
	SKILL_HITRUN = War3_AddRaceSkill(thisRaceID,"Hit and Run","Bonus Damage and reduce the cooldown of Phase Walk on kill (passive)",false,4);
	SKILL_INTUITION = War3_AddRaceSkill(thisRaceID,"Intuition","Gain extra movement speed (passive)",false,4);
	ULT_PHASE=War3_AddRaceSkill(thisRaceID,"Phase Walk","Go invisible for a short time, and do a phase blast when you become visible again, doing damage to nearby enemies (+ultimate)",true,4);
	War3_CreateRaceEnd(thisRaceID);
	War3_AddSkillBuff(thisRaceID,SKILL_HITRUN,fDamageModifier,HitDamage);
	War3_AddSkillBuff(thisRaceID,SKILL_INTUITION,fMaxSpeed,IntuitionSpeed);
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
	bMenuUsed[client]=false;
}

public OnMapStart()
{
	ExplosionModel=PrecacheModel("materials/sprites/zerogxplode.vmt",false);
}


/* *************************************** (SKILL_ENFORCER) *************************************** */
public OnAbilityCommand(client,ability,bool:pressed)
{
	if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && ValidPlayer(client,true))
	{
		new EnforcerLevel=War3_GetSkillLevel(client,thisRaceID,SKILL_ENFORCER);
		if(EnforcerLevel>0)
		{
			if(!bMenuUsed[client])
			{
				new Handle:menu = CreateMenu(SelectGun);
				SetMenuTitle(menu, "Select which gun you want to use");
				AddMenuItem(menu, "usp", "USP");
				if(EnforcerLevel>1)
					AddMenuItem(menu, "p228", "P228");
				if(EnforcerLevel>2)
					AddMenuItem(menu, "deagle", "Desert Eagle");
				if(EnforcerLevel>3)
					AddMenuItem(menu, "duelies", "Dual Elites");	
					
				SetMenuExitButton(menu, true);
				DisplayMenu(menu, client, 20);
			}
			else
				PrintHintText(client,"You've already used your gun menu this round");
		}
		else
			PrintHintText(client,"Level your skill first");
	}
}

public SelectGun(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		bMenuUsed[client]=true;
		if(StrEqual(info,"usp"))
		{
			War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife, weapon_usp");
			GivePlayerItem(client,"weaon_usp");
		}
		else if(StrEqual(info,"p228"))
		{
			War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife, weapon_p228");
			GivePlayerItem(client,"weapon_p228");
		}
		else if(StrEqual(info,"deagle"))
		{
			War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife, weapon_deagle");
			GivePlayerItem(client,"weapon_deagle");
		}
		else if(StrEqual(info,"elite"))
		{
			War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife, weapon_elite");
			GivePlayerItem(client,"weapon_elite");
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

/* *************************************** (SKILL_HITRUN) *************************************** */
public OnWar3EventDeath(victim,attacker)
{
	if(GetClientTeam(attacker)!=GetClientTeam(victim))
	{
		if(War3_GetRace(attacker)==thisRaceID && !Silenced(attacker))
		{
			new HitLevel=War3_GetSkillLevel(attacker,thisRaceID,SKILL_HITRUN);
			if(HitLevel>0)
			{
				new CurrentCD = (War3_CooldownRemaining(attacker,thisRaceID,ULT_PHASE)-4);
				new Float:NewCD = float(CurrentCD);
				War3_CooldownMGR(attacker,NewCD,thisRaceID,ULT_PHASE,true,true);
			}
		}
	}
}

/* *************************************** (ULT_PHASE) *************************************** */
public OnUltimateCommand(client,race,bool:pressed)
{
	if(ValidPlayer(client,true) && race==thisRaceID && pressed)
	{
		new PhaseLevel=War3_GetSkillLevel(client,thisRaceID,ULT_PHASE);
		if(PhaseLevel>0)
		{
			if(InInvis[client])
				TriggerTimer(InvisEndTimer[client]); 
			else if(SkillAvailable(client,thisRaceID,ULT_PHASE,true,true,true))
			{
				EmitSoundToAll(InvisOn,client);
				War3_SetBuff(client,fInvisibilitySkill,thisRaceID,0.0);
				War3_SetBuff(client,bDisarm,thisRaceID,true);
				InvisEndTimer[client]=CreateTimer(InvisDuration[PhaseLevel],EndInvis,client);
				InInvis[client]=true;
				War3_CooldownMGR(client,InvisCD,thisRaceID,ULT_PHASE, _, _);
			}
		}
		else
			W3MsgUltNotLeveled(client);
	}
}

public Action:EndInvis(Handle:timer,any:client)
{
	W3ResetBuffRace(client,fInvisibilitySkill,thisRaceID);
	CreateTimer(0.5,StopDisarm,client);
	EmitSoundToAll(InvisOff,client);
	InInvis[client]=false;
	new Float:ExplodePos[3];
	new Float:iPos[3];
	GetClientAbsOrigin(client,ExplodePos);

	TE_SetupExplosion(ExplodePos,ExplosionModel,10.0,1,0,RoundToFloor(PhaseRadius),100);
	TE_SendToAll();

	for(new i=1;i<=MaxClients;i++)
	{
		if(ValidPlayer(i,true) && GetClientTeam(i)!=GetClientTeam(client) && UltFilter(i))
		{
			GetClientAbsOrigin(i,iPos);
			new Float:Distance=GetVectorDistance(iPos,ExplodePos);
			if(Distance<=PhaseRadius)
			{
				new Float:factor=(PhaseRadius-Distance)/PhaseRadius;
				new damage=RoundFloat(PhaseDamage*factor);
				War3_DealDamage(i,damage,client,_,"phase blast",W3DMGORIGIN_ULTIMATE,W3DMGTYPE_PHYSICAL);    
			
				War3_ShakeScreen(i,2.0*factor,100.0*factor,20.0);
				W3FlashScreen(i,RGBA_COLOR_RED);
			}
		}
	}
}

public Action:StopDisarm(Handle:timer,any:client)
{
	War3_SetBuff(client,bDisarm,thisRaceID,false);
}
