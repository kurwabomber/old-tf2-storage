#pragma semicolon 1
 
#include "W3SIncs/War3Source_Interface"
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <smlib>

public Plugin:myinfo = 
{
	name = "War3Source Race - Metal Gear notSOLID",
	author = "ABGar",
	description = "The Metal Gear notSOLID race for War3Source.",
	version = "1.0",
	// Jokr's Private Race Request - https://www.sevensinsgaming.com/forum/index.php?/topic/5594-jokr-metal-gear-notsolid-private/
}

new thisRaceID;

new SKILL_CROUCH, SKILL_HEALTH, SKILL_MSPEED, SKILL_ATTACK, ULT_REGEN;

// PASSIVES
new ExtraHealth[]={0,15,30,45,60};
new Float:CrouchDelay=2.0;
new Float:SkillSpeed[]={1.0,1.1,1.2,1.3};
new Float:SkillAttack[]={1.0,1.2,1.4,1.6,1.8,2.0};


// SKILL_CROUCH
new g_cardboardEntity[MAXPLAYERSCUSTOM]={-1, ...};
new Float:CanCrouchTime[MAXPLAYERSCUSTOM];
new bool:bDucking[MAXPLAYERSCUSTOM];
new String:CardboardModel[]="models/props_junk/cardboard_box003a_gib01.mdl";



// ULT_REGEN
new Float:RegenHPAmount=15.0;
new Float:RegenCD[]={0.0,45.0,38.0,30.0};
new Float:RegenDuration[]={0.0,2.0,4.0,6.0};
new bool:bInRegen[MAXPLAYERSCUSTOM]={false, ...};


public OnWar3PluginReady()
{
	thisRaceID=War3_CreateNewRace("Metal Gear notSOLID [PRIVATE]","notsolid");
	SKILL_CROUCH = War3_AddRaceSkill(thisRaceID,"Cardboard Box","Camouflage (passive when crouching)",false,1);
	SKILL_HEALTH = War3_AddRaceSkill(thisRaceID,"Soon-2-be-solid","Increased max health (passive)",false,4);
	SKILL_MSPEED = War3_AddRaceSkill(thisRaceID,"Zippydippy-dash","Increased Movemement Speed (passive)",false,3);
	SKILL_ATTACK = War3_AddRaceSkill(thisRaceID,"Zippydippy-slash","Increased Attack Speed (passive)",false,5);
	ULT_REGEN=War3_AddRaceSkill(thisRaceID,"Mmmmmmmmedikit","Massive HP Regen for a short time (+ultimate)",true,3);
	War3_CreateRaceEnd(thisRaceID);
	W3SkillCooldownOnSpawn(thisRaceID,ULT_REGEN,10.0,_);
	War3_AddSkillBuff(thisRaceID,SKILL_HEALTH,iAdditionalMaxHealth,ExtraHealth);
	War3_AddSkillBuff(thisRaceID,SKILL_MSPEED,fMaxSpeed,SkillSpeed);
	War3_AddSkillBuff(thisRaceID,SKILL_ATTACK,fAttackSpeed,SkillAttack);
}

public OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart);
	CreateTimer(0.1,CalcVis,_,TIMER_REPEAT);
}

public OnMapStart()
{
	PrecacheModel(CardboardModel);
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
    for (new i=1; i<MaxClients; i++)
    {
        if (ValidPlayer(i,true) && War3_GetRace(i)==thisRaceID)
        {
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
		KillCardboardEnt(client);
		CS_UpdateClientModel(client);
	}
	else
	{
		if (ValidPlayer(client,true))
        {
			InitPassiveSkills(client);
		}
	}
}

public OnSkillLevelChanged(client, race, skill, newskilllevel)
{
	if(race==thisRaceID && skill==SKILL_CROUCH && newskilllevel>0)
		CreateCardboardEnt(client);
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
	War3_WeaponRestrictTo(client,thisRaceID,"weapon_knife");
	bInRegen[client]=false;
	W3ResetAllBuffRace(client,thisRaceID);
	
	if(War3_GetSkillLevel(client,thisRaceID,SKILL_CROUCH)>0)
		CreateCardboardEnt(client);
}

/* *************************************** (SKILL_CROUCH) *************************************** */
public KillCardboardEnt(client)
{
	new ent = g_cardboardEntity[client];
	if(IsValidEntity(ent)) 
	{
		AcceptEntityInput(ent, "Kill");
	}
}

public CreateCardboardEnt(client)
{
	new Float:clientPos[3];		GetClientAbsOrigin(client,clientPos);		clientPos[2]+=10.0;
	new ent = CreateEntityByName("prop_dynamic_override");
	DispatchKeyValue(ent, "model", CardboardModel);
	DispatchSpawn(ent);
	TeleportEntity(ent,clientPos,NULL_VECTOR,NULL_VECTOR);
	SetVariantString("!activator");
	AcceptEntityInput(ent, "SetParent", client, ent, 0);
	AcceptEntityInput(ent, "TurnOff");
	g_cardboardEntity[client] = ent;
}

public OnWar3EventDeath(victim,attacker)
{
	if(ValidPlayer(victim) && War3_GetRace(victim)==thisRaceID)
	{
		KillCardboardEnt(victim);
	}
}

public Action:CalcVis(Handle:timer)
{
	for(new i=1;i<=MaxClients;i++)
	{
		if(ValidPlayer(i,true) && War3_GetRace(i)==thisRaceID)
		{
			new ent = g_cardboardEntity[i];
			if(IsValidEntity(ent))
			{
				new CrouchLevel = War3_GetSkillLevel(i,thisRaceID,SKILL_CROUCH);
				if(CanCrouchTime[i]<GetGameTime() && CrouchLevel>0)
				{
					War3_SetBuff(i,fInvisibilitySkill,thisRaceID,0.0);
					War3_SetBuff(i,bDisarm,thisRaceID,true);
					AcceptEntityInput(ent, "TurnOn");
				}
				else
				{		
					AcceptEntityInput(ent, "TurnOff");
					W3ResetBuffRace(i,fInvisibilitySkill,thisRaceID);
					War3_SetBuff(i,bDisarm,thisRaceID,false);
				}
				
				if(!bDucking[i] && CrouchLevel>0)
				{
					CanCrouchTime[i]=GetGameTime() + CrouchDelay;
				}
			}
		}
	}
}


public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(ValidPlayer(client,true) && War3_GetRace(client)==thisRaceID)
	{
		bDucking[client]=(buttons & IN_DUCK)?true:false;
	}
	return Plugin_Continue;
}

/* *************************************** (ULT_REGEN) *************************************** */
public OnUltimateCommand(client,race,bool:pressed)
{
	if(ValidPlayer(client,true) && race==thisRaceID && pressed)
	{
		new RegenLevel=War3_GetSkillLevel(client,thisRaceID,ULT_REGEN);
		if(RegenLevel>0)
		{
			if(SkillAvailable(client,thisRaceID,ULT_REGEN,true,true,true))
			{
				War3_CooldownMGR(client,RegenCD[RegenLevel],thisRaceID,ULT_REGEN,true,true);
				War3_SetBuff(client,fHPRegen,thisRaceID,RegenHPAmount);
				CreateTimer(RegenDuration[RegenLevel],StopRegen,client);
				bInRegen[client]=true;
			}
		}
		else
			W3MsgUltNotLeveled(client);
	}
}

public Action:StopRegen(Handle:timer,any:client)
{
	if(ValidPlayer(client))
	{
		bInRegen[client]=true;
		W3ResetBuffRace(client,fHPRegen,thisRaceID);
	}
}