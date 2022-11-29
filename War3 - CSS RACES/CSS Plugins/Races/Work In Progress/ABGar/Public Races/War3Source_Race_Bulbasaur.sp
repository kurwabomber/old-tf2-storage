#pragma semicolon 1
 
#include "W3SIncs/War3Source_Interface"
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <smlib>

public Plugin:myinfo = 
{
	name = "War3Source Race - Bulbasaur",
	author = "ABGar",
	description = "The Bulbasaur race for War3Source.",
	version = "1.0",
}

new thisRaceID;

new SKILL_SYNTH, SKILL_SEED, SKILL_GROWTH, ULT_VINE;

// SKILL_SYNTH
new SynthesisHealth[]={0,25,50,75,100};

// SKILL_SEED
new SeedHealth=2;
new TotalSeeded[MAXPLAYERSCUSTOM]={0, ...};
new bool:bSeeded[MAXPLAYERSCUSTOM]={false, ...};
new Float:SeedChance[]={0.0,0.03,0.06,0.08,0.1};
new String:SeedSound[]="player/footsteps/mud3.wav";


// SKILL_GROWTH
new ExplSprite;
new GrowthHealth[]={0,100,150,200,250};
new iGrowth[MAXPLAYERSCUSTOM]={-1, ...};
new String:GrowthModel[]="models/props_debris/barricade_tall02a.mdl";
new String:GrowthSound[]="player/footsteps/duct2.wav";

// ULT_VINE
new BeamSprite,HaloSprite;
new VineDamage[]={0,5,10,15,20};
new Float:VineCD[]={0.0,50.0,40.0,30.0,20.0};
new Float:PullForce[]={0.0,1500.0,2000.0,2500.0,3000.0};
new String:VineSound[]="weapons/slam/throw.wav";


public OnWar3PluginReady()
{
	thisRaceID=War3_CreateNewRace("Bulbasaur","bulbasaur");
	SKILL_SYNTH = War3_AddRaceSkill(thisRaceID,"Synthesis","Bulbasaur draws in strength from sunlight (passive) \n Bonus health",false,4);
	SKILL_SEED = War3_AddRaceSkill(thisRaceID,"Leech Seed","Plant seeds to sap the enemy's health (passive attack) \n chance to infect up to 3 enemies, and decrease their health while increasing yours",false,4);
	SKILL_GROWTH = War3_AddRaceSkill(thisRaceID,"Growth","Raise a growth from the ground, to block your opponent (+ability) \n Spawn a wide plant that is solid, but destructible",false,4);
	ULT_VINE=War3_AddRaceSkill(thisRaceID,"Wine Whip","Use vines to pull your enemy towards you (+ultimate) \n Pull a targetted enemy closer to you",true,4);
	War3_CreateRaceEnd(thisRaceID);
	W3SkillCooldownOnSpawn(thisRaceID,ULT_VINE,10.0,_);
	War3_AddSkillBuff(thisRaceID,SKILL_SYNTH,iAdditionalMaxHealth,SynthesisHealth);
}

public OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart);
	CreateTimer(1.0,SeedTimer,_,TIMER_REPEAT);
}

public OnMapStart()
{
	PrecacheModel(GrowthModel);
	ExplSprite=PrecacheModel("materials/effects/fire_cloud1.vmt");
	BeamSprite=PrecacheModel("materials/sprites/lgtning.vmt");
	HaloSprite=PrecacheModel("materials/sprites/halo01.vmt");
	
	War3_PrecacheSound(SeedSound);
	War3_PrecacheSound(GrowthSound);
	War3_PrecacheSound(VineSound);
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i=1; i<MaxClients; i++)
	{
		if (ValidPlayer(i,true))
		{
			bSeeded[i]=false;
			if(War3_GetRace(i)==thisRaceID)
			{
				InitPassiveSkills(i);
			}
		}
	}
}

public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace != thisRaceID)
	{
		War3_WeaponRestrictTo(client,thisRaceID,"");
		W3ResetAllBuffRace(client,thisRaceID);
		CS_UpdateClientModel(client);
		iGrowth[client]=-1;
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
	if(ValidPlayer(client,true) && War3_GetRace(client)==thisRaceID)
	{
		InitPassiveSkills(client);
	}
}

