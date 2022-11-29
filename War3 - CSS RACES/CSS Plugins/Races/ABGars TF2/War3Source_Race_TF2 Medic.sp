#pragma semicolon 1
 
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdkhooks>

public Plugin:myinfo = 
{
	name = "War3Source Race - TF2 Medic",
	author = "ABGar",
	description = "The TF2 Medic race for War3Source.",
	version = "1.0",
}

new thisRaceID;

new SKILL_MEDI, SKILL_KRITZ, SKILL_UBER, ULT_CHARGE;

// SKILL_MEDI
new BeamSprite, HaloSprite;
new Float:MediGunRange=600.0;
new Float:MediGunCD[]={0.0,20.0,15.0,10.0,5.0};
new Float:MediHeal[]={0.0,2.0,3.0,4.0,5.0};
new bool:bMediGunActive[MAXPLAYERSCUSTOM];
new bTargettedAlly[MAXPLAYERSCUSTOM];
new String:MediOn[]="items/medshot4.wav";
new String:MediOff[]="items/medshotno1.wav";


// SKILL_KRITZ
new MoneyOffsetCS;
new KritzMoney[]={0,50,100,150,200};

// SKILL_UBER
new UberMoney[]={0,300,400,500,600};

// ULT_CHARGE
new ChargeMinMoney[]={0,4000,6000,8000,10000};
new bool:bInUberCharge[MAXPLAYERSCUSTOM];
new Float:ChargeTime[]={0.0,4.0,6.0,8.0,10.0};
new Float:ChargeCD=10.0;
new String:UberActive[]="items/suitchargeok1.wav";
new String:UberEnd[]="items/battery_pickup.wav";



public OnWar3PluginReady()
{
	thisRaceID=War3_CreateNewRace("TF2 Medic","tf2medic");
	SKILL_MEDI = War3_AddRaceSkill(thisRaceID,"Medi gun","Targets and heals a single teammate (+ability)",false,4);
	SKILL_KRITZ = War3_AddRaceSkill(thisRaceID,"Kritzkrieg ","Gains money over time when you have a teammate targeted",false,4);
	SKILL_UBER = War3_AddRaceSkill(thisRaceID,"Übersaw ","Gains money from knife attacks on enemy’s",false,4);
	ULT_CHARGE=War3_AddRaceSkill(thisRaceID,"ÜberCharge","Medic and his target are invulnerable, at the cost of money (+ultimate)",true,4);
	War3_CreateRaceEnd(thisRaceID);
	W3SkillCooldownOnSpawn(thisRaceID,ULT_CHARGE,15.0,_);
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
	War3_WeaponRestrictTo(client,thisRaceID,"weapon_tmp,weapon_knife");
	GivePlayerItem(client,"weapon_tmp");
	bMediGunActive[client]=false;
	bTargettedAlly[client]=-1;
	bInUberCharge[client]=false;
	EndMediGun(client);
	SetMoney(client,800);
}

public OnPluginStart()
{
	CreateTimer(1.0,MediGunTimer,_,TIMER_REPEAT);
	MoneyOffsetCS=FindSendPropInfo("CCSPlayer","m_iAccount");
}

public OnMapStart()
{
	BeamSprite=PrecacheModel("materials/sprites/lgtning.vmt");
	HaloSprite=PrecacheModel("materials/sprites/halo01.vmt");
	
	War3_PrecacheSound(MediOn);
	War3_PrecacheSound(MediOff);
	War3_PrecacheSound(UberActive);
	War3_PrecacheSound(UberEnd);
}


/* *************************************** (SKILL_KRITZ) *************************************** */
stock GetMoney(player)
{
	return GetEntData(player,MoneyOffsetCS);
}

