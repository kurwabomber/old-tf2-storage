#pragma semicolon 1
 
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdkhooks>
#include <smlib>


public Plugin:myinfo = 
{
	name = "War3Source Race - T-800",
	author = "ABGar (edited by Kibbles)",
	description = "The T-800 race for War3Source.",
	version = "1.0",
    url = "http://sevensinsgaming.com"
}

new thisRaceID;

new SKILL_TITANIUM, SKILL_FATBOY, SKILL_HASTA, ULT_DIE;

// SKILL_TITANIUM
new Float:TitaniumReduce[]={1.0,0.95,0.9,0.85,0.8};//Sticking to the posted stats + IORY's balance suggestions

// SKILL_FATBOY
new Float:FatboyCooldown = 25.0;
new Float:FatboyDuration[]={0.0,7.0,8.0,9.0,10.0};
new Float:FatboySpeed[]={1.0,1.2,1.3,1.4,1.5};
new bool:bInFatboy[MAXPLAYERSCUSTOM];

// SKILL_HASTA
new Float:HastaCD=5.0;
new Float:HastaDamage[]={1.0,1.2,1.3,1.4,1.5};
new bool:g_bDamageMultipler[MAXPLAYERSCUSTOM];

// ULT_DIE
new Float:ResChance[]={0.0,0.2,0.3,0.4,0.5};
new bool:bKilledYet[MAXPLAYERSCUSTOM];


public OnWar3PluginReady()
{
	thisRaceID=War3_CreateNewRace("T-800 [PRIVATE]","t800");
	SKILL_TITANIUM = War3_AddRaceSkill(thisRaceID,"Titanium Skin","T-800 is made from titanium, and reduces damage (passive)",false,4);
	SKILL_FATBOY = War3_AddRaceSkill(thisRaceID,"Fatboy (+ability)","Hop on your fatboy to increase your speed for a little while (+ability)",false,4);
	SKILL_HASTA = War3_AddRaceSkill(thisRaceID,"Hasta La Vista, Baby","T-800 gets bonus damage after a few seconds (passive on attack)",false,4);
	ULT_DIE=War3_AddRaceSkill(thisRaceID,"I'll be back","Get a kill before you die for a chance to respawn (passive)",true,4);
	War3_CreateRaceEnd(thisRaceID);
}


public OnPluginStart()
{
	HookEvent("weapon_fire", Event_WeaponFire, EventHookMode_Pre);//Better to hook it before the event goes through, just to be sure you've got the timing right
    HookEvent("round_start", Event_RoundStart);//If you're using flags, you need to reset them when the round starts, or call an init method which is set up to account for things like weapons already existing. I've added that in.
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

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
    for (new i=0; i<MaxClients; i++)
    {
        if (ValidPlayer(i, true) && War3_GetRace(i)==thisRaceID)
        {
            InitPassiveSkills(i);
        }
    }
}

public InitPassiveSkills(client)
{
	War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife, weapon_smokegrenade, weapon_m3");
    if (!Client_HasWeapon(client, "weapon_smokegrenade"))//Always check whether or not they have the item, or it can bug out
    {
        Client_GiveWeapon(client, "weapon_smokegrenade", false);
    }
    if (!Client_HasWeapon(client, "weapon_m3"))
    {
        Client_GiveWeapon(client, "weapon_m3", true);
    }
	W3ResetAllBuffRace(client,thisRaceID);
	bKilledYet[client]=false;
	bInFatboy[client]=false;
}

