#pragma semicolon 1
 
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdkhooks>

public Plugin:myinfo = 
{
	name = "War3Source Race - Diablo2 Barbarian",
	author = "ABGar",
	description = "The Diablo2 Barbarian race for War3Source.",
	version = "1.0",
}

new thisRaceID;

new SKILL_WARCRY, SKILL_ORDERS, SKILL_SKIN, ULT_BERSERK;

// SKILL_WARCRY
new BeamSprite, HaloSprite;
new WarcryDamage[]={0,5,10,15,20};
new Float:WarcryCD=30.0;
new Float:WarcryRadius=300.0;
new Float:WarcryDuration[]={0.0,0.2,0.4,0.6,0.8};
//new String:WarcrySound[]="npc/combine_gunship/see_enemy.wav";
new String:WarcrySound[]="war3source/d2barbarian/warcry.wav";

// SKILL_ORDERS
new OrdersHeal[]={0,5,10,15,20};
new Float:OrdersDuration=10.0;
new Float:OrdersRadius=250.0;
new Float:OrdersCD[]={0.0,45.0,40.0,35.0,30.0};
new Float:OrdersSpeed[]={1.0,1.15,1.2,1.25,1.3};
//new String:OrdersSound[]="npc/vort/vort_pain3.wav";
new String:OrdersSound[]="war3source/d2barbarian/battleorders.wav";

// SKILL_SKIN
new Float:SkinDamageReduce[]={1.0,0.94,0.91,0.88,0.85};

// ULT_BERSERK
new bool:bInBerserk[MAXPLAYERSCUSTOM]={false, ...};
new Float:BerserkDamage[]={0.0,0.1,0.15,0.2,0.25};
new Float:BerserkCD=10.0;
new Float:BerserkHealthLoss[]={0.0,1.0,2.0,3.0,4.0};
//new String:BerserkOnSound[]="npc/zombie/zombie_pain5.wav";
//new String:BerserkOffSound[]="npc/zombie/zombie_pain1.wav";
new String:BerserkOnSound[]="war3source/d2barbarian/berserkon.wav";
new String:BerserkOffSound[]="war3source/d2barbarian/berserkoff.wav";


public OnWar3PluginReady()
{
	thisRaceID=War3_CreateNewRace("Diablo2 Barbarian","d2barbarian");
	SKILL_WARCRY = War3_AddRaceSkill(thisRaceID,"Warcry","Summoning the ancient powers known to his people, a Barbarian warrior can call on his spirit animal and lash out at his enemies. (+ability) \n stuns and damages nearby enemies",false,4);
	SKILL_ORDERS = War3_AddRaceSkill(thisRaceID,"Battle Orders","Although skillful in single combat, the Barbarian warrior also has a talent for group tactics. (+ability1) \nHeals self and allies, and increases speed for 10 seconds",false,4);
	SKILL_SKIN = War3_AddRaceSkill(thisRaceID,"Iron Skin","Constant prolonged exposure to the sun, wind, rain and other elements has toughened Barbarian skin to the resilience of natural leather. (passive) \nDamage Reduction",false,4);
	ULT_BERSERK=War3_AddRaceSkill(thisRaceID,"Berserk","One of the most powerful combat skills a Barbarian can learn is to cross that line into rage, expending the sum of his energy and slaying everything without regard for consequences. (+ultimate) \nIncrease damage and reduce health - toggle on and off",true,4);
	War3_CreateRaceEnd(thisRaceID);
	W3SkillCooldownOnSpawn(thisRaceID,ULT_BERSERK,10.0,_);
}

public OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart);
}