stock SetMoney(player,money)
{
	SetEntData(player,MoneyOffsetCS,money);
}
/* *************************************** (SKILL_MEDI) *************************************** */
public Action:MediGunTimer(Handle:timer,any:userid)
{
	for(new client=1;client<=MaxClients;client++)
	{
		if(ValidPlayer(client,true) && War3_GetRace(client)==thisRaceID)
		{
			if(bMediGunActive[client])
			{
				new Float:clientPos[3];
				new Float:allyPos[3];
				new MediLevel=War3_GetSkillLevel(client,thisRaceID,SKILL_MEDI);
				new KritzLevel=War3_GetSkillLevel(client,thisRaceID,SKILL_KRITZ);  // SKILL_KRITZ
				new ally=bTargettedAlly[client];
				if(ValidPlayer(ally,true)&& GetClientTeam(ally)==GetClientTeam(client))
				{
					if(bMediGunActive[ally])
					{
						GetClientAbsOrigin(ally,allyPos);
						GetClientAbsOrigin(client,clientPos);
						allyPos[2]+=20.0;
						clientPos[2]+=20.0;
						if(GetVectorDistance(clientPos,allyPos)<=MediGunRange)
						{
							new CurrentMoney=GetMoney(client);  //  SKILL_KRITZ
							SetMoney(client,CurrentMoney+KritzMoney[KritzLevel]);  //  SKILL_KRITZ
							
							War3_SetBuff(ally,fHPRegen,thisRaceID,MediHeal[MediLevel]);
							TE_SetupBeamPoints(allyPos,clientPos,BeamSprite,HaloSprite,0,35,0.5,6.0,5.0,0,1.0,{44,206,60,255},20);
							TE_SendToClient(client);
						}
						else
							W3ResetBuffRace(ally,fHPRegen,thisRaceID);
					}
				}
				else
				{
					PrintHintText(client,"You're no longer targetting with your Medi Gun");
					W3EmitSoundToAll(MediOff,client);
					EndMediGun(client);
					bTargettedAlly[client]=-1;				
				}
			}
		}
	}
}

public OnAbilityCommand(client,ability,bool:pressed)
{
	if(War3_GetRace(client)==thisRaceID && pressed && ValidPlayer(client,true))
	{
		new MediLevel=War3_GetSkillLevel(client,thisRaceID,SKILL_MEDI);
		if(MediLevel>0)
		{
			if(ability==0)
			{
				if(SkillAvailable(client,thisRaceID,SKILL_MEDI,true,true,true))
				{
					if(bMediGunActive[client])
					{
						PrintHintText(client,"You are already using your Medi Gun..... idiot");
					}
					else
					{
						new ally = War3_GetTargetInViewCone(client,MediGunRange,true,23.0);
						if(ally>0 && GetClientTeam(client)==GetClientTeam(ally))
						{
							bTargettedAlly[client]=ally;
							bTargettedAlly[ally]=client;
							bMediGunActive[client]=true;
							bMediGunActive[ally]=true;
							W3EmitSoundToAll(MediOn,client);
							W3EmitSoundToAll(MediOn,ally);
							PrintHintText(client,"Targetting %N with Medi Gun",ally);
						}
						else
							W3MsgNoTargetFound(client);
					}
				}
			}
			if(ability==1)
			{
				if(bMediGunActive[client])
				{
					EndMediGun(client);
					PrintHintText(client,"You're Medi Gun has run out of juice...");
					War3_CooldownMGR(client,MediGunCD[MediLevel],thisRaceID,SKILL_MEDI,true,true);
					bMediGunActive[client]=false;
					bTargettedAlly[client]=-1;
					W3EmitSoundToAll(MediOff,client);
				}
			}
		}
		else
			PrintHintText(client,"Level your skill first");
	}
}

public EndMediGun(client)
{
	for (new ally=1;ally<=MaxClients;ally++)
	{
		if(ValidPlayer(ally))
		{
			bMediGunActive[ally]=false;
			bInUberCharge[ally]=false;
		}
	}
}

