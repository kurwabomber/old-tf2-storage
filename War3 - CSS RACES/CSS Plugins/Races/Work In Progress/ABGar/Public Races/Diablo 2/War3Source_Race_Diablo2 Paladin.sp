#pragma semicolon 1
 
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdkhooks>
#include <smlib>

public Plugin:myinfo = 
{
	name = "War3Source Race - Diablo2 Paladin",
	author = "ABGar",
	description = "The Diablo2 Paladin race for War3Source.",
	version = "1.0",
}

new thisRaceID;

new SKILL_THORNS, SKILL_SACRIFICE, SKILL_BOLT, ULT_CHARGE;

// SKILL_THORNS
new ThornsOwner[MAXPLAYERSCUSTOM]={-1, ...};
new bool:bThornsActive[MAXPLAYERSCUSTOM]={false, ...};
new Float:ThornsAuraRadius=200.0;
new Float:ThornsReturnDamage[]={0.0,0.06,0.09,0.12,0.15};
new String:ThornsSound[]="war3source/d2paladin/thorns.wav";

// SKILL_SACRIFICE
new Float:SacrificeCD=30.0;
new Float:SacrificeDuration=10.0;
new Float:SacrificeHealth[]={0.0,0.2,0.3,0.4,0.5};
new Float:SacrificeDamageInc[]={0.0,0.25,0.5,0.75,1.0};
new Handle:hSacrificeTimer[MAXPLAYERSCUSTOM]={INVALID_HANDLE, ...};
new String:SacrificeSound[]="war3source/d2paladin/sacrifice.wav";

// SKILL_BOLT
new BeamSprite, HaloSprite;
new BoltHealth[]={0,5,10,15,20};
new BoltDamage[]={0,5,10,15,20};
new Float:BoltRange=500.0;
new Float:BoltCD[]={0.0,35.0,30.0,25.0,20.0};
new String:BoltSound[]="war3source/d2paladin/holybolt.wav";

// ULT_CHARGE
new ChargeDamage[]={0,25,40,55,75};
new bool:bChargeUsed[MAXPLAYERSCUSTOM]={false, ...};
new bool:bInCharge[MAXPLAYERSCUSTOM]={false, ...};
new Float:ChargeSpeed=1.6;
new Float:ChargeDuration=5.0;
new Float:ChargeDamageReduce[]={0.0,0.8,0.7,0.6,0.5};
new Handle:hChargeTimer[MAXPLAYERSCUSTOM]={INVALID_HANDLE, ...};
new String:ChargeSound[]="war3source/d2paladin/charge.wav";
new String:ChargeImpactSound[]="war3source/d2paladin/chargeimpact.wav";


public OnWar3PluginReady()
{
	thisRaceID=War3_CreateNewRace("Diablo2 Paladin","d2paladin");
	SKILL_THORNS = War3_AddRaceSkill(thisRaceID,"Thorns","Those who would strike the emissaries of the Light had best take warning, for retribution shall be swift and certain. (passive) \n Caster and allies within 200 radius get return damage",false,4);
	SKILL_SACRIFICE = War3_AddRaceSkill(thisRaceID,"Sacrifice","By sanctifying his weapon with some of his own blood, a Paladin of Zakarum is able to increase his efficiency in combat. (+ability) \n 40/60/80/100% damage increase for 10/20/30/40% health sacrifice. Lasts 10 seconds.",false,4);
	SKILL_BOLT = War3_AddRaceSkill(thisRaceID,"Holy Bolt","The Paladin can learn to summon bolts formed of pure, righteous energies. (+ability1) \n Bolt of light fired at an ally will heal, or at an enemy to damage.",false,4);
	ULT_CHARGE=War3_AddRaceSkill(thisRaceID,"Charge","Rush forward with heads down and shields up, allowing their glory to carry them into the thick of battle to deliver the first blow. (+ultimate) \n Increase speed, reduce damage, and any contact with an enemy will do instant damage",true,4);
	War3_CreateRaceEnd(thisRaceID);
	W3SkillCooldownOnSpawn(thisRaceID,SKILL_SACRIFICE,10.0,_);
	W3SkillCooldownOnSpawn(thisRaceID,ULT_CHARGE,10.0,_);
}

public OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart);
	CreateTimer(1.0,Aura,_,TIMER_REPEAT);
}

public OnMapStart()
{
	AddFileToDownloadsTable("sound/war3source/d2paladin/thorns.wav");
	AddFileToDownloadsTable("sound/war3source/d2paladin/sacrifice.wav");
	AddFileToDownloadsTable("sound/war3source/d2paladin/holybolt.wav");
	AddFileToDownloadsTable("sound/war3source/d2paladin/charge.wav");
	AddFileToDownloadsTable("sound/war3source/d2paladin/chargeimpact.wav");
	War3_PrecacheSound(ThornsSound);
	War3_PrecacheSound(SacrificeSound);
	War3_PrecacheSound(BoltSound);
	War3_PrecacheSound(ChargeSound);
	War3_PrecacheSound(ChargeImpactSound);
	BeamSprite=PrecacheModel("materials/sprites/lgtning.vmt");
	HaloSprite=PrecacheModel("materials/sprites/halo01.vmt");
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
    for (new i=1; i<MaxClients; i++)
    {
        if (ValidPlayer(i,true) && War3_GetRace(i)==thisRaceID)
        {
			bChargeUsed[i]=false;
			if(hSacrificeTimer[i] != INVALID_HANDLE)
			{
				KillTimer(hSacrificeTimer[i]);
				hSacrificeTimer[i] = INVALID_HANDLE;
			}
			if(hChargeTimer[i] != INVALID_HANDLE)
			{
				KillTimer(hChargeTimer[i]);
				hChargeTimer[i] = INVALID_HANDLE;
			}
			InitPassiveSkills(i);
        }
    }
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
	W3ResetBuffRace(client,fDamageModifier,thisRaceID);
	bInCharge[client]=false;
	if(hSacrificeTimer[client] != INVALID_HANDLE)
	{
		KillTimer(hSacrificeTimer[client]);
		hSacrificeTimer[client] = INVALID_HANDLE;
	}
	if(hChargeTimer[client] != INVALID_HANDLE)
	{
		KillTimer(hChargeTimer[client]);
		hChargeTimer[client] = INVALID_HANDLE;
	}
	War3_WeaponRestrictTo(client,thisRaceID,"weapon_m3,weapon_usp,weapon_knife");
	CreateTimer(0.5,GiveWep,client);
}

public Action:GiveWep(Handle:timer,any:client)
{
	if (!Client_HasWeapon(client, "weapon_m3"))
		Client_GiveWeapon(client, "weapon_m3", true);
	if (!Client_HasWeapon(client, "weapon_usp"))
		Client_GiveWeapon(client, "weapon_usp", false);
}

/* *************************************** (SKILL_THORNS) *************************************** */
public Action:Aura(Handle:timer,any:userid)
{
	for(new client=1;client<=MaxClients;client++)
	{
		if(ValidPlayer(client,true) && War3_GetRace(client)==thisRaceID)
		{
			new Float:clientPos[3];		GetClientAbsOrigin(client,clientPos);
			new Float:allyPos[3];

			for (new ally=1;ally<=MaxClients;ally++)
			{
				if(ValidPlayer(ally,true)&& GetClientTeam(ally)==GetClientTeam(client))
				{
					GetClientAbsOrigin(ally,allyPos);
					if(GetVectorDistance(clientPos,allyPos)<=ThornsAuraRadius)
					{
						bThornsActive[ally]=true;
						ThornsOwner[ally]=client;
					}
					else
					{
						bThornsActive[ally]=false;
						ThornsOwner[ally]=-1;
					}
				}
			}
		}
	}
}