public InitPassiveSkills(client)
{
	War3_WeaponRestrictTo(client,thisRaceID,"weapon_m4a1,weapon_ak47,weapon_ump45,weapon_glock,weapon_knife");
	RemovePrimary(client);
	CreateTimer(0.2,GiveWep,client);
	iGrowth[client]=-1;
	TotalSeeded[client]=0;
}

public RemovePrimary(client)
{
	new iWeapon = GetPlayerWeaponSlot(client, 0);  
	if(IsValidEntity(iWeapon))
	{
		RemovePlayerItem(client, iWeapon);
		AcceptEntityInput(iWeapon, "kill");
	}
}

public Action:GiveWep(Handle:timer,any:client)
{
	if(ValidPlayer(client,true) && War3_GetRace(client)==thisRaceID)
	{
		GivePlayerItem(client,"weapon_ump45");
		if(!Client_HasWeapon(client,"weapon_glock"))
			GivePlayerItem(client,"weapon_glock");
	}
}

/* *************************************** (SKILL_SEED) *************************************** */
public Action:SeedTimer(Handle:timer,any:userid)
{
	for(new client=1;client<=MaxClients;client++)
	{
		if(ValidPlayer(client,true))
		{
			if(War3_GetRace(client)==thisRaceID)
			{
				new MaxHealth=War3_GetMaxHP(client);
				new SeedLevel = War3_GetSkillLevel(client,thisRaceID,SKILL_SEED);
				if(SeedLevel>0 && GetClientHealth(client)<MaxHealth)
				{
					for (new i=1;i<=MaxClients;i++)
					{
						if(ValidPlayer(i,true) && GetClientTeam(i)!=GetClientTeam(client) && bSeeded[i])
						{
							new iHealth=GetClientHealth(i);
							if(iHealth-SeedHealth>0)
							{
								War3_DecreaseHP(i,SeedHealth);
								PrintToChat(client,"Stole Health from %N",i);
							}
							else
								War3_DealDamage(i,SeedHealth,client,DMG_CRUSH,"bulbasaur seed",_,W3DMGTYPE_MAGIC);

							War3_HealToMaxHP(client,SeedHealth);
						}
					}
				}
			}
		}
	}
}

public OnW3TakeDmgBulletPre(victim,attacker,Float:damage)
{
	if(ValidPlayer(victim) && ValidPlayer(attacker) && GetClientTeam(attacker)!=GetClientTeam(victim))
	{
		if(War3_GetRace(attacker)==thisRaceID)
		{
			if(War3_GetRace(victim)==War3_GetRaceIDByShortname("squirtle"))
			{
				War3_DamageModPercent(1.1);
			}
			
			new SeedLevel = War3_GetSkillLevel(attacker,thisRaceID,SKILL_SEED);
			if(SeedLevel>0 && TotalSeeded[attacker]<3)
			{
				if(!bSeeded[victim] && W3Chance(SeedChance[SeedLevel]))
				{
					bSeeded[victim]=true;
					CPrintToChat(attacker,"{red}You have seeded {green}%N",victim);
					TotalSeeded[attacker]++;
					W3EmitSoundToAll(SeedSound,attacker);
					W3EmitSoundToAll(SeedSound,victim);
				}
			}
		}
	}
}