// public OnWar3EventDeath(victim,attacker)
// {
	// if(bMediGunActive[victim])
	// {
		// new partner = bTargettedAlly[victim];
		// bMediGunActive[victim]=false;
		// bMediGunActive[partner]=false;
		// bTargettedAlly[victim]=-1;
		// bTargettedAlly[partner]=-1;
		// if(War3_GetRace(partner)==thisRaceID)
		// {
			// PrintHintText(partner,"You left %N to die....  Get a new target",victim);
		// }
	// }
// }

/* *************************************** (SKILL_UBER) *************************************** */
public OnW3TakeDmgBullet(victim,attacker,Float:damage)
{
	if(ValidPlayer(victim) && ValidPlayer(attacker) && GetClientTeam(attacker)!=GetClientTeam(victim))
	{
		if(War3_GetRace(attacker)==thisRaceID)
		{
			new UberLevel = War3_GetSkillLevel(attacker,thisRaceID,SKILL_UBER);
			if(UberLevel>0)
			{
				new String:weapon[32]; 
				GetClientWeapon(attacker,weapon,32);
				if(StrEqual(weapon,"weapon_knife"))
				{
					new CurrentMoney=GetMoney(attacker);
					SetMoney(attacker,CurrentMoney+UberMoney[UberLevel]);
				}
			}
		}
	}
}
/* *************************************** (ULT_CHARGE) *************************************** */
public OnUltimateCommand(client,race,bool:pressed)
{
	if(ValidPlayer(client,true) && race==thisRaceID && pressed)
	{
		new ChargeLevel=War3_GetSkillLevel(client,thisRaceID,ULT_CHARGE);
		if(ChargeLevel>0)
		{
			if(bMediGunActive[client])
			{
				if(SkillAvailable(client,thisRaceID,ULT_CHARGE,true,true,true))
				{
					new CurrentMoney=GetMoney(client);
					if(CurrentMoney>=ChargeMinMoney[ChargeLevel])
					{
						War3_CooldownMGR(client,(ChargeCD+ChargeTime[ChargeLevel]),thisRaceID,ULT_CHARGE,true,true);
						new ally=bTargettedAlly[client];
						SetMoney(client,CurrentMoney-ChargeMinMoney[ChargeLevel]);
						new iSeconds = RoundToZero(ChargeTime[ChargeLevel]);
						PrintHintText(client,"ÜberCharge activated - invulnerability for %i seconds",iSeconds);
						PrintHintText(ally,"ÜberCharge activated - invulnerability for %i seconds",iSeconds);
						bInUberCharge[client]=true;
						bInUberCharge[ally]=true;
						W3SetPlayerColor(client,thisRaceID,10,10,255,_,GLOW_ULTIMATE);
						W3SetPlayerColor(ally,thisRaceID,10,10,255,_,GLOW_ULTIMATE);
						CreateTimer(ChargeTime[ChargeLevel],EndUberCharge,client);
						CreateTimer(ChargeTime[ChargeLevel],EndUberCharge,ally);
						W3EmitSoundToAll(UberActive,client);
						W3EmitSoundToAll(UberActive,ally);
					}
					else
						PrintHintText(client,"You don't have enough money");
				}
			}
			else
				PrintHintText(client,"You haven't got your Medi Gun active.  Target a player first");
		}
		else
			W3MsgUltNotLeveled(client);
	}
}

public Action:EndUberCharge(Handle:timer,any:client)
{
	if(ValidPlayer(client))
	{
		bInUberCharge[client]=false;
		W3ResetPlayerColor(client, thisRaceID);
		PrintHintText(client,"ÜberCharge has ended - you're now vulnerable to damage");
		W3EmitSoundToAll(UberEnd,client);
	}
}


public OnW3TakeDmgBulletPre(victim,attacker,Float:damage)
{
	if(ValidPlayer(victim) && ValidPlayer(attacker) && GetClientTeam(attacker)!=GetClientTeam(victim))
	{
		if(bInUberCharge[victim])
		{
			if(UltFilter(attacker))
			{
				War3_DamageModPercent(0.0);
			}
		}
	}
}