public OnW3TakeDmgAll(victim,attacker,Float:damage)
{
	if(ValidPlayer(victim) && ValidPlayer(attacker) && GetClientTeam(attacker)!=GetClientTeam(victim))
	{
		if(bThornsActive[victim] && SkillFilter(attacker))
		{
			new paladin = ThornsOwner[victim];
			new ThornsLevel = War3_GetSkillLevel(paladin,thisRaceID,SKILL_THORNS);

			new iDamage = RoundToFloor(damage * ThornsReturnDamage[ThornsLevel]);
			if(iDamage>0)
			{
				if(iDamage>40)	iDamage=40;
				War3_DealDamageDelayed(attacker,victim,iDamage,"thorns aura",0.1,true,SKILL_THORNS);
				War3_EffectReturnDamage(victim,attacker,iDamage,SKILL_THORNS);
				W3EmitSoundToAll(ThornsSound,victim);
			}
		}
	}
}

/* *************************************** (SKILL_SACRIFICE) *************************************** */
public Action:StopSacrifice(Handle:timer,any:client)
{
	if(ValidPlayer(client))
	{
		W3ResetBuffRace(client,fDamageModifier,thisRaceID);
	}
}

public OnAbilityCommand(client,ability,bool:pressed)
{
	if(ValidPlayer(client,true) && War3_GetRace(client)==thisRaceID && pressed)
	{
		if(ability==0)
		{
			new SacrificeLevel=War3_GetSkillLevel(client,thisRaceID,SKILL_SACRIFICE);
			if(SacrificeLevel>0)
			{
				if(SkillAvailable(client,thisRaceID,SKILL_SACRIFICE,true,true,true))
				{
					War3_CooldownMGR(client,SacrificeCD,thisRaceID,SKILL_SACRIFICE,true,true);
					new iHealth=RoundToZero(GetClientHealth(client)*SacrificeHealth[SacrificeLevel]);
					War3_DealDamage(client,iHealth,client,DMG_CRUSH,"sacrifice",_,W3DMGTYPE_MAGIC);
					War3_SetBuff(client,fDamageModifier,thisRaceID,SacrificeDamageInc[SacrificeLevel]);
					hSacrificeTimer[client] = CreateTimer(SacrificeDuration,StopSacrifice,client);
					W3EmitSoundToAll(SacrificeSound,client);
				}
			}
			else
				PrintHintText(client,"Level your skill first");
		}
/* *************************************** (SKILL_BOLT) *************************************** */
		if(ability==1)
		{
			new BoltLevel=War3_GetSkillLevel(client,thisRaceID,SKILL_BOLT);
			if(BoltLevel>0)
			{
				if(SkillAvailable(client,thisRaceID,SKILL_BOLT,true,true,true))
				{
					new target = War3_GetTargetInViewCone(client,BoltRange,true,23.0);
					if(target>0 && SkillFilter(target))
					{
						War3_CooldownMGR(client,BoltCD[BoltLevel],thisRaceID,SKILL_BOLT,true,true);
						new Float:clientPos[3];		GetClientAbsOrigin(client,clientPos);	clientPos[2]+=40.0;
						new Float:targetPos[3];		GetClientAbsOrigin(target,targetPos);	targetPos[2]+=40.0;
						W3EmitSoundToAll(BoltSound,client);
						CreateTimer(1.0,SoundStop,client);
						new colour[4];
						if(GetClientTeam(target)==GetClientTeam(client))
						{
							War3_HealToMaxHP(client,BoltHealth[BoltLevel]);
							colour={255,255,255,200};
						}
						else if (GetClientTeam(target)!=GetClientTeam(client))
						{
							War3_DealDamage(target,BoltDamage[BoltLevel],client,DMG_CRUSH,"holy bolt",_,W3DMGTYPE_MAGIC);
							colour={0,100,0,200};
						}
						TE_SetupBeamPoints(clientPos,targetPos,BeamSprite,HaloSprite,0,35,0.5,6.0,5.0,0,1.0,colour,20);
						TE_SendToAll();
					}
					else
						W3MsgNoTargetFound(client,BoltRange);
				}
			}
		}
	}
}

