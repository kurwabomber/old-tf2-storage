#pragma semicolon 1
 
#include <sourcemod>
#include <smlib>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
	name = "War3Source Race - The Emperor",
	author = "ABGar & Kibbles",
	description = "The Emperor race for War3Source.",
	version = "1.0",
    url = "http://sevensinsgaming.com"
}

new thisRaceID;

new SKILL_BLAST, SKILL_BLESS, SKILL_WEAPON, ULT_MIGHT;

// SKILL_BLAST
new Float:BlastRange=500.0;//Use variables with repeated values to make maintenance easier!
new BlastDamage=10;
new Float:BlastDuration[]={0.0,0.5,1.0,1.5,2.0};
new Float:BlastCooldown = 15.0;
new GlowSprite;
new String:BlastSound[]="npc/roller/code2.wav";

// SKILL_BLESS
new Float:VampDamageMod[]={0.0,0.01,0.02,0.03,0.04};
new Float:VampDamageCap=10.0;
new String:VampSound[]="war3source/mask.mp3";

// SKILL_WEAPON
new bool:bAwpnext[MAXPLAYERS];
new Float:WeaponCD[]={0.0,11.0,9.0,7.0,5.0};

// ULT_MIGHT
new Float:RitualTime[]={0.0,7.0,8.0,9.0,10.0};
new Float:RitualCooldown=10.0;
new Handle:hRitualDisableTimers[MAXPLAYERS] = {INVALID_HANDLE, ...};//Track timers, in case they respawn!
new String:RitualSound[]="npc/vort/health_charge.wav";


public OnWar3PluginReady()
{
	thisRaceID=War3_CreateNewRace("The Emperor [PRIVATE]","emperor");
	SKILL_BLAST = War3_AddRaceSkill(thisRaceID,"Divine Blast","The Emperor stuns an enemy unit, disabling their movement and dealing damage (+ability)",false,4);
	SKILL_BLESS = War3_AddRaceSkill(thisRaceID,"Divine Blessing","The Emperor deals additional damage with every attack, and heals for the same amount (passive attack)",false,4);
	SKILL_WEAPON = War3_AddRaceSkill(thisRaceID,"Divine Weapon","The Emperor summons weapons to aid him in battle (+ability1)",false,4);
	ULT_MIGHT = War3_AddRaceSkill(thisRaceID,"God's Might","The Emperor is bathed in holy light, becoming immune to all skills (+ultimate)",true,4);//Ultimate, not skill.
	War3_CreateRaceEnd(thisRaceID);
	W3SkillCooldownOnSpawn(thisRaceID,ULT_MIGHT,10.0,_);
}


public OnPluginStart()
{
    HookEvent("round_start",Round_Start);
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
    War3_SetBuff(client,bBashed,thisRaceID,false);
	if(War3_GetRace(client)==thisRaceID)
	{
		InitPassiveSkills(client);
        DropPrimWeapon(client);
        DropSecWeapon(client);
        GivePlayerItem(client,"weapon_m4a1");
        GivePlayerItem(client,"weapon_deagle");
	}
}

public Round_Start(Handle:event, const String:name[], bool:dontBroadcast)//guns are always a bit finnicky when you're removing and then giving back. Added a round-start check because it was bugging with just spawn.
{
    for (new i=1; i<=MaxClients; i++)
    {
        if (ValidPlayer(i, true) && War3_GetRace(i) == thisRaceID)
        {
            CreateTimer(0.1,GiveWeaponsDelayed,i);//Short delay to avoid a clash of weapon remove/add functions at the start of the round. A better way to handle this would be to give weapons on a timer and check if the timer exists before trying to give, but I'm feeling lazy so this is how it is for now.
        }
    }
}
public Action:GiveWeaponsDelayed(Handle:timer, any:client)
{
    if (ValidPlayer(client,true))
    {
        bAwpnext[client]=true;
        DropPrimWeapon(client);
        DropSecWeapon(client);
        GivePlayerItem(client,"weapon_m4a1");
        GivePlayerItem(client,"weapon_deagle");
    }
}

public OnMapStart()
{
	War3_PrecacheSound(RitualSound);
	War3_PrecacheSound(BlastSound);
	//GlowSprite=PrecacheModel("effects/combinemuzzle2_dark.vmt");
    GlowSprite=PrecacheModel("sprites/yelflare1.vmt");
    for (new i=0; i<MAXPLAYERS; i++)
    {
        hRitualDisableTimers[i] = INVALID_HANDLE;
    }
}

static InitPassiveSkills(client)
{
    if (hRitualDisableTimers[client] != INVALID_HANDLE)
    {
        KillTimer(hRitualDisableTimers[client]);
        hRitualDisableTimers[client] = INVALID_HANDLE;
    }
	W3ResetAllBuffRace(client,thisRaceID);
	bAwpnext[client]=true;
}

/* *************************************** (SKILL_BLESS) *************************************** */
public OnW3TakeDmgBullet(victim,attacker,Float:damage)
{
	if(ValidPlayer(attacker)&&ValidPlayer(victim)&&attacker!=victim&&GetClientTeam(attacker)!=GetClientTeam(victim))
	{
		if(War3_GetRace(attacker)==thisRaceID)
		{
			new VampLevel = War3_GetSkillLevel(attacker,thisRaceID,SKILL_BLESS);
			if(VampLevel>0)
			{
                if (!IsSkillImmune(victim))
                {
                    new Float:fplusdamage=(War3_GetMaxHP(victim)*VampDamageMod[VampLevel]);//Better to just use floats and round, rather than relying on implicit conversions (in my opinion :P)
                    if(fplusdamage>VampDamageCap)
                        fplusdamage=VampDamageCap;
                    new iplusdamage = RoundToFloor(fplusdamage);
                    War3_HealToMaxHP(attacker, iplusdamage);
                    EmitSoundToAll(VampSound,attacker);
                    PrintHintText(attacker,"You leeched %i health with Divine Blessing",iplusdamage);
                    War3_DealDamage(victim,iplusdamage,attacker,DMG_CRUSH,"divine blessing",_,W3DMGTYPE_MAGIC);
                }
                else
                {
                    W3MsgEnemyHasImmunity(attacker,false);
                }
			}
		}
	}
}