/* *************************************** (SKILL_TITANIUM) *************************************** */
public OnW3TakeDmgAllPre(victim,attacker,Float:damage)
{
	if(ValidPlayer(victim, true) && ValidPlayer(attacker) && attacker!=victim)
	{
		if(GetClientTeam(victim)!=GetClientTeam(attacker))
		{
			if(War3_GetRace(victim)==thisRaceID)
			{
				new TitaniumLevel = War3_GetSkillLevel(victim,thisRaceID,SKILL_TITANIUM);
				if(TitaniumLevel>0)
				{
					War3_DamageModPercent(TitaniumReduce[TitaniumLevel]);
				}
			}
/* *************************************** (SKILL_HASTA) *************************************** */
			if(War3_GetRace(attacker)==thisRaceID && g_bDamageMultipler[attacker])
			{
				new HastaLevel = War3_GetSkillLevel(attacker,thisRaceID,SKILL_HASTA);
				if(HastaLevel>0)
				{
                    War3_CooldownMGR(attacker,HastaCD,thisRaceID,SKILL_HASTA,true,true);//cooldown goes here. Otherwise if they miss they'll still trigger the cooldown!
					War3_DamageModPercent(HastaDamage[HastaLevel]);
                    PrintToChat(attacker,"\x03 : Hasta La Vista, baby");//Just in case something goes wrong, put the message where the damage is applied.
                    g_bDamageMultipler[attacker] = false;//Easier to disable it here, but I'll leave the other disabler in for redundancy
				}
			}
		}
	}
}

public Event_WeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(ValidPlayer(client, true) && War3_GetRace(client)==thisRaceID)
	{
		new String:weapon[32]; 
		GetClientWeapon(client,weapon,32);
		if(StrEqual(weapon,"weapon_m3") && War3_SkillNotInCooldown(client,thisRaceID,SKILL_HASTA,true) && !Hexed(client))//Check for hexes (i.e. no ability proc
		{
			g_bDamageMultipler[client] = true;
		}
		else
		{
			g_bDamageMultipler[client] = false;//redundant disable
		}
    }
}

/* *************************************** (SKILL_FATBOY) *************************************** */
public Action:SpeedStop( Handle:timer, any:client )
{
	if(ValidPlayer(client) && bInFatboy[client])
	{
        bInFatboy[client] = false;
        W3ResetBuffRace(client, fMaxSpeed, thisRaceID);
	}
}

public OnAbilityCommand(client,ability,bool:pressed)
{
	if(ValidPlayer(client, true) && War3_GetRace(client)==thisRaceID && ability==0 && pressed)//Put validplayer checks first, or the checks can bug out.
	{
		new FatboyLevel = War3_GetSkillLevel(client,thisRaceID,SKILL_FATBOY);
		if(FatboyLevel>0)
		{
			if(SkillAvailable(client,thisRaceID,SKILL_FATBOY,true,true,true))
			{
				War3_CooldownMGR(client,(FatboyDuration[FatboyLevel]+FatboyCooldown),thisRaceID,SKILL_FATBOY, _, _);
				new seconds = RoundToFloor(FatboyDuration[FatboyLevel]);
				PrintToChat(client, "\x03 : Get on your fatboy for \x04%i seconds.",seconds);
				War3_SetBuff(client,fMaxSpeed,thisRaceID,FatboySpeed[FatboyLevel]);			
				bInFatboy[client] = true;
				CreateTimer(FatboyDuration[FatboyLevel],SpeedStop,client);	
			}
		}
		else
			PrintHintText(client,"Level your ability first");
	}
}

/* *************************************** (ULT_DIE) *************************************** */

public OnWar3EventDeath(victim,attacker)
{
	if(ValidPlayer(victim) && ValidPlayer(attacker, true) && attacker!=victim)
	{
		if(GetClientTeam(victim)!=GetClientTeam(attacker))
		{
			if(War3_GetRace(victim)==thisRaceID && bKilledYet[victim])
			{
				new DieLevel = War3_GetSkillLevel(victim,thisRaceID,ULT_DIE);
				if(DieLevel>0 && W3Chance(ResChance[DieLevel]))
				{
					CreateTimer(2.0,RespawnPlayer,victim);
					PrintToChat(victim,"\x03 : You will respawn in 2 seconds");
				}
			}
            if(War3_GetRace(attacker)==thisRaceID && !bKilledYet[attacker])
			{
				bKilledYet[attacker]=true;
                PrintToChat(attacker,"\x03 : You might come back to life once you die");
			}
		}
	}
}

public Action:RespawnPlayer(Handle:timer,any:client)
{
	if(ValidPlayer(client) && !IsPlayerAlive(client) && War3_GetRace(client)==thisRaceID && bKilledYet[client])//If the round has cycled over, this should reset.
	{
        War3_SpawnPlayer(client);
	}
}