public Action:SoundStop(Handle:timer,any:client)
{
	StopSound(client,SNDCHAN_AUTO,BoltSound);
}

/* *************************************** (ULT_CHARGE) *************************************** */
public OnUltimateCommand(client,race,bool:pressed)
{
	if(ValidPlayer(client,true) && race==thisRaceID && pressed)
	{
		new ChargeLevel=War3_GetSkillLevel(client,thisRaceID,ULT_CHARGE);
		if(ChargeLevel>0)
		{
			if(SkillAvailable(client,thisRaceID,ULT_CHARGE,true,true,true))
			{
				if(!bChargeUsed[client])
				{
					bChargeUsed[client]=true;
					bInCharge[client]=true;
					W3EmitSoundToAll(ChargeSound,client);
					War3_SetBuff(client,fMaxSpeed,thisRaceID,ChargeSpeed);
					War3_SetBuff(client,bDisarm,thisRaceID,true);
					hChargeTimer[client] = CreateTimer(ChargeDuration,StopCharge,client);
				}
				else
					PrintHintText(client,"You've already used your Charge this round");
			}
		}
		else
			W3MsgUltNotLeveled(client);
	}
}

public Action:StopCharge(Handle:timer,any:client)
{
	if(ValidPlayer(client))
	{
		bInCharge[client]=false;
		W3ResetBuffRace(client,fMaxSpeed,thisRaceID);
		War3_SetBuff(client,bDisarm,thisRaceID,false);
		if(hChargeTimer[client] != INVALID_HANDLE)
		{
			KillTimer(hChargeTimer[client]);
			hChargeTimer[client] = INVALID_HANDLE;
		}
	}
}

public OnGameFrame()
{
    for(new client=1; client<=MaxClients; client++)
    {
		if(ValidPlayer(client,true) && War3_GetRace(client)==thisRaceID && bInCharge[client])
		{
			new ChargeLevel=War3_GetSkillLevel(client,thisRaceID,ULT_CHARGE);
			new Float:clientPos[3];		GetClientAbsOrigin(client,clientPos);
			for (new enemy=1;enemy<=MaxClients;enemy++)
			{
				if(ValidPlayer(enemy,true) && GetClientTeam(enemy)!=GetClientTeam(client) && UltFilter(enemy))
				{
					new Float:enemyPos[3];		GetClientAbsOrigin(enemy,enemyPos);
					if(GetVectorDistance(clientPos,enemyPos)<=30.0)
					{
						War3_DealDamage(enemy,ChargeDamage[ChargeLevel],client,DMG_CRUSH,"charge",_,W3DMGTYPE_MAGIC);
						W3EmitSoundToAll(ChargeImpactSound,client);
						TriggerTimer(hChargeTimer[client]);
					}
				}
			}
		}
    }
}

public OnW3TakeDmgAllPre(victim,attacker,Float:damage)
{
	if(ValidPlayer(victim) && ValidPlayer(attacker) && GetClientTeam(attacker)!=GetClientTeam(victim))
	{
		if(War3_GetRace(victim)==thisRaceID && bInCharge[victim] && UltFilter(attacker))
		{
			new ChargeLevel=War3_GetSkillLevel(victim,thisRaceID,ULT_CHARGE);
			if(ChargeLevel>0)
			{
				War3_DamageModPercent(ChargeDamageReduce[ChargeLevel]);
				PrintToConsole(victim,"Damage reduced while in Charge");
				PrintToConsole(attacker,"Damage reduced against Paladin in Charge");
			}
		}
	}
}