public OnMapStart()
{
	AddFileToDownloadsTable("sound/war3source/d2barbarian/warcry.wav");
	AddFileToDownloadsTable("sound/war3source/d2barbarian/battleorders.wav");
	AddFileToDownloadsTable("sound/war3source/d2barbarian/berserkon.wav");
	AddFileToDownloadsTable("sound/war3source/d2barbarian/berserkoff.wav");
	War3_PrecacheSound(WarcrySound);
	War3_PrecacheSound(OrdersSound);
	War3_PrecacheSound(BerserkOnSound);
	War3_PrecacheSound(BerserkOffSound);
	BeamSprite=PrecacheModel("materials/sprites/lgtning.vmt");
	HaloSprite=PrecacheModel("materials/sprites/halo01.vmt");
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
    for (new i=1; i<MaxClients; i++)
    {
        if (ValidPlayer(i))
        {
			W3ResetAllBuffRace(i,thisRaceID);
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
	bInBerserk[client]=false;
}

/* *************************************** (SKILL_WARCRY) *************************************** */
public Action:StopStun(Handle:timer,any:client)
{
	if(ValidPlayer(client))
	{
		War3_SetBuff(client,bStunned,thisRaceID,false);//Careful! You had this set as true
	}
}

public OnAbilityCommand(client,ability,bool:pressed)
{
	if(ValidPlayer(client,true) && War3_GetRace(client)==thisRaceID && pressed)
	{
		if(ability==0)
		{
			new WarcryLevel=War3_GetSkillLevel(client,thisRaceID,SKILL_WARCRY);
			if(WarcryLevel>0)
			{
				if(SkillAvailable(client,thisRaceID,SKILL_WARCRY,true,true,true))
				{
					War3_CooldownMGR(client,WarcryCD,thisRaceID,SKILL_WARCRY,true,true);
					EmitSoundToAll(WarcrySound,client);
					new Float:ClientPos[3];		GetClientAbsOrigin(client,ClientPos);
					TE_SetupBeamRingPoint(ClientPos, 20.0, WarcryRadius, BeamSprite, HaloSprite, 0, 5, 0.5, 10.0, 1.0, {255,0,0,133}, 60, 0);
					TE_SendToAll();
					for(new target=1;target<=MaxClients;target++)
					{
						if(ValidPlayer(target,true) && GetClientTeam(target)!=GetClientTeam(client) && SkillFilter(target))
						{
							new Float:TargetPos[3];		GetClientAbsOrigin(target,TargetPos);
							if(GetVectorDistance(ClientPos,TargetPos)<WarcryRadius)
							{
								War3_SetBuff(target,bStunned,thisRaceID,true);
								War3_DealDamage(target,WarcryDamage[WarcryLevel],client,DMG_CRUSH,"warcry",_,W3DMGTYPE_MAGIC);
								CreateTimer(WarcryDuration[WarcryLevel],StopStun,target);
							}
						}
					}
				}

			}
			else
				PrintHintText(client,"Level your Warcry first");
		}
/* *************************************** (SKILL_ORDERS) *************************************** */
		if(ability==1)
		{
			new OrdersLevel=War3_GetSkillLevel(client,thisRaceID,SKILL_ORDERS);
			if(OrdersLevel>0)
			{
				if(SkillAvailable(client,thisRaceID,SKILL_ORDERS,true,true,true))
				{
					War3_CooldownMGR(client,OrdersCD[OrdersLevel],thisRaceID,SKILL_ORDERS,true,true);
					EmitSoundToAll(OrdersSound,client);
					//CreateTimer(2.0, Stop, client);
					new Float:ClientPos[3];		GetClientAbsOrigin(client,ClientPos);
					TE_SetupBeamRingPoint(ClientPos, 20.0, WarcryRadius, BeamSprite, HaloSprite, 0, 5, 0.5, 10.0, 1.0, {0,0,255,133}, 60, 0);
					TE_SendToAll();
					for(new ally=1;ally<=MaxClients;ally++)
					{
						if(ValidPlayer(ally,true) && GetClientTeam(ally)==GetClientTeam(client))
						{
							new Float:AllyPos[3];		GetClientAbsOrigin(ally,AllyPos);
							if(GetVectorDistance(ClientPos,AllyPos)<OrdersRadius)
							{
								War3_HealToMaxHP(ally,OrdersHeal[OrdersLevel]);
								War3_SetBuff(ally,fMaxSpeed,thisRaceID,OrdersSpeed[OrdersLevel]);
								CreateTimer(OrdersDuration,StopSpeed,ally);
							}
						}
					}
				}
			}
			else
				PrintHintText(client,"Level your Battle Orders first");
		
		}
	}
}

// public Action:Stop(Handle:timer,any:client)
// {
	// StopSound(client,SNDCHAN_AUTO,OrdersSound);
// }

public Action:StopSpeed(Handle:timer,any:client)
{
	if(ValidPlayer(client))
	{
		W3ResetBuffRace(client,fMaxSpeed,thisRaceID);
	}
}

/* *************************************** (SKILL_SKIN) *************************************** */
public OnW3TakeDmgBulletPre(victim,attacker,Float:damage)
{
	if(ValidPlayer(victim) && ValidPlayer(attacker) && GetClientTeam(attacker)!=GetClientTeam(victim))
	{
		if(War3_GetRace(victim)==thisRaceID)
		{
			new SkinLevel = War3_GetSkillLevel(victim,thisRaceID,SKILL_SKIN);
			if(SkinLevel>0)
			{
				War3_DamageModPercent(SkinDamageReduce[SkinLevel]);
			}
		}
	}
}

/* *************************************** (ULT_BERSERK) *************************************** */
public OnUltimateCommand(client,race,bool:pressed)
{
	if(ValidPlayer(client,true) && race==thisRaceID && pressed)
	{
		new BerserkLevel=War3_GetSkillLevel(client,thisRaceID,ULT_BERSERK);
		if(BerserkLevel>0)
		{
			if(bInBerserk[client])
			{
				War3_CooldownMGR(client,BerserkCD,thisRaceID,ULT_BERSERK,true,true);
				bInBerserk[client]=false;
				EmitSoundToAll(BerserkOffSound,client);
				W3ResetBuffRace(client,fDamageModifier,thisRaceID);
				W3ResetBuffRace(client,fHPDecay,thisRaceID);
			}
			else
			{
				if(SkillAvailable(client,thisRaceID,ULT_BERSERK,true,true))
				{
					bInBerserk[client]=true;
					War3_SetBuff(client,fHPDecay,thisRaceID,BerserkHealthLoss[BerserkLevel]);
					War3_SetBuff(client,fDamageModifier,thisRaceID,BerserkDamage[BerserkLevel]);
					EmitSoundToAll(BerserkOnSound,client);
					
				}
			}
		}
		else
			W3MsgUltNotLeveled(client);
	}
}