/* *************************************** (SKILL_BLAST) *************************************** */
public Action:EndBashed(Handle:timer,any:client)//Don't use userID. Buffs are applied to a player slot, not a person.
{
	if(ValidPlayer(client))
		War3_SetBuff(client,bBashed,thisRaceID,false);
}

public OnAbilityCommand(client,ability,bool:pressed)
{
	if(ValidPlayer(client, true) && War3_GetRace(client)==thisRaceID && ability==0 && pressed)//Use ValidPlayer, and check it first. Some functions will break if you run them on an invalid clientID
	{
		new BlastLevel = War3_GetSkillLevel(client,thisRaceID,SKILL_BLAST);
		if(BlastLevel>0)
		{
			if(War3_SkillNotInCooldown(client,thisRaceID,SKILL_BLAST,true))
			{
				new target = War3_GetTargetInViewCone(client,BlastRange,false,23.0);//Always be careful with the include_friendlies flag
				if(target>0 && GetClientTeam(client)!=GetClientTeam(target))
				{
					if(!W3HasImmunity(target,Immunity_Skills))
					{
						new Float:TargetPos[3];
						GetClientAbsOrigin(target,TargetPos);
						TargetPos[2]+=30.0;
						War3_SetBuff(target,bBashed,thisRaceID,true);
						CreateTimer(BlastDuration[BlastLevel],EndBashed,target);
						War3_DealDamage(target,BlastDamage,client,DMG_CRUSH,"divine blast",_,W3DMGTYPE_MAGIC);
						PrintHintText(target,"You've been stunned by a Divine Blast");
						War3_CooldownMGR(client,BlastCooldown,thisRaceID,SKILL_BLAST,_,_);
						
						TE_SetupGlowSprite(TargetPos,GlowSprite,BlastDuration[BlastLevel],3.0,200);//Arrow wants something yellow, has said a laser is okay
						TE_SendToClient(client);
						EmitSoundToAll(BlastSound,client);
					}
					else
						W3MsgEnemyHasImmunity(client,false);
				}
				else
				{
					W3MsgNoTargetFound(client, BlastRange);
				}
			}
		}
		else
			PrintHintText(client,"Level your Divine Blast first");
	}	
/* *************************************** (SKILL_WEAPON) *************************************** */
	if(ValidPlayer(client, true) && War3_GetRace(client)==thisRaceID && ability==1 && pressed)
	{
		new WeaponLevel = War3_GetSkillLevel(client,thisRaceID,SKILL_WEAPON);
		if(WeaponLevel>0)
		{
			if(!Silenced(client,true) && War3_SkillNotInCooldown(client,thisRaceID,SKILL_WEAPON,true))
			{
                War3_CooldownMGR(client,WeaponCD[WeaponLevel],thisRaceID,SKILL_WEAPON,_,_);//Put cooldown first to avoid double presses.
				if(bAwpnext[client])
				{
					DropPrimWeapon(client);
					GivePlayerItem(client,"weapon_awp");
					bAwpnext[client]=false;
				}
				else
				{
					DropPrimWeapon(client);
					GivePlayerItem(client,"weapon_m4a1");
					bAwpnext[client]=true;
				}
			}
		}
		else
			PrintHintText(client, "Level your Demonic Weapon first");
	}
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


/* *************************************** (ULT_MIGHT) *************************************** */
public OnUltimateCommand(client,race,bool:pressed)
{
    if(race==thisRaceID && pressed && ValidPlayer(client,true))
	{
        if(!Silenced(client,true) && War3_SkillNotInCooldown(client,thisRaceID,ULT_MIGHT,true))
        {
            new RitualLevel=War3_GetSkillLevel(client,thisRaceID,ULT_MIGHT);
            if(RitualLevel>0)
            {
				EmitSoundToAll(RitualSound,client);
				War3_SetBuff(client,bImmunityWards,thisRaceID,true);//Why did you use SetBuffItem?
				War3_SetBuff(client,bImmunityUltimates,thisRaceID,true);
				War3_SetBuff(client,bImmunitySkills,thisRaceID,true);
				War3_SetBuff(client,fMaxSpeed,thisRaceID,1.2);
				hRitualDisableTimers[client]=CreateTimer(RitualTime[RitualLevel],EndRitual,client);
				PrintHintText(client, "You begin the Demonic Ritual....  Immunity for %.1f seconds",RitualTime[RitualLevel]);
				War3_CooldownMGR(client,(RitualTime[RitualLevel]+RitualCooldown),thisRaceID,ULT_MIGHT,_,_);
			}
			else
				W3MsgUltNotLeveled(client);
		}
	}
}

public Action:EndRitual(Handle:timer,any:client)
{
	if(ValidPlayer(client))
	{
		War3_SetBuff(client,bImmunityWards,thisRaceID,false);
		War3_SetBuff(client,bImmunityUltimates,thisRaceID,false);
		War3_SetBuff(client,bImmunitySkills,thisRaceID,false);
		War3_SetBuff(client,fMaxSpeed,thisRaceID,1.0);
		PrintHintText(client, "The ritual is complete");
	}
}