/* *************************************** (SKILL_GROWTH) *************************************** */
public OnAbilityCommand(client,ability,bool:pressed)
{
	if(ValidPlayer(client,true) && War3_GetRace(client)==thisRaceID && pressed)
	{
		if(ability==0)
		{
			new GrowthLevel=War3_GetSkillLevel(client,thisRaceID,SKILL_GROWTH);
			if(GrowthLevel>0)
			{
				if(SkillAvailable(client,thisRaceID,SKILL_GROWTH,true,true,true))
				{
					new Float:GrowthPos[3];		War3_GetAimTraceMaxLen(client,GrowthPos,200.0);		
					new Float:angles[3];		GetClientAbsAngles(client,angles);					
					new Float:direction[3];		direction[0] = 89.0;
					
					TR_TraceRay(GrowthPos,direction,MASK_PLAYERSOLID_BRUSHONLY, RayType_Infinite);
					if(TR_DidHit(INVALID_HANDLE))
					{
						TR_GetEndPosition(GrowthPos, INVALID_HANDLE);
					}
					
					angles[1]+=180.0;
					GrowthPos[2]+=20.0;
					
					new growth = CreateEntityByName("prop_dynamic_override");
					SetEntityModel(growth, GrowthModel);
					DispatchKeyValue(growth, "StartDisabled", "false");
					DispatchSpawn(growth);		
					TeleportEntity(growth, GrowthPos, angles, NULL_VECTOR);
					
					SetEntProp(growth, Prop_Data, "m_usSolidFlags", 152);
					SetEntProp(growth, Prop_Send, "m_CollisionGroup", 5);
					SetEntProp(growth, Prop_Data, "m_MoveCollide", 0);
					SetEntProp(growth, Prop_Data, "m_nSolidType", 6);
					SetEntProp(growth, Prop_Data, "m_takedamage", 2);
					SetEntProp(growth, Prop_Data, "m_iHealth", GrowthHealth[GrowthLevel]);
					HookSingleEntityOutput(growth, "OnBreak", OnGrowthDestroyed, true);
					AcceptEntityInput(growth, "Enable");
					iGrowth[client]=growth;
					
					W3EmitSoundToAll(GrowthSound,client);
				}
			}
			else
				PrintHintText(client,"Level your skill first");
		}
	}
}

public OnGrowthDestroyed(const String:output[], caller, activator, Float:delay)
{
	for(new client=1;client<=MaxClients;client++)
	{
		if(IsClientInGame(client) && War3_GetRace(client)==thisRaceID)
		{
			if(IsValidEdict(caller))
			{
				new Float:GrowthPos[3];
				GetEntPropVector(caller, Prop_Send, "m_vecOrigin", GrowthPos);
				
				TE_SetupSmoke(GrowthPos, ExplSprite, 100.0, 2);
				TE_SendToAll();
				
				AcceptEntityInput(caller, "Kill");
				iGrowth[client]=-1;
			}
		}
	}
}

/* *************************************** (ULT_VINE) *************************************** */
public OnUltimateCommand(client,race,bool:pressed)
{
	if(ValidPlayer(client,true) && race==thisRaceID && pressed)
	{
		new VineLevel=War3_GetSkillLevel(client,thisRaceID,ULT_VINE);
		if(VineLevel>0)
		{
			if(SkillAvailable(client,thisRaceID,ULT_VINE,true,true,true))
			{
				new target = War3_GetTargetInViewCone(client,800.0,false,30.0);
				if(target>0 && UltFilter(target))
				{
					War3_CooldownMGR(client,VineCD[VineLevel],thisRaceID,ULT_VINE,_,_);
					
					new Float:startpos[3];			GetClientAbsOrigin(target,startpos);
					new Float:endpos[3];			GetClientAbsOrigin(client,endpos);
					new Float:vector[3];

					MakeVectorFromPoints(startpos, endpos, vector);
					NormalizeVector(vector, vector);
					ScaleVector(vector, PullForce[VineLevel]);
					TeleportEntity(target, NULL_VECTOR, NULL_VECTOR, vector);
					War3_DealDamage(target,VineDamage[VineLevel],client,DMG_CRUSH,"vine whip",_,W3DMGTYPE_MAGIC);
					
					startpos[2]+=40.0;
					endpos[2]+=40.0;
					
					TE_SetupBeamPoints(startpos,endpos,BeamSprite,HaloSprite,0,35,1.0,10.0,20.0,0,1.0,{255,69,0,255},20);
					TE_SendToAll();
					
					W3EmitSoundToAll(VineSound,client);
				}
				else
					W3MsgNoTargetFound(client, 800.0);
			}
		}
		else
			W3MsgUltNotLeveled(client);
	}
}

